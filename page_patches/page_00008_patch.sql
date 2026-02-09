-- ============================================================
-- Page 8 Patch: Administration Page — Full Build
-- ============================================================
-- File: page_patches/page_00008_patch.sql
--
-- Roadmap IDs: 4.5.4, 4.5.5, 4.5.6, 4.5.7
--   4.5.4  Build Administration page (Page 8)
--   4.5.5  Add audit logs viewer
--   4.5.6  Add job scheduler status panel
--   4.5.7  Add system health indicators
--
-- Prerequisites:
--   - USCIS_AUDIT_PKG (package 03) installed with get_recent_activity, purge_old_records
--   - USCIS_SCHEDULER_PKG (package 07) installed with get_job_status
--   - USCIS_OAUTH_PKG (package 05) installed with has_credentials, clear_token
--   - CASE_AUDIT_LOG table exists
--   - USER_SCHEDULER_JOBS / USER_SCHEDULER_RUNNING_JOBS accessible
--
-- Apply via: Page Designer — create new Page 8 as Normal page
-- ============================================================


-- ============================================================
-- STEP 1: Create Page 8 — Normal Page
-- ============================================================
-- In Page Designer → Create Page:
--   Page Number:      8
--   Name:             Administration
--   Title:            Administration
--   Page Mode:        Normal
--   Page Alias:       admin
--   Page Group:       Administration
--   Page Template:    Left Side Column (or standard)
--   Authorization:    ADMIN_ROLE
--   Navigation Menu:
--     Label: Administration
--     Icon:  fa-shield
--     Parent: (root)


-- ============================================================
-- STEP 2: Create Region Display Selector
-- ============================================================
-- Create Region:
--   Name:        Admin Tabs
--   Type:        Region Display Selector
--   Position:    Body (Sequence 5)
--   Template:    (default)
--
-- This region enables tab-based navigation between the
-- sub-regions: System Health, Audit Logs, Scheduler Jobs.


-- ============================================================
-- STEP 3: Breadcrumb Bar
-- ============================================================
-- Region: Breadcrumb
--   Type:         Breadcrumb
--   Position:     Breadcrumb Bar
--   Breadcrumb:   Application Breadcrumb
--   Entry:        Administration


-- ============================================================
-- ================================================================
-- REGION 1: System Health (Cards Layout)
-- ================================================================
-- Roadmap 4.5.7 — Add system health indicators
-- ============================================================
-- Create Region:
--   Name:          System Health
--   Type:          Classic Report
--   Position:      Body (Sequence 10)
--   Parent Region: Admin Tabs
--   Template:      Cards
--   Card Template Options:
--     Icons: Yes
--     Style: Basic
--   Include in RDS: Yes
--   Icon:          fa-heartbeat
--
-- Source SQL:

