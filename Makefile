# USCIS Case Tracker - Oracle APEX Makefile
# Database and APEX application management

# Use bash (compatible with macOS default GNU Make 3.81 — no .ONESHELL)
SHELL := /bin/bash

.PHONY: help import export upload deploy install test connect connections \
        packages-install packages-compile watch clean backup restore \
        static-list static-delete logs check-prereqs info \
        css-build css-minify

# ============================================================
# Configuration (override with: make import CONNECTION=ADMIN)
# ============================================================

CONNECTION ?= USCIS_APP
APP_ID ?= 102
WORKSPACE ?= USCIS_APP
SCRIPTS_DIR := scripts

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Find SQLcl
SQL_CMD := $(shell command -v sql 2>/dev/null || \
	([ -x "/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin/sql" ] && \
	echo "/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin/sql") || \
	find /opt/homebrew/Caskroom/sqlcl -name 'sql' -type f -path '*/bin/*' 2>/dev/null | head -1)

# ============================================================
# Default Target
# ============================================================

help:
	@echo "$(BLUE)USCIS Case Tracker - Oracle APEX$(NC)"
	@echo ""
	@echo "$(YELLOW)APEX Application:$(NC)"
	@echo "  make import          Import APEX app $(APP_ID)"
	@echo "  make export          Export APEX app $(APP_ID)"
	@echo "  make upload          Upload static files (CSS/JS)"
	@echo "  make deploy          Full deploy (import + upload)"
	@echo ""
	@echo "$(YELLOW)Database:$(NC)"
	@echo "  make install         Install all packages (fresh)"
	@echo "  make packages-install  Install packages only"
	@echo "  make packages-compile  Recompile invalid objects"
	@echo "  make test            Run PL/SQL unit tests"
	@echo "  make connect         Interactive SQLcl session"
	@echo "  make connections     List saved connections"
	@echo ""
	@echo "$(YELLOW)Static Files:$(NC)"
	@echo "  make static-list     List static files in app"
	@echo "  make static-delete   Delete a static file"
	@echo "  make css-build       Concatenate CSS modules → maine-pine-v5.css"
	@echo "  make css-minify      Minify concatenated CSS (requires cssnano-cli)"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  make watch           Watch for export changes"
	@echo "  make logs            View recent audit logs"
	@echo "  make backup          Backup database objects"
	@echo "  make info            Show app/connection info"
	@echo "  make check-prereqs   Verify prerequisites"
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  CONNECTION=$(CONNECTION) APP_ID=$(APP_ID)"
	@echo "  Override: make import CONNECTION=ADMIN APP_ID=200"

# ============================================================
# Prerequisites Check
# ============================================================

check-prereqs:
	@echo "Checking prerequisites..."
	@if [ -z "$(SQL_CMD)" ]; then \
		echo "$(RED)✗ SQLcl not found$(NC)"; \
		echo "  Install with: brew install --cask sqlcl"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ SQLcl found: $(SQL_CMD)$(NC)"; \
	fi
	@if [ -f apex.env.local ]; then \
		echo "$(GREEN)✓ apex.env.local exists$(NC)"; \
	else \
		echo "$(YELLOW)⚠ apex.env.local not found - using defaults$(NC)"; \
	fi

check-sqlcl:
	@if [ -z "$(SQL_CMD)" ]; then \
		echo "$(RED)Error: SQLcl not found. Install with: brew install --cask sqlcl$(NC)"; \
		exit 1; \
	fi

# ============================================================
# APEX Application Commands
# ============================================================

# Import APEX application from SQL files
import: check-sqlcl
	@echo "$(BLUE)Importing APEX Application $(APP_ID)...$(NC)"
	cd $(SCRIPTS_DIR) && ./apex-import.sh $(APP_ID) --connection $(CONNECTION)
	@echo "$(GREEN)✓ Import complete$(NC)"

# Export APEX application to SQL files
export: check-sqlcl
	@echo "$(BLUE)Exporting APEX Application $(APP_ID)...$(NC)"
	cd $(SCRIPTS_DIR) && ./apex-export.sh $(APP_ID) --connection $(CONNECTION)
	@echo "$(GREEN)✓ Export complete$(NC)"

# Upload static files (CSS, JS)
upload: check-sqlcl
	@echo "$(BLUE)Uploading static files...$(NC)"
	cd $(SCRIPTS_DIR) && ./upload-static-files.sh --app-id $(APP_ID) --connection $(CONNECTION)
	@echo "$(GREEN)✓ Static files uploaded$(NC)"

# Full deployment: import app + upload static files
deploy: import upload
	@echo ""
	@echo "$(GREEN)✓ Deployment complete!$(NC)"
	@echo "  Clear browser cache and refresh your APEX application."

# Watch for changes in exported files (for development)
watch: check-sqlcl
	@echo "$(BLUE)Watching for APEX export changes...$(NC)"
	@if [ -f $(SCRIPTS_DIR)/apex-watch.sh ]; then \
		cd $(SCRIPTS_DIR) && ./apex-watch.sh $(APP_ID) --connection $(CONNECTION); \
	else \
		echo "Watch script not found. Use 'make export' after changes in APEX."; \
	fi

