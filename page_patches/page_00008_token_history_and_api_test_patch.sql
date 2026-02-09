-- ============================================================
-- Page 8 Patch: Token History + Interactive API Test
-- ============================================================
-- File: page_patches/page_00008_token_history_and_api_test_patch.sql
--
-- Purpose: Add two new tabs to the Administration page:
--   1. OAuth Token History — shows current and past tokens
--   2. API Test Console   — interactive USCIS API test tool
--
-- Prerequisites:
--   - Page 8 (Administration) already built per page_00008_patch.sql
--   - USCIS_OAUTH_PKG (package 05) installed with get_token_status
--   - USCIS_API_PKG (package 06) installed with test_api_connection,
--     check_case_status_json, is_mock_mode, get_rate_limit_status
--   - USCIS_UTIL_PKG (package 02) installed with validate_receipt_number
--   - OAUTH_TOKENS table exists
--
-- Apply via: Page Designer — add regions/items/processes to existing Page 8
-- ============================================================


-- ============================================================
-- REGION 4: OAuth Token History (Interactive Report)
-- ============================================================
-- Add as a new tab under the existing "Admin Tabs" Region
-- Display Selector on Page 8.
--
-- Create Region:
--   Name:          OAuth Token History
--   Type:          Interactive Report
--   Position:      Body (Sequence 40)
--   Parent Region: Admin Tabs
--   Include in RDS: Yes
--   Icon:          fa-key
--   CSS Classes:   admin-token-history
--
-- Source SQL:

/*
SELECT
    t.token_id,
    t.service_name,
    -- Mask the token: show first 8 chars + ellipsis (never expose full token)
    CASE 
        WHEN LENGTH(t.access_token) >= 16 THEN
            SUBSTR(t.access_token, 1, 8) || '...' || SUBSTR(t.access_token, -4)
        WHEN LENGTH(t.access_token) >= 8 THEN
            SUBSTR(t.access_token, 1, 4) || '...'
        ELSE
            '***'
    END AS token_preview,
    t.token_type,
    t.expires_at,
    t.created_at,
    t.last_used_at,
    -- Computed: is this token current or expired?
    CASE
        WHEN t.expires_at > SYSTIMESTAMP THEN 'Current'
        ELSE 'Expired'
    END AS token_state,
    -- Computed: CSS class for the badge
    CASE
        WHEN t.expires_at > SYSTIMESTAMP THEN 'u-success'
        ELSE 'u-danger'
    END AS state_css,
    -- Computed: minutes until expiry (negative if expired)
    ROUND(
        EXTRACT(DAY FROM (t.expires_at - SYSTIMESTAMP)) * 1440
        + EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) * 60
        + EXTRACT(MINUTE FROM (t.expires_at - SYSTIMESTAMP))
    ) AS minutes_remaining,
    -- Computed: human-readable time remaining or "Expired X ago"
    CASE
        WHEN t.expires_at > SYSTIMESTAMP THEN
            CASE
                WHEN EXTRACT(DAY FROM (t.expires_at - SYSTIMESTAMP)) > 0 THEN
                    EXTRACT(DAY FROM (t.expires_at - SYSTIMESTAMP)) || 'd '
                    || EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) || 'h remaining'
                WHEN EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) > 0 THEN
                    EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) || 'h '
                    || EXTRACT(MINUTE FROM (t.expires_at - SYSTIMESTAMP)) || 'm remaining'
                ELSE
                    EXTRACT(MINUTE FROM (t.expires_at - SYSTIMESTAMP)) || 'm remaining'
            END
        ELSE
            CASE
                WHEN EXTRACT(DAY FROM (SYSTIMESTAMP - t.expires_at)) > 0 THEN
                    'Expired ' || EXTRACT(DAY FROM (SYSTIMESTAMP - t.expires_at)) || 'd ago'
                WHEN EXTRACT(HOUR FROM (SYSTIMESTAMP - t.expires_at)) > 0 THEN
                    'Expired ' || EXTRACT(HOUR FROM (SYSTIMESTAMP - t.expires_at)) || 'h ago'
                ELSE
                    'Expired ' || EXTRACT(MINUTE FROM (SYSTIMESTAMP - t.expires_at)) || 'm ago'
            END
    END AS time_display
FROM oauth_tokens t
ORDER BY t.created_at DESC
*/