/*
SELECT
    component,
    status,
    icon_class,
    detail,
    CASE
        WHEN status IN ('Healthy', 'Configured', 'Running')
            THEN 'u-success'
        WHEN status IN ('Warning', 'Degraded')
            THEN 'u-warning'
        ELSE 'u-danger'
    END AS card_color
FROM (
    -- Database Health
    SELECT
        'Database' AS component,
        'Healthy' AS status,
        'fa-database' AS icon_class,
        (SELECT TO_CHAR(SUM(bytes)/1024/1024, 'FM999,999.0') || ' MB'
           FROM user_segments) AS detail,
        1 AS sort_order
    FROM dual
    UNION ALL
    -- Scheduler Jobs
    SELECT
        'Scheduler Jobs',
        CASE
            WHEN (SELECT COUNT(*) FROM user_scheduler_jobs WHERE enabled = 'TRUE') > 0
                THEN 'Running'
            ELSE 'No Active Jobs'
        END,
        'fa-clock-o',
        (SELECT COUNT(*) || ' active job(s)'
           FROM user_scheduler_jobs
          WHERE enabled = 'TRUE'),
        2
    FROM dual
    UNION ALL
    -- API Connection
    SELECT
        'API Connection',
        CASE WHEN uscis_oauth_pkg.has_credentials
             THEN 'Configured'
             ELSE 'Not Configured'
        END,
        'fa-plug',
        CASE WHEN uscis_oauth_pkg.has_credentials
             THEN (SELECT 'Token expires: '
                       || NVL(TO_CHAR(expires_at, 'HH:MI AM'), 'N/A')
                     FROM oauth_tokens
                    WHERE service_name = 'USCIS_API'
                    ORDER BY expires_at DESC
                    FETCH FIRST 1 ROW ONLY)
             ELSE 'No credentials found'
        END,
        3
    FROM dual
    UNION ALL
    -- Cases Summary
    SELECT
        'Tracked Cases',
        TO_CHAR((SELECT COUNT(*) FROM case_history)) || ' cases',
        'fa-folder-open-o',
        (SELECT COUNT(*) || ' active'
           FROM case_history
          WHERE is_active = 1),
        4
    FROM dual
    UNION ALL
    -- Audit Log Size
    SELECT
        'Audit Log',
        TO_CHAR((SELECT COUNT(*) FROM case_audit_log)) || ' records',
        'fa-file-text',
        (SELECT 'Oldest: ' || NVL(
            TO_CHAR(MIN(performed_at), 'Mon DD, YYYY'),
            'N/A')
           FROM case_audit_log),
        5
    FROM dual
)
ORDER BY sort_order
*/

-- Column Mapping (for Cards template):
--   Title:        COMPONENT
--   Body:         DETAIL
--   Icon Source:   ICON_CLASS
--   Badge:        STATUS
--   CSS Classes:  CARD_COLOR

-- Buttons in this region:

-- BTN_CLEAR_TOKEN — Clear OAuth Token
-- Settings:
--   Label:            Clear OAuth Token
--   Action:           Submit Page
--   Request Value:    CLEAR_TOKEN
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-refresh
--   CSS Classes:      t-Button--warning t-Button--small
--   Confirm Message:  Force a token refresh? The current token will
--                      be deleted and a new one fetched on next API call.

-- BTN_REFRESH_HEALTH — Refresh
-- Settings:
--   Label:            Refresh
--   Action:           Redirect to Page 8
--   Position:         Region Body (Right of Title)
--   Button Template:  Icon Only
--   Icon:             fa-refresh
--   CSS Classes:      t-Button--small


-- ============================================================
-- ================================================================
-- REGION 2: Audit Logs (Interactive Report)
-- ================================================================
-- Roadmap 4.5.5 — Add audit logs viewer
-- ============================================================
-- Create Region:
--   Name:          Audit Logs
--   Type:          Interactive Report
--   Position:      Body (Sequence 20)
--   Parent Region: Admin Tabs
--   Include in RDS: Yes
--   Icon:          fa-file-text
--
-- Source SQL:

/*
SELECT
    audit_id,
    performed_at,
    action,
    receipt_number,
    performed_by,
    ip_address,
    old_values,
    new_values
FROM case_audit_log
ORDER BY performed_at DESC
*/

-- Report Attributes:
--   Pagination:       Scroll (100 rows per page)
--   Show Row Count:   Yes
--   Download:         CSV, Excel
--   Search Bar:       Yes
--   Actions Menu:     Yes (Filter, Highlight, Sort, etc.)

-- Column Configuration:
--
-- AUDIT_ID
--   Type:             Hidden
--
-- PERFORMED_AT
--   Heading:          Date/Time
--   Format Mask:      DD-MON-YYYY HH24:MI:SS
--   Width:            160px
--   Sort:             Default (DESC)
--   Group:            When/Who
--
-- ACTION
--   Heading:          Action
--   Width:            140px
--   Group:            What
--   HTML Expression (for badge display):

