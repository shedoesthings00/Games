# Dispatch: The Mighty Nein

Demo jugable tipo **Dispatch Hero** ambientada en **The Mighty Nein** (Critical Role), desarrollada con **Godot Engine 4.x** (GDScript).

## Cómo ejecutar

1. Abre el proyecto en Godot 4.x (Editor).
2. La **escena principal** está configurada en **Project → Project Settings → Application → Run → Main Scene**: `res://scenes/main_menu.tscn`.
3. Pulsa **F5** o el botón **Play** para ejecutar la demo.

## Flujo de juego

1. **Menú principal** → Jugar / Opciones / Salir
2. **Opciones** → Volumen, pantalla completa, Atrás (guardado en `user://settings.cfg`)
3. **Selección de héroes** → Lista de los 7 miembros de The Mighty Nein; **Empezar partida** inicia la partida
4. **Pantalla de Dispatch (juego)**  
   - Oleada actual con briefing y requisitos  
   - Lista de héroes con estado (OK / Fatigado / Herido) y barra de fatiga  
   - Seleccionar 1–3 héroes (click en **Seleccionar**) y pulsar **Enviar misión**  
   - Resultado (éxito/fallo) con quote del personaje  
   - Tras 7 oleadas completadas con éxito → **Victoria**  
   - Si se alcanzan 3 fallos o no quedan héroes disponibles → **Derrota**
5. **Victoria / Game Over** → Reintentar (vuelve al juego) o Menú principal

## Estructura del proyecto

- `scenes/` — Escenas: `main_menu`, `options`, `hero_select`, `game/game`, `game_over`, `victory`
- `scripts/autoloads/` — `game_manager.gd`, `hero_manager.gd`, `wave_manager.gd`
- `scripts/game/` — `game.gd`, `mission_resolver.gd`
- `scripts/ui/` — Scripts de menús y pantallas de fin
- `resources/` — `hero_data.gd`, `wave_data.gd` (definiciones de datos)

## Mecánicas principales

- **Stats por héroe**: Combate, Intelecto, Movilidad, Carisma, Vigor.
- **Éxito de misión**: Se compara la suma de stats del equipo con los requisitos de la oleada (~80 % umbral); se aplican fatiga y habilidades especiales.
- **Fatiga**: Aumenta al enviar; reduce efectividad. **Lesión**: Posible en fallo; el héroe no puede ir 2 oleadas.
- **Habilidades distintivas** por personaje (bonus según tipo de misión o efecto pasivo).

## TODOs opcionales (post-demo)

- Sustituir placeholders por sprites/iconos de los 7 personajes y UI.
- Tileset o fondo 2D top-down para el área de juego.
- Balance fino de stats, requisitos de oleadas y probabilidad de lesión.
- Animaciones o transiciones en UI.
- Efectos de sonido.
- Persistencia de partida en disco (guardar/cargar).

## Requisitos

- Godot Engine **4.x** (probado con 4.6).