-- Report Attributes:
--   Pagination:       Scroll (50 rows per page)
--   Show Row Count:   Yes
--   Download:         CSV
--   Search Bar:       Yes
--   Actions Menu:     Yes

-- Column Configuration:
--
-- TOKEN_ID
--   Type:             Hidden
--
-- SERVICE_NAME
--   Heading:          Service
--   Width:            120px
--
-- TOKEN_PREVIEW
--   Heading:          Token
--   Width:            200px
--   CSS Classes:      u-textMonospace
--   Help Text:        Tokens are masked for security. Only the first
--                      8 and last 4 characters are shown.
--
-- TOKEN_TYPE
--   Heading:          Type
--   Width:            80px
--   Visible:          No (hidden by default, available in Actions)
--
-- EXPIRES_AT
--   Heading:          Expires At
--   Format Mask:      DD-MON-YYYY HH24:MI:SS
--   Width:            180px
--
-- CREATED_AT
--   Heading:          Created
--   Format Mask:      DD-MON-YYYY HH24:MI:SS
--   Width:            180px
--
-- LAST_USED_AT
--   Heading:          Last Used
--   Format Mask:      DD-MON-YYYY HH24:MI:SS
--   Width:            180px
--
-- TOKEN_STATE
--   Heading:          Status
--   Width:            100px
--   HTML Expression:
/*
<span class="t-Badge t-Badge--small #STATE_CSS#">#TOKEN_STATE#</span>
*/
--
-- STATE_CSS
--   Type:             Hidden (used by TOKEN_STATE column HTML)
--
-- MINUTES_REMAINING
--   Type:             Hidden (used for sorting/filtering)
--
-- TIME_DISPLAY
--   Heading:          Time Remaining
--   Width:            160px

-- Sub-region: Token Status Summary (Static Content, above the IR)
-- Create Region:
--   Name:          Current Token Status
--   Type:          PL/SQL Dynamic Content
--   Position:      Body (Sequence 38)
--   Parent Region: Admin Tabs
--   Include in RDS: No  (will appear within the Token History tab area)
--   Template:      Alert
--   Template Options:
--     Alert Type:  Information
--     Icon:        fa-info-circle
--   CSS Classes:   admin-token-status-banner
--
-- NOTE: A cleaner approach is to add a "Token Status" sub-region
-- INSIDE the "OAuth Token History" region (before the IR rows).
-- Alternatively, place it as Sequence 39 with Parent = Admin Tabs
-- and rely on RDS grouping. The approach below places it as an
-- informational banner at the top of the token tab.
--
-- For simplicity, we add it as items in the OAuth Token History
-- region header instead. See the Static Content approach below.

-- ALTERNATIVE: Add page items to show the live token status:
--
-- P8_TOKEN_STATUS_JSON — Hidden item
-- Settings:
--   Type:             Hidden
--   Session State:    Per Request (Memory Only)
--   Source:           PL/SQL Expression
--   PL/SQL:           uscis_oauth_pkg.get_token_status('USCIS_API')

-- P8_TOKEN_STATUS_DISPLAY — Display Only (HTML)
-- Settings:
--   Type:             Display Only
--   Label:            Current Token Status
--   Position:         Region: OAuth Token History (above report, Seq 1)
--   Template:         Optional - Floating
--   Based On:         PL/SQL Function Body
--   PL/SQL:

/*
DECLARE
    l_json     CLOB;
    l_status   VARCHAR2(20);
    l_mins     NUMBER;
    l_expires  VARCHAR2(100);
    l_used     VARCHAR2(100);
    l_creds    VARCHAR2(5);
    l_html     VARCHAR2(4000);
    l_badge    VARCHAR2(200);
BEGIN
    l_json := uscis_oauth_pkg.get_token_status('USCIS_API');

    l_status  := JSON_VALUE(l_json, '$.status');
    l_mins    := JSON_VALUE(l_json, '$.minutes_until_expiry' RETURNING NUMBER);
    l_expires := JSON_VALUE(l_json, '$.expires_at');
    l_used    := JSON_VALUE(l_json, '$.last_used_at');
    l_creds   := JSON_VALUE(l_json, '$.credentials_configured');

    -- Status badge
    CASE l_status
        WHEN 'VALID' THEN
            l_badge := '<span class="t-Badge u-success"><span class="fa fa-check"></span> Valid</span>';
        WHEN 'EXPIRING' THEN
            l_badge := '<span class="t-Badge u-warning"><span class="fa fa-clock-o"></span> Expiring Soon</span>';
        WHEN 'EXPIRED' THEN
            l_badge := '<span class="t-Badge u-danger"><span class="fa fa-times"></span> Expired</span>';
        ELSE
            l_badge := '<span class="t-Badge u-color-7"><span class="fa fa-question"></span> No Token</span>';
    END CASE;

    l_html := '<div class="admin-token-summary">'
        || '<div class="admin-token-summary-row">'
        || '<strong>Status:</strong> ' || l_badge
        || '</div>';

    IF l_mins IS NOT NULL THEN
        l_html := l_html
            || '<div class="admin-token-summary-row">'
            || '<strong>Expires:</strong> '
            || apex_escape.html(NVL(l_expires, 'N/A'))
            || ' (' || apex_escape.html(TO_CHAR(l_mins)) || ' min remaining)'
            || '</div>';
    END IF;

    IF l_used IS NOT NULL THEN
        l_html := l_html
            || '<div class="admin-token-summary-row">'
            || '<strong>Last Used:</strong> '
            || apex_escape.html(l_used)
            || '</div>';
    END IF;

    l_html := l_html
        || '<div class="admin-token-summary-row">'
        || '<strong>Credentials:</strong> '
        || CASE WHEN l_creds = 'true'
                THEN '<span class="u-success-text">Configured</span>'
                ELSE '<span class="u-danger-text">Not Configured</span>'
           END
        || '</div>'
        || '</div>';

    RETURN l_html;
END;
*/

-- Buttons in the OAuth Token History region:

-- BTN_REFRESH_TOKEN_STATUS — Refresh
-- Settings:
--   Label:            Refresh
--   Action:           Redirect to Page 8 (set request to show this tab)
--   Position:         Region Body (Right of Title)
--   Button Template:  Icon Only
--   Icon:             fa-refresh
--   CSS Classes:      t-Button--small
--   Link Target:      Page 8, Request = IR_TOKEN_HISTORY
--                      (or just redirect to page 8 with no request
--                      and let RDS remember the active tab)

-- BTN_FORCE_REFRESH_TOKEN — Force Token Refresh
-- Settings:
--   Label:            Force Token Refresh
--   Action:           Submit Page
--   Request Value:    REFRESH_TOKEN
--   Position:         Region Body (Right of Title)
--   Button Template:  Text with Icon
--   Icon:             fa-bolt
--   CSS Classes:      t-Button--warning t-Button--small
--   Confirm Message:  Force a token refresh? The current token will be
--                      invalidated and a new one fetched immediately.


-- ============================================================
-- REGION 5: API Test Console (Static Content + Items)
-- ============================================================
-- This region provides an interactive form where admins can:
--   1. Enter a receipt number
--   2. Click "Test" to call the USCIS API
--   3. See the result rendered in a details panel
--
-- Create Region:
--   Name:          API Test Console
--   Type:          Static Content
--   Position:      Body (Sequence 50)
--   Parent Region: Admin Tabs
--   Include in RDS: Yes
--   Icon:          fa-flask
--   CSS Classes:   admin-api-test
--   Template:      Standard
--
-- Template Options:
--   Header: Visible
--   Body Overflow: Visible

-- --------------------------------------------------------
-- Sub-region: Test Input (inside API Test Console)
-- --------------------------------------------------------
-- Create Region:
--   Name:          Test Input
--   Type:          Static Content
--   Position:      Body (Sequence 10)
--   Parent Region: API Test Console
--   Template:      Blank with Attributes
--   CSS Classes:   admin-api-test-input

-- Items:

-- P8_TEST_RECEIPT — Receipt Number Input
-- Settings:
--   Type:             Text Field
--   Label:            Receipt Number
--   Placeholder:      e.g. IOE1234567890
--   Template:         Required - Floating
--   Maximum Length:    13
--   CSS Classes:      u-textMonospace
--   Help Text:        Enter a USCIS receipt number (3 letters + 10 digits).
--                      In sandbox/mock mode, any valid format will return
--                      a simulated response.
--   Value Required:   No (validation done on submit via DA)

-- P8_TEST_SAVE_TO_DB — Save to Database toggle
-- Settings:
--   Type:             Switch
--   Label:            Save Result to Database
--   Default:          N
--   On Value:         Y
--   Off Value:        N
--   Help Text:        When enabled, the API response will be saved to the
--                      case history and status_updates tables. Leave off
--                      for testing purposes.