# ============================================================
# Database Commands
# ============================================================

# Full installation (tables, packages, etc.)
install: check-sqlcl
	@echo "$(BLUE)Installing database objects...$(NC)"
	$(SQL_CMD) -name $(CONNECTION) @install_all_v2.sql
	@echo "$(GREEN)✓ Installation complete$(NC)"

# Install packages only (01-10)
packages-install: check-sqlcl
	@echo "$(BLUE)Installing PL/SQL packages...$(NC)"
	$(SQL_CMD) -name $(CONNECTION) @install_packages.sql
	@echo "$(GREEN)✓ Packages installed$(NC)"

# Recompile invalid objects
packages-compile: check-sqlcl
	@echo "$(BLUE)Recompiling invalid objects...$(NC)"
	@printf '%s\n' \
		"BEGIN" \
		"  DBMS_UTILITY.compile_schema(schema => USER, compile_all => FALSE);" \
		"END;" \
		"/" \
		"SELECT object_name, object_type, status FROM user_objects WHERE status = 'INVALID';" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION)

# Run PL/SQL unit tests (utPLSQL)
test: check-sqlcl
	@echo "$(BLUE)Running PL/SQL unit tests...$(NC)"
	@printf '%s\n' \
		"SET SERVEROUTPUT ON SIZE UNLIMITED" \
		"exec ut.run()" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION)

# Interactive database connection
connect: check-sqlcl
	@echo "$(BLUE)Connecting to $(CONNECTION)...$(NC)"
	$(SQL_CMD) -name $(CONNECTION)

# List available saved connections
connections: check-sqlcl
	@echo "$(BLUE)Saved SQLcl connections:$(NC)"
	@$(SQL_CMD) /NOLOG <<< "connmgr list" 2>/dev/null || echo "Run: sql /NOLOG then 'connmgr list'"

# ============================================================
# Static Files Management
# ============================================================

# List static files in the application
static-list: check-sqlcl
	@echo "$(BLUE)Static files in Application $(APP_ID):$(NC)"
	@printf '%s\n' \
		"SET PAGESIZE 100" \
		"SET LINESIZE 120" \
		"COLUMN file_name FORMAT A40" \
		"COLUMN mime_type FORMAT A30" \
		"COLUMN last_updated_on FORMAT A20" \
		"SELECT file_name, mime_type, TO_CHAR(last_updated_on, 'YYYY-MM-DD HH24:MI') as last_updated_on FROM apex_application_static_files WHERE application_id = $(APP_ID) ORDER BY file_name;" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION) -S

# Delete a static file (use: make static-delete FILE=old-file.js)
static-delete: check-sqlcl
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Usage: make static-delete FILE=filename.js$(NC)"; \
		exit 1; \
	fi
	@# Validate FILE contains only safe characters (alphanumeric, dash, underscore, dot)
	@if echo "$(FILE)" | grep -qE '[^a-zA-Z0-9._-]'; then \
		echo "$(RED)Error: FILE contains invalid characters. Only alphanumeric, dash, underscore, and dot are allowed.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deleting static file: $(FILE)$(NC)"
	@printf '%s\n' \
		"DEFINE STATIC_FILENAME = '$(FILE)'" \
		"DECLARE" \
		"  l_file_id NUMBER;" \
		"  l_workspace_id NUMBER;" \
		"  l_filename VARCHAR2(255) := '&STATIC_FILENAME.';" \
		"BEGIN" \
		"  SELECT workspace_id INTO l_workspace_id FROM apex_applications WHERE application_id = $(APP_ID);" \
		"  apex_session.create_session(p_app_id => $(APP_ID), p_page_id => 1, p_username => 'ADMIN', p_call_post_authentication => FALSE);" \
		"  SELECT application_file_id INTO l_file_id FROM apex_application_static_files WHERE application_id = $(APP_ID) AND file_name = l_filename;" \
		"  wwv_flow_api.remove_app_static_file(p_id => l_file_id, p_flow_id => $(APP_ID));" \
		"  COMMIT;" \
		"  DBMS_OUTPUT.PUT_LINE('Deleted: ' || l_filename);" \
		"  apex_session.delete_session;" \
		"EXCEPTION" \
		"  WHEN NO_DATA_FOUND THEN" \
		"    BEGIN apex_session.delete_session; EXCEPTION WHEN OTHERS THEN NULL; END;" \
		"    DBMS_OUTPUT.PUT_LINE('File not found: ' || l_filename);" \
		"END;" \
		"/" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION)

# ============================================================
# Utilities
# ============================================================

# View recent audit logs
logs: check-sqlcl
	@echo "$(BLUE)Recent audit log entries:$(NC)"
	@printf '%s\n' \
		"SET PAGESIZE 50" \
		"SET LINESIZE 150" \
		"COLUMN event_time FORMAT A20" \
		"COLUMN event_type FORMAT A15" \
		"COLUMN receipt_number FORMAT A15" \
		"COLUMN description FORMAT A60" \
		"SELECT TO_CHAR(event_time, 'MM-DD HH24:MI:SS') as event_time, event_type, receipt_number, SUBSTR(description, 1, 60) as description FROM case_audit_log ORDER BY event_time DESC FETCH FIRST 20 ROWS ONLY;" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION) -S

