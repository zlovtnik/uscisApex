-- ============================================================
-- USCIS Case Tracker - Complete Database Installation (Fixed)
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: install_all_v2.sql
-- IMPORTANT: Run Step 0 as ADMIN first, then run rest as USCIS_APP
-- ============================================================

SET ECHO ON
SET TIMING ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET SCAN OFF

PROMPT ============================================================
PROMPT  USCIS Case Tracker Database Installation
PROMPT  Started: 
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS install_started FROM dual;
PROMPT ============================================================

-- ============================================================
-- STEP 0: GRANT QUOTA (Run as ADMIN first!)
-- ============================================================
-- Uncomment and run this section as ADMIN before running the rest as USCIS_APP:
--
-- ALTER USER uscis_app QUOTA UNLIMITED ON data;
-- COMMIT;
--
-- Or run this:
-- ALTER USER uscis_app QUOTA 500M ON data;
-- ============================================================

PROMPT Checking database version...
SELECT banner FROM v$version WHERE ROWNUM = 1;

PROMPT Current schema...
SELECT USER AS current_user FROM dual;


-- ============================================================
-- STEP 1: CREATE TABLES
-- ============================================================

PROMPT ============================================================
PROMPT Step 1: Creating Tables...
PROMPT ============================================================

-- Drop existing objects if they exist (for re-runs)
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables 
        WHERE table_name IN (
            'STATUS_UPDATES', 'CASE_HISTORY', 'OAUTH_TOKENS', 
            'API_RATE_LIMITER', 'CASE_AUDIT_LOG', 'SCHEDULER_CONFIG',
            'CASE_AUDIT_LOG_ARCHIVE'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
        DBMS_OUTPUT.PUT_LINE('Dropped table: ' || t.table_name);
    END LOOP;
END;
/

-- Drop existing views
BEGIN
    FOR v IN (
        SELECT view_name FROM user_views 
        WHERE view_name IN (
            'V_CASE_CURRENT_STATUS', 'V_CASE_DASHBOARD', 'V_RECENT_ACTIVITY',
            'V_STATUS_HISTORY', 'V_CASES_DUE_FOR_CHECK', 'V_CASE_TYPE_SUMMARY',
            'V_TOKEN_STATUS', 'V_RATE_LIMIT_STATUS', 'V_OAUTH_TOKENS_SECURE'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
        DBMS_OUTPUT.PUT_LINE('Dropped view: ' || v.view_name);
    END LOOP;
END;
/

-- 1.1 CASE_HISTORY Table
CREATE TABLE case_history (
    receipt_number    VARCHAR2(13)    NOT NULL,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    created_by        VARCHAR2(255),
    notes             CLOB,
    is_active         NUMBER(1)       DEFAULT 1 NOT NULL,
    last_checked_at   TIMESTAMP,
    check_frequency   NUMBER          DEFAULT 24,
    --
    CONSTRAINT pk_case_history 
        PRIMARY KEY (receipt_number),
    CONSTRAINT chk_receipt_format 
        CHECK (REGEXP_LIKE(receipt_number, '^[A-Z]{3}[0-9]{10}$')),
    CONSTRAINT chk_is_active 
        CHECK (is_active IN (0, 1)),
    CONSTRAINT chk_check_frequency 
        CHECK (check_frequency >= 1 AND check_frequency <= 720)
);

COMMENT ON TABLE case_history IS 'Master table for tracked USCIS cases';

PROMPT Created table: CASE_HISTORY

-- 1.2 STATUS_UPDATES Table
CREATE TABLE status_updates (
    id                NUMBER GENERATED ALWAYS AS IDENTITY,
    receipt_number    VARCHAR2(13)    NOT NULL,
    case_type         VARCHAR2(100)   NOT NULL,
    current_status    VARCHAR2(500)   NOT NULL,
    last_updated      TIMESTAMP       NOT NULL,
    details           CLOB,
    source            VARCHAR2(20)    DEFAULT 'MANUAL' NOT NULL,
    api_response_json CLOB,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    --
    CONSTRAINT pk_status_updates 
        PRIMARY KEY (id),
    CONSTRAINT fk_status_receipt 
        FOREIGN KEY (receipt_number)
        REFERENCES case_history(receipt_number) 
        ON DELETE CASCADE,
    CONSTRAINT chk_source 
        CHECK (source IN ('MANUAL', 'API', 'IMPORT'))
);

COMMENT ON TABLE status_updates IS 'Historical status updates for each tracked case';

PROMPT Created table: STATUS_UPDATES

-- 1.3 OAUTH_TOKENS Table
-- NOTE: For production with sensitive data, consider:
--   1. APEX Web Credentials (recommended for APEX apps)
--   2. Oracle TDE column encryption
--   3. Custom encryption with DBMS_CRYPTO (requires grant)
CREATE TABLE oauth_tokens (
    token_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    service_name      VARCHAR2(50)    NOT NULL,
    access_token      VARCHAR2(4000)  NOT NULL,  -- OAuth access token
    token_type        VARCHAR2(50)    DEFAULT 'Bearer',
    expires_at        TIMESTAMP       NOT NULL,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    last_used_at      TIMESTAMP,
    --
    CONSTRAINT pk_oauth_tokens 
        PRIMARY KEY (token_id),
    CONSTRAINT uk_oauth_service 
        UNIQUE (service_name)
);

COMMENT ON TABLE oauth_tokens IS 'OAuth2 access tokens for API authentication';
COMMENT ON COLUMN oauth_tokens.access_token IS 'OAuth access token - consider APEX Web Credentials for production';

PROMPT Created table: OAUTH_TOKENS

-- 1.4 API_RATE_LIMITER Table
CREATE TABLE api_rate_limiter (
    limiter_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    service_name      VARCHAR2(50)    NOT NULL,
    last_request_at   TIMESTAMP       NOT NULL,
    request_count     NUMBER          DEFAULT 0,
    window_start      TIMESTAMP,
    --
    CONSTRAINT pk_api_rate_limiter 
        PRIMARY KEY (limiter_id),
    CONSTRAINT uk_limiter_service 
        UNIQUE (service_name)
);

COMMENT ON TABLE api_rate_limiter IS 'Rate limiting state for external API calls';

PROMPT Created table: API_RATE_LIMITER

-- 1.5 CASE_AUDIT_LOG Table
CREATE TABLE case_audit_log (
    audit_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    receipt_number    VARCHAR2(13),
    action            VARCHAR2(50)    NOT NULL,
    old_values        CLOB,
    new_values        CLOB,
    performed_by      VARCHAR2(255),
    performed_at      TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    ip_address        VARCHAR2(45),
    user_agent        VARCHAR2(500),
    --
    CONSTRAINT pk_case_audit_log 
        PRIMARY KEY (audit_id),
    CONSTRAINT chk_audit_action 
        CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'CHECK', 'EXPORT', 'IMPORT'))
);

COMMENT ON TABLE case_audit_log IS 'Audit trail for all case operations';

PROMPT Created table: CASE_AUDIT_LOG

-- 1.6 SCHEDULER_CONFIG Table
CREATE TABLE scheduler_config (
    config_id         NUMBER GENERATED ALWAYS AS IDENTITY,
    config_key        VARCHAR2(100)   NOT NULL,
    config_value      VARCHAR2(4000),
    description       VARCHAR2(500),
    updated_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    --
    CONSTRAINT pk_scheduler_config 
        PRIMARY KEY (config_id),
    CONSTRAINT uk_config_key 
        UNIQUE (config_key)
);

COMMENT ON TABLE scheduler_config IS 'Application configuration key-value store';

PROMPT Created table: SCHEDULER_CONFIG

-- 1.7 CASE_AUDIT_LOG_ARCHIVE Table (proper DDL with constraints)
CREATE TABLE case_audit_log_archive (
    audit_id          NUMBER          NOT NULL,
    receipt_number    VARCHAR2(13),
    action            VARCHAR2(50)    NOT NULL,
    old_values        CLOB,
    new_values        CLOB,
    performed_by      VARCHAR2(255),
    performed_at      TIMESTAMP       NOT NULL,
    ip_address        VARCHAR2(45),
    user_agent        VARCHAR2(500),
    archived_at       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    --
    CONSTRAINT pk_case_audit_log_archive 
        PRIMARY KEY (audit_id)
);

CREATE INDEX idx_archive_performed_at ON case_audit_log_archive(performed_at);
CREATE INDEX idx_archive_receipt ON case_audit_log_archive(receipt_number);

COMMENT ON TABLE case_audit_log_archive IS 'Archived audit records for compliance retention';

PROMPT Created table: CASE_AUDIT_LOG_ARCHIVE


-- ============================================================
-- STEP 2: CREATE INDEXES
-- ============================================================

PROMPT ============================================================
PROMPT Step 2: Creating Indexes...
PROMPT ============================================================

CREATE INDEX idx_status_receipt ON status_updates(receipt_number);
CREATE INDEX idx_status_date ON status_updates(last_updated DESC);
CREATE INDEX idx_status_receipt_date ON status_updates(receipt_number, last_updated DESC);
CREATE INDEX idx_status_created ON status_updates(created_at DESC);
CREATE INDEX idx_audit_receipt ON case_audit_log(receipt_number);
CREATE INDEX idx_audit_date ON case_audit_log(performed_at DESC);
CREATE INDEX idx_audit_action ON case_audit_log(action, performed_at DESC);

PROMPT Created 7 indexes


-- ============================================================
-- STEP 2.5: OAUTH TOKEN ENCRYPTION FUNCTIONS
-- ============================================================

PROMPT ============================================================
PROMPT Step 2.5: Creating OAuth Token Encryption Functions...
PROMPT ============================================================

-- IMPORTANT: The encryption key MUST be stored securely.
-- Use Oracle Wallet, TDE, or APEX Web Credentials for the master key.
-- NEVER store the encryption key in scheduler_config or source code.

-- Type to return encrypted token with IV and salt (for atomic INSERT/UPDATE by caller)
CREATE OR REPLACE TYPE t_encrypted_token AS OBJECT (
    encrypted_data RAW(2000),
    iv             RAW(16),
    salt           RAW(16)
);
/

-- ============================================================
-- ENCRYPTION KEY RETRIEVAL
-- ============================================================
-- For APEX applications, OAuth tokens should be stored using APEX Web Credentials
-- (Shared Components > Web Credentials) which handles encryption automatically.
--
-- This function is a STUB for non-APEX token encryption use cases.
-- To enable encryption, either:
--   1. Use APEX Web Credentials (recommended for APEX apps)
--   2. Configure a secure key source and modify this function
--   3. Use Oracle TDE (Transparent Data Encryption) for column-level encryption
--
-- PRODUCTION SETUP OPTIONS:
--   Option A - APEX Web Credentials (no code changes needed, use apex_credential APIs)
--   Option B - Environment variable via DBMS_SCHEDULER credential
--   Option C - Oracle Wallet with external key file
-- ============================================================
CREATE OR REPLACE FUNCTION get_oauth_master_key RETURN RAW IS
    l_key RAW(32);
    l_key_source VARCHAR2(100);
BEGIN
    -- Check for key source configuration
    BEGIN
        SELECT config_value INTO l_key_source
        FROM scheduler_config
        WHERE config_key = 'ENCRYPTION_KEY_SOURCE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_key_source := 'NOT_CONFIGURED';
    END;
    
    -- STUB: Token encryption is not configured
    -- For APEX applications, use APEX Web Credentials instead of this function
    RAISE_APPLICATION_ERROR(-20010,
        'Token encryption not configured. ' ||
        'For APEX apps, use APEX Web Credentials (Shared Components > Web Credentials) ' ||
        'which provides built-in secure token storage. ' ||
        'See APEX_CREDENTIAL package for programmatic access.');
    
    RETURN l_key; -- Never reached, satisfies compiler
END get_oauth_master_key;
/

-- ============================================================
-- TOKEN ENCRYPTION FUNCTION (STUB)
-- ============================================================
-- This function requires: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP;
-- For APEX applications, use APEX Web Credentials instead.
-- ============================================================
CREATE OR REPLACE FUNCTION encrypt_oauth_token(
    p_plaintext_token IN VARCHAR2
) RETURN t_encrypted_token IS
    l_result t_encrypted_token;
BEGIN
    -- STUB: Encryption requires DBMS_CRYPTO grant and key configuration
    -- For APEX applications, use APEX Web Credentials instead:
    --   APEX_CREDENTIAL.SET_PERSISTENT_CREDENTIALS(
    --       p_credential_static_id => 'USCIS_API',
    --       p_client_id => 'your_client_id',
    --       p_client_secret => 'your_client_secret'
    --   );
    --
    -- To enable this function:
    --   1. Run as DBA: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP;
    --   2. Configure encryption key source (see get_oauth_master_key)
    --   3. Recompile this function with the full implementation
    
    RAISE_APPLICATION_ERROR(-20010,
        'Token encryption not available. Use APEX Web Credentials for secure token storage. ' ||
        'To enable: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP');
    
    RETURN l_result; -- Never reached, satisfies compiler
END encrypt_oauth_token;
/

-- ============================================================
-- TOKEN DECRYPTION FUNCTION (STUB)
-- ============================================================
-- This function requires: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP;
-- For APEX applications, use APEX Web Credentials instead.
-- ============================================================
CREATE OR REPLACE FUNCTION decrypt_oauth_token(
    p_encrypted_token IN RAW,
    p_service_name    IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    -- STUB: Decryption requires DBMS_CRYPTO grant and key configuration
    -- For APEX applications, use APEX Web Credentials instead:
    --   APEX_CREDENTIAL.SET_SESSION_CREDENTIALS(
    --       p_credential_static_id => 'USCIS_API'
    --   );
    --   -- Then use apex_web_service.make_rest_request with p_credential_static_id
    --
    -- To enable this function:
    --   1. Run as DBA: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP;
    --   2. Configure encryption key source (see get_oauth_master_key)
    --   3. Recompile this function with the full implementation
    
    RAISE_APPLICATION_ERROR(-20010,
        'Token decryption not available. Use APEX Web Credentials for secure token storage. ' ||
        'To enable: GRANT EXECUTE ON SYS.DBMS_CRYPTO TO USCIS_APP');
    
    RETURN NULL; -- Never reached, satisfies compiler
END decrypt_oauth_token;
/

-- SECURITY NOTE: v_oauth_tokens_secure has been REMOVED.
-- That view exposed plaintext tokens to anyone with SELECT access.
-- Instead, call decrypt_oauth_token(encrypted_token, service_name) directly
-- with proper filtering by service_name and user-scoped criteria.
--
-- Example secure usage:
--   SELECT decrypt_oauth_token(encrypted_token, service_name) AS access_token
--   FROM oauth_tokens
--   WHERE service_name = 'USCIS_CASE_STATUS'
--     AND expires_at > SYSTIMESTAMP;
--
-- Consider implementing:
--   1. Row-level security (RLS) policies on oauth_tokens
--   2. Fine-Grained Auditing (FGA) to log/block unauthorized reads
--   3. Restrict SELECT grants to specific roles/procedures only

PROMPT Created OAuth encryption functions (v_oauth_tokens_secure removed for security)


-- ============================================================
-- STEP 3: CREATE VIEWS
-- ============================================================

PROMPT ============================================================
PROMPT Step 3: Creating Views...
PROMPT ============================================================

-- 3.1 V_CASE_CURRENT_STATUS View (Fixed - using WITH clause instead of outer join to subquery)
CREATE OR REPLACE VIEW v_case_current_status AS
WITH latest_status AS (
    SELECT 
        receipt_number,
        MAX(id) AS max_id
    FROM status_updates
    GROUP BY receipt_number
)
SELECT 
    ch.receipt_number,
    ch.created_at           AS tracking_since,
    ch.created_by,
    ch.notes,
    ch.is_active,
    ch.last_checked_at,
    ch.check_frequency,
    su.case_type,
    su.current_status,
    su.last_updated,
    su.details,
    su.source               AS last_update_source,
    (SELECT COUNT(*) 
     FROM status_updates s2 
     WHERE s2.receipt_number = ch.receipt_number) AS total_updates,
    -- Fixed: Use EXTRACT for timestamp arithmetic
    ROUND(SYSDATE - CAST(su.last_updated AS DATE), 1) AS days_since_update,
    ROUND((SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24, 1) AS hours_since_check,
    CASE 
        WHEN ch.is_active = 1 
             AND (ch.last_checked_at IS NULL 
                  OR (SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24 >= ch.check_frequency)
        THEN 'Y'
        ELSE 'N'
    END AS check_due_flag
FROM case_history ch
LEFT JOIN latest_status ls ON ls.receipt_number = ch.receipt_number
LEFT JOIN status_updates su ON su.id = ls.max_id;

PROMPT Created view: V_CASE_CURRENT_STATUS

-- 3.2 V_CASE_DASHBOARD View
CREATE OR REPLACE VIEW v_case_dashboard AS
SELECT 
    current_status,
    COUNT(*)                AS case_count,
    MIN(last_updated)       AS oldest_update,
    MAX(last_updated)       AS newest_update,
    AVG(days_since_update)  AS avg_days_since_update,
    SUM(CASE WHEN check_due_flag = 'Y' THEN 1 ELSE 0 END) AS checks_due
FROM v_case_current_status
WHERE is_active = 1
GROUP BY current_status;

PROMPT Created view: V_CASE_DASHBOARD

-- 3.3 V_RECENT_ACTIVITY View
CREATE OR REPLACE VIEW v_recent_activity AS
SELECT 
    cal.audit_id,
    cal.performed_at,
    cal.action,
    cal.receipt_number,
    cal.performed_by,
    cal.ip_address,
    vcs.current_status,
    vcs.case_type,
    CASE cal.action
        WHEN 'INSERT' THEN 'Added case ' || cal.receipt_number
        WHEN 'UPDATE' THEN 'Updated case ' || cal.receipt_number
        WHEN 'DELETE' THEN 'Deleted case ' || cal.receipt_number
        WHEN 'CHECK'  THEN 'Checked status for ' || cal.receipt_number
        WHEN 'EXPORT' THEN 'Exported cases'
        WHEN 'IMPORT' THEN 'Imported cases'
        ELSE cal.action
    END AS action_description
FROM case_audit_log cal
LEFT JOIN v_case_current_status vcs 
    ON vcs.receipt_number = cal.receipt_number;

PROMPT Created view: V_RECENT_ACTIVITY

-- 3.4 V_STATUS_HISTORY View (Fixed timestamp arithmetic)
CREATE OR REPLACE VIEW v_status_history AS
SELECT 
    su.id,
    su.receipt_number,
    su.case_type,
    su.current_status,
    su.last_updated,
    su.details,
    su.source,
    su.created_at,
    LAG(su.current_status) OVER (
        PARTITION BY su.receipt_number 
        ORDER BY su.last_updated
    ) AS previous_status,
    -- Fixed: Extract days from interval
    ROUND(
        EXTRACT(DAY FROM (su.last_updated - LAG(su.last_updated) OVER (
            PARTITION BY su.receipt_number 
            ORDER BY su.last_updated
        ))) +
        EXTRACT(HOUR FROM (su.last_updated - LAG(su.last_updated) OVER (
            PARTITION BY su.receipt_number 
            ORDER BY su.last_updated
        ))) / 24 +
        EXTRACT(MINUTE FROM (su.last_updated - LAG(su.last_updated) OVER (
            PARTITION BY su.receipt_number 
            ORDER BY su.last_updated
        ))) / 1440
    , 2) AS days_since_previous,
    ROW_NUMBER() OVER (
        PARTITION BY su.receipt_number 
        ORDER BY su.last_updated
    ) AS update_sequence,
    CASE 
        WHEN su.id = MAX(su.id) OVER (PARTITION BY su.receipt_number) 
        THEN 'Y' 
        ELSE 'N' 
    END AS is_current
FROM status_updates su;

PROMPT Created view: V_STATUS_HISTORY

-- 3.5 V_CASES_DUE_FOR_CHECK View
CREATE OR REPLACE VIEW v_cases_due_for_check AS
SELECT 
    ch.receipt_number,
    ch.last_checked_at,
    ch.check_frequency,
    ROUND((SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24, 1) AS hours_overdue,
    vcs.current_status,
    vcs.case_type
FROM case_history ch
LEFT JOIN v_case_current_status vcs 
    ON vcs.receipt_number = ch.receipt_number
WHERE ch.is_active = 1
  AND (ch.last_checked_at IS NULL 
       OR (SYSDATE - CAST(ch.last_checked_at AS DATE)) * 24 >= ch.check_frequency);

PROMPT Created view: V_CASES_DUE_FOR_CHECK

-- 3.6 V_CASE_TYPE_SUMMARY View
CREATE OR REPLACE VIEW v_case_type_summary AS
SELECT 
    case_type,
    COUNT(*)                AS total_cases,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_cases,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive_cases,
    MIN(tracking_since)     AS earliest_tracking,
    MAX(last_updated)       AS most_recent_update
FROM v_case_current_status
WHERE case_type IS NOT NULL
GROUP BY case_type;

PROMPT Created view: V_CASE_TYPE_SUMMARY

-- 3.7 V_TOKEN_STATUS View (Fixed timestamp arithmetic)
CREATE OR REPLACE VIEW v_token_status AS
SELECT 
    service_name,
    token_type,
    expires_at,
    last_used_at,
    created_at,
    -- Fixed: Extract from interval for minutes calculation
    ROUND(
        EXTRACT(DAY FROM (expires_at - SYSTIMESTAMP)) * 24 * 60 +
        EXTRACT(HOUR FROM (expires_at - SYSTIMESTAMP)) * 60 +
        EXTRACT(MINUTE FROM (expires_at - SYSTIMESTAMP))
    , 0) AS minutes_until_expiry,
    CASE 
        WHEN expires_at < SYSTIMESTAMP THEN 'EXPIRED'
        WHEN expires_at < SYSTIMESTAMP + INTERVAL '5' MINUTE THEN 'EXPIRING'
        ELSE 'VALID'
    END AS token_status,
    CASE 
        WHEN last_used_at IS NULL THEN NULL
        ELSE ROUND(
            EXTRACT(DAY FROM (SYSTIMESTAMP - last_used_at)) * 24 * 60 +
            EXTRACT(HOUR FROM (SYSTIMESTAMP - last_used_at)) * 60 +
            EXTRACT(MINUTE FROM (SYSTIMESTAMP - last_used_at))
        , 0)
    END AS minutes_since_use
FROM oauth_tokens;

PROMPT Created view: V_TOKEN_STATUS

-- 3.8 V_RATE_LIMIT_STATUS View (Fixed timestamp arithmetic)
CREATE OR REPLACE VIEW v_rate_limit_status AS
SELECT 
    service_name,
    last_request_at,
    request_count,
    window_start,
    -- Fixed: Extract seconds from interval
    ROUND(
        EXTRACT(DAY FROM (SYSTIMESTAMP - last_request_at)) * 86400 +
        EXTRACT(HOUR FROM (SYSTIMESTAMP - last_request_at)) * 3600 +
        EXTRACT(MINUTE FROM (SYSTIMESTAMP - last_request_at)) * 60 +
        EXTRACT(SECOND FROM (SYSTIMESTAMP - last_request_at))
    , 2) AS seconds_since_request,
    CASE 
        WHEN window_start IS NOT NULL THEN
            ROUND(
                request_count / GREATEST(
                    EXTRACT(DAY FROM (SYSTIMESTAMP - window_start)) * 86400 +
                    EXTRACT(HOUR FROM (SYSTIMESTAMP - window_start)) * 3600 +
                    EXTRACT(MINUTE FROM (SYSTIMESTAMP - window_start)) * 60 +
                    EXTRACT(SECOND FROM (SYSTIMESTAMP - window_start)),
                    1  -- Minimum 1 second to prevent division by zero/negative
                )
            , 2)
        ELSE 0
    END AS requests_per_second,
    CASE 
        WHEN (
            EXTRACT(DAY FROM (SYSTIMESTAMP - last_request_at)) * 86400 +
            EXTRACT(HOUR FROM (SYSTIMESTAMP - last_request_at)) * 3600 +
            EXTRACT(MINUTE FROM (SYSTIMESTAMP - last_request_at)) * 60 +
            EXTRACT(SECOND FROM (SYSTIMESTAMP - last_request_at))
        ) >= 0.1 THEN 'Y'
        ELSE 'N'
    END AS can_request_now
FROM api_rate_limiter;

PROMPT Created view: V_RATE_LIMIT_STATUS


-- ============================================================

PROMPT ============================================================

-- Insert default configuration
INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('USCIS_API_BASE_URL', 'https://api-int.uscis.gov/case-status', 'USCIS Case Status API base URL');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('USCIS_OAUTH_TOKEN_URL', 'https://api-int.uscis.gov/oauth/accesstoken', 'USCIS OAuth2 token URL');

-- SECURITY NOTE: USCIS_CLIENT_ID and USCIS_CLIENT_SECRET are NOT stored here.
-- OAuth credentials MUST be stored securely using one of these methods:
--   1. APEX Web Credentials (recommended for APEX apps)
--   2. Oracle Wallet / DBMS_CREDENTIAL
--   3. External secrets manager via REST API
-- The OAuth package should retrieve credentials from the secure store.

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('RATE_LIMIT_REQUESTS_PER_SECOND', '10', 'Maximum API requests per second (USCIS limit)');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('RATE_LIMIT_MIN_INTERVAL_MS', '100', 'Minimum milliseconds between API requests');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('AUTO_CHECK_ENABLED', 'Y', 'Enable automatic status checks (Y/N)');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('AUTO_CHECK_INTERVAL_HOURS', '24', 'Default hours between automatic status checks');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('AUTO_CHECK_BATCH_SIZE', '50', 'Number of cases to check per scheduler run');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('AUDIT_RETENTION_DAYS', '365', 'Days to retain audit log entries');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('STATUS_HISTORY_RETENTION_DAYS', '730', 'Days to retain status history (2 years)');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('APP_VERSION', '1.0.0', 'Application version number');

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('APP_ENVIRONMENT', 'DEVELOPMENT', 'Environment: DEVELOPMENT, TEST, PRODUCTION');

COMMIT;

PROMPT Inserted 11 configuration entries

-- Initialize rate limiter
INSERT INTO api_rate_limiter (service_name, last_request_at, request_count, window_start)
VALUES ('USCIS_API', SYSTIMESTAMP - INTERVAL '1' HOUR, 0, NULL);
COMMIT;

PROMPT Initialized rate limiter


-- ============================================================
-- STEP 5: SAMPLE TEST DATA
-- ============================================================

PROMPT ============================================================
PROMPT Step 5: Loading Sample Test Data...
PROMPT ============================================================

-- Sample case 1: I-485 (Adjustment of Status)
INSERT INTO case_history (receipt_number, created_by, notes, is_active)
VALUES ('IOE0912345678', 'ADMIN', 'Sample I-485 application for testing', 1);

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('IOE0912345678', 'I-485', 'Case Was Received', 
        SYSTIMESTAMP - INTERVAL '90' DAY,
        'On ' || TO_CHAR(SYSTIMESTAMP - INTERVAL '90' DAY, 'Month DD, YYYY') || ', we received your Form I-485, Application to Register Permanent Residence or Adjust Status.',
        'MANUAL');

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('IOE0912345678', 'I-485', 'Case Is Being Actively Reviewed By USCIS', 
        SYSTIMESTAMP - INTERVAL '30' DAY,
        'As of ' || TO_CHAR(SYSTIMESTAMP - INTERVAL '30' DAY, 'Month DD, YYYY') || ', your case is being actively reviewed by USCIS.',
        'MANUAL');

PROMPT Added sample case: IOE0912345678 (I-485)

-- Sample case 2: I-765 (Employment Authorization)
INSERT INTO case_history (receipt_number, created_by, notes, is_active)
VALUES ('IOE0912345679', 'ADMIN', 'Sample I-765 EAD application', 1);

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('IOE0912345679', 'I-765', 'Case Was Received', 
        SYSTIMESTAMP - INTERVAL '60' DAY,
        'On April 5, 2025, we received your Form I-765, Application for Employment Authorization.',
        'MANUAL');

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('IOE0912345679', 'I-765', 'New Card Is Being Produced', 
        SYSTIMESTAMP - INTERVAL '10' DAY,
        'On May 24, 2025, we ordered your new card.',
        'MANUAL');

PROMPT Added sample case: IOE0912345679 (I-765)

-- Sample case 3: I-140 (Immigrant Petition)
INSERT INTO case_history (receipt_number, created_by, notes, is_active)
VALUES ('LIN2412345678', 'ADMIN', 'Sample I-140 petition (premium processing)', 1);

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('LIN2412345678', 'I-140', 'Case Was Approved', 
        SYSTIMESTAMP - INTERVAL '5' DAY,
        'On May 29, 2025, your Form I-140 was approved.',
        'MANUAL');

PROMPT Added sample case: LIN2412345678 (I-140)

-- Sample case 4: Inactive case (Fixed: use NUMTODSINTERVAL for large intervals)
INSERT INTO case_history (receipt_number, created_by, notes, is_active)
VALUES ('WAC2312345678', 'ADMIN', 'Old case - no longer tracking', 0);

INSERT INTO status_updates (receipt_number, case_type, current_status, last_updated, details, source)
VALUES ('WAC2312345678', 'I-130', 'Case Was Approved', 
        SYSTIMESTAMP - NUMTODSINTERVAL(365, 'DAY'),
        'Your Form I-130 was approved.',
        'MANUAL');

PROMPT Added sample case: WAC2312345678 (I-130 - inactive)

-- Add audit log entries
INSERT INTO case_audit_log (receipt_number, action, new_values, performed_by, ip_address)
VALUES ('IOE0912345678', 'INSERT', '{"receipt_number":"IOE0912345678","case_type":"I-485"}', 'ADMIN', '127.0.0.1');

INSERT INTO case_audit_log (receipt_number, action, new_values, performed_by, ip_address)
VALUES ('IOE0912345679', 'INSERT', '{"receipt_number":"IOE0912345679","case_type":"I-765"}', 'ADMIN', '127.0.0.1');

INSERT INTO case_audit_log (receipt_number, action, new_values, performed_by, ip_address)
VALUES ('LIN2412345678', 'INSERT', '{"receipt_number":"LIN2412345678","case_type":"I-140"}', 'ADMIN', '127.0.0.1');

COMMIT;

PROMPT Added audit log entries


-- ============================================================
-- INSTALLATION SUMMARY
-- ============================================================

PROMPT ============================================================
PROMPT  Installation Summary
PROMPT ============================================================

PROMPT Tables created:
SELECT table_name FROM user_tables 
WHERE table_name IN ('CASE_HISTORY', 'STATUS_UPDATES', 'OAUTH_TOKENS', 
                     'API_RATE_LIMITER', 'CASE_AUDIT_LOG', 'SCHEDULER_CONFIG',
                     'CASE_AUDIT_LOG_ARCHIVE')
ORDER BY table_name;

PROMPT Views created:
SELECT view_name FROM user_views 
WHERE view_name LIKE 'V_%'
ORDER BY view_name;

PROMPT Configuration entries:
SELECT config_key, config_value FROM scheduler_config ORDER BY config_key;

PROMPT Sample cases:
SELECT receipt_number, case_type, current_status, is_active
FROM v_case_current_status
ORDER BY receipt_number;

PROMPT ============================================================
PROMPT  Installation Complete!
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS install_completed FROM dual;
PROMPT ============================================================