-- P8_TEST_MODE_DISPLAY — Display Only: Current API Mode
-- Settings:
--   Type:             Display Only
--   Label:            API Mode
--   Based On:         PL/SQL Expression
--   PL/SQL Expression:

/*
CASE WHEN uscis_api_pkg.is_mock_mode
     THEN 'Sandbox / Mock'
     ELSE 'Production / Live'
END
*/

-- P8_TEST_RESULT — Hidden (holds JSON response)
-- Settings:
--   Type:             Hidden
--   Session State:    Per Request (Memory Only)

-- Buttons:

-- BTN_TEST_API — Run API Test
-- Settings:
--   Label:            Test API Call
--   Action:           Defined by Dynamic Action
--   Position:         Region Body (Inline with items)
--   Button Template:  Text with Icon
--   Icon:             fa-play
--   CSS Classes:      t-Button--hot
--   Is Hot:           Yes

-- BTN_TEST_CONNECTION — Test Connection (no receipt needed)
-- Settings:
--   Label:            Test Connection
--   Action:           Defined by Dynamic Action
--   Position:         Region Body (Next to BTN_TEST_API)
--   Button Template:  Text with Icon
--   Icon:             fa-plug
--   CSS Classes:      t-Button--primary

-- --------------------------------------------------------
-- Sub-region: Test Results (inside API Test Console)
-- --------------------------------------------------------
-- Create Region:
--   Name:          Test Results
--   Type:          Static Content
--   Position:      Body (Sequence 20)
--   Parent Region: API Test Console
--   Template:      Blank with Attributes
--   CSS Classes:   admin-api-test-results
--   Static ID:     api_test_results
--
-- This region is initially empty. It gets populated by the
-- Dynamic Action after the API call completes.

-- P8_TEST_RESULTS_HTML — Display Only (rendered results)
-- Settings:
--   Type:             Display Only
--   Label:            (none — suppress label)
--   Based On:         PL/SQL Function Body (returning CLOB)
--   Escape:           No (we produce safe, escaped HTML)
--   Session State:    Per Request (Memory Only)
--   Condition:        P8_TEST_RESULT IS NOT NULL
--   PL/SQL:

/*
-- This is set by the AJAX callback; for initial page load just show instructions
RETURN '<div class="admin-api-test-empty">'
    || '<span class="fa fa-flask fa-3x u-color-7-text"></span>'
    || '<p>Enter a receipt number and click <strong>Test API Call</strong> '
    || 'to see the response, or click <strong>Test Connection</strong> '
    || 'to verify API connectivity.</p>'
    || '</div>';
*/


-- ============================================================
-- DYNAMIC ACTIONS
-- ============================================================

-- DA 1: Test API Call (fires on BTN_TEST_API click)
-- ============================================================
-- Event:            Click
-- Selection Type:   Button
-- Button:           BTN_TEST_API
-- Event Scope:      Static
--
-- True Actions:
--
-- Action 1: Validate Receipt Number (JavaScript)
--   Type:            JavaScript Code
--   Fire on Init:    No
--   Code:

/*
(function(apex, $) {
    var receipt = apex.item('P8_TEST_RECEIPT').getValue().trim().toUpperCase();
    if (!receipt) {
        apex.message.showErrors([{
            type: 'error',
            location: 'inline',
            pageItem: 'P8_TEST_RECEIPT',
            message: 'Please enter a receipt number.'
        }]);
        apex.da.cancel();
        return;
    }
    // Basic client-side format check: 3 letters + 10 digits
    if (!/^[A-Z]{3}\d{10}$/.test(receipt)) {
        apex.message.showErrors([{
            type: 'error',
            location: 'inline',
            pageItem: 'P8_TEST_RECEIPT',
            message: 'Invalid format. Expected 3 letters + 10 digits (e.g. IOE1234567890).'
        }]);
        apex.da.cancel();
        return;
    }
    // Clear previous errors
    apex.message.clearErrors();
    // Normalize the value
    apex.item('P8_TEST_RECEIPT').setValue(receipt);
})(apex, apex.jQuery);
*/

-- Action 2: Show spinner
--   Type:            JavaScript Code
--   Code:

/*
(function(apex, $) {
    var $results = $('#api_test_results');
    $results.html(
        '<div class="admin-api-test-loading">'
        + '<span class="fa fa-refresh fa-spin fa-2x"></span>'
        + '<p>Calling USCIS API...</p>'
        + '</div>'
    );
})(apex, apex.jQuery);
*/

