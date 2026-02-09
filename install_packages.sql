-- Install PL/SQL packages in dependency order (01-10)
-- Usage: sql -name USCIS_APP @install_packages.sql

SET ECHO ON
SET FEEDBACK ON

PROMPT ========================================
PROMPT Installing PL/SQL packages (01-10)...
PROMPT ========================================

@packages/01_uscis_types_pkg.sql
@packages/02_uscis_util_pkg.sql
@packages/03_uscis_audit_pkg.sql
@packages/04_uscis_case_pkg.sql
@packages/05_uscis_oauth_pkg.sql
@packages/06_uscis_api_pkg.sql
@packages/07_uscis_scheduler_pkg.sql
@packages/08_uscis_export_pkg.sql
@packages/09_uscis_template_components_pkg.sql
@packages/10_uscis_error_pkg.sql

-- Show any compilation errors
PROMPT ========================================
PROMPT Checking for invalid objects...
PROMPT ========================================

SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'USCIS%'
ORDER BY object_name, object_type;

exit
