import json
import re
from dataclasses import dataclass
from collections import deque
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
SRC_TS = ROOT / "tools" / "roomLayouts_source.ts"
OUT_DIR = ROOT / "Escenas" / "Levels" / "Level1" / "LayoutRooms"

# Escala mundo por celda (sube esto para habitaciones más grandes y más espacio de maniobra).
CELL_SIZE = 3.0
GRID_W = 40
GRID_H = 30
WALL_HEIGHT = 3.0
DOOR_Y = 1.5

# Reducir un poco el "footprint" de los objetos para abrir pasillos entre ellos.
# 1.0 = tamaño completo; 0.8 deja ~20% de aire extra alrededor.
OBJECT_FOOTPRINT_FACTOR = 0.8

# Aperturas automáticas en paredes para conectar zonas inaccesibles.
AUTO_CONNECT_AREAS = True
DOORWAY_WIDTH_CELLS = 2
OBJECT_BLOCKS_PATHING = True

# --- Clasificación de objetos (colisión / decoración) ---
# Se usa para:
# - Marcar metadata/collidable en el .tscn
# - Decidir qué objetos bloquean pathing para el auto-conector
COLLIDABLE_CATEGORIES = {"furniture", "cover", "obstacle", "door"}


def _obj_is_collidable(obj: dict[str, Any]) -> bool:
    # En el source TS, `type` se usa también para elementos “pegados a la pared” (deco).
    # Para colisión, nos fiamos del `category`.
    cat = str(obj.get("category", "")).strip().lower()
    return cat in COLLIDABLE_CATEGORIES


def _strip_ts_to_json_text(ts_text: str) -> str:
    # Keep only the array contents of roomLayouts
    m = re.search(r"roomLayouts\s*:\s*RoomLayout\[\]\s*=\s*(\[[\s\S]*?\])\s*;", ts_text)
    if not m:
        # fallback: first [ ... last ]
        start = ts_text.find("[")
        end = ts_text.rfind("]")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("No array found in TS text")
        array_text = ts_text[start : end + 1]
    else:
        array_text = m.group(1)

    # Quote keys: id: -> "id":
    array_text = re.sub(r"(\b[a-zA-Z_]\w*)\s*:", r'"\1":', array_text)
    # Convert single-quoted strings to double-quoted
    array_text = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'", lambda m2: json.dumps(m2.group(1)), array_text)
    # Remove trailing commas before } or ]
    array_text = re.sub(r",\s*([}\]])", r"\1", array_text)
    return array_text


def load_layouts() -> list[dict[str, Any]]:
    ts_text = SRC_TS.read_text(encoding="utf-8")
    json_text = _strip_ts_to_json_text(ts_text)
    return json.loads(json_text)


def _t3(scale_x: float, scale_y: float, scale_z: float, pos_x: float, pos_y: float, pos_z: float) -> str:
    # Transform3D basis columns + origin
    # Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz)
    return f"Transform3D({scale_x}, 0, 0, 0, {scale_y}, 0, 0, 0, {scale_z}, {pos_x}, {pos_y}, {pos_z})"


def _grid_to_world(x: float, y: float) -> tuple[float, float]:
    off_x = -(GRID_W * CELL_SIZE) / 2.0
    off_z = -(GRID_H * CELL_SIZE) / 2.0
    wx = off_x + x * CELL_SIZE
    wz = off_z + y * CELL_SIZE
    return wx, wz


def _in_bounds(x: int, y: int) -> bool:
    return 0 <= x < GRID_W and 0 <= y < GRID_H


def _neighbors4(x: int, y: int) -> Iterable[tuple[int, int]]:
    if x > 0:
        yield x - 1, y
    if x + 1 < GRID_W:
        yield x + 1, y
    if y > 0:
        yield x, y - 1
    if y + 1 < GRID_H:
        yield x, y + 1


def _build_wall_grid(walls: list[dict[str, Any]]) -> list[list[bool]]:
    grid = [[False for _ in range(GRID_H)] for _ in range(GRID_W)]
    for w in walls:
        x0 = int(float(w["x"]))
        y0 = int(float(w["y"]))
        ww = int(float(w["width"]))
        hh = int(float(w["height"]))
        for x in range(x0, x0 + ww):
            for y in range(y0, y0 + hh):
                if _in_bounds(x, y):
                    grid[x][y] = True
    return grid


