#!/bin/bash
# ==============================================================================
# APEX Export Script
# Exports an APEX application to SQL files for version control
# Uses SQLcl saved connections (same as MCP SQLcl)
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

# Find SQLcl - check PATH first, then Homebrew Caskroom
if command -v sql &> /dev/null; then
    SQL_CMD="$(command -v sql)"
elif [ -d "/opt/homebrew/Caskroom/sqlcl" ]; then
    SQL_CMD="$(find /opt/homebrew/Caskroom/sqlcl -name 'sql' -type f -path '*/bin/*' 2>/dev/null | head -1)"
else
    SQL_CMD=""
fi

# Helper function to check SQLcl availability
check_sqlcl_available() {
    if [ -z "$SQL_CMD" ]; then
        echo -e "${RED}Error: SQLcl not found. Run: brew install --cask sqlcl${NC}"
        echo -e "${YELLOW}Then add to PATH: export PATH=\$PATH:/opt/homebrew/Caskroom/sqlcl/*/sqlcl/bin${NC}"
        exit 1
    fi
    if ! command -v "$SQL_CMD" &> /dev/null && [ ! -x "$SQL_CMD" ]; then
        echo -e "${RED}Error: SQLcl not found or not executable: ${SQL_CMD}${NC}"
        exit 1
    fi
}

# Default values
APP_ID="${APEX_APP_ID:-102}"
SPLIT="Y"
OUTPUT_DIR="${BASE_DIR}/apex/f${APP_ID}"
CONNECTION_NAME="${DB_CONNECTION_NAME:-USCIS_APP}"

show_help() {
    echo "Usage: $(basename "$0") [APP_ID] [OPTIONS]"
    echo ""
    echo "Exports an APEX application to SQL files using SQLcl saved connections."
    echo ""
    echo "Arguments:"
    echo "  APP_ID              APEX Application ID (default: 102)"
    echo ""
    echo "Options:"
    echo "  --split             Split into individual component files (default)"
    echo "  --no-split          Export as single file"
    echo "  --connection NAME   SQLcl saved connection name (default: USCIS_APP)"
    echo "  --list-connections  List available SQLcl saved connections"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") 102"
    echo "  $(basename "$0") 102 --connection USCIS_APP"
    echo "  $(basename "$0") --list-connections"
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
        --split)
            SPLIT="Y"
            shift
            ;;
        --no-split)
            SPLIT="N"
            shift
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
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                APP_ID="$1"
                OUTPUT_DIR="${BASE_DIR}/apex/f${APP_ID}"
            fi
            shift
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       APEX Application Export          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  Application ID:  ${GREEN}${APP_ID}${NC}"
echo -e "  Connection:      ${GREEN}${CONNECTION_NAME}${NC}"
echo -e "  Output:          ${GREEN}${OUTPUT_DIR}${NC}"
echo ""

# Check for SQLcl
check_sqlcl_available
echo -e "  SQLcl:           ${GREEN}${SQL_CMD}${NC}"
echo ""

# Export to temp dir then move
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT
cd "$WORK_DIR"

echo -e "${YELLOW}Exporting application ${APP_ID}...${NC}"

if [ "$SPLIT" = "Y" ]; then
    APEX_CMD="apex export -applicationid ${APP_ID} -split"
else
    APEX_CMD="apex export -applicationid ${APP_ID}"
fi

"$SQL_CMD" /NOLOG <<EOSQL
conn -name ${CONNECTION_NAME}
${APEX_CMD}
EXIT
EOSQL

if [ -d "$WORK_DIR/f${APP_ID}" ]; then
    mkdir -p "$(dirname "$OUTPUT_DIR")"
    rm -rf "$OUTPUT_DIR"
    mv "$WORK_DIR/f${APP_ID}" "$OUTPUT_DIR"
    
    echo -e "${GREEN}Export completed!${NC}"
    echo ""
    FILE_COUNT=$(find "$OUTPUT_DIR" -name "*.sql" -type f | wc -l | tr -d ' ')
    echo -e "  SQL files: ${GREEN}${FILE_COUNT}${NC}"
    echo ""
    echo -e "${BLUE}Page files:${NC}"
    ls "$OUTPUT_DIR/application/pages/" 2>/dev/null || echo "  (none)"
else
    echo -e "${RED}Export failed${NC}"
    exit 1
fi
