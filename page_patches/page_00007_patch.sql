-- ============================================================
-- Page 7 Patch: Settings Page — Full Build
-- ============================================================
-- File: page_patches/page_00007_patch.sql
--
-- Roadmap IDs: 4.5.1, 4.5.2, 4.5.3
--   4.5.1  Build Settings page (Page 7)
--   4.5.2  Add API configuration section
--   4.5.3  Add scheduler settings section
--
-- Prerequisites:
--   - USCIS_UTIL_PKG (package 02) installed with get_config / set_config
--   - USCIS_OAUTH_PKG (package 05) installed with has_credentials
--   - USCIS_SCHEDULER_PKG (package 07) installed with set_auto_check_enabled,
--     create_auto_check_job
--   - USCIS_API_PKG (package 06) installed with check_case_status
--   - SCHEDULER_CONFIG table populated with default rows
--   - API_RATE_LIMITER table exists
--
-- Apply via: Page Designer — create new Page 7 as Normal page
-- ============================================================


-- ============================================================
-- STEP 1: Create Page 7 — Normal Page
-- ============================================================
-- In Page Designer → Create Page:
--   Page Number:      7
--   Name:             Settings
--   Title:            Settings
--   Page Mode:        Normal
--   Page Group:       Administration
--   Page Template:    Left Side Column (or standard)
--   Authorization:    ADMIN_ROLE
--   Navigation Menu:
--     Label: Settings
--     Icon:  fa-cog
--     Parent: (root)

-- ============================================================
-- STEP 2: Create Shared LOV — CHECK_FREQUENCIES
-- ============================================================
-- In Shared Components → List of Values → Create:
--   Name:    CHECK_FREQUENCIES
--   Type:    Static
--   Values:
--     Display        Return
--     Every 6 hours     6
--     Every 12 hours   12
--     Every 24 hours   24
--     Every 48 hours   48
--     Weekly          168

-- ============================================================
-- STEP 3: Create Page Items — Hidden (Before Header)
-- ============================================================
-- These items are set by the "Load Settings" Before Header
-- process. Add them as hidden items in the page root:
--
--   P7_SAVED           (Hidden, Value Protected: No, Session State: Per Session)

-- ============================================================
-- STEP 4: Create Breadcrumb Bar
-- ============================================================
-- Region: Breadcrumb
--   Type:         Breadcrumb
--   Position:     Breadcrumb Bar
--   Breadcrumb:   Application Breadcrumb
--   Entry:        Settings


-- ============================================================
-- ================================================================
-- REGION 1: API Configuration (Collapsible)
-- ================================================================
-- Roadmap 4.5.2 — Add API configuration section
-- ============================================================
-- Create Region:
--   Name:        API Configuration
--   Type:        Static Content
--   Position:    Body (Sequence 10)
--   Template:    Collapsible
--   Title:       USCIS API Configuration
--   Icon:        fa-cloud
--   Default State: Expanded
--
-- Items inside this region:

-- 4a. P7_API_MODE — Radio Group
-- Settings:
--   Label:            API Mode
--   Type:             Radio Group
--   Template:         Required - Floating
--   LOV Type:         Static Values
--   Static Values:    STATIC:Sandbox (Testing);SANDBOX,Production;PRODUCTION
--   Default:          (from process — see Step 11)
--   Columns Span:     3
--   Help Text:        Sandbox mode uses mock responses for testing.
--                      Production mode calls the live USCIS API.

-- 4b. P7_API_BASE_URL — Display Only
-- Settings:
--   Label:            API Base URL
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)
--   Help Text:        The USCIS API endpoint URL.

-- 4c. P7_HAS_CREDENTIALS — Display Only (HTML)
-- Settings:
--   Label:            Credentials Status
--   Type:             Display Only
--   Template:         Optional - Floating
--   Escape:           No (contains HTML)
--   Source:           (from process — see Step 11)
--   Help Text:        Whether OAuth2 client credentials are configured.

-- 4d. P7_RATE_LIMIT_RPS — Display Only
-- Settings:
--   Label:            Rate Limit (req/sec)
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)

-- 4e. P7_REQUESTS_TODAY — Display Only
-- Settings:
--   Label:            API Requests Today
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)