def _build_objects_grid(objects: list[dict[str, Any]]) -> list[list[bool]]:
    grid = [[False for _ in range(GRID_H)] for _ in range(GRID_W)]
    if not OBJECT_BLOCKS_PATHING:
        return grid

    for obj in objects:
        # La decoración no debería bloquear el pathing / conectividad.
        if not _obj_is_collidable(obj):
            continue

        ox = float(obj.get("x", 0.0))
        oy = float(obj.get("y", 0.0))
        ow = float(obj.get("width", 1.0))
        oh = float(obj.get("height", 1.0))

        # Convertir a tiles (aprox). Si hay decimales, cubrir el rango.
        x0 = int(ox)
        y0 = int(oy)
        x1 = int(ox + max(0.0, ow))
        y1 = int(oy + max(0.0, oh))
        if x1 < x0:
            x0, x1 = x1, x0
        if y1 < y0:
            y0, y1 = y1, y0

        # Asegurar al menos 1 celda.
        if x1 == x0:
            x1 = x0 + 1
        if y1 == y0:
            y1 = y0 + 1

        for x in range(x0, x1):
            for y in range(y0, y1):
                if _in_bounds(x, y):
                    grid[x][y] = True
    return grid


def _find_nearest_free_cell(wall_grid: list[list[bool]], x: int, y: int) -> tuple[int, int] | None:
    # Si ya es libre, ok.
    if _in_bounds(x, y) and not wall_grid[x][y]:
        return x, y

    # BFS desde la celda (aunque sea wall) hasta encontrar la primera libre.
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    if _in_bounds(x, y):
        q.append((x, y))
        seen.add((x, y))
    else:
        # clamp dentro del grid
        x = min(max(x, 0), GRID_W - 1)
        y = min(max(y, 0), GRID_H - 1)
        q.append((x, y))
        seen.add((x, y))

    while q:
        cx, cy = q.popleft()
        if not wall_grid[cx][cy]:
            return cx, cy
        for nx, ny in _neighbors4(cx, cy):
            if (nx, ny) in seen:
                continue
            seen.add((nx, ny))
            q.append((nx, ny))
    return None


def _label_components(blocked_grid: list[list[bool]]) -> tuple[list[list[int]], int]:
    comp = [[-1 for _ in range(GRID_H)] for _ in range(GRID_W)]
    cid = 0
    for x in range(GRID_W):
        for y in range(GRID_H):
            if blocked_grid[x][y] or comp[x][y] != -1:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            comp[x][y] = cid
            while q:
                cx, cy = q.popleft()
                for nx, ny in _neighbors4(cx, cy):
                    if blocked_grid[nx][ny] or comp[nx][ny] != -1:
                        continue
                    comp[nx][ny] = cid
                    q.append((nx, ny))
            cid += 1
    return comp, cid


def _carve_doorway(wall_grid: list[list[bool]], x: int, y: int) -> None:
    if not _in_bounds(x, y):
        return
    if not wall_grid[x][y]:
        return

    # Orientación aproximada según continuidad de pared.
    h = int(_in_bounds(x - 1, y) and wall_grid[x - 1][y]) + int(_in_bounds(x + 1, y) and wall_grid[x + 1][y])
    v = int(_in_bounds(x, y - 1) and wall_grid[x][y - 1]) + int(_in_bounds(x, y + 1) and wall_grid[x][y + 1])
    horizontal = h >= v

    wall_grid[x][y] = False
    if DOORWAY_WIDTH_CELLS <= 1:
        return

    # Abrir un segundo “tile” contiguo para que pase mejor el player.
    if horizontal:
        if _in_bounds(x + 1, y) and wall_grid[x + 1][y]:
            wall_grid[x + 1][y] = False
        elif _in_bounds(x - 1, y) and wall_grid[x - 1][y]:
            wall_grid[x - 1][y] = False
    else:
        if _in_bounds(x, y + 1) and wall_grid[x][y + 1]:
            wall_grid[x][y + 1] = False
        elif _in_bounds(x, y - 1) and wall_grid[x][y - 1]:
            wall_grid[x][y - 1] = False


