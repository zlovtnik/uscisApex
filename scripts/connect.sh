#!/bin/bash
# ==============================================================================
# Database Connection Helper
# Quick connect to the database using SQLcl
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
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

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Opens an interactive SQLcl session to your database.

Options:
  --user USERNAME     Database username (default: \$DB_USER)
  --conn STRING       Connection string (default: \$DB_CONNECTION)
  --help              Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --user admin
  $(basename "$0") --conn uscis_tracker_high

Environment Variables:
  DB_USER             Database username
  DB_PASSWORD         Database password
  DB_CONNECTION       Database connection string or TNS alias
  TNS_ADMIN           Path to wallet (for Autonomous DB)

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --user)
            if [ -z "$2" ] || [[ "$2" == --* ]]; then
                echo -e "${RED}Error: --user requires a username argument${NC}"
                show_help
            fi
            DB_USER="$2"
            shift 2
            ;;
        --conn)
            if [ -z "$2" ] || [[ "$2" == --* ]]; then
                echo -e "${RED}Error: --conn requires a connection string argument${NC}"
                show_help
            fi
            DB_CONNECTION="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Error: Unknown argument: $1${NC}"
            show_help
            ;;
    esac
done

# Check for SQLcl
if ! command -v sql &> /dev/null; then
    echo -e "${RED}Error: SQLcl (sql) is not installed${NC}"
    echo ""
    echo "Install SQLcl:"
    echo "  macOS:   brew install --cask sqlcl"
    echo "  Manual:  https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/"
    exit 1
fi

# Get credentials
if [ -z "$DB_USER" ]; then
    read -p "Database username: " DB_USER
fi

if [ -z "$DB_PASSWORD" ]; then
    read -sp "Password for $DB_USER: " DB_PASSWORD
    echo ""
fi

if [ -z "$DB_CONNECTION" ]; then
    read -p "Connection (TNS alias or connection string): " DB_CONNECTION
fi

# Set TNS_ADMIN if provided
if [ -n "$TNS_ADMIN" ]; then
    export TNS_ADMIN
    echo -e "${BLUE}Using wallet: ${TNS_ADMIN}${NC}"
fi

echo -e "${GREEN}Connecting to ${DB_CONNECTION} as ${DB_USER}...${NC}"
echo ""

# Create a temporary SQL script with the connect command
# This avoids exposing password in process list while allowing interactive session
TEMP_CONNECT=$(mktemp)
chmod 600 "$TEMP_CONNECT"
trap "rm -f '$TEMP_CONNECT'" EXIT

cat > "$TEMP_CONNECT" << EOF
CONNECT ${DB_USER}/${DB_PASSWORD}@${DB_CONNECTION}
EOF

# Start SQLcl with the connect script, then continue interactively
sql /nolog @"$TEMP_CONNECT"