-- 4f. BTN_TEST_API — Button
-- Settings:
--   Label:            Test API Connection
--   Action:           Defined by Dynamic Action (see Step 13)
--   Position:         Region Body (Below Items)
--   Button Template:  Text
--   CSS Classes:      t-Button--warning
--   Icon:             fa-plug


-- ============================================================
-- ================================================================
-- REGION 2: Scheduler Configuration (Collapsible)
-- ================================================================
-- Roadmap 4.5.3 — Add scheduler settings section
-- ============================================================
-- Create Region:
--   Name:        Scheduler Configuration
--   Type:        Static Content
--   Position:    Body (Sequence 20)
--   Template:    Collapsible
--   Title:       Automatic Status Checking
--   Icon:        fa-clock-o
--   Default State: Expanded
--
-- Items inside this region:

-- 5a. P7_AUTO_CHECK_ENABLED — Switch
-- Settings:
--   Label:            Enable automatic status checks
--   Type:             Switch
--   Template:         Optional - Floating
--   On Value:         Y
--   Off Value:        N
--   Default:          (from process — see Step 11)
--   Help Text:        When enabled, the system automatically checks
--                      USCIS for status updates on all active cases at
--                      the configured interval.

-- 5b. P7_AUTO_CHECK_INTERVAL — Select List
-- Settings:
--   Label:            Check Interval
--   Type:             Select List
--   Template:         Optional - Floating
--   LOV:              CHECK_FREQUENCIES (Shared LOV from Step 2)
--   Display Null:     No
--   Default:          (from process — see Step 11)
--   Help Text:        How often the system checks for status updates.
--   Server-side Condition:
--     Type:           Item = Value
--     Item:           P7_AUTO_CHECK_ENABLED
--     Value:          Y

-- 5c. P7_AUTO_CHECK_BATCH_SIZE — Number Field
-- Settings:
--   Label:            Cases per Batch
--   Type:             Number Field
--   Template:         Optional - Floating
--   Minimum:          1
--   Maximum:          200
--   Default:          (from process — see Step 11)
--   Help Text:        Number of cases to check in each batch run.
--                      Lower values reduce API load; higher values
--                      ensure all cases are checked faster.
--   Server-side Condition:
--     Type:           Item = Value
--     Item:           P7_AUTO_CHECK_ENABLED
--     Value:          Y

-- 5d. P7_NEXT_RUN — Display Only
-- Settings:
--   Label:            Next Scheduled Check
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)
--   Server-side Condition:
--     Type:           Item = Value
--     Item:           P7_AUTO_CHECK_ENABLED
--     Value:          Y

-- 5e. P7_LAST_RUN — Display Only
-- Settings:
--   Label:            Last Run
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)
--   Server-side Condition:
--     Type:           Item = Value
--     Item:           P7_AUTO_CHECK_ENABLED
--     Value:          Y

-- 5f. P7_JOB_STATUS — Display Only
-- Settings:
--   Label:            Job Status
--   Type:             Display Only
--   Template:         Optional - Floating
--   Source:           (from process — see Step 11)
--   Server-side Condition:
--     Type:           Item = Value
--     Item:           P7_AUTO_CHECK_ENABLED
--     Value:          Y


-- ============================================================
-- ================================================================
-- REGION 3: Rate Limiting (Collapsible — Read Only)
-- ================================================================
-- ============================================================
-- Create Region:
--   Name:        Rate Limiting
--   Type:        Static Content
--   Position:    Body (Sequence 30)
--   Template:    Collapsible
--   Title:       Rate Limiting
--   Icon:        fa-dashboard
--   Default State: Collapsed
--
-- Items inside this region:

-- 6a. P7_RATE_LIMIT_DISPLAY — Display Only
-- Settings:
--   Label:            Requests per Second
--   Type:             Display Only
--   Source:           (from process — see Step 11)

-- 6b. P7_DAILY_QUOTA — Display Only
-- Settings:
--   Label:            Daily Quota
--   Type:             Display Only
--   Source:           Static text "1,000 requests"

-- 6c. P7_REQUESTS_TODAY_DETAIL — Display Only
-- Settings:
--   Label:            Requests Used Today
--   Type:             Display Only
--   Source:           (from process — see Step 11)


-- ============================================================
-- ================================================================
-- REGION 4: Buttons Bar
-- ================================================================
-- ============================================================
-- Create Region:
--   Name:        Buttons
--   Type:        Static Content
--   Position:    Body (Sequence 40)
--   Template:    Buttons Container
--
-- Buttons:

