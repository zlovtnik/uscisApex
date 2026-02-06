-- ============================================================
-- Fix: Add missing columns to CASE_HISTORY table
-- ============================================================
-- File:    scripts/fix_missing_columns.sql
-- Purpose: Adds check_frequency and notifications_enabled columns
--          if they don't already exist, then recreates dependent
--          views that reference them.
--
-- Root cause: The deployed database was provisioned before these
--   columns were added to install_all_v2.sql, so the table lacks
--   them and all views referencing them are invalid.
--
-- Run via: SQL*Plus / SQLcl connected as USCIS_APP
--   @scripts/fix_missing_columns.sql
--
-- Safe to re-run: Yes (all statements are idempotent)
-- ============================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ============================================================
PROMPT Checking CASE_HISTORY for missing columns...
PROMPT ============================================================

-- ---------- check_frequency ----------
DECLARE
    l_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM user_tab_columns
     WHERE table_name  = 'CASE_HISTORY'
       AND column_name = 'CHECK_FREQUENCY';

    IF l_count = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE case_history ADD (check_frequency NUMBER DEFAULT 24)';
    END IF;

    SELECT COUNT(*) INTO l_count
      FROM user_constraints
     WHERE table_name = 'CASE_HISTORY'
       AND constraint_name = 'CHK_CHECK_FREQUENCY';

    IF l_count = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE case_history ADD CONSTRAINT chk_check_frequency '
         || 'CHECK (check_frequency >= 1 AND check_frequency <= 720)';
        DBMS_OUTPUT.PUT_LINE('Added constraint: CHK_CHECK_FREQUENCY');
    END IF;
END;
/

-- ---------- notifications_enabled ----------
DECLARE
    l_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM user_tab_columns
     WHERE table_name  = 'CASE_HISTORY'
       AND column_name = 'NOTIFICATIONS_ENABLED';

    IF l_count = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE case_history ADD (notifications_enabled NUMBER(1) DEFAULT 0 NOT NULL)';
        EXECUTE IMMEDIATE
            'ALTER TABLE case_history ADD CONSTRAINT chk_notifications_enabled '
         || 'CHECK (notifications_enabled IN (0, 1))';
        DBMS_OUTPUT.PUT_LINE('Added column: CASE_HISTORY.NOTIFICATIONS_ENABLED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Column already exists: CASE_HISTORY.NOTIFICATIONS_ENABLED');
    END IF;
END;
/

PROMPT
PROMPT ============================================================
PROMPT Recreating dependent views...
PROMPT ============================================================

