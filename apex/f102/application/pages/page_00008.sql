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
,p_css_file_urls=>'#APP_FILES#app-styles.css'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Admin page health cards */',
'.admin-health-cards {',
'  display: grid;',
'  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));',
'  gap: 16px;',
'  padding: 8px 0;',
'}',
'.admin-health-card {',
'  background: var(--ut-component-background-color, #fff);',
'  border-radius: 8px;',
'  padding: 16px;',
'  box-shadow: 0 1px 3px rgba(0,0,0,.12);',
'}',
'.admin-health-card .card-label {',
'  color: var(--ut-component-text-muted-color, #666);',
'  font-size: 12px;',
'  text-transform: uppercase;',
'  margin-bottom: 4px;',
'}',
'.admin-health-card .card-value {',
'  font-size: 24px;',
'  font-weight: 700;',
'}',
'.admin-audit-table { width: 100%; border-collapse: collapse; }',
'.admin-audit-table th { background: var(--ut-component-header-background-color, #f5f5f5);',
'  padding: 8px 12px; text-align: left; font-weight: 600; font-size: 12px;',
'  text-transform: uppercase; border-bottom: 2px solid var(--ut-component-border-color, #ddd); }',
'.admin-audit-table td { padding: 8px 12px; border-bottom: 1px solid var(--ut-component-border-color, #eee);',
'  font-size: 13px; vertical-align: top; }',
'.admin-audit-table tr:hover td { background: var(--ut-component-highlight-background-color, #f9f9f9); }'))
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_imp.id(13056708774297879)
,p_protection_level=>'C'
,p_help_text=>'System administration: health monitoring, audit logs, and scheduler job management.'
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
'        htp.p(''<tr><td colspan="5" style="text-align:center;padding:24px;color:#666;">No audit records found.</td></tr>'');',
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
'        htp.p(''<td style="text-align:right">'' || r.run_count || ''</td>'');',
'        htp.p(''<td style="text-align:right">'' || r.failure_count || ''</td>'');',
'        htp.p(''</tr>'');',
'    END LOOP;',
'    IF l_count = 0 THEN',
'        htp.p(''<tr><td colspan="7" style="text-align:center;padding:24px;color:#666;">No USCIS scheduler jobs found. Use the buttons below to create them.</td></tr>'');',
'    END IF;',
'    htp.p(''</tbody></table>'');',
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
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_image_alt=>'Clear OAuth Token Cache'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-trash-o'
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
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_image_alt=>'Purge Old Audit Logs'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-eraser'
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
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
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
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
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
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_image_alt=>'Drop All Jobs'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-times-circle'
,p_button_css_classes=>'t-Button--danger'
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
wwv_flow_imp.component_end;
end;
/