-- BTN_SAVE — Save Settings
-- Settings:
--   Label:            Save Settings
--   Action:           Submit Page
--   Position:         Next (or Create)
--   Button Template:  Text with Icon
--   CSS Classes:      t-Button--hot
--   Icon:             fa-save
--   Request Value:    SAVE

-- BTN_CANCEL — Cancel
-- Settings:
--   Label:            Cancel
--   Action:           Redirect to Page → 1 (Dashboard)
--   Position:         Previous
--   Button Template:  Text
--   CSS Classes:      (none)


-- ============================================================
-- ================================================================
-- STEP 11: Before Header Process — Load Settings
-- ================================================================
-- ============================================================
-- In Page Designer → Processing (Before Header) → Create Process:
--   Name:        Load Settings
--   Type:        PL/SQL Code
--   Sequence:    10
--   Point:       Before Header
--
-- PL/SQL Code:

/*
DECLARE
    l_job_name      VARCHAR2(30) := 'USCIS_AUTO_CHECK_JOB';
    l_requests      NUMBER := 0;
BEGIN
    -------------------------------------------------------
    -- API Configuration items
    -------------------------------------------------------
    :P7_API_MODE := uscis_util_pkg.get_config('USCIS_API_MODE', 'SANDBOX');

    :P7_API_BASE_URL := uscis_util_pkg.get_config(
        'USCIS_API_BASE_URL',
        'https://api-int.uscis.gov/case-status'
    );

    -- Credentials status (HTML — Display Only with Escape=No)
    IF uscis_oauth_pkg.has_credentials THEN
        :P7_HAS_CREDENTIALS := '<span class="u-success-text">'
            || '<span class="fa fa-check-circle"></span> Configured</span>';
    ELSE
        :P7_HAS_CREDENTIALS := '<span class="u-danger-text">'
            || '<span class="fa fa-exclamation-triangle"></span> Not Configured</span>';
    END IF;

    -- Rate limiting
    :P7_RATE_LIMIT_RPS := uscis_util_pkg.get_config('RATE_LIMIT_REQUESTS_PER_SECOND', '10');
    :P7_RATE_LIMIT_DISPLAY := :P7_RATE_LIMIT_RPS;

    -- Requests today
    BEGIN
        SELECT NVL(SUM(request_count), 0)
          INTO l_requests
          FROM api_rate_limiter
         WHERE service_name = 'USCIS_API'
           AND TRUNC(window_start) = TRUNC(SYSDATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_requests := 0;
    END;
    :P7_REQUESTS_TODAY := TO_CHAR(l_requests, 'FM999,999') || ' / 1,000';
    :P7_REQUESTS_TODAY_DETAIL := :P7_REQUESTS_TODAY;

    -------------------------------------------------------
    -- Scheduler Configuration items
    -------------------------------------------------------
    :P7_AUTO_CHECK_ENABLED := uscis_util_pkg.get_config('AUTO_CHECK_ENABLED', 'N');

    :P7_AUTO_CHECK_INTERVAL := uscis_util_pkg.get_config_number(
        'AUTO_CHECK_INTERVAL_HOURS', 24
    );

    :P7_AUTO_CHECK_BATCH_SIZE := uscis_util_pkg.get_config_number(
        'AUTO_CHECK_BATCH_SIZE', 50
    );

    -- Next scheduled run
    BEGIN
        SELECT TO_CHAR(next_run_date, 'Mon DD, YYYY HH:MI AM')
          INTO :P7_NEXT_RUN
          FROM user_scheduler_jobs
         WHERE job_name = l_job_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :P7_NEXT_RUN := 'Not scheduled';
    END;

    -- Last run
    BEGIN
        SELECT TO_CHAR(last_start_date, 'Mon DD, YYYY HH:MI AM')
          INTO :P7_LAST_RUN
          FROM user_scheduler_jobs
         WHERE job_name = l_job_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :P7_LAST_RUN := 'Never';
    END;

    -- Job status
    :P7_JOB_STATUS := uscis_scheduler_pkg.get_job_status(l_job_name);

END;
*/


