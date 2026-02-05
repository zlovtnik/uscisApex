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
-- USAGE:
--   From SQL*Plus or SQLcl:
--     @master.sql
--
--   From SQL Developer:
--     Open this file and run as script (F5)
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

PROMPT
PROMPT ============================================================
PROMPT  STEP 1: Core Database Objects (Tables, Views, Config)
PROMPT ============================================================
PROMPT

@@install_all_v2.sql

PROMPT
PROMPT ============================================================
PROMPT  STEP 2: PL/SQL Packages (in dependency order)
PROMPT ============================================================
PROMPT

PROMPT Installing 01_uscis_types_pkg.sql (Type definitions)...
@@packages/01_uscis_types_pkg.sql

PROMPT Installing 02_uscis_util_pkg.sql (Utility functions)...
@@packages/02_uscis_util_pkg.sql

PROMPT Installing 03_uscis_audit_pkg.sql (Audit logging)...
@@packages/03_uscis_audit_pkg.sql

PROMPT Installing 04_uscis_case_pkg.sql (Core CRUD operations)...
@@packages/04_uscis_case_pkg.sql

PROMPT Installing 05_uscis_oauth_pkg.sql (OAuth2 token management)...
@@packages/05_uscis_oauth_pkg.sql

PROMPT Installing 06_uscis_api_pkg.sql (USCIS API integration)...
@@packages/06_uscis_api_pkg.sql

PROMPT Installing 07_uscis_scheduler_pkg.sql (Background jobs)...
@@packages/07_uscis_scheduler_pkg.sql

PROMPT Installing 08_uscis_export_pkg.sql (Import/Export utilities)...
@@packages/08_uscis_export_pkg.sql

PROMPT
PROMPT ============================================================
PROMPT  STEP 3: Validation
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
            -- Use DBMS_ASSERT to prevent SQL injection and correct syntax for PACKAGE BODY
            IF obj.object_type = 'PACKAGE BODY' THEN
                -- PACKAGE BODY requires: ALTER PACKAGE <name> COMPILE BODY
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

PROMPT
PROMPT ============================================================
PROMPT  Installation Summary
PROMPT ============================================================
PROMPT

PROMPT Tables:
SELECT COUNT(*) AS table_count FROM user_tables 
WHERE table_name IN ('CASE_HISTORY', 'STATUS_UPDATES', 'OAUTH_TOKENS', 
                     'API_RATE_LIMITER', 'CASE_AUDIT_LOG', 'SCHEDULER_CONFIG',
                     'CASE_AUDIT_LOG_ARCHIVE');

PROMPT Views:
SELECT COUNT(*) AS view_count FROM user_views WHERE view_name LIKE 'V_%';

PROMPT Packages:
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
PROMPT Sample cases loaded:
SELECT receipt_number, case_type, current_status 
FROM v_case_current_status
ORDER BY receipt_number;

PROMPT
PROMPT ============================================================
PROMPT  Installation Complete!
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS install_completed FROM dual;
PROMPT ============================================================
PROMPT
PROMPT Next Steps:
PROMPT   1. Review any invalid objects above and fix compilation errors
PROMPT   2. Configure APEX Web Credentials for USCIS API OAuth
PROMPT   3. Set up APEX application using the installed schema
PROMPT   4. Configure scheduler jobs if automatic status checks needed
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
