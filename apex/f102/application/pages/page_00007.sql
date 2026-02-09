prompt --application/pages/page_00007
begin
--   Manifest
--     PAGE: 00007
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
 p_id=>7
,p_name=>'Settings'
,p_alias=>'SETTINGS'
,p_step_title=>'Settings - USCIS Case Tracker'
,p_autocomplete_on_off=>'OFF'
,p_css_file_urls=>'#APP_FILES#css/maine-pine-v5.css'
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_imp.id(13056708774297879)
,p_protection_level=>'C'
,p_help_text=>'Configure API settings, scheduler options, and rate limiting for the USCIS Case Tracker.'
,p_page_component_map=>'16'
);
-- ============================================================
-- Region: Breadcrumb
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90007000)
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
-- Region 1: API Configuration (Collapsible)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90007001)
,p_plug_name=>'API Configuration'
,p_icon_css_classes=>'fa-cloud'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- ============================================================
-- Region 2: Scheduler Configuration (Collapsible)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90007002)
,p_plug_name=>'Automatic Status Checking'
,p_icon_css_classes=>'fa-clock-o'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- ============================================================
-- Region 3: Rate Limiting (Collapsed)
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90007003)
,p_plug_name=>'Rate Limiting'
,p_icon_css_classes=>'fa-dashboard'
,p_region_template_options=>'#DEFAULT#:is-collapsed:t-Region--scrollBody'
,p_plug_template=>wwv_flow_imp.id(2674015595481413035)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- ============================================================
-- Region 4: Buttons
-- ============================================================
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90007004)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>40
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- ============================================================
-- Buttons
-- ============================================================
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90007401)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90007004)
,p_button_name=>'BTN_SAVE'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Save Settings'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-save'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90007402)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(90007004)
,p_button_name=>'BTN_CANCEL'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Cancel'
,p_button_position=>'PREVIOUS'
,p_button_redirect_url=>'f?p=&APP_ID.:1:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-chevron-left'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90007403)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(90007001)
,p_button_name=>'BTN_TEST_API'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Test API Connection'
,p_button_position=>'NEXT'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-plug'
,p_button_css_classes=>'t-Button--warning'
);
-- ============================================================
-- Items: API Configuration region
-- ============================================================
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007101)
,p_name=>'P7_API_MODE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90007001)
,p_prompt=>'API Mode'
,p_display_as=>'NATIVE_RADIOGROUP'
,p_lov=>'STATIC:Sandbox (Testing);SANDBOX,Production;PRODUCTION'
,p_field_template=>1609122147107268652
,p_item_template_options=>'#DEFAULT#:t-Form-fieldContainer--radioButtonGroup'
,p_lov_display_extra=>'NO'
,p_help_text=>'Sandbox mode uses mock responses for testing. Production mode calls the live USCIS API.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'columns', '2',
  'number_of_columns', '2')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007102)
,p_name=>'P7_API_BASE_URL'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90007001)
,p_prompt=>'API Base URL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The USCIS API endpoint URL.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007103)
,p_name=>'P7_HAS_CREDENTIALS'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90007001)
,p_prompt=>'Credentials Status'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_escape_on_http_output=>'N'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Whether OAuth2 client credentials are configured.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007104)
,p_name=>'P7_RATE_LIMIT_RPS'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(90007001)
,p_prompt=>'Rate Limit (req/sec)'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007105)
,p_name=>'P7_REQUESTS_TODAY'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(90007001)
,p_prompt=>'API Requests Today'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
-- ============================================================
-- Items: Scheduler Configuration region
-- ============================================================
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007201)
,p_name=>'P7_AUTO_CHECK_ENABLED'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Enable automatic status checks'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'When enabled, the system automatically checks USCIS for status updates on all active cases at the configured interval.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'off_value', 'N',
  'on_value', 'Y',
  'use_defaults', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007202)
