# Exporta la story bible (.xlsx) a JSON UTF-8 en res://data.
# Volver a ejecutar tras editar el Excel: python tools/export_story_bible.py
from __future__ import annotations

import argparse
import json
from pathlib import Path

import openpyxl

# Contactos sintéticos para verificación (fase intermedia: teléfono/email obligatorios).
# CASO-0010: sin teléfono a propósito (GDD).
CASE_EXTRA_CONTACT: dict[str, dict[str, str]] = {
    "CASO-2026-0001": {"telefono": "+34 912 100 001", "email": "laura.gomez@consultora.ej"},
    "CASO-2026-0002": {"telefono": "+34 918 100 002", "email": "anonimo@temp-mail.ej"},
    "CASO-2026-0003": {"telefono": "+34 916 100 003", "email": "javier.luque@correo.ej"},
    "CASO-2026-0004": {"telefono": "+34 912 100 004", "email": "marta.delrio@correo.ej"},
    "CASO-2026-0005": {"telefono": "+34 921 100 005", "email": "contacto@solucionesnorte.ej"},
    "CASO-2026-0006": {"telefono": "+34 918 100 006", "email": "andres.cid@correo.ej"},
    "CASO-2026-0007": {"telefono": "+34 912 100 007", "email": "ricardo.barlacurva@correo.ej"},
    "CASO-2026-0008": {"telefono": "+34 912 100 008", "email": "admision@clinica.ej"},
    "CASO-2026-0009": {"telefono": "+34 916 100 009", "email": "piedad.torres@correo.ej"},
    "CASO-2026-0010": {"telefono": "", "email": "cliente.nuevo@madrid.ej"},
    "CASO-2026-0011": {"telefono": "+34 912 100 011", "email": "laura.gomez@consultora.ej"},
    "CASO-2026-0012": {"telefono": "+34 912 100 012", "email": "familia.delrio@correo.ej"},
    "CASO-2026-0013": {"telefono": "+34 912 100 013", "email": "ops@transportes.ej"},
    "CASO-2026-0014": {"telefono": "+34 918 100 014", "email": "m.castillo@instituto.ej"},
    "CASO-2026-0015": {"telefono": "+34 916 100 015", "email": "rrhh@nochefactory.ej"},
    "CASO-2026-0016": {"telefono": "+34 912 100 016", "email": "testigo.calle@correo.ej"},
    "CASO-2026-0017": {"telefono": "+34 912 100 017", "email": "seguridad@empresa.ej"},
    "CASO-2026-0018": {"telefono": "+34 918 100 018", "email": "vecino.molesto@correo.ej"},
    "CASO-2026-0019": {"telefono": "+34 912 100 019", "email": "familia.victima3@correo.ej"},
    "CASO-2026-0020": {"telefono": "+34 912 100 020", "email": "archivo.interno@empresa.ej"},
    "CASO-2026-0021": {"telefono": "+34 912 100 021", "email": "investigacion@corporate.ej"},
}

