prompt --application/pages/page_00003
begin
--   Manifest
--     PAGE: 00003
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
 p_id=>3
,p_name=>'Case Details'
,p_alias=>'CASE-DETAILS'
,p_step_title=>'Case Details'
,p_autocomplete_on_off=>'OFF'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Status Badge Styling */',
'.status-badge {',
'  display: inline-block;',
'  padding: 4px 12px;',
'  border-radius: 12px;',
'  font-size: 12px;',
'  font-weight: 600;',
'  text-transform: uppercase;',
'  line-height: 1.4;',
'}',
'.status-approved { background-color: #2e8540; color: #fff; }',
'.status-denied { background-color: #cd2026; color: #fff; }',
'.status-rfe { background-color: #0071bc; color: #fff; }',
'.status-received { background-color: #4c2c92; color: #fff; }',
'.status-pending { background-color: #fdb81e; color: #212121; }',
'.status-unknown { background-color: #5b616b; color: #fff; }',
'',
'/* Receipt Number Styling */',
'.receipt-number {',
'  font-family: "Courier New", monospace;',
'  font-weight: bold;',
'  letter-spacing: 1px;',
'  font-size: 18px;',
'}',
'',
'/* Case Detail Layout */',
'.case-detail-card {',
'  padding: 4px 0;',
'}',
'.case-header-row {',
'  display: flex;',
'  justify-content: space-between;',
'  align-items: center;',
'  flex-wrap: wrap;',
'  gap: 12px;',
'  margin-bottom: 16px;',
'  padding-bottom: 12px;',
'  border-bottom: 1px solid #e0e0e0;',
'}',
'.case-receipt-info {',
'  display: flex;',
'  align-items: center;',
'  gap: 12px;',
'}',
'.active-tag {',
'  display: inline-block;',
'  padding: 2px 8px;',
'  border-radius: 4px;',
'  font-size: 11px;',
'  font-weight: 600;',
'  background-color: #2e8540;',
'  color: #fff;',
'}',
'.inactive-tag {',
'  display: inline-block;',
'  padding: 2px 8px;',
'  border-radius: 4px;',
'  font-size: 11px;',
'  font-weight: 600;',
'  background-color: #5b616b;',
'  color: #fff;',
'}',
'.case-info-grid {',
'  display: grid;',
'  grid-template-columns: 1fr 1fr;',
'  gap: 12px 24px;',
'}',
'@media (max-width: 640px) {',
'  .case-info-grid { grid-template-columns: 1fr; }',
'}',
'.info-item {',
'  display: flex;',
'  flex-direction: column;',
'  gap: 2px;',
'}',
'.info-label {',
'  font-size: 11px;',
'  font-weight: 600;',
'  text-transform: uppercase;',
'  color: #666;',
'}',
'.info-value {',
'  font-size: 14px;',
'  color: #212121;',
'}',
'',
'/* Status History Table */',
'.status-history-table {',
'  width: 100%;',
'  border-collapse: collapse;',
'}',
'.status-history-table th {',
'  padding: 8px;',
'  text-align: left;',
'  border-bottom: 2px solid #e0e0e0;',
'  font-size: 12px;',
'  font-weight: 600;',
'  text-transform: uppercase;',
'  color: #666;',
'}',
'.status-history-table td {',
'  padding: 8px;',
'  border-bottom: 1px solid #f0f0f0;',
'  font-size: 13px;',
'}'))
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'U'
,p_page_component_map=>'16'
);
-- Breadcrumb Region
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13300001000000001)
,p_plug_name=>'Breadcrumb'
,p_region_template_options=>'#DEFAULT#:t-BreadcrumbRegion--useBreadcrumbTitle'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>2531463326621247859
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_menu_id=>wwv_flow_imp.id(13051532648297767)
,p_plug_source_type=>'NATIVE_BREADCRUMB'
,p_menu_template_id=>4072363345357175094
);
-- Case Information Region
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13300002000000002)
,p_plug_name=>'Case Information'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>10
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div class="case-detail-card">',
'  <div class="case-header-row">',
'    <div class="case-receipt-info">',
'      <span class="receipt-number">&P3_RECEIPT_NUMBER.</span>',
'      <span class="&P3_ACTIVE_CLASS.">&P3_ACTIVE_DISPLAY.</span>',
'    </div>',
'    <div class="case-status-display">',
'      <span class="status-badge &P3_STATUS_CLASS.">&P3_CURRENT_STATUS.</span>',
'    </div>',
'  </div>',
'  <div class="case-info-grid">',
'    <div class="info-item">',
'      <span class="info-label">Case Type</span>',
'      <span class="info-value">&P3_CASE_TYPE.</span>',
'    </div>',
'    <div class="info-item">',
'      <span class="info-label">Last Updated</span>',
'      <span class="info-value">&P3_LAST_UPDATED.</span>',
'    </div>',
'    <div class="info-item">',
'      <span class="info-label">Tracking Since</span>',
'      <span class="info-value">&P3_TRACKING_SINCE.</span>',
'    </div>',
'    <div class="info-item">',
'      <span class="info-label">Notes</span>',
'      <span class="info-value">&P3_NOTES.</span>',
'    </div>',
'  </div>',
'</div>'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- Status History Region
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13300003000000003)
,p_plug_name=>'Status History'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>20
,p_plug_source=>'&P3_STATUS_HTML.'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
-- Hidden Items
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300010000000010)
,p_name=>'P3_RECEIPT_NUMBER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300011000000011)
,p_name=>'P3_CASE_TYPE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300012000000012)
,p_name=>'P3_CURRENT_STATUS'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300013000000013)
,p_name=>'P3_LAST_UPDATED'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300014000000014)
,p_name=>'P3_TRACKING_SINCE'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300015000000015)
,p_name=>'P3_IS_ACTIVE'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300016000000016)
,p_name=>'P3_NOTES'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300017000000017)
,p_name=>'P3_STATUS_CLASS'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300018000000018)
,p_name=>'P3_ACTIVE_DISPLAY'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300019000000019)
,p_name=>'P3_ACTIVE_CLASS'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_imp.id(13300002000000002)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13300020000000020)
,p_name=>'P3_STATUS_HTML'
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_imp.id(13300003000000003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
);
-- Buttons in Breadcrumb Region
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13300100000000100)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(13300001000000001)
,p_button_name=>'BTN_BACK'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Back to Cases'
,p_button_position=>'PREVIOUS'
,p_button_redirect_url=>'f?p=&APP_ID.:22:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-chevron-left'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13300101000000101)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(13300001000000001)
,p_button_name=>'BTN_REFRESH'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Refresh Status'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-refresh'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13300102000000102)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(13300001000000001)
,p_button_name=>'BTN_DELETE'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft:t-Button--danger'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Delete Case'
,p_button_position=>'NEXT'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-trash-o'
);
-- Before Header Process: Load Case Data
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13300200000000200)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load Case Data'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_receipt      VARCHAR2(13) := :P3_RECEIPT_NUMBER;',
'  l_html         VARCHAR2(32767);',
'  l_count        NUMBER := 0;',
'  l_raw_status   VARCHAR2(500);',
'BEGIN',
'  IF l_receipt IS NULL THEN',
'    RETURN;',
'  END IF;',
'',
'  -- Load case data from view',
'  BEGIN',
'    SELECT',
'      NVL(case_type, ''Unknown''),',
'      NVL(current_status, ''Unknown''),',
'      NVL(TO_CHAR(last_updated, ''Mon DD, YYYY HH:MI AM''), ''N/A''),',
'      NVL(TO_CHAR(tracking_since, ''Mon DD, YYYY''), ''N/A''),',
'      NVL(is_active, ''Y''),',
'      notes',
'    INTO',
'      :P3_CASE_TYPE,',
'      :P3_CURRENT_STATUS,',
'      :P3_LAST_UPDATED,',
'      :P3_TRACKING_SINCE,',
'      :P3_IS_ACTIVE,',
'      :P3_NOTES',
'    FROM v_case_current_status',
'    WHERE receipt_number = l_receipt;',
'  EXCEPTION',
'    WHEN NO_DATA_FOUND THEN',
'      :P3_CURRENT_STATUS := ''Not Found'';',
'      :P3_CASE_TYPE := ''Unknown'';',
'      :P3_LAST_UPDATED := ''N/A'';',
'      :P3_TRACKING_SINCE := ''N/A'';',
'      :P3_IS_ACTIVE := ''N'';',
'      :P3_NOTES := NULL;',
'  END;',
'',
'  -- Escape display values for safe HTML rendering',
'  :P3_CASE_TYPE := apex_escape.html(:P3_CASE_TYPE);',
'  l_raw_status := :P3_CURRENT_STATUS;',
'  :P3_CURRENT_STATUS := apex_escape.html(:P3_CURRENT_STATUS);',
'  :P3_LAST_UPDATED := apex_escape.html(:P3_LAST_UPDATED);',
'  :P3_TRACKING_SINCE := apex_escape.html(:P3_TRACKING_SINCE);',
'  :P3_NOTES := apex_escape.html(:P3_NOTES);',
'',
'  -- Status CSS class (use raw value for matching)',
'  :P3_STATUS_CLASS := CASE',
'    WHEN UPPER(l_raw_status) LIKE ''%APPROVED%'' THEN ''status-approved''',
'    WHEN UPPER(l_raw_status) LIKE ''%DENIED%''',
'      OR UPPER(l_raw_status) LIKE ''%REJECT%'' THEN ''status-denied''',
'    WHEN UPPER(l_raw_status) LIKE ''%RFE%''',
'      OR UPPER(l_raw_status) LIKE ''%EVIDENCE%'' THEN ''status-rfe''',
'    WHEN UPPER(l_raw_status) LIKE ''%RECEIVED%'' THEN ''status-received''',
'    WHEN UPPER(l_raw_status) LIKE ''%PENDING%''',
'      OR UPPER(l_raw_status) LIKE ''%REVIEW%'' THEN ''status-pending''',
'    ELSE ''status-unknown''',
'  END;',
'',
'  -- Active display',
'  :P3_ACTIVE_DISPLAY := CASE WHEN :P3_IS_ACTIVE = ''Y''',
'    THEN ''Active'' ELSE ''Inactive'' END;',
'  :P3_ACTIVE_CLASS := CASE WHEN :P3_IS_ACTIVE = ''Y''',
'    THEN ''active-tag'' ELSE ''inactive-tag'' END;',
'',
'  -- Build status history HTML table',
'  l_html := ''<table class="status-history-table">''',
'    || ''<thead><tr>''',
'    || ''<th>Date</th>''',
'    || ''<th>Status</th>''',
'    || ''<th>Type</th>''',
'    || ''<th>Source</th>''',
'    || ''</tr></thead><tbody>'';',
'',
'  FOR rec IN (',
'    SELECT',
'      TO_CHAR(last_updated, ''Mon DD, YYYY HH:MI AM'') AS updated_dt,',
'      NVL(current_status, ''Unknown'') AS sts,',
'      NVL(case_type, ''-'') AS ctype,',
'      NVL(source, ''MANUAL'') AS src',
'    FROM status_updates',
'    WHERE receipt_number = l_receipt',
'    ORDER BY last_updated DESC',
'    FETCH FIRST 20 ROWS ONLY',
'  ) LOOP',
'    l_html := l_html || ''<tr>''',
'      || ''<td>'' || apex_escape.html(rec.updated_dt) || ''</td>''',
'      || ''<td>'' || apex_escape.html(rec.sts) || ''</td>''',
'      || ''<td>'' || apex_escape.html(rec.ctype) || ''</td>''',
'      || ''<td>'' || apex_escape.html(rec.src) || ''</td>''',
'      || ''</tr>'';',
'    l_count := l_count + 1;',
'  END LOOP;',
'',
'  IF l_count = 0 THEN',
'    l_html := l_html',
'      || ''<tr><td colspan="4" style="padding:16px;text-align:center;''',
'      || ''color:#666">No status updates recorded yet.</td></tr>'';',
'  END IF;',
'',
'  l_html := l_html || ''</tbody></table>'';',
'  :P3_STATUS_HTML := l_html;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
-- After Submit Process: Refresh Status
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13300201000000201)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Refresh Status'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_status uscis_types_pkg.t_case_status;',
'BEGIN',
'  IF :P3_RECEIPT_NUMBER IS NULL THEN',
'    apex_error.add_error(',
'      p_message => ''No receipt number specified. Please navigate from the Cases list.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'  END IF;',
'  l_status := uscis_api_pkg.check_case_status(',
'    p_receipt_number   => :P3_RECEIPT_NUMBER,',
'    p_save_to_database => TRUE',
'  );',
'EXCEPTION',
'  WHEN OTHERS THEN',
'    apex_debug.error(',
'      p_message => ''Refresh status failed for [%s]: %s'',',
'      p0 => :P3_RECEIPT_NUMBER,',
'      p1 => SQLERRM',
'    );',
'    apex_error.add_error(',
'      p_message => ''Failed to refresh status. The USCIS API may be unavailable.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(13300101000000101)
,p_process_success_message=>'Status refreshed successfully.'
);
-- After Submit Process: Delete Case
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13300202000000202)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Delete Case'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'  IF :P3_RECEIPT_NUMBER IS NULL THEN',
'    apex_error.add_error(',
'      p_message => ''No receipt number specified. Cannot delete.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'  END IF;',
'  uscis_case_pkg.delete_case(',
'    p_receipt_number => :P3_RECEIPT_NUMBER',
'  );',
'EXCEPTION',
'  WHEN OTHERS THEN',
'    apex_debug.error(',
'      p_message => ''Delete case failed for [%s]: %s'',',
'      p0 => :P3_RECEIPT_NUMBER,',
'      p1 => SQLERRM',
'    );',
'    apex_error.add_error(',
'      p_message => ''Failed to delete case. Please try again.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'DELETE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Case deleted successfully.'
);
-- Branch: After Delete -> Back to Cases list
wwv_flow_imp_page.create_page_branch(
 p_id=>wwv_flow_imp.id(13300300000000300)
,p_branch_name=>'After Delete'
,p_branch_action=>'f?p=&APP_ID.:22:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
,p_branch_condition_type=>'REQUEST_EQUALS_CONDITION'
,p_branch_condition=>'DELETE'
);
-- Branch: Default -> Reload Case Details (after Refresh)
wwv_flow_imp_page.create_page_branch(
 p_id=>wwv_flow_imp.id(13300301000000301)
,p_branch_name=>'Reload Case Details'
,p_branch_action=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.::P3_RECEIPT_NUMBER:&P3_RECEIPT_NUMBER.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>20
);
-- Dynamic Action: Confirm Delete
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13300600000000600)
,p_name=>'Confirm Delete'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(13300102000000102)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13300601000000601)
,p_event_id=>wwv_flow_imp.id(13300600000000600)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'apex.message.confirm("Are you sure you want to delete this case? This action cannot be undone.",function(ok){if(ok){apex.page.submit("DELETE");}});'
);
wwv_flow_imp.component_end;
end;
/
