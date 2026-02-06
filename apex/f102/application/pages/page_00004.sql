prompt --application/pages/page_00004
begin
--   Manifest
--     PAGE: 00004
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
 p_id=>4
,p_name=>'Add Case'
,p_alias=>'ADD-CASE'
,p_page_mode=>'MODAL'
,p_step_title=>'Add Case'
,p_autocomplete_on_off=>'OFF'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'.receipt-input {',
'  font-family: "Courier New", monospace;',
'  letter-spacing: 1px;',
'  text-transform: uppercase;',
'}'))
,p_page_template_options=>'#DEFAULT#'
,p_dialog_height=>'auto'
,p_dialog_width=>'500'
,p_protection_level=>'C'
,p_page_component_map=>'16'
);
-- Main Form Region
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13200001000000001)
,p_plug_name=>'Add Case'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>10
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'Y')).to_clob
);
-- Receipt Number Input
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13200020000000020)
,p_name=>'P4_RECEIPT_NUMBER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_prompt=>'Receipt Number'
,p_placeholder=>'e.g., IOE1234567890'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>20
,p_cMaxlength=>13
,p_field_template=>1609121967514267634
,p_item_css_classes=>'receipt-input'
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Enter the 13-character receipt number from your USCIS notice'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'send_on_page_submit', 'Y',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
-- Personal Notes
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13200070000000070)
,p_name=>'P4_NOTES'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_prompt=>'Personal Notes'
,p_placeholder=>'Add any personal notes about this case...'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cSize=>60
,p_cMaxlength=>4000
,p_cHeight=>2
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'auto_height', 'N',
  'character_counter', 'N',
  'resizable', 'Y',
  'trim_spaces', 'BOTH')).to_clob
);
-- Fetch From USCIS Switch
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13200030000000030)
,p_name=>'P4_FETCH_FROM_USCIS'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_item_default=>'Y'
,p_prompt=>'Fetch status from USCIS'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'When enabled, we will automatically check the USCIS system for the current case status'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'off_value', 'N',
  'on_value', 'Y',
  'use_defaults', 'N')).to_clob
);
-- Case Type Select List
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13200040000000040)
,p_name=>'P4_CASE_TYPE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_prompt=>'Case Type'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:I-130;I-130,I-140;I-140,I-485;I-485,I-539;I-539,I-765;I-765,I-821D;I-821D,N-400;N-400,Other;Other'
,p_lov_display_null=>'YES'
,p_lov_null_text=>'- Select Case Type -'
,p_cHeight=>1
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
);
-- Cancel Button
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13200100000000100)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_button_name=>'CANCEL'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Cancel'
,p_button_position=>'NEXT'
,p_warn_on_unsaved_changes=>null
);
-- Save Button
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13200110000000110)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(13200001000000001)
,p_button_name=>'SAVE'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Add Case'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-plus'
);
-- Receipt Number Required Validation
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(13200200000000200)
,p_validation_name=>'V_RECEIPT_REQUIRED'
,p_validation_sequence=>10
,p_validation=>'P4_RECEIPT_NUMBER'
,p_validation_type=>'ITEM_NOT_NULL'
,p_error_message=>'Receipt Number is required.'
,p_associated_item=>wwv_flow_imp.id(13200020000000020)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
-- Receipt Number Format Validation
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(13200210000000210)
,p_validation_name=>'V_RECEIPT_FORMAT'
,p_validation_sequence=>20
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_normalized VARCHAR2(13);',
'BEGIN',
'  BEGIN',
'    l_normalized := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);',
'  EXCEPTION',
'    WHEN OTHERS THEN',
'      l_normalized := :P4_RECEIPT_NUMBER;',
'  END;',
'  IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN',
'    RETURN FALSE;',
'  END IF;',
'  RETURN TRUE;',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_BOOLEAN'
,p_error_message=>'Invalid receipt number format. Expected: 3 letters + 10 digits (e.g., IOE1234567890)'
,p_validation_condition=>'P4_RECEIPT_NUMBER'
,p_validation_condition_type=>'ITEM_IS_NOT_NULL'
,p_associated_item=>wwv_flow_imp.id(13200020000000020)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
-- Case Already Exists Validation
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(13200220000000220)
,p_validation_name=>'V_CASE_NOT_EXISTS'
,p_validation_sequence=>30
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_normalized VARCHAR2(13);',
'  l_count      NUMBER;',
'BEGIN',
'  BEGIN',
'    l_normalized := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);',
'  EXCEPTION',
'    WHEN OTHERS THEN',
'      l_normalized := :P4_RECEIPT_NUMBER;',
'  END;',
'  SELECT COUNT(*) INTO l_count',
'  FROM case_history',
'  WHERE receipt_number = l_normalized;',
'  RETURN l_count = 0;',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_BOOLEAN'
,p_error_message=>'This case is already being tracked.'
,p_validation_condition=>'P4_RECEIPT_NUMBER'
,p_validation_condition_type=>'ITEM_IS_NOT_NULL'
,p_associated_item=>wwv_flow_imp.id(13200020000000020)
,p_error_display_location=>'INLINE_WITH_FIELD'
);
-- Add Case Process
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13200310000000310)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Add Case'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_receipt   VARCHAR2(13);',
'  l_case_type VARCHAR2(100);',
'  l_status    VARCHAR2(500);',
'  l_norm_failed BOOLEAN := FALSE;',
'BEGIN',
'  -- Normalize receipt number via package, fallback to local logic',
'  BEGIN',
'    l_receipt := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);',
'  EXCEPTION',
'    WHEN OTHERS THEN',
'      -- Log the error with context',
'      apex_debug.error(',
'        p_message => ''normalize_receipt_number failed for input [%s]: %s'',',
'        p0 => :P4_RECEIPT_NUMBER,',
'        p1 => SQLERRM',
'      );',
'      -- Fallback to local normalization',
'      l_receipt := UPPER(REGEXP_REPLACE(:P4_RECEIPT_NUMBER, ''[^A-Za-z0-9]'', ''''));',
'      l_norm_failed := TRUE;',
'  END;',
'  ',
'  -- Log if normalization fell back to local logic',
'  IF l_norm_failed THEN',
'    apex_debug.info(',
'      p_message => ''normalize_receipt_number fell back to local logic for input [%s]'',',
'      p0 => :P4_RECEIPT_NUMBER',
'    );',
'  END IF;',
'  ',
'  -- Validate normalized receipt number',
'  IF l_receipt IS NULL OR LENGTH(l_receipt) != 13 THEN',
'    apex_error.add_error(',
'      p_message => ''Unable to normalize receipt number. Please verify the format.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'  END IF;',
'  ',
'  -- Determine case type and status based on fetch preference',
'  IF NVL(:P4_FETCH_FROM_USCIS, ''N'') = ''Y'' THEN',
'    l_case_type := ''Checking...'';',
'    l_status := ''Checking Status...'';',
'  ELSE',
'    l_case_type := NVL(:P4_CASE_TYPE, ''Unknown'');',
'    l_status := ''Case Received'';',
'  END IF;',
'  ',
'  -- Insert into case_history (master table)',
'  INSERT INTO case_history (',
'    receipt_number,',
'    notes,',
'    created_by',
'  ) VALUES (',
'    l_receipt,',
'    :P4_NOTES,',
'    :APP_USER',
'  );',
'  ',
'  -- Insert initial status into status_updates',
'  INSERT INTO status_updates (',
'    receipt_number,',
'    case_type,',
'    current_status,',
'    last_updated,',
'    source',
'  ) VALUES (',
'    l_receipt,',
'    l_case_type,',
'    l_status,',
'    SYSTIMESTAMP,',
'    ''MANUAL''',
'  );',
'  ',
'  :P4_RECEIPT_NUMBER := l_receipt;',
'EXCEPTION',
'  WHEN OTHERS THEN',
'    apex_debug.error(',
'      p_message => ''Add Case process failed for receipt [%s]: %s'',',
'      p0 => l_receipt,',
'      p1 => SQLERRM',
'    );',
'    apex_error.add_error(',
'      p_message => ''An error occurred while adding the case. Please try again.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RETURN;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(13200110000000110)
);
-- Close Dialog Process  
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13200330000000330)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Close Dialog'
,p_process_sql_clob=>'apex_application.g_print_success_message := ''Case added successfully.'';'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_imp.id(13200110000000110)
);
-- Branch to close dialog
wwv_flow_imp_page.create_page_branch(
 p_id=>wwv_flow_imp.id(13200340000000340)
,p_branch_name=>'Go To Page 22'
,p_branch_action=>'f?p=&APP_ID.:22:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
-- Cancel Button Dynamic Action - Close Dialog
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13200600000000600)
,p_name=>'Cancel Dialog'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(13200100000000100)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13200610000000610)
,p_event_id=>wwv_flow_imp.id(13200600000000600)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_DIALOG_CANCEL'
);
-- Toggle Case Type visibility based on Fetch switch
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13200500000000500)
,p_name=>'Toggle Case Type'
,p_event_sequence=>20
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P4_FETCH_FROM_USCIS'
,p_condition_element=>'P4_FETCH_FROM_USCIS'
,p_triggering_condition_type=>'EQUALS'
,p_triggering_expression=>'N'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13200510000000510)
,p_event_id=>wwv_flow_imp.id(13200500000000500)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P4_CASE_TYPE'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13200520000000520)
,p_event_id=>wwv_flow_imp.id(13200500000000500)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_HIDE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P4_CASE_TYPE'
);
-- Format Receipt Number on Blur (uppercase)
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13200700000000700)
,p_name=>'Format Receipt Number'
,p_event_sequence=>30
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P4_RECEIPT_NUMBER'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'focusout'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13200710000000710)
,p_event_id=>wwv_flow_imp.id(13200700000000700)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'var v=apex.item("P4_RECEIPT_NUMBER").getValue();if(v)apex.item("P4_RECEIPT_NUMBER").setValue(v.toUpperCase().replace(/[^A-Z0-9]/g,""));'
);
wwv_flow_imp.component_end;
end;
/