# Narrativas jugables (resumen ampliado alineado con GDD / story bible).
CASE_NARRATIVE_BODY: dict[str, str] = {
    "CASO-2026-0001": (
        "Buenos días. Trabajo en una consultora pequeña y creo que uno de los socios está "
        "desviando clientes a espaldas de la empresa, usando nuestros informes para montar algo "
        "por su cuenta. Necesito pruebas antes de confrontarlo o plantear acciones legales.\n\n"
        "Adjunto contrato de trabajo y un listado parcial de clientes."
    ),
    "CASO-2026-0002": (
        "Quiero que el detective siga a mi pareja para saber con quién se ve. No quiero dar "
        "muchos datos por correo; prefiero discreción total."
    ),
    "CASO-2026-0003": (
        "Desde hace semanas alguien deja notas en la puerta de mi piso. No hay insultos: solo "
        "un símbolo raro, como una espiral rota, y la frase «nos veremos en la curva». "
        "Vivo cerca de la carretera M-23.\n\n"
        "Adjunto fotografía de la nota y el sobre escaneado."
    ),
    "CASO-2026-0004": (
        "Mi hermano lleva dos días sin aparecer. Salió del trabajo y la última vez que lo vieron "
        "fue en un bar de carretera, el «Bar La Curva», de camino a la M-23.\n\n"
        "Adjunto captura impresa de un mensaje con la última ubicación compartida."
    ),
    "CASO-2026-0005": (
        "Somos «Soluciones Norte», en Segovia. Sospechamos que un empleado filtra información "
        "de proyectos a la competencia en Madrid. Necesitamos investigación corporativa."
    ),
    "CASO-2026-0006": (
        "Llevo semanas recibiendo llamadas anónimas: silencio, respiración a veces. "
        "De fondo se oye tráfico, como si llamaran desde un arcén. Vivo en Alcalá de Henares."
    ),
    "CASO-2026-0007": (
        "Soy el dueño del Bar La Curva, junto a la M-23. Desde hace un mes aparecen dibujos en "
        "servilletas y en la pared del baño: una espiral rota. Algunos clientes se quejan; "
        "no sé si es broma o algo más serio.\n\n"
        "Adjunto fotos y ticket de caja con hora."
    ),
    "CASO-2026-0008": (
        "Representamos una clínica privada en Madrid. Tenemos indicios de accesos no autorizados "
        "a historiales médicos. Se necesita prueba discreta y trazabilidad."
    ),
    "CASO-2026-0009": (
        "Soy mayor y vivo sola en Getafe. Mi gato lleva una noche sin volver; estoy angustiada. "
        "Puedo pagar poco pero necesito ayuda."
    ),
    "CASO-2026-0010": (
        "Me están siguiendo. Necesito ayuda cuanto antes. No quiero dar mi número; "
        "solo contacto por este correo. Madrid."
    ),
    "CASO-2026-0011": (
        "Soy Laura Gómez (ya les escribí antes). El socio del que les hablé borra correos y papeles. "
        "Necesito ampliar el encargo con urgencia."
    ),
    "CASO-2026-0012": (
        "Soy la madre del joven que desapareció (ya trabajamos con ustedes). En las noticias "
        "apareció un accidente cerca de la M-23 y alguien escribió en redes «nos veremos en la curva». "
        "Es la misma frase que en una nota anónima en casa antes de que mi hijo desapareciera."
    ),
    "CASO-2026-0013": (
        "Empresa de transporte en Madrid. Alguien manipula registros GPS de flota; queremos "
        "saber quién accede y desde dónde. Presupuesto amplio, tiempo limitado."
    ),
    "CASO-2026-0014": (
        "Profesora en Alcalá. Desde hace dos semanas dibujan una espiral rota en la puerta del "
        "instituto junto a la palabra «curva». Hay padres preocupados.\n\n"
        "Adjunto foto y un fotograma CCTV borroso."
    ),
    "CASO-2026-0015": (
        "Un empleado no aparece tras un turno de noche en Getafe. La empresa quiere "
        "descartar fuga o incidente antes de comunicar a familia."
    ),
    "CASO-2026-0016": (
        "Testigo clave: afirma haber visto al sospechoso en sitio y hora concretos; "
        "datos para contrastar con otras declaraciones."
    ),
    "CASO-2026-0017": (
        "Madrid. Robo interno de documentos reservados; sospecha de cadena de accesos "
        "en archivos físicos y digitales."
    ),
    "CASO-2026-0018": (
        "Acoso vecinal en Alcalá; presupuesto bajo. Solicitud exprés con poco margen económico."
    ),
    "CASO-2026-0019": (
        "Tercera víctima con rutina conectada a la M-23 y patrones horarios similares. "
        "Familia pide revisión lateral sin interferir con investigación oficial."
    ),
    "CASO-2026-0020": (
        "Documento interno sitúa de forma recurrente al mismo interviniente en tres incidentes. "
        "Necesitamos validación antes de escalada interna."
    ),
    "CASO-2026-0021": (
        "Seguimiento prolongado de empleado sospechoso de filtración; coordinación con caso corporativo previo."
    ),
}

