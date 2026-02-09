prompt --application/pages/page_00006
begin
--   Manifest
--     PAGE: 00006
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
 p_id=>6
,p_name=>'Import/Export'
,p_alias=>'TRANSFER'
,p_step_title=>'Import & Export Cases - USCIS Case Tracker'
,p_autocomplete_on_off=>'OFF'
,p_javascript_file_urls=>'#APP_FILES#js/page_0006_import_export.js'
,p_css_file_urls=>'#APP_FILES#app-styles.css'
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_help_text=>'Import cases from JSON/CSV files or export your tracked cases for backup or analysis.'
,p_page_component_map=>'16'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90006001)
,p_plug_name=>'Export Cases'
,p_icon_css_classes=>'fa-download'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_grid_column_span=>6
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div class="transfer-card">',
'  <div class="transfer-card__header">',
'    <span class="t-Icon fa fa-download"></span>',
'    <h3>Download Cases</h3>',
'  </div>',
'  <p class="transfer-card__desc">Export your tracked cases to a file for backup, sharing, or analysis.</p>',
'</div>'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90006002)
,p_plug_name=>'Import Cases'
,p_icon_css_classes=>'fa-upload'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>6
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div class="transfer-card">',
'  <div class="transfer-card__header">',
'    <span class="t-Icon fa fa-upload"></span>',
'    <h3>Upload Cases</h3>',
'  </div>',
'  <p class="transfer-card__desc">Import cases from a JSON or CSV file. Supported formats are provided below.</p>',
'</div>'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90006003)
,p_plug_name=>'Import Result'
,p_region_template_options=>'#DEFAULT#:t-Alert--horizontal:t-Alert--defaultIcons:t-Alert--success'
,p_plug_template=>wwv_flow_imp.id(2674006209498413027)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source=>'&P6_IMPORT_RESULT_MSG.'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P6_IMPORT_RESULT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(90006004)
,p_plug_name=>'File Format Help'
,p_icon_css_classes=>'fa-question-circle-o'
,p_region_template_options=>'#DEFAULT#:is-collapsed:t-Region--scrollBody'
,p_plug_template=>wwv_flow_imp.id(2674015595481413035)
,p_plug_display_sequence=>40
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<h4>JSON Format</h4>',
'<pre class="u-code">{',
'  "cases": [',
'    {',
'      "receipt_number": "IOE1234567890",',
'      "case_type": "I-765",',
'      "current_status": "Case Was Received",',
'      "last_updated": "2025-01-15T10:30:00Z",',
'      "details": "Case was received and a receipt notice was sent.",',
'      "notes": "Employment authorization",',
'      "is_active": 1,',
'      "check_frequency": 24',
'    }',
'  ]',
'}</pre>',
'<h4>CSV Format</h4>',
'<pre class="u-code">Receipt Number,Case Type,Current Status,Last Updated,Is Active,Check Frequency,Tracking Since,Created By,Notes',
'"IOE1234567890","I-765","Case Was Received","2025-01-15 10:30:00",1,24,"2025-01-01 08:00:00","user@example.com","Employment authorization"</pre>',
'',
'<h4>Requirements</h4>',
'<ul>',
'  <li>Maximum file size: <strong>10 MB</strong></li>',
'  <li>Accepted file types: <strong>.json</strong> or <strong>.csv</strong></li>',
'  <li>Receipt numbers must be valid 13-character USCIS format (e.g., IOE1234567890)</li>',
'  <li>Timestamps should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ) or YYYY-MM-DD HH24:MI:SS</li>',
'</ul>'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90006402)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_imp.id(90006002)
,p_button_name=>'BTN_PREVIEW'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_image_alt=>'Preview Import'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-eye'
,p_request_source=>'PREVIEW'
,p_request_source_type=>'STATIC'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90006401)
,p_button_sequence=>50
,p_button_plug_id=>wwv_flow_imp.id(90006001)
,p_button_name=>'BTN_EXPORT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Download Export'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-download'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90006403)
,p_button_sequence=>50
,p_button_plug_id=>wwv_flow_imp.id(90006002)
,p_button_name=>'BTN_IMPORT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Import Cases'
,p_button_position=>'NEXT'
,p_button_condition=>'P6_IMPORT_PREVIEW'
,p_button_condition_type=>'ITEM_IS_NOT_NULL'
,p_icon_css_classes=>'fa-upload'
,p_button_cattributes=>'data-confirm-message="Are you sure you want to import the selected cases?"'
,p_request_source=>'IMPORT'
,p_request_source_type=>'STATIC'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(90006404)
,p_button_sequence=>60
,p_button_plug_id=>wwv_flow_imp.id(90006002)
,p_button_name=>'BTN_CLEAR'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>wwv_flow_imp.id(13349797865298420)
,p_button_image_alt=>'Clear'
,p_button_position=>'NEXT'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-times'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006101)
,p_name=>'P6_EXPORT_FORMAT'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90006001)
,p_item_default=>'JSON'
,p_prompt=>'Export Format'
,p_display_as=>'NATIVE_RADIOGROUP'
,p_lov=>'STATIC:JSON;JSON,CSV;CSV'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#:t-Form-fieldContainer--radioButtonGroup'
,p_lov_display_extra=>'NO'
,p_help_text=>'Select the format for your export file. JSON includes full case history; CSV is simpler but lacks history.'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006102)
,p_name=>'P6_EXPORT_FILTER'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90006001)
,p_prompt=>'Receipt Prefix Filter'
,p_placeholder=>'e.g., IOE, LIN (leave empty for all)'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>50
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Optional: Enter a receipt number prefix to filter cases (e.g., IOE to export only IOE cases).'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006103)
,p_name=>'P6_INCLUDE_HISTORY'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90006001)
,p_item_default=>'Y'
,p_prompt=>'Include Status History'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Include the full status history for each case in the JSON export. Not applicable for CSV format.'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006104)
,p_name=>'P6_EXPORT_ACTIVE_ONLY'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(90006001)
,p_item_default=>'N'
,p_prompt=>'Export Active Cases Only'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'When enabled, only cases marked as active will be exported.'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006201)
,p_name=>'P6_IMPORT_FILE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90006002)
,p_prompt=>'Select File'
,p_display_as=>'NATIVE_FILE'
,p_cSize=>60
,p_field_template=>1609122147107268652
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Select a JSON file to import. Maximum file size is 10 MB. CSV import coming soon.'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'allow_multiple_files', 'N',
  'max_file_size', '10000',
  'purge_file_at', 'END_OF_SESSION',
  'storage_type', 'APEX_APPLICATION_TEMP_FILES')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006202)