,p_name=>'P7_AUTO_CHECK_INTERVAL'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Check Interval'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:Every 6 hours;6,Every 12 hours;12,Every 24 hours;24,Every 48 hours;48,Weekly;168'
,p_lov_display_null=>'NO'
,p_cHeight=>1
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'How often the system checks for status updates.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007203)
,p_name=>'P7_AUTO_CHECK_BATCH_SIZE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Cases per Batch'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>10
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Number of cases to check in each batch run. Lower values reduce API load; higher values ensure all cases are checked faster.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'number_alignment', 'left',
  'virtual_keyboard', 'decimal')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007204)
,p_name=>'P7_NEXT_RUN'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Next Scheduled Check'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007205)
,p_name=>'P7_LAST_RUN'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Last Run'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007206)
,p_name=>'P7_JOB_STATUS'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(90007002)
,p_prompt=>'Job Status'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
-- ============================================================
-- Items: Rate Limiting region
-- ============================================================
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007301)
,p_name=>'P7_RATE_LIMIT_DISPLAY'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90007003)
,p_prompt=>'Requests per Second'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007302)
,p_name=>'P7_DAILY_QUOTA'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90007003)
,p_item_default=>'1,000 requests'
,p_prompt=>'Daily Quota'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90007303)
,p_name=>'P7_REQUESTS_TODAY_DETAIL'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90007003)
,p_prompt=>'Requests Used Today'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
);
-- ============================================================
-- Validation: Batch Size
-- ============================================================
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(90007501)
,p_validation_name=>'V_BATCH_SIZE'
,p_validation_sequence=>10
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_size NUMBER;',
'BEGIN',
'    l_size := TO_NUMBER(:P7_AUTO_CHECK_BATCH_SIZE);',
'    IF l_size < 1 OR l_size > 200 THEN',
'        RETURN ''Batch size must be between 1 and 200.'';',
'    END IF;',
'    RETURN NULL;',
'EXCEPTION',
'    WHEN VALUE_ERROR THEN',
'        RETURN ''Batch size must be a number.'';',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_ERR_TEXT'
,p_error_message=>'Invalid batch size.'
,p_validation_condition=>'P7_AUTO_CHECK_ENABLED'
,p_validation_condition2=>'Y'
,p_validation_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_when_button_pressed=>wwv_flow_imp.id(90007401)
,p_associated_item=>wwv_flow_imp.id(90007203)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
-- ============================================================
-- Dynamic Action: Toggle Scheduler Fields
-- ============================================================
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90007601)
,p_name=>'Toggle Scheduler Fields'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P7_AUTO_CHECK_ENABLED'
,p_condition_element=>'P7_AUTO_CHECK_ENABLED'
,p_triggering_condition_type=>'EQUALS'
,p_triggering_expression=>'Y'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90007611)
,p_event_id=>wwv_flow_imp.id(90007601)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P7_AUTO_CHECK_INTERVAL,P7_AUTO_CHECK_BATCH_SIZE,P7_NEXT_RUN,P7_LAST_RUN,P7_JOB_STATUS'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90007612)
,p_event_id=>wwv_flow_imp.id(90007601)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_HIDE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P7_AUTO_CHECK_INTERVAL,P7_AUTO_CHECK_BATCH_SIZE,P7_NEXT_RUN,P7_LAST_RUN,P7_JOB_STATUS'
);
-- ============================================================
-- Dynamic Action: Test API Connection
-- ============================================================
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90007602)
,p_name=>'Test API Connection'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(90007403)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90007621)
,p_event_id=>wwv_flow_imp.id(90007602)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var da = this;',
'(function(apex, $) {',
'    "use strict";',
'    apex.message.clearErrors();',
'    var $btn = $(da.triggeringElement);',
'    var origLabel = $btn.html();',
'    $btn.prop("disabled", true).html("Testing...");',
'    apex.server.process("TEST_API", {',
'        pageItems: "#P7_API_MODE"',
'    }, {',
'        success: function(data) {',
'            $btn.prop("disabled", false).html(origLabel);',
'            if (data.success) {',
'                apex.message.showPageSuccess(data.message);',
'            } else {',
'                apex.message.showErrors([{',
'                    type: "error",',
'                    location: "page",',
'                    message: data.message',
'                }]);',
'            }',
'        },',
'        error: function(jqXHR, textStatus, errorThrown) {',
'            $btn.prop("disabled", false).html(origLabel);',
'            apex.message.showErrors([{',
'                type: "error",',
'                location: "page",',
'                message: "API test failed: " + errorThrown',
'            }]);',
'        }',
'    });',
'})(apex, apex.jQuery);'))
);
-- ============================================================
-- Process: Load Settings (Before Header)
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90007701)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load Settings'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_job_name      VARCHAR2(30) := ''USCIS_AUTO_CHECK_JOB'';',
'    l_requests      NUMBER := 0;',
'BEGIN',
'    -- API Configuration',
'    :P7_API_MODE := uscis_util_pkg.get_config(''USCIS_API_MODE'', ''SANDBOX'');',
'    :P7_API_BASE_URL := uscis_util_pkg.get_config(',
'        ''USCIS_API_BASE_URL'',',
'        ''https://api-int.uscis.gov/case-status''',
'    );',
'    IF uscis_oauth_pkg.has_credentials THEN',
'        :P7_HAS_CREDENTIALS := ''<span class="u-success-text">''',
'            || ''<span class="fa fa-check-circle"></span> Configured</span>'';',
'    ELSE',
'        :P7_HAS_CREDENTIALS := ''<span class="u-danger-text">''',
'            || ''<span class="fa fa-exclamation-triangle"></span> Not Configured</span>'';',
'    END IF;',
'    :P7_RATE_LIMIT_RPS := uscis_util_pkg.get_config(''RATE_LIMIT_REQUESTS_PER_SECOND'', ''10'');',
'    :P7_RATE_LIMIT_DISPLAY := :P7_RATE_LIMIT_RPS;',
'    SELECT NVL(SUM(request_count), 0)',
'      INTO l_requests',
'      FROM api_rate_limiter',
'     WHERE service_name = ''USCIS_API''',
'       AND TRUNC(window_start) = TRUNC(SYSDATE);',
'    :P7_REQUESTS_TODAY := TO_CHAR(l_requests, ''FM999,999'') || '' / 1,000'';',
'    :P7_REQUESTS_TODAY_DETAIL := :P7_REQUESTS_TODAY;',
'    -- Scheduler Configuration',
'    :P7_AUTO_CHECK_ENABLED := uscis_util_pkg.get_config(''AUTO_CHECK_ENABLED'', ''N'');',
'    :P7_AUTO_CHECK_INTERVAL := uscis_util_pkg.get_config_number(',
'        ''AUTO_CHECK_INTERVAL_HOURS'', 24',
'    );',
'    :P7_AUTO_CHECK_BATCH_SIZE := uscis_util_pkg.get_config_number(',
'        ''AUTO_CHECK_BATCH_SIZE'', 50',
'    );',
'    BEGIN',
'        SELECT TO_CHAR(next_run_date, ''Mon DD, YYYY HH:MI AM'')',
'          INTO :P7_NEXT_RUN',
'          FROM user_scheduler_jobs',
'         WHERE job_name = l_job_name;',
'    EXCEPTION',
'        WHEN NO_DATA_FOUND THEN',
'            :P7_NEXT_RUN := ''Not scheduled'';',
'    END;',
'    BEGIN',
'        SELECT TO_CHAR(last_start_date, ''Mon DD, YYYY HH:MI AM'')',
'          INTO :P7_LAST_RUN',
'          FROM user_scheduler_jobs',
'         WHERE job_name = l_job_name;',
'    EXCEPTION',
'        WHEN NO_DATA_FOUND THEN',
'            :P7_LAST_RUN := ''Never'';',
'    END;',
'    :P7_JOB_STATUS := uscis_scheduler_pkg.get_job_status(l_job_name);',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>90007701
);
-- ============================================================
-- Process: Save Settings (After Submit)
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90007702)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Save Settings'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_util_pkg.set_config(''USCIS_API_MODE'', :P7_API_MODE);',
'    uscis_util_pkg.set_config(''AUTO_CHECK_ENABLED'', :P7_AUTO_CHECK_ENABLED);',
'    uscis_util_pkg.set_config(',
'        ''AUTO_CHECK_INTERVAL_HOURS'',',
'        TO_CHAR(:P7_AUTO_CHECK_INTERVAL)',
'    );',
'    uscis_util_pkg.set_config(',
'        ''AUTO_CHECK_BATCH_SIZE'',',
'        TO_CHAR(:P7_AUTO_CHECK_BATCH_SIZE)',
'    );',
'    IF :P7_AUTO_CHECK_ENABLED = ''Y'' THEN',
'        uscis_scheduler_pkg.create_auto_check_job(',
'            p_interval_hours => :P7_AUTO_CHECK_INTERVAL',
'        );',
'    ELSE',
'        uscis_scheduler_pkg.set_auto_check_enabled(FALSE);',
'    END IF;',
'    uscis_audit_pkg.log_event(',
'        p_receipt_number => NULL,',
'        p_action         => ''SETTINGS_UPDATED'',',
'        p_new_values     => ''{'' ',
'            || ''"api_mode":"'' || apex_escape.html(:P7_API_MODE) || ''"'' ',
'            || '',"auto_check":"'' || apex_escape.html(:P7_AUTO_CHECK_ENABLED) || ''"'' ',
'            || '',"interval":"'' || :P7_AUTO_CHECK_INTERVAL || ''"'' ',
'            || '',"batch_size":"'' || :P7_AUTO_CHECK_BATCH_SIZE || ''"'' ',
'            || ''}''',
'    );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(90007401)
,p_process_success_message=>'Settings saved successfully.'
,p_internal_uid=>90007702
);
-- ============================================================
-- Ajax Callback: TEST_API
-- ============================================================
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90007703)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'TEST_API'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_result     uscis_types_pkg.t_api_result;',
'    l_mode       VARCHAR2(30) := ''UNKNOWN'';',
'BEGIN',
'    l_mode := UPPER(NVL(V(''P7_API_MODE''), ''SANDBOX''));',
'    -- Always hit the real API endpoint to verify connectivity',
'    l_result := uscis_api_pkg.test_api_connection;',
'    IF l_result.success THEN',
'        uscis_audit_pkg.log_event(',
'            p_receipt_number => NULL,',
'            p_action         => ''API_TEST'',',
'            p_new_values     => ''{''',
'                || ''"mode":"'' || apex_escape.html(l_mode) || ''"''',
'                || '',"http_status":'' || l_result.http_status',
'                || '',"response_ms":'' || l_result.response_time_ms',
'                || '',"success":true}''',
'        );',
'        apex_json.open_object;',
'        apex_json.write(''success'', TRUE);',
'        apex_json.write(''message'',',
'            ''API connection successful ('' || l_result.response_time_ms || ''ms). Mode: '' || l_mode);',
'        apex_json.close_object;',
'    ELSE',
'        uscis_audit_pkg.log_event(',
'            p_receipt_number => NULL,',
'            p_action         => ''API_TEST'',',
'            p_new_values     => ''{''',
'                || ''"mode":"'' || apex_escape.html(l_mode) || ''"''',
'                || '',"http_status":'' || l_result.http_status',
'                || '',"error":"'' || apex_escape.html(l_result.error_message) || ''"''',
'                || '',"success":false}''',
'        );',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'',',
'            ''API returned HTTP '' || l_result.http_status || '': '' || l_result.error_message);',
'        apex_json.close_object;',
'    END IF;',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        apex_debug.error(''TEST_API failed: %s %s'', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'        uscis_audit_pkg.log_event(',
'            p_receipt_number => NULL,',
'            p_action         => ''API_TEST'',',
'            p_new_values     => ''{''',
'                || ''"mode":"'' || apex_escape.html(l_mode) || ''"''',
'                || '',"error":"'' || apex_escape.html(SQLERRM) || ''"''',
'                || '',"success":false}''',
'        );',
'        apex_json.open_object;',
'        apex_json.write(''success'', FALSE);',
'        apex_json.write(''message'', ''API test failed: '' || SQLERRM);',
'        apex_json.close_object;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>90007703
);
wwv_flow_imp.component_end;
end;
/
