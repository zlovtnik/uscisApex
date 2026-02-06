#!/bin/bash
# ==============================================================================
# APEX Import Script
# Imports an APEX application from SQL files
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
SOURCE_DIR="${BASE_DIR}/apex/f${APP_ID}"
CONNECTION_NAME="${DB_CONNECTION_NAME:-USCIS_APP}"
OFFSET=""

show_help() {
    echo "Usage: $(basename "$0") [APP_ID] [OPTIONS]"
    echo ""
    echo "Imports an APEX application from SQL files using SQLcl saved connections."
    echo ""
    echo "Arguments:"
    echo "  APP_ID              APEX Application ID (default: 102)"
    echo ""
    echo "Options:"
    echo "  --offset ID         Install with a different application ID"
    echo "  --connection NAME   SQLcl saved connection name (default: USCIS_APP)"
    echo "  --list-connections  List available SQLcl saved connections"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") 102"
    echo "  $(basename "$0") 102 --offset 200"
    echo "  $(basename "$0") 102 --connection USCIS_APP"
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
        --offset)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --offset requires a numeric argument${NC}"
                show_help
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: --offset must be a non-negative integer, got: $2${NC}"
                exit 1
            fi
            OFFSET="$2"
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
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                APP_ID="$1"
                SOURCE_DIR="${BASE_DIR}/apex/f${APP_ID}"
            fi
            shift
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       APEX Application Import          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  Application ID:  ${GREEN}${APP_ID}${NC}"
echo -e "  Connection:      ${GREEN}${CONNECTION_NAME}${NC}"
echo -e "  Source:          ${GREEN}${SOURCE_DIR}${NC}"
if [ -n "$OFFSET" ]; then
    echo -e "  Target App ID:   ${GREEN}${OFFSET}${NC}"
fi
echo ""

# Check for SQLcl
check_sqlcl_available
echo -e "  SQLcl:           ${GREEN}${SQL_CMD}${NC}"
echo ""

# Check source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory not found: ${SOURCE_DIR}${NC}"
    echo -e "${YELLOW}Run apex-export.sh first to export the application.${NC}"
    exit 1
fi

# Check for install.sql
INSTALL_FILE="$SOURCE_DIR/install.sql"
if [ ! -f "$INSTALL_FILE" ]; then
    echo -e "${RED}Error: install.sql not found in ${SOURCE_DIR}${NC}"
    exit 1
fi

echo -e "${YELLOW}Importing application ${APP_ID}...${NC}"
echo ""

# Change to source directory so relative paths in install.sql work
cd "$SOURCE_DIR"

# Build the import command
if [ -n "$OFFSET" ]; then
    APEX_CMD="@install.sql ${OFFSET}"
else
    APEX_CMD="@install.sql"
fi

# Temporarily disable errexit to capture SQLcl exit code
set +e
"$SQL_CMD" /NOLOG <<EOSQL
conn -name ${CONNECTION_NAME}
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET ECHO ON

WHENEVER SQLERROR EXIT SQL.SQLCODE

${APEX_CMD}

SHOW ERRORS

COMMIT;
EXIT
EOSQL
SQLCL_EXIT_CODE=$?
set -e

if [ $SQLCL_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Import completed successfully!${NC}"
else
    echo ""
    echo -e "${RED}Import failed${NC}"
    exit 1
fi
