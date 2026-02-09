prompt --application/user_interfaces
begin
--   Manifest
--     USER INTERFACES: 102
--   Manifest End
-- Environment-specific values are resolved via apex_application_install overrides
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.13'
,p_default_workspace_id=>wwv_flow_imp.get_default_workspace_id
,p_default_application_id=>wwv_flow_imp.get_default_application_id
,p_default_id_offset=>wwv_flow_imp.get_default_id_offset
,p_default_owner=>wwv_flow_imp.get_default_owner
);
wwv_flow_imp_shared.create_user_interface(
 p_id=>wwv_flow_imp.id(102)
,p_theme_id=>42
,p_home_url=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_login_url=>'f?p=&APP_ID.:LOGIN:&APP_SESSION.::&DEBUG.:::'
,p_theme_style_by_user_pref=>false
,p_global_page_id=>0
,p_navigation_list_id=>wwv_flow_imp.id(13052023954297773)
,p_navigation_list_position=>'SIDE'
,p_navigation_list_template_id=>2467739217141810545
,p_nav_list_template_options=>'#DEFAULT#:js-defaultCollapsed:js-navCollapsed--hidden:t-TreeNav--styleA'
,p_css_file_urls=>'#APP_FILES#css/maine-pine-v5.css'
,p_javascript_file_urls=>'#APP_FILES#app-scripts.js'
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_imp.id(13053183405297823)
,p_nav_bar_list_template_id=>2847543055748234966
,p_nav_bar_template_options=>'#DEFAULT#'
);
wwv_flow_imp.component_end;
end;
/
