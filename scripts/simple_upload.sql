-- ============================================================
-- Simple Upload Script for Enhanced Static Files
-- ============================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    l_app_id NUMBER := 102;
    l_workspace_id NUMBER;
BEGIN
    -- Get workspace ID
    SELECT workspace_id INTO l_workspace_id
    FROM apex_applications
    WHERE application_id = l_app_id;

    -- Set APEX security context
    apex_util.set_security_group_id(l_workspace_id);

    DBMS_OUTPUT.PUT_LINE('Security context set for application ' || l_app_id);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('NOTE: This simple script sets up the security context only.');
    DBMS_OUTPUT.PUT_LINE('For actual file uploads, use one of these options:');
    DBMS_OUTPUT.PUT_LINE('  1. Run upload_enhanced_files.sql for full CSS/JS upload');
    DBMS_OUTPUT.PUT_LINE('  2. Run upload_inline.sql for inline content upload');
    DBMS_OUTPUT.PUT_LINE('  3. Use wwv_flow_api.create_app_static_file() directly');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Expected features when files are uploaded:');
    DBMS_OUTPUT.PUT_LINE('  - Modern glassmorphism design');
    DBMS_OUTPUT.PUT_LINE('  - Beautiful gradient backgrounds');
    DBMS_OUTPUT.PUT_LINE('  - Animated status badges');
    DBMS_OUTPUT.PUT_LINE('  - Enhanced visual effects');
    DBMS_OUTPUT.PUT_LINE('  - Improved user experience');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

SET DEFINE ON