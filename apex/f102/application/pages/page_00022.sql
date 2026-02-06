prompt --application/pages/page_00022
begin
--   Manifest
--     PAGE: 00022
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
 p_id=>22
,p_name=>'My Cases'
,p_alias=>'CASES'
,p_step_title=>'My Cases'
,p_autocomplete_on_off=>'OFF'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Page 22 inline styles (UT-compliant) */',
'.receipt-number {',
'  font-family: "Courier New", monospace;',
'  font-weight: bold;',
'  letter-spacing: 1px;',
'}',
'.receipt-link {',
'  font-family: "Courier New", monospace;',
'  font-weight: bold;',
'  letter-spacing: 1px;',
'  color: #0071bc;',
'  text-decoration: none;',
'}',
'.receipt-link:hover {',
'  text-decoration: underline;',
'  color: #003366;',
'}',
'.ig-row-inactive {',
'  opacity: 0.6;',
'  background-color: #f0f0f0 !important;',
'}',
'.case-list-toolbar .a-Button--hot {',
'  margin-left: 8px;',
'}',
'.case-filters {',
'  padding: 12px 16px;',
'  background: #f5f5f5;',
'  border-bottom: 1px solid #e0e0e0;',
'  display: flex;',
'  gap: 16px;',
'  flex-wrap: wrap;',
'  align-items: flex-end;',
'}',
'.case-filters .t-Form-fieldContainer {',
'  margin-bottom: 0;',
'}',
'.a-GV-row.is-selected .a-GV-cell,',
'.a-GV-row.is-active .a-GV-cell,',
'.a-GV-row.is-focused .a-GV-cell {',
'  background-color: #e8f0fe !important;',
'  color: #1a1a1a !important;',
'}',
'.a-GV-row.is-selected .receipt-link,',
'.a-GV-row.is-active .receipt-link {',
'  color: #003d99 !important;',
'}',
'.a-IG .is-changed .a-GV-cell {',
'  background-color: #fffde7 !important;',
'}',
'.a-IG-button--save {',
'  margin-left: 8px;',
'}'))
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'21'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13088000000253650)
,p_plug_name=>'Filters'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4501440665235496320
,p_plug_display_sequence=>20
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'TEXT',
  'show_line_breaks', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13088035678253657)
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
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13088711960253661)
,p_plug_name=>'Case List'
,p_region_name=>'case_list_ig'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2100526641005906379
,p_plug_display_sequence=>40
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'WITH base AS (',
'  SELECT ',
'      ch.ROWID AS row_id,',
'      v.receipt_number,',
'      v.case_type,',
'      APEX_ESCAPE.HTML(v.current_status) AS current_status,',
'      v.last_updated,',
'      v.tracking_since,',
'      ch.is_active,',
'      ch.notes,',
'      v.total_updates,',
'      v.last_update_source,',
'      v.check_frequency,',
'      v.last_checked_at,',
'      v.created_by,',
'      v.days_since_update,',
'      NVL(TO_CHAR(v.hours_since_check) || '' hrs ago'', ''Never'') AS last_check_display,',
'      CASE',
'        WHEN v.current_status IS NULL THEN ''unknown''',
'        WHEN UPPER(v.current_status) LIKE ''%NOT APPROVED%''',
'          OR UPPER(v.current_status) LIKE ''%DENIED%''',
'          OR UPPER(v.current_status) LIKE ''%REJECT%''',
'          OR UPPER(v.current_status) LIKE ''%TERMINAT%''',
'          OR UPPER(v.current_status) LIKE ''%WITHDRAWN%''',
'          OR UPPER(v.current_status) LIKE ''%REVOKED%'' THEN ''denied''',
'        WHEN UPPER(v.current_status) LIKE ''%APPROVED%''',
'          OR UPPER(v.current_status) LIKE ''%CARD WAS PRODUCED%''',
'          OR UPPER(v.current_status) LIKE ''%CARD IS BEING PRODUCED%''',
'          OR UPPER(v.current_status) LIKE ''%CARD WAS DELIVERED%''',
'          OR UPPER(v.current_status) LIKE ''%CARD WAS MAILED%''',
'          OR UPPER(v.current_status) LIKE ''%CARD WAS PICKED UP%''',
'          OR UPPER(v.current_status) LIKE ''%OATH CEREMONY%''',
'          OR UPPER(v.current_status) LIKE ''%WELCOME NOTICE%'' THEN ''approved''',
'        WHEN UPPER(v.current_status) LIKE ''%EVIDENCE%''',
'          OR UPPER(v.current_status) LIKE ''%RFE%'' THEN ''rfe''',
'        WHEN UPPER(v.current_status) LIKE ''%RECEIVED%''',
'          OR UPPER(v.current_status) LIKE ''%ACCEPTED%''',
'          OR UPPER(v.current_status) LIKE ''%FEE WAS%'' THEN ''received''',
'        WHEN UPPER(v.current_status) LIKE ''%FINGERPRINT%''',
'          OR UPPER(v.current_status) LIKE ''%INTERVIEW%''',
'          OR UPPER(v.current_status) LIKE ''%PROCESSING%''',
'          OR UPPER(v.current_status) LIKE ''%REVIEW%''',
'          OR UPPER(v.current_status) LIKE ''%PENDING%''',
'          OR UPPER(v.current_status) LIKE ''%SCHEDULED%'' THEN ''pending''',
'        WHEN UPPER(v.current_status) LIKE ''%TRANSFER%''',
'          OR UPPER(v.current_status) LIKE ''%RELOCATED%''',
'          OR UPPER(v.current_status) LIKE ''%SENT TO%'' THEN ''transferred''',
'        ELSE ''unknown''',
'      END AS status_category',
'  FROM v_case_current_status v',
'  JOIN case_history ch ON ch.receipt_number = v.receipt_number',
'  WHERE (NVL(:P22_ACTIVE_FILTER, ''ALL'') = ''ALL'' ',
'         OR (NVL(:P22_ACTIVE_FILTER, ''ALL'') = ''ACTIVE'' AND ch.is_active = 1)',
'         OR (NVL(:P22_ACTIVE_FILTER, ''ALL'') = ''INACTIVE'' AND ch.is_active = 0))',
'    AND (NVL(:P22_STATUS_FILTER, ''ALL'') = ''ALL'' OR v.current_status = :P22_STATUS_FILTER)',
'    AND (:P22_RECEIPT_SEARCH IS NULL OR UPPER(v.receipt_number) LIKE ''%'' || UPPER(:P22_RECEIPT_SEARCH) || ''%'')',
')',
'SELECT ',
'    b.row_id,',
'    b.receipt_number,',
'    b.case_type,',
'    b.current_status,',
'    b.last_updated,',
'    b.tracking_since,',
'    b.is_active,',
'    b.notes,',
'    b.total_updates,',
'    b.last_update_source,',
'    b.check_frequency,',
'    b.last_checked_at,',
'    b.created_by,',
'    b.days_since_update,',
'    b.last_check_display,',
'    b.status_category,',
'    CASE b.status_category',
'      WHEN ''approved''    THEN ''u-success''',
'      WHEN ''denied''      THEN ''u-danger''',
'      WHEN ''rfe''         THEN ''u-info''',
'      WHEN ''received''    THEN ''u-color-14''',
'      WHEN ''pending''     THEN ''u-warning''',
'      WHEN ''transferred'' THEN ''u-color-16''',
'      ELSE ''u-color-7''',
'    END AS status_ut_class,',
'    APEX_PAGE.GET_URL(p_page => 3, p_items => ''P3_RECEIPT_NUMBER'', p_values => b.receipt_number) AS detail_url',
'FROM base b',
'ORDER BY b.last_updated DESC NULLS LAST'))
,p_plug_source_type=>'NATIVE_IG'
,p_prn_page_header=>'My Cases'
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13090010413253679)
,p_name=>'RECEIPT_NUMBER'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'RECEIPT_NUMBER'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HTML_EXPRESSION'
,p_heading=>'Receipt #'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>10
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'html_expression', '<a href="&DETAIL_URL." class="receipt-link">&RECEIPT_NUMBER.</a>')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>true
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>false
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>false
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13091043908253686)
,p_name=>'CASE_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'CASE_TYPE'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Form Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>20
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13092016549253690)
,p_name=>'CURRENT_STATUS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'CURRENT_STATUS'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HTML_EXPRESSION'
,p_heading=>'Status'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>30
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'html_expression', '<span class="u-pill &STATUS_UT_CLASS."><span class="u-pill-label">&CURRENT_STATUS.</span></span>')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13093032096253693)
,p_name=>'LAST_UPDATED'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LAST_UPDATED'
,p_data_type=>'TIMESTAMP'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Last Updated'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>40
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_format_mask=>'SINCE'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_date_ranges=>'ALL'
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13093949710253697)
,p_name=>'TRACKING_SINCE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TRACKING_SINCE'
,p_data_type=>'TIMESTAMP'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Tracking Since'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>50
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_format_mask=>'SINCE'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_date_ranges=>'ALL'
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13094948530253700)
,p_name=>'IS_ACTIVE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IS_ACTIVE'
,p_data_type=>'NUMBER'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_YES_NO'
,p_heading=>'Active'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>60
,p_value_alignment=>'CENTER'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'off_value', '0',
  'on_value', '1',
  'use_defaults', 'N')).to_clob