# Backup database objects (export DDL)
backup: check-sqlcl
	@echo "$(BLUE)Backing up database objects...$(NC)"
	@mkdir -p backups
	@BACKUP_FILE="backups/backup_$$(date +%Y%m%d_%H%M%S).sql"; \
	printf '%s\n' \
		"SET LONG 1000000" \
		"SET PAGESIZE 0" \
		"SET LINESIZE 32767" \
		"SET TRIMSPOOL ON" \
		"SET FEEDBACK OFF" \
		"SPOOL $$BACKUP_FILE" \
		"SELECT DBMS_METADATA.get_ddl(object_type, object_name) FROM user_objects WHERE object_type IN ('TABLE', 'VIEW', 'PACKAGE', 'SEQUENCE', 'TRIGGER') ORDER BY object_type, object_name;" \
		"SPOOL OFF" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION); \
	if [ -s "$$BACKUP_FILE" ]; then \
		echo "$(GREEN)✓ Backup saved to backups/$(NC)"; \
	else \
		echo "$(RED)✗ Backup failed — file missing or empty$(NC)"; \
		exit 1; \
	fi

# Show application and connection info
info: check-sqlcl
	@echo "$(BLUE)USCIS Case Tracker - APEX Info$(NC)"
	@echo "================================"
	@echo "App ID:     $(APP_ID)"
	@echo "Connection: $(CONNECTION)"
	@echo "Workspace:  $(WORKSPACE)"
	@echo "SQLcl:      $(SQL_CMD)"
	@echo ""
	@printf '%s\n' \
		"SET HEADING OFF" \
		"SET FEEDBACK OFF" \
		"SELECT 'Database: ' || ora_database_name FROM dual;" \
		"SELECT 'Schema: ' || USER FROM dual;" \
		"SELECT 'APEX Version: ' || version_no FROM apex_release;" \
		"SELECT 'App Name: ' || application_name FROM apex_applications WHERE application_id = $(APP_ID);" \
		"exit" \
	| $(SQL_CMD) -name $(CONNECTION) -S

# Clean temporary files
clean:
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	rm -rf backups/*.sql.bak
	@echo "$(GREEN)✓ Clean complete$(NC)"

# ============================================================
# CSS Theme Build (Maine Pine v5)
# ============================================================

CSS_SRC_DIR := shared_components/files/css/maine-pine-v5
CSS_BUILD   := $(CSS_SRC_DIR)/maine-pine-v5.css
CSS_MIN     := $(CSS_SRC_DIR)/maine-pine-v5.min.css

CSS_MODULES := \
	$(CSS_SRC_DIR)/00-tokens.css \
	$(CSS_SRC_DIR)/01-foundations.css \
	$(CSS_SRC_DIR)/02-layout.css \
	$(CSS_SRC_DIR)/03-navigation.css \
	$(CSS_SRC_DIR)/04-forms.css \
	$(CSS_SRC_DIR)/05-components.css \
	$(CSS_SRC_DIR)/06-pages.css \
	$(CSS_SRC_DIR)/07-utilities.css

MODULE_COUNT := $(words $(CSS_MODULES))

# Concatenate CSS modules into a single build file
css-build: $(CSS_MODULES)
	@echo "$(BLUE)Building Maine Pine v5 CSS...$(NC)"
	@printf '/**\n * Maine Pine v5 — USCIS Case Tracker Theme\n * Build: %s | Modules: %s\n * DO NOT EDIT — edit individual modules then run: make css-build\n */\n\n' "$$(date +%Y-%m-%d)" "$(MODULE_COUNT)" > $(CSS_BUILD)
	@cat $(CSS_MODULES) >> $(CSS_BUILD)
	@echo "$(GREEN)✓ Built $(CSS_BUILD) ($$(wc -l < $(CSS_BUILD)) lines)$(NC)"

# Minify concatenated CSS (requires: npm i -g cssnano-cli)
css-minify: css-build
	@echo "$(BLUE)Minifying CSS...$(NC)"
	@if command -v cssnano >/dev/null 2>&1; then \
		cssnano $(CSS_BUILD) $(CSS_MIN); \
		echo "$(GREEN)✓ Minified → $(CSS_MIN) ($$(wc -c < $(CSS_MIN)) bytes)$(NC)"; \
	else \
		echo "$(YELLOW)⚠ cssnano not found — install with: npm i -g cssnano-cli$(NC)"; \
		echo "  Falling back to simple whitespace compression..."; \
		perl -0777 -pe 's{/\*.*?\*/}{}gs; s/^\s+//mg; s/\n{2,}/\n/g' $(CSS_BUILD) > $(CSS_MIN); \
		echo "$(GREEN)✓ Compressed → $(CSS_MIN) ($$(wc -c < $(CSS_MIN)) bytes)$(NC)"; \
	fi
