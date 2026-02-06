-- ============================================================
-- USCIS Case Tracker - Utility Package
-- Task 1.3.2: USCIS_UTIL_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/02_uscis_util_pkg.sql
-- Purpose: Utility functions for validation, masking, config
-- Dependencies: USCIS_TYPES_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_UTIL_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_util_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_UTIL_PKG';
    
    -- ========================================================
    -- Receipt Number Functions
    -- ========================================================
    
    -- Validate receipt number format (3 letters + 10 digits)
    FUNCTION validate_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Validate and raise exception if invalid
    PROCEDURE assert_valid_receipt(
        p_receipt_number IN VARCHAR2
    );
    
    -- Normalize receipt number (uppercase, alphanumeric only)
    FUNCTION normalize_receipt_number(
        p_input IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Mask receipt number for logging (IOE****5678)
    FUNCTION mask_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Extract service center prefix
    FUNCTION get_service_center(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- ========================================================
    -- Configuration Functions
    -- ========================================================
    
    -- Get configuration value by key
    FUNCTION get_config(
        p_key     IN VARCHAR2,
        p_default IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
    
    -- Get configuration as number
    FUNCTION get_config_number(
        p_key     IN VARCHAR2,
        p_default IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;
    
    -- Get configuration as boolean (Y/N)
    FUNCTION get_config_boolean(
        p_key     IN VARCHAR2,
        p_default IN BOOLEAN DEFAULT FALSE
    ) RETURN BOOLEAN;
    
    -- Set configuration value
    PROCEDURE set_config(
        p_key         IN VARCHAR2,
        p_value       IN VARCHAR2,
        p_description IN VARCHAR2 DEFAULT NULL
    );
    
    -- ========================================================
    -- Date/Time Functions
    -- ========================================================
    
    -- Parse ISO 8601 timestamp string to TIMESTAMP
    FUNCTION parse_iso_timestamp(
        p_timestamp_str IN VARCHAR2
    ) RETURN TIMESTAMP;
    
    -- Format timestamp as ISO 8601 string
    FUNCTION format_iso_timestamp(
        p_timestamp IN TIMESTAMP
    ) RETURN VARCHAR2;
    
    -- Get relative time description (e.g., "2 days ago")
    FUNCTION get_relative_time(
        p_timestamp IN TIMESTAMP
    ) RETURN VARCHAR2;
    
    -- ========================================================
    -- APEX Context Functions
    -- ========================================================
    
    -- Get current APEX user (or DB user if not in APEX)
    FUNCTION get_current_user RETURN VARCHAR2;
    
    -- Get client IP address
    FUNCTION get_client_ip RETURN VARCHAR2;
    
    -- Get APEX session ID
    FUNCTION get_session_id RETURN NUMBER;
    
    -- Get APEX application ID
    FUNCTION get_app_id RETURN NUMBER;
    
    -- ========================================================
    -- JSON Utility Functions
    -- ========================================================
    
    -- Safe JSON string escape (returns CLOB for long strings)
    FUNCTION json_escape(
        p_string IN VARCHAR2
    ) RETURN CLOB;
    
    -- Safe JSON string escape (VARCHAR2 overload for backward compatibility)
    -- Note: Truncates output to 32767 chars; use CLOB version for long strings
    FUNCTION json_escape_varchar2(
        p_string IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Build simple JSON object from key-value pairs
    FUNCTION build_json(
        p_keys   IN uscis_types_pkg.t_string_tab,
        p_values IN uscis_types_pkg.t_string_tab
    ) RETURN CLOB;
    
    -- ========================================================
    -- Logging Functions
    -- ========================================================
    
    -- Log debug message (to DBMS_OUTPUT)
    PROCEDURE log_debug(
        p_message IN VARCHAR2,
        p_module  IN VARCHAR2 DEFAULT NULL
    );
    
    -- Log error with context
    PROCEDURE log_error(
        p_message IN VARCHAR2,
        p_module  IN VARCHAR2 DEFAULT NULL,
        p_sqlcode IN NUMBER DEFAULT NULL,
        p_sqlerrm IN VARCHAR2 DEFAULT NULL
    );

    -- ========================================================
    -- JSON Builder Helpers (used by audit triggers)
    -- ========================================================

    -- Build JSON for case_history row (trigger NEW/OLD values)
    FUNCTION build_case_history_json(
        p_receipt_number        IN VARCHAR2,
        p_created_at            IN TIMESTAMP,
        p_created_by            IN VARCHAR2,
        p_notes                 IN CLOB,
        p_is_active             IN NUMBER,
        p_last_checked_at       IN TIMESTAMP,
        p_check_frequency       IN NUMBER,
        p_notifications_enabled IN NUMBER
    ) RETURN CLOB;

    -- Build JSON for status_updates row (trigger NEW/OLD values)
    FUNCTION build_audit_json(
        p_id             IN NUMBER,
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2,
        p_current_status IN VARCHAR2,
        p_last_updated   IN TIMESTAMP,
        p_details        IN CLOB,
        p_source         IN VARCHAR2,
        p_created_at     IN TIMESTAMP
    ) RETURN CLOB;

END uscis_util_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_util_pkg AS

    -- --------------------------------------------------------
    -- validate_receipt_number
    -- --------------------------------------------------------
    FUNCTION validate_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF p_receipt_number IS NULL THEN
            RETURN FALSE;
        END IF;
        RETURN REGEXP_LIKE(UPPER(p_receipt_number), uscis_types_pkg.gc_receipt_pattern);
    END validate_receipt_number;
    
    -- --------------------------------------------------------
    -- assert_valid_receipt
    -- --------------------------------------------------------
    PROCEDURE assert_valid_receipt(
        p_receipt_number IN VARCHAR2
    ) IS
    BEGIN
        IF NOT validate_receipt_number(p_receipt_number) THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_invalid_receipt,
                'Invalid receipt number format: ' || NVL(mask_receipt_number(p_receipt_number), 'NULL') ||
                '. Expected format: 3 letters + 10 digits (e.g., IOE0912345678)'
            );
        END IF;
    END assert_valid_receipt;
    
    -- --------------------------------------------------------
    -- normalize_receipt_number
    -- --------------------------------------------------------
    FUNCTION normalize_receipt_number(
        p_input IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_input IS NULL THEN
            RETURN NULL;
        END IF;
        -- Remove all non-alphanumeric characters and uppercase
        RETURN UPPER(REGEXP_REPLACE(p_input, '[^A-Za-z0-9]', ''));
    END normalize_receipt_number;
    
    -- --------------------------------------------------------
    -- mask_receipt_number
    -- --------------------------------------------------------
    FUNCTION mask_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_len NUMBER := LENGTH(p_receipt_number);
    BEGIN
        IF p_receipt_number IS NULL THEN
            RETURN NULL;
        ELSIF l_len >= 7 THEN
            -- Show first 3 and last 4: IOE****5678
            RETURN SUBSTR(p_receipt_number, 1, 3) || '****' || SUBSTR(p_receipt_number, -4);
        ELSIF l_len >= 3 THEN
            RETURN SUBSTR(p_receipt_number, 1, 3) || '****';
        ELSE
            RETURN '****';
        END IF;
    END mask_receipt_number;
    
    -- --------------------------------------------------------
    -- get_service_center
    -- --------------------------------------------------------
    FUNCTION get_service_center(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_prefix VARCHAR2(3);
    BEGIN
        IF p_receipt_number IS NULL OR LENGTH(p_receipt_number) < 3 THEN
            RETURN NULL;
        END IF;
        
        l_prefix := UPPER(SUBSTR(p_receipt_number, 1, 3));
        
        RETURN CASE l_prefix
            WHEN 'IOE' THEN 'Online Filing'
            WHEN 'LIN' THEN 'Nebraska Service Center'
            WHEN 'WAC' THEN 'California Service Center'
            WHEN 'EAC' THEN 'Vermont Service Center'
            WHEN 'SRC' THEN 'Texas Service Center'
            WHEN 'MSC' THEN 'National Benefits Center'
            ELSE 'Unknown (' || l_prefix || ')'
        END;
    END get_service_center;
    
    -- --------------------------------------------------------
    -- get_config
    -- --------------------------------------------------------
    FUNCTION get_config(
        p_key     IN VARCHAR2,
        p_default IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(4000);
    BEGIN
        SELECT config_value 
        INTO l_value
        FROM scheduler_config
        WHERE config_key = UPPER(p_key);
        
        RETURN NVL(l_value, p_default);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN p_default;
    END get_config;
    
    -- --------------------------------------------------------
    -- get_config_number
    -- --------------------------------------------------------
    FUNCTION get_config_number(
        p_key     IN VARCHAR2,
        p_default IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_value VARCHAR2(4000);
    BEGIN
        l_value := get_config(p_key);
        IF l_value IS NULL THEN
            RETURN p_default;
        END IF;
        RETURN TO_NUMBER(l_value);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RETURN p_default;
    END get_config_number;
    
    -- --------------------------------------------------------
    -- get_config_boolean
    -- --------------------------------------------------------
    FUNCTION get_config_boolean(
        p_key     IN VARCHAR2,
        p_default IN BOOLEAN DEFAULT FALSE
    ) RETURN BOOLEAN IS
        l_value VARCHAR2(4000);
    BEGIN
        l_value := UPPER(get_config(p_key));
        IF l_value IS NULL THEN
            RETURN p_default;
        END IF;
        RETURN l_value IN ('Y', 'YES', 'TRUE', '1', 'ON');
    END get_config_boolean;
    
    -- --------------------------------------------------------
    -- set_config
    -- --------------------------------------------------------
    PROCEDURE set_config(
        p_key         IN VARCHAR2,
        p_value       IN VARCHAR2,
        p_description IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        MERGE INTO scheduler_config sc
        USING (SELECT UPPER(p_key) AS config_key FROM dual) src
        ON (sc.config_key = src.config_key)
        WHEN MATCHED THEN
            UPDATE SET 
                config_value = p_value, 
                description = NVL(p_description, sc.description),
                updated_at = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (config_key, config_value, description)
            VALUES (UPPER(p_key), p_value, p_description);
        COMMIT;
    END set_config;
    
    -- --------------------------------------------------------
    -- parse_iso_timestamp
    -- --------------------------------------------------------
    FUNCTION parse_iso_timestamp(
        p_timestamp_str IN VARCHAR2
    ) RETURN TIMESTAMP IS
        l_result TIMESTAMP;
    BEGIN
        IF p_timestamp_str IS NULL THEN
            RETURN NULL;
        END IF;
        
        -- Try common ISO formats
        BEGIN
            l_result := TO_TIMESTAMP(p_timestamp_str, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"');
            RETURN l_result;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        
        BEGIN
            l_result := TO_TIMESTAMP(p_timestamp_str, 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
            RETURN l_result;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        
        BEGIN
            l_result := TO_TIMESTAMP(p_timestamp_str, 'YYYY-MM-DD"T"HH24:MI:SS');
            RETURN l_result;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        
        BEGIN
            l_result := TO_TIMESTAMP(p_timestamp_str, 'YYYY-MM-DD HH24:MI:SS');
            RETURN l_result;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        
        -- If all else fails, try default
        RETURN TO_TIMESTAMP(p_timestamp_str);
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END parse_iso_timestamp;
    
    -- --------------------------------------------------------
    -- format_iso_timestamp
    -- Converts timestamp to UTC and formats as ISO 8601 with Z suffix
    -- --------------------------------------------------------
    FUNCTION format_iso_timestamp(
        p_timestamp IN TIMESTAMP
    ) RETURN VARCHAR2 IS
        l_utc_timestamp TIMESTAMP;
    BEGIN
        IF p_timestamp IS NULL THEN
            RETURN NULL;
        END IF;
        -- Convert to UTC before formatting so the Z suffix is correct
        l_utc_timestamp := SYS_EXTRACT_UTC(p_timestamp);
        RETURN TO_CHAR(l_utc_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
    END format_iso_timestamp;
    
    -- --------------------------------------------------------
    -- get_relative_time
    -- --------------------------------------------------------
    FUNCTION get_relative_time(
        p_timestamp IN TIMESTAMP
    ) RETURN VARCHAR2 IS
        l_interval    INTERVAL DAY TO SECOND;
        l_is_future   BOOLEAN := FALSE;
        l_total_mins  NUMBER;
        l_diff_days   NUMBER;
        l_diff_hours  NUMBER;
        l_diff_mins   NUMBER;
    BEGIN
        IF p_timestamp IS NULL THEN
            RETURN 'Unknown';
        END IF;
        
        l_interval := SYSTIMESTAMP - p_timestamp;
        
        -- Compute total minutes from the interval
        l_total_mins := EXTRACT(DAY FROM l_interval) * 1440 +
                        EXTRACT(HOUR FROM l_interval) * 60 +
                        EXTRACT(MINUTE FROM l_interval);
        
        -- Handle future timestamps (negative total minutes)
        IF l_total_mins < 0 THEN
            l_is_future := TRUE;
            l_total_mins := ABS(l_total_mins);
        END IF;
        
        -- Derive consistent days/hours/mins from positive total minutes
        l_diff_days := FLOOR(l_total_mins / 1440);
        l_diff_hours := FLOOR(MOD(l_total_mins, 1440) / 60);
        l_diff_mins := MOD(l_total_mins, 60);
        
        IF l_is_future THEN
            -- Future timestamp returns
            IF l_diff_days > 365 THEN
                RETURN 'In ' || FLOOR(l_diff_days / 365) || ' year' || 
                       CASE WHEN FLOOR(l_diff_days / 365) > 1 THEN 's' END;
            ELSIF l_diff_days > 30 THEN
                RETURN 'In ' || FLOOR(l_diff_days / 30) || ' month' || 
                       CASE WHEN FLOOR(l_diff_days / 30) > 1 THEN 's' END;
            ELSIF l_diff_days > 0 THEN
                RETURN 'In ' || l_diff_days || ' day' || 
                       CASE WHEN l_diff_days > 1 THEN 's' END;
            ELSIF l_diff_hours > 0 THEN
                RETURN 'In ' || l_diff_hours || ' hour' || 
                       CASE WHEN l_diff_hours > 1 THEN 's' END;
            ELSIF l_diff_mins > 0 THEN
                RETURN 'In ' || l_diff_mins || ' minute' || 
                       CASE WHEN l_diff_mins > 1 THEN 's' END;
            ELSE
                RETURN 'Just now';
            END IF;
        ELSE
            -- Past timestamp returns
            IF l_diff_days > 365 THEN
                RETURN FLOOR(l_diff_days / 365) || ' year' || 
                       CASE WHEN FLOOR(l_diff_days / 365) > 1 THEN 's' END || ' ago';
            ELSIF l_diff_days > 30 THEN
                RETURN FLOOR(l_diff_days / 30) || ' month' || 
                       CASE WHEN FLOOR(l_diff_days / 30) > 1 THEN 's' END || ' ago';
            ELSIF l_diff_days > 0 THEN
                RETURN l_diff_days || ' day' || 
                       CASE WHEN l_diff_days > 1 THEN 's' END || ' ago';
            ELSIF l_diff_hours > 0 THEN
                RETURN l_diff_hours || ' hour' || 
                       CASE WHEN l_diff_hours > 1 THEN 's' END || ' ago';
            ELSIF l_diff_mins > 0 THEN
                RETURN l_diff_mins || ' minute' || 
                       CASE WHEN l_diff_mins > 1 THEN 's' END || ' ago';
            ELSE
                RETURN 'Just now';
            END IF;
        END IF;
    END get_relative_time;
    
    -- --------------------------------------------------------
    -- get_current_user
    -- --------------------------------------------------------
    FUNCTION get_current_user RETURN VARCHAR2 IS
        l_user VARCHAR2(255);
    BEGIN
        -- Try APEX user first
        l_user := SYS_CONTEXT('APEX$SESSION', 'APP_USER');
        IF l_user IS NOT NULL THEN
            RETURN l_user;
        END IF;
        
        -- Fall back to database user
        RETURN SYS_CONTEXT('USERENV', 'SESSION_USER');
    END get_current_user;
    
    -- --------------------------------------------------------
    -- get_client_ip
    -- --------------------------------------------------------
    FUNCTION get_client_ip RETURN VARCHAR2 IS
        l_ip VARCHAR2(45);
    BEGIN
        -- Try APEX first
        l_ip := OWA_UTIL.get_cgi_env('REMOTE_ADDR');
        IF l_ip IS NOT NULL THEN
            RETURN l_ip;
        END IF;
        
        -- Fall back to session context
        RETURN SYS_CONTEXT('USERENV', 'IP_ADDRESS');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SYS_CONTEXT('USERENV', 'IP_ADDRESS');
    END get_client_ip;
    
    -- --------------------------------------------------------
    -- get_session_id
    -- --------------------------------------------------------
    FUNCTION get_session_id RETURN NUMBER IS
    BEGIN
        RETURN NVL(APEX_APPLICATION.g_instance, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_session_id;
    
    -- --------------------------------------------------------
    -- get_app_id
    -- --------------------------------------------------------
    FUNCTION get_app_id RETURN NUMBER IS
    BEGIN
        RETURN NVL(APEX_APPLICATION.g_flow_id, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_app_id;
    
    -- --------------------------------------------------------
    -- json_escape
    -- Escapes a string for safe inclusion in JSON values.
    -- Handles backslash, quotes, and all control characters (0-31).
    -- Returns CLOB to handle expansion from control char escaping.
    -- --------------------------------------------------------
    FUNCTION json_escape(
        p_string IN VARCHAR2
    ) RETURN CLOB IS
        l_result CLOB;
    BEGIN
        IF p_string IS NULL THEN
            RETURN NULL;
        END IF;
        
        -- Initialize CLOB with input string
        l_result := TO_CLOB(p_string);
        
        -- First escape backslash (must be first)
        l_result := REPLACE(l_result, '\', '\\');
        -- Escape double quotes
        l_result := REPLACE(l_result, '"', '\"');
        -- Standard escapes for common control characters
        l_result := REPLACE(l_result, CHR(8), '\b');   -- Backspace
        l_result := REPLACE(l_result, CHR(9), '\t');   -- Tab
        l_result := REPLACE(l_result, CHR(10), '\n');  -- Newline
        l_result := REPLACE(l_result, CHR(12), '\f');  -- Form feed
        l_result := REPLACE(l_result, CHR(13), '\r');  -- Carriage return
        
        -- Escape remaining control characters (0-31) as Unicode escapes
        FOR i IN 0..31 LOOP
            -- Skip already handled characters
            IF i NOT IN (8, 9, 10, 12, 13) THEN
                l_result := REPLACE(l_result, CHR(i), 
                    '\u00' || LPAD(TRIM(TO_CHAR(i, 'XX')), 2, '0'));
            END IF;
        END LOOP;
        
        RETURN l_result;
    END json_escape;
    
    -- --------------------------------------------------------
    -- json_escape_varchar2
    -- VARCHAR2 overload for backward compatibility
    -- --------------------------------------------------------
    FUNCTION json_escape_varchar2(
        p_string IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_clob CLOB;
    BEGIN
        IF p_string IS NULL THEN
            RETURN NULL;
        END IF;
        
        l_clob := json_escape(p_string);
        
        -- Safely convert CLOB to VARCHAR2, truncating if needed
        IF DBMS_LOB.GETLENGTH(l_clob) > 32767 THEN
            RETURN DBMS_LOB.SUBSTR(l_clob, 32767, 1);
        ELSE
            RETURN TO_CHAR(l_clob);
        END IF;
    END json_escape_varchar2;
    
    -- --------------------------------------------------------
    -- build_json
    -- --------------------------------------------------------
    FUNCTION build_json(
        p_keys   IN uscis_types_pkg.t_string_tab,
        p_values IN uscis_types_pkg.t_string_tab
    ) RETURN CLOB IS
        l_json CLOB := '{';
        l_first BOOLEAN := TRUE;
    BEGIN
        IF p_keys IS NULL OR p_values IS NULL THEN
            RETURN '{}';
        END IF;
        
        FOR i IN 1..LEAST(p_keys.COUNT, p_values.COUNT) LOOP
            IF NOT l_first THEN
                l_json := l_json || ',';
            END IF;
            l_first := FALSE;
            l_json := l_json || '"' || json_escape(p_keys(i)) || '":"' || json_escape(p_values(i)) || '"';
        END LOOP;
        
        RETURN l_json || '}';
    END build_json;
    
    -- --------------------------------------------------------
    -- log_debug
    -- --------------------------------------------------------
    PROCEDURE log_debug(
        p_message IN VARCHAR2,
        p_module  IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || ' [DEBUG] ' ||
            CASE WHEN p_module IS NOT NULL THEN '[' || p_module || '] ' END ||
            p_message
        );
    END log_debug;
    
    -- --------------------------------------------------------
    -- log_error
    -- --------------------------------------------------------
    PROCEDURE log_error(
        p_message IN VARCHAR2,
        p_module  IN VARCHAR2 DEFAULT NULL,
        p_sqlcode IN NUMBER DEFAULT NULL,
        p_sqlerrm IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3') || ' [ERROR] ' ||
            CASE WHEN p_module IS NOT NULL THEN '[' || p_module || '] ' END ||
            p_message ||
            CASE WHEN p_sqlcode IS NOT NULL THEN ' (SQLCODE: ' || p_sqlcode || ')' END ||
            CASE WHEN p_sqlerrm IS NOT NULL THEN ' - ' || p_sqlerrm END
        );
    END log_error;

    -- --------------------------------------------------------
    -- Private JSON builder helpers (shared by build_case_history_json and build_audit_json)
    -- --------------------------------------------------------
    PROCEDURE json_append_raw(
        p_clob  IN OUT NOCOPY CLOB,
        p_chunk IN VARCHAR2
    ) IS
    BEGIN
        DBMS_LOB.APPEND(p_clob, p_chunk);
    END json_append_raw;

    PROCEDURE json_add_string(
        p_clob      IN OUT NOCOPY CLOB,
        p_has_value IN OUT NOCOPY BOOLEAN,
        p_key       IN VARCHAR2,
        p_value     IN VARCHAR2
    ) IS
    BEGIN
        IF p_value IS NULL THEN RETURN; END IF;
        IF p_has_value THEN json_append_raw(p_clob, ','); END IF;
        json_append_raw(p_clob, '"' || p_key || '":"' || json_escape_varchar2(p_value) || '"');
        p_has_value := TRUE;
    END json_add_string;

    PROCEDURE json_add_number(
        p_clob      IN OUT NOCOPY CLOB,
        p_has_value IN OUT NOCOPY BOOLEAN,
        p_key       IN VARCHAR2,
        p_value     IN NUMBER
    ) IS
    BEGIN
        IF p_value IS NULL THEN RETURN; END IF;
        IF p_has_value THEN json_append_raw(p_clob, ','); END IF;
        json_append_raw(p_clob, '"' || p_key || '":' || TO_CHAR(p_value, 'FM999999999990D999999999', 'NLS_NUMERIC_CHARACTERS = ''.'''));
        p_has_value := TRUE;
    END json_add_number;

    -- --------------------------------------------------------
    -- build_case_history_json
    -- --------------------------------------------------------
    FUNCTION build_case_history_json(
        p_receipt_number        IN VARCHAR2,
        p_created_at            IN TIMESTAMP,
        p_created_by            IN VARCHAR2,
        p_notes                 IN CLOB,
        p_is_active             IN NUMBER,
        p_last_checked_at       IN TIMESTAMP,
        p_check_frequency       IN NUMBER,
        p_notifications_enabled IN NUMBER
    ) RETURN CLOB IS
        l_json      CLOB;
        l_has_value BOOLEAN := FALSE;
        l_notes     VARCHAR2(500);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(l_json, TRUE);
        json_append_raw(l_json, '{');

        json_add_string(l_json, l_has_value, 'receipt_number', p_receipt_number);
        json_add_string(l_json, l_has_value, 'created_at', format_iso_timestamp(p_created_at));
        json_add_string(l_json, l_has_value, 'created_by', p_created_by);
        l_notes := DBMS_LOB.SUBSTR(p_notes, 500, 1);
        json_add_string(l_json, l_has_value, 'notes', l_notes);
        json_add_number(l_json, l_has_value, 'is_active', p_is_active);
        json_add_string(l_json, l_has_value, 'last_checked_at', format_iso_timestamp(p_last_checked_at));
        json_add_number(l_json, l_has_value, 'check_frequency', p_check_frequency);
        json_add_number(l_json, l_has_value, 'notifications_enabled', p_notifications_enabled);

        json_append_raw(l_json, '}');
        RETURN l_json;
    END build_case_history_json;

    -- --------------------------------------------------------
    -- build_audit_json
    -- --------------------------------------------------------
    FUNCTION build_audit_json(
        p_id             IN NUMBER,
        p_receipt_number IN VARCHAR2,
        p_case_type      IN VARCHAR2,
        p_current_status IN VARCHAR2,
        p_last_updated   IN TIMESTAMP,
        p_details        IN CLOB,
        p_source         IN VARCHAR2,
        p_created_at     IN TIMESTAMP
    ) RETURN CLOB IS
        l_json      CLOB;
        l_has_value BOOLEAN := FALSE;
        l_details   VARCHAR2(500);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(l_json, TRUE);
        json_append_raw(l_json, '{');

        json_add_number(l_json, l_has_value, 'id', p_id);
        json_add_string(l_json, l_has_value, 'receipt_number', p_receipt_number);
        json_add_string(l_json, l_has_value, 'case_type', p_case_type);
        json_add_string(l_json, l_has_value, 'current_status', p_current_status);
        json_add_string(l_json, l_has_value, 'last_updated', format_iso_timestamp(p_last_updated));
        l_details := DBMS_LOB.SUBSTR(p_details, 500, 1);
        json_add_string(l_json, l_has_value, 'details', l_details);
        json_add_string(l_json, l_has_value, 'source', p_source);
        json_add_string(l_json, l_has_value, 'created_at', format_iso_timestamp(p_created_at));

        json_append_raw(l_json, '}');
        RETURN l_json;
    END build_audit_json;

END uscis_util_pkg;
/

SHOW ERRORS PACKAGE uscis_util_pkg
SHOW ERRORS PACKAGE BODY uscis_util_pkg

PROMPT ============================================================
PROMPT USCIS_UTIL_PKG created successfully
PROMPT ============================================================
