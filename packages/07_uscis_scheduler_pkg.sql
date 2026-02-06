-- ============================================================
-- USCIS Case Tracker - Scheduler Package
-- Task 1.3.6: USCIS_SCHEDULER_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/07_uscis_scheduler_pkg.sql
-- Purpose: Background job management for automatic status checks
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG, USCIS_API_PKG, DBMS_SCHEDULER
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_SCHEDULER_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_scheduler_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_SCHEDULER_PKG';
    
    -- ========================================================
    -- Job Name Constants
    -- ========================================================
    gc_job_auto_check   CONSTANT VARCHAR2(30) := 'USCIS_AUTO_CHECK_JOB';
    gc_job_token_refresh CONSTANT VARCHAR2(30) := 'USCIS_TOKEN_REFRESH_JOB';
    gc_job_cleanup      CONSTANT VARCHAR2(30) := 'USCIS_CLEANUP_JOB';
    
    -- ========================================================
    -- Job Management Procedures
    -- ========================================================
    
    -- Create automatic status check job
    PROCEDURE create_auto_check_job(
        p_interval_hours IN NUMBER DEFAULT NULL  -- NULL = use config
    );
    
    -- Create token refresh job
    PROCEDURE create_token_refresh_job(
        p_interval_minutes IN NUMBER DEFAULT 55
    );
    
    -- Create cleanup job (old audit logs, etc.)
    PROCEDURE create_cleanup_job(
        p_interval_days IN NUMBER DEFAULT 1
    );
    
    -- Create all scheduler jobs
    PROCEDURE create_all_jobs;
    
    -- Drop a specific job
    PROCEDURE drop_job(
        p_job_name IN VARCHAR2
    );
    
    -- Drop all scheduler jobs
    PROCEDURE drop_all_jobs;
    
    -- ========================================================
    -- Job Execution Procedures (called by scheduler)
    -- ========================================================
    
    -- Run automatic status check
    PROCEDURE run_auto_check;
    
    -- Run token refresh
    PROCEDURE run_token_refresh;
    
    -- Run cleanup
    PROCEDURE run_cleanup;
    
    -- ========================================================
    -- Configuration Procedures
    -- ========================================================
    
    -- Enable/disable automatic checking
    PROCEDURE set_auto_check_enabled(
        p_enabled IN BOOLEAN
    );
    
    -- Check if auto check is enabled
    FUNCTION is_auto_check_enabled RETURN BOOLEAN;
    
    -- Set auto check interval
    PROCEDURE set_auto_check_interval(
        p_hours IN NUMBER
    );
    
    -- Set auto check batch size
    PROCEDURE set_auto_check_batch_size(
        p_size IN NUMBER
    );
    
    -- ========================================================
    -- Status Functions
    -- ========================================================
    
    -- Get job status
    FUNCTION get_job_status(
        p_job_name IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Get all jobs status (as JSON)
    FUNCTION get_all_jobs_status RETURN CLOB;
    
    -- Get job run history
    FUNCTION get_job_history(
        p_job_name IN VARCHAR2,
        p_limit    IN NUMBER DEFAULT 10
    ) RETURN SYS_REFCURSOR;
    
    -- Get next run time
    FUNCTION get_next_run_time(
        p_job_name IN VARCHAR2
    ) RETURN TIMESTAMP;

END uscis_scheduler_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_scheduler_pkg AS

    -- --------------------------------------------------------
    -- Session context constants for headless (DBMS_SCHEDULER) execution.
    -- APEX_WEB_SERVICE requires a valid APEX session; these are used by
    -- apex_session.create_session before any APEX API call.
    -- --------------------------------------------------------
    gc_app_id          CONSTANT NUMBER       := 102;
    gc_page_id         CONSTANT NUMBER       := 1;
    gc_scheduler_user  CONSTANT VARCHAR2(30) := 'USCIS_SCHEDULER';

    -- --------------------------------------------------------
    -- Private: Check if job exists
    -- --------------------------------------------------------
    FUNCTION job_exists(
        p_job_name IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM user_scheduler_jobs
        WHERE job_name = UPPER(p_job_name);
        
        RETURN l_count > 0;
    END job_exists;
    
    -- --------------------------------------------------------
    -- drop_job
    -- --------------------------------------------------------
    PROCEDURE drop_job(
        p_job_name IN VARCHAR2
    ) IS
    BEGIN
        IF job_exists(p_job_name) THEN
            DBMS_SCHEDULER.DROP_JOB(
                job_name => p_job_name,
                force    => TRUE
            );
            uscis_util_pkg.log_debug('Dropped job: ' || p_job_name, gc_package_name);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            uscis_util_pkg.log_error(
                'Error dropping job ' || p_job_name,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
    END drop_job;
    
    -- --------------------------------------------------------
    -- drop_all_jobs
    -- --------------------------------------------------------
    PROCEDURE drop_all_jobs IS
    BEGIN
        drop_job(gc_job_auto_check);
        drop_job(gc_job_token_refresh);
        drop_job(gc_job_cleanup);
        
        uscis_util_pkg.log_debug('Dropped all scheduler jobs', gc_package_name);
    END drop_all_jobs;
    
    -- --------------------------------------------------------
    -- create_auto_check_job
    -- --------------------------------------------------------
    PROCEDURE create_auto_check_job(
        p_interval_hours IN NUMBER DEFAULT NULL
    ) IS
        l_interval NUMBER;
    BEGIN
        -- Get interval from config or parameter
        l_interval := NVL(p_interval_hours, 
            uscis_util_pkg.get_config_number('AUTO_CHECK_INTERVAL_HOURS', 24));
        
        -- Validate interval
        IF l_interval < 1 OR l_interval > 168 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Interval must be between 1 and 168 hours');
        END IF;
        
        -- Drop existing job
        drop_job(gc_job_auto_check);
        
        -- Create new job
        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => gc_job_auto_check,
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'USCIS_SCHEDULER_PKG.RUN_AUTO_CHECK',
            start_date      => SYSTIMESTAMP + INTERVAL '1' MINUTE,
            repeat_interval => 'FREQ=HOURLY; INTERVAL=' || l_interval,
            enabled         => is_auto_check_enabled,
            comments        => 'Automatic USCIS case status check'
        );
        
        uscis_util_pkg.log_debug(
            'Created auto check job with interval: ' || l_interval || ' hours',
            gc_package_name
        );
    END create_auto_check_job;
    
    -- --------------------------------------------------------
    -- create_token_refresh_job
    -- --------------------------------------------------------
    PROCEDURE create_token_refresh_job(
        p_interval_minutes IN NUMBER DEFAULT 55
    ) IS
    BEGIN
        -- Validate interval (1 minute to 1440 minutes = 24 hours)
        IF p_interval_minutes IS NULL OR p_interval_minutes < 1 OR p_interval_minutes > 1440 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Token refresh interval must be between 1 and 1440 minutes');
        END IF;
        
        -- Drop existing job
        drop_job(gc_job_token_refresh);
        
        -- Create new job
        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => gc_job_token_refresh,
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'USCIS_SCHEDULER_PKG.RUN_TOKEN_REFRESH',
            start_date      => SYSTIMESTAMP + INTERVAL '5' MINUTE,
            repeat_interval => 'FREQ=MINUTELY; INTERVAL=' || p_interval_minutes,
            enabled         => TRUE,
            comments        => 'Proactive OAuth token refresh'
        );
        
        uscis_util_pkg.log_debug(
            'Created token refresh job with interval: ' || p_interval_minutes || ' minutes',
            gc_package_name
        );
    END create_token_refresh_job;
    
    -- --------------------------------------------------------
    -- create_cleanup_job
    -- --------------------------------------------------------
    PROCEDURE create_cleanup_job(
        p_interval_days IN NUMBER DEFAULT 1
    ) IS
    BEGIN
        -- Validate interval (NULL or 1 day to 30 days)
        IF p_interval_days IS NULL THEN
            RAISE_APPLICATION_ERROR(-20100, 'Interval cannot be NULL');
        END IF;
        IF p_interval_days < 1 OR p_interval_days > 30 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Interval must be between 1 and 30 days');
        END IF;
        
        -- Drop existing job
        drop_job(gc_job_cleanup);
        
        -- Create new job - run at 2 AM daily
        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => gc_job_cleanup,
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'USCIS_SCHEDULER_PKG.RUN_CLEANUP',
            start_date      => TRUNC(SYSTIMESTAMP) + INTERVAL '1' DAY + INTERVAL '2' HOUR,
            repeat_interval => 'FREQ=DAILY; INTERVAL=' || p_interval_days || '; BYHOUR=2',
            enabled         => TRUE,
            comments        => 'Cleanup old audit logs and expired tokens'
        );
        
        uscis_util_pkg.log_debug('Created cleanup job', gc_package_name);
    END create_cleanup_job;
    
    -- --------------------------------------------------------
    -- create_all_jobs
    -- --------------------------------------------------------
    PROCEDURE create_all_jobs IS
    BEGIN
        create_auto_check_job;
        create_token_refresh_job;
        create_cleanup_job;
        
        uscis_util_pkg.log_debug('Created all scheduler jobs', gc_package_name);
    END create_all_jobs;
    
    -- --------------------------------------------------------
    -- run_auto_check
    -- --------------------------------------------------------
    PROCEDURE run_auto_check IS
        l_batch_size  NUMBER;
        l_receipts    uscis_types_pkg.t_receipt_tab := uscis_types_pkg.t_receipt_tab();
        l_cursor      SYS_REFCURSOR;
        l_receipt     VARCHAR2(13);
        l_count       NUMBER := 0;
    BEGIN
        -- Establish APEX session context (required for APEX_WEB_SERVICE)
        apex_session.create_session(
            p_app_id   => gc_app_id,
            p_page_id  => gc_page_id,
            p_username => gc_scheduler_user
        );

        -- Check if enabled
        IF NOT is_auto_check_enabled THEN
            uscis_util_pkg.log_debug('Auto check is disabled, skipping', gc_package_name);
            apex_session.delete_session;
            RETURN;
        END IF;
        
        -- Check if API is configured
        IF NOT uscis_api_pkg.is_api_configured AND NOT uscis_api_pkg.is_mock_mode THEN
            uscis_util_pkg.log_debug('API not configured, skipping auto check', gc_package_name);
            apex_session.delete_session;
            RETURN;
        END IF;
        
        -- Get batch size
        l_batch_size := uscis_util_pkg.get_config_number('AUTO_CHECK_BATCH_SIZE', 50);
        
        -- Get cases due for check
        l_cursor := uscis_case_pkg.get_cases_due_for_check(l_batch_size);
        
        -- Collect receipt numbers with proper cleanup
        BEGIN
            LOOP
                FETCH l_cursor INTO l_receipt;
                EXIT WHEN l_cursor%NOTFOUND OR l_count >= l_batch_size;
                
                l_receipts.EXTEND;
                l_receipts(l_receipts.COUNT) := l_receipt;
                l_count := l_count + 1;
            END LOOP;
            CLOSE l_cursor;
        EXCEPTION
            WHEN OTHERS THEN
                IF l_cursor%ISOPEN THEN
                    CLOSE l_cursor;
                END IF;
                RAISE;
        END;
        
        IF l_receipts.COUNT = 0 THEN
            uscis_util_pkg.log_debug('No cases due for check', gc_package_name);
            apex_session.delete_session;
            RETURN;
        END IF;
        
        uscis_util_pkg.log_debug(
            'Auto-checking ' || l_receipts.COUNT || ' cases',
            gc_package_name
        );
        
        -- Check cases
        uscis_api_pkg.check_multiple_cases(
            p_receipt_numbers  => l_receipts,
            p_save_to_database => TRUE,
            p_stop_on_error    => FALSE
        );

        -- Tear down APEX session
        apex_session.delete_session;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Always clean up APEX session on error
            BEGIN
                apex_session.delete_session;
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
            uscis_util_pkg.log_error(
                'Auto check failed: ' || SQLERRM,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
            RAISE;  -- Allow scheduler to record job failure
    END run_auto_check;
    
    -- --------------------------------------------------------
    -- run_token_refresh
    -- --------------------------------------------------------
    PROCEDURE run_token_refresh IS
    BEGIN
        -- Establish APEX session context (required for APEX_WEB_SERVICE)
        apex_session.create_session(
            p_app_id   => gc_app_id,
            p_page_id  => gc_page_id,
            p_username => gc_scheduler_user
        );

        uscis_oauth_pkg.refresh_token_if_needed(
            p_buffer_seconds => 300  -- Refresh 5 min before expiry
        );

        apex_session.delete_session;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                apex_session.delete_session;
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
            uscis_util_pkg.log_error(
                'Token refresh failed: ' || SQLERRM,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
            RAISE;
    END run_token_refresh;
    
    -- --------------------------------------------------------
    -- run_cleanup
    -- --------------------------------------------------------
    PROCEDURE run_cleanup IS
        l_audit_days  NUMBER;
        l_status_days NUMBER;
        l_deleted_count NUMBER := 0;
    BEGIN
        -- Establish APEX session context (cleanup may call APEX APIs indirectly)
        apex_session.create_session(
            p_app_id   => gc_app_id,
            p_page_id  => gc_page_id,
            p_username => gc_scheduler_user
        );

        -- Get retention periods
        l_audit_days := uscis_util_pkg.get_config_number('AUDIT_RETENTION_DAYS', 365);
        l_status_days := uscis_util_pkg.get_config_number('STATUS_HISTORY_RETENTION_DAYS', 730);
        
        uscis_util_pkg.log_debug('Running cleanup job', gc_package_name);
        
        -- Purge old status history (keep at least most recent per case)
        DELETE FROM status_updates
        WHERE id NOT IN (
            -- Keep the most recent status update per receipt
            SELECT MAX(id) FROM status_updates GROUP BY receipt_number
        )
        AND created_at < SYSTIMESTAMP - l_status_days;
        l_deleted_count := SQL%ROWCOUNT;
        
        IF l_deleted_count > 0 THEN
            uscis_util_pkg.log_debug('Purged ' || l_deleted_count || ' old status records', gc_package_name);
        END IF;
        
        -- Delete old expired tokens
        DELETE FROM oauth_tokens
        WHERE expires_at < SYSTIMESTAMP - INTERVAL '7' DAY;
        
        COMMIT;
        
        -- Purge old audit logs AFTER other cleanup operations
        -- Note: purge_old_records performs its own COMMITs internally (batch processing)
        -- so it runs independently of the above transaction
        uscis_audit_pkg.purge_old_records(l_audit_days);
        
        uscis_util_pkg.log_debug('Cleanup completed', gc_package_name);

        apex_session.delete_session;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            BEGIN
                apex_session.delete_session;
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
            uscis_util_pkg.log_error(
                'Cleanup failed: ' || SQLERRM,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
            RAISE;  -- Allow scheduler to record job failure
    END run_cleanup;
    
    -- --------------------------------------------------------
    -- set_auto_check_enabled
    -- --------------------------------------------------------
    PROCEDURE set_auto_check_enabled(
        p_enabled IN BOOLEAN
    ) IS
        l_value VARCHAR2(1) := CASE WHEN p_enabled THEN 'Y' ELSE 'N' END;
    BEGIN
        uscis_util_pkg.set_config('AUTO_CHECK_ENABLED', l_value);
        
        -- Enable/disable job
        IF job_exists(gc_job_auto_check) THEN
            IF p_enabled THEN
                DBMS_SCHEDULER.ENABLE(gc_job_auto_check);
            ELSE
                DBMS_SCHEDULER.DISABLE(gc_job_auto_check);
            END IF;
        END IF;
    END set_auto_check_enabled;
    
    -- --------------------------------------------------------
    -- is_auto_check_enabled
    -- --------------------------------------------------------
    FUNCTION is_auto_check_enabled RETURN BOOLEAN IS
    BEGIN
        RETURN uscis_util_pkg.get_config_boolean('AUTO_CHECK_ENABLED', TRUE);
    END is_auto_check_enabled;
    
    -- --------------------------------------------------------
    -- set_auto_check_interval
    -- --------------------------------------------------------
    PROCEDURE set_auto_check_interval(
        p_hours IN NUMBER
    ) IS
    BEGIN
        IF p_hours < 1 OR p_hours > 168 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Interval must be between 1 and 168 hours');
        END IF;
        
        uscis_util_pkg.set_config('AUTO_CHECK_INTERVAL_HOURS', TO_CHAR(p_hours));
        
        -- Recreate job with new interval
        create_auto_check_job(p_hours);
    END set_auto_check_interval;
    
    -- --------------------------------------------------------
    -- set_auto_check_batch_size
    -- --------------------------------------------------------
    PROCEDURE set_auto_check_batch_size(
        p_size IN NUMBER
    ) IS
    BEGIN
        IF p_size IS NULL OR p_size < 1 OR p_size > 500 THEN
            RAISE_APPLICATION_ERROR(-20100, 'Batch size must be between 1 and 500');
        END IF;
        
        uscis_util_pkg.set_config('AUTO_CHECK_BATCH_SIZE', TO_CHAR(p_size));
    END set_auto_check_batch_size;
    
    -- --------------------------------------------------------
    -- get_job_status
    -- --------------------------------------------------------
    FUNCTION get_job_status(
        p_job_name IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_state VARCHAR2(50);
    BEGIN
        SELECT state
        INTO l_state
        FROM user_scheduler_jobs
        WHERE job_name = UPPER(p_job_name);
        
        RETURN l_state;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'NOT_EXISTS';
    END get_job_status;
    
    -- --------------------------------------------------------
    -- get_all_jobs_status
    -- --------------------------------------------------------
    FUNCTION get_all_jobs_status RETURN CLOB IS
        l_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'job_name' VALUE job_name,
                'state' VALUE state,
                'enabled' VALUE enabled,
                'next_run_date' VALUE TO_CHAR(
                    SYS_EXTRACT_UTC(next_run_date), 
                    'YYYY-MM-DD"T"HH24:MI:SS"Z"'
                ),
                'last_start_date' VALUE TO_CHAR(
                    SYS_EXTRACT_UTC(last_start_date), 
                    'YYYY-MM-DD"T"HH24:MI:SS"Z"'
                ),
                'run_count' VALUE run_count,
                'failure_count' VALUE failure_count
            )
        )
        INTO l_json
        FROM user_scheduler_jobs
        WHERE job_name IN (gc_job_auto_check, gc_job_token_refresh, gc_job_cleanup);
        
        RETURN NVL(l_json, '[]');
    END get_all_jobs_status;
    
    -- --------------------------------------------------------
    -- get_job_history
    -- --------------------------------------------------------
    FUNCTION get_job_history(
        p_job_name IN VARCHAR2,
        p_limit    IN NUMBER DEFAULT 10
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT 
                log_id,
                job_name,
                status,
                actual_start_date,
                run_duration,
                error#,
                additional_info
            FROM user_scheduler_job_run_details
            WHERE job_name = UPPER(p_job_name)
            ORDER BY actual_start_date DESC
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN l_cursor;
    END get_job_history;
    
    -- --------------------------------------------------------
    -- get_next_run_time
    -- --------------------------------------------------------
    FUNCTION get_next_run_time(
        p_job_name IN VARCHAR2
    ) RETURN TIMESTAMP IS
        l_next_run TIMESTAMP;
    BEGIN
        SELECT next_run_date
        INTO l_next_run
        FROM user_scheduler_jobs
        WHERE job_name = UPPER(p_job_name);
        
        RETURN l_next_run;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_next_run_time;

END uscis_scheduler_pkg;
/

SHOW ERRORS PACKAGE uscis_scheduler_pkg
SHOW ERRORS PACKAGE BODY uscis_scheduler_pkg

PROMPT ============================================================
PROMPT USCIS_SCHEDULER_PKG created successfully
PROMPT ============================================================