# Cuerpos de correo por email_id (entrantes).
EMAIL_BODY_BY_ID: dict[str, str] = {
    "MAIL-0001": CASE_NARRATIVE_BODY["CASO-2026-0001"],
    "MAIL-0002": CASE_NARRATIVE_BODY["CASO-2026-0002"],
    "MAIL-0003": CASE_NARRATIVE_BODY["CASO-2026-0003"],
    "MAIL-0004": (
        "Estimada cliente,\n\n"
        "Confirmamos cita con el despacho según acuerdo telefónico. Quedamos a la espera de documentación adicional si fuera necesaria.\n\n"
        "Un saludo,\nDespacho Ortega"
    ),
    "MAIL-0005": CASE_NARRATIVE_BODY["CASO-2026-0004"],
    "MAIL-0006": CASE_NARRATIVE_BODY["CASO-2026-0005"],
    "MAIL-0007": CASE_NARRATIVE_BODY["CASO-2026-0006"],
    "MAIL-0008": "Gracias por atenderme ayer por teléfono. Quedo a la espera de instrucciones.",
    "MAIL-0009": CASE_NARRATIVE_BODY["CASO-2026-0007"],
    "MAIL-0010": CASE_NARRATIVE_BODY["CASO-2026-0008"],
    "MAIL-0011": CASE_NARRATIVE_BODY["CASO-2026-0009"],
    "MAIL-0012": CASE_NARRATIVE_BODY["CASO-2026-0010"],
    "MAIL-0013": CASE_NARRATIVE_BODY["CASO-2026-0011"],
    "MAIL-0014": CASE_NARRATIVE_BODY["CASO-2026-0012"],
    "MAIL-0015": CASE_NARRATIVE_BODY["CASO-2026-0013"],
    "MAIL-0016": CASE_NARRATIVE_BODY["CASO-2026-0014"],
    "MAIL-0017": CASE_NARRATIVE_BODY["CASO-2026-0015"],
    "MAIL-0018": (
        "Tú también miras los archivos. La curva no olvida. La espiral sigue abierta.\n\n"
        "(remitente no verificado)"
    ),
}


def _norm_value(v):
    if v is None:
        return None
    if isinstance(v, float) and v == int(v):
        return int(v)
    if isinstance(v, str):
        return v.strip()
    return v


def _sheet_to_records(ws: openpyxl.worksheet.worksheet.Worksheet, first_data_row: int = 3) -> list[dict]:
    rows = list(ws.iter_rows(values_only=True))
    if len(rows) < 2:
        return []
    header = rows[1]  # fila 2 en Excel: cabeceras
    keys: list[str | None] = list(header)
    out: list[dict] = []
    for r in rows[first_data_row - 1 :]:
        if not r or all(x is None for x in r):
            continue
        d: dict = {}
        for i, key in enumerate(keys):
            if key is None or str(key).strip() == "":
                continue
            k = str(key).strip()
            d[k] = _norm_value(r[i] if i < len(r) else None)
        # fila vacía de datos
        if not any(v not in (None, "") for v in d.values()):
            continue
        out.append(d)
    return out


def _boolish(v) -> bool:
    if v is True or v is False:
        return bool(v)
    if isinstance(v, str):
        return v.strip().lower() in ("1", "true", "sí", "si", "yes")
    return bool(v)


