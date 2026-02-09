-- ============================================================
-- USCIS Case Tracker - Global Error Handler Package
-- Task 3.4.4: Create global error handler
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/10_uscis_error_pkg.sql
-- Purpose: APEX application-level error handling function.
--          Registered in App → Shared Components → Application
--          Definition → Error Handling Function:
--            uscis_error_pkg.handle_error
--          Sanitizes internal errors, maps ORA-200xx to
--          user-friendly messages, logs context, and auto-maps
--          constraint violations to page items.
-- Dependencies: USCIS_TYPES_PKG, USCIS_AUDIT_PKG
-- ============================================================

-- Create sequence for atomic error reference IDs (idempotent)
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_exists
      FROM user_sequences
     WHERE sequence_name = 'USCIS_ERROR_REF_SEQ';
    IF l_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE uscis_error_ref_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    END IF;
END;
/

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_ERROR_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_error_pkg
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version      CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name CONSTANT VARCHAR2(30) := 'USCIS_ERROR_PKG';

    -- ========================================================
    -- APEX Error Handling Callback
    -- ========================================================

    /**
     * Global error handling function for the APEX application.
     *
     * Register in Shared Components → Application Definition →
     *   Error Handling → Error Handling Function:
     *   uscis_error_pkg.handle_error
     *
     * Behaviour:
     *   1. Internal APEX errors (p_error.is_internal_error) that
     *      are NOT common runtime errors → masked with a generic
     *      message; original logged via log_error_detail.
     *   2. Application -200xx RAISE_APPLICATION_ERROR codes →
     *      mapped to friendly text via get_friendly_message.
     *   3. Constraint violations (ORA-00001, -02290, -02291,
     *      -02292, -02091) → looked up by constraint name.
     *   4. All other ORA errors → first ORA error text extracted.
     *   5. If no page item is set, auto_set_associated_item is
     *      called to guess the affected field.
     *
     * @param p_error  APEX error record
     * @return         APEX error result
     */
    FUNCTION handle_error(
        p_error IN apex_error.t_error
    ) RETURN apex_error.t_error_result;

    -- ========================================================
    -- Friendly Message Mapping
    -- ========================================================

    /**
     * Map an ORA error code (typically -200xx from
     * RAISE_APPLICATION_ERROR) to a user-friendly message.
     * Returns NULL if no mapping exists.
     *
     * @param p_ora_sqlcode  The SQLCODE (e.g. -20001)
     * @return Friendly message text, or NULL
     */
    FUNCTION get_friendly_message(
        p_ora_sqlcode IN NUMBER
    ) RETURN VARCHAR2;

    -- ========================================================
    -- Error Logging (Autonomous Transaction)
    -- ========================================================

    /**
     * Log an error detail record for help-desk investigation.
     * Uses an autonomous transaction so the log survives
     * rollbacks. Returns a reference ID for display.
     *
     * @param p_error  The APEX error record
     * @return Numeric reference ID
     */
    FUNCTION log_error_detail(
        p_error IN apex_error.t_error
    ) RETURN NUMBER;

