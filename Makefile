# USCIS Case Tracker - Oracle APEX Makefile
# Database and APEX application management

# Use bash and run all recipe lines in one shell (enables heredocs)
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -e -o pipefail -c

.PHONY: help import export upload deploy install test connect connections \
        packages-install packages-compile watch clean backup restore \
        static-list static-delete logs check-prereqs info

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

# Install packages only (01-08)
packages-install: check-sqlcl
	@echo "$(BLUE)Installing PL/SQL packages...$(NC)"
	$(SQL_CMD) -name $(CONNECTION) <<-'EOSQL'
		@packages/01_uscis_types_pkg.sql
		@packages/02_uscis_util_pkg.sql
		@packages/03_uscis_audit_pkg.sql
		@packages/04_uscis_case_pkg.sql
		@packages/05_uscis_oauth_pkg.sql
		@packages/06_uscis_api_pkg.sql
		@packages/07_uscis_scheduler_pkg.sql
		@packages/08_uscis_export_pkg.sql
		exit
	EOSQL
	@echo "$(GREEN)✓ Packages installed$(NC)"

# Recompile invalid objects
packages-compile: check-sqlcl
	@echo "$(BLUE)Recompiling invalid objects...$(NC)"
	$(SQL_CMD) -name $(CONNECTION) <<-'EOSQL'
		BEGIN
			DBMS_UTILITY.compile_schema(schema => USER, compile_all => FALSE);
		END;
		/
		SELECT object_name, object_type, status 
		FROM user_objects 
		WHERE status = 'INVALID';
		exit
	EOSQL

# Run PL/SQL unit tests (utPLSQL)
test: check-sqlcl
	@echo "$(BLUE)Running PL/SQL unit tests...$(NC)"
	$(SQL_CMD) -name $(CONNECTION) <<-'EOSQL'
		SET SERVEROUTPUT ON SIZE UNLIMITED
		exec ut.run()
		exit
	EOSQL

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
	@$(SQL_CMD) -name $(CONNECTION) -S <<-'EOSQL'
		SET PAGESIZE 100
		SET LINESIZE 120
		COLUMN file_name FORMAT A40
		COLUMN mime_type FORMAT A30
		COLUMN last_updated_on FORMAT A20
		SELECT file_name, mime_type, 
		       TO_CHAR(last_updated_on, 'YYYY-MM-DD HH24:MI') as last_updated_on
		FROM apex_application_static_files
		WHERE application_id = $(APP_ID)
		ORDER BY file_name;
		exit
	EOSQL

# Delete a static file (use: make static-delete FILE=old-file.js)
static-delete: check-sqlcl
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Usage: make static-delete FILE=filename.js$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deleting static file: $(FILE)$(NC)"
	@$(SQL_CMD) -name $(CONNECTION) <<-EOSQL
		DECLARE
			l_file_id NUMBER;
			l_workspace_id NUMBER;
		BEGIN
			SELECT workspace_id INTO l_workspace_id
			FROM apex_applications WHERE application_id = $(APP_ID);
			apex_util.set_security_group_id(l_workspace_id);
			
			SELECT application_file_id INTO l_file_id
			FROM apex_application_static_files
			WHERE application_id = $(APP_ID) AND file_name = '$(FILE)';
			
			wwv_flow_api.remove_app_static_file(p_id => l_file_id, p_flow_id => $(APP_ID));
			COMMIT;
			DBMS_OUTPUT.PUT_LINE('Deleted: $(FILE)');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('File not found: $(FILE)');
		END;
		/
		exit
	EOSQL

# ============================================================
# Utilities
# ============================================================

# View recent audit logs
logs: check-sqlcl
	@echo "$(BLUE)Recent audit log entries:$(NC)"
	@$(SQL_CMD) -name $(CONNECTION) -S <<-'EOSQL'
		SET PAGESIZE 50
		SET LINESIZE 150
		COLUMN event_time FORMAT A20
		COLUMN event_type FORMAT A15
		COLUMN receipt_number FORMAT A15
		COLUMN description FORMAT A60
		SELECT TO_CHAR(event_time, 'MM-DD HH24:MI:SS') as event_time,
		       event_type, receipt_number, 
		       SUBSTR(description, 1, 60) as description
		FROM case_audit_log
		ORDER BY event_time DESC
		FETCH FIRST 20 ROWS ONLY;
		exit
	EOSQL

# Backup database objects (export DDL)
backup: check-sqlcl
	@echo "$(BLUE)Backing up database objects...$(NC)"
	@mkdir -p backups
	@$(SQL_CMD) -name $(CONNECTION) <<-'EOSQL'
		SET LONG 1000000
		SET PAGESIZE 0
		SET LINESIZE 32767
		SET TRIMSPOOL ON
		SET FEEDBACK OFF
		SPOOL backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
		SELECT DBMS_METADATA.get_ddl(object_type, object_name)
		FROM user_objects
		WHERE object_type IN ('TABLE', 'VIEW', 'PACKAGE', 'SEQUENCE', 'TRIGGER')
		ORDER BY object_type, object_name;
		SPOOL OFF
		exit
	EOSQL
	@echo "$(GREEN)✓ Backup saved to backups/$(NC)"

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
