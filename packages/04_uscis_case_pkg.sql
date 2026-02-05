-- ============================================================
-- USCIS Case Tracker - Case Management Package
-- Task 1.3.3: USCIS_CASE_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/04_uscis_case_pkg.sql
-- Purpose: Core CRUD operations for case management
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG, USCIS_AUDIT_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_CASE_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_case_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_CASE_PKG';
    
    -- ========================================================
    -- Exception Definitions
    -- ========================================================
    e_invalid_receipt   EXCEPTION;
    e_case_not_found    EXCEPTION;
    e_duplicate_case    EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_invalid_receipt, -20001);
    PRAGMA EXCEPTION_INIT(e_case_not_found, -20002);
    PRAGMA EXCEPTION_INIT(e_duplicate_case, -20003);
    
    -- ========================================================
    -- Case Creation Functions
    -- ========================================================
    
    -- Add a new case (returns receipt_number if successful)
    FUNCTION add_case(
        p_receipt_number   IN VARCHAR2,
        p_case_type        IN VARCHAR2 DEFAULT 'Unknown',
        p_current_status   IN VARCHAR2 DEFAULT 'Pending',
        p_last_updated     IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details          IN CLOB DEFAULT NULL,
        p_notes            IN CLOB DEFAULT NULL,
        p_source           IN VARCHAR2 DEFAULT 'MANUAL',
        p_check_frequency  IN NUMBER DEFAULT 24
    ) RETURN VARCHAR2;
    
    -- Add or update case status (upsert)
    PROCEDURE add_or_update_case(
        p_receipt_number   IN VARCHAR2,
        p_case_type        IN VARCHAR2,
        p_current_status   IN VARCHAR2,
        p_last_updated     IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details          IN CLOB DEFAULT NULL,
        p_source           IN VARCHAR2 DEFAULT 'MANUAL',
        p_api_response_json IN CLOB DEFAULT NULL
    );
    
    -- ========================================================
    -- Case Query Functions
    -- ========================================================
    
    -- Get case by receipt number (returns cursor)
    FUNCTION get_case(
        p_receipt_number   IN VARCHAR2,
        p_include_history  IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR;
    
    -- List cases with pagination and filtering
    FUNCTION list_cases(
        p_receipt_filter   IN VARCHAR2 DEFAULT NULL,
        p_status_filter    IN VARCHAR2 DEFAULT NULL,
        p_active_only      IN BOOLEAN DEFAULT TRUE,
        p_page_size        IN NUMBER DEFAULT 20,
        p_page             IN NUMBER DEFAULT 1,
        p_order_by         IN VARCHAR2 DEFAULT 'LAST_UPDATED DESC'
    ) RETURN SYS_REFCURSOR;
    
    -- Get total case count (with optional filters)
    FUNCTION count_cases(
        p_receipt_filter   IN VARCHAR2 DEFAULT NULL,
        p_status_filter    IN VARCHAR2 DEFAULT NULL,
        p_active_only      IN BOOLEAN DEFAULT TRUE
    ) RETURN NUMBER;
    
    -- Check if case exists
    FUNCTION case_exists(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Get cases by multiple receipt numbers
    FUNCTION get_cases_by_receipts(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    ) RETURN SYS_REFCURSOR;
    
    -- Get cases due for status check
    FUNCTION get_cases_due_for_check(
        p_limit IN NUMBER DEFAULT 50
    ) RETURN SYS_REFCURSOR;
    
    -- ========================================================
    -- Case Update Functions
    -- ========================================================
    
    -- Update case notes
    PROCEDURE update_case_notes(
        p_receipt_number IN VARCHAR2,
        p_notes          IN CLOB
    );
    
    -- Toggle case active status
    PROCEDURE set_case_active(
        p_receipt_number IN VARCHAR2,
        p_is_active      IN BOOLEAN
    );
    
    -- Update last checked timestamp
    PROCEDURE update_last_checked(
        p_receipt_number IN VARCHAR2
    );
    
    -- Update check frequency
    PROCEDURE set_check_frequency(
        p_receipt_number IN VARCHAR2,
        p_hours          IN NUMBER
    );
    
    -- ========================================================
    -- Case Delete Functions
    -- ========================================================
    
    -- Delete case (cascades to status_updates)
    PROCEDURE delete_case(
        p_receipt_number IN VARCHAR2
    );
    
    -- Delete multiple cases
    PROCEDURE delete_cases(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    );
    
    -- Delete inactive cases older than X days
    PROCEDURE purge_inactive_cases(
        p_days_old IN NUMBER DEFAULT 365
    );
    
    -- ========================================================
    -- Status History Functions
    -- ========================================================
    
    -- Get status history for a case
    FUNCTION get_status_history(
        p_receipt_number IN VARCHAR2,
        p_limit          IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR;
    
    -- Get latest status for a case
    FUNCTION get_latest_status(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- Count status updates for a case
    FUNCTION count_status_updates(
        p_receipt_number IN VARCHAR2
    ) RETURN NUMBER;

END uscis_case_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_case_pkg AS

    -- --------------------------------------------------------
    -- add_case
    -- --------------------------------------------------------
    FUNCTION add_case(
        p_receipt_number   IN VARCHAR2,
        p_case_type        IN VARCHAR2 DEFAULT 'Unknown',
        p_current_status   IN VARCHAR2 DEFAULT 'Pending',
        p_last_updated     IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details          IN CLOB DEFAULT NULL,
        p_notes            IN CLOB DEFAULT NULL,
        p_source           IN VARCHAR2 DEFAULT 'MANUAL',
        p_check_frequency  IN NUMBER DEFAULT 24
    ) RETURN VARCHAR2 IS
        l_receipt VARCHAR2(13);
        l_user    VARCHAR2(255);
    BEGIN
        -- Normalize and validate receipt number
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Check for duplicate
        IF case_exists(l_receipt) THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_duplicate_case,
                'Case already exists: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
        
        l_user := uscis_util_pkg.get_current_user;
        
        -- Insert case history record
        INSERT INTO case_history (
            receipt_number,
            created_at,
            created_by,
            notes,
            is_active,
            check_frequency
        ) VALUES (
            l_receipt,
            SYSTIMESTAMP,
            l_user,
            p_notes,
            1,
            NVL(p_check_frequency, 24)
        );
        
        -- Insert initial status update
        INSERT INTO status_updates (
            receipt_number,
            case_type,
            current_status,
            last_updated,
            details,
            source,
            created_at
        ) VALUES (
            l_receipt,
            NVL(p_case_type, 'Unknown'),
            NVL(p_current_status, 'Pending'),
            NVL(p_last_updated, SYSTIMESTAMP),
            p_details,
            NVL(p_source, uscis_types_pkg.gc_source_manual),
            SYSTIMESTAMP
        );
        
        -- Log audit event
        uscis_audit_pkg.log_insert(l_receipt, p_case_type, p_notes);
        
        RETURN l_receipt;
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_duplicate_case,
                'Case already exists: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
    END add_case;
    
    -- --------------------------------------------------------
    -- add_or_update_case
    -- --------------------------------------------------------
    PROCEDURE add_or_update_case(
        p_receipt_number    IN VARCHAR2,
        p_case_type         IN VARCHAR2,
        p_current_status    IN VARCHAR2,
        p_last_updated      IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details           IN CLOB DEFAULT NULL,
        p_source            IN VARCHAR2 DEFAULT 'MANUAL',
        p_api_response_json IN CLOB DEFAULT NULL
    ) IS
        l_receipt    VARCHAR2(13);
        l_exists     BOOLEAN;
        l_old_status VARCHAR2(500);
    BEGIN
        -- Normalize and validate
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        l_exists := case_exists(l_receipt);
        
        IF NOT l_exists THEN
            -- Create new case with race condition handling
            BEGIN
                INSERT INTO case_history (
                    receipt_number,
                    created_at,
                    created_by,
                    is_active,
                    check_frequency
                ) VALUES (
                    l_receipt,
                    SYSTIMESTAMP,
                    uscis_util_pkg.get_current_user,
                    1,
                    24  -- Default check frequency matching add_case
                );
                
                uscis_audit_pkg.log_insert(l_receipt, p_case_type);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    -- Another session inserted the case concurrently
                    -- This is fine, we'll just add the status update below
                    NULL;
            END;
        ELSE
            -- Get old status for comparison
            BEGIN
                SELECT current_status
                INTO l_old_status
                FROM status_updates
                WHERE receipt_number = l_receipt
                  AND id = (SELECT MAX(id) FROM status_updates WHERE receipt_number = l_receipt);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_old_status := NULL;
            END;
        END IF;
        
        -- Always add new status update
        INSERT INTO status_updates (
            receipt_number,
            case_type,
            current_status,
            last_updated,
            details,
            source,
            api_response_json,
            created_at
        ) VALUES (
            l_receipt,
            p_case_type,
            p_current_status,
            NVL(p_last_updated, SYSTIMESTAMP),
            p_details,
            NVL(p_source, uscis_types_pkg.gc_source_manual),
            p_api_response_json,
            SYSTIMESTAMP
        );
        
        -- Log status change if different (use NVL for NULL-safe comparison)
        IF l_exists AND NVL(l_old_status, '<NULL>') <> NVL(p_current_status, '<NULL>') THEN
            uscis_audit_pkg.log_update(l_receipt, 'current_status', l_old_status, p_current_status);
        END IF;
        
    END add_or_update_case;
    
    -- --------------------------------------------------------
    -- get_case
    -- --------------------------------------------------------
    FUNCTION get_case(
        p_receipt_number  IN VARCHAR2,
        p_include_history IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR IS
        l_receipt VARCHAR2(13);
        l_cursor  SYS_REFCURSOR;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        IF p_include_history THEN
            -- Return case with all status history
            OPEN l_cursor FOR
                SELECT 
                    ch.receipt_number,
                    ch.created_at AS tracking_since,
                    ch.created_by,
                    ch.notes,
                    ch.is_active,
                    ch.last_checked_at,
                    ch.check_frequency,
                    su.case_type,
                    su.current_status,
                    su.last_updated,
                    su.details,
                    su.source,
                    su.created_at AS status_created_at
                FROM case_history ch
                LEFT JOIN status_updates su ON su.receipt_number = ch.receipt_number
                WHERE ch.receipt_number = l_receipt
                ORDER BY su.last_updated DESC;
        ELSE
            -- Return case with only current status
            OPEN l_cursor FOR
                SELECT *
                FROM v_case_current_status
                WHERE receipt_number = l_receipt;
        END IF;
        
        RETURN l_cursor;
    END get_case;
    
    -- --------------------------------------------------------
    -- list_cases
    -- --------------------------------------------------------
    FUNCTION list_cases(
        p_receipt_filter   IN VARCHAR2 DEFAULT NULL,
        p_status_filter    IN VARCHAR2 DEFAULT NULL,
        p_active_only      IN BOOLEAN DEFAULT TRUE,
        p_page_size        IN NUMBER DEFAULT 20,
        p_page             IN NUMBER DEFAULT 1,
        p_order_by         IN VARCHAR2 DEFAULT 'LAST_UPDATED DESC'
    ) RETURN SYS_REFCURSOR IS
        l_cursor   SYS_REFCURSOR;
        l_offset   NUMBER;
        l_sql      VARCHAR2(4000);
        l_order_by VARCHAR2(100);
    BEGIN
        l_offset := (NVL(p_page, 1) - 1) * NVL(p_page_size, 20);
        
        -- Validate and whitelist p_order_by to prevent SQL injection
        l_order_by := UPPER(TRIM(NVL(p_order_by, 'LAST_UPDATED DESC')));
        
        -- Only allow specific safe ordering options
        IF l_order_by NOT IN (
            'LAST_UPDATED DESC', 'LAST_UPDATED ASC',
            'RECEIPT_NUMBER DESC', 'RECEIPT_NUMBER ASC',
            'CREATED_AT DESC', 'CREATED_AT ASC',
            'TRACKING_SINCE DESC', 'TRACKING_SINCE ASC',
            'CURRENT_STATUS DESC', 'CURRENT_STATUS ASC',
            'CASE_TYPE DESC', 'CASE_TYPE ASC'
        ) THEN
            -- Invalid order_by value - default to safe option
            l_order_by := 'LAST_UPDATED DESC';
            uscis_util_pkg.log_debug(
                'Invalid order_by value rejected, using default: ' || p_order_by,
                gc_package_name
            );
        END IF;
        
        -- Build dynamic SQL for flexibility
        l_sql := 'SELECT * FROM v_case_current_status WHERE 1=1';
        
        IF p_active_only THEN
            l_sql := l_sql || ' AND is_active = 1';
        END IF;
        
        IF p_receipt_filter IS NOT NULL THEN
            l_sql := l_sql || ' AND receipt_number LIKE :p_receipt || ''%''';
        END IF;
        
        IF p_status_filter IS NOT NULL THEN
            l_sql := l_sql || ' AND UPPER(current_status) LIKE ''%'' || UPPER(:p_status) || ''%''';
        END IF;
        
        -- Use validated order_by from whitelist
        l_sql := l_sql || ' ORDER BY ' || l_order_by || ' NULLS LAST';
        l_sql := l_sql || ' OFFSET :p_offset ROWS FETCH NEXT :p_limit ROWS ONLY';
        
        -- Execute with bind variables
        IF p_receipt_filter IS NOT NULL AND p_status_filter IS NOT NULL THEN
            OPEN l_cursor FOR l_sql 
                USING p_receipt_filter, p_status_filter, l_offset, p_page_size;
        ELSIF p_receipt_filter IS NOT NULL THEN
            OPEN l_cursor FOR l_sql 
                USING p_receipt_filter, l_offset, p_page_size;
        ELSIF p_status_filter IS NOT NULL THEN
            OPEN l_cursor FOR l_sql 
                USING p_status_filter, l_offset, p_page_size;
        ELSE
            OPEN l_cursor FOR l_sql 
                USING l_offset, p_page_size;
        END IF;
        
        RETURN l_cursor;
    END list_cases;
    
    -- --------------------------------------------------------
    -- count_cases
    -- --------------------------------------------------------
    FUNCTION count_cases(
        p_receipt_filter   IN VARCHAR2 DEFAULT NULL,
        p_status_filter    IN VARCHAR2 DEFAULT NULL,
        p_active_only      IN BOOLEAN DEFAULT TRUE
    ) RETURN NUMBER IS
        l_count NUMBER;
        l_active_flag NUMBER := CASE WHEN p_active_only THEN 1 ELSE 0 END;
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM v_case_current_status
        WHERE (l_active_flag = 0 OR is_active = 1)
          AND (p_receipt_filter IS NULL OR receipt_number LIKE p_receipt_filter || '%')
          AND (p_status_filter IS NULL OR UPPER(current_status) LIKE '%' || UPPER(p_status_filter) || '%');
        
        RETURN l_count;
    END count_cases;
    
    -- --------------------------------------------------------
    -- case_exists
    -- --------------------------------------------------------
    FUNCTION case_exists(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_count NUMBER;
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        SELECT COUNT(*)
        INTO l_count
        FROM case_history
        WHERE receipt_number = l_receipt;
        
        RETURN l_count > 0;
    END case_exists;
    
    -- --------------------------------------------------------
    -- get_cases_by_receipts
    -- --------------------------------------------------------
    FUNCTION get_cases_by_receipts(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        IF p_receipt_numbers IS NULL OR p_receipt_numbers.COUNT = 0 THEN
            OPEN l_cursor FOR SELECT * FROM v_case_current_status WHERE 1=0;
            RETURN l_cursor;
        END IF;

        OPEN l_cursor FOR
            SELECT *
            FROM v_case_current_status
            WHERE receipt_number IN (
                SELECT uscis_util_pkg.normalize_receipt_number(COLUMN_VALUE) 
                FROM TABLE(p_receipt_numbers)
            )
            ORDER BY last_updated DESC;
        
        RETURN l_cursor;
    END get_cases_by_receipts;
    
    -- --------------------------------------------------------
    -- get_cases_due_for_check
    -- --------------------------------------------------------
    FUNCTION get_cases_due_for_check(
        p_limit IN NUMBER DEFAULT 50
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT *
            FROM v_cases_due_for_check
            ORDER BY last_checked_at NULLS FIRST, receipt_number
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN l_cursor;
    END get_cases_due_for_check;
    
    -- --------------------------------------------------------
    -- update_case_notes
    -- --------------------------------------------------------
    PROCEDURE update_case_notes(
        p_receipt_number IN VARCHAR2,
        p_notes          IN CLOB
    ) IS
        l_receipt   VARCHAR2(13);
        l_old_notes CLOB;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Get old notes for audit
        SELECT notes INTO l_old_notes
        FROM case_history
        WHERE receipt_number = l_receipt;
        
        UPDATE case_history
        SET notes = p_notes
        WHERE receipt_number = l_receipt;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
        
        -- Audit the change
        uscis_audit_pkg.log_update(
            l_receipt, 
            'notes', 
            SUBSTR(l_old_notes, 1, 100), 
            SUBSTR(p_notes, 1, 100)
        );
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
    END update_case_notes;
    
    -- --------------------------------------------------------
    -- set_case_active
    -- --------------------------------------------------------
    PROCEDURE set_case_active(
        p_receipt_number IN VARCHAR2,
        p_is_active      IN BOOLEAN
    ) IS
        l_receipt    VARCHAR2(13);
        l_old_active NUMBER;
        l_new_active NUMBER := CASE WHEN p_is_active THEN 1 ELSE 0 END;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Get old value for audit
        SELECT is_active INTO l_old_active
        FROM case_history
        WHERE receipt_number = l_receipt;
        
        UPDATE case_history
        SET is_active = l_new_active
        WHERE receipt_number = l_receipt;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
        
        IF l_old_active != l_new_active THEN
            uscis_audit_pkg.log_update(
                l_receipt, 
                'is_active', 
                TO_CHAR(l_old_active), 
                TO_CHAR(l_new_active)
            );
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
    END set_case_active;
    
    -- --------------------------------------------------------
    -- update_last_checked
    -- --------------------------------------------------------
    PROCEDURE update_last_checked(
        p_receipt_number IN VARCHAR2
    ) IS
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        UPDATE case_history
        SET last_checked_at = SYSTIMESTAMP
        WHERE receipt_number = l_receipt;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
    END update_last_checked;
    
    -- --------------------------------------------------------
    -- set_check_frequency
    -- --------------------------------------------------------
    PROCEDURE set_check_frequency(
        p_receipt_number IN VARCHAR2,
        p_hours          IN NUMBER
    ) IS
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Validate range (1 hour to 30 days), reject NULL
        IF p_hours IS NULL OR p_hours < 1 OR p_hours > 720 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_invalid_frequency,
                'Check frequency must be between 1 and 720 hours'
            );
        END IF;
        
        UPDATE case_history
        SET check_frequency = p_hours
        WHERE receipt_number = l_receipt;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
    END set_check_frequency;
    
    -- --------------------------------------------------------
    -- delete_case
    -- --------------------------------------------------------
    PROCEDURE delete_case(
        p_receipt_number IN VARCHAR2
    ) IS
        l_receipt   VARCHAR2(13);
        l_case_type VARCHAR2(100);
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Get case type for audit before delete
        BEGIN
            SELECT case_type INTO l_case_type
            FROM v_case_current_status
            WHERE receipt_number = l_receipt;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_case_type := NULL;
        END;
        
        -- Delete (cascades to status_updates)
        DELETE FROM case_history
        WHERE receipt_number = l_receipt;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
        END IF;
        
        -- Audit the deletion
        uscis_audit_pkg.log_delete(l_receipt, l_case_type);
        
    END delete_case;
    
    -- --------------------------------------------------------
    -- delete_cases
    -- --------------------------------------------------------
    PROCEDURE delete_cases(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    ) IS
    BEGIN
        IF p_receipt_numbers IS NULL OR p_receipt_numbers.COUNT = 0 THEN
            RETURN;
        END IF;
        
        FOR i IN 1..p_receipt_numbers.COUNT LOOP
            BEGIN
                delete_case(p_receipt_numbers(i));
            EXCEPTION
                WHEN OTHERS THEN
                    -- Log but continue with other deletes (mask receipt for privacy)
                    uscis_util_pkg.log_error(
                        'Failed to delete case ' || uscis_util_pkg.mask_receipt_number(p_receipt_numbers(i)) || ': ' || SQLERRM,
                        gc_package_name
                    );
            END;
        END LOOP;
    END delete_cases;
    
    -- --------------------------------------------------------
    -- purge_inactive_cases
    -- --------------------------------------------------------
    PROCEDURE purge_inactive_cases(
        p_days_old IN NUMBER DEFAULT 365
    ) IS
        l_deleted NUMBER := 0;
    BEGIN
        FOR rec IN (
            SELECT receipt_number
            FROM case_history
            WHERE is_active = 0
              AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(p_days_old, 'DAY')
        ) LOOP
            BEGIN
                delete_case(rec.receipt_number);
                l_deleted := l_deleted + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Log error with masked receipt (matching delete_cases pattern) and continue
                    uscis_util_pkg.log_error(
                        'Failed to purge case ' || uscis_util_pkg.mask_receipt_number(rec.receipt_number),
                        gc_package_name,
                        SQLCODE
                    );
            END;
        END LOOP;
        
        uscis_util_pkg.log_debug(
            'Purged ' || l_deleted || ' inactive cases older than ' || p_days_old || ' days',
            gc_package_name
        );
    END purge_inactive_cases;
    
    -- --------------------------------------------------------
    -- get_status_history
    -- --------------------------------------------------------
    FUNCTION get_status_history(
        p_receipt_number IN VARCHAR2,
        p_limit          IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR IS
        l_receipt VARCHAR2(13);
        l_cursor  SYS_REFCURSOR;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        OPEN l_cursor FOR
            SELECT *
            FROM v_status_history
            WHERE receipt_number = l_receipt
            ORDER BY last_updated DESC
            FETCH FIRST p_limit ROWS ONLY;
        
        RETURN l_cursor;
    END get_status_history;
    
    -- --------------------------------------------------------
    -- get_latest_status
    -- --------------------------------------------------------
    FUNCTION get_latest_status(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status IS
        l_receipt VARCHAR2(13);
        l_status  uscis_types_pkg.t_case_status;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        SELECT 
            receipt_number,
            case_type,
            current_status,
            last_updated,
            details
        INTO 
            l_status.receipt_number,
            l_status.case_type,
            l_status.current_status,
            l_status.last_updated,
            l_status.details
        FROM v_case_current_status
        WHERE receipt_number = l_receipt;
        
        RETURN l_status;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_case_not_found,
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_receipt)
            );
    END get_latest_status;

    -- --------------------------------------------------------
    -- count_status_updates
    -- --------------------------------------------------------
    FUNCTION count_status_updates(
        p_receipt_number IN VARCHAR2
    ) RETURN NUMBER IS
        l_receipt VARCHAR2(13);
        l_count   NUMBER;
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        SELECT COUNT(*)
        INTO l_count
        FROM status_updates
        WHERE receipt_number = l_receipt;
        
        RETURN l_count;
    END count_status_updates;

END uscis_case_pkg;
/

SHOW ERRORS PACKAGE uscis_case_pkg
SHOW ERRORS PACKAGE BODY uscis_case_pkg

PROMPT ============================================================
PROMPT USCIS_CASE_PKG created successfully
PROMPT ============================================================