,p_is_required=>true
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13095962807253704)
,p_name=>'NOTES'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'NOTES'
,p_data_type=>'CLOB'
,p_session_state_data_type=>'CLOB'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXTAREA'
,p_heading=>'Notes'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>70
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'auto_height', 'Y',
  'character_counter', 'Y',
  'max_characters', '4000',
  'resizable', 'Y',
  'trim_spaces', 'BOTH')).to_clob
,p_is_required=>false
,p_max_length=>4000
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13096988465253707)
,p_name=>'TOTAL_UPDATES'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TOTAL_UPDATES'
,p_data_type=>'NUMBER'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Updates'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>80
,p_value_alignment=>'CENTER'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13097993885253711)
,p_name=>'LAST_UPDATE_SOURCE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LAST_UPDATE_SOURCE'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Source'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>90
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13098979713253714)
,p_name=>'CHECK_FREQUENCY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'CHECK_FREQUENCY'
,p_data_type=>'NUMBER'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Check Freq (hrs)'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>100
,p_value_alignment=>'CENTER'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13099945765253718)
,p_name=>'LAST_CHECKED_AT'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LAST_CHECKED_AT'
,p_data_type=>'TIMESTAMP'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Last Checked'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>110
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_format_mask=>'SINCE'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_date_ranges=>'ALL'
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13100912685253721)
,p_name=>'CREATED_BY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'CREATED_BY'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Created By'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>120
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13101976099253725)
,p_name=>'DAYS_SINCE_UPDATE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DAYS_SINCE_UPDATE'
,p_data_type=>'NUMBER'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Days Since Update'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>130
,p_value_alignment=>'CENTER'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13102991952253729)
,p_name=>'LAST_CHECK_DISPLAY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LAST_CHECK_DISPLAY'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Last Check'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>140
,p_value_alignment=>'LEFT'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'based_on', 'VALUE',
  'format', 'PLAIN')).to_clob
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13103985039253732)
,p_name=>'STATUS_CATEGORY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'STATUS_CATEGORY'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>150
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_include_in_export=>false
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13103985039253734)
,p_name=>'STATUS_UT_CLASS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'STATUS_UT_CLASS'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>155
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_include_in_export=>false
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13103985039253733)
,p_name=>'DETAIL_URL'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DETAIL_URL'
,p_data_type=>'VARCHAR2'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>160
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'N')).to_clob
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_include_in_export=>false
);
wwv_flow_imp_page.create_region_column(
 p_id=>wwv_flow_imp.id(13106000000253740)
,p_name=>'ROW_ID'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'ROW_ID'
,p_data_type=>'ROWID'
,p_session_state_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>5
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
,p_use_as_row_header=>false
,p_is_primary_key=>true
,p_duplicate_value=>false
,p_include_in_export=>false
);
wwv_flow_imp_page.create_interactive_grid(
 p_id=>wwv_flow_imp.id(13089201375253664)
,p_internal_uid=>13089201375253664
,p_is_editable=>true
,p_edit_operations=>'u:d'
,p_lost_update_check_type=>'VALUES'
,p_submit_checked_rows=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_select_first_row=>true
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>true
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SAVE:RESET'
,p_enable_save_public_report=>false
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>true
,p_download_formats=>'CSV:HTML:XLSX'
,p_enable_mail_download=>true
,p_fixed_header=>'PAGE'
,p_show_icon_view=>false
,p_show_detail_view=>false
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function(config) {',
'    // Add row class based on is_active status',
'    config.defaultGridViewOptions = {',
'        rowHeader: "sequence"',
'    };',
'    config.initActions = function(actions) {',
'        // Custom action: View Details',
'        actions.add({',
'            name: "view-details",',
'            label: "View Details",',
'            icon: "fa fa-eye",',
'            action: function(event, element, args) {',
'                var model = this.model;',
'                var url;',
'                if (model && args.selectedRecords && args.selectedRecords.length > 0) {',
'                    url = model.getValue(args.selectedRecords[0], "DETAIL_URL");',
'                }',
'                if (url) {',
'                    apex.navigation.redirect(url);',
'                }',
'            }',
'        });',
'        // Custom action: Refresh case status',
'        actions.add({',
'            name: "refresh-case",',
'            label: "Refresh Status",',
'            icon: "fa fa-refresh",',
'            action: function(event, element, args) {',
'                var model = this.model;',
'                var receipt;',
'                if (model && args.selectedRecords && args.selectedRecords.length > 0) {',
'                    receipt = model.getValue(args.selectedRecords[0], "RECEIPT_NUMBER");',
'                }',
'                if (receipt) {',
'                    apex.server.process("REFRESH_CASE_STATUS", {',
'                        x01: receipt',
'                    }, {',
'                        success: function(data) {',
'                            if (data.success) {',
'                                apex.message.showPageSuccess("Status refreshed: " + data.status);',
'                                apex.region("case_list_ig").refresh();',
'                            } else {',
'                                apex.message.alert(data.message || "Failed to refresh status.");',
'                            }',
'                        },',
'                        error: function() {',
'                            apex.message.alert("An error occurred. Please try again.");',
'                        }',
'                    });',
'                }',
'            }',
'        });',
'        // Custom action: Delete case',
'        actions.add({',
'            name: "delete-case",',
'            label: "Delete Case",',
'            icon: "fa fa-trash-o u-danger-text",',
'            action: function(event, element, args) {',
'                var model = this.model;',
'                var receipt;',
'                if (model && args.selectedRecords && args.selectedRecords.length > 0) {',
'                    receipt = model.getValue(args.selectedRecords[0], "RECEIPT_NUMBER");',
'                }',
'                if (receipt) {',
'                    apex.message.confirm("Are you sure you want to delete case " + receipt + "?", function(ok) {',
'                        if (ok) {',
'                            apex.item("P22_SELECTED_RECEIPT").setValue(receipt);',
'                            apex.page.submit({request: "DELETE_CASE", showWait: true});',
'                        }',
'                    });',
'                }',
'            }',
'        });',
'    };',
'    return config;',
'}'))
);
wwv_flow_imp_page.create_ig_report(
 p_id=>wwv_flow_imp.id(13089640352253668)
,p_interactive_grid_id=>wwv_flow_imp.id(13089201375253664)
,p_static_id=>'130897'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_imp_page.create_ig_report_view(
 p_id=>wwv_flow_imp.id(13089822797253670)
,p_report_id=>wwv_flow_imp.id(13089640352253668)
,p_view_type=>'GRID'
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13090446580253682)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>1
,p_column_id=>wwv_flow_imp.id(13090010413253679)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13091477071253687)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>2
,p_column_id=>wwv_flow_imp.id(13091043908253686)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13092469770253691)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>3
,p_column_id=>wwv_flow_imp.id(13092016549253690)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13093354228253694)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>4
,p_column_id=>wwv_flow_imp.id(13093032096253693)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13094315927253698)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>5
,p_column_id=>wwv_flow_imp.id(13093949710253697)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13095344280253701)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>6
,p_column_id=>wwv_flow_imp.id(13094948530253700)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13096351197253705)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>7
,p_column_id=>wwv_flow_imp.id(13095962807253704)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13097336971253709)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>8
,p_column_id=>wwv_flow_imp.id(13096988465253707)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13098307522253712)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>9
,p_column_id=>wwv_flow_imp.id(13097993885253711)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13099337303253716)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>10
,p_column_id=>wwv_flow_imp.id(13098979713253714)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13100370671253719)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>11
,p_column_id=>wwv_flow_imp.id(13099945765253718)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13101314307253723)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>12
,p_column_id=>wwv_flow_imp.id(13100912685253721)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13102342710253726)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>13
,p_column_id=>wwv_flow_imp.id(13101976099253725)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13103392903253730)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>14
,p_column_id=>wwv_flow_imp.id(13102991952253729)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13104346763253733)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>15
,p_column_id=>wwv_flow_imp.id(13103985039253732)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_ig_report_column(
 p_id=>wwv_flow_imp.id(13106100000253741)
,p_view_id=>wwv_flow_imp.id(13089822797253670)
,p_display_seq=>0
,p_column_id=>wwv_flow_imp.id(13106000000253740)
,p_is_visible=>false
,p_is_frozen=>false
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13107600000471606)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_button_name=>'ADD_CASE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Add Case'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:4:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-plus'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13107700000471607)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_button_name=>'APPLY_FILTER'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Apply Filter'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-filter'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13107800000471608)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_button_name=>'EXPORT'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Export'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:6:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-download'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13107208091471602)
,p_name=>'P22_STATUS_FILTER'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_prompt=>'Status'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT DISTINCT current_status AS d, current_status AS r',
'      FROM v_case_current_status',
'      WHERE current_status IS NOT NULL',
'      ORDER BY 1'))
,p_lov_display_null=>'YES'
,p_lov_null_text=>'- All Statuses -'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13107338626471603)
,p_name=>'P22_RECEIPT_SEARCH'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_prompt=>'Search Receipt'
,p_placeholder=>'Enter receipt number...'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>20
,p_begin_on_new_line=>'N'
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'Y',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13107460361471604)
,p_name=>'P22_ACTIVE_FILTER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(13088000000253650)
,p_item_default=>'ACTIVE'
,p_prompt=>'Filter by Status'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:All Cases;ALL,Active Only;ACTIVE,Inactive Only;INACTIVE'
,p_cHeight=>1
,p_field_template=>1609121967514267634
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(13107500000471605)
,p_name=>'P22_SELECTED_RECEIPT'
,p_item_sequence=>40
,p_display_as=>'NATIVE_HIDDEN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13108000000471610)
,p_name=>'Refresh Grid on Filter Change'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P22_ACTIVE_FILTER,P22_STATUS_FILTER'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13108100000471611)
,p_event_id=>wwv_flow_imp.id(13108000000471610)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_REFRESH'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_imp.id(13088711960253661)
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(13108300000471613)
,p_name=>'Refresh Grid on Dialog Close'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(13107600000471606)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'apexafterclosedialog'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(13108400000471614)
,p_event_id=>wwv_flow_imp.id(13108300000471613)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_REFRESH'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_imp.id(13088711960253661)
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13108500000471615)
,p_process_sequence=>5
,p_process_point=>'AFTER_SUBMIT'
,p_region_id=>wwv_flow_imp.id(13088711960253661)
,p_process_type=>'NATIVE_IG_DML'
,p_process_name=>'Save IG Changes'
,p_attribute_01=>'REGION_SOURCE'
,p_attribute_05=>'Y'
,p_attribute_06=>'Y'
,p_attribute_08=>'Y'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>13108500000471615
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13108600000471616)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Delete Case'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'  IF :P22_SELECTED_RECEIPT IS NOT NULL THEN',
'    -- Use bind variable only (never substitution strings)',
'    uscis_case_pkg.delete_case(',
'      p_receipt_number => :P22_SELECTED_RECEIPT',
'    );',
'    ',
'    -- Log deletion audit',
'    apex_debug.info(',
'      p_message => ''Case deleted by user %s: %s'',',
'      p0 => :APP_USER,',
'      p1 => uscis_util_pkg.mask_receipt_number(:P22_SELECTED_RECEIPT)',
'    );',
'  END IF;',
'EXCEPTION',
'  WHEN OTHERS THEN',
'    apex_debug.error(''Delete Case error: '' || SQLERRM);',
'    apex_error.add_error(',
'      p_message => ''An error occurred while deleting the case. Please try again.'',',
'      p_display_location => apex_error.c_inline_in_notification',
'    );',
'    RAISE;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'DELETE_CASE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_internal_uid=>13108600000471616
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(13108200000471612)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'REFRESH_CASE_STATUS'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_receipt_number VARCHAR2(13);',
'  l_status         uscis_types_pkg.t_case_status;',
'BEGIN',
'  -- Get receipt number from AJAX parameter',
'  l_receipt_number := APEX_APPLICATION.G_X01;',
'  ',
'  -- Validate format',
'  IF l_receipt_number IS NULL OR NOT REGEXP_LIKE(l_receipt_number, ''^[A-Z]{3}[0-9]{10}$'') THEN',
'    APEX_JSON.OPEN_OBJECT;',
'    APEX_JSON.WRITE(''success'', FALSE);',
'    APEX_JSON.WRITE(''message'', ''Invalid receipt number format'');',
'    APEX_JSON.CLOSE_OBJECT;',
'    RETURN;',
'  END IF;',
'  ',
'  BEGIN',
'    -- Call API to check status',
'    l_status := uscis_api_pkg.check_case_status(',
'      p_receipt_number   => l_receipt_number,',
'      p_save_to_database => TRUE',
'    );',
'    ',
'    -- Return success response',
'    APEX_JSON.OPEN_OBJECT;',
'    APEX_JSON.WRITE(''success'', TRUE);',
'    APEX_JSON.WRITE(''message'', ''Status refreshed successfully'');',
'    APEX_JSON.WRITE(''status'', l_status.current_status);',
'    APEX_JSON.WRITE(''caseType'', l_status.case_type);',
'    APEX_JSON.CLOSE_OBJECT;',
'    ',
'    -- Note: APEX manages transactions; do not explicitly COMMIT',
'  EXCEPTION',
'    WHEN OTHERS THEN',
'      ROLLBACK;',
'      -- Log full error details server-side including stack trace',
'      APEX_DEBUG.ERROR(''REFRESH_CASE_STATUS error: '' || SQLERRM || '' Stack: '' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);',
'      APEX_JSON.OPEN_OBJECT;',
'      APEX_JSON.WRITE(''success'', FALSE);',
'      APEX_JSON.WRITE(''message'', ''Failed to refresh case status. Please try again.'');',
'      APEX_JSON.CLOSE_OBJECT;',
'      -- Do not RAISE; let the JSON response be the final output',
'  END;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>13108200000471612
);
wwv_flow_imp.component_end;
end;
/
