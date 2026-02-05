-- ============================================================
-- USCIS Case Tracker - API Integration Package
-- Task 1.3.5: USCIS_API_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/06_uscis_api_pkg.sql
-- Purpose: USCIS API integration with rate limiting
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG, USCIS_OAUTH_PKG, USCIS_CASE_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_API_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_api_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_API_PKG';
    
    -- ========================================================
    -- Exception Definitions
    -- ========================================================
    e_api_error         EXCEPTION;
    e_rate_limited      EXCEPTION;
e_invalid_response  EXCEPTION;
    e_resource_busy   EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_api_error, -20020);
    PRAGMA EXCEPTION_INIT(e_rate_limited, -20021);
    PRAGMA EXCEPTION_INIT(e_invalid_response, -20022);
    PRAGMA EXCEPTION_INIT(e_resource_busy, -00054);
    
    -- ========================================================
    -- API Call Functions
    -- ========================================================
    
    -- Check case status from USCIS API
    FUNCTION check_case_status(
        p_receipt_number   IN VARCHAR2,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- Check case status (returns JSON)
    FUNCTION check_case_status_json(
        p_receipt_number   IN VARCHAR2,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB;
    
    -- Check multiple cases with rate limiting
    PROCEDURE check_multiple_cases(
        p_receipt_numbers  IN uscis_types_pkg.t_receipt_tab,
        p_save_to_database IN BOOLEAN DEFAULT TRUE,
        p_stop_on_error    IN BOOLEAN DEFAULT FALSE
    );
    
    -- ========================================================
    -- Rate Limiting Functions
    -- ========================================================
    
    -- Apply rate limiting (waits if necessary)
    PROCEDURE apply_rate_limit;
    
    -- Check if we can make a request now (performs atomic update)
    FUNCTION can_request_now RETURN BOOLEAN;
    
    -- Check if we can make a request now (read-only, no side effects)
    FUNCTION can_request_now_readonly RETURN BOOLEAN;
    
    -- Get current rate limit status
    FUNCTION get_rate_limit_status RETURN CLOB;
    
    -- Reset rate limiter (for testing)
    PROCEDURE reset_rate_limiter;
    
    -- ========================================================
    -- Mock/Test Functions
    -- ========================================================
    
    -- Get mock response (when API not configured)
    FUNCTION get_mock_response(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- Check if mock mode is enabled
    FUNCTION is_mock_mode RETURN BOOLEAN;
    
    -- ========================================================
    -- Response Parsing Functions
    -- ========================================================
    
    -- Parse API response JSON to record
    FUNCTION parse_api_response(
        p_json_response IN CLOB
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- ========================================================
    -- Configuration Functions
    -- ========================================================
    
    -- Get API base URL
    FUNCTION get_api_base_url RETURN VARCHAR2;
    
    -- Check if API is configured
    FUNCTION is_api_configured RETURN BOOLEAN;

END uscis_api_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_api_pkg AS

    -- --------------------------------------------------------
    -- Private: Record API request for rate limiting
    -- --------------------------------------------------------
    PROCEDURE record_request IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        MERGE INTO api_rate_limiter arl
        USING (SELECT uscis_types_pkg.gc_service_uscis AS service_name FROM dual) src
        ON (arl.service_name = src.service_name)
        WHEN MATCHED THEN
            UPDATE SET 
                last_request_at = SYSTIMESTAMP,
                request_count = request_count + 1
        WHEN NOT MATCHED THEN
            INSERT (service_name, last_request_at, request_count, window_start)
            VALUES (src.service_name, SYSTIMESTAMP, 1, SYSTIMESTAMP);
        
        COMMIT;
    END record_request;
    
    -- --------------------------------------------------------
    -- Private: Get seconds since last request
    -- --------------------------------------------------------
    FUNCTION get_seconds_since_last_request RETURN NUMBER IS
        l_last_request TIMESTAMP;
        l_diff         INTERVAL DAY TO SECOND;
    BEGIN
        SELECT last_request_at
        INTO l_last_request
        FROM api_rate_limiter
        WHERE service_name = uscis_types_pkg.gc_service_uscis;
        
        IF l_last_request IS NULL THEN
            RETURN 999999;  -- No previous request
        END IF;
        
        l_diff := SYSTIMESTAMP - l_last_request;
        
        RETURN EXTRACT(DAY FROM l_diff) * 86400 +
               EXTRACT(HOUR FROM l_diff) * 3600 +
               EXTRACT(MINUTE FROM l_diff) * 60 +
               EXTRACT(SECOND FROM l_diff);
               
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 999999;
    END get_seconds_since_last_request;
    
    -- --------------------------------------------------------
    -- can_request_now
    -- Atomic check-and-update to avoid TOCTOU race condition.
    -- Uses SELECT FOR UPDATE SKIP LOCKED to acquire row lock.
    -- --------------------------------------------------------
    FUNCTION can_request_now RETURN BOOLEAN IS
        l_min_interval_ms NUMBER;
        l_min_interval_s  NUMBER;
        l_last_request    TIMESTAMP;
        l_diff            INTERVAL DAY TO SECOND;
        l_secs_since      NUMBER;
        l_can_request     BOOLEAN := FALSE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        l_min_interval_ms := uscis_util_pkg.get_config_number('RATE_LIMIT_MIN_INTERVAL_MS', 100);
        l_min_interval_s := l_min_interval_ms / 1000;
        
-- Atomic check-and-update with row lock
        BEGIN
            SELECT last_request_at
            INTO l_last_request
            FROM api_rate_limiter
            WHERE service_name = uscis_types_pkg.gc_service_uscis
            FOR UPDATE SKIP LOCKED;

            IF l_last_request IS NULL THEN
                l_secs_since := 999999;
            ELSE
                l_diff := SYSTIMESTAMP - l_last_request;
                l_secs_since := EXTRACT(DAY FROM l_diff) * 86400 +
                               EXTRACT(HOUR FROM l_diff) * 3600 +
                               EXTRACT(MINUTE FROM l_diff) * 60 +
                               EXTRACT(SECOND FROM l_diff);
            END IF;

            IF l_secs_since >= l_min_interval_s THEN
                -- Update timestamp atomically while we hold the lock
                UPDATE api_rate_limiter
                SET last_request_at = SYSTIMESTAMP,
                    request_count = request_count + 1
                WHERE service_name = uscis_types_pkg.gc_service_uscis;
                l_can_request := TRUE;
            END IF;

            COMMIT;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Initialize rate limiter row, handle potential race with DUP_VAL_ON_INDEX
                BEGIN
                    INSERT INTO api_rate_limiter (service_name, last_request_at, request_count, window_start)
                    VALUES (uscis_types_pkg.gc_service_uscis, SYSTIMESTAMP, 1, SYSTIMESTAMP);
                    COMMIT;
                    l_can_request := TRUE;
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                        -- Another session inserted first; retry select/update
                        COMMIT;  -- Release any locks
                        BEGIN
                            SELECT last_request_at
                            INTO l_last_request
                            FROM api_rate_limiter
                            WHERE service_name = uscis_types_pkg.gc_service_uscis
                            FOR UPDATE NOWAIT;

                            UPDATE api_rate_limiter
                            SET last_request_at = SYSTIMESTAMP,
                                request_count = request_count + 1
                            WHERE service_name = uscis_types_pkg.gc_service_uscis;
                            COMMIT;
                            l_can_request := TRUE;
                        EXCEPTION
WHEN e_resource_busy THEN
                -- Row locked by another session, rate limit should be enforced
                COMMIT;
                l_can_request := FALSE;
            WHEN OTHERS THEN
                -- Re-raise other exceptions to avoid masking errors
                RAISE;
                        END;
                END;
        END;
        
        RETURN l_can_request;
    END can_request_now;
    
    -- --------------------------------------------------------
    -- can_request_now_readonly
    -- Read-only check if a request can be made (no side effects)
    -- --------------------------------------------------------
    FUNCTION can_request_now_readonly RETURN BOOLEAN IS
        l_min_interval_ms NUMBER;
        l_min_interval_s  NUMBER;
        l_last_request    TIMESTAMP;
        l_diff            INTERVAL DAY TO SECOND;
        l_secs_since      NUMBER;
    BEGIN
        l_min_interval_ms := uscis_util_pkg.get_config_number('RATE_LIMIT_MIN_INTERVAL_MS', 100);
        l_min_interval_s := l_min_interval_ms / 1000;
        
        BEGIN
            SELECT last_request_at
            INTO l_last_request
            FROM api_rate_limiter
            WHERE service_name = uscis_types_pkg.gc_service_uscis;
            
            IF l_last_request IS NULL THEN
                RETURN TRUE;
            END IF;
            
            l_diff := SYSTIMESTAMP - l_last_request;
            l_secs_since := EXTRACT(DAY FROM l_diff) * 86400 +
                           EXTRACT(HOUR FROM l_diff) * 3600 +
                           EXTRACT(MINUTE FROM l_diff) * 60 +
                           EXTRACT(SECOND FROM l_diff);
            
            RETURN l_secs_since >= l_min_interval_s;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN TRUE;  -- No rate limiter row, can request
        END;
    END can_request_now_readonly;
    
    -- --------------------------------------------------------
    -- apply_rate_limit
    -- --------------------------------------------------------
    PROCEDURE apply_rate_limit IS
        l_min_interval_ms NUMBER;
        l_secs_since      NUMBER;
        l_wait_secs       NUMBER;
    BEGIN
        l_min_interval_ms := uscis_util_pkg.get_config_number('RATE_LIMIT_MIN_INTERVAL_MS', 100);
        l_secs_since := get_seconds_since_last_request;
        l_wait_secs := (l_min_interval_ms / 1000) - l_secs_since;
        
        IF l_wait_secs > 0 THEN
            uscis_util_pkg.log_debug(
                'Rate limiting: waiting ' || ROUND(l_wait_secs * 1000) || 'ms',
                gc_package_name
            );
            DBMS_SESSION.SLEEP(l_wait_secs);
        END IF;
    END apply_rate_limit;
    
    -- --------------------------------------------------------
    -- get_rate_limit_status
    -- --------------------------------------------------------
    FUNCTION get_rate_limit_status RETURN CLOB IS
        l_json CLOB;
        l_can_request BOOLEAN;
        l_can_request_str VARCHAR2(5);
        l_secs_since NUMBER;
    BEGIN
        -- Use read-only check to avoid side effects
        l_can_request := can_request_now_readonly;
        l_can_request_str := CASE WHEN l_can_request THEN 'true' ELSE 'false' END;
        l_secs_since := get_seconds_since_last_request;
        
        SELECT JSON_OBJECT(
            'service_name' VALUE service_name,
            'last_request_at' VALUE TO_CHAR(SYS_EXTRACT_UTC(last_request_at), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'request_count' VALUE request_count,
            'seconds_since_request' VALUE ROUND(l_secs_since, 2),
            'can_request_now' VALUE l_can_request_str FORMAT JSON
        )
        INTO l_json
        FROM api_rate_limiter
        WHERE service_name = uscis_types_pkg.gc_service_uscis;
        
        RETURN l_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"service_name":"' || uscis_types_pkg.gc_service_uscis || '","request_count":0,"can_request_now":true}';
    END get_rate_limit_status;
    
    -- --------------------------------------------------------
    -- reset_rate_limiter
    -- --------------------------------------------------------
    PROCEDURE reset_rate_limiter IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE api_rate_limiter
        SET request_count = 0,
            window_start = SYSTIMESTAMP,
            last_request_at = SYSTIMESTAMP - INTERVAL '1' HOUR
        WHERE service_name = uscis_types_pkg.gc_service_uscis;
        
        COMMIT;
    END reset_rate_limiter;
    
    -- --------------------------------------------------------
    -- get_api_base_url
    -- --------------------------------------------------------
    FUNCTION get_api_base_url RETURN VARCHAR2 IS
    BEGIN
        RETURN uscis_util_pkg.get_config(
            'USCIS_API_BASE_URL',
            'https://api-int.uscis.gov/case-status'
        );
    END get_api_base_url;
    
    -- --------------------------------------------------------
    -- is_api_configured
    -- --------------------------------------------------------
    FUNCTION is_api_configured RETURN BOOLEAN IS
    BEGIN
        RETURN uscis_oauth_pkg.has_credentials;
    END is_api_configured;
    
    -- --------------------------------------------------------
    -- is_mock_mode
    -- --------------------------------------------------------
    FUNCTION is_mock_mode RETURN BOOLEAN IS
    BEGIN
        -- Mock mode if API not configured or explicitly enabled
        IF NOT is_api_configured THEN
            RETURN TRUE;
        END IF;
        
        RETURN uscis_util_pkg.get_config_boolean('USE_MOCK_API', FALSE);
    END is_mock_mode;
    
    -- --------------------------------------------------------
    -- get_mock_response
    -- --------------------------------------------------------
    FUNCTION get_mock_response(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status IS
        l_status uscis_types_pkg.t_case_status;
        l_rand   NUMBER;
    BEGIN
        l_rand := MOD(ABS(DBMS_RANDOM.RANDOM), 5);
        
        l_status.receipt_number := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        l_status.last_updated := SYSTIMESTAMP - NUMTODSINTERVAL(MOD(ABS(DBMS_RANDOM.RANDOM), 30), 'DAY');
        
        -- Random case type based on prefix
        CASE SUBSTR(l_status.receipt_number, 1, 3)
            WHEN 'IOE' THEN l_status.case_type := CASE MOD(l_rand, 3) 
                WHEN 0 THEN 'I-485' WHEN 1 THEN 'I-765' ELSE 'I-131' END;
            WHEN 'LIN' THEN l_status.case_type := 'I-140';
            WHEN 'WAC' THEN l_status.case_type := 'I-129';
            ELSE l_status.case_type := 'I-130';
        END CASE;
        
        -- Random status
        l_status.current_status := CASE l_rand
            WHEN 0 THEN 'Case Was Received'
            WHEN 1 THEN 'Case Is Being Actively Reviewed By USCIS'
            WHEN 2 THEN 'Request for Additional Evidence Was Sent'
            WHEN 3 THEN 'Case Was Approved'
            ELSE 'New Card Is Being Produced'
        END;
        
        l_status.details := 'On ' || TO_CHAR(l_status.last_updated, 'Month DD, YYYY') || 
            ', ' || l_status.current_status || ' for Form ' || l_status.case_type || 
            '. (MOCK RESPONSE - API not configured)';
        
        RETURN l_status;
    END get_mock_response;
    
    -- --------------------------------------------------------
    -- parse_api_response
    -- --------------------------------------------------------
    FUNCTION parse_api_response(
        p_json_response IN CLOB
    ) RETURN uscis_types_pkg.t_case_status IS
        l_status uscis_types_pkg.t_case_status;
    BEGIN
        IF p_json_response IS NULL THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_invalid_json,
                'Empty API response'
            );
        END IF;
        
        -- Parse JSON using JSON_VALUE
        BEGIN
            SELECT 
                JSON_VALUE(p_json_response, '$.receiptNumber'),
                JSON_VALUE(p_json_response, '$.formType'),
                JSON_VALUE(p_json_response, '$.status'),
                uscis_util_pkg.parse_iso_timestamp(JSON_VALUE(p_json_response, '$.lastUpdatedDate')),
                JSON_VALUE(p_json_response, '$.statusDescription')
            INTO 
                l_status.receipt_number,
                l_status.case_type,
                l_status.current_status,
                l_status.last_updated,
                l_status.details
            FROM dual;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_invalid_json,
                    'Failed to parse API response: ' || SQLERRM
                );
        END;
        
        -- Use timestamp if not parsed
        IF l_status.last_updated IS NULL THEN
            l_status.last_updated := SYSTIMESTAMP;
        END IF;
        
        RETURN l_status;
    END parse_api_response;
    
    -- --------------------------------------------------------
    -- Private: Call USCIS API
    -- --------------------------------------------------------
    FUNCTION call_uscis_api(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_api_result IS
        l_result        uscis_types_pkg.t_api_result;
        l_url           VARCHAR2(1000);
        l_token         VARCHAR2(4000);
        l_start_time    TIMESTAMP;
        l_retry_count   NUMBER := 0;
        l_max_retries   CONSTANT NUMBER := 10;
        l_backoff_ms    NUMBER := 100;
    BEGIN
        l_start_time := SYSTIMESTAMP;
        l_result.success := FALSE;
        
        -- Atomically acquire rate limit slot with backoff loop
        WHILE NOT can_request_now LOOP
            l_retry_count := l_retry_count + 1;
            IF l_retry_count > l_max_retries THEN
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_rate_limited,
                    'Rate limit slot not available after ' || l_max_retries || ' retries'
                );
            END IF;
            uscis_util_pkg.log_debug(
                'Rate limiting: waiting ' || l_backoff_ms || 'ms (attempt ' || l_retry_count || ')',
                gc_package_name
            );
            DBMS_SESSION.SLEEP(l_backoff_ms / 1000);
            -- Exponential backoff with cap
            l_backoff_ms := LEAST(l_backoff_ms * 2, 1000);
        END LOOP;
        
        -- Get OAuth token
        l_token := uscis_oauth_pkg.get_access_token;
        
        -- Build URL
        l_url := get_api_base_url || '/' || p_receipt_number;
        
        -- Set headers
        APEX_WEB_SERVICE.g_request_headers.DELETE;
        APEX_WEB_SERVICE.g_request_headers(1).name := 'Authorization';
        APEX_WEB_SERVICE.g_request_headers(1).value := 'Bearer ' || l_token;
        APEX_WEB_SERVICE.g_request_headers(2).name := 'Accept';
        APEX_WEB_SERVICE.g_request_headers(2).value := 'application/json';
        
        -- Make request
        l_result.data := APEX_WEB_SERVICE.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET'
        );
        
        l_result.http_status := APEX_WEB_SERVICE.g_status_code;
        
        -- Note: request already recorded by can_request_now (atomic increment)
        
        -- Calculate response time
        l_result.response_time_ms := ROUND(
            EXTRACT(SECOND FROM (SYSTIMESTAMP - l_start_time)) * 1000 +
            EXTRACT(MINUTE FROM (SYSTIMESTAMP - l_start_time)) * 60000 +
            EXTRACT(HOUR FROM (SYSTIMESTAMP - l_start_time)) * 3600000
        );
        
        -- Check response status
        IF l_result.http_status = 200 THEN
            l_result.success := TRUE;
        ELSIF l_result.http_status = 429 THEN
            l_result.error_message := 'Rate limited by USCIS API';
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_rate_limited,
                l_result.error_message
            );
        ELSIF l_result.http_status = 401 THEN
            -- Token may be invalid, clear it
            uscis_oauth_pkg.clear_token;
            l_result.error_message := 'Authentication failed';
        ELSE
            l_result.error_message := 'API returned status ' || l_result.http_status;
        END IF;
        
        RETURN l_result;
        
    EXCEPTION
        WHEN e_rate_limited THEN
            RAISE;  -- Propagate rate limit exceptions
        WHEN OTHERS THEN
            l_result.success := FALSE;
            l_result.error_message := SQLERRM;
            l_result.http_status := -1;
            RETURN l_result;
    END call_uscis_api;
    
    -- --------------------------------------------------------
    -- check_case_status
    -- --------------------------------------------------------
    FUNCTION check_case_status(
        p_receipt_number   IN VARCHAR2,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) RETURN uscis_types_pkg.t_case_status IS
        l_receipt VARCHAR2(13);
        l_status  uscis_types_pkg.t_case_status;
        l_result  uscis_types_pkg.t_api_result;
    BEGIN
        -- Normalize and validate
        l_receipt := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        uscis_util_pkg.assert_valid_receipt(l_receipt);
        
        -- Use mock mode if API not configured
        IF is_mock_mode THEN
            uscis_util_pkg.log_debug('Using mock response (API not configured)', gc_package_name);
            l_status := get_mock_response(l_receipt);
        ELSE
            -- Call real API
            l_result := call_uscis_api(l_receipt);
            
            IF NOT l_result.success THEN
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_api_error,
                    'USCIS API error: ' || l_result.error_message
                );
            END IF;
            
            l_status := parse_api_response(l_result.data);
        END IF;
        
        -- Save to database if requested
        IF p_save_to_database THEN
            uscis_case_pkg.add_or_update_case(
                p_receipt_number => l_status.receipt_number,
                p_case_type      => l_status.case_type,
                p_current_status => l_status.current_status,
                p_last_updated   => l_status.last_updated,
                p_details        => l_status.details,
                p_source         => uscis_types_pkg.gc_source_api,
                p_api_response_json => CASE WHEN NOT is_mock_mode THEN l_result.data END
            );
            
            -- Update last checked time
            uscis_case_pkg.update_last_checked(l_receipt);
            
            -- Log the check
            uscis_audit_pkg.log_check(l_receipt, 'API', l_status.current_status);
        END IF;
        
        RETURN l_status;
        
    EXCEPTION
        WHEN OTHERS THEN
            uscis_util_pkg.log_error(
                'check_case_status failed for ' || uscis_util_pkg.mask_receipt_number(l_receipt),
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
            RAISE;
    END check_case_status;
    
-- --------------------------------------------------------
-- check_case_status_json
-- --------------------------------------------------------
FUNCTION check_case_status_json(
    p_receipt_number   IN VARCHAR2,
    p_save_to_database IN BOOLEAN DEFAULT TRUE
) RETURN CLOB IS
    l_status uscis_types_pkg.t_case_status;
    l_json   CLOB;
BEGIN
    l_status := check_case_status(p_receipt_number, p_save_to_database);
SELECT JSON_OBJECT(
    'receipt_number' VALUE l_status.receipt_number,
    'case_type' VALUE l_status.case_type,
    'current_status' VALUE l_status.current_status,
    'last_updated' VALUE TO_CHAR(SYS_EXTRACT_UTC(l_status.last_updated), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'details' VALUE SUBSTR(l_status.details, 1, 1000)
) INTO l_json FROM dual;
    RETURN l_json;
END check_case_status_json;
    
    -- --------------------------------------------------------
    -- check_multiple_cases
    -- --------------------------------------------------------
    PROCEDURE check_multiple_cases(
        p_receipt_numbers  IN uscis_types_pkg.t_receipt_tab,
        p_save_to_database IN BOOLEAN DEFAULT TRUE,
        p_stop_on_error    IN BOOLEAN DEFAULT FALSE
    ) IS
        l_status uscis_types_pkg.t_case_status;
        l_count  NUMBER := 0;
        l_errors NUMBER := 0;
    BEGIN
        IF p_receipt_numbers IS NULL OR p_receipt_numbers.COUNT = 0 THEN
            RETURN;
        END IF;
        
        uscis_util_pkg.log_debug(
            'Checking ' || p_receipt_numbers.COUNT || ' cases',
            gc_package_name
        );
        
        FOR i IN 1..p_receipt_numbers.COUNT LOOP
            BEGIN
                l_status := check_case_status(
                    p_receipt_number   => p_receipt_numbers(i),
                    p_save_to_database => p_save_to_database
                );
                l_count := l_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    uscis_util_pkg.log_error(
                        'Error checking case ' || uscis_util_pkg.mask_receipt_number(p_receipt_numbers(i)) || ': ' || SQLERRM,
                        gc_package_name
                    );
                    l_errors := l_errors + 1;
                    
                    IF p_stop_on_error THEN
                        RAISE;
                    END IF;
            END;
        END LOOP;
        
        uscis_util_pkg.log_debug(
            'Completed: ' || l_count || ' successful, ' || l_errors || ' errors',
            gc_package_name
        );
    END check_multiple_cases;

END uscis_api_pkg;
/

SHOW ERRORS PACKAGE uscis_api_pkg
SHOW ERRORS PACKAGE BODY uscis_api_pkg

PROMPT ============================================================
PROMPT USCIS_API_PKG created successfully
PROMPT ============================================================
