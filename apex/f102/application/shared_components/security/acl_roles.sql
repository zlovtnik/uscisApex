prompt --application/shared_components/security/acl_roles
begin
--   Manifest
--     ACL ROLES
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.13'
,p_default_workspace_id=>13027568242155993
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'USCIS_APP'
);
wwv_flow_imp_shared.create_acl_role(
 p_id=>wwv_flow_imp.id(90000901)
,p_static_id=>'ADMINISTRATOR'
,p_name=>'Administrator'
,p_description=>'Application administrator'
);
wwv_flow_imp_shared.create_acl_role(
 p_id=>wwv_flow_imp.id(90000902)
,p_static_id=>'CONTRIBUTOR'
,p_name=>'Contributor'
,p_description=>'Can add and edit cases'
);
wwv_flow_imp_shared.create_acl_role(
 p_id=>wwv_flow_imp.id(90000903)
,p_static_id=>'READER'
,p_name=>'Reader'
,p_description=>'Read-only access'
);
wwv_flow_imp.component_end;
end;
/