-- Action 3: Execute AJAX Callback — check_case_status
--   Type:            Execute Server-side Code
--   PL/SQL Code:

/*
DECLARE
    l_receipt   VARCHAR2(13);
    l_save      BOOLEAN;
    l_json      CLOB;
    l_html      CLOB;
    l_status    VARCHAR2(500);
    l_case_type VARCHAR2(100);
    l_details   CLOB;
    l_updated   VARCHAR2(100);
BEGIN
    l_receipt := UPPER(TRIM(:P8_TEST_RECEIPT));
    l_save    := (:P8_TEST_SAVE_TO_DB = 'Y');

    -- Server-side validation
    IF NOT uscis_util_pkg.validate_receipt_number(l_receipt) THEN
        :P8_TEST_RESULT := '{"error":"Invalid receipt number format"}';
        RETURN;
    END IF;

    -- Call API (returns JSON CLOB)
    l_json := uscis_api_pkg.check_case_status_json(
        p_receipt_number   => l_receipt,
        p_save_to_database => l_save
    );

    :P8_TEST_RESULT := l_json;

    -- Parse for display
    l_status    := JSON_VALUE(l_json, '$.current_status');
    l_case_type := JSON_VALUE(l_json, '$.case_type');
    l_details   := JSON_VALUE(l_json, '$.details');
    l_updated   := JSON_VALUE(l_json, '$.last_updated');

    -- Build results HTML (all output escaped per R-13)
    l_html := '<div class="admin-api-test-result-card">'
        || '<h4 class="admin-api-test-result-title">'
        || '<span class="fa fa-check-circle u-success-text"></span> '
        || 'API Response for ' || apex_escape.html(l_receipt)
        || '</h4>'
        || '<table class="admin-api-test-result-table t-Report">'
        || '<tbody>'
        || '<tr><th>Receipt Number</th><td class="u-textMonospace">'
            || apex_escape.html(l_receipt) || '</td></tr>'
        || '<tr><th>Case Type</th><td>'
            || apex_escape.html(NVL(l_case_type, 'N/A')) || '</td></tr>'
        || '<tr><th>Status</th><td><strong>'
            || apex_escape.html(NVL(l_status, 'N/A')) || '</strong></td></tr>'
        || '<tr><th>Last Updated</th><td>'
            || apex_escape.html(NVL(l_updated, 'N/A')) || '</td></tr>'
        || '<tr><th>Details</th><td>'
            || apex_escape.html(NVL(DBMS_LOB.SUBSTR(l_details, 2000, 1), 'N/A'))
            || '</td></tr>'
        || '<tr><th>Saved to DB</th><td>'
            || CASE WHEN l_save THEN 'Yes' ELSE 'No' END
            || '</td></tr>'
        || '</tbody></table>';

    -- Show raw JSON in a collapsible section
    l_html := l_html
        || '<details class="admin-api-test-raw">'
        || '<summary>Raw JSON Response</summary>'
        || '<pre class="admin-api-test-json">'
        || apex_escape.html(l_json)
        || '</pre>'
        || '</details>'
        || '</div>';

    -- Return via hidden item; JS will move it to the results region
    :P8_TEST_RESULTS_HTML := l_html;

EXCEPTION
    WHEN uscis_api_pkg.e_api_error THEN
        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.write('error', SQLERRM);
        apex_json.close_object;
        :P8_TEST_RESULT := apex_json.get_clob_output;
        apex_json.free_output;
        :P8_TEST_RESULTS_HTML :=
            '<div class="admin-api-test-error">'
            || '<span class="fa fa-exclamation-triangle fa-2x u-danger-text"></span>'
            || '<p><strong>API Error:</strong> '
            || apex_escape.html(SQLERRM)
            || '</p></div>';
    WHEN uscis_api_pkg.e_rate_limited THEN
        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.write('error', 'Rate limited');
        apex_json.close_object;
        :P8_TEST_RESULT := apex_json.get_clob_output;
        apex_json.free_output;
        :P8_TEST_RESULTS_HTML :=
            '<div class="admin-api-test-error">'
            || '<span class="fa fa-hourglass fa-2x u-warning-text"></span>'
            || '<p><strong>Rate Limited:</strong> Too many requests. Please wait before trying again.</p>'
            || '</div>';
    WHEN OTHERS THEN
        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.write('error', SQLERRM);
        apex_json.close_object;
        :P8_TEST_RESULT := apex_json.get_clob_output;
        apex_json.free_output;
        :P8_TEST_RESULTS_HTML :=
            '<div class="admin-api-test-error">'
            || '<span class="fa fa-exclamation-circle fa-2x u-danger-text"></span>'
            || '<p><strong>Unexpected Error:</strong> '
            || apex_escape.html(SQLERRM)
            || '</p></div>';
END;
*/