END uscis_error_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_error_pkg AS

    -- --------------------------------------------------------
    -- Private: Sequence-based reference ID generator
    -- Uses dedicated Oracle sequence for atomic, race-free IDs.
    -- --------------------------------------------------------
    FUNCTION next_reference_id RETURN NUMBER IS
        l_id  NUMBER;
        l_err VARCHAR2(4000);
    BEGIN
        SELECT uscis_error_ref_seq.NEXTVAL
          INTO l_id
          FROM DUAL;
        RETURN l_id;
    EXCEPTION
        WHEN OTHERS THEN
            -- Capture diagnostic info before returning fallback
            l_err := SQLERRM || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            -- Log the sequence failure so it can be investigated
            apex_debug.error(
                'uscis_error_pkg.next_reference_id failed: %s', l_err);

            -- Fallback: timestamp-based pseudo-ID
            -- Use shortened format (YYMMDDHH24MISS = 12 digits) to fit
            -- the display mask '999G999G999G990' (max ~13 digits)
            RETURN TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'YYMMDDHH24MISS'));
    END next_reference_id;

    -- --------------------------------------------------------
    -- log_error_detail  (autonomous transaction)
    -- --------------------------------------------------------
    FUNCTION log_error_detail(
        p_error IN apex_error.t_error
    ) RETURN NUMBER IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_ref_id NUMBER;
    BEGIN
        l_ref_id := next_reference_id;

        -- Log to CASE_AUDIT_LOG with action = 'ERROR'
        INSERT INTO case_audit_log (
            receipt_number,
            action,
            old_values,
            new_values,
            performed_by,
            ip_address
        ) VALUES (
            'SYSTEM',
            'ERROR',
            -- old_values: structured error context
            JSON_OBJECT(
                'reference_id'  VALUE l_ref_id,
                'ora_sqlcode'   VALUE p_error.ora_sqlcode,
                'message'       VALUE SUBSTR(p_error.message, 1, 2000),
                'component'     VALUE SUBSTR(
                    p_error.component.type || ':' || p_error.component.name, 1, 500),
                'is_internal'   VALUE CASE WHEN p_error.is_internal_error
                                     THEN 'Y' ELSE 'N' END
            ),
            -- new_values: additional info + backtrace
            JSON_OBJECT(
                'additional_info' VALUE SUBSTR(p_error.additional_info, 1, 2000),
                'page_id'         VALUE APEX_APPLICATION.G_FLOW_STEP_ID,
                'app_id'          VALUE APEX_APPLICATION.G_FLOW_ID
            ),
            NVL(APEX_APPLICATION.G_USER, SYS_CONTEXT('USERENV', 'SESSION_USER')),
            SYS_CONTEXT('USERENV', 'IP_ADDRESS')
        );

        COMMIT;
        RETURN l_ref_id;

    EXCEPTION
        WHEN OTHERS THEN
            -- If logging itself fails, swallow the error and
            -- return a fallback reference ID.
            ROLLBACK;
            RETURN TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'YYMMDDHH24MISSFF3'));
    END log_error_detail;

    -- --------------------------------------------------------
    -- get_friendly_message
    -- --------------------------------------------------------
    FUNCTION get_friendly_message(
        p_ora_sqlcode IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_ora_sqlcode
            -- USCIS_CASE_PKG errors
            WHEN uscis_types_pkg.gc_err_invalid_receipt THEN
                'Invalid receipt number format. '
                || 'Expected 3 letters followed by 10 digits (e.g., IOE1234567890).'
            WHEN uscis_types_pkg.gc_err_case_not_found THEN
                'The requested case was not found. '
                || 'Please verify the receipt number and try again.'
            WHEN uscis_types_pkg.gc_err_duplicate_case THEN
                'This case is already being tracked. '
                || 'You can view it from your case list.'
            WHEN uscis_types_pkg.gc_err_invalid_frequency THEN
                'Invalid check frequency. Please enter a value between 1 and 720 hours.'

            -- USCIS_OAUTH_PKG errors
            WHEN uscis_types_pkg.gc_err_auth_failed THEN
                'API authentication failed. '
                || 'Please contact the administrator to verify API credentials.'
            WHEN uscis_types_pkg.gc_err_credentials_missing THEN
                'API credentials are not configured. '
                || 'Please set up USCIS API credentials in Settings.'

            -- USCIS_API_PKG errors
            WHEN uscis_types_pkg.gc_err_api_error THEN
                'The USCIS API is temporarily unavailable. '
                || 'Please try again in a few minutes.'
            WHEN uscis_types_pkg.gc_err_rate_limited THEN
                'Too many requests. Please wait a moment and try again.'

            -- USCIS_EXPORT_PKG errors
            WHEN uscis_types_pkg.gc_err_invalid_json THEN
                'The provided data could not be parsed. '
                || 'Please check the format and try again.'
            WHEN uscis_types_pkg.gc_err_export_failed THEN
                'Export failed. Please try again or contact support.'
            WHEN uscis_types_pkg.gc_err_import_failed THEN
                'Import failed. Please verify the file format and contents.'

            ELSE NULL  -- No mapping; fall through to default handling
        END;
    END get_friendly_message;

    -- --------------------------------------------------------
    -- handle_error  (APEX Error Handling callback)
    -- --------------------------------------------------------
    FUNCTION handle_error(
        p_error IN apex_error.t_error
    ) RETURN apex_error.t_error_result IS
        l_result       apex_error.t_error_result;
        l_reference_id NUMBER;
        l_friendly_msg VARCHAR2(4000);
    BEGIN
        -- Initialize the result from the incoming error
        l_result := apex_error.init_error_result(p_error => p_error);

        -- ====================================================
        -- CASE 1: Internal APEX errors (engine/framework)
        -- ====================================================
        IF p_error.is_internal_error THEN
            IF NOT p_error.is_common_runtime_error THEN
                -- Log the real error for investigation
                l_reference_id := log_error_detail(p_error);

                -- Replace with generic message (no DB internals exposed)
                l_result.message :=
                    'An unexpected application error has occurred. '
                    || 'Please contact support and provide reference #'
                    || TO_CHAR(l_reference_id, '999G999G999G990')
                    || ' for investigation.';
                l_result.additional_info := NULL;
            END IF;

        -- ====================================================
        -- CASE 2: Application RAISE_APPLICATION_ERROR (-200xx)
        -- ====================================================
        ELSIF p_error.ora_sqlcode BETWEEN -20999 AND -20000 THEN
            l_friendly_msg := get_friendly_message(p_error.ora_sqlcode);
            IF l_friendly_msg IS NOT NULL THEN
                l_result.message := l_friendly_msg;
            ELSE
                -- Unmapped -20xxx: show first ORA text only (no stack)
                l_result.message := apex_error.get_first_ora_error_text(
                                        p_error => p_error);
            END IF;

            -- Log all application errors for audit trail
            l_reference_id := log_error_detail(p_error);

        -- ====================================================
        -- CASE 3: Constraint violations (friendly mapping)
        -- ====================================================
        ELSIF p_error.ora_sqlcode IN (-1, -2091, -2290, -2291, -2292) THEN
            -- Map known constraints to friendly messages
            DECLARE
                l_constraint VARCHAR2(255);
            BEGIN
                l_constraint := apex_error.extract_constraint_name(
                                    p_error => p_error);
                CASE UPPER(l_constraint)
                    WHEN 'CASE_HISTORY_PK' THEN
                        l_result.message :=
                            'This receipt number is already being tracked.';
                    WHEN 'STATUS_UPDATES_CASE_FK' THEN
                        l_result.message :=
                            'Cannot update status: the parent case does not exist.';
                    WHEN 'CK_CASE_HISTORY_ACTIVE' THEN
                        l_result.message :=
                            'Active flag must be 0 (inactive) or 1 (active).';
                    WHEN 'CK_CASE_HISTORY_FREQUENCY' THEN
                        l_result.message :=
                            'Check frequency must be between 1 and 720 hours.';
                    ELSE
                        NULL; -- Keep original message for unknown constraints
                END CASE;
            END;

            -- Log constraint violations for audit trail
            l_reference_id := log_error_detail(p_error);

        -- ====================================================
        -- CASE 4: Other ORA errors — show first error text only
        -- ====================================================
        ELSIF p_error.ora_sqlcode IS NOT NULL
          AND l_result.message = p_error.message
        THEN
            l_result.message := apex_error.get_first_ora_error_text(
                                    p_error => p_error);

            -- Audit-log other ORA errors (mirrors CASE 3 pattern)
            l_reference_id := log_error_detail(p_error);
        END IF;

        -- ====================================================
        -- Auto-associate page item (guess from constraint/column)
        -- ====================================================
        IF l_result.page_item_name IS NULL
           AND l_result.column_alias IS NULL
        THEN
            apex_error.auto_set_associated_item(
                p_error        => p_error,
                p_error_result => l_result);
        END IF;

        RETURN l_result;

    EXCEPTION
        WHEN OTHERS THEN
            -- Last resort: never let the error handler itself crash
            apex_debug.error(
                'uscis_error_pkg.handle_error failed: %s %s',
                SQLERRM,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            l_result.message :=
                'An unexpected error occurred. Please try again.';
            l_result.additional_info := NULL;
            RETURN l_result;
    END handle_error;

END uscis_error_pkg;
/

SHOW ERRORS PACKAGE uscis_error_pkg
SHOW ERRORS PACKAGE BODY uscis_error_pkg

PROMPT ============================================================
PROMPT USCIS_ERROR_PKG created successfully
PROMPT ============================================================
PROMPT
PROMPT To register in APEX:
PROMPT   App Builder → App 102 → Edit Application Definition →
PROMPT   Error Handling → Error Handling Function:
PROMPT     uscis_error_pkg.handle_error
PROMPT ============================================================
