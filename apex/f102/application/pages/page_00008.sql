prompt --application/pages/page_00008
begin
--   Manifest
--     PAGE: 00008
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.13'
,p_default_workspace_id=>13027568242155993
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'USCIS_APP'
);
wwv_flow_imp_page.create_page(
 p_id=>8
,p_name=>'Administration'
,p_alias=>'ADMINISTRATION'
,p_step_title=>'Administration - USCIS Case Tracker'
,p_autocomplete_on_off=>'OFF'
,p_css_file_urls=>'#APP_FILES#css/maine-pine-v5.css'
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_imp.id(13056708774297879)
,p_protection_level=>'C'
,p_help_text=>'System administration: health monitoring, audit logs, scheduler jobs, OAuth tokens, and API testing.'
,p_page_component_map=>'16'
);
-- ============================================================
-- Region: Breadcrumb
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008000)
,p_plug_name=>'Breadcrumb'
,p_region_template_options=>'#DEFAULT#:t-BreadcrumbRegion--useBreadcrumbTitle'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>2674020415498413040
,p_plug_display_sequence=>1
,p_plug_display_point=>'REGION_POSITION_01'
,p_menu_id=>wwv_flow_imp.id(13051532648297767)
,p_plug_source_type=>'NATIVE_BREADCRUMB'
,p_menu_template_id=>wwv_flow_imp.id(13349993746298421)
);
-- ============================================================
-- Region: Admin Tabs (Region Display Selector)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008001)
,p_plug_name=>'Admin Tabs'
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--scrollBody'
,p_plug_template=>4072358936313175081
,p_plug_display_sequence=>10
,p_plug_source_type=>'NATIVE_DISPLAY_SELECTOR'
);
-- ============================================================
-- Sub-region Tab 1: System Health (PL/SQL Dynamic Content)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008010)
,p_plug_name=>'System Health'
,p_parent_plug_id=>wwv_flow_imp.id(90008001)
,p_icon_css_classes=>'fa-heart'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_total_cases    NUMBER := 0;',
'    l_active_cases   NUMBER := 0;',
'    l_total_updates  NUMBER := 0;',
'    l_api_calls      NUMBER := 0;',
'    l_token_status   VARCHAR2(200);',
'    l_last_api_call  VARCHAR2(50);',
'    l_job_status     VARCHAR2(100);',
'BEGIN',
'    SELECT COUNT(*), SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END)',
'      INTO l_total_cases, l_active_cases',
'      FROM case_history;',
'    SELECT COUNT(*) INTO l_total_updates FROM status_updates;',
'    SELECT NVL(SUM(request_count), 0) INTO l_api_calls',
'      FROM api_rate_limiter',
'     WHERE service_name = ''USCIS_API''',
'       AND TRUNC(window_start) = TRUNC(SYSDATE);',
'    IF uscis_oauth_pkg.has_credentials THEN',
'        l_token_status := ''<span class="u-success-text"><span class="fa fa-check-circle"></span> Valid</span>'';',
'    ELSE',
'        l_token_status := ''<span class="u-danger-text"><span class="fa fa-times-circle"></span> Not Configured</span>'';',
'    END IF;',
'    SELECT TO_CHAR(MAX(window_start), ''Mon DD HH:MI AM'')',
'      INTO l_last_api_call',
'      FROM api_rate_limiter',
'     WHERE service_name = ''USCIS_API'';',
'    l_job_status := uscis_scheduler_pkg.get_job_status(''USCIS_AUTO_CHECK_JOB'');',
'    htp.p(''<div class="admin-health-cards">'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">Total Cases</div>'');',
'    htp.p(''<div class="card-value">'' || apex_escape.html(TO_CHAR(l_total_cases)) || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">Active Cases</div>'');',
'    htp.p(''<div class="card-value u-success-text">'' || apex_escape.html(TO_CHAR(l_active_cases)) || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">Status Updates</div>'');',
'    htp.p(''<div class="card-value">'' || apex_escape.html(TO_CHAR(l_total_updates)) || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">API Calls Today</div>'');',
'    htp.p(''<div class="card-value">'' || apex_escape.html(TO_CHAR(l_api_calls, ''FM999,999'')) || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">OAuth Token</div>'');',
'    htp.p(''<div class="card-value">'' || l_token_status || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">Last API Call</div>'');',
'    htp.p(''<div class="card-value">'' || apex_escape.html(NVL(l_last_api_call, ''Never'')) || ''</div></div>'');',
'    htp.p(''<div class="admin-health-card"><div class="card-label">Scheduler</div>'');',
'    htp.p(''<div class="card-value">'' || apex_escape.html(NVL(l_job_status, ''Not running'')) || ''</div></div>'');',
'    htp.p(''</div>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Sub-region Tab 2: Audit Logs (PL/SQL Dynamic Content)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008020)
,p_plug_name=>'Audit Logs'
,p_parent_plug_id=>wwv_flow_imp.id(90008001)
,p_icon_css_classes=>'fa-file-text-o'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_count NUMBER := 0;',
'BEGIN',
'    htp.p(''<table class="admin-audit-table">'');',
'    htp.p(''<thead><tr>'');',
'    htp.p(''<th>Date/Time</th><th>Receipt #</th><th>Action</th><th>User</th><th>Details</th>'');',
'    htp.p(''</tr></thead><tbody>'');',
'    FOR r IN (',
'        SELECT audit_id, receipt_number, action, performed_by,',
'               TO_CHAR(performed_at, ''Mon DD HH:MI AM'') AS performed_at_str,',
'               SUBSTR(new_values, 1, 200) AS detail_summary',
'          FROM case_audit_log',
'         ORDER BY performed_at DESC',
'         FETCH FIRST 100 ROWS ONLY',
'    ) LOOP',
'        l_count := l_count + 1;',
'        htp.p(''<tr>'');',
'        htp.p(''<td>'' || apex_escape.html(r.performed_at_str) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.receipt_number) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.action) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.performed_by) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.detail_summary) || ''</td>'');',
'        htp.p(''</tr>'');',
'    END LOOP;',
'    IF l_count = 0 THEN',
'        htp.p(''<tr><td colspan="5" class="admin-empty-state">No audit records found.</td></tr>'');',
'    END IF;',
'    htp.p(''</tbody></table>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Sub-region Tab 3: Scheduler Jobs (PL/SQL Dynamic Content)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008030)
,p_plug_name=>'Scheduler Jobs'
,p_parent_plug_id=>wwv_flow_imp.id(90008001)
,p_icon_css_classes=>'fa-clock-o'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_count NUMBER := 0;',
'BEGIN',
'    htp.p(''<table class="admin-audit-table">'');',
'    htp.p(''<thead><tr>'');',
'    htp.p(''<th>Job Name</th><th>State</th><th>Interval</th><th>Last Run</th><th>Next Run</th><th>Runs</th><th>Failures</th>'');',
'    htp.p(''</tr></thead><tbody>'');',
'    FOR r IN (',
'        SELECT job_name, state, repeat_interval,',
'               TO_CHAR(last_start_date, ''Mon DD HH:MI AM'') AS last_run,',
'               TO_CHAR(next_run_date, ''Mon DD HH:MI AM'') AS next_run,',
'               run_count, failure_count',
'          FROM user_scheduler_jobs',
'         WHERE job_name LIKE ''USCIS%''',
'         ORDER BY job_name',
'    ) LOOP',
'        l_count := l_count + 1;',
'        htp.p(''<tr>'');',
'        htp.p(''<td>'' || apex_escape.html(r.job_name) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.state) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.repeat_interval) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.last_run) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.next_run) || ''</td>'');',
'        htp.p(''<td class="admin-num-cell">'' || r.run_count || ''</td>'');',
'        htp.p(''<td class="admin-num-cell">'' || r.failure_count || ''</td>'');',
'        htp.p(''</tr>'');',
'    END LOOP;',
'    IF l_count = 0 THEN',
'        htp.p(''<tr><td colspan="7" class="admin-empty-state">No USCIS scheduler jobs found. Use the buttons below to create them.</td></tr>'');',
'    END IF;',
'    htp.p(''</tbody></table>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Sub-region Tab 4: OAuth Token History (PL/SQL Dynamic Content)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008040)
,p_plug_name=>'OAuth Token History'
,p_parent_plug_id=>wwv_flow_imp.id(90008001)
,p_icon_css_classes=>'fa-key'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>40
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_json       CLOB;',
'    l_status     VARCHAR2(20);',
'    l_mins       NUMBER;',
'    l_expires    VARCHAR2(100);',
'    l_used       VARCHAR2(100);',
'    l_creds      VARCHAR2(5);',
'    l_badge      VARCHAR2(200);',
'    l_count      NUMBER := 0;',
'BEGIN',
'    -- ---- Current token status banner ----',
'    l_json := uscis_oauth_pkg.get_token_status(''USCIS_API'');',
'    l_status  := JSON_VALUE(l_json, ''$.status'');',
'    l_mins    := JSON_VALUE(l_json, ''$.minutes_until_expiry'' RETURNING NUMBER);',
'    l_expires := JSON_VALUE(l_json, ''$.expires_at'');',
'    l_used    := JSON_VALUE(l_json, ''$.last_used_at'');',
'    l_creds   := JSON_VALUE(l_json, ''$.credentials_configured'');',
'    CASE l_status',
'        WHEN ''VALID'' THEN',
'            l_badge := ''<span class="t-Badge u-success"><span class="fa fa-check"></span> Valid</span>'';',
'        WHEN ''EXPIRING'' THEN',
'            l_badge := ''<span class="t-Badge u-warning"><span class="fa fa-clock-o"></span> Expiring Soon</span>'';',
'        WHEN ''EXPIRED'' THEN',
'            l_badge := ''<span class="t-Badge u-danger"><span class="fa fa-times"></span> Expired</span>'';',
'        ELSE',
'            l_badge := ''<span class="t-Badge u-color-7"><span class="fa fa-question"></span> No Token</span>'';',
'    END CASE;',
'    htp.p(''<div class="admin-token-summary">'');',
'    htp.p(''<div class="admin-token-summary-row"><strong>Current Status:</strong> '' || l_badge || ''</div>'');',
'    IF l_mins IS NOT NULL THEN',
'        htp.p(''<div class="admin-token-summary-row"><strong>Expires:</strong> ''',
'            || apex_escape.html(NVL(l_expires, ''N/A''))',
'            || '' ('' || apex_escape.html(TO_CHAR(l_mins)) || '' min remaining)</div>'');',
'    END IF;',
'    IF l_used IS NOT NULL THEN',
'        htp.p(''<div class="admin-token-summary-row"><strong>Last Used:</strong> ''',
'            || apex_escape.html(l_used) || ''</div>'');',
'    END IF;',
'    htp.p(''<div class="admin-token-summary-row"><strong>Credentials:</strong> ''',
'        || CASE WHEN l_creds = ''true''',
'                THEN ''<span class="u-success-text">Configured</span>''',
'                ELSE ''<span class="u-danger-text">Not Configured</span>''',
'           END || ''</div>'');',
'    htp.p(''</div>'');',
'',
'    -- ---- Token history table ----',
'    htp.p(''<table class="admin-audit-table">'');',
'    htp.p(''<thead><tr>'');',
'    htp.p(''<th>ID</th><th>Service</th><th>Token</th><th>Type</th>''',
'        || ''<th>Created</th><th>Expires</th><th>Last Used</th><th>Status</th><th>Time Remaining</th>'');',
'    htp.p(''</tr></thead><tbody>'');',
'    FOR r IN (',
'        SELECT t.token_id,',
'               t.service_name,',
'               SUBSTR(t.access_token, 1, 8) || ''...'' || SUBSTR(t.access_token, -4) AS token_preview,',
'               t.token_type,',
'               TO_CHAR(t.created_at, ''Mon DD HH:MI AM'') AS created_str,',
'               TO_CHAR(t.expires_at, ''Mon DD HH:MI AM'') AS expires_str,',
'               TO_CHAR(t.last_used_at, ''Mon DD HH:MI AM'') AS used_str,',
'               CASE WHEN t.expires_at > SYSTIMESTAMP THEN ''Current'' ELSE ''Expired'' END AS token_state,',
'               CASE WHEN t.expires_at > SYSTIMESTAMP THEN ''u-success'' ELSE ''u-danger'' END AS state_css,',
'               CASE',
'                   WHEN t.expires_at > SYSTIMESTAMP THEN',
'                       CASE',
'                           WHEN EXTRACT(DAY FROM (t.expires_at - SYSTIMESTAMP)) > 0 THEN',
'                               EXTRACT(DAY FROM (t.expires_at - SYSTIMESTAMP)) || ''d ''',
'                               || EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) || ''h''',
'                           WHEN EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) > 0 THEN',
'                               EXTRACT(HOUR FROM (t.expires_at - SYSTIMESTAMP)) || ''h ''',
'                               || EXTRACT(MINUTE FROM (t.expires_at - SYSTIMESTAMP)) || ''m''',
'                           ELSE',
'                               EXTRACT(MINUTE FROM (t.expires_at - SYSTIMESTAMP)) || ''m''',
'                       END',
'                   ELSE',
'                       CASE',
'                           WHEN EXTRACT(DAY FROM (SYSTIMESTAMP - t.expires_at)) > 0 THEN',
'                               ''Expired '' || EXTRACT(DAY FROM (SYSTIMESTAMP - t.expires_at)) || ''d ago''',
'                           WHEN EXTRACT(HOUR FROM (SYSTIMESTAMP - t.expires_at)) > 0 THEN',
'                               ''Expired '' || EXTRACT(HOUR FROM (SYSTIMESTAMP - t.expires_at)) || ''h ago''',
'                           ELSE',
'                               ''Expired '' || EXTRACT(MINUTE FROM (SYSTIMESTAMP - t.expires_at)) || ''m ago''',
'                       END',
'               END AS time_display',
'          FROM oauth_tokens t',
'         ORDER BY t.created_at DESC',
'    ) LOOP',
'        l_count := l_count + 1;',
'        htp.p(''<tr>'');',
'        htp.p(''<td>'' || r.token_id || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.service_name) || ''</td>'');',
'        htp.p(''<td class="admin-monospace">'' || apex_escape.html(r.token_preview) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.token_type) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.created_str) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.expires_str) || ''</td>'');',
'        htp.p(''<td>'' || apex_escape.html(NVL(r.used_str, ''Never'')) || ''</td>'');',
'        htp.p(''<td><span class="t-Badge t-Badge--small '' || r.state_css || ''">''',
'            || apex_escape.html(r.token_state) || ''</span></td>'');',
'        htp.p(''<td>'' || apex_escape.html(r.time_display) || ''</td>'');',
'        htp.p(''</tr>'');',
'    END LOOP;',
'    IF l_count = 0 THEN',
'        htp.p(''<tr><td colspan="9" class="admin-empty-state">''',
'            || ''No OAuth tokens found. Tokens are created automatically when API calls are made.</td></tr>'');',
'    END IF;',
'    htp.p(''</tbody></table>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Sub-region Tab 5: API Test Console (PL/SQL Dynamic Content)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008050)
,p_plug_name=>'API Test Console'
,p_parent_plug_id=>wwv_flow_imp.id(90008001)
,p_icon_css_classes=>'fa-flask'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>50
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_mode VARCHAR2(30);',
'BEGIN',
'    IF uscis_api_pkg.is_mock_mode THEN',
'        l_mode := ''Sandbox / Mock'';',
'    ELSE',
'        l_mode := ''Production / Live'';',
'    END IF;',
'    htp.p(''<div class="admin-api-test">'');',
'',
'    -- Mode indicator',
'    htp.p(''<div class="admin-api-test-mode">'');',
'    htp.p(''<strong>API Mode:</strong> '' || apex_escape.html(l_mode));',
'    htp.p('' &middot; <strong>Base URL:</strong> ''',
'        || ''<span class="admin-monospace">'' || apex_escape.html(uscis_api_pkg.get_api_base_url) || ''</span>'');',
'    htp.p(''</div>'');',
'',
'    -- Input form',
'    htp.p(''<div class="admin-api-test-form">'');',
'    htp.p(''<div class="admin-api-test-field">'');',
'    htp.p(''<label for="P8_TEST_RECEIPT">Receipt Number</label>'');',
'    htp.p(''<input type="text" id="P8_TEST_RECEIPT" class="text_field apex-item-text admin-monospace"''',
'        || '' maxlength="13" placeholder="e.g. IOE1234567890" />'');',
'    htp.p(''</div>'');',
'    htp.p(''<div class="admin-api-test-field">'');',
'    htp.p(''<label class="admin-api-test-checkbox">'');',
'    htp.p(''<input type="checkbox" id="P8_TEST_SAVE_DB" value="Y" /> Save result to database'');',
'    htp.p(''</label>'');',
'    htp.p(''</div>'');',
'    htp.p(''<div class="admin-api-test-buttons">'');',
'    htp.p(''<button type="button" id="btn_test_case" class="t-Button t-Button--hot">'');',
'    htp.p(''<span class="fa fa-play"></span> Test Case Lookup</button>'');',
'    htp.p(''<button type="button" id="btn_test_connection" class="t-Button t-Button--primary">'');',
'    htp.p(''<span class="fa fa-plug"></span> Test Connection</button>'');',
'    htp.p(''</div>'');',
'    htp.p(''</div>'');',
'',
'    -- Results area',
'    htp.p(''<div id="api_test_results" class="admin-api-test-results">'');',
'    htp.p(''<div class="admin-api-test-empty">'');',
'    htp.p(''<span class="fa fa-flask fa-3x"></span>'');',
'    htp.p(''<p>Enter a receipt number and click <strong>Test Case Lookup</strong> ''',
'        || ''to query the API, or click <strong>Test Connection</strong> to verify connectivity.</p>'');',
'    htp.p(''</div></div>'');',
'',
'    htp.p(''</div>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Buttons: System Health Actions
-- ============================================================
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008401)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90008010)
,p_button_name=>'BTN_CLEAR_TOKEN'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Clear OAuth Token Cache'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-trash'
,p_button_css_classes=>'t-Button--warning'
);
-- ============================================================
-- Buttons: Audit Logs
-- ============================================================
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008402)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90008020)
,p_button_name=>'BTN_PURGE_AUDIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Purge Old Audit Logs'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-trash'
,p_button_css_classes=>'t-Button--danger'
);
-- ============================================================
-- Buttons: Scheduler Jobs
-- ============================================================
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008403)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90008030)
,p_button_name=>'BTN_RUN_NOW'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Run Now'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-play'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008404)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(90008030)
,p_button_name=>'BTN_CREATE_JOBS'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Create Scheduler Jobs'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-plus-circle'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008405)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(90008030)
,p_button_name=>'BTN_DROP_JOBS'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Drop All Jobs'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-trash'
,p_button_css_classes=>'t-Button--danger'
);
-- ============================================================
-- Buttons: Token History
-- ============================================================
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90008406)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90008040)
,p_button_name=>'BTN_FORCE_REFRESH_TOKEN'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Force Token Refresh'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-bolt'
,p_button_css_classes=>'t-Button--warning'
);
-- ============================================================
-- Page JavaScript: API Test Console handlers
-- ============================================================
-- Using page-level JavaScript (Function and Global Variable
-- Declaration) to wire up the test buttons.
-- Follows R-10 (IIFE wrapping) and R-08 (native messaging).
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90008060)
,p_plug_name=>'API Test JS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>99
,p_plug_display_point=>'AFTER_FOOTER'
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    htp.p(''<script>'');',
'    htp.p(''(function(apex, $) {'');',
'    htp.p(''  "use strict";'');',
'',
'    -- Test Case Lookup button',
'    htp.p(''  $("#btn_test_case").on("click", function() {'');',
'    htp.p(''    var receipt = ($("#P8_TEST_RECEIPT").val() || "").trim().toUpperCase();'');',
'    htp.p(''    if (!receipt) {'');',
'    htp.p(''      apex.message.showErrors([{type:"error",location:"page",'');',
'    htp.p(''        message:"Please enter a receipt number."}]);'');',
'    htp.p(''      return;'');',
'    htp.p(''    }'');',
'    htp.p(''    if (!/^[A-Z]{3}\\d{10}$/.test(receipt)) {'');',
'    htp.p(''      apex.message.showErrors([{type:"error",location:"page",'');',
'    htp.p(''        message:"Invalid format. Expected 3 letters + 10 digits (e.g. IOE1234567890)."}]);'');',
'    htp.p(''      return;'');',
'    htp.p(''    }'');',
'    htp.p(''    apex.message.clearErrors();'');',
'    htp.p(''    $("#P8_TEST_RECEIPT").val(receipt);'');',
'    htp.p(''    var saveDb = $("#P8_TEST_SAVE_DB").is(":checked") ? "Y" : "N";'');',
'    htp.p(''    var $btn = $(this);'');',
'    htp.p(''    var origHtml = $btn.html();'');',
'    htp.p(''    $btn.prop("disabled", true).html("<span class=\\"fa fa-refresh fa-spin\\"></span> Testing...");'');',
'    htp.p(''    $("#api_test_results").html("'');',
'    htp.p(''      <div class=\\"admin-api-test-loading\\">'');',
'    htp.p(''        <span class=\\"fa fa-refresh fa-spin fa-2x\\"></span>'');',
'    htp.p(''        <p>Querying USCIS API...</p>'');',
'    htp.p(''      </div>");'');',
'    htp.p(''    apex.server.process("TEST_CASE_LOOKUP", {'');',
'    htp.p(''      x01: receipt,'');',
'    htp.p(''      x02: saveDb'');',
'    htp.p(''    }, {'');',
'    htp.p(''      success: function(data) {'');',
'    htp.p(''        $btn.prop("disabled", false).html(origHtml);'');',
'    htp.p(''        $("#api_test_results").html(data.html);'');',
'    htp.p(''        if (data.success) {'');',
'    htp.p(''          apex.message.showPageSuccess("API call completed for " + receipt);'');',
'    htp.p(''        }'');',
'    htp.p(''      },'');',
'    htp.p(''      error: function(jqXHR, textStatus, err) {'');',
'    htp.p(''        $btn.prop("disabled", false).html(origHtml);'');',
'    htp.p(''        $("#api_test_results").html('');',
'    htp.p(''          "<div class=\\"admin-api-test-error\\">"'');',
'    htp.p(''          + "<span class=\\"fa fa-exclamation-circle fa-2x u-danger-text\\"></span>"'');',
'    htp.p(''          + "<p><strong>Request failed:</strong> " + apex.util.escapeHTML(err) + "</p></div>");'');',
'    htp.p(''      }'');',
'    htp.p(''    });'');',
'    htp.p(''  });'');',
'',
'    -- Test Connection button',
'    htp.p(''  $("#btn_test_connection").on("click", function() {'');',
'    htp.p(''    apex.message.clearErrors();'');',
'    htp.p(''    var $btn = $(this);'');',
'    htp.p(''    var origHtml = $btn.html();'');',
'    htp.p(''    $btn.prop("disabled", true).html("<span class=\\"fa fa-refresh fa-spin\\"></span> Testing...");'');',
'    htp.p(''    $("#api_test_results").html("'');',
'    htp.p(''      <div class=\\"admin-api-test-loading\\">'');',
'    htp.p(''        <span class=\\"fa fa-refresh fa-spin fa-2x\\"></span>'');',
'    htp.p(''        <p>Testing API connection...</p>'');',
'    htp.p(''      </div>");'');',
'    htp.p(''    apex.server.process("TEST_API_CONNECTION", {}, {'');',
'    htp.p(''      success: function(data) {'');',
'    htp.p(''        $btn.prop("disabled", false).html(origHtml);'');',
'    htp.p(''        $("#api_test_results").html(data.html);'');',
'    htp.p(''        if (data.success) {'');',
'    htp.p(''          apex.message.showPageSuccess(data.message);'');',
'    htp.p(''        } else {'');',
'    htp.p(''          apex.message.showErrors([{type:"error",location:"page",message:data.message}]);'');',
'    htp.p(''        }'');',
'    htp.p(''      },'');',
'    htp.p(''      error: function(jqXHR, textStatus, err) {'');',
'    htp.p(''        $btn.prop("disabled", false).html(origHtml);'');',
'    htp.p(''        $("#api_test_results").html('');',
'    htp.p(''          "<div class=\\"admin-api-test-error\\">"'');',
'    htp.p(''          + "<span class=\\"fa fa-exclamation-circle fa-2x u-danger-text\\"></span>"'');',
'    htp.p(''          + "<p><strong>Connection test failed:</strong> " + apex.util.escapeHTML(err) + "</p></div>");'');',
'    htp.p(''      }'');',
'    htp.p(''    });'');',
'    htp.p(''  });'');',
'',
'    htp.p(''})(apex, apex.jQuery);'');',
'    htp.p(''</script>'');',
'END;'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
-- ============================================================
-- Processes: After Submit
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008701)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Clear OAuth Token Cache'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_oauth_pkg.clear_token;',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_CLEAR_TOKEN'',',
'        p_new_values     => ''OAuth token cache cleared''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008401)
,p_process_success_message=>'OAuth token cache cleared.'
,p_internal_uid=>90008701
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008702)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Purge Old Audit Logs'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_audit_pkg.purge_old_records(p_days_to_keep => 90);',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_PURGE_AUDIT'',',
'        p_new_values     => ''Purged audit records older than 90 days''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008402)
,p_process_success_message=>'Old audit logs purged (90+ days old).'
,p_internal_uid=>90008702
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008703)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Run Status Check Now'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_scheduler_pkg.run_auto_check;',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_RUN_NOW'',',
'        p_new_values     => ''Manual auto-check triggered''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008403)
,p_process_success_message=>'Auto-check job submitted. Results will appear in the audit log.'
,p_internal_uid=>90008703
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008704)
,p_process_sequence=>40
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Create Scheduler Jobs'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_scheduler_pkg.create_auto_check_job(',
'        p_interval_hours => NVL(',
'            uscis_util_pkg.get_config_number(''AUTO_CHECK_INTERVAL_HOURS'', 24),',
'            24',
'        )',
'    );',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_CREATE_JOBS'',',
'        p_new_values     => ''Scheduler jobs created''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008404)
,p_process_success_message=>'Scheduler jobs created.'
,p_internal_uid=>90008704
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008705)
,p_process_sequence=>50
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Drop All Jobs'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_count NUMBER := 0;',
'BEGIN',
'    FOR rec IN (SELECT job_name FROM user_scheduler_jobs WHERE job_name LIKE ''USCIS%'') LOOP',
'        uscis_scheduler_pkg.drop_job(rec.job_name);',
'        l_count := l_count + 1;',
'    END LOOP;',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_DROP_JOBS'',',
'        p_new_values     => l_count || '' scheduler job(s) dropped''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008405)
,p_process_success_message=>'All scheduler jobs removed.'
,p_internal_uid=>90008705
);
-- ============================================================
-- Process: Force Token Refresh (After Submit)
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008706)
,p_process_sequence=>60
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Force Token Refresh'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_token VARCHAR2(4000);',
'BEGIN',
'    uscis_oauth_pkg.clear_token(''USCIS_API'');',
'    l_token := uscis_oauth_pkg.get_access_token(''USCIS_API'');',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''ADMIN_REFRESH_TOKEN'',',
'        p_new_values     => ''OAuth token force-refreshed''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90008406)
,p_process_success_message=>'OAuth token refreshed. New token fetched from authorization server.'
,p_internal_uid=>90008706
);
-- ============================================================
-- Ajax Callback: TEST_CASE_LOOKUP
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008710)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'TEST_CASE_LOOKUP'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_receipt  VARCHAR2(13);',
'    l_save     BOOLEAN;',
'    l_json     CLOB;',
'    l_status   VARCHAR2(500);',
'    l_type     VARCHAR2(100);',
'    l_details  CLOB;',
'    l_updated  VARCHAR2(100);',
'    l_html     CLOB;',
'BEGIN',
'    l_receipt := UPPER(TRIM(apex_application.g_x01));',
'    l_save    := (apex_application.g_x02 = ''Y'');',
'',
'    IF NOT uscis_util_pkg.validate_receipt_number(l_receipt) THEN',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''Invalid receipt number format'');',
'        apex_json.write(''html'',',
'            ''<div class="admin-api-test-error">''',
'            || ''<span class="fa fa-exclamation-triangle fa-2x u-warning-text"></span>''',
'            || ''<p><strong>Invalid receipt number.</strong> Expected 3 letters + 10 digits.</p></div>'');',
'        apex_json.close_object;',
'        RETURN;',
'    END IF;',
'',
'    l_json := uscis_api_pkg.check_case_status_json(',
'        p_receipt_number   => l_receipt,',
'        p_save_to_database => l_save',
'    );',
'',
'    l_status  := JSON_VALUE(l_json, ''$.current_status'');',
'    l_type    := JSON_VALUE(l_json, ''$.case_type'');',
'    l_details := JSON_VALUE(l_json, ''$.details'');',
'    l_updated := JSON_VALUE(l_json, ''$.last_updated'');',
'',
'    l_html := ''<div class="admin-api-test-result-card">''',
'        || ''<h4 class="admin-api-test-result-title">''',
'        || ''<span class="fa fa-check-circle u-success-text"></span> ''',
'        || ''API Response for '' || apex_escape.html(l_receipt)',
'        || ''</h4>''',
'        || ''<table class="admin-api-test-result-table">''',
'        || ''<tbody>''',
'        || ''<tr><th>Receipt Number</th><td class="admin-monospace">''',
'            || apex_escape.html(l_receipt) || ''</td></tr>''',
'        || ''<tr><th>Case Type</th><td>''',
'            || apex_escape.html(NVL(l_type, ''N/A'')) || ''</td></tr>''',
'        || ''<tr><th>Status</th><td><strong>''',
'            || apex_escape.html(NVL(l_status, ''N/A'')) || ''</strong></td></tr>''',
'        || ''<tr><th>Last Updated</th><td>''',
'            || apex_escape.html(NVL(l_updated, ''N/A'')) || ''</td></tr>''',
'        || ''<tr><th>Details</th><td>''',
'            || apex_escape.html(NVL(DBMS_LOB.SUBSTR(l_details, 2000, 1), ''N/A''))',
'            || ''</td></tr>''',
'        || ''<tr><th>Saved to DB</th><td>''',
'            || CASE WHEN l_save THEN ''Yes'' ELSE ''No'' END',
'            || ''</td></tr>''',
'        || ''</tbody></table>''',
'        || ''<details class="admin-api-test-raw">''',
'        || ''<summary>Raw JSON Response</summary>''',
'        || ''<pre class="admin-api-test-json">''',
'        || apex_escape.html(l_json)',
'        || ''</pre></details></div>'';',
'',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => l_receipt,',
'        p_action         => ''API_TEST_CASE'',',
'        p_new_values     => ''{'' ',
'            || ''"status":"'' || apex_escape.html(NVL(l_status, ''N/A'')) || ''"''',
'            || '',"saved":'' || CASE WHEN l_save THEN ''true'' ELSE ''false'' END',
'            || ''}''',
'    );',
'',
'    apex_json.open_object;',
'    apex_json.write(''success'', TRUE);',
'    apex_json.write(''message'', ''Case status retrieved for '' || l_receipt);',
'    apex_json.write(''html'', l_html);',
'    apex_json.close_object;',
'',
'EXCEPTION',
'    WHEN uscis_api_pkg.e_api_error THEN',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''API Error: '' || SQLERRM);',
'        apex_json.write(''html'',',
'            ''<div class="admin-api-test-error">''',
'            || ''<span class="fa fa-exclamation-triangle fa-2x u-danger-text"></span>''',
'            || ''<p><strong>API Error:</strong> '' || apex_escape.html(SQLERRM) || ''</p></div>'');',
'        apex_json.close_object;',
'    WHEN uscis_api_pkg.e_rate_limited THEN',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''Rate limited — please wait before trying again'');',
'        apex_json.write(''html'',',
'            ''<div class="admin-api-test-error">''',
'            || ''<span class="fa fa-hourglass fa-2x u-warning-text"></span>''',
'            || ''<p><strong>Rate Limited:</strong> Too many requests. Please wait.</p></div>'');',
'        apex_json.close_object;',
'    WHEN OTHERS THEN',
'        apex_debug.error(''TEST_CASE_LOOKUP failed: %s %s'', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''Unexpected error: '' || SQLERRM);',
'        apex_json.write(''html'',',
'            ''<div class="admin-api-test-error">''',
'            || ''<span class="fa fa-exclamation-circle fa-2x u-danger-text"></span>''',
'            || ''<p><strong>Error:</strong> '' || apex_escape.html(SQLERRM) || ''</p></div>'');',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>90008710
);
-- ============================================================
-- Ajax Callback: TEST_API_CONNECTION
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90008711)
,p_process_sequence=>20
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'TEST_API_CONNECTION'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_result  uscis_types_pkg.t_api_result;',
'    l_html    CLOB;',
'    l_rl_json CLOB;',
'    l_icon    VARCHAR2(100);',
'    l_color   VARCHAR2(100);',
'    l_mode    VARCHAR2(30);',
'BEGIN',
'    l_result  := uscis_api_pkg.test_api_connection;',
'    l_rl_json := uscis_api_pkg.get_rate_limit_status;',
'',
'    IF uscis_api_pkg.is_mock_mode THEN',
'        l_mode := ''Sandbox / Mock'';',
'    ELSE',
'        l_mode := ''Production / Live'';',
'    END IF;',
'',
'    IF l_result.success THEN',
'        l_icon  := ''fa-check-circle'';',
'        l_color := ''u-success-text'';',
'    ELSE',
'        l_icon  := ''fa-times-circle'';',
'        l_color := ''u-danger-text'';',
'    END IF;',
'',
'    l_html := ''<div class="admin-api-test-result-card">''',
'        || ''<h4 class="admin-api-test-result-title">''',
'        || ''<span class="fa '' || l_icon || '' '' || l_color || ''"></span> ''',
'        || ''Connection Test Results</h4>''',
'        || ''<table class="admin-api-test-result-table">''',
'        || ''<tbody>''',
'        || ''<tr><th>Status</th><td>''',
'            || CASE WHEN l_result.success',
'                    THEN ''<span class="u-success-text"><strong>Connected</strong></span>''',
'                    ELSE ''<span class="u-danger-text"><strong>Failed</strong></span>''',
'               END || ''</td></tr>''',
'        || ''<tr><th>HTTP Status</th><td>''',
'            || apex_escape.html(NVL(TO_CHAR(l_result.http_status), ''N/A''))',
'            || ''</td></tr>''',
'        || ''<tr><th>Response Time</th><td>''',
'            || apex_escape.html(NVL(TO_CHAR(l_result.response_time_ms), ''N/A''))',
'            || '' ms</td></tr>''',
'        || ''<tr><th>API Mode</th><td>'' || apex_escape.html(l_mode) || ''</td></tr>''',
'        || ''<tr><th>Base URL</th><td class="admin-monospace">''',
'            || apex_escape.html(uscis_api_pkg.get_api_base_url)',
'            || ''</td></tr>'';',
'',
'    IF l_result.error_message IS NOT NULL THEN',
'        l_html := l_html',
'            || ''<tr><th>Error</th><td class="u-danger-text">''',
'            || apex_escape.html(l_result.error_message)',
'            || ''</td></tr>'';',
'    END IF;',
'',
'    l_html := l_html || ''</tbody></table>'';',
'',
'    -- Rate limit status',
'    l_html := l_html',
'        || ''<details class="admin-api-test-raw">''',
'        || ''<summary>Rate Limit Status</summary>''',
'        || ''<pre class="admin-api-test-json">'' || apex_escape.html(l_rl_json)',
'        || ''</pre></details>'';',
'',
'    -- Raw response',
'    IF l_result.data IS NOT NULL THEN',
'        l_html := l_html',
'            || ''<details class="admin-api-test-raw">''',
'            || ''<summary>Raw API Response</summary>''',
'            || ''<pre class="admin-api-test-json">''',
'            || apex_escape.html(DBMS_LOB.SUBSTR(l_result.data, 4000, 1))',
'            || ''</pre></details>'';',
'    END IF;',
'',
'    l_html := l_html || ''</div>'';',
'',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''API_TEST_CONNECTION'',',
'        p_new_values     => ''{''',
'            || ''"http_status":'' || NVL(TO_CHAR(l_result.http_status), ''null'')',
'            || '',"response_ms":'' || NVL(TO_CHAR(l_result.response_time_ms), ''null'')',
'            || '',"success":'' || CASE WHEN l_result.success THEN ''true'' ELSE ''false'' END',
'            || ''}''',
'    );',
'',
'    apex_json.open_object;',
'    apex_json.write(''success'', l_result.success);',
'    apex_json.write(''message'',',
'        CASE WHEN l_result.success',
'             THEN ''API connection OK ('' || l_result.response_time_ms || ''ms)''',
'             ELSE ''Connection failed: HTTP '' || l_result.http_status',
'        END);',
'    apex_json.write(''html'', l_html);',
'    apex_json.close_object;',
'',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_debug.error(''TEST_API_CONNECTION failed: %s %s'', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'        uscis_audit_pkg.log_event(',
'            p_receipt_number => NULL,',
'            p_action         => ''API_TEST_CONNECTION'',',
'            p_new_values     => ''{'' ',
'                || ''"error":"'' || apex_escape.html(SQLERRM) || ''"''',
'                || '',"success":false}''',
'        );',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''Connection test failed: '' || SQLERRM);',
'        apex_json.write(''html'',',
'            ''<div class="admin-api-test-error">''',
'            || ''<span class="fa fa-exclamation-circle fa-2x u-danger-text"></span>''',
'            || ''<p><strong>Error:</strong> '' || apex_escape.html(SQLERRM) || ''</p></div>'');',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>90008711
);
wwv_flow_imp.component_end;
end;
/