-- ============================================================
-- ================================================================
-- STEP 12: Page Process — Save Settings (On Submit)
-- ================================================================
-- ============================================================
-- In Page Designer → Processing (After Submit) → Create Process:
--   Name:        Save Settings
--   Type:        PL/SQL Code
--   Sequence:    10
--   Point:       Processing
--   When Button Pressed: BTN_SAVE (or Request = SAVE)
--   Success Message:     Settings saved successfully.
--   Error Message:       Failed to save settings.
--
-- PL/SQL Code:

/*
BEGIN
    -------------------------------------------------------
    -- Save API Configuration
    -------------------------------------------------------
    uscis_util_pkg.set_config('USCIS_API_MODE', :P7_API_MODE);

    -------------------------------------------------------
    -- Save Scheduler Configuration
    -------------------------------------------------------
    uscis_util_pkg.set_config('AUTO_CHECK_ENABLED', :P7_AUTO_CHECK_ENABLED);
    uscis_util_pkg.set_config(
        'AUTO_CHECK_INTERVAL_HOURS',
        TO_CHAR(:P7_AUTO_CHECK_INTERVAL)
    );
    uscis_util_pkg.set_config(
        'AUTO_CHECK_BATCH_SIZE',
        TO_CHAR(:P7_AUTO_CHECK_BATCH_SIZE)
    );

    -------------------------------------------------------
    -- Update scheduler job based on new settings
    -------------------------------------------------------
    IF :P7_AUTO_CHECK_ENABLED = 'Y' THEN
        -- Create or update the auto-check job with the new interval
        uscis_scheduler_pkg.create_auto_check_job(
            p_interval_hours => :P7_AUTO_CHECK_INTERVAL
        );
    ELSE
        -- Disable the auto-check job
        uscis_scheduler_pkg.set_auto_check_enabled(FALSE);
    END IF;

    -------------------------------------------------------
    -- Audit the settings change
    -------------------------------------------------------
    uscis_audit_pkg.log_event(
        p_receipt_number => NULL,
        p_action         => 'SETTINGS_UPDATED',
        p_new_values     => '{"api_mode":"' || apex_escape.html(:P7_API_MODE)
                            || '","auto_check":"' || apex_escape.html(:P7_AUTO_CHECK_ENABLED)
                            || '","interval":"' || :P7_AUTO_CHECK_INTERVAL
                            || '","batch_size":"' || :P7_AUTO_CHECK_BATCH_SIZE
                            || '"}'
    );
END;
*/


-- ============================================================
-- ================================================================
-- STEP 13: Dynamic Action — Test API Connection
-- ================================================================
-- ============================================================
-- In Page Designer → Dynamic Actions → Create:
--   Name:        Test API Connection
--   Event:       Click
--   Selection:   Button → BTN_TEST_API
--
-- True Action 1: Execute Server-side Code
--   PL/SQL Code:

/*
DECLARE
    l_result     uscis_types_pkg.t_case_status;
    l_test_rcpt  VARCHAR2(13) := 'IOE0000000000';  -- Known test receipt
BEGIN
    -- Use a test receipt number to verify connectivity
    l_result := uscis_api_pkg.check_case_status(
        p_receipt_number  => l_test_rcpt,
        p_save_to_db      => FALSE  -- Do not persist test call
    );

    -- If we get here, the API connection works
    apex_json.open_object;
    apex_json.write('success', TRUE);
    apex_json.write('message', 'API connection successful. Mode: '
        || uscis_util_pkg.get_config('USCIS_API_MODE', 'SANDBOX'));
    apex_json.write('status', l_result.current_status);
    apex_json.close_object;

EXCEPTION
    WHEN OTHERS THEN
        apex_debug.error('TEST_API failed: %s %s', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        apex_json.open_object;
        apex_json.write('success', FALSE);
        apex_json.write('message', 'API connection failed; contact support');
        apex_json.close_object;
END;
*/

--   Items to Submit: P7_API_MODE
--
-- True Action 2: Execute JavaScript Code

/*
-- JS (wrapped in IIFE per R-10):
(function(apex, $) {
    "use strict";
    var result = JSON.parse(apex.server.getResult());
    if (result.success) {
        apex.message.showPageSuccess(result.message);
    } else {
        apex.message.showErrors([{
            type:    "error",
            location: "page",
            message:  result.message
        }]);
    }
})(apex, apex.jQuery);
*/

