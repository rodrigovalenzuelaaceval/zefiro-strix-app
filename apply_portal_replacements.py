# -*- coding: utf-8 -*-
"""
Aplica 7 reemplazos exactos sobre portal.h usando str.replace().

Convención del proyecto: no edición manual línea por línea. Cada reemplazo
verifica que el texto buscado exista exactamente; si alguno falta, se informa
cuál y NO se escribe el archivo (no se continúa a ciegas).

Uso:
    python apply_portal_replacements.py
"""

import os
import sys

FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "portal.h")

# (nombre, buscar, reemplazar). Los saltos de línea "\n" se adaptan
# automáticamente al estilo de fin de línea real del archivo (\r\n o \n).
REPLACEMENTS = [
    (
        "REEMPLAZO 1 — Google Fonts",
        '<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;1,300&family=Inconsolata:wght@300;400&display=swap" rel="stylesheet">',
        '<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">',
    ),
    (
        "REEMPLAZO 2 — Variables de fuente en :root",
        "    --mono:      'Inconsolata', monospace;\n"
        "    --serif:     'Cormorant Garamond', Georgia, serif;",
        "    --mono:      'Inter', sans-serif;\n"
        "    --serif:     'Montserrat', sans-serif;",
    ),
    (
        "REEMPLAZO 3 — Peso base del body",
        "  body {\n"
        "    background: var(--paper);\n"
        "    color: var(--ink);\n"
        "    font-family: var(--serif);\n"
        "    font-weight: 300;\n"
        "    min-height: 100vh;\n"
        "    padding-bottom: 80px;\n"
        "  }",
        "  body {\n"
        "    background: var(--paper);\n"
        "    color: var(--ink);\n"
        "    font-family: var(--mono);\n"
        "    font-weight: 400;\n"
        "    min-height: 100vh;\n"
        "    padding-bottom: 80px;\n"
        "  }",
    ),
    (
        "REEMPLAZO 4 — Título del header",
        "  .header-title {\n"
        "    font-size: 2rem;\n"
        "    font-weight: 300;",
        "  .header-title {\n"
        "    font-size: 2rem;\n"
        "    font-family: var(--serif);\n"
        "    font-weight: 800;",
    ),
    (
        "REEMPLAZO 5 — Texto del banner de navegador",
        "  .browser-banner-body {\n"
        "    font-family: var(--serif);\n"
        "    font-size: 1rem;\n"
        "    font-weight: 300;",
        "  .browser-banner-body {\n"
        "    font-family: var(--mono);\n"
        "    font-size: 1rem;\n"
        "    font-weight: 400;",
    ),
    (
        "REEMPLAZO 6 — Botón Copiar",
        "  .browser-banner-copy {\n"
        "    background: var(--orange);\n"
        "    color: white;",
        "  .browser-banner-copy {\n"
        "    background: var(--orange);\n"
        "    color: var(--ink);",
    ),
    (
        "REEMPLAZO 7 — Alineación de números del dashboard",
        "  .dash-card-value {\n"
        "    font-family: var(--mono);\n"
        "    font-size: 15px;\n"
        "    color: var(--ink);\n"
        "    font-weight: 400;\n"
        "  }",
        "  .dash-card-value {\n"
        "    font-family: var(--mono);\n"
        "    font-size: 15px;\n"
        "    color: var(--ink);\n"
        "    font-weight: 600;\n"
        "    font-variant-numeric: tabular-nums;\n"
        "  }",
    ),
]


def main() -> int:
    if not os.path.exists(FILE):
        print(f"ERROR: no existe {FILE}")
        return 1

    with open(FILE, "rb") as fh:
        raw = fh.read()

    # BOM / codificación.
    has_bom = raw.startswith(b"\xef\xbb\xbf")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")

    # Fin de línea dominante del archivo.
    eol = "\r\n" if "\r\n" in text else "\n"

    def adapt(s: str) -> str:
        # Solo las líneas "nuevas" reales del texto original se adaptan al EOL.
        return s.replace("\n", eol) if "\n" in s else s

    missing = []
    applied = []
    result = text

    for name, old, new in REPLACEMENTS:
        old_file = adapt(old)
        new_file = adapt(new)
        count = result.count(old_file)
        if count == 0:
            missing.append(name)
            continue
        result = result.replace(old_file, new_file)
        applied.append((name, count))

    if missing:
        print("ERROR: NO se aplicó ningún cambio. Textos NO encontrados:")
        for m in missing:
            print(f"  - {m}")
        print("No se escribió el archivo para no continuar a ciegas.")
        return 1

    with open(FILE, "wb") as fh:
        out = result.encode("utf-8")
        if has_bom:
            out = b"\xef\xbb\xbf" + out
        fh.write(out)

    print(f"OK: los 7 reemplazos se aplicaron sobre {os.path.basename(FILE)} (EOL={eol!r}):")
    for name, count in applied:
        print(f"  - {name}: encontrado y aplicado ({count} ocurrencia(s))")
    print(f"Tamaño original: {len(raw)} bytes -> nuevo: {len(out)} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
