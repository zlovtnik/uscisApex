#!/bin/bash
# ==============================================================================
# Upload Static Files Script
# Re-imports APEX static files using the official import mechanism.
# This avoids the ORA-20987 "Runtime API Usage" block in APEX 24.2.
#
# How it works:
#   1. Calls wwv_flow_imp.import_begin() to establish import context
#   2. Removes existing non-icon static files
#   3. Re-imports files from the exported SQL in apex/f102/.../files/
#   4. Calls wwv_flow_imp.import_end() to finalize
#
# Workflow:
#   Edit CSS/JS in APEX App Builder → make export → make upload
#   Or edit exported SQL files directly → make upload
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
if [ -f "$BASE_DIR/apex.env.local" ]; then
    source "$BASE_DIR/apex.env.local"
elif [ -f "$BASE_DIR/apex.env" ]; then
    source "$BASE_DIR/apex.env"
fi

# Find SQLcl - check PATH first, then Homebrew Caskroom, then SQL Developer
if command -v sql &> /dev/null; then
    SQL_CMD="$(command -v sql)"
elif [ -d "/opt/homebrew/Caskroom/sqlcl" ]; then
    SQL_CMD="$(find /opt/homebrew/Caskroom/sqlcl -name 'sql' -type f -path '*/bin/*' 2>/dev/null | head -1)"
elif [ -f "/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin/sql" ]; then
    SQL_CMD="/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin/sql"
else
    SQL_CMD=""
fi

# Helper function to check SQLcl availability
check_sqlcl_available() {
    if [ -z "$SQL_CMD" ]; then
        echo -e "${RED}Error: SQLcl not found.${NC}"
        echo -e "${YELLOW}Try one of these:${NC}"
        echo -e "  brew install --cask sqlcl"
        echo -e "  export PATH=\$PATH:/opt/homebrew/Caskroom/sqlcl/*/sqlcl/bin"
        echo -e "  export PATH=\$PATH:/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin"
        exit 1
    fi
    if ! command -v "$SQL_CMD" &> /dev/null && [ ! -x "$SQL_CMD" ]; then
        echo -e "${RED}Error: SQLcl not found or not executable: ${SQL_CMD}${NC}"
        exit 1
    fi
}

# Default values
APP_ID="${APEX_APP_ID:-102}"
CONNECTION_NAME="ADMIN"
SQL_SCRIPT="${SCRIPT_DIR}/upload_static_import.sql"

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Re-imports APEX static files (CSS/JS) using the official import mechanism."
    echo "This script reads the exported SQL files from apex/f102/ and re-imports them."
    echo ""
    echo "Options:"
    echo "  --app-id ID         APEX Application ID (default: 102)"
    echo "  --connection NAME   SQLcl saved connection name (default: ADMIN)"
    echo "  --list-connections  List available SQLcl saved connections"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")"
    echo "  $(basename "$0") --app-id 102"
    echo "  $(basename "$0") --connection USCIS_APP"
    exit 0
}

list_connections() {
    check_sqlcl_available
    echo -e "${BLUE}Available SQLcl saved connections:${NC}"
    "$SQL_CMD" /NOLOG <<EOF
connmgr list
exit
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --app-id)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --app-id requires a numeric argument${NC}"
                show_help
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: --app-id must be a non-negative integer, got: $2${NC}"
                exit 1
            fi
            APP_ID="$2"
            shift 2
            ;;
        --connection)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --connection requires a connection name argument${NC}"
                show_help
            fi
            CONNECTION_NAME="$2"
            shift 2
            ;;
        --list-connections)
            list_connections
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Upload Static Files (Import Mode)     ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  Application ID:  ${GREEN}${APP_ID}${NC}"
echo -e "  Connection:      ${GREEN}${CONNECTION_NAME}${NC}"
echo -e "  SQL Script:      ${GREEN}${SQL_SCRIPT}${NC}"
echo ""

# Check for SQLcl
check_sqlcl_available
echo -e "  SQLcl:           ${GREEN}${SQL_CMD}${NC}"
echo ""

# Check SQL script exists
if [ ! -f "$SQL_SCRIPT" ]; then
    echo -e "${RED}Error: SQL script not found: ${SQL_SCRIPT}${NC}"
    exit 1
fi

# Verify exported static files exist
STATIC_FILES_DIR="$BASE_DIR/apex/f${APP_ID}/application/shared_components/files"
if [ ! -d "$STATIC_FILES_DIR" ]; then
    echo -e "${RED}Error: Exported static files not found at:${NC}"
    echo -e "${RED}  ${STATIC_FILES_DIR}${NC}"
    echo -e "${YELLOW}Run 'make export' first to export the APEX application.${NC}"
    exit 1
fi

FILE_COUNT=$(find "$STATIC_FILES_DIR" -name '*.sql' | wc -l | tr -d ' ')
echo -e "  Static files:    ${GREEN}${FILE_COUNT} SQL file(s) in export${NC}"
echo ""

echo -e "${YELLOW}Uploading static files to application ${APP_ID}...${NC}"
echo ""

# Run the import-format SQL script via SQLcl.
# The script uses wwv_flow_imp.import_begin/import_end (the official
# APEX import mechanism) to bypass Runtime API Usage restrictions.
set +e
"$SQL_CMD" /NOLOG <<EOSQL
conn -name "${CONNECTION_NAME}"
@"${SQL_SCRIPT}"
exit
EOSQL
SQLCL_EXIT_CODE=$?
set -e

if [ $SQLCL_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Static files uploaded successfully!${NC}"
    echo -e "${YELLOW}Clear browser cache and refresh your APEX application.${NC}"
else
    echo ""
    echo -e "${RED}Upload failed (exit code: ${SQLCL_EXIT_CODE})${NC}"
    echo -e "${YELLOW}Check the output above for errors.${NC}"
    exit 1
fi