/*
<span class="t-Badge t-Badge--small
  #CASE WHEN ACTION IN ('DELETE','CASE_DELETED') THEN 'u-danger'
        WHEN ACTION LIKE '%INSERT%' OR ACTION = 'CASE_ADDED' THEN 'u-success'
        WHEN ACTION LIKE '%UPDATE%' OR ACTION = 'SETTINGS_UPDATED' THEN 'u-info'
        WHEN ACTION LIKE '%CHECK%' OR ACTION = 'STATUS_CHECK' THEN 'u-warning'
        WHEN ACTION LIKE '%EXPORT%' THEN 'u-color-14'
        WHEN ACTION LIKE '%IMPORT%' THEN 'u-color-16'
        ELSE '' END#">
  #ACTION#
</span>
*/

-- NOTE: The above HTML Expression uses APEX substitution syntax.
-- The nested CASE is evaluated by the report engine, not PL/SQL.
-- Alternatively, use the column CSS Classes attribute with a
-- computed column for simpler maintenance.

-- RECEIPT_NUMBER
--   Heading:          Receipt #
--   Width:            140px
--   Group:            What
--   Link:
--     Target Page:    3
--     Items:          P3_RECEIPT_NUMBER = #RECEIPT_NUMBER#
--   Link Condition:   RECEIPT_NUMBER IS NOT NULL

-- PERFORMED_BY
--   Heading:          User
--   Width:            120px
--   Group:            When/Who

-- IP_ADDRESS
--   Heading:          IP Address
--   Width:            120px
--   Group:            When/Who
--   Visible:          No (hidden by default, available in Actions)

-- OLD_VALUES
--   Heading:          Previous Values
--   Width:            200px
--   Group:            Details
--   Display As:       Plain Text (escape special characters)
--   Visible:          No (hidden by default)

-- NEW_VALUES
--   Heading:          New Values
--   Width:            200px
--   Group:            Details
--   Display As:       Plain Text (escape special characters)
--   Visible:          No (hidden by default)

-- Buttons in this region:

-- BTN_PURGE_AUDIT — Purge Old Audit Logs
-- Settings:
--   Label:            Purge Old Logs
--   Action:           Submit Page
--   Request Value:    PURGE_AUDIT
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-trash-o
--   CSS Classes:      t-Button--danger t-Button--small
--   Confirm Message:  Delete audit log records older than 90 days?
--                      This action cannot be undone.


-- ============================================================
-- ================================================================
-- REGION 3: Scheduler Jobs (Interactive Report)
-- ================================================================
-- Roadmap 4.5.6 — Add job scheduler status panel
-- ============================================================
-- Create Region:
--   Name:          Scheduler Jobs
--   Type:          Interactive Report
--   Position:      Body (Sequence 30)
--   Parent Region: Admin Tabs
--   Include in RDS: Yes
--   Icon:          fa-clock-o
--
-- Source SQL:

/*
SELECT
    j.job_name,
    j.job_action,
    j.start_date,
    j.repeat_interval,
    j.next_run_date,
    j.last_start_date,
    CASE
        WHEN j.last_run_duration IS NOT NULL THEN
            CASE
                WHEN EXTRACT(HOUR FROM j.last_run_duration) > 0 THEN
                    EXTRACT(HOUR FROM j.last_run_duration) || 'h '
                    || EXTRACT(MINUTE FROM j.last_run_duration) || 'm '
                    || ROUND(EXTRACT(SECOND FROM j.last_run_duration)) || 's'
                ELSE
                    EXTRACT(MINUTE FROM j.last_run_duration) || 'm '
                    || ROUND(EXTRACT(SECOND FROM j.last_run_duration)) || 's'
            END
        ELSE 'N/A'
    END AS run_duration_display,
    j.enabled,
    j.state,
    CASE
        WHEN j.enabled = 'TRUE' AND j.state = 'SCHEDULED' THEN 'u-success'
        WHEN j.enabled = 'TRUE' AND j.state = 'RUNNING'   THEN 'u-info'
        WHEN j.enabled = 'FALSE'                           THEN 'u-warning'
        ELSE 'u-color-7'
    END AS state_css,
    uscis_scheduler_pkg.get_job_status(j.job_name) AS detailed_status
FROM user_scheduler_jobs j
ORDER BY j.job_name
*/

