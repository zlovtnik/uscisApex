-- ============================================================
-- USCIS Case Tracker - Types Package
-- Task 1.3.1: USCIS_TYPES_PKG Specification
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/01_uscis_types_pkg.sql
-- Purpose: Type definitions, constants, and collection types
-- Dependencies: None
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_TYPES_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_types_pkg 
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version          CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name     CONSTANT VARCHAR2(30) := 'USCIS_TYPES_PKG';
    
    -- ========================================================
    -- Receipt Number Constants
    -- ========================================================
    gc_receipt_pattern  CONSTANT VARCHAR2(30) := '^[A-Z]{3}[0-9]{10}$';
    gc_receipt_length   CONSTANT NUMBER := 13;
    
    -- Valid receipt number prefixes (service centers)
    gc_prefix_ioe       CONSTANT VARCHAR2(3) := 'IOE';  -- Online filing
    gc_prefix_lin       CONSTANT VARCHAR2(3) := 'LIN';  -- Nebraska
    gc_prefix_wac       CONSTANT VARCHAR2(3) := 'WAC';  -- California  
    gc_prefix_eac       CONSTANT VARCHAR2(3) := 'EAC';  -- Vermont
    gc_prefix_src       CONSTANT VARCHAR2(3) := 'SRC';  -- Texas
    gc_prefix_msc       CONSTANT VARCHAR2(3) := 'MSC';  -- National Benefits Center
    
    -- ========================================================
    -- Source Type Constants
    -- ========================================================
    gc_source_manual    CONSTANT VARCHAR2(20) := 'MANUAL';
    gc_source_api       CONSTANT VARCHAR2(20) := 'API';
    gc_source_import    CONSTANT VARCHAR2(20) := 'IMPORT';
    
    -- ========================================================
    -- Audit Action Constants
    -- ========================================================
    gc_action_insert    CONSTANT VARCHAR2(20) := 'INSERT';
    gc_action_update    CONSTANT VARCHAR2(20) := 'UPDATE';
    gc_action_delete    CONSTANT VARCHAR2(20) := 'DELETE';
    gc_action_check     CONSTANT VARCHAR2(20) := 'CHECK';
    gc_action_export    CONSTANT VARCHAR2(20) := 'EXPORT';
    gc_action_import    CONSTANT VARCHAR2(20) := 'IMPORT';
    
    -- ========================================================
    -- API Service Constants
    -- ========================================================
    gc_service_uscis    CONSTANT VARCHAR2(50) := 'USCIS_API';
    gc_api_version      CONSTANT VARCHAR2(10) := 'v1';
    
    -- ========================================================
    -- Rate Limiting Constants
    -- ========================================================
    gc_rate_limit_tps   CONSTANT NUMBER := 10;          -- 10 transactions per second
    gc_min_interval_ms  CONSTANT NUMBER := 100;         -- 100ms between requests
    gc_daily_limit      CONSTANT NUMBER := 400000;      -- 400K requests per day
    
    -- ========================================================
    -- Token Management Constants
    -- ========================================================
    gc_token_type_bearer CONSTANT VARCHAR2(20) := 'Bearer';
    gc_token_buffer_secs CONSTANT NUMBER := 60;         -- Refresh 60s before expiry
    
    -- ========================================================
    -- Error Codes
    -- ========================================================
    gc_err_invalid_receipt    CONSTANT NUMBER := -20001;
    gc_err_case_not_found     CONSTANT NUMBER := -20002;
    gc_err_duplicate_case     CONSTANT NUMBER := -20003;
    gc_err_invalid_frequency  CONSTANT NUMBER := -20004;
    gc_err_auth_failed        CONSTANT NUMBER := -20010;
    gc_err_credentials_missing CONSTANT NUMBER := -20011;
    gc_err_api_error          CONSTANT NUMBER := -20020;
    gc_err_rate_limited       CONSTANT NUMBER := -20021;
    gc_err_invalid_json       CONSTANT NUMBER := -20030;
    gc_err_export_failed      CONSTANT NUMBER := -20040;
    gc_err_import_failed      CONSTANT NUMBER := -20041;
    
    -- Named exceptions for PRAGMA EXCEPTION_INIT
    e_invalid_frequency EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_frequency, -20004);
    
    -- ========================================================
    -- Record Types
    -- ========================================================
    
    -- Case status record (mirrors API response)
    TYPE t_case_status IS RECORD (
        receipt_number    VARCHAR2(13),
        case_type         VARCHAR2(100),
        current_status    VARCHAR2(500),
        last_updated      TIMESTAMP,
        details           CLOB
    );
    
    -- Case history record (with tracking info)
    TYPE t_case_history IS RECORD (
        receipt_number    VARCHAR2(13),
        created_at        TIMESTAMP,
        created_by        VARCHAR2(255),
        notes             CLOB,
        is_active         NUMBER(1),
        last_checked_at   TIMESTAMP,
        check_frequency   NUMBER,
        status_count      NUMBER
    );
    
    -- Case with current status (joined data)
    TYPE t_case_full IS RECORD (
        receipt_number    VARCHAR2(13),
        tracking_since    TIMESTAMP,
        created_by        VARCHAR2(255),
        notes             CLOB,
        is_active         NUMBER(1),
        last_checked_at   TIMESTAMP,
        check_frequency   NUMBER,
        case_type         VARCHAR2(100),
        current_status    VARCHAR2(500),
        last_updated      TIMESTAMP,
        details           CLOB,
        total_updates     NUMBER
    );
    
    -- OAuth token record
    TYPE t_oauth_token IS RECORD (
        token_id          NUMBER,
        service_name      VARCHAR2(50),
        access_token      VARCHAR2(4000),
        token_type        VARCHAR2(50),
        expires_at        TIMESTAMP,
        created_at        TIMESTAMP,
        last_used_at      TIMESTAMP
    );
    
    -- API result wrapper
    TYPE t_api_result IS RECORD (
        success           BOOLEAN,
        data              CLOB,
        error_message     VARCHAR2(4000),
        http_status       NUMBER,
        response_time_ms  NUMBER
    );
    
    -- Audit log record
    TYPE t_audit_entry IS RECORD (
        audit_id          NUMBER,
        receipt_number    VARCHAR2(13),
        action            VARCHAR2(50),
        old_values        CLOB,
        new_values        CLOB,
        performed_by      VARCHAR2(255),
        performed_at      TIMESTAMP,
        ip_address        VARCHAR2(45)
    );
    
    -- ========================================================
    -- Collection Types (TABLE OF)
    -- ========================================================
    
    TYPE t_case_status_tab    IS TABLE OF t_case_status;
    TYPE t_case_history_tab   IS TABLE OF t_case_history;
    TYPE t_case_full_tab      IS TABLE OF t_case_full;
    TYPE t_audit_entry_tab    IS TABLE OF t_audit_entry;
    
    TYPE t_receipt_tab        IS TABLE OF VARCHAR2(13);
    TYPE t_string_tab         IS TABLE OF VARCHAR2(4000);
    TYPE t_number_tab         IS TABLE OF NUMBER;
    
    -- ========================================================
    -- Associative Array Types (INDEX BY)
    -- ========================================================
    
    TYPE t_string_map IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(100);
    TYPE t_number_map IS TABLE OF NUMBER INDEX BY VARCHAR2(100);
    
    -- ========================================================
    -- Package Info Functions
    -- ========================================================
    
    -- Get package version
    FUNCTION get_version RETURN VARCHAR2;
    
    -- Get package info as JSON
    FUNCTION get_info RETURN CLOB;
    
