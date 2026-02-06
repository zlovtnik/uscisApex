-- ============================================================
-- USCIS Case Tracker - Master Installation Script
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: master.sql
-- Purpose: Orchestrates execution of all database scripts
--
-- PREREQUISITES:
--   1. Run as USCIS_APP user (or your application schema)
--   2. Ensure user has quota on tablespace:
--      ALTER USER uscis_app QUOTA UNLIMITED ON data;
--   3. For full encryption support, run as DBA:
--      GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP;
--
-- USAGE (connect interactively - never embed passwords):
--   sqlplus uscis_app@db
--   SQL> @master.sql
--
--   From SQL Developer:
--     Open this file and run as script (F5)
--
-- INSTALLATION ORDER:
--   Step 1: Core DB objects (tables, views, triggers, seed data)
--   Step 1b: Schema fix (add missing columns, recreate views)
--   Step 2: PL/SQL packages (01-09, in dependency order)
--   Step 3: Template Components (static files + shared components)
--   Step 4: Static Application Files
--   Step 5: APEX plugin settings
--   Step 6: Stress test seed data (optional, for testing)
--   Step 7: Validation & recompilation
--   Step 8: Summary
-- ============================================================

SET ECHO ON
SET TIMING ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET SCAN OFF

PROMPT ============================================================
PROMPT  USCIS Case Tracker - Master Installation
PROMPT  Started:
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS install_started FROM dual;
PROMPT ============================================================

PROMPT
PROMPT Current schema:
SELECT USER AS schema_user FROM dual;

PROMPT
PROMPT Database version:
SELECT banner FROM v$version WHERE ROWNUM = 1;

-- ============================================================
-- STEP 1: Core Database Objects (Tables, Views, Triggers, Seed)
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 1: Core Database Objects (Tables, Views, Config)
PROMPT ============================================================
PROMPT

@@install_all_v2.sql

-- ============================================================
-- STEP 1b: Schema Fix (add missing columns, recreate views)
-- ============================================================
-- Safe for fresh installs (idempotent) and existing databases
-- that are missing check_frequency / notifications_enabled.
PROMPT
PROMPT ============================================================
PROMPT  STEP 1b: Schema Fix (missing columns + view rebuild)
PROMPT ============================================================
PROMPT

@@scripts/fix_missing_columns.sql

-- ============================================================
-- STEP 2: PL/SQL Packages (in dependency order)
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 2: PL/SQL Packages (in dependency order)
PROMPT ============================================================
PROMPT

PROMPT [2.1] Installing 01_uscis_types_pkg.sql (Type definitions)...
@@packages/01_uscis_types_pkg.sql

PROMPT [2.2] Installing 02_uscis_util_pkg.sql (Utility functions)...
@@packages/02_uscis_util_pkg.sql

PROMPT [2.3] Installing 03_uscis_audit_pkg.sql (Audit logging)...
@@packages/03_uscis_audit_pkg.sql

PROMPT [2.4] Installing 04_uscis_case_pkg.sql (Core CRUD operations)...
@@packages/04_uscis_case_pkg.sql

PROMPT [2.5] Installing 05_uscis_oauth_pkg.sql (OAuth2 token management)...
@@packages/05_uscis_oauth_pkg.sql

PROMPT [2.6] Installing 06_uscis_api_pkg.sql (USCIS API integration)...
@@packages/06_uscis_api_pkg.sql

PROMPT [2.7] Installing 07_uscis_scheduler_pkg.sql (Background jobs)...
@@packages/07_uscis_scheduler_pkg.sql

PROMPT [2.8] Installing 08_uscis_export_pkg.sql (Import/Export utilities)...
@@packages/08_uscis_export_pkg.sql

PROMPT [2.9] Installing 09_uscis_template_components_pkg.sql (Template Component logic)...
@@packages/09_uscis_template_components_pkg.sql

-- ============================================================
-- STEP 3: Template Components (Static Files + Shared Components)
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 3: Template Components (Static Files + Shared Components)
PROMPT ============================================================
PROMPT

PROMPT [3.1] Uploading Template Component static files (CSS + JS)...
@@scripts/upload_template_component_files.sql

PROMPT [3.2] Installing shared component definitions...
@@shared_components/template_components.sql

PROMPT [3.3] Applying Template Component page instructions...
@@scripts/apply_template_components.sql

-- ============================================================
-- STEP 4: Static Application Files
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 4: Static Application Files
PROMPT ============================================================
PROMPT

PROMPT [4.1] Uploading static files...
@@scripts/upload_static_files.sql

-- ============================================================
-- STEP 5: APEX Plugin Settings
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 5: APEX Plugin Settings
PROMPT ============================================================
PROMPT

@@plugin_settings.sql

-- ============================================================
-- STEP 6: Stress Test Seed Data (optional)
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 6: Stress Test Seed Data (~500 cases for testing)
PROMPT ============================================================
PROMPT

@@scripts/seed_stress_test_data.sql

-- ============================================================
-- STEP 7: Validation & Recompilation
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 7: Validation & Recompilation
PROMPT ============================================================
PROMPT

PROMPT Checking for invalid objects...
SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID'
  AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE', 'VIEW', 'TRIGGER', 'TYPE')
ORDER BY object_type, object_name;

