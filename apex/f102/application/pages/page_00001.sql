prompt --application/pages/page_00001
begin
--   Manifest
--     PAGE: 00001
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
 p_id=>1
,p_name=>'Home'
,p_alias=>'HOME'
,p_step_title=>'USCIS Case Tracker'
,p_autocomplete_on_off=>'OFF'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Dashboard Cards */',
'.dash-card { text-align: center; padding: 16px 8px; }',
'.dash-card .card-value { font-size: 32px; font-weight: 700; line-height: 1.2; }',
'.dash-card .card-label { font-size: 13px; color: #666; margin-top: 4px; }',
'.dash-card .card-sub { font-size: 11px; color: #999; margin-top: 2px; }',
'.dash-card a.card-value { text-decoration: none; }',
'.dash-card a.card-value:hover { opacity: 0.8; }',
'/* Activity list */',
'.activity-item { padding: 8px 0; border-bottom: 1px solid #f0f0f0; }',
'.activity-item:last-child { border-bottom: none; }',
'.activity-time { font-size: 11px; color: #999; }',
'.activity-desc { font-size: 13px; color: #333; }'))
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'16'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13001001000000101)
,p_plug_name=>'Summary Cards'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>20
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_total       NUMBER := 0;',
'  l_active      NUMBER := 0;',
'  l_today       NUMBER := 0;',
'  l_stale       NUMBER := 0;',
'  l_html        VARCHAR2(32767);',
'BEGIN',
'  -- Total cases',
'  SELECT COUNT(*) INTO l_total FROM case_history;',
'  -- Active cases',
'  SELECT COUNT(*) INTO l_active FROM case_history WHERE is_active = 1;',
'  -- Updated today',
'  BEGIN',
'    SELECT COUNT(*) INTO l_today',
'    FROM status_updates',
'    WHERE created_at >= TRUNC(SYSDATE)',
'      AND created_at <  TRUNC(SYSDATE) + 1;',
'  EXCEPTION WHEN OTHERS THEN l_today := 0;',
'  END;',
'  -- Stale (not checked in 7+ days)',
'  SELECT COUNT(*) INTO l_stale',
'  FROM case_history',
'  WHERE is_active = 1',
'    AND (last_checked_at < SYSDATE - 7 OR last_checked_at IS NULL);',
'',
'  l_html := ''<div class="row">'';',
'  -- Card 1: Total',
'  l_html := l_html',
'    || ''<div class="col col-3">''',
'    || ''<div class="dash-card"><span class="t-Icon fa fa-briefcase u-color-1-text" style="font-size:24px"></span>''',
'    || ''<div class="card-value">'' || l_total || ''</div>''',
'    || ''<div class="card-label">Total Cases</div>''',
'    || ''<div class="card-sub">All tracked cases</div>''',
'    || ''</div></div>'';',
'  -- Card 2: Active',
'  l_html := l_html',
'    || ''<div class="col col-3">''',
'    || ''<div class="dash-card"><span class="t-Icon fa fa-check-circle u-success-text" style="font-size:24px"></span>''',
'    || ''<div class="card-value">'' || l_active || ''</div>''',
'    || ''<div class="card-label">Active Cases</div>''',
'    || ''<div class="card-sub">Currently monitoring</div>''',
'    || ''</div></div>'';',
'  -- Card 3: Updated Today',
'  l_html := l_html',
'    || ''<div class="col col-3">''',
'    || ''<div class="dash-card"><span class="t-Icon fa fa-bell u-warning-text" style="font-size:24px"></span>''',
'    || ''<div class="card-value">'' || l_today || ''</div>''',
'    || ''<div class="card-label">Updated Today</div>''',
'    || ''<div class="card-sub">Recent status changes</div>''',
'    || ''</div></div>'';',
'  -- Card 4: Pending Check',
'  l_html := l_html',
'    || ''<div class="col col-3">''',
'    || ''<div class="dash-card"><span class="t-Icon fa fa-clock-o u-info-text" style="font-size:24px"></span>''',
'    || ''<div class="card-value">'' || l_stale || ''</div>''',
'    || ''<div class="card-label">Pending Check</div>''',
'    || ''<div class="card-sub">Not checked in 7+ days</div>''',
'    || ''</div></div>'';',
'  l_html := l_html || ''</div>'';',
'',
'  htp.p(l_html);',
'END;'))
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13001002000000102)
,p_plug_name=>'Cases by Status'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>30
,p_plug_grid_column_span=>7
,p_location=>null
,p_plug_source_type=>'NATIVE_JET_CHART'
);
wwv_flow_imp_page.create_jet_chart(
 p_id=>wwv_flow_imp.id(13001003000000103)
,p_region_id=>wwv_flow_imp.id(13001002000000102)
,p_chart_type=>'donut'
,p_width=>'500'
,p_height=>'350'
,p_animation_on_display=>'auto'
,p_animation_on_data_change=>'auto'
,p_data_cursor=>'auto'
,p_data_cursor_behavior=>'auto'
,p_hover_behavior=>'dim'
,p_stack=>'off'
,p_stack_label=>'off'
,p_connect_nulls=>'Y'
,p_value_position=>'auto'
,p_sorting=>'value-desc'
,p_fill_multi_series_gaps=>true
,p_tooltip_rendered=>'Y'
,p_show_series_name=>true
,p_show_group_name=>true
,p_show_value=>true
,p_show_label=>true
,p_show_row=>true
,p_show_start=>true
,p_show_end=>true
,p_show_progress=>true
,p_show_baseline=>true
,p_legend_rendered=>'on'
,p_legend_position=>'bottom'
,p_overview_rendered=>'off'
,p_horizontal_grid=>'auto'
,p_vertical_grid=>'auto'
,p_gauge_orientation=>'circular'
,p_gauge_plot_area=>'on'
,p_show_gauge_value=>true
);
wwv_flow_imp_page.create_jet_chart_series(
 p_id=>wwv_flow_imp.id(13001004000000104)
,p_chart_id=>wwv_flow_imp.id(13001003000000103)
,p_seq=>10
,p_name=>'Cases'
,p_data_source_type=>'SQL'
,p_data_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT',
'  NVL(current_status, ''Unknown'') AS status_label,',
'  case_count,',
'  CASE',
'    WHEN current_status LIKE ''%Approved%'' THEN ''#2e8540''',
'    WHEN current_status LIKE ''%Denied%''   THEN ''#cd2026''',
'    WHEN current_status LIKE ''%RFE%''      THEN ''#0071bc''',
'    WHEN current_status LIKE ''%Received%'' THEN ''#4c2c92''',
'    WHEN current_status LIKE ''%Pending%''  THEN ''#fdb81e''',
'    ELSE ''#5b616b''',
'  END AS status_color',
'FROM v_case_dashboard',
'ORDER BY case_count DESC',
'FETCH FIRST 8 ROWS ONLY'))
,p_items_value_column_name=>'CASE_COUNT'
,p_items_label_column_name=>'STATUS_LABEL'
,p_color=>'&STATUS_COLOR.'
,p_items_label_rendered=>true
,p_items_label_display_as=>'PERCENT'
,p_threshold_display=>'onIndicator'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13001005000000105)
,p_plug_name=>'Recent Activity'
,p_icon_css_classes=>'fa-clock-o'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>40
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>5
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'  l_html  VARCHAR2(32767);',
'  l_count NUMBER := 0;',
'BEGIN',
'  l_html := ''<div class="activity-list">'';',
'  FOR rec IN (',
'    SELECT',
'      TO_CHAR(performed_at, ''Mon DD HH24:MI'') AS event_time,',
'      action_description,',
'      CASE action',
'        WHEN ''INSERT'' THEN ''fa-plus-circle u-success-text''',
'        WHEN ''DELETE'' THEN ''fa-minus-circle u-danger-text''',
'        WHEN ''CHECK''  THEN ''fa-refresh u-info-text''',
'        ELSE ''fa-edit u-warning-text''',
'      END AS icon_cls',
'    FROM v_recent_activity',
'    ORDER BY performed_at DESC',
'    FETCH FIRST 10 ROWS ONLY',
'  ) LOOP',
'    l_html := l_html',
'      || ''<div class="activity-item">''',
'      || ''<span class="t-Icon '' || rec.icon_cls || ''" style="margin-right:6px"></span>''',
'      || ''<span class="activity-desc">'' || apex_escape.html(rec.action_description) || ''</span>''',
'      || ''<div class="activity-time">'' || apex_escape.html(rec.event_time) || ''</div>''',
'      || ''</div>'';',
'    l_count := l_count + 1;',
'  END LOOP;',
'',
'  IF l_count = 0 THEN',
'    l_html := l_html',
'      || ''<div style="padding:24px;text-align:center;color:#999">''',
'      || ''<span class="t-Icon fa fa-info-circle" style="font-size:20px"></span><br>''',
'      || ''No recent activity yet. Add a case to get started!''',
'      || ''</div>'';',
'  END IF;',
'',
'  l_html := l_html || ''</div>'';',
'  htp.p(l_html);',
'END;'))
,p_plug_source_type=>'NATIVE_PLSQL'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13001006000000106)
,p_plug_name=>'Quick Actions'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>50
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(13064674777297960)
,p_plug_name=>'USCIS Case Tracker'
,p_region_template_options=>'#DEFAULT#'
,p_escape_on_http_output=>'Y'
,p_plug_template=>2674017834225413037
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_plug_query_num_rows=>15
,p_region_image=>'#APP_FILES#icons/app-icon-512.png'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML',
  'show_line_breaks', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13001101000000111)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(13001006000000106)
,p_button_name=>'BTN_ADD_CASE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Add New Case'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:4:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-plus'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13001102000000112)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(13001006000000106)
,p_button_name=>'BTN_VIEW_CASES'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'View All Cases'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:22:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-table'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(13001103000000113)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(13001006000000106)
,p_button_name=>'BTN_IMPORT_EXPORT'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>4072362960822175091
,p_button_image_alt=>'Import / Export'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:6:&SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-exchange'
);
wwv_flow_imp.component_end;
end;
/