-- 1. V_CASE_CURRENT_STATUS (primary view; references both columns)
CREATE OR REPLACE VIEW v_case_current_status AS
WITH latest_status AS (
    SELECT
        receipt_number,
        MAX(id) AS max_id
    FROM status_updates
    GROUP BY receipt_number
)
SELECT
    ch.receipt_number,
    ch.created_at           AS tracking_since,
    ch.created_by,
    ch.notes,
    ch.is_active,
    ch.last_checked_at,
    ch.check_frequency,
    ch.notifications_enabled,
    su.case_type,
    su.current_status,
    su.last_updated,
    su.details,
    su.source               AS last_update_source,
    (SELECT COUNT(*)
     FROM status_updates s2
     WHERE s2.receipt_number = ch.receipt_number) AS total_updates,
    ROUND(SYSDATE - CAST(su.last_updated AS DATE), 1) AS days_since_update,
    ROUND((SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24, 1) AS hours_since_check,
    CASE
        WHEN ch.is_active = 1
             AND (ch.last_checked_at IS NULL
                  OR (SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24 >= ch.check_frequency)
        THEN 'Y'
        ELSE 'N'
    END AS check_due_flag
FROM case_history ch
LEFT JOIN latest_status ls ON ls.receipt_number = ch.receipt_number
LEFT JOIN status_updates su ON su.id = ls.max_id;

PROMPT Recreated view: V_CASE_CURRENT_STATUS

-- 2. V_CASE_DASHBOARD (depends on V_CASE_CURRENT_STATUS)
CREATE OR REPLACE VIEW v_case_dashboard AS
SELECT
    current_status,
    COUNT(*)                AS case_count,
    MIN(last_updated)       AS oldest_update,
    MAX(last_updated)       AS newest_update,
    AVG(days_since_update)  AS avg_days_since_update,
    SUM(CASE WHEN check_due_flag = 'Y' THEN 1 ELSE 0 END) AS checks_due
FROM v_case_current_status
WHERE is_active = 1
GROUP BY current_status;

PROMPT Recreated view: V_CASE_DASHBOARD

-- 3. V_RECENT_ACTIVITY (depends on V_CASE_CURRENT_STATUS)
CREATE OR REPLACE VIEW v_recent_activity AS
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
        WHEN 'INSERT' THEN 'Added case '    || cal.receipt_number
        WHEN 'UPDATE' THEN 'Updated case '  || cal.receipt_number
        WHEN 'DELETE' THEN 'Deleted case '   || cal.receipt_number
        WHEN 'CHECK'  THEN 'Checked status for ' || cal.receipt_number
        WHEN 'EXPORT' THEN 'Exported cases'
        WHEN 'IMPORT' THEN 'Imported cases'
        ELSE cal.action
    END AS action_description
FROM case_audit_log cal
LEFT JOIN v_case_current_status vcs
    ON vcs.receipt_number = cal.receipt_number;

PROMPT Recreated view: V_RECENT_ACTIVITY

-- 4. V_CASES_DUE_FOR_CHECK (depends on case_history + V_CASE_CURRENT_STATUS)
CREATE OR REPLACE VIEW v_cases_due_for_check AS
SELECT
    ch.receipt_number,
    ch.last_checked_at,
    ch.check_frequency,
    ROUND((SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24, 1) AS hours_overdue,
    vcs.current_status,
    vcs.case_type
FROM case_history ch
LEFT JOIN v_case_current_status vcs
    ON vcs.receipt_number = ch.receipt_number
WHERE ch.is_active = 1
  AND (ch.last_checked_at IS NULL
       OR (SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24 >= ch.check_frequency);

PROMPT Recreated view: V_CASES_DUE_FOR_CHECK

-- Recompile any remaining invalid objects
BEGIN
    FOR obj IN (
        SELECT object_name, object_type
          FROM user_objects
         WHERE status = 'INVALID'
           AND object_type IN ('VIEW', 'PACKAGE', 'PACKAGE BODY',
                               'TRIGGER', 'FUNCTION', 'PROCEDURE')
         ORDER BY DECODE(object_type,
                    'VIEW', 1, 'PACKAGE', 2, 'PACKAGE BODY', 3,
                    'TRIGGER', 4, 5)
    ) LOOP
        BEGIN
            IF obj.object_type = 'PACKAGE BODY' THEN
                EXECUTE IMMEDIATE 'ALTER PACKAGE ' || obj.object_name || ' COMPILE BODY';
            ELSE
                EXECUTE IMMEDIATE 'ALTER ' || obj.object_type || ' '
                               || obj.object_name || ' COMPILE';
            END IF;
            DBMS_OUTPUT.PUT_LINE('Recompiled: ' || obj.object_type || ' ' || obj.object_name);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('WARNING: Failed to compile '
                    || obj.object_type || ' ' || obj.object_name
                    || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

PROMPT
PROMPT ============================================================
PROMPT Verification
PROMPT ============================================================

SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN (
    'V_CASE_CURRENT_STATUS', 'V_CASE_DASHBOARD',
    'V_RECENT_ACTIVITY', 'V_CASES_DUE_FOR_CHECK'
 )
 ORDER BY object_name;

PROMPT
PROMPT Done. If all views show VALID, the Page 3 error is resolved.
PROMPT ============================================================
