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

    -- Initialize full APEX session context (R-02: use apex_session instead of set_security_group_id)
    apex_session.create_session(
        p_app_id                   => l_app_id,
        p_page_id                  => 1,
        p_username                 => 'ADMIN',
        p_call_post_authentication => FALSE
    );

    DBMS_OUTPUT.PUT_LINE('Session context set for application ' || l_app_id);
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

    -- Clean up APEX session (R-02)
    apex_session.delete_session;

EXCEPTION
    WHEN OTHERS THEN
        -- Clean up APEX session on error (R-02)
        BEGIN apex_session.delete_session; EXCEPTION WHEN OTHERS THEN NULL; END;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

SET DEFINE ON