def _postprocess_cases(records: list[dict]) -> list[dict]:
    for row in records:
        cid = row.get("case_id")
        if cid and cid in CASE_EXTRA_CONTACT:
            row["client_phone"] = CASE_EXTRA_CONTACT[cid]["telefono"]
            row["client_email"] = CASE_EXTRA_CONTACT[cid]["email"]
        if cid and cid in CASE_NARRATIVE_BODY:
            row["narrative_body"] = CASE_NARRATIVE_BODY[cid]
        for k in ("can_archive_personal", "is_metacase"):
            if k in row and row[k] is not None:
                row[k] = _boolish(row[k])
        if "budget_eur" in row and row["budget_eur"] is not None:
            try:
                row["budget_eur"] = float(row["budget_eur"])
            except (TypeError, ValueError):
                pass
        if "slot_order" in row and row["slot_order"] is not None:
            try:
                row["slot_order"] = int(row["slot_order"])
            except (TypeError, ValueError):
                pass
    return records


def _postprocess_emails(records: list[dict]) -> list[dict]:
    for row in records:
        eid = row.get("email_id")
        if eid in EMAIL_BODY_BY_ID:
            row["body"] = EMAIL_BODY_BY_ID[eid]
        else:
            purpose = row.get("purpose") or ""
            subj = row.get("subject") or ""
            notes = row.get("notes") or ""
            row["body"] = f"{purpose}\n\n{notes}".strip() or subj
        for k in ("requires_player_reply", "is_metacase"):
            if k in row and row[k] is not None:
                row[k] = _boolish(row[k])
    return records


def _postprocess_calls(records: list[dict]) -> list[dict]:
    for row in records:
        for k in ("must_happen", "answer_required", "is_metacase"):
            if k in row and row[k] is not None:
                row[k] = _boolish(row[k])
    return records


def _postprocess_story_days(records: list[dict]) -> list[dict]:
    for row in records:
        for k in (
            "day_number",
            "fixed_cases_count",
            "fixed_emails_count",
            "fixed_calls_count",
            "fixed_appointments_count",
        ):
            if k in row and row[k] is not None:
                try:
                    row[k] = int(row[k])  # type: ignore[arg-type]
                except (TypeError, ValueError):
                    pass
    return records


def _postprocess_rules(records: list[dict]) -> list[dict]:
    for row in records:
        for k in ("day_start", "day_end"):
            if k in row and row[k] is not None:
                try:
                    row[k] = int(row[k])  # type: ignore[arg-type]
                except (TypeError, ValueError):
                    pass
        if "player_visible" in row and row["player_visible"] is not None:
            row["player_visible"] = _boolish(row["player_visible"])
    return records


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--xlsx",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "el_despacho_story_bible.xlsx",
    )
    ap.add_argument(
        "--xlsx-alt",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "el_despacho_story_bible (1).xlsx",
    )
    ap.add_argument("--out", type=Path, default=Path(__file__).resolve().parent.parent / "data")
    args = ap.parse_args()
    src = args.xlsx if args.xlsx.is_file() else args.xlsx_alt
    if not src.is_file():
        raise SystemExit(f"No se encontró el xlsx: {args.xlsx} ni {args.xlsx_alt}")

    wb = openpyxl.load_workbook(src, data_only=True)
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)

    def dump(name: str, filename: str, post=None):
        records = _sheet_to_records(wb[name])
        if post:
            records = post(records)
        (out / filename).write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Wrote {len(records)} -> {out / filename}")

    dump("story_days", "story_days.json", _postprocess_story_days)
    dump("cases_fixed", "cases_fixed.json", _postprocess_cases)
    dump("emails_fixed", "emails_fixed.json", _postprocess_emails)
    dump("calls_fixed", "calls_fixed.json", _postprocess_calls)
    dump("office_rules", "office_rules.json", _postprocess_rules)
    dump("appointments_fixed", "appointments_fixed.json")
    dump("npcs", "npcs.json")

    print("Listo. UTF-8, ejecutar de nuevo si cambia el Excel.")


if __name__ == "__main__":
    main()