--   Items to Submit: P8_TEST_RECEIPT, P8_TEST_SAVE_TO_DB
--   Items to Return: P8_TEST_RESULT, P8_TEST_RESULTS_HTML

-- Action 4: Render results (JavaScript)
--   Type:            JavaScript Code
--   Code:

/*
(function(apex, $) {
    var html = apex.item('P8_TEST_RESULTS_HTML').getValue();
    if (html) {
        $('#api_test_results').html(html);
    }
})(apex, apex.jQuery);
*/


-- DA 2: Test Connection (fires on BTN_TEST_CONNECTION click)
-- ============================================================
-- Event:            Click
-- Selection Type:   Button
-- Button:           BTN_TEST_CONNECTION
-- Event Scope:      Static
--
-- True Actions:
--
-- Action 1: Show spinner
--   Type:            JavaScript Code
--   Code:

/*
(function(apex, $) {
    var $results = $('#api_test_results');
    $results.html(
        '<div class="admin-api-test-loading">'
        + '<span class="fa fa-refresh fa-spin fa-2x"></span>'
        + '<p>Testing API connection...</p>'
        + '</div>'
    );
})(apex, apex.jQuery);
*/

-- Action 2: Execute Server-side Code — test_api_connection
--   Type:            Execute Server-side Code
--   PL/SQL Code:

/*
DECLARE
    l_result  uscis_types_pkg.t_api_result;
    l_html    CLOB;
    l_rl_json CLOB;
    l_icon    VARCHAR2(100);
    l_color   VARCHAR2(100);
BEGIN
    l_result := uscis_api_pkg.test_api_connection;
    l_rl_json := uscis_api_pkg.get_rate_limit_status;

    IF l_result.success THEN
        l_icon  := 'fa-check-circle';
        l_color := 'u-success-text';
    ELSE
        l_icon  := 'fa-times-circle';
        l_color := 'u-danger-text';
    END IF;

    l_html := '<div class="admin-api-test-result-card">'
        || '<h4 class="admin-api-test-result-title">'
        || '<span class="fa ' || l_icon || ' ' || l_color || '"></span> '
        || 'Connection Test Results'
        || '</h4>'
        || '<table class="admin-api-test-result-table t-Report">'
        || '<tbody>'
        || '<tr><th>Status</th><td>'
            || CASE WHEN l_result.success
                    THEN '<span class="u-success-text"><strong>Connected</strong></span>'
                    ELSE '<span class="u-danger-text"><strong>Failed</strong></span>'
               END
            || '</td></tr>'
        || '<tr><th>HTTP Status</th><td>'
            || apex_escape.html(NVL(TO_CHAR(l_result.http_status), 'N/A'))
            || '</td></tr>'
        || '<tr><th>Response Time</th><td>'
            || apex_escape.html(NVL(TO_CHAR(l_result.response_time_ms), 'N/A'))
            || ' ms</td></tr>'
        || '<tr><th>API Mode</th><td>'
            || CASE WHEN uscis_api_pkg.is_mock_mode
                    THEN 'Sandbox / Mock'
                    ELSE 'Production / Live'
               END
            || '</td></tr>'
        || '<tr><th>API Base URL</th><td class="u-textMonospace">'
            || apex_escape.html(uscis_api_pkg.get_api_base_url)
            || '</td></tr>';

    IF l_result.error_message IS NOT NULL THEN
        l_html := l_html
            || '<tr><th>Error</th><td class="u-danger-text">'
            || apex_escape.html(l_result.error_message)
            || '</td></tr>';
    END IF;

    l_html := l_html
        || '</tbody></table>';

    -- Rate limit status section
    l_html := l_html
        || '<details class="admin-api-test-raw">'
        || '<summary>Rate Limit Status</summary>'
        || '<pre class="admin-api-test-json">'
        || apex_escape.html(l_rl_json)
        || '</pre>'
        || '</details>';

    -- Raw response in collapsible
    IF l_result.data IS NOT NULL THEN
        l_html := l_html
            || '<details class="admin-api-test-raw">'
            || '<summary>Raw API Response</summary>'
            || '<pre class="admin-api-test-json">'
            || apex_escape.html(DBMS_LOB.SUBSTR(l_result.data, 4000, 1))
            || '</pre>'
            || '</details>';
    END IF;

    l_html := l_html || '</div>';

    :P8_TEST_RESULTS_HTML := l_html;

EXCEPTION
    WHEN OTHERS THEN
        :P8_TEST_RESULTS_HTML :=
            '<div class="admin-api-test-error">'
            || '<span class="fa fa-exclamation-circle fa-2x u-danger-text"></span>'
            || '<p><strong>Connection Test Failed:</strong> '
            || apex_escape.html(SQLERRM)
            || '</p></div>';
END;
*/

