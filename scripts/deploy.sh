#!/bin/bash
# ==============================================================================
# Full Deployment Script
# Deploys database objects and APEX application
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
if [ -f "$BASE_DIR/apex.env.local" ]; then
    source "$BASE_DIR/apex.env.local"
elif [ -f "$BASE_DIR/apex.env" ]; then
    source "$BASE_DIR/apex.env"
fi

APP_ID="${APEX_APP_ID:-100}"
SKIP_DB=""
SKIP_APEX=""
SKIP_PACKAGES=""

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Full deployment of database objects and APEX application.

Options:
  --app-id NUM        APEX Application ID (default: 100)
  --skip-db           Skip database schema deployment
  --skip-apex         Skip APEX application deployment
  --skip-packages     Skip PL/SQL package deployment
  --db-only           Only deploy database objects
  --apex-only         Only deploy APEX application
  --help              Show this help message

Deployment Order:
  1. Database tables and views (install_all_v2.sql)
  2. PL/SQL packages (packages/*.sql)
  3. APEX application (f{APP_ID}/)

Examples:
  $(basename "$0")
  $(basename "$0") --skip-apex
  $(basename "$0") --apex-only

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
                echo -e "${RED}Error: --app-id must be a numeric application ID, got: $2${NC}"
                exit 1
            fi
            APP_ID="$2"
            shift 2
            ;;
        --skip-db)
            SKIP_DB="Y"
            shift
            ;;
        --skip-apex)
            SKIP_APEX="Y"
            shift
            ;;
        --skip-packages)
            SKIP_PACKAGES="Y"
            shift
            ;;
        --db-only)
            SKIP_APEX="Y"
            shift
            ;;
        --apex-only)
            SKIP_DB="Y"
            SKIP_PACKAGES="Y"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           USCIS Case Tracker - Full Deployment               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Deployment Plan:${NC}"
if [ -z "$SKIP_DB" ]; then
    echo -e "  ${GREEN}✓${NC} Database schema (tables, views, indexes)"
fi
if [ -z "$SKIP_PACKAGES" ]; then
    echo -e "  ${GREEN}✓${NC} PL/SQL packages"
fi
if [ -z "$SKIP_APEX" ]; then
    echo -e "  ${GREEN}✓${NC} APEX application ${APP_ID}"
fi
echo ""

# Check for SQLcl
if ! command -v sql &> /dev/null; then
    echo -e "${RED}Error: SQLcl (sql) is not installed${NC}"
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

if [ -n "$TNS_ADMIN" ]; then
    export TNS_ADMIN
fi

# Confirm
echo ""
read -p "Deploy to ${DB_CONNECTION} as ${DB_USER}? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""

# Create deployment SQL script
DEPLOY_SQL=$(mktemp)
trap "rm -f $DEPLOY_SQL" EXIT

cat > "$DEPLOY_SQL" << EOSQL
SET TERMOUT ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET DEFINE OFF

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT  USCIS Case Tracker Deployment
PROMPT  Started: $(date)
PROMPT ============================================================
PROMPT

EOSQL

# Add database schema
if [ -z "$SKIP_DB" ]; then
    if [ -f "$BASE_DIR/install_all_v2.sql" ]; then
        echo -e "${YELLOW}Adding database schema...${NC}"
        cat >> "$DEPLOY_SQL" << EOSQL
PROMPT ------------------------------------------------------------
PROMPT  Deploying Database Schema
PROMPT ------------------------------------------------------------
@"$BASE_DIR/install_all_v2.sql"
PROMPT
EOSQL
    else
        echo -e "${YELLOW}Warning: install_all_v2.sql not found, skipping schema${NC}"
    fi
fi

# Add PL/SQL packages
if [ -z "$SKIP_PACKAGES" ]; then
    if [ -d "$BASE_DIR/packages" ]; then
        echo -e "${YELLOW}Adding PL/SQL packages...${NC}"
        
        cat >> "$DEPLOY_SQL" << EOSQL
PROMPT ------------------------------------------------------------
PROMPT  Deploying PL/SQL Packages
PROMPT ------------------------------------------------------------
EOSQL

        # Sort packages by number prefix
        for pkg in $(ls "$BASE_DIR/packages"/*.sql 2>/dev/null | sort); do
            echo "PROMPT Installing: $(basename $pkg)" >> "$DEPLOY_SQL"
            echo "@\"$pkg\"" >> "$DEPLOY_SQL"
            echo "" >> "$DEPLOY_SQL"
        done
    else
        echo -e "${YELLOW}Warning: packages/ directory not found, skipping packages${NC}"
    fi
fi

# Add APEX application
if [ -z "$SKIP_APEX" ]; then
    APEX_DIR="$BASE_DIR/f${APP_ID}"
    if [ -d "$APEX_DIR" ]; then
        echo -e "${YELLOW}Adding APEX application ${APP_ID}...${NC}"
        
        # Find install file
        if [ -f "$APEX_DIR/install.sql" ]; then
            INSTALL_FILE="$APEX_DIR/install.sql"
        elif [ -f "$APEX_DIR/f${APP_ID}.sql" ]; then
            INSTALL_FILE="$APEX_DIR/f${APP_ID}.sql"
        else
            INSTALL_FILE=$(find "$APEX_DIR" -maxdepth 1 -name "*.sql" -type f | head -1)
        fi
        
        if [ -n "$INSTALL_FILE" ]; then
            cat >> "$DEPLOY_SQL" << EOSQL
PROMPT ------------------------------------------------------------
PROMPT  Deploying APEX Application ${APP_ID}
PROMPT ------------------------------------------------------------
@"$INSTALL_FILE"
PROMPT
EOSQL
        else
            echo -e "${YELLOW}Warning: No APEX install file found for app ${APP_ID} in ${APEX_DIR}${NC}" >&2
            cat >> "$DEPLOY_SQL" << EOSQL
PROMPT ------------------------------------------------------------
PROMPT  WARNING: No APEX install file found for application ${APP_ID}
PROMPT  Directory: ${APEX_DIR}
PROMPT  Skipping APEX deployment
PROMPT ------------------------------------------------------------
EOSQL
        fi
    else
        echo -e "${YELLOW}Warning: APEX directory f${APP_ID}/ not found${NC}"
        echo "Run: ./scripts/apex-export.sh ${APP_ID}"
    fi
fi

# Add completion message
cat >> "$DEPLOY_SQL" << EOSQL
PROMPT ============================================================
PROMPT  Deployment Complete: $(date)
PROMPT ============================================================

EXIT
EOSQL

# Run deployment
echo ""
echo -e "${CYAN}Running deployment...${NC}"
echo ""

# Use sql /nolog with stdin to avoid password in process list
if sql /nolog <<EOLOGIN 2>&1 | tee /tmp/deploy.log
CONNECT ${DB_USER}/${DB_PASSWORD}@${DB_CONNECTION}
@"$DEPLOY_SQL"
EOLOGIN
then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Deployment Completed Successfully!                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Log saved to: /tmp/deploy.log"
else
    echo ""
    echo -e "${RED}Deployment failed! Check /tmp/deploy.log for details.${NC}"
    exit 1
fi
