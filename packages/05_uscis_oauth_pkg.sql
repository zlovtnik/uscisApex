-- ============================================================
-- USCIS Case Tracker - OAuth Package
-- Task 1.3.4: USCIS_OAUTH_PKG Specification & Body
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/05_uscis_oauth_pkg.sql
-- Purpose: OAuth2 token management for USCIS API
-- Dependencies: USCIS_TYPES_PKG, USCIS_UTIL_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_OAUTH_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_oauth_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_OAUTH_PKG';
    gc_default_service  CONSTANT VARCHAR2(30) := 'USCIS_API';
    gc_default_token_url CONSTANT VARCHAR2(200) := 'https://api-int.uscis.gov/oauth/accesstoken';
    
    -- ========================================================
    -- Exception Definitions
    -- ========================================================
    e_auth_failed       EXCEPTION;
    e_credentials_missing EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_auth_failed, -20010);
    PRAGMA EXCEPTION_INIT(e_credentials_missing, -20011);
    
    -- ========================================================
    -- Token Management Functions
    -- ========================================================
    
    -- Get valid access token (fetches new one if expired/missing)
    FUNCTION get_access_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN VARCHAR2;
    
    -- Fetch new token from OAuth server
    -- @param p_service_name Optional service name for token storage (defaults to USCIS_API)
    FUNCTION fetch_new_token(
        p_client_id     IN VARCHAR2,
        p_client_secret IN VARCHAR2,
        p_token_url     IN VARCHAR2 DEFAULT NULL,
        p_service_name  IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN VARCHAR2;
    
    -- Check if current token is valid (not expired)
    FUNCTION is_token_valid(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN BOOLEAN;
    
    -- Get token expiration time
    FUNCTION get_token_expiry(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN TIMESTAMP;
    
    -- Get minutes until token expires
    FUNCTION get_minutes_until_expiry(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN NUMBER;
    
    -- ========================================================
    -- Token Maintenance Procedures
    -- ========================================================
    
    -- Clear cached token (force refresh on next request)
    PROCEDURE clear_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    );
    
    -- Refresh token proactively (before expiration)
    PROCEDURE refresh_token_if_needed(
        p_service_name    IN VARCHAR2 DEFAULT 'USCIS_API',
        p_buffer_seconds  IN NUMBER DEFAULT 60
    );
    
    -- Update last used timestamp
    PROCEDURE mark_token_used(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    );
    
    -- ========================================================
    -- Credential Functions
    -- ========================================================
    
    -- Check if OAuth credentials are configured
    FUNCTION has_credentials RETURN BOOLEAN;
    
    -- Get OAuth token URL from config
    FUNCTION get_token_url RETURN VARCHAR2;
    
    -- Validate credentials (attempts token fetch)
    FUNCTION validate_credentials(
        p_client_id     IN VARCHAR2,
        p_client_secret IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- ========================================================
    -- Status Functions
    -- ========================================================
    
    -- Get token status info (as JSON)
    FUNCTION get_token_status(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN CLOB;

END uscis_oauth_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_oauth_pkg AS

    -- --------------------------------------------------------
    -- Private: Save token to database
    -- --------------------------------------------------------
    PROCEDURE save_token(
        p_service_name  IN VARCHAR2,
        p_access_token  IN VARCHAR2,
        p_token_type    IN VARCHAR2 DEFAULT 'Bearer',
        p_expires_in    IN NUMBER DEFAULT 3600
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_expires_at TIMESTAMP;
    BEGIN
        l_expires_at := SYSTIMESTAMP + NUMTODSINTERVAL(p_expires_in, 'SECOND');
        
        MERGE INTO oauth_tokens ot
        USING (SELECT p_service_name AS service_name FROM dual) src
        ON (ot.service_name = src.service_name)
        WHEN MATCHED THEN
            UPDATE SET 
                access_token = p_access_token,
                token_type = NVL(p_token_type, 'Bearer'),
                expires_at = l_expires_at
                -- NOTE: created_at is NOT updated on refresh - it tracks original creation
                -- last_used_at will be updated by mark_token_used()
        WHEN NOT MATCHED THEN
            INSERT (service_name, access_token, token_type, expires_at, created_at)
            VALUES (p_service_name, p_access_token, NVL(p_token_type, 'Bearer'), l_expires_at, SYSTIMESTAMP);
        
        COMMIT;
    END save_token;
    
    -- --------------------------------------------------------
    -- Private: Get stored token
    -- --------------------------------------------------------
    FUNCTION get_stored_token(
        p_service_name IN VARCHAR2
    ) RETURN uscis_types_pkg.t_oauth_token IS
        l_token uscis_types_pkg.t_oauth_token;
    BEGIN
        SELECT 
            token_id,
            service_name,
            access_token,
            token_type,
            expires_at,
            created_at,
            last_used_at
        INTO 
            l_token.token_id,
            l_token.service_name,
            l_token.access_token,
            l_token.token_type,
            l_token.expires_at,
            l_token.created_at,
            l_token.last_used_at
        FROM oauth_tokens
        WHERE service_name = p_service_name;
        
        RETURN l_token;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN l_token;  -- Returns empty record
    END get_stored_token;
    
    -- --------------------------------------------------------
    -- is_token_valid
    -- --------------------------------------------------------
    FUNCTION is_token_valid(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN BOOLEAN IS
        l_token uscis_types_pkg.t_oauth_token;
        l_buffer_secs NUMBER;
    BEGIN
        l_token := get_stored_token(p_service_name);
        
        IF l_token.access_token IS NULL THEN
            RETURN FALSE;
        END IF;
        
        -- Get buffer from config (default 60 seconds)
        l_buffer_secs := uscis_util_pkg.get_config_number('TOKEN_REFRESH_BUFFER_SECONDS', 60);
        
        -- Check if expired (with buffer)
        RETURN l_token.expires_at > SYSTIMESTAMP + NUMTODSINTERVAL(l_buffer_secs, 'SECOND');
    END is_token_valid;
    
    -- --------------------------------------------------------
    -- get_token_expiry
    -- --------------------------------------------------------
    FUNCTION get_token_expiry(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN TIMESTAMP IS
        l_expires_at TIMESTAMP;
    BEGIN
        SELECT expires_at
        INTO l_expires_at
        FROM oauth_tokens
        WHERE service_name = p_service_name;
        
        RETURN l_expires_at;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_token_expiry;
    
    -- --------------------------------------------------------
    -- get_minutes_until_expiry
    -- --------------------------------------------------------
    FUNCTION get_minutes_until_expiry(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN NUMBER IS
        l_expires_at TIMESTAMP;
        l_diff       INTERVAL DAY TO SECOND;
    BEGIN
        l_expires_at := get_token_expiry(p_service_name);
        
        IF l_expires_at IS NULL THEN
            RETURN NULL;
        END IF;
        
        -- Check if already expired - EXTRACT on negative intervals is unreliable
        IF l_expires_at <= SYSTIMESTAMP THEN
            RETURN 0;  -- Already expired
        END IF;
        
        -- Calculate positive interval
        l_diff := l_expires_at - SYSTIMESTAMP;
        
        RETURN ROUND(
            EXTRACT(DAY FROM l_diff) * 24 * 60 +
            EXTRACT(HOUR FROM l_diff) * 60 +
            EXTRACT(MINUTE FROM l_diff)
        );
    END get_minutes_until_expiry;
    
    -- --------------------------------------------------------
    -- has_credentials
    -- --------------------------------------------------------
    FUNCTION has_credentials RETURN BOOLEAN IS
        l_client_id     VARCHAR2(4000);
        l_client_secret VARCHAR2(4000);
    BEGIN
        l_client_id := uscis_util_pkg.get_config('USCIS_CLIENT_ID');
        l_client_secret := uscis_util_pkg.get_config('USCIS_CLIENT_SECRET');
        
        RETURN l_client_id IS NOT NULL AND LENGTH(l_client_id) > 0
           AND l_client_secret IS NOT NULL AND LENGTH(l_client_secret) > 0;
    END has_credentials;
    
    -- --------------------------------------------------------
    -- get_token_url
    -- --------------------------------------------------------
    FUNCTION get_token_url RETURN VARCHAR2 IS
    BEGIN
        RETURN uscis_util_pkg.get_config(
            'USCIS_OAUTH_TOKEN_URL',
            'https://api-int.uscis.gov/oauth/accesstoken'
        );
    END get_token_url;
    
    -- --------------------------------------------------------
    -- fetch_new_token
    -- Fetches a new OAuth token and saves it to storage.
    -- @param p_service_name Optional service name (defaults to package default)
    -- --------------------------------------------------------
    FUNCTION fetch_new_token(
        p_client_id     IN VARCHAR2,
        p_client_secret IN VARCHAR2,
        p_token_url     IN VARCHAR2 DEFAULT NULL,
        p_service_name  IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN VARCHAR2 IS
        l_url           VARCHAR2(1000);
        l_response      CLOB;
        l_access_token  VARCHAR2(4000);
        l_expires_in    NUMBER := 3600;
        l_token_type    VARCHAR2(50) := 'Bearer';
    BEGIN
        l_url := NVL(p_token_url, get_token_url);
        
        -- Use APEX_WEB_SERVICE for HTTP calls
        APEX_WEB_SERVICE.g_request_headers.DELETE;
        APEX_WEB_SERVICE.g_request_headers(1).name := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers(1).value := 'application/x-www-form-urlencoded';
        
        l_response := APEX_WEB_SERVICE.make_rest_request(
            p_url              => l_url,
            p_http_method      => 'POST',
            p_body             => 'grant_type=client_credentials' ||
                            '&client_id=' || UTL_URL.escape(p_client_id, TRUE) ||
                            '&client_secret=' || UTL_URL.escape(p_client_secret, TRUE),
            p_transfer_timeout => 30  -- 30 second timeout to avoid indefinite blocking
        );
        
        -- Check HTTP status
        IF APEX_WEB_SERVICE.g_status_code != 200 THEN
            -- Sanitize response: limit length and redact potential sensitive fields
            DECLARE
                l_safe_response VARCHAR2(200);
            BEGIN
                l_safe_response := REGEXP_REPLACE(
                    SUBSTR(l_response, 1, 200),
                    '("(access_token|client_secret|password|token)"\s*:\s*")[^"]*"',
                    '"\1:[REDACTED]"',
                    1, 0, 'i'
                );
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_auth_failed,
                    'OAuth token request failed with status ' || APEX_WEB_SERVICE.g_status_code ||
                    ': ' || l_safe_response
                );
            END;
        END IF;
        
        -- Parse JSON response
        BEGIN
            SELECT 
                JSON_VALUE(l_response, '$.access_token'),
                NVL(JSON_VALUE(l_response, '$.expires_in' RETURNING NUMBER), 3600),
                NVL(JSON_VALUE(l_response, '$.token_type'), 'Bearer')
            INTO l_access_token, l_expires_in, l_token_type
            FROM dual;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(
                    uscis_types_pkg.gc_err_auth_failed,
                    'Failed to parse OAuth response: ' || SQLERRM
                );
        END;
        
        IF l_access_token IS NULL THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_auth_failed,
                'No access token in OAuth response'
            );
        END IF;
        
        -- Save token using the specified service name (or package default)
        save_token(
            p_service_name => NVL(p_service_name, gc_default_service),
            p_access_token => l_access_token,
            p_token_type   => l_token_type,
            p_expires_in   => l_expires_in
        );
        
        uscis_util_pkg.log_debug(
            'Obtained new OAuth token, expires in ' || l_expires_in || ' seconds',
            gc_package_name
        );
        
        RETURN l_access_token;
        
    EXCEPTION
        WHEN OTHERS THEN
            uscis_util_pkg.log_error(
                'OAuth token fetch failed: ' || SQLERRM,
                gc_package_name,
                SQLCODE,
                SQLERRM
            );
            RAISE;
    END fetch_new_token;
    
    -- --------------------------------------------------------
    -- get_access_token
    -- --------------------------------------------------------
    FUNCTION get_access_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN VARCHAR2 IS
        l_token         uscis_types_pkg.t_oauth_token;
        l_client_id     VARCHAR2(4000);
        l_client_secret VARCHAR2(4000);
    BEGIN
        -- Check if we have a valid cached token
        IF is_token_valid(p_service_name) THEN
            l_token := get_stored_token(p_service_name);
            mark_token_used(p_service_name);
            RETURN l_token.access_token;
        END IF;
        
        -- Need to fetch new token
        l_client_id := uscis_util_pkg.get_config('USCIS_CLIENT_ID');
        l_client_secret := uscis_util_pkg.get_config('USCIS_CLIENT_SECRET');
        
        IF l_client_id IS NULL OR l_client_secret IS NULL THEN
            RAISE_APPLICATION_ERROR(
                uscis_types_pkg.gc_err_credentials_missing,
                'USCIS OAuth credentials not configured. Set USCIS_CLIENT_ID and USCIS_CLIENT_SECRET in scheduler_config.'
            );
        END IF;
        
        -- Pass service name so token is stored for the requested service
        RETURN fetch_new_token(l_client_id, l_client_secret, p_service_name => p_service_name);
    END get_access_token;
    
    -- --------------------------------------------------------
    -- clear_token
    -- --------------------------------------------------------
    PROCEDURE clear_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        DELETE FROM oauth_tokens
        WHERE service_name = p_service_name;
        
        COMMIT;
        
        uscis_util_pkg.log_debug('Cleared OAuth token for ' || p_service_name, gc_package_name);
    END clear_token;
    
    -- --------------------------------------------------------
    -- refresh_token_if_needed
    -- --------------------------------------------------------
    PROCEDURE refresh_token_if_needed(
        p_service_name   IN VARCHAR2 DEFAULT 'USCIS_API',
        p_buffer_seconds IN NUMBER DEFAULT 60
    ) IS
        l_expires_at    TIMESTAMP;
        l_access_token  VARCHAR2(4000);
    BEGIN
        l_expires_at := get_token_expiry(p_service_name);
        
        IF l_expires_at IS NULL THEN
            -- No token, fetch one
            l_access_token := get_access_token(p_service_name);
        ELSIF l_expires_at <= SYSTIMESTAMP + NUMTODSINTERVAL(p_buffer_seconds, 'SECOND') THEN
            -- Token expires soon, clear cached token to force refresh
            -- This ensures get_access_token fetches new token instead of returning cached one
            uscis_util_pkg.log_debug('Proactively refreshing token', gc_package_name);
            clear_token(p_service_name);
            l_access_token := get_access_token(p_service_name);
        END IF;
    END refresh_token_if_needed;
    
    -- --------------------------------------------------------
    -- mark_token_used
    -- --------------------------------------------------------
    PROCEDURE mark_token_used(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE oauth_tokens
        SET last_used_at = SYSTIMESTAMP
        WHERE service_name = p_service_name;
        
        COMMIT;
    END mark_token_used;
    
    -- --------------------------------------------------------
    -- validate_credentials
    -- Validates OAuth credentials without persisting any tokens.
    -- This is useful for testing credentials during configuration
    -- without side effects on the token storage.
    -- --------------------------------------------------------
    FUNCTION validate_credentials(
        p_client_id     IN VARCHAR2,
        p_client_secret IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_url        VARCHAR2(500);
        l_response   CLOB;
        l_token      VARCHAR2(4000);
    BEGIN
        -- Attempt to fetch a token without saving it
        l_url := uscis_util_pkg.get_config('USCIS_OAUTH_TOKEN_URL', gc_default_token_url);
        
        -- Make OAuth request (test only, don't persist)
        apex_web_service.g_request_headers.DELETE;
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
        
        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
            p_body        => 'grant_type=client_credentials' ||
                            '&client_id=' || UTL_URL.escape(p_client_id, TRUE) ||
                            '&client_secret=' || UTL_URL.escape(p_client_secret, TRUE)
        );
        
        -- Only consider valid if we got HTTP 200
        IF apex_web_service.g_status_code != 200 THEN
            RETURN FALSE;
        END IF;
        
        -- Check if we got a valid token (without persisting)
        l_token := JSON_VALUE(l_response, '$.access_token');
        RETURN l_token IS NOT NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validate_credentials;
    
    -- --------------------------------------------------------
    -- get_token_status
    -- --------------------------------------------------------
    FUNCTION get_token_status(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_API'
    ) RETURN CLOB IS
        l_token       uscis_types_pkg.t_oauth_token;
        l_status      VARCHAR2(20);
        l_mins_left   NUMBER;
        l_json        CLOB;
        l_has_creds   BOOLEAN;
    BEGIN
        l_token := get_stored_token(p_service_name);
        l_mins_left := get_minutes_until_expiry(p_service_name);
        l_has_creds := has_credentials;
        
        IF l_token.access_token IS NULL THEN
            l_status := 'NONE';
        ELSIF l_token.expires_at < SYSTIMESTAMP THEN
            l_status := 'EXPIRED';
        ELSIF l_mins_left <= 5 THEN
            l_status := 'EXPIRING';
        ELSE
            l_status := 'VALID';
        END IF;
        
        -- Use JSON_OBJECT for safe JSON encoding (prevents injection, handles nulls)
        SELECT JSON_OBJECT(
            'service_name'           VALUE p_service_name,
            'status'                 VALUE l_status,
            'has_token'              VALUE CASE WHEN l_token.access_token IS NOT NULL THEN 'true' ELSE 'false' END FORMAT JSON,
            'expires_at'             VALUE CASE 
                                            WHEN l_token.expires_at IS NOT NULL 
                                            THEN TO_CHAR(SYS_EXTRACT_UTC(FROM_TZ(l_token.expires_at, SESSIONTIMEZONE)), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                                            ELSE NULL 
                                          END,
            'minutes_until_expiry'   VALUE l_mins_left,
            'last_used_at'           VALUE CASE 
                                            WHEN l_token.last_used_at IS NOT NULL 
                                            THEN TO_CHAR(SYS_EXTRACT_UTC(FROM_TZ(l_token.last_used_at, SESSIONTIMEZONE)), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                                            ELSE NULL 
                                          END,
            'credentials_configured' VALUE CASE WHEN l_has_creds THEN 'true' ELSE 'false' END FORMAT JSON
            ABSENT ON NULL
            RETURNING CLOB
        )
        INTO l_json
        FROM dual;
        
        RETURN l_json;
    END get_token_status;

END uscis_oauth_pkg;
/

SHOW ERRORS PACKAGE uscis_oauth_pkg
SHOW ERRORS PACKAGE BODY uscis_oauth_pkg

PROMPT ============================================================
PROMPT USCIS_OAUTH_PKG created successfully
PROMPT ============================================================
