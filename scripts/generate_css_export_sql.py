#!/usr/bin/env python3
"""
Generate APEX export-format SQL for a CSS static file.

Converts a CSS file to hex-encoded wwv_flow_imp.g_varchar2_table format
that can be imported via the APEX import mechanism.

Usage:
    python3 scripts/generate_css_export_sql.py \
        shared_components/files/css/maine-pine-v5/maine-pine-v5.css \
        css/maine-pine-v5.css \
        apex/f102/application/shared_components/files/css_maine_pine_v5_css.sql
"""

import sys
import os
import hashlib


def _generate_p_id(apex_file_name):
    """Derive a unique numeric p_id from the APEX file name.

    Uses a SHA-256 hash truncated to 12 decimal digits so each generated
    file gets a distinct, deterministic ID that won't clash with IDs
    assigned by the APEX builder (which start from low numbers).
    """
    digest = hashlib.sha256(apex_file_name.encode('utf-8')).hexdigest()
    # Take the first 12 hex digits and convert to a decimal integer
    return int(digest[:12], 16) % 10**12


def generate_apex_static_file_sql(css_path, apex_file_name, output_path, p_id=None):
    """Convert a CSS file to APEX export SQL format."""

    with open(css_path, 'rb') as f:
        data = f.read()

    hex_data = data.hex().upper()

    # Split into 200-char chunks (100 bytes each) — APEX export format
    chunk_size = 200
    chunks = [hex_data[i:i+chunk_size] for i in range(0, len(hex_data), chunk_size)]

    # Derive a safe SQL identifier from the file name
    sql_id = apex_file_name.replace('/', '_').replace('-', '_').replace('.', '_')

    if p_id is None:
        p_id = _generate_p_id(apex_file_name)

    lines = []
    lines.append(f"prompt --application/shared_components/files/{sql_id}")
    lines.append("begin")
    lines.append("--   Manifest")
    lines.append("--     APP STATIC FILES: 102")
    lines.append("--   Manifest End")
    lines.append("wwv_flow_imp.component_begin (")
    lines.append(" p_version_yyyy_mm_dd=>'2024.11.30'")
    lines.append(",p_release=>'24.2.13'")
    lines.append(",p_default_workspace_id=>13027568242155993")
    lines.append(",p_default_application_id=>102")
    lines.append(",p_default_id_offset=>0")
    lines.append(",p_default_owner=>'USCIS_APP'")
    lines.append(");")
    lines.append("wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;")

    for i, chunk in enumerate(chunks, 1):
        lines.append(f"wwv_flow_imp.g_varchar2_table({i}) := '{chunk}';")

    lines.append("wwv_flow_imp_shared.create_app_static_file (")
    lines.append(f" p_id=>wwv_flow_imp.id({p_id})")
    lines.append(",p_flow_id=>wwv_flow_imp.id(102)")
    # Escape single quotes for SQL string literal
    safe_apex_file_name = apex_file_name.replace("'", "''")
    lines.append(f",p_file_name=>'{safe_apex_file_name}'")
    lines.append(",p_mime_type=>'text/css'")
    lines.append(",p_file_charset=>'utf-8'")
    lines.append(",p_file_content => wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)")
    lines.append(");")
    lines.append("wwv_flow_imp.component_end;")
    lines.append("end;")
    lines.append("/")

    output_dir = os.path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Generated: {output_path}")
    print(f"  Source: {css_path} ({len(data)} bytes)")
    print(f"  APEX file name: {apex_file_name}")
    print(f"  Hex chunks: {len(chunks)}")


if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: generate_css_export_sql.py <css_file> <apex_file_name> <output_sql>")
        sys.exit(1)

    generate_apex_static_file_sql(sys.argv[1], sys.argv[2], sys.argv[3])
