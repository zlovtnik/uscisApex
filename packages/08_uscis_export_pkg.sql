-- ============================================================
-- USCIS Case Tracker - Export/Import Package
-- Task 1.3.7: USCIS_EXPORT_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/08_uscis_export_pkg.sql
-- Purpose: Import and export utilities for case data
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG, USCIS_CASE_PKG, USCIS_AUDIT_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_EXPORT_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_export_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_EXPORT_PKG';
    
    -- ========================================================
    -- Exception Definitions
    -- ========================================================
    e_export_failed     EXCEPTION;
    e_import_failed     EXCEPTION;
    e_invalid_format    EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_export_failed, -20040);
    PRAGMA EXCEPTION_INIT(e_import_failed, -20041);
    PRAGMA EXCEPTION_INIT(e_invalid_format, -20042);
    
    -- ========================================================
    -- Export Functions
    -- ========================================================
    
    -- Export all cases as JSON
    FUNCTION export_cases_json(
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_include_history IN BOOLEAN DEFAULT TRUE,
        p_active_only     IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB;
    
    -- Export cases as CSV
    FUNCTION export_cases_csv(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB;
    
    -- Export single case as JSON
    FUNCTION export_case_json(
        p_receipt_number  IN VARCHAR2,
        p_include_history IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB;
    
    -- ========================================================
    -- Import Functions
    -- ========================================================
    
    -- Import cases from JSON
    FUNCTION import_cases_json(
        p_json_data        IN CLOB,
        p_replace_existing IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER;  -- Returns count of imported cases
    
    -- Import single case from JSON
    FUNCTION import_case_json(
        p_json_data        IN CLOB,
        p_replace_existing IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2;  -- Returns receipt number
    
    -- Validate import JSON structure
    FUNCTION validate_import_json(
        p_json_data IN CLOB
    ) RETURN CLOB;  -- Returns validation result as JSON
    
    -- ========================================================
    -- Download Procedures (for APEX)
    -- ========================================================
    
    -- Generate download (sets APEX headers)
    PROCEDURE download_export(
        p_format          IN VARCHAR2 DEFAULT 'JSON',  -- JSON, CSV
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_include_history IN BOOLEAN DEFAULT TRUE,
        p_active_only     IN BOOLEAN DEFAULT FALSE,
        p_filename        IN VARCHAR2 DEFAULT NULL
    );
    
    -- ========================================================
    -- Statistics Functions
    -- ========================================================
    
    -- Get export statistics
    FUNCTION get_export_stats(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB;

END uscis_export_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_export_pkg AS

    -- --------------------------------------------------------
    -- Private: Sanitize CSV value to prevent injection
    -- --------------------------------------------------------
    FUNCTION sanitize_csv_value(p_value IN VARCHAR2) RETURN VARCHAR2 IS
        l_value VARCHAR2(4000) := p_value;
    BEGIN
        -- Replace CR/LF with spaces
        l_value := REPLACE(REPLACE(l_value, CHR(13), ' '), CHR(10), ' ');
        -- Escape double quotes by doubling them
        l_value := REPLACE(l_value, '"', '""');
        -- Prefix with single quote if starts with formula characters
        IF SUBSTR(l_value, 1, 1) IN ('=', '+', '-', '@') OR INSTR(l_value, CHR(9)) = 1 THEN
            l_value := '''' || l_value;
        END IF;
        RETURN l_value;
    END sanitize_csv_value;

    -- --------------------------------------------------------
    -- Private: Build case JSON object
    -- --------------------------------------------------------
    FUNCTION build_case_json(
        p_receipt_number  IN VARCHAR2,
        p_include_history IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB IS
        l_json    CLOB;
        l_history CLOB;
        l_first   BOOLEAN := TRUE;
    BEGIN
        -- Get case info from view
        FOR rec IN (
            SELECT *
            FROM v_case_current_status
            WHERE receipt_number = p_receipt_number
        ) LOOP
            l_json := '{' ||
                '"receipt_number":"' || rec.receipt_number || '",' ||
                '"case_type":"' || uscis_util_pkg.json_escape(rec.case_type) || '",' ||
                '"current_status":"' || uscis_util_pkg.json_escape(rec.current_status) || '",' ||
                '"last_updated":' || CASE WHEN rec.last_updated IS NULL THEN 'null' 
                    ELSE '"' || TO_CHAR(rec.last_updated, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') || '"' END || ',' ||
                '"details":"' || uscis_util_pkg.json_escape(SUBSTR(rec.details, 1, 4000)) || '",' ||
                '"tracking_since":' || CASE WHEN rec.tracking_since IS NULL THEN 'null' 
                    ELSE '"' || TO_CHAR(rec.tracking_since, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') || '"' END || ',' ||
                '"created_by":"' || uscis_util_pkg.json_escape(rec.created_by) || '",' ||
                '"notes":"' || uscis_util_pkg.json_escape(SUBSTR(rec.notes, 1, 4000)) || '",' ||
                '"is_active":' || NVL(rec.is_active, 0) || ',' ||
                '"check_frequency":' || NVL(rec.check_frequency, 24) || ',' ||
                '"total_updates":' || NVL(rec.total_updates, 0);
        END LOOP;
        
        IF l_json IS NULL THEN
            RETURN NULL;
        END IF;
        
        -- Add history if requested
        IF p_include_history THEN
            l_history := ',"status_history":[';
            
            FOR rec IN (
                SELECT *
                FROM v_status_history
                WHERE receipt_number = p_receipt_number
                ORDER BY last_updated DESC
            ) LOOP
                IF NOT l_first THEN
                    l_history := l_history || ',';
                END IF;
                l_first := FALSE;
                
                l_history := l_history || '{' ||
                    '"case_type":"' || uscis_util_pkg.json_escape(rec.case_type) || '",' ||
                    '"status":"' || uscis_util_pkg.json_escape(rec.current_status) || '",' ||
                    '"updated":"' || TO_CHAR(rec.last_updated, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') || '",' ||
                    '"source":"' || uscis_util_pkg.json_escape(rec.source) || '",' ||
                    '"details":"' || uscis_util_pkg.json_escape(SUBSTR(rec.details, 1, 1000)) || '"' ||
                '}';
            END LOOP;
            
            l_history := l_history || ']';
            l_json := l_json || l_history;
        END IF;
        
        l_json := l_json || '}';
        
        RETURN l_json;
    END build_case_json;
    
    -- --------------------------------------------------------
    -- export_case_json
    -- --------------------------------------------------------
    FUNCTION export_case_json(
        p_receipt_number  IN VARCHAR2,
        p_include_history IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB IS
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        RETURN build_case_json(l_receipt, p_include_history);
    END export_case_json;
    
    -- --------------------------------------------------------
    -- export_cases_json
    -- --------------------------------------------------------
    FUNCTION export_cases_json(
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_include_history IN BOOLEAN DEFAULT TRUE,
        p_active_only     IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB IS
        l_json         CLOB;
        l_case_json    CLOB;
        l_first        BOOLEAN := TRUE;
        l_count        NUMBER := 0;
        l_safe_filter  VARCHAR2(1000);
    BEGIN
        l_json := '{"export_date":"' || TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') || 
                  '","exported_by":"' || uscis_util_pkg.get_current_user || 
                  '","cases":[';
        
        -- Escape wildcards in filter for safe LIKE pattern matching
        -- Escape backslash first, then % and _ to treat them as literal characters
        IF p_receipt_filter IS NOT NULL THEN
            l_safe_filter := REPLACE(p_receipt_filter, '\', '\\');
            l_safe_filter := REPLACE(l_safe_filter, '%', '\%');
            l_safe_filter := REPLACE(l_safe_filter, '_', '\_');
        END IF;
        
        FOR rec IN (
            SELECT receipt_number
            FROM v_case_current_status
            WHERE (p_receipt_filter IS NULL OR receipt_number LIKE l_safe_filter || '%' ESCAPE '\')
              AND (NOT p_active_only OR is_active = 1)
            ORDER BY receipt_number
        ) LOOP
            l_case_json := build_case_json(rec.receipt_number, p_include_history);
            
            IF l_case_json IS NOT NULL THEN
                IF NOT l_first THEN
                    l_json := l_json || ',';
                END IF;
                l_first := FALSE;
                l_json := l_json || l_case_json;
                l_count := l_count + 1;
            END IF;
        END LOOP;
        
        l_json := l_json || '],"total_cases":' || l_count || '}';
        
        -- Log export
        uscis_audit_pkg.log_export(l_count, 'JSON');
        
        RETURN l_json;
    END export_cases_json;
    
    -- --------------------------------------------------------
    -- export_cases_csv
    -- --------------------------------------------------------
    FUNCTION export_cases_csv(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB IS
        l_csv         CLOB;
        l_count       NUMBER := 0;
        l_safe_filter VARCHAR2(1000);
    BEGIN
        -- Header row
        l_csv := 'Receipt Number,Case Type,Current Status,Last Updated,Is Active,Check Frequency,Tracking Since,Created By,Notes' || CHR(13) || CHR(10);
        
        -- Escape wildcards in filter for safe LIKE pattern matching
        IF p_receipt_filter IS NOT NULL THEN
            l_safe_filter := REPLACE(p_receipt_filter, '\', '\\');
            l_safe_filter := REPLACE(l_safe_filter, '%', '\%');
            l_safe_filter := REPLACE(l_safe_filter, '_', '\_');
        END IF;
        
        FOR rec IN (
            SELECT 
                receipt_number,
                case_type,
                current_status,
                last_updated,
                is_active,
                check_frequency,
                tracking_since,
                created_by,
                notes
            FROM v_case_current_status
            WHERE (p_receipt_filter IS NULL OR receipt_number LIKE l_safe_filter || '%' ESCAPE '\')
              AND (NOT p_active_only OR is_active = 1)
            ORDER BY receipt_number
        ) LOOP
            l_csv := l_csv ||
                '"' || sanitize_csv_value(rec.receipt_number) || '",' ||
                '"' || sanitize_csv_value(rec.case_type) || '",' ||
                '"' || sanitize_csv_value(rec.current_status) || '",' ||
                '"' || TO_CHAR(rec.last_updated, 'YYYY-MM-DD HH24:MI:SS') || '",' ||
                rec.is_active || ',' ||
                NVL(rec.check_frequency, 24) || ',' ||
                '"' || TO_CHAR(rec.tracking_since, 'YYYY-MM-DD HH24:MI:SS') || '",' ||
                '"' || sanitize_csv_value(rec.created_by) || '",' ||
                '"' || sanitize_csv_value(SUBSTR(rec.notes, 1, 500)) || '"' ||
                CHR(13) || CHR(10);
            l_count := l_count + 1;
        END LOOP;
        
        -- Log export
        uscis_audit_pkg.log_export(l_count, 'CSV');
        
        RETURN l_csv;
    END export_cases_csv;
    
    -- --------------------------------------------------------
    -- validate_import_json
    -- --------------------------------------------------------
    FUNCTION validate_import_json(
        p_json_data IN CLOB
    ) RETURN CLOB IS
        l_result      CLOB;
        l_valid       BOOLEAN := TRUE;
        l_case_count  NUMBER := 0;
        l_errors      CLOB := '';
        l_has_cases   NUMBER;
    BEGIN
        IF p_json_data IS NULL OR LENGTH(p_json_data) = 0 THEN
            RETURN '{"valid":false,"error":"Empty JSON data"}';
        END IF;
        
        -- Check if it's valid JSON
        BEGIN
            SELECT COUNT(*)
            INTO l_has_cases
            FROM JSON_TABLE(p_json_data, '$.cases[*]'
                COLUMNS (receipt_number VARCHAR2(13) PATH '$.receipt_number')
            );
            l_case_count := l_has_cases;
        EXCEPTION
            WHEN OTHERS THEN
                -- Try single case format
                BEGIN
                    SELECT 1 INTO l_has_cases
                    FROM dual
                    WHERE JSON_VALUE(p_json_data, '$.receipt_number') IS NOT NULL;
                    l_case_count := 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN '{"valid":false,"error":"Invalid JSON structure: ' || 
                               uscis_util_pkg.json_escape(SQLERRM) || '"}';
                END;
        END;
        
        l_result := '{' ||
            '"valid":true,' ||
            '"case_count":' || l_case_count || ',' ||
            '"format":"' || CASE WHEN l_case_count = 1 THEN 'single' ELSE 'array' END || '"' ||
        '}';
        
        RETURN l_result;
    END validate_import_json;
    
    -- --------------------------------------------------------
    -- import_case_json
    -- --------------------------------------------------------
    FUNCTION import_case_json(
        p_json_data        IN CLOB,
        p_replace_existing IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2 IS
        l_receipt             VARCHAR2(13);
        l_case_type           VARCHAR2(100);
        l_status              VARCHAR2(500);
        l_last_updated        TIMESTAMP;
        l_details             CLOB;
        l_notes               CLOB;
        l_is_active           NUMBER;
        l_frequency           NUMBER;
        l_sp_replace_case_set BOOLEAN := FALSE;  -- Track if savepoint was created
    BEGIN
        -- Parse JSON
        SELECT 
            JSON_VALUE(p_json_data, '$.receipt_number'),
            JSON_VALUE(p_json_data, '$.case_type'),
            JSON_VALUE(p_json_data, '$.current_status'),
            uscis_util_pkg.parse_iso_timestamp(JSON_VALUE(p_json_data, '$.last_updated')),
            JSON_VALUE(p_json_data, '$.details'),
            JSON_VALUE(p_json_data, '$.notes'),
            NVL(JSON_VALUE(p_json_data, '$.is_active' RETURNING NUMBER), 1),
            NVL(JSON_VALUE(p_json_data, '$.check_frequency' RETURNING NUMBER), 24)
        INTO l_receipt, l_case_type, l_status, l_last_updated, l_details, l_notes, l_is_active, l_frequency
        FROM dual;
        
        -- Validate receipt
        l_receipt := uscis_util_pkg.normalize_receipt_number(l_receipt);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Track if savepoint was set for exception handler
        l_sp_replace_case_set := FALSE;
        
        -- Check if exists
        IF uscis_case_pkg.case_exists(l_receipt) THEN
            IF p_replace_existing THEN
                SAVEPOINT sp_replace_case;
                l_sp_replace_case_set := TRUE;
                uscis_case_pkg.delete_case(l_receipt);
            ELSE
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_duplicate_case,
                    'Case already exists: ' || l_receipt
                );
            END IF;
        END IF;
        
        -- Add case (single call - duplicate was removed)
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number  => l_receipt,
            p_case_type       => l_case_type,
            p_current_status  => l_status,
            p_last_updated    => l_last_updated,
            p_details         => l_details,
            p_notes           => l_notes,
            p_source          => uscis_types_pkg.gc_source_import,
            p_check_frequency => l_frequency
        );
        
        -- Set active status
        IF l_is_active = 0 THEN
            uscis_case_pkg.set_case_active(l_receipt, FALSE);
        END IF;
        
        RETURN l_receipt;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Only rollback to savepoint if it was actually set
            IF p_replace_existing AND l_sp_replace_case_set THEN
                ROLLBACK TO sp_replace_case;
            END IF;
            RAISE;
    END import_case_json;
    
    -- --------------------------------------------------------
    -- import_cases_json
    -- --------------------------------------------------------
    FUNCTION import_cases_json(
        p_json_data        IN CLOB,
        p_replace_existing IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER IS
        l_count      NUMBER := 0;
        l_errors     NUMBER := 0;
        l_receipt    VARCHAR2(13);
        l_case_json  CLOB;
    BEGIN
        -- Determine format
        IF JSON_EXISTS(p_json_data, '$.cases') THEN
            -- Array format
            FOR rec IN (
                SELECT jt.*
                FROM JSON_TABLE(p_json_data, '$.cases[*]'
                    COLUMNS (
                        receipt_number VARCHAR2(13) PATH '$.receipt_number',
                        case_type VARCHAR2(100) PATH '$.case_type',
                        current_status VARCHAR2(500) PATH '$.current_status',
                        last_updated VARCHAR2(50) PATH '$.last_updated',
                        details VARCHAR2(4000) PATH '$.details',
                        notes VARCHAR2(4000) PATH '$.notes',
                        is_active NUMBER PATH '$.is_active',
                        check_frequency NUMBER PATH '$.check_frequency'
                    )
                ) jt
            ) LOOP
                BEGIN
                    -- Build single case JSON
                    l_case_json := '{' ||
                        '"receipt_number":"' || rec.receipt_number || '",' ||
                        '"case_type":"' || uscis_util_pkg.json_escape(rec.case_type) || '",' ||
                        '"current_status":"' || uscis_util_pkg.json_escape(rec.current_status) || '",' ||
                        '"last_updated":"' || rec.last_updated || '",' ||
                        '"details":"' || uscis_util_pkg.json_escape(rec.details) || '",' ||
                        '"notes":"' || uscis_util_pkg.json_escape(rec.notes) || '",' ||
                        '"is_active":' || NVL(rec.is_active, 1) || ',' ||
                        '"check_frequency":' || NVL(rec.check_frequency, 24) ||
                    '}';
                    
                    l_receipt := import_case_json(l_case_json, p_replace_existing);
                    l_count := l_count + 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        -- Re-raise unexpected errors, only catch format-related
                        IF SQLCODE IN (-31011, -31013) THEN -- JSON parsing errors
                            l_errors := l_errors + 1;
                            uscis_util_pkg.log_error(
                                'Failed to import case ' || rec.receipt_number || ': ' || SQLERRM,
                                gc_package_name
                            );
                        ELSE
                            RAISE;
                        END IF;
                END;
            END LOOP;
        ELSE
            -- Single case format
            l_receipt := import_case_json(p_json_data, p_replace_existing);
            l_count := 1;
        END IF;
        
        -- Log import with error count
        uscis_audit_pkg.log_import(l_count, NULL, l_errors);
        
        RETURN l_count;
    END import_cases_json;
    
    -- --------------------------------------------------------
    -- download_export
    -- --------------------------------------------------------
    PROCEDURE download_export(
        p_format          IN VARCHAR2 DEFAULT 'JSON',
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_include_history IN BOOLEAN DEFAULT TRUE,
        p_active_only     IN BOOLEAN DEFAULT FALSE,
        p_filename        IN VARCHAR2 DEFAULT NULL
    ) IS
        l_data     CLOB;
        l_filename VARCHAR2(255);
        l_mime     VARCHAR2(100);
    BEGIN
        -- Check APEX context first (before any OWA/HTP operations)
        IF apex_application.g_flow_id IS NULL THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_export_failed,
                'Download only available in APEX context'
            );
        END IF;
        
        -- Generate and sanitize filename (prevent HTTP header injection)
        l_filename := NVL(p_filename, 
            'uscis_cases_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS'));
        -- Remove CR/LF characters that could inject headers
        l_filename := REPLACE(l_filename, CHR(13), '');
        l_filename := REPLACE(l_filename, CHR(10), '');
        -- Escape or remove double quotes
        l_filename := REPLACE(l_filename, '"', '_');
        -- Trim and provide safe default if empty
        l_filename := TRIM(l_filename);
        IF l_filename IS NULL OR LENGTH(l_filename) = 0 THEN
            l_filename := 'uscis_export_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS');
        END IF;
        
        IF UPPER(p_format) = 'CSV' THEN
            l_data := export_cases_csv(p_receipt_filter, p_active_only);
            l_filename := l_filename || '.csv';
            l_mime := 'text/csv';
        ELSE
            l_data := export_cases_json(p_receipt_filter, p_include_history, p_active_only);
            l_filename := l_filename || '.json';
            l_mime := 'application/json';
        END IF;
        
        -- Set APEX download headers
        OWA_UTIL.MIME_HEADER(l_mime, FALSE);
        HTP.P('Content-Disposition: attachment; filename="' || APEX_ESCAPE.HTML(l_filename) || '"');
        HTP.P('Content-Length: ' || LENGTHB(l_data));
        OWA_UTIL.HTTP_HEADER_CLOSE;
        
        -- Output data
        HTP.PRN(l_data);
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log and re-raise the original error
            uscis_util_pkg.log_error(
                'download_export failed: ' || SQLERRM,
                gc_package_name
            );
            RAISE;
    END download_export;
    
    -- --------------------------------------------------------
    -- get_export_stats
    -- --------------------------------------------------------
    FUNCTION get_export_stats(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT FALSE
    ) RETURN CLOB IS
        l_total       NUMBER;
        l_active      NUMBER;
        l_inactive    NUMBER;
        l_by_type     CLOB;
        l_by_status   CLOB;
        l_safe_filter VARCHAR2(1000);
    BEGIN
        -- Escape wildcards in filter for safe LIKE pattern matching
        IF p_receipt_filter IS NOT NULL THEN
            l_safe_filter := REPLACE(p_receipt_filter, '\', '\\');
            l_safe_filter := REPLACE(l_safe_filter, '%', '\%');
            l_safe_filter := REPLACE(l_safe_filter, '_', '\_');
        END IF;
        
        SELECT 
            COUNT(*),
            SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END),
            SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)
        INTO l_total, l_active, l_inactive
        FROM v_case_current_status
        WHERE (p_receipt_filter IS NULL OR receipt_number LIKE l_safe_filter || '%' ESCAPE '\')
          AND (NOT p_active_only OR is_active = 1);
        
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT('type' VALUE case_type, 'count' VALUE cnt)
        )
        INTO l_by_type
        FROM (
            SELECT case_type, COUNT(*) cnt
            FROM v_case_current_status
            WHERE (p_receipt_filter IS NULL OR receipt_number LIKE l_safe_filter || '%' ESCAPE '\')
              AND (NOT p_active_only OR is_active = 1)
              AND case_type IS NOT NULL
            GROUP BY case_type
        );
        
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT('status' VALUE current_status, 'count' VALUE cnt)
        )
        INTO l_by_status
        FROM (
            SELECT current_status, COUNT(*) cnt
            FROM v_case_current_status
            WHERE (p_receipt_filter IS NULL OR receipt_number LIKE l_safe_filter || '%' ESCAPE '\')
              AND (NOT p_active_only OR is_active = 1)
              AND current_status IS NOT NULL
            GROUP BY current_status
        );
        
        RETURN '{' ||
            '"total_cases":' || l_total || ',' ||
            '"active_cases":' || l_active || ',' ||
            '"inactive_cases":' || l_inactive || ',' ||
            '"by_type":' || NVL(l_by_type, '[]') || ',' ||
            '"by_status":' || NVL(l_by_status, '[]') ||
        '}';
    END get_export_stats;

END uscis_export_pkg;
/

SHOW ERRORS PACKAGE uscis_export_pkg
SHOW ERRORS PACKAGE BODY uscis_export_pkg

PROMPT ============================================================
PROMPT USCIS_EXPORT_PKG created successfully
PROMPT ============================================================