PROMPT
PROMPT Attempting to recompile any invalid objects...
BEGIN
    FOR obj IN (
        SELECT object_name, object_type
        FROM user_objects
        WHERE status = 'INVALID'
          AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE', 'VIEW', 'TRIGGER', 'TYPE')
        ORDER BY
            CASE object_type
                WHEN 'TYPE' THEN 1
                WHEN 'PACKAGE' THEN 2
                WHEN 'PACKAGE BODY' THEN 3
                WHEN 'FUNCTION' THEN 4
                WHEN 'PROCEDURE' THEN 5
                WHEN 'VIEW' THEN 6
                WHEN 'TRIGGER' THEN 7
                ELSE 8
            END
    ) LOOP
        BEGIN
            IF obj.object_type = 'PACKAGE BODY' THEN
                EXECUTE IMMEDIATE 'ALTER PACKAGE ' ||
                    DBMS_ASSERT.ENQUOTE_NAME(obj.object_name, FALSE) || ' COMPILE BODY';
            ELSE
                EXECUTE IMMEDIATE 'ALTER ' || obj.object_type || ' ' ||
                    DBMS_ASSERT.ENQUOTE_NAME(obj.object_name, FALSE) || ' COMPILE';
            END IF;
            DBMS_OUTPUT.PUT_LINE('Compiled: ' || obj.object_type || ' ' || obj.object_name);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Failed to compile ' || obj.object_type || ' ' || obj.object_name || ': ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- ============================================================
-- STEP 8: Installation Summary
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  STEP 8: Installation Summary
PROMPT ============================================================
PROMPT

PROMPT Tables:
SELECT COUNT(*) AS table_count FROM user_tables
WHERE table_name IN ('CASE_HISTORY', 'STATUS_UPDATES', 'OAUTH_TOKENS',
                     'API_RATE_LIMITER', 'CASE_AUDIT_LOG', 'SCHEDULER_CONFIG',
                     'CASE_AUDIT_LOG_ARCHIVE');

PROMPT Views:
SELECT COUNT(*) AS view_count FROM user_views WHERE view_name LIKE 'V_%';

PROMPT Packages (spec):
SELECT COUNT(*) AS package_count FROM user_objects
WHERE object_type = 'PACKAGE' AND object_name LIKE 'USCIS_%';

PROMPT Package Bodies:
SELECT COUNT(*) AS package_body_count FROM user_objects
WHERE object_type = 'PACKAGE BODY' AND object_name LIKE 'USCIS_%';

PROMPT Functions:
SELECT COUNT(*) AS function_count FROM user_objects
WHERE object_type = 'FUNCTION';

PROMPT Types:
SELECT COUNT(*) AS type_count FROM user_objects
WHERE object_type = 'TYPE';

PROMPT
PROMPT All objects status:
SELECT object_type, COUNT(*) AS total,
       SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) AS valid,
       SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) AS invalid
FROM user_objects
WHERE object_type IN ('TABLE', 'VIEW', 'PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE', 'TYPE', 'TRIGGER', 'INDEX')
GROUP BY object_type
ORDER BY object_type;

PROMPT
PROMPT Configuration entries:
SELECT config_key, SUBSTR(config_value, 1, 50) AS config_value
FROM scheduler_config
ORDER BY config_key;

PROMPT
PROMPT Cases loaded:
SELECT COUNT(*) AS total_cases FROM case_history;

PROMPT
PROMPT Cases by form type:
SELECT case_type, COUNT(DISTINCT receipt_number) AS case_count
FROM status_updates
GROUP BY case_type
ORDER BY case_count DESC;

PROMPT
PROMPT ============================================================
PROMPT  Installation Complete!
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS install_completed FROM dual;
PROMPT ============================================================
PROMPT
PROMPT Files executed (in order):
PROMPT   1. install_all_v2.sql              - Tables, views, triggers, base seed data
PROMPT   2. packages/01_uscis_types_pkg.sql  - Type definitions
PROMPT   3. packages/02_uscis_util_pkg.sql   - Utility functions
PROMPT   4. packages/03_uscis_audit_pkg.sql  - Audit logging
PROMPT   5. packages/04_uscis_case_pkg.sql   - Core CRUD operations
PROMPT   6. packages/05_uscis_oauth_pkg.sql  - OAuth2 token management
PROMPT   7. packages/06_uscis_api_pkg.sql    - USCIS API integration
PROMPT   8. packages/07_uscis_scheduler_pkg.sql - Background jobs
PROMPT   9. packages/08_uscis_export_pkg.sql - Import/Export utilities
PROMPT  10. packages/09_uscis_template_components_pkg.sql - Template Component logic
PROMPT  11. scripts/upload_template_component_files.sql - CSS/JS static files
PROMPT  12. shared_components/template_components.sql - Shared component definitions
PROMPT  13. scripts/apply_template_components.sql - Page patch instructions
PROMPT  14. scripts/upload_static_files.sql  - Static application files
PROMPT  15. plugin_settings.sql              - APEX plugin settings
PROMPT  16. scripts/seed_stress_test_data.sql - Stress test data (~500 cases)
PROMPT
PROMPT Manual steps remaining:
PROMPT   - Apply page patches via Page Designer (see page_patches/*.sql)
PROMPT   - Configure APEX Web Credentials for USCIS API OAuth
PROMPT   - Configure scheduler jobs if automatic status checks needed
PROMPT
PROMPT For OAuth configuration, use APEX Web Credentials:
PROMPT   Shared Components > Web Credentials > Create
PROMPT   - Name: USCIS_API_CREDENTIAL
PROMPT   - Type: OAuth2 Client Credentials
PROMPT   - Client ID: (from developer.uscis.gov)
PROMPT   - Client Secret: (from developer.uscis.gov)
PROMPT   - Token URL: https://api-int.uscis.gov/oauth/accesstoken
PROMPT
PROMPT ============================================================
