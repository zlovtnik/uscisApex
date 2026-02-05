#!/bin/bash
# ==============================================================================
# APEX Watch Script
# Watches for file changes and auto-imports to APEX
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load environment
if [ -f "$BASE_DIR/apex.env.local" ]; then
    source "$BASE_DIR/apex.env.local"
elif [ -f "$BASE_DIR/apex.env" ]; then
    source "$BASE_DIR/apex.env"
fi

# Default values
APP_ID="${APEX_APP_ID:-100}"
WATCH_DIR=""
DEBOUNCE_SECONDS=2
EXPLICIT_DIR_SET=false

# Help text
show_help() {
    cat << EOF
Usage: $(basename "$0") [APP_ID] [OPTIONS]

Watches APEX source files and auto-imports on change.
Great for rapid development - edit in VS Code, see changes immediately in APEX.

Arguments:
  APP_ID              APEX Application ID (default: 100 or \$APEX_APP_ID)

Options:
  --dir DIR           Directory to watch (default: f{APP_ID})
  --debounce SEC      Seconds to wait before import (default: 2)
  --help              Show this help message

Requirements:
  - fswatch (macOS): brew install fswatch
  - inotify-tools (Linux): apt install inotify-tools

Examples:
  $(basename "$0") 100
  $(basename "$0") 100 --dir f100/application/pages

Press Ctrl+C to stop watching.

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --dir)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --dir requires a directory path argument${NC}"
                show_help
            fi
            WATCH_DIR="$2"
            EXPLICIT_DIR_SET=true
            shift 2
            ;;
        --debounce)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --debounce requires a numeric argument${NC}"
                show_help
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: --debounce must be a non-negative integer, got: $2${NC}"
                exit 1
            fi
            DEBOUNCE_SECONDS="$2"
            shift 2
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                APP_ID="$1"
                # Only set WATCH_DIR if --dir was not explicitly provided
                if [ "$EXPLICIT_DIR_SET" = false ]; then
                    WATCH_DIR="${BASE_DIR}/f${APP_ID}"
                fi
            fi
            shift
            ;;
    esac
done

# Set default WATCH_DIR if not explicitly set
if [ -z "$WATCH_DIR" ]; then
    WATCH_DIR="${BASE_DIR}/f${APP_ID}"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           APEX File Watcher                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Application ID:  ${GREEN}${APP_ID}${NC}"
echo -e "  Watching:        ${GREEN}${WATCH_DIR}${NC}"
echo -e "  Debounce:        ${GREEN}${DEBOUNCE_SECONDS}s${NC}"
echo ""

# Check watch directory exists
if [ ! -d "$WATCH_DIR" ]; then
    echo -e "${RED}Error: Watch directory not found: ${WATCH_DIR}${NC}"
    echo ""
    echo "Run export first:"
    echo "  ./scripts/apex-export.sh ${APP_ID}"
    exit 1
fi

# Check for fswatch (macOS) or inotifywait (Linux)
if command -v fswatch &> /dev/null; then
    WATCH_CMD="fswatch"
elif command -v inotifywait &> /dev/null; then
    WATCH_CMD="inotifywait"
else
    echo -e "${RED}Error: No file watcher found${NC}"
    echo ""
    echo "Install one of:"
    echo "  macOS:  brew install fswatch"
    echo "  Linux:  apt install inotify-tools"
    exit 1
fi

echo -e "${CYAN}Watching for changes... (Ctrl+C to stop)${NC}"
echo ""

# Track last import time to debounce
LAST_IMPORT=0

do_import() {
    local CHANGED_FILE="$1"
    local NOW=$(date +%s)
    local DIFF=$((NOW - LAST_IMPORT))
    
    # Debounce: skip if we just imported
    if [ $DIFF -lt $DEBOUNCE_SECONDS ]; then
        return
    fi
    
    LAST_IMPORT=$NOW
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}File changed: ${CHANGED_FILE}${NC}"
    echo -e "${YELLOW}Importing...${NC}"
    echo ""
    
    # Determine what to import
    if [[ "$CHANGED_FILE" == *"/pages/"* ]]; then
        # Extract page number from filename
        PAGE_NUM=$(echo "$CHANGED_FILE" | grep -o 'page_[0-9]*' | grep -o '[0-9]*' | sed 's/^0*//')
        if [ -n "$PAGE_NUM" ]; then
            echo -e "${CYAN}Importing page ${PAGE_NUM}...${NC}"
            # For single page import, we'd need to parse the page file
            # For now, do full import
        fi
    fi
    
    # Run import (using environment credentials)
    if "$SCRIPT_DIR/apex-import.sh" "$APP_ID" <<< "y" 2>&1; then
        echo -e "${GREEN}✓ Import successful at $(date '+%H:%M:%S')${NC}"
    else
        echo -e "${RED}✗ Import failed${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Watching for changes...${NC}"
}

# Export function for use in subshell
export -f do_import
export SCRIPT_DIR APP_ID DEBOUNCE_SECONDS LAST_IMPORT
export RED GREEN YELLOW BLUE CYAN NC

if [ "$WATCH_CMD" = "fswatch" ]; then
    # macOS with fswatch - use process substitution to run loop in main shell
    while read -d "" CHANGED_FILE; do
        do_import "$CHANGED_FILE"
    done < <(fswatch -0 -e ".*" -i "\\.sql$" "$WATCH_DIR")
else
    # Linux with inotifywait
    while true; do
        CHANGED_FILE=$(inotifywait -q -e modify -e create --format '%w%f' -r "$WATCH_DIR" --include '\.sql$')
        do_import "$CHANGED_FILE"
    done
fi
