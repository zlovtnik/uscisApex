-- ============================================================
-- USCIS Case Tracker - Audit Package
-- Task 1.3.8: USCIS_AUDIT_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/03_uscis_audit_pkg.sql
-- Purpose: Audit logging for all case operations
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_AUDIT_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_audit_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_AUDIT_PKG';
    
    -- ========================================================
    -- Audit Logging Procedures
    -- ========================================================
    
    -- Log an audit event (autonomous transaction)
    PROCEDURE log_event(
        p_receipt_number IN VARCHAR2,
        p_action         IN VARCHAR2,
        p_old_values     IN CLOB DEFAULT NULL,
        p_new_values     IN CLOB DEFAULT NULL,
        p_performed_by   IN VARCHAR2 DEFAULT NULL,
        p_ip_address     IN VARCHAR2 DEFAULT NULL,
        p_user_agent     IN VARCHAR2 DEFAULT NULL
    );
    
    -- Log a case insert
    PROCEDURE log_insert(
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2 DEFAULT NULL,
        p_notes          IN CLOB DEFAULT NULL
    );
    
    -- Log a case update
    PROCEDURE log_update(
        p_receipt_number IN VARCHAR2,
        p_field_name     IN VARCHAR2,
        p_old_value      IN VARCHAR2,
        p_new_value      IN VARCHAR2
    );
    
    -- Log a case delete
    PROCEDURE log_delete(
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2 DEFAULT NULL
    );
    
    -- Log a status check
    PROCEDURE log_check(
        p_receipt_number IN VARCHAR2,
        p_source         IN VARCHAR2 DEFAULT 'MANUAL',
        p_status_found   IN VARCHAR2 DEFAULT NULL
    );
    
    -- Log an export operation
    PROCEDURE log_export(
        p_case_count     IN NUMBER,
        p_format         IN VARCHAR2 DEFAULT 'JSON'
    );
    
    -- Log an import operation
    PROCEDURE log_import(
        p_case_count     IN NUMBER,
        p_source_file    IN VARCHAR2 DEFAULT NULL,
        p_error_count    IN NUMBER DEFAULT 0
    );
    
    -- ========================================================
    -- Audit Query Functions
    -- ========================================================
    
    -- Get audit history for a specific case
    FUNCTION get_case_audit(
        p_receipt_number IN VARCHAR2
    ) RETURN SYS_REFCURSOR;
    
    -- Get recent activity across all cases
    FUNCTION get_recent_activity(
        p_limit IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR;
    
    -- Get activity by user
    FUNCTION get_user_activity(
        p_user  IN VARCHAR2,
        p_limit IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR;
    
    -- Get activity by date range
    FUNCTION get_activity_by_date(
        p_start_date IN TIMESTAMP,
        p_end_date   IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_limit      IN NUMBER DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
    
    -- Count audit records
    FUNCTION count_audit_records(
        p_receipt_number IN VARCHAR2 DEFAULT NULL,
        p_action         IN VARCHAR2 DEFAULT NULL,
        p_days           IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;
    
    -- ========================================================
    -- Maintenance Procedures
    -- ========================================================
    
    -- Purge old audit records
    PROCEDURE purge_old_records(
        p_days_to_keep IN NUMBER DEFAULT NULL  -- NULL = use config
    );
    
    -- Archive audit records to a backup table
    PROCEDURE archive_records(
        p_days_old IN NUMBER DEFAULT 365
    );

END uscis_audit_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_audit_pkg AS

    -- --------------------------------------------------------
    -- log_event (main audit logging procedure)
    -- --------------------------------------------------------
    PROCEDURE log_event(
        p_receipt_number IN VARCHAR2,
        p_action         IN VARCHAR2,
        p_old_values     IN CLOB DEFAULT NULL,
        p_new_values     IN CLOB DEFAULT NULL,
        p_performed_by   IN VARCHAR2 DEFAULT NULL,
        p_ip_address     IN VARCHAR2 DEFAULT NULL,
        p_user_agent     IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_user      VARCHAR2(255);
        l_ip        VARCHAR2(45);
        l_agent     VARCHAR2(500);
    BEGIN
        -- Get context if not provided
        l_user := NVL(p_performed_by, uscis_util_pkg.get_current_user);
        l_ip := NVL(p_ip_address, uscis_util_pkg.get_client_ip);
        
        -- Try to get user agent from APEX
        BEGIN
            l_agent := NVL(p_user_agent, OWA_UTIL.get_cgi_env('HTTP_USER_AGENT'));
        EXCEPTION
            WHEN OTHERS THEN
                l_agent := p_user_agent;
        END;
        
        INSERT INTO case_audit_log (
            receipt_number,
            action,
            old_values,
            new_values,
            performed_by,
            performed_at,
            ip_address,
            user_agent
        ) VALUES (
            p_receipt_number,
            p_action,
            p_old_values,
            p_new_values,
            l_user,
            SYSTIMESTAMP,
            l_ip,
            SUBSTR(l_agent, 1, 500)
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Don't let audit failures break the main transaction
            ROLLBACK;
            uscis_util_pkg.log_error(
                'Failed to log audit event: ' || SQLERRM,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
    END log_event;
    
    -- --------------------------------------------------------
    -- log_insert
    -- --------------------------------------------------------
    PROCEDURE log_insert(
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2 DEFAULT NULL,
        p_notes          IN CLOB DEFAULT NULL
    ) IS
        l_new_values CLOB;
    BEGIN
        l_new_values := '{' ||
            '"receipt_number":"' || uscis_util_pkg.json_escape(p_receipt_number) || '"' ||
            CASE WHEN p_case_type IS NOT NULL 
                 THEN ',"case_type":"' || uscis_util_pkg.json_escape(p_case_type) || '"' 
            END ||
            CASE WHEN p_notes IS NOT NULL 
                 THEN ',"notes":"' || uscis_util_pkg.json_escape(SUBSTR(p_notes, 1, 500)) || '"' 
            END ||
        '}';
        
        log_event(
            p_receipt_number => p_receipt_number,
            p_action         => uscis_types_pkg.gc_action_insert,
            p_new_values     => l_new_values
        );
    END log_insert;
    
    -- --------------------------------------------------------
    -- log_update
    -- --------------------------------------------------------
    PROCEDURE log_update(
        p_receipt_number IN VARCHAR2,
        p_field_name     IN VARCHAR2,
        p_old_value      IN VARCHAR2,
        p_new_value      IN VARCHAR2
    ) IS
        l_old_values CLOB;
        l_new_values CLOB;
    BEGIN
        -- Properly handle NULL values in JSON (produce null without quotes)
        l_old_values := '{"' || uscis_util_pkg.json_escape(p_field_name) || '":' || 
                        CASE WHEN p_old_value IS NULL THEN 'null'
                             ELSE '"' || uscis_util_pkg.json_escape(p_old_value) || '"'
                        END || '}';
        l_new_values := '{"' || uscis_util_pkg.json_escape(p_field_name) || '":' || 
                        CASE WHEN p_new_value IS NULL THEN 'null'
                             ELSE '"' || uscis_util_pkg.json_escape(p_new_value) || '"'
                        END || '}';
        
        log_event(
            p_receipt_number => p_receipt_number,
            p_action         => uscis_types_pkg.gc_action_update,
            p_old_values     => l_old_values,
            p_new_values     => l_new_values
        );
    END log_update;
    
    -- --------------------------------------------------------
    -- log_delete
    -- --------------------------------------------------------
    PROCEDURE log_delete(
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2 DEFAULT NULL
    ) IS
        l_old_values CLOB;
    BEGIN
        l_old_values := '{' ||
            '"receipt_number":"' || uscis_util_pkg.json_escape(p_receipt_number) || '"' ||
            CASE WHEN p_case_type IS NOT NULL 
                 THEN ',"case_type":"' || uscis_util_pkg.json_escape(p_case_type) || '"' 
            END ||
        '}';
        
        log_event(
            p_receipt_number => p_receipt_number,
            p_action         => uscis_types_pkg.gc_action_delete,
            p_old_values     => l_old_values
        );
    END log_delete;
    
    -- --------------------------------------------------------
    -- log_check
    -- --------------------------------------------------------
    PROCEDURE log_check(
        p_receipt_number IN VARCHAR2,
        p_source         IN VARCHAR2 DEFAULT 'MANUAL',
        p_status_found   IN VARCHAR2 DEFAULT NULL
    ) IS
        l_new_values CLOB;
    BEGIN
        l_new_values := '{' ||
            '"source":"' || uscis_util_pkg.json_escape(p_source) || '"' ||
            CASE WHEN p_status_found IS NOT NULL 
                 THEN ',"status":"' || uscis_util_pkg.json_escape(p_status_found) || '"' 
            END ||
        '}';
        
        log_event(
            p_receipt_number => p_receipt_number,
            p_action         => uscis_types_pkg.gc_action_check,
            p_new_values     => l_new_values
        );
    END log_check;
    
    -- --------------------------------------------------------
    -- log_export
    -- --------------------------------------------------------
    PROCEDURE log_export(
        p_case_count IN NUMBER,
        p_format     IN VARCHAR2 DEFAULT 'JSON'
    ) IS
        l_new_values CLOB;
    BEGIN
        l_new_values := '{"case_count":' || p_case_count || 
                        ',"format":"' || uscis_util_pkg.json_escape(p_format) || '"}';
        
        log_event(
            p_receipt_number => NULL,
            p_action         => uscis_types_pkg.gc_action_export,
            p_new_values     => l_new_values
        );
    END log_export;
    
    -- --------------------------------------------------------
    -- log_import
    -- --------------------------------------------------------
    PROCEDURE log_import(
        p_case_count  IN NUMBER,
        p_source_file IN VARCHAR2 DEFAULT NULL,
        p_error_count IN NUMBER DEFAULT 0
    ) IS
        l_new_values CLOB;
    BEGIN
        l_new_values := '{"case_count":' || p_case_count ||
            ',"error_count":' || NVL(p_error_count, 0) ||
            CASE WHEN p_source_file IS NOT NULL 
                 THEN ',"source_file":"' || uscis_util_pkg.json_escape(p_source_file) || '"' 
            END ||
        '}';
        
        log_event(
            p_receipt_number => NULL,
            p_action         => uscis_types_pkg.gc_action_import,
            p_new_values     => l_new_values
        );
    END log_import;
    
    -- --------------------------------------------------------
    -- get_case_audit
    -- --------------------------------------------------------
    FUNCTION get_case_audit(
        p_receipt_number IN VARCHAR2
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT 
                audit_id,
                receipt_number,
                action,
                old_values,
                new_values,
                performed_by,
                performed_at,
                ip_address,
                user_agent
            FROM case_audit_log
            WHERE receipt_number = p_receipt_number
            ORDER BY performed_at DESC;
        
        RETURN l_cursor;
    END get_case_audit;
    
    -- --------------------------------------------------------
    -- get_recent_activity
    -- --------------------------------------------------------
    FUNCTION get_recent_activity(
        p_limit IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT 
                cal.audit_id,
                cal.performed_at,
                cal.action,
                cal.receipt_number,
                cal.performed_by,
                cal.ip_address,
                vcs.current_status,
                vcs.case_type,
                CASE cal.action
                    WHEN 'INSERT' THEN 'Added case ' || cal.receipt_number
                    WHEN 'UPDATE' THEN 'Updated case ' || cal.receipt_number
                    WHEN 'DELETE' THEN 'Deleted case ' || cal.receipt_number
                    WHEN 'CHECK'  THEN 'Checked status for ' || cal.receipt_number
                    WHEN 'EXPORT' THEN 'Exported cases'
                    WHEN 'IMPORT' THEN 'Imported cases'
                    ELSE cal.action
                END AS action_description
            FROM case_audit_log cal
            LEFT JOIN v_case_current_status vcs 
                ON vcs.receipt_number = cal.receipt_number
            ORDER BY cal.performed_at DESC
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN l_cursor;
    END get_recent_activity;
    
    -- --------------------------------------------------------
    -- get_user_activity
    -- --------------------------------------------------------
    FUNCTION get_user_activity(
        p_user  IN VARCHAR2,
        p_limit IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT 
                audit_id,
                receipt_number,
                action,
                old_values,
                new_values,
                performed_by,
                performed_at,
                ip_address
            FROM case_audit_log
            WHERE performed_by = p_user
            ORDER BY performed_at DESC
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN l_cursor;
    END get_user_activity;
    
    -- --------------------------------------------------------
    -- get_activity_by_date
    -- --------------------------------------------------------
    FUNCTION get_activity_by_date(
        p_start_date IN TIMESTAMP,
        p_end_date   IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_limit      IN NUMBER DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
        l_max_rows NUMBER := NVL(p_limit, 1000000);  -- Default to large number if no limit
    BEGIN
        OPEN l_cursor FOR
            SELECT * FROM (
                SELECT 
                    audit_id,
                    receipt_number,
                    action,
                    old_values,
                    new_values,
                    performed_by,
                    performed_at,
                    ip_address
                FROM case_audit_log
                WHERE performed_at BETWEEN p_start_date AND p_end_date
                ORDER BY performed_at DESC
            ) WHERE ROWNUM <= l_max_rows;
        
        RETURN l_cursor;
    END get_activity_by_date;
    
    -- --------------------------------------------------------
    -- count_audit_records
    -- --------------------------------------------------------
    FUNCTION count_audit_records(
        p_receipt_number IN VARCHAR2 DEFAULT NULL,
        p_action         IN VARCHAR2 DEFAULT NULL,
        p_days           IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM case_audit_log
        WHERE (p_receipt_number IS NULL OR receipt_number = p_receipt_number)
          AND (p_action IS NULL OR action = p_action)
          AND (p_days IS NULL OR performed_at >= SYSTIMESTAMP - NUMTODSINTERVAL(p_days, 'DAY'));
        
        RETURN l_count;
    END count_audit_records;
    
-- --------------------------------------------------------
-- purge_old_records
-- --------------------------------------------------------
PROCEDURE purge_old_records(
    p_days_to_keep IN NUMBER DEFAULT NULL
) IS
    l_days         NUMBER;
    l_deleted      NUMBER := 0;
    l_batch_size   CONSTANT NUMBER := 1000;
    l_cutoff_ts    TIMESTAMP;
BEGIN
    -- Get retention period from config if not specified
    l_days := NVL(p_days_to_keep, 
                  uscis_util_pkg.get_config_number('AUDIT_RETENTION_DAYS', 365));
    l_cutoff_ts := SYSTIMESTAMP - NUMTODSINTERVAL(l_days, 'DAY');

    -- Process in batches to avoid PGA exhaustion
    DECLARE
        TYPE t_rowid_tab IS TABLE OF ROWID;
        l_rowids t_rowid_tab;
    BEGIN
        LOOP
            -- Collect a batch of ROWIDs
            SELECT ROWID
            BULK COLLECT INTO l_rowids
            FROM case_audit_log
            WHERE performed_at < l_cutoff_ts
            AND ROWNUM <= l_batch_size;

            EXIT WHEN l_rowids.COUNT = 0;

            -- Delete batch using collected ROWIDs
            FORALL i IN 1..l_rowids.COUNT
                DELETE FROM case_audit_log
                WHERE ROWID = l_rowids(i);

            l_deleted := l_deleted + l_rowids.COUNT;

            -- Commit after each batch to release locks and prevent undo exhaustion
            COMMIT;
        END LOOP;
    END;

    uscis_util_pkg.log_debug(
        'Purged ' || l_deleted || ' audit records older than ' || l_days || ' days',
        gc_package_name
    );
END purge_old_records;
    
    -- --------------------------------------------------------
    -- archive_records
    -- --------------------------------------------------------
    PROCEDURE archive_records(
        p_days_old IN NUMBER DEFAULT 365
    ) IS
    BEGIN
        -- Create archive table if not exists (include archived_at column)
        BEGIN
            EXECUTE IMMEDIATE '
                CREATE TABLE case_audit_log_archive AS
                SELECT cal.*, CAST(NULL AS TIMESTAMP) AS archived_at
                FROM case_audit_log cal WHERE 1=0';
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -955 THEN  -- Table already exists
                    RAISE;
                END IF;
        END;
        
        -- Archive in batches using re-query pattern to avoid ORA-01555
        DECLARE
            TYPE t_rowid_tab IS TABLE OF ROWID;
            l_rowids         t_rowid_tab;
            l_batch_size     CONSTANT NUMBER := 1000;
            l_total_archived NUMBER := 0;
            l_cutoff_ts      TIMESTAMP := SYSTIMESTAMP - NUMTODSINTERVAL(p_days_old, 'DAY');
        BEGIN
            LOOP
                -- Re-query each batch to avoid keeping cursor open across COMMITs
                SELECT ROWID
                BULK COLLECT INTO l_rowids
                FROM case_audit_log
                WHERE performed_at < l_cutoff_ts
                  AND ROWNUM <= l_batch_size;
                
                -- Exit when no more rows to process
                EXIT WHEN l_rowids.COUNT = 0;
                
                -- Archive batch using FORALL with INSERT...SELECT by ROWID
                FORALL i IN 1..l_rowids.COUNT
                    INSERT INTO case_audit_log_archive (
                        audit_id,
                        receipt_number,
                        action,
                        old_values,
                        new_values,
                        performed_by,
                        performed_at,
                        ip_address,
                        user_agent,
                        archived_at
                    )
                    SELECT 
                        audit_id,
                        receipt_number,
                        action,
                        old_values,
                        new_values,
                        performed_by,
                        performed_at,
                        ip_address,
                        user_agent,
                        SYSTIMESTAMP
                    FROM case_audit_log
                    WHERE ROWID = l_rowids(i);
                
                -- Delete batch using same ROWIDs
                FORALL i IN 1..l_rowids.COUNT
                    DELETE FROM case_audit_log
                    WHERE ROWID = l_rowids(i);
                
                l_total_archived := l_total_archived + l_rowids.COUNT;
                
                -- Commit after each batch to release locks and prevent undo exhaustion
                COMMIT;
            END LOOP;
            
            uscis_util_pkg.log_debug(
                'Archived ' || l_total_archived || ' audit records',
                gc_package_name
            );
        END;
    END archive_records;

END uscis_audit_pkg;
/

SHOW ERRORS PACKAGE uscis_audit_pkg
SHOW ERRORS PACKAGE BODY uscis_audit_pkg

PROMPT ============================================================
PROMPT USCIS_AUDIT_PKG created successfully
PROMPT ============================================================