-- Report Attributes:
--   Pagination:     Scroll (50 rows)
--   Download:       CSV
--   Search Bar:     Yes

-- Column Configuration:
--
-- JOB_NAME
--   Heading:          Job Name
--   Width:            200px
--
-- JOB_ACTION
--   Heading:          Action
--   Width:            200px
--   Visible:          No (hidden by default)
--
-- START_DATE
--   Heading:          Start Date
--   Format Mask:      DD-MON-YYYY HH24:MI
--   Visible:          No (hidden by default)
--
-- REPEAT_INTERVAL
--   Heading:          Schedule
--   Width:            200px
--
-- NEXT_RUN_DATE
--   Heading:          Next Run
--   Format Mask:      DD-MON-YYYY HH24:MI
--   Width:            160px
--
-- LAST_START_DATE
--   Heading:          Last Run
--   Format Mask:      DD-MON-YYYY HH24:MI
--   Width:            160px
--
-- RUN_DURATION_DISPLAY
--   Heading:          Duration
--   Width:            100px
--
-- ENABLED
--   Heading:          Enabled
--   Width:            80px
--   HTML Expression:
/*
<span class="fa #CASE WHEN ENABLED = 'TRUE'
    THEN 'fa-check-circle u-success-text'
    ELSE 'fa-times-circle u-danger-text' END#"></span>
*/
--
-- STATE
--   Heading:          State
--   Width:            100px
--   CSS Classes:      (use STATE_CSS column — see below)
--   HTML Expression:
/*
<span class="t-Badge t-Badge--small #STATE_CSS#">#STATE#</span>
*/
--
-- STATE_CSS
--   Type:             Hidden (used by STATE column HTML)
--
-- DETAILED_STATUS
--   Heading:          Details
--   Width:            200px

-- Buttons in this region:

-- BTN_RUN_NOW — Run Auto-Check Now
-- Settings:
--   Label:            Run Auto-Check Now
--   Action:           Submit Page
--   Request Value:    RUN_AUTO_CHECK
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-play
--   CSS Classes:      t-Button--success t-Button--small
--   Confirm Message:  Run the automatic status check now?
--                      This will check all active cases.

-- BTN_CREATE_JOBS — Create All Jobs
-- Settings:
--   Label:            Create All Jobs
--   Action:           Submit Page
--   Request Value:    CREATE_JOBS
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-plus-circle
--   CSS Classes:      t-Button--primary t-Button--small
--   Confirm Message:  Create or recreate all scheduler jobs
--                      (auto-check, token refresh, cleanup)?

-- BTN_DROP_JOBS — Drop All Jobs
-- Settings:
--   Label:            Drop All Jobs
--   Action:           Submit Page
--   Request Value:    DROP_JOBS
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-trash-o
--   CSS Classes:      t-Button--danger t-Button--small
--   Confirm Message:  Drop all scheduler jobs? This will stop all
--                      automatic processing.


-- ============================================================
-- ================================================================
-- STEP 10: Processing — After Submit Processes
-- ================================================================
-- ============================================================

-- Process 1: Purge Audit Logs
-- In Page Designer → Processing → Create Process:
--   Name:        Purge Audit Logs
--   Type:        PL/SQL Code
--   Sequence:    10
--   Point:       Processing
--   When Request: PURGE_AUDIT
--   Success Message: Audit logs older than 90 days have been purged.
--
-- PL/SQL Code:

/*
BEGIN
    uscis_audit_pkg.purge_old_records(p_days_to_keep => 90);
END;
*/