-- NOTE: Alternatively, implement this as an Ajax Callback process
-- named "TEST_API_CONNECTION" and call it via apex.server.process().


-- ============================================================
-- ================================================================
-- STEP 14: Dynamic Action — Toggle Scheduler Fields
-- ================================================================
-- ============================================================
-- In Page Designer → Dynamic Actions → Create:
--   Name:        Toggle Scheduler Fields
--   Event:       Change
--   Selection:   Item → P7_AUTO_CHECK_ENABLED
--
-- True Action (when P7_AUTO_CHECK_ENABLED = 'Y'):
--   Action: Show
--   Selection Type: Item(s)
--   Items:  P7_AUTO_CHECK_INTERVAL, P7_AUTO_CHECK_BATCH_SIZE,
--           P7_NEXT_RUN, P7_LAST_RUN, P7_JOB_STATUS
--
-- False Action (when P7_AUTO_CHECK_ENABLED = 'N'):
--   Action: Hide
--   Selection Type: Item(s)
--   Items:  P7_AUTO_CHECK_INTERVAL, P7_AUTO_CHECK_BATCH_SIZE,
--           P7_NEXT_RUN, P7_LAST_RUN, P7_JOB_STATUS

-- ============================================================
-- ================================================================
-- STEP 15: Validation — Batch Size Range
-- ================================================================
-- ============================================================
-- In Page Designer → Processing → Validations → Create:
--   Name:        Validate Batch Size
--   Type:        PL/SQL Function (Returning Error Text)
--   Associated Item: P7_AUTO_CHECK_BATCH_SIZE
--   When Button Pressed: BTN_SAVE
--   When Condition:
--     Type:  Item = Value
--     Item:  P7_AUTO_CHECK_ENABLED
--     Value: Y
--
-- PL/SQL:

/*
DECLARE
    l_size NUMBER;
BEGIN
    l_size := TO_NUMBER(:P7_AUTO_CHECK_BATCH_SIZE);
    IF l_size < 1 OR l_size > 200 THEN
        RETURN 'Batch size must be between 1 and 200.';
    END IF;
    RETURN NULL;
EXCEPTION
    WHEN VALUE_ERROR THEN
        RETURN 'Batch size must be a number.';
END;
*/


-- ============================================================
-- ================================================================
-- STEP 16: Page CSS (Inline — only if not in static file)
-- ================================================================
-- ============================================================
-- Per R-11 (CSP compliance), prefer adding these styles to
-- shared_components/files/app-styles.css instead of inline.
-- If adding to app-styles.css, add this section:

/*
-- === Settings Page (Page 7) ===
#P7_HAS_CREDENTIALS .u-success-text {
    color: var(--ut-palette-success);
    font-weight: 600;
}
#P7_HAS_CREDENTIALS .u-danger-text {
    color: var(--ut-palette-danger);
    font-weight: 600;
}
#P7_HAS_CREDENTIALS .fa {
    margin-right: 4px;
}
*/


-- ============================================================
-- END OF PAGE 7 PATCH
-- ============================================================
-- Summary of items created:
--
--   Page Items:
--     P7_API_MODE, P7_API_BASE_URL, P7_HAS_CREDENTIALS,
--     P7_RATE_LIMIT_RPS, P7_REQUESTS_TODAY,
--     P7_AUTO_CHECK_ENABLED, P7_AUTO_CHECK_INTERVAL,
--     P7_AUTO_CHECK_BATCH_SIZE, P7_NEXT_RUN, P7_LAST_RUN,
--     P7_JOB_STATUS, P7_RATE_LIMIT_DISPLAY, P7_DAILY_QUOTA,
--     P7_REQUESTS_TODAY_DETAIL, P7_SAVED
--
--   Regions:
--     API Configuration, Scheduler Configuration,
--     Rate Limiting, Buttons
--
--   Buttons:
--     BTN_TEST_API, BTN_SAVE, BTN_CANCEL
--
--   Processes:
--     Load Settings (Before Header)
--     Save Settings (After Submit)
--
--   Dynamic Actions:
--     Test API Connection (Click BTN_TEST_API)
--     Toggle Scheduler Fields (Change P7_AUTO_CHECK_ENABLED)
--
--   Validations:
--     Validate Batch Size
--
--   Shared LOV:
--     CHECK_FREQUENCIES
-- ============================================================