,p_name=>'P6_REPLACE_EXISTING'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90006002)
,p_item_default=>'N'
,p_prompt=>'Replace Existing Cases'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'When enabled, if a case with the same receipt number already exists, it will be replaced with the imported data. Otherwise, duplicates will be skipped.'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006203)
,p_name=>'P6_IMPORT_PREVIEW'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90006002)
,p_prompt=>'Import Preview'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_escape_on_http_output=>'N'
,p_field_template=>1609121967514267634
,p_item_css_classes=>'import-preview'
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006301)
,p_name=>'P6_IMPORT_RESULT'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(90006003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006302)
,p_name=>'P6_IMPORTED_COUNT'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(90006003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006303)
,p_name=>'P6_IMPORT_ERRORS'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(90006003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(90006304)
,p_name=>'P6_IMPORT_RESULT_MSG'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(90006003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(90006501)
,p_validation_name=>'V_FILE_REQUIRED'
,p_validation_sequence=>10
,p_validation=>'P6_IMPORT_FILE'
,p_validation_type=>'ITEM_NOT_NULL'
,p_error_message=>'Please select a file to import.'
,p_validation_condition=>'PREVIEW,IMPORT'
,p_validation_condition_type=>'REQUEST_IN_CONDITION'
,p_associated_item=>wwv_flow_imp.id(90006201)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(90006502)
,p_validation_name=>'V_FILE_SIZE'
,p_validation_sequence=>20
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_file_size NUMBER;',
'BEGIN',
'    SELECT NVL(doc_size, 0)',
'    INTO l_file_size',
'    FROM apex_application_temp_files',
'    WHERE name = :P6_IMPORT_FILE',
'    AND ROWNUM = 1;',
'    ',
'    RETURN l_file_size <= 10485760; -- 10MB in bytes',
'EXCEPTION',
'    WHEN NO_DATA_FOUND THEN',
'        RETURN TRUE;',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_BOOLEAN'
,p_error_message=>'File size exceeds 10 MB limit. Please select a smaller file.'
,p_validation_condition=>'PREVIEW,IMPORT'
,p_validation_condition_type=>'REQUEST_IN_CONDITION'
,p_associated_item=>wwv_flow_imp.id(90006201)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(90006503)
,p_validation_name=>'V_FILE_TYPE'
,p_validation_sequence=>30
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_filename VARCHAR2(400);',
'    l_ext      VARCHAR2(10);',
'BEGIN',
'    SELECT filename',
'    INTO l_filename',
'    FROM apex_application_temp_files',
'    WHERE name = :P6_IMPORT_FILE',
'    AND ROWNUM = 1;',
'    ',
'    l_ext := LOWER(SUBSTR(l_filename, INSTR(l_filename, ''.'', -1)));',
'    RETURN l_ext = ''.json'';',
'EXCEPTION',
'    WHEN NO_DATA_FOUND THEN',
'        RETURN FALSE;',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_BOOLEAN'
,p_error_message=>'Please select a .json file. CSV import is coming soon.'
,p_validation_condition=>'PREVIEW,IMPORT'
,p_validation_condition_type=>'REQUEST_IN_CONDITION'
,p_associated_item=>wwv_flow_imp.id(90006201)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90006701)
,p_name=>'Clear Preview on File Change'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P6_IMPORT_FILE'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006711)
,p_event_id=>wwv_flow_imp.id(90006701)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SET_VALUE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P6_IMPORT_PREVIEW'
,p_attribute_01=>'STATIC_ASSIGNMENT'
,p_attribute_09=>'N'
,p_wait_for_result=>'Y'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006712)
,p_event_id=>wwv_flow_imp.id(90006701)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SET_VALUE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P6_IMPORT_RESULT'
,p_attribute_01=>'STATIC_ASSIGNMENT'
,p_attribute_09=>'N'
,p_wait_for_result=>'Y'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90006702)
,p_name=>'Clear Import Form'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(90006404)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006721)
,p_event_id=>wwv_flow_imp.id(90006702)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'USCIS.ImportExport.clearImportForm();'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90006703)
,p_name=>'Toggle History Option'
,p_event_sequence=>30
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P6_EXPORT_FORMAT'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006731)
,p_event_id=>wwv_flow_imp.id(90006703)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_DISABLE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P6_INCLUDE_HISTORY'
,p_client_condition_type=>'EQUALS'
,p_client_condition_element=>'P6_EXPORT_FORMAT'
,p_client_condition_expression=>'CSV'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006732)
,p_event_id=>wwv_flow_imp.id(90006703)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_ENABLE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P6_INCLUDE_HISTORY'
,p_client_condition_type=>'NOT_EQUALS'
,p_client_condition_element=>'P6_EXPORT_FORMAT'
,p_client_condition_expression=>'CSV'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(90006704)
,p_name=>'Initialize Page JS'
,p_event_sequence=>40
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'ready'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(90006741)
,p_event_id=>wwv_flow_imp.id(90006704)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// Initialize Import/Export module',
'if (typeof USCIS !== "undefined" && USCIS.ImportExport) {',
'    USCIS.ImportExport.init();',
'}'))
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90006602)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Preview Import'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_blob       BLOB;',
'    l_clob       CLOB;',
'    l_filename   VARCHAR2(400);',
'    l_mime_type  VARCHAR2(255);',
'    l_ext        VARCHAR2(10);',
'    l_validation CLOB;',
'    l_case_count NUMBER := 0;',
'    l_preview    VARCHAR2(4000);',
'BEGIN',
'    -- Get uploaded file',
'    SELECT blob_content, filename, mime_type',
'    INTO l_blob, l_filename, l_mime_type',
'    FROM apex_application_temp_files',
'    WHERE name = :P6_IMPORT_FILE',
'    AND ROWNUM = 1;',
'    ',
'    -- Convert BLOB to CLOB',
'    l_clob := uscis_util_pkg.blob_to_clob(l_blob);',
'    ',
'    -- Determine file type',
'    l_ext := LOWER(SUBSTR(l_filename, INSTR(l_filename, ''.'', -1)));',
'    ',
'    IF l_ext = ''.json'' THEN',
'        -- Validate JSON and get case count',
'        l_validation := uscis_export_pkg.validate_import_json(l_clob);',
'        ',
'        IF JSON_VALUE(l_validation, ''$.valid'' RETURNING NUMBER) = 1 THEN',
'            l_case_count := JSON_VALUE(l_validation, ''$.case_count'' RETURNING NUMBER);',
'            l_preview := ''<div class="import-preview--valid">'' ||',
'                ''<span class="t-Icon fa fa-check-circle u-success-text"></span> '' ||',
'                ''<strong>'' || l_case_count || '' case(s)</strong> found in JSON file.'' ||',
'                ''<br><small>File: '' || APEX_ESCAPE.HTML(l_filename) || ''</small>'' ||',
'                ''</div>'';',
'        ELSE',
'            l_preview := ''<div class="import-preview--invalid">'' ||',
'                ''<span class="t-Icon fa fa-exclamation-triangle u-warning-text"></span> '' ||',
'                ''<strong>Invalid JSON format.</strong><br>'' ||',
'                ''<small>'' || APEX_ESCAPE.HTML(JSON_VALUE(l_validation, ''$.error'')) || ''</small>'' ||',
'                ''</div>'';',
'        END IF;',
'    ELSIF l_ext = ''.csv'' THEN',
'        -- Count CSV lines (excluding header)',
'        SELECT COUNT(*) - 1',
'        INTO l_case_count',
'        FROM TABLE(APEX_STRING.SPLIT(l_clob, CHR(10)))',
'        WHERE TRIM(column_value) IS NOT NULL;',
'        ',
'        l_case_count := GREATEST(l_case_count, 0);',
'        ',
'        l_preview := ''<div class="import-preview--valid">'' ||',
'            ''<span class="t-Icon fa fa-check-circle u-success-text"></span> '' ||',
'            ''<strong>'' || l_case_count || '' case(s)</strong> found in CSV file.'' ||',
'            ''<br><small>File: '' || APEX_ESCAPE.HTML(l_filename) || ''</small>'' ||',
'            ''</div>'';',
'    ELSE',
'        l_preview := ''<div class="import-preview--invalid">'' ||',
'            ''<span class="t-Icon fa fa-times-circle u-danger-text"></span> '' ||',
'            ''Unsupported file type: '' || APEX_ESCAPE.HTML(l_ext) ||',
'            ''</div>'';',
'    END IF;',
'    ',
'    :P6_IMPORT_PREVIEW := l_preview;',
'    ',
'EXCEPTION',
'    WHEN NO_DATA_FOUND THEN',
'        :P6_IMPORT_PREVIEW := ''<div class="import-preview--invalid">'' ||',
'            ''<span class="t-Icon fa fa-times-circle u-danger-text"></span> '' ||',
'            ''No file found. Please upload a file.'' ||',
'            ''</div>'';',
'    WHEN OTHERS THEN',
'        -- Log the actual error server-side for debugging',
'        APEX_DEBUG.ERROR(''File preview error: '' || SQLERRM || '' Stack: '' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'        :P6_IMPORT_PREVIEW := ''<div class="import-preview--invalid">'' ||',
'            ''<span class="t-Icon fa fa-times-circle u-danger-text"></span> '' ||',
'            ''An error occurred while reading the file. Please try again or contact support.'' ||',
'            ''</div>'';',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'PREVIEW'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_internal_uid=>90006602
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90006603)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Import Cases'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    l_blob           BLOB;',
'    l_clob           CLOB;',
'    l_filename       VARCHAR2(400);',
'    l_ext            VARCHAR2(10);',
'    l_imported       NUMBER := 0;',
'    l_replace        BOOLEAN;',
'    l_error_log      CLOB;',
'    l_error_count    NUMBER := 0;',
'BEGIN',
'    -- Get uploaded file',
'    SELECT blob_content, filename',
'    INTO l_blob, l_filename',
'    FROM apex_application_temp_files',
'    WHERE name = :P6_IMPORT_FILE',
'    AND ROWNUM = 1;',
'    ',
'    -- Convert BLOB to CLOB',
'    l_clob := uscis_util_pkg.blob_to_clob(l_blob);',
'    ',
'    -- Determine replace mode',
'    l_replace := (:P6_REPLACE_EXISTING = ''Y'');',
'    ',
'    -- Determine file type and import',
'    l_ext := LOWER(SUBSTR(l_filename, INSTR(l_filename, ''.'', -1)));',
'    ',
'    IF l_ext = ''.json'' THEN',
'        l_imported := uscis_export_pkg.import_cases_json(',
'            p_json_data        => l_clob,',
'            p_replace_existing => l_replace',
'        );',
'    ELSE',
'        -- Unsupported file type - JSON only currently supported',
'        RAISE_APPLICATION_ERROR(-20100, ''Only JSON format is currently supported. CSV import coming soon.'');',
'    END IF;',
'    ',
'    -- Set result items',
'    :P6_IMPORTED_COUNT := l_imported;',
'    ',
'    IF l_imported > 0 THEN',
'        :P6_IMPORT_RESULT := ''SUCCESS'';',
'        :P6_IMPORT_RESULT_MSG := ''<strong>'' || l_imported || '' case(s)</strong> imported successfully! '' ||',
'            ''<a href="f?p=&APP_ID.:2:&SESSION.">View Case List</a>'';',
'    ELSE',
'        :P6_IMPORT_RESULT := ''WARNING'';',
'        :P6_IMPORT_RESULT_MSG := ''No cases were imported. The file may be empty or all cases already exist.'';',
'    END IF;',
'    ',
'    -- Clear preview',
'    :P6_IMPORT_PREVIEW := NULL;',
'    ',
'    -- Clean up temp file',
'    DELETE FROM apex_application_temp_files',
'    WHERE name = :P6_IMPORT_FILE;',
'    ',
'    :P6_IMPORT_FILE := NULL;',
'    ',
'    -- Log to audit',
'    uscis_audit_pkg.log_event(',
'        p_event_type => ''IMPORT'',',
'        p_event_data => ''Imported '' || l_imported || '' cases from '' || l_filename',
'    );',
'    ',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        DECLARE',
'            l_error_id VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, ''YYYYMMDDHH24MISSFF3'');',
'        BEGIN',
'            :P6_IMPORT_RESULT := ''FAILED'';',
'            :P6_IMPORT_ERRORS := ''ERR-'' || l_error_id;',
'            :P6_IMPORT_RESULT_MSG := ''<strong>Import failed.</strong> Please contact support with error ID: '' || l_error_id;',
'            ',
'            -- Log full error details server-side for debugging',
'            APEX_DEBUG.ERROR(''Import error ['' || l_error_id || '']: '' || SQLERRM || '' Stack: '' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'            uscis_audit_pkg.log_event(',
'                p_event_type => ''IMPORT_ERROR'',',
'                p_event_data => ''Import failed ['' || l_error_id || '']: '' || SQLERRM',
'            );',
'        END;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'IMPORT'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_internal_uid=>90006603
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90006604)
,p_process_sequence=>40
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Export Cases'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    uscis_export_pkg.download_export(',
'        p_format          => :P6_EXPORT_FORMAT,',
'        p_receipt_filter  => NULLIF(TRIM(:P6_EXPORT_FILTER), ''''),',
'        p_include_history => (:P6_INCLUDE_HISTORY = ''Y''),',
'        p_active_only     => (:P6_EXPORT_ACTIVE_ONLY = ''Y''),',
'        p_filename        => NULL  -- Auto-generate filename',
'    );',
'    ',
'    -- Stop APEX processing since we''re sending a file download',
'    apex_application.stop_apex_engine;',
'    ',
'EXCEPTION',
'    WHEN apex_application.e_stop_apex_engine THEN',
'        -- Normal exit for file download',
'        RAISE;',
'    WHEN OTHERS THEN',
'        -- Log error and show message',
'        uscis_audit_pkg.log_event(',
'            p_event_type => ''EXPORT_ERROR'',',
'            p_event_data => ''Export failed: '' || SQLERRM',
'        );',
'        RAISE;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'BTN_EXPORT'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_internal_uid=>90006604
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(90006601)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Initialize Page'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    -- Clear result items on fresh page load (not a button submit)',
'    IF :REQUEST IS NULL THEN',
'        :P6_IMPORT_RESULT := NULL;',
'        :P6_IMPORTED_COUNT := NULL;',
'        :P6_IMPORT_ERRORS := NULL;',
'        :P6_IMPORT_RESULT_MSG := NULL;',
'        :P6_IMPORT_PREVIEW := NULL;',
'    END IF;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>90006601
);
wwv_flow_imp.component_end;
end;
/