-- Process 2: Clear OAuth Token
-- In Page Designer → Processing → Create Process:
--   Name:        Clear OAuth Token
--   Type:        PL/SQL Code
--   Sequence:    20
--   Point:       Processing
--   When Request: CLEAR_TOKEN
--   Success Message: OAuth token cleared. A new token will be
--                     fetched on the next API call.
--
-- PL/SQL Code:

/*
BEGIN
    uscis_oauth_pkg.clear_token;
END;
*/


-- Process 3: Run Auto-Check Now
-- In Page Designer → Processing → Create Process:
--   Name:        Run Auto-Check Now
--   Type:        PL/SQL Code
--   Sequence:    30
--   Point:       Processing
--   When Request: RUN_AUTO_CHECK
--   Success Message: Automatic status check started.
--
-- PL/SQL Code:

/*
BEGIN
    uscis_scheduler_pkg.run_auto_check;
END;
*/

-- NOTE: run_auto_check can take a while if there are many cases.
-- Consider showing a spinner or running via DBMS_SCHEDULER.RUN_JOB
-- in the background instead. For an immediate approach:

/*
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name            => 'USCIS_AUTO_CHECK_JOB',
        use_current_session => FALSE   -- run in background
    );
END;
*/


-- Process 4: Create All Jobs
-- In Page Designer → Processing → Create Process:
--   Name:        Create All Jobs
--   Type:        PL/SQL Code
--   Sequence:    40
--   Point:       Processing
--   When Request: CREATE_JOBS
--   Success Message: All scheduler jobs have been created.
--
-- PL/SQL Code:

/*
BEGIN
    uscis_scheduler_pkg.create_all_jobs;
END;
*/


-- Process 5: Drop All Jobs
-- In Page Designer → Processing → Create Process:
--   Name:        Drop All Jobs
--   Type:        PL/SQL Code
--   Sequence:    50
--   Point:       Processing
--   When Request: DROP_JOBS
--   Success Message: All scheduler jobs have been dropped.
--
-- PL/SQL Code:

/*
BEGIN
    uscis_scheduler_pkg.drop_all_jobs;
END;
*/


-- ============================================================
-- ================================================================
-- STEP 11: Page CSS (add to app-styles.css per R-11)
-- ================================================================
-- ============================================================
-- Per R-11 (CSP compliance), add these styles to
-- shared_components/files/app-styles.css:

/*
-- === Administration Page (Page 8) ===

-- Audit action badges
.admin-audit-action .t-Badge {
    font-size: 11px;
    padding: 2px 8px;
}

-- Scheduler job state badges
.admin-job-state .t-Badge {
    font-size: 11px;
    padding: 2px 8px;
}

-- Health cards — equal height
.admin-health-cards .t-Cards-item {
    min-height: 120px;
}
*/


-- ============================================================
-- END OF PAGE 8 PATCH
-- ============================================================
-- Summary of items created:
--
--   Page Regions:
--     Admin Tabs (Region Display Selector)
--     System Health (Classic Report / Cards)
--     Audit Logs (Interactive Report)
--     Scheduler Jobs (Interactive Report)
--
--   Buttons:
--     BTN_CLEAR_TOKEN, BTN_REFRESH_HEALTH
--     BTN_PURGE_AUDIT
--     BTN_RUN_NOW, BTN_CREATE_JOBS, BTN_DROP_JOBS
--
--   Processes (After Submit):
--     Purge Audit Logs (PURGE_AUDIT)
--     Clear OAuth Token (CLEAR_TOKEN)
--     Run Auto-Check Now (RUN_AUTO_CHECK)
--     Create All Jobs (CREATE_JOBS)
--     Drop All Jobs (DROP_JOBS)
--
--   Interactive Report Column Groups (Audit Logs):
--     When/Who: performed_at, performed_by, ip_address
--     What: action, receipt_number
--     Details: old_values, new_values
--
--   Authorization:
--     ADMIN_ROLE required for page access
-- ============================================================
