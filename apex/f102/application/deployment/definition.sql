prompt --application/deployment/definition
begin
--   Manifest
--     INSTALL: 102
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.13'
,p_default_workspace_id=>13027568242155993
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'USCIS_APP'
);
wwv_flow_imp_shared.create_install(
 p_id=>wwv_flow_imp.id(13067111312300857)
);
wwv_flow_imp.component_end;
end;
/