def _connect_all_areas(wall_grid: list[list[bool]], objects_grid: list[list[bool]], start: tuple[int, int]) -> None:
    if not AUTO_CONNECT_AREAS:
        return

    blocked = [[(wall_grid[x][y] or objects_grid[x][y]) for y in range(GRID_H)] for x in range(GRID_W)]
    comp, n = _label_components(blocked)
    sx, sy = start
    if not _in_bounds(sx, sy):
        return
    if blocked[sx][sy]:
        # Buscar un inicio libre cercano (evitando paredes/objetos)
        nf = _find_nearest_free_cell(blocked, sx, sy)
        if nf is None:
            return
        sx, sy = nf
        start = (sx, sy)
        blocked = [[(wall_grid[x][y] or objects_grid[x][y]) for y in range(GRID_H)] for x in range(GRID_W)]
        comp, n = _label_components(blocked)

    start_comp = comp[sx][sy]
    if start_comp == -1:
        return

    # Iterar hasta que todo el espacio libre sea accesible desde start.
    safety = 0
    while n > 1 and safety < 200:
        safety += 1
        blocked = [[(wall_grid[x][y] or objects_grid[x][y]) for y in range(GRID_H)] for x in range(GRID_W)]
        comp, n = _label_components(blocked)
        start_comp = comp[sx][sy]
        if n <= 1:
            break

        # Calcular tamaños de componentes para priorizar la más grande.
        sizes = [0] * n
        for x in range(GRID_W):
            for y in range(GRID_H):
                if comp[x][y] != -1:
                    sizes[comp[x][y]] += 1
        # Elegir una componente objetivo distinta a la de start (la más grande).
        target_comp = max((i for i in range(n) if i != start_comp), key=lambda i: sizes[i])

        # Objetivo: cualquier celda libre de la componente target (según el estado actual).
        target_cells: set[tuple[int, int]] = set()
        for x in range(GRID_W):
            for y in range(GRID_H):
                if comp[x][y] == target_comp:
                    target_cells.add((x, y))

        if not target_cells:
            break

        # 0-1 BFS: moverse por celdas libres cuesta 0; atravesar pared cuesta 1; objetos son impasables.
        INF = 10**9
        dist = [[INF for _ in range(GRID_H)] for _ in range(GRID_W)]
        prev: dict[tuple[int, int], tuple[int, int] | None] = {}

        dq: deque[tuple[int, int]] = deque()
        dist[sx][sy] = 0
        prev[(sx, sy)] = None
        dq.append((sx, sy))

        end: tuple[int, int] | None = None
        while dq:
            cx, cy = dq.popleft()
            if (cx, cy) in target_cells and not wall_grid[cx][cy]:
                end = (cx, cy)
                break

            cd = dist[cx][cy]
            for nx, ny in _neighbors4(cx, cy):
                if objects_grid[nx][ny]:
                    continue
                wcost = 1 if wall_grid[nx][ny] else 0
                nd = cd + wcost
                if nd < dist[nx][ny]:
                    dist[nx][ny] = nd
                    prev[(nx, ny)] = (cx, cy)
                    if wcost == 0:
                        dq.appendleft((nx, ny))
                    else:
                        dq.append((nx, ny))

        if end is None:
            # No se puede conectar (p.ej. objetos bloqueando todo).
            break

        # Reconstruir camino y “excavar” paredes.
        cur = end
        path: list[tuple[int, int]] = []
        while cur is not None:
            path.append(cur)
            cur = prev.get(cur)
        path.reverse()

        carved_any = False
        for px, py in path:
            if wall_grid[px][py]:
                _carve_doorway(wall_grid, px, py)
                carved_any = True

        if not carved_any:
            # Ya conectados o el camino no requiere romper paredes.
            # Evitar bucle infinito.
            break


