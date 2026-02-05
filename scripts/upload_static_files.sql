-- ============================================================
-- Upload Static Files to APEX Application
-- ============================================================
-- Run this script in your APEX application's schema (USCIS_APP)
-- after connecting to the database.
--
-- This will add the missing static files that are causing 404 errors.
-- ============================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Uploading static files to APEX Application 102...

DECLARE
    l_app_id NUMBER := 102;
    l_workspace_id NUMBER;
    l_js_content CLOB;
BEGIN
    -- Get workspace ID
    SELECT workspace_id INTO l_workspace_id
    FROM apex_applications 
    WHERE application_id = l_app_id;
    
    -- Set APEX security context
    apex_util.set_security_group_id(l_workspace_id);
    
    -- JavaScript content for page_0006_import_export.js
    l_js_content := q'[/**
 * USCIS Case Tracker - Page 6: Import/Export JavaScript
 * @file page_0006_import_export.js
 */
(function() {
    'use strict';
    
    var ImportExport = {
        init: function() {
            this.setupDragAndDrop();
            this.setupFileValidation();
        },
        
        setupDragAndDrop: function() {
            var fileInput = document.getElementById('P6_IMPORT_FILE');
            if (!fileInput) return;
            
            var container = fileInput.closest('.t-Form-fieldContainer');
            if (!container) return;
            
            ['dragenter', 'dragover'].forEach(function(eventName) {
                container.addEventListener(eventName, function(e) {
                    e.preventDefault();
                    container.classList.add('drag-over');
                });
            });
            
            ['dragleave', 'drop'].forEach(function(eventName) {
                container.addEventListener(eventName, function(e) {
                    e.preventDefault();
                    container.classList.remove('drag-over');
                });
            });
            
            // Note: Change handler moved to setupFileValidation to avoid duplicate handlers
        },
        
        setupFileValidation: function() {
            var fileInput = document.getElementById('P6_IMPORT_FILE');
            if (!fileInput) return;
            
            fileInput.addEventListener('change', function() {
                var file = this.files[0];
                if (!file) return;
                
                var maxSize = 10 * 1024 * 1024;
                if (file.size > maxSize) {
                    apex.message.alert('File size exceeds 10MB limit.');
                    this.value = '';
                    return;
                }
                
                var validExtensions = ['.json'];
                var fileName = file.name.toLowerCase();
                var isValid = validExtensions.some(function(ext) {
                    return fileName.endsWith(ext);
                });
                
                if (!isValid) {
                    apex.message.alert('Please select a .json file.');
                    this.value = '';
                    return;
                }
                
                // Show success message only after validation passes
                apex.message.showPageSuccess('Selected: ' + file.name);
            });
        }
    };
    
    apex.jQuery(function() {
        ImportExport.init();
    });
    
    window.USCIS = window.USCIS || {};
    window.USCIS.ImportExport = ImportExport;
})();
]';

    -- Delete existing file if present (using APEX API)
    DECLARE
        l_file_id NUMBER;
    BEGIN
        SELECT application_file_id INTO l_file_id
        FROM apex_application_static_files
        WHERE application_id = l_app_id
        AND file_name = 'js/page_0006_import_export.js';
        
        wwv_flow_imp.remove_app_static_file(
            p_id      => l_file_id,
            p_flow_id => l_app_id
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- File doesn't exist, that's OK
    END;

    -- Upload the JS file
    wwv_flow_imp.create_app_static_file(
        p_id           => wwv_flow_id.next_val,
        p_flow_id      => l_app_id,
        p_file_name    => 'js/page_0006_import_export.js',
        p_mime_type    => 'application/javascript',
        p_file_charset => 'utf-8',
        p_file_content => utl_raw.cast_to_raw(l_js_content)
    );
    
    DBMS_OUTPUT.PUT_LINE('Successfully uploaded: js/page_0006_import_export.js');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Static files upload complete!');
    DBMS_OUTPUT.PUT_LINE('Clear your browser cache and refresh the page.');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

SET DEFINE ON

PROMPT Done. Clear browser cache and refresh the Import/Export page.