--   Items to Submit: (none)
--   Items to Return: P8_TEST_RESULTS_HTML

-- Action 3: Render results (JavaScript)
--   Type:            JavaScript Code
--   Code:

/*
(function(apex, $) {
    var html = apex.item('P8_TEST_RESULTS_HTML').getValue();
    if (html) {
        $('#api_test_results').html(html);
    }
})(apex, apex.jQuery);
*/


-- ============================================================
-- NEW PROCESS: Force Token Refresh
-- ============================================================
-- In Page Designer → Processing → Create Process:
--   Name:        Force Token Refresh
--   Type:        PL/SQL Code
--   Sequence:    25 (after Clear OAuth Token)
--   Point:       Processing
--   When Request: REFRESH_TOKEN
--   Success Message: A new OAuth token has been fetched.
--
-- PL/SQL Code:

/*
BEGIN
    -- Clear existing token first
    uscis_oauth_pkg.clear_token('USCIS_API');
    -- Force fetch of a new token (will auto-acquire on next call)
    DECLARE
        l_token VARCHAR2(4000);
    BEGIN
        l_token := uscis_oauth_pkg.get_access_token('USCIS_API');
    END;
END;
*/


-- ============================================================
-- NEW PAGE ITEMS (Hidden, supporting)
-- ============================================================

-- P8_TEST_RESULTS_HTML — Hidden item for AJAX result HTML
-- Settings:
--   Type:             Hidden
--   Session State:    Per Request (Memory Only)
--   Value Protected:  No


-- ============================================================
-- CSS additions (add to shared_components/files/app-styles.css)
-- ============================================================
-- Per R-11 (CSP compliance), add these styles to app-styles.css.
-- See the separate CSS diff below.


-- ============================================================
-- SUMMARY OF CHANGES
-- ============================================================
--
--   New Page Regions:
--     OAuth Token History (Interactive Report, tab 4 under Admin Tabs)
--     API Test Console (Static Content, tab 5 under Admin Tabs)
--       └── Test Input (sub-region)
--       └── Test Results (sub-region, Static ID: api_test_results)
--
--   New Page Items:
--     P8_TOKEN_STATUS_JSON (Hidden)
--     P8_TOKEN_STATUS_DISPLAY (Display Only — live token status banner)
--     P8_TEST_RECEIPT (Text Field — receipt number input)
--     P8_TEST_SAVE_TO_DB (Switch — save toggle)
--     P8_TEST_MODE_DISPLAY (Display Only — current API mode)
--     P8_TEST_RESULT (Hidden — raw JSON result)
--     P8_TEST_RESULTS_HTML (Hidden — rendered HTML result)
--
--   New Buttons:
--     BTN_REFRESH_TOKEN_STATUS (Icon Only, in Token History region)
--     BTN_FORCE_REFRESH_TOKEN (Text with Icon, in Token History region)
--     BTN_TEST_API (Hot button, in API Test Console)
--     BTN_TEST_CONNECTION (Primary button, in API Test Console)
--
--   New Dynamic Actions:
--     Test API Call (on BTN_TEST_API click)
--     Test Connection (on BTN_TEST_CONNECTION click)
--
--   New Processes:
--     Force Token Refresh (After Submit, Request: REFRESH_TOKEN)
--
--   Modified Regions:
--     Admin Tabs — now includes 5 tabs:
--       1. System Health
--       2. Audit Logs
--       3. Scheduler Jobs
--       4. OAuth Token History  (NEW)
--       5. API Test Console     (NEW)
--
-- ============================================================