def _rects_from_wall_grid(wall_grid: list[list[bool]]) -> list[dict[str, int]]:
    # Extraer rectángulos (x,y,width,height) de un grid booleano para reducir nodos.
    visited = [[False for _ in range(GRID_H)] for _ in range(GRID_W)]
    rects: list[dict[str, int]] = []

    for y in range(GRID_H):
        for x in range(GRID_W):
            if visited[x][y] or not wall_grid[x][y]:
                continue

            # expand width
            w = 1
            while x + w < GRID_W and wall_grid[x + w][y] and not visited[x + w][y]:
                w += 1

            # expand height while full row segment is wall
            h = 1
            done = False
            while y + h < GRID_H and not done:
                for xx in range(x, x + w):
                    if not wall_grid[xx][y + h] or visited[xx][y + h]:
                        done = True
                        break
                if not done:
                    h += 1

            for yy in range(y, y + h):
                for xx in range(x, x + w):
                    visited[xx][yy] = True

            rects.append({"x": x, "y": y, "width": w, "height": h})
    return rects


def generate_room_tscn(layout: dict[str, Any]) -> str:
    room_id = int(layout["id"])
    room_name = f"LayoutRoom{room_id}"

    # Resources for default 3 waves: 2 Enemy1 + 2 Enemy2
    wave_resources = []
    for w in range(1, 4):
        wave_resources.append(
            f"""
[sub_resource type="Resource" id="SpawnEntry_w{w}_e1"]
script = ExtResource("5_spawnentry")
scene = ExtResource("3_enemy1")
count = 2

[sub_resource type="Resource" id="SpawnEntry_w{w}_e2"]
script = ExtResource("5_spawnentry")
scene = ExtResource("4_enemy2")
count = 2

[sub_resource type="Resource" id="WaveDefinition_w{w}"]
script = ExtResource("6_wavedef")
entries = [SubResource("SpawnEntry_w{w}_e1"), SubResource("SpawnEntry_w{w}_e2")]
spawn_interval = 2.0
max_alive = 5
""".rstrip()
        )

    # Floor
    floor_scale_x = GRID_W * CELL_SIZE
    floor_scale_z = GRID_H * CELL_SIZE
    floor_t = _t3(floor_scale_x, 0.2, floor_scale_z, 0.0, -0.1, 0.0)

    # SpawnPoint
    ps = layout.get("playerStart", {"x": GRID_W / 2, "y": GRID_H / 2})
    psx, psz = _grid_to_world(float(ps["x"]), float(ps["y"]))
    spawn_t = _t3(1, 1, 1, psx, 0.0, psz)

    # Door at exit
    ex = layout.get("exit", {"x": GRID_W - 2, "y": GRID_H - 2})
    exx, exz = _grid_to_world(float(ex["x"]), float(ex["y"]))
    door_t = _t3(1, 1, 1, exx, DOOR_Y, exz)

    # Walls (conectando zonas inaccesibles si hace falta)
    wall_grid = _build_wall_grid(layout.get("walls", []))
    objects_grid = _build_objects_grid(layout.get("objects", []))
    blocked_for_start = [[(wall_grid[x][y] or objects_grid[x][y]) for y in range(GRID_H)] for x in range(GRID_W)]
    start_cell = _find_nearest_free_cell(blocked_for_start, int(float(ps["x"])), int(float(ps["y"]))) or (
        int(float(ps["x"])),
        int(float(ps["y"])),
    )
    if AUTO_CONNECT_AREAS:
        _connect_all_areas(wall_grid, objects_grid, start_cell)

    wall_rects = _rects_from_wall_grid(wall_grid)
    wall_nodes = []
    for idx, w in enumerate(wall_rects):
        wx = float(w["x"])
        wy = float(w["y"])
        ww = float(w["width"])
        wh = float(w["height"])
        cx = wx + ww / 2.0
        cy = wy + wh / 2.0
        px, pz = _grid_to_world(cx, cy)
        sx = ww * CELL_SIZE
        sz = wh * CELL_SIZE
        t = _t3(sx, WALL_HEIGHT, sz, px, WALL_HEIGHT / 2.0, pz)
        wall_nodes.append(
            f"""
[node name="Wall_{idx}" type="MeshInstance3D" parent="Walls"]
mesh = SubResource("BoxMesh_1")
material_override = SubResource("Mat_Collidable")
transform = {t}
""".rstrip()
        )

    # Objects (placeholders)
    obj_nodes = []
    used_names: set[str] = set()
    for obj in layout.get("objects", []):
        oid = str(obj.get("id", ""))
        raw_name = str(obj.get("name", f"Obj_{oid}"))
        # Usar el nombre humano del objeto como nombre del nodo (más fácil de leer en Godot),
        # evitando caracteres problemáticos para NodePath.
        node_name_base = raw_name.replace("/", "-").replace("\n", " ").strip() or f"Obj_{oid}"
        if len(node_name_base) > 80:
            node_name_base = node_name_base[:80].rstrip()
        node_name = node_name_base
        if node_name in used_names:
            node_name = f"{node_name_base}_{oid}"
        used_names.add(node_name)

        ox = float(obj.get("x", 0.0))
        oy = float(obj.get("y", 0.0))
        ow = float(obj.get("width", 1.0))
        oh = float(obj.get("height", 1.0))
        cx = ox + ow / 2.0
        cy = oy + oh / 2.0
        px, pz = _grid_to_world(cx, cy)
        sx = max(0.1, ow * CELL_SIZE * OBJECT_FOOTPRINT_FACTOR)
        sz = max(0.1, oh * CELL_SIZE * OBJECT_FOOTPRINT_FACTOR)
        is_wall = str(obj.get("type", "")) == "wall"
        py = 1.5 if is_wall else 0.5
        sy = 1.0
        t = _t3(sx, sy, sz, px, py, pz)
        collidable = _obj_is_collidable(obj)
        mat = "Mat_Collidable" if collidable else "Mat_NoCollide"
        obj_nodes.append(
            f"""
[node name="{node_name}" type="MeshInstance3D" parent="Objects"]
mesh = SubResource("BoxMesh_1")
material_override = SubResource("{mat}")
transform = {t}
metadata/collidable = {str(collidable).lower()}
""".rstrip()
        )

    return f"""[gd_scene format=3]

[ext_resource type="PackedScene" path="res://Escenas/Levels/Door.tscn" id="1_door"]
[ext_resource type="Script" path="res://Scripts/Levels/room_waves.gd" id="2_roomwaves"]
[ext_resource type="PackedScene" path="res://Escenas/Enemies/Enemy1.tscn" id="3_enemy1"]
[ext_resource type="PackedScene" path="res://Escenas/Enemies/Enemy2.tscn" id="4_enemy2"]
[ext_resource type="Script" path="res://Scripts/Enemies/spawn_entry.gd" id="5_spawnentry"]
[ext_resource type="Script" path="res://Scripts/Enemies/wave_definition.gd" id="6_wavedef"]

[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(1, 1, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Collidable"]
albedo_color = Color(0.22, 0.22, 0.22, 1)
metallic = 0.0
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Mat_NoCollide"]
albedo_color = Color(0.75, 0.75, 0.75, 1)
metallic = 0.0
roughness = 1.0

{chr(10).join(wave_resources)}

[node name="{room_name}" type="Node3D"]

[node name="RoomWaves" type="Node" parent="."]
script = ExtResource("2_roomwaves")
waves = [SubResource("WaveDefinition_w1"), SubResource("WaveDefinition_w2"), SubResource("WaveDefinition_w3")]

[node name="SpawnPoint" type="Marker3D" parent="."]
transform = {spawn_t}

[node name="Door" parent="." instance=ExtResource("1_door")]
transform = {door_t}

[node name="Floor" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_1")
transform = {floor_t}

[node name="Walls" type="Node3D" parent="."]
{chr(10).join(wall_nodes)}

[node name="Objects" type="Node3D" parent="."]
{chr(10).join(obj_nodes)}
"""


def main() -> None:
    layouts = load_layouts()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for layout in layouts:
        room_id = int(layout["id"])
        path = OUT_DIR / f"Room{room_id}.tscn"
        path.write_text(generate_room_tscn(layout), encoding="utf-8")
    print(f"Generated {len(layouts)} rooms into {OUT_DIR}")


if __name__ == "__main__":
    main()

