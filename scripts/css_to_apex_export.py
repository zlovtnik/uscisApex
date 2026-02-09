#!/usr/bin/env python3
"""
Convert a CSS (or any text) file into the APEX hex-encoded export SQL format.

Usage:
    python3 scripts/css_to_apex_export.py \
        shared_components/files/app-styles.css \
        apex/f102/application/shared_components/files/app_styles_css.sql \
        app-styles.css

Produces a SQL file compatible with `make upload` / upload_static_import.sql.
"""

import sys
import os
import re
import hashlib
import textwrap

# ── Configuration ──────────────────────────────────────────────
CHUNK_SIZE = 100          # 100 raw bytes → 200 hex chars per line
VERSION    = "2024.11.30"
RELEASE    = "24.2.13"
WS_ID      = 13027568242155993
APP_ID     = 102
OWNER      = "USCIS_APP"

# The p_id values used in the APEX export (one per file slot).
# These MUST match the ids already in the export, otherwise APEX
# will create duplicates.  Read from existing SQL if possible.
FILE_IDS = {
    "app-styles.css":     13063284063853025,   # root-level slot
    "css/app-styles.css": 13223867759128839,   # css/ slot
}


def hex_encode(data: bytes) -> list[str]:
    """Split binary data into hex-encoded chunks."""
    hex_str = data.hex().upper()
    return textwrap.wrap(hex_str, CHUNK_SIZE * 2)


def extract_file_id(existing_sql_path: str, default_id: int) -> int:
    """Try to read the p_id from an existing export SQL file."""
    try:
        with open(existing_sql_path, "r") as f:
            for line in f:
                if "p_id=>wwv_flow_imp.id(" in line:
                    start = line.index("p_id=>wwv_flow_imp.id(") + len("p_id=>wwv_flow_imp.id(")
                    end = line.index(")", start)
                    return int(line[start:end])
    except Exception:
        pass
    return default_id


def generate_sql(
    css_bytes: bytes,
    file_name: str,
    prompt_label: str,
    file_id: int,
) -> str:
    chunks = hex_encode(css_bytes)
    mime = "text/css" if file_name.endswith(".css") else "application/javascript"

    lines = []
    lines.append(f"prompt --application/shared_components/files/{prompt_label}")
    lines.append("begin")
    lines.append("--   Manifest")
    lines.append(f"--     APP STATIC FILES: {APP_ID}")
    lines.append("--   Manifest End")
    lines.append("wwv_flow_imp.component_begin (")
    lines.append(f" p_version_yyyy_mm_dd=>'{VERSION}'")
    lines.append(f",p_release=>'{RELEASE}'")
    lines.append(f",p_default_workspace_id=>{WS_ID}")
    lines.append(f",p_default_application_id=>{APP_ID}")
    lines.append(",p_default_id_offset=>0")
    lines.append(f",p_default_owner=>'{OWNER}'")
    lines.append(");")
    lines.append("wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;")

    for i, chunk in enumerate(chunks, start=1):
        lines.append(f"wwv_flow_imp.g_varchar2_table({i}) := '{chunk}';")

    # Validate file_name to prevent SQL injection in generated SQL
    if not re.match(r'^[A-Za-z0-9/_.-]+$', file_name):
        raise ValueError(
            f"Unsafe file_name '{file_name}': only [A-Za-z0-9/_.-] characters are allowed"
        )

    lines.append("wwv_flow_imp_shared.create_app_static_file(")
    lines.append(f" p_id=>wwv_flow_imp.id({file_id})")
    lines.append(f",p_file_name=>'{file_name}'")
    lines.append(f",p_mime_type=>'{mime}'")
    lines.append(",p_file_charset=>'utf-8'")
    lines.append(",p_file_content => wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)")
    lines.append(");")
    lines.append("wwv_flow_imp.component_end;")
    lines.append("end;")
    lines.append("/")
    lines.append("")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <source-file> <output-sql> <apex-file-name>")
        print(f"Example: {sys.argv[0]} shared_components/files/app-styles.css "
              f"apex/f102/application/shared_components/files/app_styles_css.sql "
              f"app-styles.css")
        sys.exit(1)

    src_path   = sys.argv[1]
    out_path   = sys.argv[2]
    apex_name  = sys.argv[3]   # e.g. "app-styles.css" or "css/app-styles.css"

    with open(src_path, "rb") as f:
        css_bytes = f.read()

    # Determine file id from existing export or known map.
    # Raise an error for unknown file names rather than using a magic number.
    if apex_name in FILE_IDS:
        default_id = FILE_IDS[apex_name]
    else:
        # Deterministic fallback: derive a stable ID from the name so repeated
        # runs produce the same value, but warn the developer.
        h = hashlib.sha256(apex_name.encode()).hexdigest()
        default_id = int(h[:15], 16)  # 60-bit int — fits APEX ID range
        print(f"⚠  WARNING: '{apex_name}' not in FILE_IDS — using derived ID {default_id}."
              f" Add it to FILE_IDS for a stable, conflict-free mapping.",
              file=sys.stderr)
    file_id = extract_file_id(out_path, default_id)

    # Prompt label = file_name with / and . and - replaced
    prompt_label = apex_name.replace("/", "_").replace(".", "_").replace("-", "_")

    sql = generate_sql(css_bytes, apex_name, prompt_label, file_id)

    dir_name = os.path.dirname(out_path)
    if dir_name:
        os.makedirs(dir_name, exist_ok=True)
    with open(out_path, "w") as f:
        f.write(sql)

    chunks = len(hex_encode(css_bytes))
    print(f"✓ Generated {out_path}")
    print(f"  Source: {src_path} ({len(css_bytes):,} bytes)")
    print(f"  APEX file name: {apex_name}")
    print(f"  Hex chunks: {chunks}")


if __name__ == "__main__":
    main()
