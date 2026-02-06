prompt --application/shared_components/navigation/breadcrumbs/breadcrumb
begin
--   Manifest
--     MENU: Breadcrumb
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.13'
,p_default_workspace_id=>13027568242155993
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'USCIS_APP'
);
wwv_flow_imp_shared.create_menu(
 p_id=>wwv_flow_imp.id(13051532648297767)
,p_name=>'Breadcrumb'
);
wwv_flow_imp_shared.create_menu_option(
 p_id=>wwv_flow_imp.id(13051773748297768)
,p_short_name=>'Home'
,p_link=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_page_id=>1
);
wwv_flow_imp_shared.create_menu_option(
 p_id=>wwv_flow_imp.id(13088550178253660)
,p_parent_id=>wwv_flow_imp.id(13051773748297768)
,p_short_name=>'My Cases'
,p_link=>'f?p=&APP_ID.:22:&APP_SESSION.::&DEBUG.:::'
,p_page_id=>22
);
wwv_flow_imp_shared.create_menu_option(
 p_id=>wwv_flow_imp.id(13300001100000111)
,p_parent_id=>wwv_flow_imp.id(13088550178253660)
,p_short_name=>'Case Details'
,p_link=>'f?p=&APP_ID.:3:&APP_SESSION.::&DEBUG.::P3_RECEIPT_NUMBER:&P3_RECEIPT_NUMBER.'
,p_page_id=>3
);
wwv_flow_imp.component_end;
end;
/