END uscis_types_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_types_pkg AS

    -- --------------------------------------------------------
    -- Get package version
    -- --------------------------------------------------------
    FUNCTION get_version RETURN VARCHAR2 IS
    BEGIN
        RETURN gc_version;
    END get_version;
    
    -- --------------------------------------------------------
    -- Get package info as JSON
    -- --------------------------------------------------------
    FUNCTION get_info RETURN CLOB IS
        l_json         CLOB;
        l_compiled_utc VARCHAR2(30);
    BEGIN
        -- Get actual package compile time from ALL_OBJECTS.LAST_DDL_TIME
        BEGIN
            SELECT TO_CHAR(
                       CAST(last_ddl_time AS TIMESTAMP) AT TIME ZONE 'UTC',
                       'YYYY-MM-DD"T"HH24:MI:SS"Z"'
                   )
            INTO l_compiled_utc
            FROM all_objects
            WHERE object_name = 'USCIS_TYPES_PKG'
              AND object_type = 'PACKAGE BODY'
              AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_compiled_utc := 'unknown';
        END;

        l_json := '{' ||
            '"package": "' || gc_package_name || '",' ||
            '"version": "' || gc_version || '",' ||
            '"compiled": "' || l_compiled_utc || '",' ||
            '"constants": {' ||
                '"receipt_pattern": "' || gc_receipt_pattern || '",' ||
                '"receipt_length": ' || gc_receipt_length || ',' ||
                '"rate_limit_tps": ' || gc_rate_limit_tps || ',' ||
                '"daily_limit": ' || gc_daily_limit ||
            '}' ||
        '}';
        RETURN l_json;
    END get_info;

END uscis_types_pkg;
/

SHOW ERRORS PACKAGE uscis_types_pkg
SHOW ERRORS PACKAGE BODY uscis_types_pkg

PROMPT ============================================================
PROMPT USCIS_TYPES_PKG created successfully
PROMPT ============================================================
