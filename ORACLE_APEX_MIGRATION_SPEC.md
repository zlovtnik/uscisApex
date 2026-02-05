# USCIS Case Tracker: Oracle PL/SQL & APEX Migration Specification

**Version:** 1.0  
**Date:** February 3, 2026  
**Status:** Draft  
**Author:** Migration Team  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current Architecture Analysis](#2-current-architecture-analysis)
3. [Target Architecture](#3-target-architecture)
4. [Database Schema Design](#4-database-schema-design)
5. [PL/SQL Package Design](#5-plsql-package-design)
6. [Oracle APEX Application Design](#6-oracle-apex-application-design)
7. [USCIS API Integration](#7-uscis-api-integration)
8. [Security Considerations](#8-security-considerations)
9. [Migration Strategy](#9-migration-strategy)
10. [Testing Strategy](#10-testing-strategy)
11. [Deployment Architecture](#11-deployment-architecture)

---

## 1. Executive Summary

### 1.1 Project Overview

This specification details the migration of the USCIS Case Tracker application from a Scala/Cats Effect/gRPC architecture to an Oracle PL/SQL and APEX-based solution. The migration consolidates the application stack into Oracle's native technologies, providing:

- **Simplified Architecture**: Single Oracle database platform for logic and UI
- **Reduced Operational Complexity**: No JVM runtime, gRPC infrastructure, or separate frontend
- **Native Oracle Integration**: Leverage Oracle Autonomous Database features
- **Low-Code Frontend**: Oracle APEX for rapid UI development
- **Enterprise Security**: Oracle's built-in security and audit capabilities

### 1.2 Scope

| In Scope | Out of Scope |
|----------|--------------|
| Database schema migration | Mobile native apps |
| PL/SQL business logic packages | Third-party integrations beyond USCIS API |
| Oracle APEX web application | Real-time push notifications |
| USCIS API integration via APEX/UTL_HTTP | gRPC API compatibility layer |
| OAuth2 token management | Legacy data migration (new deployment) |
| User authentication (APEX native) | Multi-tenant architecture |

### 1.3 Success Criteria

- [ ] All existing gRPC service operations functional in APEX
- [ ] USCIS API integration working with OAuth2
- [ ] Response time < 2 seconds for standard operations
- [ ] APEX application accessible on desktop and mobile browsers
- [ ] Automated status checking via DBMS_SCHEDULER
- [ ] Audit trail for all case operations

---

## 2. Current Architecture Analysis

### 2.1 Technology Stack (Source)

```
┌─────────────────────────────────────────────────────────────┐
│                    Current Architecture                      │
├─────────────────────────────────────────────────────────────┤
│  Client Layer                                                │
│  ├── gRPC Clients (HTTP/2)                                  │
│  ├── gRPC-Web Clients (HTTP/1.1)                            │
│  └── Health Check Endpoints (HTTP)                          │
├─────────────────────────────────────────────────────────────┤
│  Application Layer (Scala/JVM)                              │
│  ├── Armeria Server (gRPC + HTTP)                           │
│  ├── fs2-grpc Service Implementation                        │
│  ├── Cats Effect IO Runtime                                 │
│  └── http4s Client (USCIS API)                              │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ├── JSON File Storage (~/.uscis-tracker/cases.json)        │
│  └── Oracle Database (Optional - Doobie/HikariCP)           │
├─────────────────────────────────────────────────────────────┤
│  External Services                                           │
│  └── USCIS Developer API (OAuth2 + REST)                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Existing Data Models

#### CaseStatus
```scala
case class CaseStatus(
  receiptNumber: String,      // Primary key: 3 letters + 10 digits (e.g., IOE1234567890)
  caseType: String,           // Form type (e.g., "I-485", "I-765")
  currentStatus: String,      // Status text (e.g., "Case Was Received")
  lastUpdated: LocalDateTime, // Timestamp of last status change
  details: Option[String]     // Extended status description
)
```

#### CaseHistory
```scala
case class CaseHistory(
  receiptNumber: String,
  statusUpdates: List[CaseStatus]  // Ordered newest to oldest
)
```

### 2.3 Existing API Operations

| gRPC Method | Description | Complexity |
|-------------|-------------|------------|
| `AddCase` | Add/update case, optionally fetch from USCIS | Medium |
| `GetCase` | Retrieve case with optional history | Low |
| `ListCases` | Paginated list with filter support | Low |
| `CheckStatus` | Query USCIS API for live status | High |
| `DeleteCase` | Remove case from tracking | Low |
| `ExportCases` | Stream export as JSON | Medium |
| `ImportCases` | Stream import from JSON | Medium |
| `WatchCases` | Server-streaming status updates | High |
| `HealthCheck` | Service health status | Low |

### 2.4 USCIS API Integration Points

- **Token URL**: `https://api-int.uscis.gov/oauth/accesstoken`
- **Case Status URL**: `https://api-int.uscis.gov/case-status/{receiptNumber}`
- **Authentication**: OAuth2 Client Credentials Grant
- **Rate Limits**: 10 TPS, 400,000 requests/day
- **Token Caching**: Required (tokens valid ~3600 seconds)

---

## 3. Target Architecture

### 3.1 Oracle Stack Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Target Architecture                       │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (Oracle APEX)                           │
│  ├── APEX Application (Desktop + Mobile Responsive)         │
│  ├── Interactive Reports & Grids                            │
│  ├── Case Dashboard with Status Charts                      │
│  ├── RESTful Services Module (optional external API)        │
│  └── Progressive Web App (PWA) capabilities                 │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (PL/SQL)                              │
│  ├── USCIS_CASE_PKG (Core CRUD operations)                  │
│  ├── USCIS_API_PKG (External API integration)               │
│  ├── USCIS_OAUTH_PKG (Token management)                     │
│  ├── USCIS_SCHEDULER_PKG (Automated status checks)          │
│  └── USCIS_EXPORT_PKG (Import/Export utilities)             │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Oracle Database)                               │
│  ├── Tables: CASE_HISTORY, STATUS_UPDATES, OAUTH_TOKENS     │
│  ├── Views: V_CASE_CURRENT_STATUS, V_CASE_DASHBOARD         │
│  ├── Indexes: Receipt number, status date, filters          │
│  └── Audit: CASE_AUDIT_LOG                                  │
├─────────────────────────────────────────────────────────────┤
│  Integration Layer                                           │
│  ├── ACL Configuration (network access)                     │
│  ├── Oracle Wallet (HTTPS certificates)                     │
│  ├── APEX Web Credentials (OAuth2)                          │
│  └── DBMS_SCHEDULER (background jobs)                       │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Component Mapping

| Source Component | Target Component |
|------------------|------------------|
| Scala Case Classes | Oracle Tables + Types |
| gRPC Service Methods | PL/SQL Package Procedures |
| fs2 Streaming | APEX IR/IG + Pagination |
| http4s Client | APEX_WEB_SERVICE / UTL_HTTP |
| OAuth2 Token Cache | OAUTH_TOKENS table |
| JSON File Storage | Oracle Tables |
| Cats Effect IO | PL/SQL + APEX Processes |
| Rate Limiter Semaphore | Token bucket in table |
| Health Endpoints | APEX REST Module |

---

## 4. Database Schema Design

### 4.1 Entity Relationship Diagram

```
                    ┌─────────────────────┐
                    │    APEX_USERS       │
                    │  (APEX Built-in)    │
                    └─────────┬───────────┘
                              │ 1:M
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      CASE_HISTORY                            │
├─────────────────────────────────────────────────────────────┤
│ PK  receipt_number     VARCHAR2(13)   NOT NULL              │
│     created_at         TIMESTAMP      DEFAULT SYSTIMESTAMP  │
│     created_by         VARCHAR2(255)  -- APEX user          │
│     notes              CLOB           -- User notes         │
│     is_active          NUMBER(1)      DEFAULT 1             │
│     last_checked_at    TIMESTAMP      -- Last API check     │
│     check_frequency    NUMBER         DEFAULT 24 (hours)    │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 1:M
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     STATUS_UPDATES                           │
├─────────────────────────────────────────────────────────────┤
│ PK  id                 NUMBER GENERATED ALWAYS AS IDENTITY  │
│ FK  receipt_number     VARCHAR2(13)   NOT NULL              │
│     case_type          VARCHAR2(100)  NOT NULL              │
│     current_status     VARCHAR2(500)  NOT NULL              │
│     last_updated       TIMESTAMP      NOT NULL              │
│     details            CLOB                                 │
│     source             VARCHAR2(20)   DEFAULT 'MANUAL'      │
│                        -- 'MANUAL', 'API', 'IMPORT'         │
│     api_response_json  CLOB           -- Raw API response   │
│     created_at         TIMESTAMP      DEFAULT SYSTIMESTAMP  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      OAUTH_TOKENS                            │
├─────────────────────────────────────────────────────────────┤
│ PK  token_id           NUMBER GENERATED ALWAYS AS IDENTITY  │
│     service_name       VARCHAR2(50)   NOT NULL UNIQUE       │
│     access_token       VARCHAR2(4000) NOT NULL              │
│     token_type         VARCHAR2(50)   DEFAULT 'Bearer'      │
│     expires_at         TIMESTAMP      NOT NULL              │
│     created_at         TIMESTAMP      DEFAULT SYSTIMESTAMP  │
│     last_used_at       TIMESTAMP                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    API_RATE_LIMITER                          │
├─────────────────────────────────────────────────────────────┤
│ PK  limiter_id         NUMBER GENERATED ALWAYS AS IDENTITY  │
│     service_name       VARCHAR2(50)   NOT NULL              │
│     last_request_at    TIMESTAMP      NOT NULL              │
│     request_count      NUMBER         DEFAULT 0             │
│     window_start       TIMESTAMP                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    CASE_AUDIT_LOG                            │
├─────────────────────────────────────────────────────────────┤
│ PK  audit_id           NUMBER GENERATED ALWAYS AS IDENTITY  │
│     receipt_number     VARCHAR2(13)                         │
│     action             VARCHAR2(50)   NOT NULL              │
│                        -- 'INSERT','UPDATE','DELETE','CHECK'│
│     old_values         CLOB           -- JSON               │
│     new_values         CLOB           -- JSON               │
│     performed_by       VARCHAR2(255)                        │
│     performed_at       TIMESTAMP      DEFAULT SYSTIMESTAMP  │
│     ip_address         VARCHAR2(45)                         │
│     user_agent         VARCHAR2(500)                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   SCHEDULER_CONFIG                           │
├─────────────────────────────────────────────────────────────┤
│ PK  config_id          NUMBER GENERATED ALWAYS AS IDENTITY  │
│     config_key         VARCHAR2(100)  NOT NULL UNIQUE       │
│     config_value       VARCHAR2(4000)                       │
│     description        VARCHAR2(500)                        │
│     updated_at         TIMESTAMP      DEFAULT SYSTIMESTAMP  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 DDL Scripts

```sql
-- ============================================================
-- USCIS Case Tracker Database Schema
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================

-- Tablespace (optional for on-prem)
-- CREATE TABLESPACE uscis_data DATAFILE SIZE 100M AUTOEXTEND ON;

-- Schema user (optional)
-- CREATE USER uscis_app IDENTIFIED BY "SecurePassword123!"
--   DEFAULT TABLESPACE uscis_data
--   QUOTA UNLIMITED ON uscis_data;
-- GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, 
--       CREATE SEQUENCE, CREATE VIEW, CREATE TRIGGER TO uscis_app;

-- ============================================================
-- Core Tables
-- ============================================================

CREATE TABLE case_history (
    receipt_number    VARCHAR2(13)    NOT NULL,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    created_by        VARCHAR2(255),
    notes             CLOB,
    is_active         NUMBER(1)       DEFAULT 1 NOT NULL,
    last_checked_at   TIMESTAMP,
    check_frequency   NUMBER          DEFAULT 24,
    --
    CONSTRAINT pk_case_history PRIMARY KEY (receipt_number),
    CONSTRAINT chk_receipt_format CHECK (
        REGEXP_LIKE(receipt_number, '^[A-Z]{3}[0-9]{10}$')
    ),
    CONSTRAINT chk_is_active CHECK (is_active IN (0, 1))
);

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
    CONSTRAINT pk_status_updates PRIMARY KEY (id),
    CONSTRAINT fk_status_receipt FOREIGN KEY (receipt_number)
        REFERENCES case_history(receipt_number) ON DELETE CASCADE,
    CONSTRAINT chk_source CHECK (source IN ('MANUAL', 'API', 'IMPORT'))
);

CREATE INDEX idx_status_receipt ON status_updates(receipt_number);
CREATE INDEX idx_status_date ON status_updates(last_updated DESC);
CREATE INDEX idx_status_receipt_date ON status_updates(receipt_number, last_updated DESC);

CREATE TABLE oauth_tokens (
    token_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    service_name      VARCHAR2(50)    NOT NULL,
    access_token      VARCHAR2(4000)  NOT NULL,
    token_type        VARCHAR2(50)    DEFAULT 'Bearer',
    expires_at        TIMESTAMP       NOT NULL,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    last_used_at      TIMESTAMP,
    --
    CONSTRAINT pk_oauth_tokens PRIMARY KEY (token_id),
    CONSTRAINT uk_oauth_service UNIQUE (service_name)
);

CREATE TABLE api_rate_limiter (
    limiter_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    service_name      VARCHAR2(50)    NOT NULL,
    last_request_at   TIMESTAMP       NOT NULL,
    request_count     NUMBER          DEFAULT 0,
    window_start      TIMESTAMP,
    --
    CONSTRAINT pk_api_rate_limiter PRIMARY KEY (limiter_id),
    CONSTRAINT uk_limiter_service UNIQUE (service_name)
);

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
    CONSTRAINT pk_case_audit_log PRIMARY KEY (audit_id),
    CONSTRAINT chk_audit_action CHECK (
        action IN ('INSERT', 'UPDATE', 'DELETE', 'CHECK', 'EXPORT', 'IMPORT')
    )
);

CREATE INDEX idx_audit_receipt ON case_audit_log(receipt_number);
CREATE INDEX idx_audit_date ON case_audit_log(performed_at DESC);

CREATE TABLE scheduler_config (
    config_id         NUMBER GENERATED ALWAYS AS IDENTITY,
    config_key        VARCHAR2(100)   NOT NULL,
    config_value      VARCHAR2(4000),
    description       VARCHAR2(500),
    updated_at        TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    --
    CONSTRAINT pk_scheduler_config PRIMARY KEY (config_id),
    CONSTRAINT uk_config_key UNIQUE (config_key)
);

-- ============================================================
-- Views
-- ============================================================

CREATE OR REPLACE VIEW v_case_current_status AS
WITH status_window AS (
    SELECT receipt_number,
           case_type,
           current_status,
           last_updated,
           details,
           source,
           ROW_NUMBER() OVER (PARTITION BY receipt_number ORDER BY id DESC) AS rn,
           COUNT(*) OVER (PARTITION BY receipt_number) AS total_updates
    FROM status_updates
)
SELECT 
    ch.receipt_number,
    ch.created_at AS tracking_since,
    ch.created_by,
    ch.notes,
    ch.is_active,
    ch.last_checked_at,
    ch.check_frequency,
    sw.case_type,
    sw.current_status,
    sw.last_updated,
    sw.details,
    sw.source AS last_update_source,
    sw.total_updates
FROM case_history ch
LEFT JOIN status_window sw ON sw.receipt_number = ch.receipt_number AND sw.rn = 1;

CREATE OR REPLACE VIEW v_case_dashboard AS
SELECT 
    current_status,
    COUNT(*) AS case_count,
    MIN(last_updated) AS oldest_update,
    MAX(last_updated) AS newest_update
FROM v_case_current_status
WHERE is_active = 1
GROUP BY current_status
ORDER BY case_count DESC;

CREATE OR REPLACE VIEW v_recent_activity AS
SELECT 
    cal.performed_at,
    cal.action,
    cal.receipt_number,
    cal.performed_by,
    vcs.current_status,
    vcs.case_type
FROM case_audit_log cal
LEFT JOIN v_case_current_status vcs ON vcs.receipt_number = cal.receipt_number
ORDER BY cal.performed_at DESC
FETCH FIRST 100 ROWS ONLY;

-- ============================================================
-- Default Configuration
-- ============================================================

INSERT INTO scheduler_config (config_key, config_value, description) VALUES
    ('USCIS_API_BASE_URL', 'https://api-int.uscis.gov/case-status', 'USCIS Case Status API base URL'),
    ('USCIS_OAUTH_TOKEN_URL', 'https://api-int.uscis.gov/oauth/accesstoken', 'USCIS OAuth2 token URL'),
    ('RATE_LIMIT_REQUESTS_PER_SECOND', '10', 'Max API requests per second'),
    ('RATE_LIMIT_MIN_INTERVAL_MS', '100', 'Minimum milliseconds between requests'),
    ('AUTO_CHECK_ENABLED', 'Y', 'Enable automatic status checks'),
    ('AUTO_CHECK_INTERVAL_HOURS', '24', 'Hours between automatic checks'),
    ('AUTO_CHECK_BATCH_SIZE', '50', 'Cases to check per batch'),
    ('TOKEN_REFRESH_BUFFER_SECONDS', '60', 'Refresh token this many seconds before expiry');

COMMIT;
```

---

## 5. PL/SQL Package Design

### 5.1 Package Overview

| Package | Purpose | Dependencies |
|---------|---------|--------------|
| `USCIS_TYPES_PKG` | Type definitions and constants | None |
| `USCIS_UTIL_PKG` | Utility functions (validation, masking) | USCIS_TYPES_PKG |
| `USCIS_CASE_PKG` | Core CRUD operations | USCIS_UTIL_PKG |
| `USCIS_OAUTH_PKG` | OAuth2 token management | APEX_WEB_SERVICE |
| `USCIS_API_PKG` | USCIS API integration | USCIS_OAUTH_PKG |
| `USCIS_SCHEDULER_PKG` | Background job management | USCIS_API_PKG, DBMS_SCHEDULER |
| `USCIS_EXPORT_PKG` | Import/Export utilities | USCIS_CASE_PKG |
| `USCIS_AUDIT_PKG` | Audit logging | None |

### 5.2 Package Specifications

```sql
-- ============================================================
-- USCIS_TYPES_PKG: Type Definitions
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_types_pkg AS
    
    -- Constants
    gc_receipt_pattern    CONSTANT VARCHAR2(30) := '^[A-Z]{3}[0-9]{10}$';
    gc_source_manual      CONSTANT VARCHAR2(20) := 'MANUAL';
    gc_source_api         CONSTANT VARCHAR2(20) := 'API';
    gc_source_import      CONSTANT VARCHAR2(20) := 'IMPORT';
    gc_service_uscis      CONSTANT VARCHAR2(50) := 'USCIS_CASE_STATUS';
    
    -- Record Types
    TYPE t_case_status IS RECORD (
        receipt_number    VARCHAR2(13),
        case_type         VARCHAR2(100),
        current_status    VARCHAR2(500),
        last_updated      TIMESTAMP,
        details           CLOB
    );
    
    TYPE t_case_history IS RECORD (
        receipt_number    VARCHAR2(13),
        created_at        TIMESTAMP,
        notes             CLOB,
        is_active         NUMBER(1),
        status_count      NUMBER
    );
    
    -- Collection Types
    TYPE t_case_status_tab IS TABLE OF t_case_status;
    TYPE t_receipt_tab IS TABLE OF VARCHAR2(13);
    TYPE t_string_tab IS TABLE OF VARCHAR2(4000);
    
    -- Result wrapper for API calls
    TYPE t_api_result IS RECORD (
        success           BOOLEAN,
        data              CLOB,
        error_message     VARCHAR2(4000),
        http_status       NUMBER
    );
    
END uscis_types_pkg;
/

-- ============================================================
-- USCIS_UTIL_PKG: Utility Functions
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_util_pkg AS
    
    -- Validate receipt number format
    FUNCTION validate_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Normalize receipt number (uppercase, remove non-alphanumeric)
    FUNCTION normalize_receipt_number(
        p_input IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Mask receipt number for logging (IOE****1234)
    FUNCTION mask_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Get configuration value
    FUNCTION get_config(
        p_key IN VARCHAR2,
        p_default IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
    
    -- Set configuration value
    PROCEDURE set_config(
        p_key   IN VARCHAR2,
        p_value IN VARCHAR2
    );
    
    -- Parse ISO timestamp string
    FUNCTION parse_iso_timestamp(
        p_timestamp_str IN VARCHAR2
    ) RETURN TIMESTAMP;
    
    -- Get current APEX user
    FUNCTION get_current_user RETURN VARCHAR2;
    
    -- Get client IP address
    FUNCTION get_client_ip RETURN VARCHAR2;
    
END uscis_util_pkg;
/

-- ============================================================
-- USCIS_CASE_PKG: Core CRUD Operations
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_case_pkg AS
    
    -- Exception definitions
    e_invalid_receipt     EXCEPTION;
    e_case_not_found      EXCEPTION;
    e_duplicate_case      EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_invalid_receipt, -20001);
    PRAGMA EXCEPTION_INIT(e_case_not_found, -20002);
    PRAGMA EXCEPTION_INIT(e_duplicate_case, -20003);
    
    -- Add a new case (returns receipt_number)
    FUNCTION add_case(
        p_receipt_number  IN VARCHAR2,
        p_case_type       IN VARCHAR2 DEFAULT 'Unknown',
        p_current_status  IN VARCHAR2 DEFAULT 'Pending',
        p_details         IN CLOB DEFAULT NULL,
        p_notes           IN CLOB DEFAULT NULL,
        p_fetch_from_uscis IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2;
    
    -- Add or update case status
    PROCEDURE add_or_update_case(
        p_receipt_number  IN VARCHAR2,
        p_case_type       IN VARCHAR2,
        p_current_status  IN VARCHAR2,
        p_last_updated    IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details         IN CLOB DEFAULT NULL,
        p_source          IN VARCHAR2 DEFAULT 'MANUAL'
    );
    
    -- Get case by receipt number (returns cursor)
    FUNCTION get_case(
        p_receipt_number   IN VARCHAR2,
        p_include_history  IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR;
    
    -- List cases with pagination
    FUNCTION list_cases(
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_page_size       IN NUMBER DEFAULT 20,
        p_page            IN NUMBER DEFAULT 1,
        p_include_history IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR;
    
    -- Get total case count (with optional filter)
    FUNCTION count_cases(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT TRUE
    ) RETURN NUMBER;
    
    -- Delete case
    PROCEDURE delete_case(
        p_receipt_number IN VARCHAR2
    );
    
    -- Check if case exists
    FUNCTION case_exists(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Get cases by multiple receipt numbers
    FUNCTION get_cases_by_receipts(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    ) RETURN SYS_REFCURSOR;
    
    -- Update case notes
    PROCEDURE update_case_notes(
        p_receipt_number IN VARCHAR2,
        p_notes          IN CLOB
    );
    
    -- Toggle case active status
    PROCEDURE set_case_active(
        p_receipt_number IN VARCHAR2,
        p_is_active      IN BOOLEAN
    );
    
END uscis_case_pkg;
/

-- ============================================================
-- USCIS_OAUTH_PKG: OAuth2 Token Management
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_oauth_pkg AS
    
    -- Exception for authentication failures
    e_auth_failed EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_auth_failed, -20010);
    
    -- Get valid access token (fetches new one if expired)
    FUNCTION get_access_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_CASE_STATUS'
    ) RETURN VARCHAR2;
    
    -- Fetch new access token from OAuth server
    FUNCTION fetch_new_token(
        p_client_id     IN VARCHAR2,
        p_client_secret IN VARCHAR2,
        p_token_url     IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Check if current token is valid
    FUNCTION is_token_valid(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_CASE_STATUS'
    ) RETURN BOOLEAN;
    
    -- Clear cached token (force refresh)
    PROCEDURE clear_token(
        p_service_name IN VARCHAR2 DEFAULT 'USCIS_CASE_STATUS'
    );
    
    -- Check if credentials are configured
    FUNCTION has_credentials RETURN BOOLEAN;
    
END uscis_oauth_pkg;
/

-- ============================================================
-- USCIS_API_PKG: USCIS API Integration
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_api_pkg AS
    
    -- Exception for API errors
    e_api_error EXCEPTION;
    e_rate_limited EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_api_error, -20020);
    PRAGMA EXCEPTION_INIT(e_rate_limited, -20021);
    
    -- Check case status from USCIS API
    FUNCTION check_case_status(
        p_receipt_number   IN VARCHAR2,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- Check multiple cases with rate limiting
    PROCEDURE check_multiple_cases(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    );
    
    -- Apply rate limiting (waits if necessary)
    PROCEDURE apply_rate_limit;
    
    -- Get mock response (when API not configured)
    FUNCTION get_mock_response(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status;
    
    -- Parse API response JSON
    FUNCTION parse_api_response(
        p_json_response IN CLOB
    ) RETURN uscis_types_pkg.t_case_status;
    
END uscis_api_pkg;
/

-- ============================================================
-- USCIS_SCHEDULER_PKG: Background Job Management
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_scheduler_pkg AS
    
    -- Job names
    gc_job_auto_check CONSTANT VARCHAR2(30) := 'USCIS_AUTO_CHECK_JOB';
    gc_job_token_refresh CONSTANT VARCHAR2(30) := 'USCIS_TOKEN_REFRESH_JOB';
    gc_job_cleanup CONSTANT VARCHAR2(30) := 'USCIS_CLEANUP_JOB';
    
    -- Create/schedule automatic status check job
    PROCEDURE create_auto_check_job(
        p_interval_hours IN NUMBER DEFAULT 24
    );
    
    -- Run automatic status check (called by scheduler)
    PROCEDURE run_auto_check;
    
    -- Create token refresh job
    PROCEDURE create_token_refresh_job;
    
    -- Create cleanup job (old audit logs, etc.)
    PROCEDURE create_cleanup_job;
    
    -- Enable/disable automatic checking
    PROCEDURE set_auto_check_enabled(
        p_enabled IN BOOLEAN
    );
    
    -- Get job status
    FUNCTION get_job_status(
        p_job_name IN VARCHAR2
    ) RETURN VARCHAR2;
    
    -- Drop all scheduler jobs
    PROCEDURE drop_all_jobs;
    
END uscis_scheduler_pkg;
/

-- ============================================================
-- USCIS_EXPORT_PKG: Import/Export Utilities
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_export_pkg AS
    
    -- Export all cases as JSON
    FUNCTION export_cases_json(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_include_history IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB;
    
    -- Import cases from JSON
    FUNCTION import_cases_json(
        p_json_data       IN CLOB,
        p_replace_existing IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER; -- Returns count of imported cases
    
    -- Export as CSV
    FUNCTION export_cases_csv(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;
    
    -- Generate APEX download
    PROCEDURE download_export(
        p_format         IN VARCHAR2 DEFAULT 'JSON',  -- JSON, CSV
        p_receipt_filter IN VARCHAR2 DEFAULT NULL
    );
    
END uscis_export_pkg;
/

-- ============================================================
-- USCIS_AUDIT_PKG: Audit Logging
-- ============================================================
CREATE OR REPLACE PACKAGE uscis_audit_pkg AS
    
    -- Log an audit event
    PROCEDURE log_event(
        p_receipt_number IN VARCHAR2,
        p_action         IN VARCHAR2,
        p_old_values     IN CLOB DEFAULT NULL,
        p_new_values     IN CLOB DEFAULT NULL
    );
    
    -- Get audit history for a case
    FUNCTION get_case_audit(
        p_receipt_number IN VARCHAR2
    ) RETURN SYS_REFCURSOR;
    
    -- Get recent activity
    FUNCTION get_recent_activity(
        p_limit IN NUMBER DEFAULT 100
    ) RETURN SYS_REFCURSOR;
    
    -- Purge old audit records
    PROCEDURE purge_old_records(
        p_days_to_keep IN NUMBER DEFAULT 365
    );
    
END uscis_audit_pkg;
/
```

### 5.3 Package Body Implementation (Key Procedures)

```sql
-- ============================================================
-- USCIS_UTIL_PKG Body
-- ============================================================
CREATE OR REPLACE PACKAGE BODY uscis_util_pkg AS

    FUNCTION validate_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(UPPER(p_receipt_number), uscis_types_pkg.gc_receipt_pattern);
    END validate_receipt_number;
    
    FUNCTION normalize_receipt_number(
        p_input IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN UPPER(REGEXP_REPLACE(p_input, '[^A-Za-z0-9]', ''));
    END normalize_receipt_number;
    
    FUNCTION mask_receipt_number(
        p_receipt_number IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_len NUMBER := LENGTH(p_receipt_number);
    BEGIN
        IF l_len >= 7 THEN
            RETURN SUBSTR(p_receipt_number, 1, 3) || '****' || SUBSTR(p_receipt_number, -4);
        ELSIF l_len >= 3 THEN
            RETURN SUBSTR(p_receipt_number, 1, 3) || '****';
        ELSE
            RETURN '****';
        END IF;
    END mask_receipt_number;
    
    FUNCTION get_config(
        p_key     IN VARCHAR2,
        p_default IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(4000);
    BEGIN
        SELECT config_value INTO l_value
        FROM scheduler_config
        WHERE config_key = p_key;
        RETURN NVL(l_value, p_default);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN p_default;
    END get_config;
    
    -- ============================================================================
    -- WARNING: AUTONOMOUS TRANSACTION BEHAVIOR
    -- ============================================================================
    -- This procedure uses PRAGMA AUTONOMOUS_TRANSACTION, making changes to
    -- scheduler_config persistent immediately and independent of the caller's
    -- transaction.
    --
    -- IMPORTANT CONSIDERATIONS:
    --   - Caller rollbacks do NOT revert changes made by this procedure
    --   - Concurrent updates follow last-write-wins semantics
    --   - Changes are immediately visible to other sessions
    --
    -- RECOMMENDATION: For operations requiring transactional atomicity (where
    -- config changes should roll back with the parent transaction), use
    -- set_config_txn instead.
    -- ============================================================================
    PROCEDURE set_config(
        p_key   IN VARCHAR2,
        p_value IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        MERGE INTO scheduler_config sc
        USING (SELECT p_key AS config_key FROM dual) src
        ON (sc.config_key = src.config_key)
        WHEN MATCHED THEN
            UPDATE SET config_value = p_value, updated_at = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (config_key, config_value) VALUES (p_key, p_value);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END set_config;
    
    -- Non-autonomous alternative for transactional consistency
    -- Use when config changes must be part of the caller's transaction
    PROCEDURE set_config_txn(
        p_key   IN VARCHAR2,
        p_value IN VARCHAR2
    ) IS
    BEGIN
        MERGE INTO scheduler_config sc
        USING (SELECT p_key AS config_key FROM dual) src
        ON (sc.config_key = src.config_key)
        WHEN MATCHED THEN
            UPDATE SET config_value = p_value, updated_at = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (config_key, config_value) VALUES (p_key, p_value);
        -- NOTE: Caller must COMMIT
    END set_config_txn;
    
    FUNCTION parse_iso_timestamp(
        p_timestamp_str IN VARCHAR2
    ) RETURN TIMESTAMP IS
    BEGIN
        -- Handle ISO 8601 format: 2024-01-15T10:30:00
        RETURN TO_TIMESTAMP(SUBSTR(p_timestamp_str, 1, 19), 'YYYY-MM-DD"T"HH24:MI:SS');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SYSTIMESTAMP;
    END parse_iso_timestamp;
    
    FUNCTION get_current_user RETURN VARCHAR2 IS
    BEGIN
        RETURN NVL(
            V('APP_USER'),
            NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER)
        );
    END get_current_user;
    
    FUNCTION get_client_ip RETURN VARCHAR2 IS
    BEGIN
        RETURN NVL(
            OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR'),
            SYS_CONTEXT('USERENV', 'IP_ADDRESS')
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_client_ip;

END uscis_util_pkg;
/

-- ============================================================
-- USCIS_CASE_PKG Body (Core Operations)
-- ============================================================
CREATE OR REPLACE PACKAGE BODY uscis_case_pkg AS

    FUNCTION add_case(
        p_receipt_number   IN VARCHAR2,
        p_case_type        IN VARCHAR2 DEFAULT 'Unknown',
        p_current_status   IN VARCHAR2 DEFAULT 'Pending',
        p_details          IN CLOB DEFAULT NULL,
        p_notes            IN CLOB DEFAULT NULL,
        p_fetch_from_uscis IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2 IS
        l_normalized VARCHAR2(13);
        l_status     uscis_types_pkg.t_case_status;
    BEGIN
        -- Normalize and validate
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'Invalid receipt number format: ' || p_receipt_number || 
                '. Expected format: 3 letters + 10 digits');
        END IF;
        
        -- Check for duplicate
        IF case_exists(l_normalized) THEN
            RAISE_APPLICATION_ERROR(-20003, 
                'Case already exists: ' || uscis_util_pkg.mask_receipt_number(l_normalized));
        END IF;
        
        -- Insert case history record
        BEGIN
            INSERT INTO case_history (
                receipt_number, created_by, notes
            ) VALUES (
                l_normalized, uscis_util_pkg.get_current_user, p_notes
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(-20003, 
                    'Case already exists: ' || uscis_util_pkg.mask_receipt_number(l_normalized));
        END;
        
        -- Fetch from USCIS or use provided values
        IF p_fetch_from_uscis THEN
            l_status := uscis_api_pkg.check_case_status(l_normalized, TRUE);
        ELSE
            -- Insert initial status
            INSERT INTO status_updates (
                receipt_number, case_type, current_status, 
                last_updated, details, source
            ) VALUES (
                l_normalized, p_case_type, p_current_status,
                SYSTIMESTAMP, p_details, uscis_types_pkg.gc_source_manual
            );
        END IF;
        
        -- Log audit
        uscis_audit_pkg.log_event(
            p_receipt_number => l_normalized,
            p_action         => 'INSERT',
            p_new_values     => JSON_OBJECT(
                'case_type' VALUE NVL(l_status.case_type, p_case_type),
                'status' VALUE NVL(l_status.current_status, p_current_status)
            )
        );
        
        -- NOTE: COMMIT removed - callers control transaction boundaries
        -- APEX pages will auto-commit, batch processes should explicitly commit
        RETURN l_normalized;
        
    END add_case;
    
    PROCEDURE add_or_update_case(
        p_receipt_number  IN VARCHAR2,
        p_case_type       IN VARCHAR2,
        p_current_status  IN VARCHAR2,
        p_last_updated    IN TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_details         IN CLOB DEFAULT NULL,
        p_source          IN VARCHAR2 DEFAULT 'MANUAL'
    ) IS
        l_normalized VARCHAR2(13);
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'Invalid receipt number format: ' || p_receipt_number);
        END IF;
        
        -- Ensure case_history record exists
        MERGE INTO case_history ch
        USING (SELECT l_normalized AS receipt_number FROM dual) src
        ON (ch.receipt_number = src.receipt_number)
        WHEN NOT MATCHED THEN
            INSERT (receipt_number, created_by)
            VALUES (src.receipt_number, uscis_util_pkg.get_current_user);
        
        -- Insert new status update
        INSERT INTO status_updates (
            receipt_number, case_type, current_status,
            last_updated, details, source
        ) VALUES (
            l_normalized, p_case_type, p_current_status,
            p_last_updated, p_details, p_source
        );
        
        -- Update last_checked_at if from API
        IF p_source = uscis_types_pkg.gc_source_api THEN
            UPDATE case_history
            SET last_checked_at = SYSTIMESTAMP
            WHERE receipt_number = l_normalized;
        END IF;
        
        -- NOTE: COMMIT removed - callers control transaction boundaries
        -- APEX pages will auto-commit, batch processes should explicitly commit
    END add_or_update_case;
    
    FUNCTION get_case(
        p_receipt_number  IN VARCHAR2,
        p_include_history IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR IS
        l_cursor     SYS_REFCURSOR;
        l_normalized VARCHAR2(13);
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        IF p_include_history THEN
            OPEN l_cursor FOR
                SELECT 
                    ch.receipt_number,
                    ch.created_at AS tracking_since,
                    ch.notes,
                    ch.is_active,
                    su.case_type,
                    su.current_status,
                    su.last_updated,
                    su.details,
                    su.source,
                    su.created_at AS status_recorded_at
                FROM case_history ch
                LEFT JOIN status_updates su ON su.receipt_number = ch.receipt_number
                WHERE ch.receipt_number = l_normalized
                ORDER BY su.last_updated DESC;
        ELSE
            OPEN l_cursor FOR
                SELECT * FROM v_case_current_status
                WHERE receipt_number = l_normalized;
        END IF;
        
        RETURN l_cursor;
    END get_case;
    
    FUNCTION list_cases(
        p_receipt_filter  IN VARCHAR2 DEFAULT NULL,
        p_page_size       IN NUMBER DEFAULT 20,
        p_page            IN NUMBER DEFAULT 1,
        p_include_history IN BOOLEAN DEFAULT FALSE
    ) RETURN SYS_REFCURSOR IS
        l_cursor     SYS_REFCURSOR;
        l_offset     NUMBER;
        l_filter     VARCHAR2(100);
        l_page_size  NUMBER := GREATEST(NVL(p_page_size, 20), 1);
        l_page       NUMBER := GREATEST(NVL(p_page, 1), 1);
    BEGIN
        l_offset := (l_page - 1) * l_page_size;
        l_filter := UPPER(p_receipt_filter);
        
        OPEN l_cursor FOR
            SELECT 
                v.*,
                COUNT(*) OVER() AS total_count,
                CEIL(COUNT(*) OVER() / l_page_size) AS total_pages
            FROM v_case_current_status v
            WHERE (l_filter IS NULL OR UPPER(v.receipt_number) LIKE '%' || l_filter || '%')
            ORDER BY v.last_updated DESC NULLS LAST
            OFFSET l_offset ROWS FETCH NEXT l_page_size ROWS ONLY;
        
        RETURN l_cursor;
    END list_cases;
    
    FUNCTION count_cases(
        p_receipt_filter IN VARCHAR2 DEFAULT NULL,
        p_active_only    IN BOOLEAN DEFAULT TRUE
    ) RETURN NUMBER IS
        l_count  NUMBER;
        l_filter VARCHAR2(100) := UPPER(p_receipt_filter);
    BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM case_history
        WHERE (l_filter IS NULL OR UPPER(receipt_number) LIKE '%' || l_filter || '%')
          AND (NOT p_active_only OR is_active = 1);
        
        RETURN l_count;
    END count_cases;
    
    PROCEDURE delete_case(
        p_receipt_number IN VARCHAR2
    ) IS
        l_normalized VARCHAR2(13);
        l_old_values CLOB;
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        -- Capture old values for audit
        SELECT JSON_OBJECT(
            'case_type' VALUE case_type,
            'current_status' VALUE current_status,
            'last_updated' VALUE TO_CHAR(last_updated, 'YYYY-MM-DD"T"HH24:MI:SS')
        ) INTO l_old_values
        FROM v_case_current_status
        WHERE receipt_number = l_normalized;
        
        -- Delete (cascades to status_updates)
        DELETE FROM case_history WHERE receipt_number = l_normalized;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Case not found: ' || uscis_util_pkg.mask_receipt_number(l_normalized));
        END IF;
        
        -- Log audit
        uscis_audit_pkg.log_event(
            p_receipt_number => l_normalized,
            p_action         => 'DELETE',
            p_old_values     => l_old_values
        );
        
        -- NOTE: COMMIT removed - callers control transaction boundaries
        -- APEX pages will auto-commit, batch processes should explicitly commit
    END delete_case;
    
    FUNCTION case_exists(
        p_receipt_number IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_count
        FROM case_history
        WHERE receipt_number = uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        RETURN l_count > 0;
    END case_exists;
    
    FUNCTION get_cases_by_receipts(
        p_receipt_numbers IN uscis_types_pkg.t_receipt_tab
    ) RETURN SYS_REFCURSOR IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        OPEN l_cursor FOR
            SELECT v.*
            FROM v_case_current_status v
            WHERE v.receipt_number IN (
                SELECT uscis_util_pkg.normalize_receipt_number(COLUMN_VALUE)
                FROM TABLE(p_receipt_numbers)
            )
            ORDER BY v.last_updated DESC;
        
        RETURN l_cursor;
    END get_cases_by_receipts;
    
    PROCEDURE update_case_notes(
        p_receipt_number IN VARCHAR2,
        p_notes          IN CLOB
    ) IS
        l_normalized VARCHAR2(13);
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        UPDATE case_history
        SET notes = p_notes
        WHERE receipt_number = l_normalized;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Case not found');
        END IF;
        
        -- NOTE: COMMIT removed - callers control transaction boundaries
        -- APEX pages will auto-commit, batch processes should explicitly commit
    END update_case_notes;
    
    PROCEDURE set_case_active(
        p_receipt_number IN VARCHAR2,
        p_is_active      IN BOOLEAN
    ) IS
        l_normalized VARCHAR2(13);
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        UPDATE case_history
        SET is_active = CASE WHEN p_is_active THEN 1 ELSE 0 END
        WHERE receipt_number = l_normalized;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Case not found');
        END IF;
        
        -- NOTE: COMMIT removed - callers control transaction boundaries
        -- APEX pages will auto-commit, batch processes should explicitly commit
    END set_case_active;

END uscis_case_pkg;
/

-- ============================================================
-- USCIS_API_PKG Body (API Integration)
-- ============================================================
CREATE OR REPLACE PACKAGE BODY uscis_api_pkg AS

    -- Internal: Make HTTP request to USCIS API
    FUNCTION call_uscis_api(
        p_receipt_number IN VARCHAR2,
        p_access_token   IN VARCHAR2
    ) RETURN CLOB IS
        l_url      VARCHAR2(500);
        l_response CLOB;
    BEGIN
        l_url := uscis_util_pkg.get_config('USCIS_API_BASE_URL') || '/' || p_receipt_number;
        
        -- Set authorization headers BEFORE making the request
        APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).NAME := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).VALUE := 'Bearer ' || p_access_token;
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).NAME := 'Accept';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).VALUE := 'application/json';
        
        -- Use APEX_WEB_SERVICE for HTTP calls (headers must be set before this)
        l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
            p_url         => l_url,
            p_http_method => 'GET',
            p_wallet_path => NULL,  -- Use APEX wallet if HTTPS
            p_wallet_pwd  => NULL
        );
        
        RETURN l_response;
    END call_uscis_api;
    
    FUNCTION check_case_status(
        p_receipt_number   IN VARCHAR2,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) RETURN uscis_types_pkg.t_case_status IS
        l_normalized   VARCHAR2(13);
        l_status       uscis_types_pkg.t_case_status;
        l_access_token VARCHAR2(4000);
        l_response     CLOB;
    BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(p_receipt_number);
        
        IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid receipt number format');
        END IF;
        
        -- Apply rate limiting
        apply_rate_limit;
        
        -- Check if credentials are configured
        IF NOT uscis_oauth_pkg.has_credentials THEN
            -- Return mock response
            l_status := get_mock_response(l_normalized);
        ELSE
            -- Get access token
            l_access_token := uscis_oauth_pkg.get_access_token;
            
            -- Call API
            l_response := call_uscis_api(l_normalized, l_access_token);
            
            -- Parse response
            l_status := parse_api_response(l_response);
        END IF;
        
        -- Save to database if requested
        IF p_save_to_database THEN
            uscis_case_pkg.add_or_update_case(
                p_receipt_number => l_normalized,
                p_case_type      => l_status.case_type,
                p_current_status => l_status.current_status,
                p_last_updated   => l_status.last_updated,
                p_details        => l_status.details,
                p_source         => uscis_types_pkg.gc_source_api
            );
        END IF;
        
        RETURN l_status;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20020, 
                'API error for ' || uscis_util_pkg.mask_receipt_number(l_normalized) || 
                ': ' || SQLERRM);
    END check_case_status;
    
    PROCEDURE check_multiple_cases(
        p_receipt_numbers  IN uscis_types_pkg.t_receipt_tab,
        p_save_to_database IN BOOLEAN DEFAULT TRUE
    ) IS
        l_status uscis_types_pkg.t_case_status;
    BEGIN
        FOR i IN 1..p_receipt_numbers.COUNT LOOP
            BEGIN
                l_status := check_case_status(
                    p_receipt_number   => p_receipt_numbers(i),
                    p_save_to_database => p_save_to_database
                );
            EXCEPTION
                WHEN OTHERS THEN
                    -- Log error but continue with other cases
                    DBMS_OUTPUT.PUT_LINE(
                        'Error checking ' || p_receipt_numbers(i) || ': ' || SQLERRM
                    );
            END;
        END LOOP;
    END check_multiple_cases;
    
    PROCEDURE apply_rate_limit IS
        l_last_request   TIMESTAMP;
        l_min_interval   NUMBER;
        l_elapsed_ms     NUMBER;
        l_wait_ms        NUMBER;
        l_interval       INTERVAL DAY TO SECOND;
        e_resource_busy  EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_resource_busy, -54); -- ORA-00054: resource busy
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        l_min_interval := TO_NUMBER(
            uscis_util_pkg.get_config('RATE_LIMIT_MIN_INTERVAL_MS', '100')
        );
        
        -- Get last request time with non-blocking lock (NOWAIT to avoid indefinite blocking)
        BEGIN
            SELECT last_request_at INTO l_last_request
            FROM api_rate_limiter
            WHERE service_name = uscis_types_pkg.gc_service_uscis
            FOR UPDATE NOWAIT;
        EXCEPTION
            WHEN e_resource_busy THEN
                -- Another session is updating; wait briefly and retry
                DBMS_LOCK.SLEEP(0.1);
                SELECT last_request_at INTO l_last_request
                FROM api_rate_limiter
                WHERE service_name = uscis_types_pkg.gc_service_uscis
                FOR UPDATE WAIT 5; -- Wait up to 5 seconds on retry
        END;
        
        -- Calculate elapsed time correctly using interval arithmetic
        -- EXTRACT(SECOND) only returns 0-59, so we need full interval computation
        l_interval := SYSTIMESTAMP - l_last_request;
        l_elapsed_ms := (
            EXTRACT(DAY FROM l_interval) * 86400000 +
            EXTRACT(HOUR FROM l_interval) * 3600000 +
            EXTRACT(MINUTE FROM l_interval) * 60000 +
            EXTRACT(SECOND FROM l_interval) * 1000
        );
        
        -- Calculate required wait time
        l_wait_ms := l_min_interval - l_elapsed_ms;
        
        IF l_wait_ms > 0 THEN
            DBMS_LOCK.SLEEP(l_wait_ms / 1000);
        END IF;
        
        -- Update last request time
        UPDATE api_rate_limiter
        SET last_request_at = SYSTIMESTAMP,
            request_count = request_count + 1
        WHERE service_name = uscis_types_pkg.gc_service_uscis;
        
        COMMIT;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Initialize rate limiter
            INSERT INTO api_rate_limiter (service_name, last_request_at)
            VALUES (uscis_types_pkg.gc_service_uscis, SYSTIMESTAMP);
            COMMIT;
    END apply_rate_limit;
    
    FUNCTION get_mock_response(
        p_receipt_number IN VARCHAR2
    ) RETURN uscis_types_pkg.t_case_status IS
        l_status  uscis_types_pkg.t_case_status;
        l_prefix  VARCHAR2(3);
    BEGIN
        l_status.receipt_number := p_receipt_number;
        l_status.last_updated := SYSTIMESTAMP;
        l_prefix := SUBSTR(p_receipt_number, 1, 3);
        
        -- Generate realistic mock data based on receipt prefix
        CASE l_prefix
            WHEN 'IOE' THEN
                l_status.case_type := 'I-485 (Application to Register Permanent Residence)';
                l_status.current_status := 'Case Was Received';
                l_status.details := 'On ' || TO_CHAR(SYSDATE, 'Month DD, YYYY') || 
                    ', we received your Form I-485, Application to Register Permanent Residence or Adjust Status.';
            WHEN 'EAC' THEN
                l_status.case_type := 'I-765 (Application for Employment Authorization)';
                l_status.current_status := 'Card Was Delivered';
                l_status.details := 'The Post Office has delivered your new card.';
            WHEN 'LIN' THEN
                l_status.case_type := 'I-140 (Immigrant Petition for Alien Workers)';
                l_status.current_status := 'Case Was Approved';
                l_status.details := 'We have approved your I-140, Immigrant Petition for Alien Workers.';
            WHEN 'SRC' THEN
                l_status.case_type := 'I-130 (Petition for Alien Relative)';
                l_status.current_status := 'Case Is Being Actively Reviewed';
                l_status.details := 'Your case is currently being reviewed by a USCIS officer.';
            WHEN 'WAC' THEN
                l_status.case_type := 'I-539 (Application to Extend/Change Nonimmigrant Status)';
                l_status.current_status := 'Request for Evidence Was Sent';
                l_status.details := 'We sent a request for evidence (RFE) on your case.';
            ELSE
                l_status.case_type := 'Unknown Form';
                l_status.current_status := 'Status Check Required';
                l_status.details := 'Please visit USCIS.gov for the most current status of your case.';
        END CASE;
        
        RETURN l_status;
    END get_mock_response;
    
    FUNCTION parse_api_response(
        p_json_response IN CLOB
    ) RETURN uscis_types_pkg.t_case_status IS
        l_status      uscis_types_pkg.t_case_status;
        l_modified_dt VARCHAR2(100);
        l_is_json     VARCHAR2(5);
    BEGIN
        -- Validate that the response is valid JSON
        BEGIN
            SELECT CASE WHEN p_json_response IS JSON THEN 'TRUE' ELSE 'FALSE' END
            INTO l_is_json
            FROM dual;
        EXCEPTION
            WHEN OTHERS THEN
                l_is_json := 'FALSE';
        END;
        
        IF l_is_json = 'FALSE' OR p_json_response IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 
                'Invalid API response: not valid JSON or empty response');
        END IF;
        
        -- Verify expected JSON structure exists
        IF JSON_EXISTS(p_json_response, '$.case_status') = FALSE THEN
            RAISE_APPLICATION_ERROR(-20011, 
                'Invalid API response: missing $.case_status object');
        END IF;
        
        -- Parse JSON using JSON_VALUE with DEFAULT ON ERROR for safe extraction
        SELECT 
            JSON_VALUE(p_json_response, '$.case_status.receiptNumber' 
                       DEFAULT NULL ON ERROR),
            JSON_VALUE(p_json_response, '$.case_status.formType' 
                       DEFAULT 'Unknown' ON ERROR),
            JSON_VALUE(p_json_response, '$.case_status.current_case_status_text_en' 
                       DEFAULT 'Status Unknown' ON ERROR),
            JSON_VALUE(p_json_response, '$.case_status.modifiedDate' 
                       DEFAULT NULL ON ERROR),
            JSON_VALUE(p_json_response, '$.case_status.current_case_status_desc_en' 
                       DEFAULT NULL ON ERROR)
        INTO 
            l_status.receipt_number,
            l_status.case_type,
            l_status.current_status,
            l_modified_dt,
            l_status.details
        FROM dual;
        
        -- Validate receipt number is present (required field)
        IF l_status.receipt_number IS NULL THEN
            RAISE_APPLICATION_ERROR(-20012, 
                'Invalid API response: missing receiptNumber');
        END IF;
        
        -- Safely parse timestamp with NULL handling
        BEGIN
            IF l_modified_dt IS NOT NULL THEN
                l_status.last_updated := uscis_util_pkg.parse_iso_timestamp(l_modified_dt);
            ELSE
                l_status.last_updated := SYSTIMESTAMP;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                -- If timestamp parsing fails, use current time
                l_status.last_updated := SYSTIMESTAMP;
        END;
        
        -- Apply defaults for any remaining NULL values
        l_status.case_type := COALESCE(l_status.case_type, 'Unknown');
        l_status.current_status := COALESCE(l_status.current_status, 'Status Unknown');
        
        RETURN l_status;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error details for debugging
            -- Re-raise with descriptive message
            IF SQLCODE BETWEEN -20000 AND -20999 THEN
                -- Application error, re-raise as-is
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20013, 
                    'Failed to parse USCIS API response: ' || SQLERRM);
            END IF;
    END parse_api_response;

END uscis_api_pkg;
/
```

---

## 6. Oracle APEX Application Design

### 6.1 Application Structure

```
USCIS Case Tracker (APEX Application)
├── Global Page (Page 0)
│   ├── Navigation Menu
│   ├── Header (Logo, User Info)
│   └── Footer (Version, Support)
│
├── Home / Dashboard (Page 1)
│   ├── Summary Cards (Total Cases, Active, Updates Today)
│   ├── Status Distribution Chart (Pie/Donut)
│   ├── Recent Activity Timeline
│   └── Quick Actions (Add Case, Check Status)
│
├── Case List (Page 2)
│   ├── Interactive Grid
│   │   ├── Inline Edit
│   │   ├── Filter/Search
│   │   ├── Bulk Actions
│   │   └── Export Options
│   └── Side Panel Details
│
├── Case Details (Page 3)
│   ├── Case Header (Receipt, Type, Status)
│   ├── Status Timeline (History)
│   ├── Notes Editor
│   ├── Action Buttons (Refresh, Delete, Toggle Active)
│   └── Audit Trail Tab
│
├── Add Case (Modal Page 4)
│   ├── Receipt Number Input
│   ├── Auto-fetch Toggle
│   ├── Manual Entry Fields
│   └── Notes Field
│
├── Check Status (Modal Page 5)
│   ├── Receipt Number Input
│   ├── Save to Database Toggle
│   └── Result Display
│
├── Import/Export (Page 6)
│   ├── Export Section
│   │   ├── Format Selection (JSON, CSV)
│   │   ├── Filter Options
│   │   └── Download Button
│   └── Import Section
│       ├── File Upload
│       ├── Replace Existing Toggle
│       └── Import Progress
│
├── Settings (Page 7)
│   ├── API Configuration
│   ├── Scheduler Settings
│   ├── Notification Preferences
│   └── User Preferences
│
├── Administration (Page 8)
│   ├── User Management
│   ├── Audit Logs
│   ├── System Health
│   └── Job Scheduler Status
│
└── Login (Page 101)
    └── APEX Authentication
```

### 6.2 Page Specifications

#### Page 1: Dashboard

```yaml
Page:
  Name: Dashboard
  Number: 1
  Mode: Normal
  Title: USCIS Case Tracker
  
Regions:
  - Name: Summary Cards
    Type: Cards
    Source: 
      SQL: |
        SELECT 
          'Total Cases' AS title,
          COUNT(*) AS value,
          'fa-briefcase' AS icon,
          'u-color-1' AS color
        FROM case_history
        UNION ALL
        SELECT 
          'Active Cases',
          COUNT(*),
          'fa-check-circle',
          'u-color-4'
        FROM case_history WHERE is_active = 1
        UNION ALL
        SELECT 
          'Updated Today',
          COUNT(*),
          'fa-refresh',
          'u-color-9'
        FROM status_updates
        WHERE TRUNC(created_at) = TRUNC(SYSDATE)
    Template: Cards (Float)
    
  - Name: Status Distribution
    Type: Chart
    Chart Type: Pie
    Source:
      SQL: |
        SELECT current_status, COUNT(*) AS case_count
        FROM v_case_current_status
        WHERE is_active = 1
        GROUP BY current_status
        ORDER BY case_count DESC
        FETCH FIRST 10 ROWS ONLY
    
  - Name: Recent Activity
    Type: Timeline
    Source:
      SQL: |
        SELECT 
          performed_at AS event_date,
          action || ': ' || receipt_number AS title,
          performed_by AS user_name,
          CASE action
            WHEN 'INSERT' THEN 'fa-plus-circle u-success'
            WHEN 'DELETE' THEN 'fa-minus-circle u-danger'
            WHEN 'CHECK'  THEN 'fa-refresh u-info'
            ELSE 'fa-edit u-warning'
          END AS icon_css
        FROM case_audit_log
        ORDER BY performed_at DESC
        FETCH FIRST 20 ROWS ONLY
        
  - Name: Quick Actions
    Type: Buttons
    Buttons:
      - Label: Add New Case
        Action: Redirect to Page 4 (Modal)
        Icon: fa-plus
        Style: Hot
      - Label: Check Status
        Action: Redirect to Page 5 (Modal)
        Icon: fa-refresh
        Style: Normal
```

#### Page 2: Case List

```yaml
Page:
  Name: Case List
  Number: 2
  Mode: Normal
  
Regions:
  - Name: Cases
    Type: Interactive Grid
    Source:
      Table: V_CASE_CURRENT_STATUS
    Columns:
      - Name: RECEIPT_NUMBER
        Type: Link
        Link Target: Page 3 (P3_RECEIPT_NUMBER)
      - Name: CASE_TYPE
        Type: Display
      - Name: CURRENT_STATUS
        Type: Display
        Highlight: 
          - Value Contains "Approved": Success
          - Value Contains "Denied": Danger
          - Value Contains "RFE": Warning
      - Name: LAST_UPDATED
        Type: Display
        Format: SINCE (e.g., "2 days ago")
      - Name: IS_ACTIVE
        Type: Switch
        On Value: 1
        Off Value: 0
      - Name: ACTIONS
        Type: Actions Menu
        Actions:
          - View Details
          - Refresh Status
          - Delete
    Features:
      - Inline Editing: Yes
      - Download: Yes (CSV, Excel)
      - Pagination: Page (20 rows)
      - Search: Column-level
    Toolbar:
      - Button: Add Case (Modal Page 4)
      - Button: Bulk Refresh
      - Button: Export All
```

#### Page 3: Case Details

```yaml
Page:
  Name: Case Details
  Number: 3
  Mode: Normal
  
Items:
  - Name: P3_RECEIPT_NUMBER
    Type: Hidden
    Source: URL Parameter
    
Regions:
  - Name: Case Header
    Type: Static Content
    Template: Hero
    Source:
      SQL: |
        SELECT 
          receipt_number,
          case_type,
          current_status,
          last_updated,
          is_active
        FROM v_case_current_status
        WHERE receipt_number = :P3_RECEIPT_NUMBER
        
  - Name: Status Timeline
    Type: Timeline
    Source:
      SQL: |
        SELECT 
          last_updated AS event_date,
          current_status AS title,
          details AS description,
          source AS subtitle,
          CASE source
            WHEN 'API' THEN 'fa-cloud u-info'
            WHEN 'IMPORT' THEN 'fa-upload u-warning'
            ELSE 'fa-edit u-normal'
          END AS icon_css
        FROM status_updates
        WHERE receipt_number = :P3_RECEIPT_NUMBER
        ORDER BY last_updated DESC
        
  - Name: Notes
    Type: Rich Text Editor
    Source:
      SQL: SELECT notes FROM case_history WHERE receipt_number = :P3_RECEIPT_NUMBER
    Save: On Change (AJAX)
    
  - Name: Audit Trail
    Type: Interactive Report
    Region Display Selector: Yes
    Source:
      SQL: |
        SELECT * FROM case_audit_log
        WHERE receipt_number = :P3_RECEIPT_NUMBER
        ORDER BY performed_at DESC

Buttons:
  - Name: BTN_REFRESH
    Label: Refresh Status
    Action: Execute PL/SQL
    PL/SQL: |
      DECLARE
        l_status uscis_types_pkg.t_case_status;
      BEGIN
        l_status := uscis_api_pkg.check_case_status(:P3_RECEIPT_NUMBER, TRUE);
      END;
    After: Refresh Page
    
  - Name: BTN_DELETE
    Label: Delete Case
    Style: Danger
    Confirm: Are you sure you want to delete this case?
    Action: Execute PL/SQL
    PL/SQL: |
      BEGIN
        uscis_case_pkg.delete_case(:P3_RECEIPT_NUMBER);
      END;
    After: Redirect to Page 2
```

#### Page 4: Add Case (Modal)

```yaml
Page:
  Name: Add Case
  Number: 4
  Mode: Modal Dialog
  
Items:
  - Name: P4_RECEIPT_NUMBER
    Type: Text Field
    Label: Receipt Number
    Placeholder: "e.g., IOE1234567890"
    Validation:
      - Type: Regular Expression
        Expression: ^[A-Za-z]{3}[0-9]{10}$
        Error: "Invalid format. Use 3 letters + 10 digits"
    Required: Yes
    
  - Name: P4_FETCH_FROM_USCIS
    Type: Switch
    Label: Fetch status from USCIS
    On Value: Y
    Off Value: N
    Default: Y
    
  - Name: P4_CASE_TYPE
    Type: Select List
    Label: Case Type
    LOV:
      - I-485 (Adjustment of Status)
      - I-765 (Employment Authorization)
      - I-140 (Immigrant Petition)
      - I-130 (Petition for Alien Relative)
      - I-539 (Change of Status)
      - Other
    Condition: P4_FETCH_FROM_USCIS = 'N'
    
  - Name: P4_CURRENT_STATUS
    Type: Text Field
    Label: Current Status
    Condition: P4_FETCH_FROM_USCIS = 'N'
    
  - Name: P4_NOTES
    Type: Textarea
    Label: Notes (Optional)

Buttons:
  - Name: BTN_ADD
    Label: Add Case
    Action: Execute PL/SQL
    PL/SQL: |
      DECLARE
        l_receipt VARCHAR2(13);
      BEGIN
        l_receipt := uscis_case_pkg.add_case(
          p_receipt_number   => :P4_RECEIPT_NUMBER,
          p_case_type        => :P4_CASE_TYPE,
          p_current_status   => :P4_CURRENT_STATUS,
          p_notes            => :P4_NOTES,
          p_fetch_from_uscis => :P4_FETCH_FROM_USCIS = 'Y'
        );
        :P3_RECEIPT_NUMBER := l_receipt;
      END;
    After: Close Dialog and Redirect to Page 3

Processes:
  - Name: Normalize Receipt
    Point: Before Processing
    PL/SQL: |
      :P4_RECEIPT_NUMBER := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);
```

### 6.3 UI/UX Design Guidelines

#### Theme & Styling

```css
/* Custom CSS for USCIS Case Tracker */

/* Status Badge Colors */
.status-approved { background-color: #4CAF50; color: white; }
.status-denied { background-color: #f44336; color: white; }
.status-pending { background-color: #ff9800; color: white; }
.status-rfe { background-color: #2196F3; color: white; }
.status-received { background-color: #9c27b0; color: white; }

/* Card Enhancements */
.case-card {
    transition: transform 0.2s, box-shadow 0.2s;
}
.case-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

/* Receipt Number Styling */
.receipt-number {
    font-family: 'Courier New', monospace;
    font-weight: bold;
    letter-spacing: 1px;
}

/* Timeline Enhancements */
.status-timeline .timeline-item {
    border-left: 3px solid var(--timeline-color, #ccc);
    padding-left: 20px;
    margin-left: 10px;
}

/* Mobile Responsive */
@media (max-width: 768px) {
    .a-CardView-items {
        grid-template-columns: 1fr !important;
    }
}
```

#### Accessibility Requirements

- WCAG 2.1 AA compliance
- Keyboard navigation support
- Screen reader compatibility
- Color contrast ratios > 4.5:1
- Focus indicators visible
- Error messages associated with fields

---

## 7. USCIS API Integration

### 7.1 Network Configuration

```sql
-- ============================================================
-- ACL Configuration for USCIS API Access
-- Required for PL/SQL to make HTTP requests
-- ============================================================

BEGIN
    -- Create ACL
    DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
        acl         => 'uscis_api_acl.xml',
        description => 'ACL for USCIS Developer API access',
        principal   => 'USCIS_APP',  -- Schema/user name
        is_grant    => TRUE,
        privilege   => 'connect'
    );
    
    -- Add resolve privilege
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
        acl       => 'uscis_api_acl.xml',
        principal => 'USCIS_APP',
        is_grant  => TRUE,
        privilege => 'resolve'
    );
    
    -- Assign ACL to USCIS API hosts
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
        acl  => 'uscis_api_acl.xml',
        host => 'api-int.uscis.gov',  -- Sandbox
        lower_port => 443,
        upper_port => 443
    );
    
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
        acl  => 'uscis_api_acl.xml',
        host => 'api.uscis.gov',  -- Production
        lower_port => 443,
        upper_port => 443
    );
    
    COMMIT;
END;
/

-- ============================================================
-- Oracle Wallet for HTTPS (if not using APEX Web Credentials)
-- ============================================================

-- Create wallet directory
-- mkdir -p /opt/oracle/wallet/uscis

-- Import USCIS API SSL certificate
-- orapki wallet add -wallet /opt/oracle/wallet/uscis -trusted_cert -cert uscis_api.cer -pwd WalletPassword123

-- Grant access to wallet
-- CREATE OR REPLACE DIRECTORY USCIS_WALLET_DIR AS '/opt/oracle/wallet/uscis';
-- GRANT READ ON DIRECTORY USCIS_WALLET_DIR TO USCIS_APP;
```

### 7.2 APEX Web Credentials Setup

```sql
-- ============================================================
-- APEX Web Credentials for OAuth2
-- ============================================================

BEGIN
    -- Create Web Credential for USCIS API
    APEX_CREDENTIAL.CREATE_CREDENTIAL(
        p_credential_name      => 'USCIS_API_CREDENTIAL',
        p_credential_type      => APEX_CREDENTIAL.C_TYPE_OAUTH2_CLIENT_CREDS,
        p_scope                => NULL,
        p_allowed_urls         => APEX_STRING.STRING_TO_TABLE(
            'https://api-int.uscis.gov:https://api.uscis.gov'
        ),
        p_credential_comment   => 'OAuth2 credentials for USCIS Case Status API',
        p_client_id            => 'YOUR_CLIENT_ID',      -- Replace
        p_client_secret        => 'YOUR_CLIENT_SECRET',  -- Replace
        p_token_url            => 'https://api-int.uscis.gov/oauth/accesstoken'
    );
END;
/
```

### 7.3 REST Data Source (Alternative to PL/SQL)

```yaml
REST Data Source:
  Name: USCIS Case Status API
  Type: REST Data Source
  URL Endpoint: https://api-int.uscis.gov/case-status/:receipt_number
  
  Remote Server:
    Base URL: https://api-int.uscis.gov
    Authentication: OAuth2 Client Credentials
    Credential: USCIS_API_CREDENTIAL
    
  Operations:
    - Name: GET_CASE_STATUS
      HTTP Method: GET
      URL Pattern: /case-status/{receiptNumber}
      Parameters:
        - Name: receiptNumber
          Type: URL Pattern
          Direction: IN
      Response:
        Format: JSON
        Row Selector: $.case_status
        Columns:
          - Name: receiptNumber
            JSON Path: $.receiptNumber
          - Name: formType
            JSON Path: $.formType
          - Name: currentStatus
            JSON Path: $.current_case_status_text_en
          - Name: modifiedDate
            JSON Path: $.modifiedDate
          - Name: details
            JSON Path: $.current_case_status_desc_en
```

---

## 8. Security Considerations

### 8.1 Authentication & Authorization

```yaml
Authentication:
  Method: APEX Built-in
  Schemes:
    - APEX Accounts (Development)
    - Oracle Cloud Identity (Production)
    - LDAP/Active Directory (Enterprise)
  
Session Management:
  Timeout: 30 minutes idle
  Max Duration: 8 hours
  Cookie Settings:
    Secure: Yes
    HttpOnly: Yes
    SameSite: Strict

Authorization:
  Schemes:
    - Name: ADMIN_ROLE
      Type: Is In Role
      Roles: ADMINISTRATOR
      
    - Name: USER_ROLE
      Type: Is In Role
      Roles: CASE_USER
      
    - Name: READONLY_ROLE
      Type: Is In Role
      Roles: VIEWER

Page Access:
  Dashboard: USER_ROLE, READONLY_ROLE, ADMIN_ROLE
  Case List: USER_ROLE, READONLY_ROLE, ADMIN_ROLE
  Case Details: USER_ROLE, READONLY_ROLE, ADMIN_ROLE
  Add Case: USER_ROLE, ADMIN_ROLE
  Check Status: USER_ROLE, ADMIN_ROLE
  Import/Export: ADMIN_ROLE
  Settings: ADMIN_ROLE
  Administration: ADMIN_ROLE
```

### 8.2 Data Protection

```sql
-- ============================================================
-- Virtual Private Database (VPD) for Multi-User Isolation
-- Optional: Enable if users should only see their own cases
-- ============================================================

CREATE OR REPLACE FUNCTION uscis_vpd_policy(
    p_schema  IN VARCHAR2,
    p_table   IN VARCHAR2
) RETURN VARCHAR2 IS
    l_predicate VARCHAR2(400);
    l_app_user  VARCHAR2(255);
    l_app_id    NUMBER;
    l_is_admin  BOOLEAN := FALSE;
BEGIN
    -- Consistently use SYS_CONTEXT for APEX session detection
    -- Do NOT call APEX packages directly without first confirming APEX session
    BEGIN
        l_app_id := TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    EXCEPTION
        WHEN OTHERS THEN
            l_app_id := NULL;
    END;
    
    IF l_app_id IS NOT NULL THEN
        -- We are in an APEX session - use APEX$SESSION context consistently
        l_app_user := SYS_CONTEXT('APEX$SESSION', 'APP_USER');
        
        -- Only call APEX_ACL when confirmed in APEX session
        BEGIN
            l_is_admin := APEX_ACL.HAS_USER_ROLE(
                p_application_id => l_app_id,
                p_user_name      => l_app_user,
                p_role_static_id => 'ADMINISTRATOR'
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- If APEX_ACL fails, default to non-admin
                l_is_admin := FALSE;
        END;
        
        -- Admins see all
        IF l_is_admin THEN
            RETURN '1=1';
        END IF;
        
        -- Regular users see only their cases (use bind variable style for safety)
        RETURN 'created_by = SYS_CONTEXT(''APEX$SESSION'', ''APP_USER'')';
    ELSE
        -- Not in APEX session - use database user as fallback
        RETURN 'created_by = USER';
    END IF;
END;
/

BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'USCIS_APP',
        object_name     => 'CASE_HISTORY',
        policy_name     => 'USCIS_USER_ISOLATION',
        function_schema => 'USCIS_APP',
        policy_function => 'uscis_vpd_policy',
        statement_types => 'SELECT,INSERT,UPDATE,DELETE'
    );
END;
/

-- ============================================================
-- Column Masking for Sensitive Data
-- ============================================================

-- Redaction policy for receipt numbers in reports
-- PARTIAL function_parameters format for VARCHAR2: 'mask_char,start_pos,length'
-- IMPORTANT: DBMS_REDACT PARTIAL preserves the original string length.
-- For 13-char receipt "IOE1234567890", mask 4 chars starting at position 4:
--   ',4,4' produces "IOE****567890" (13 chars, positions 4-7 masked)
-- Note: This differs from mask_receipt_number() in USCIS_UTIL_PKG which produces
--   "IOE****7890" (11 chars) - an intentionally shortened display format.
-- DBMS_REDACT always keeps original length; mask_receipt_number intentionally truncates.
-- Uses a safe helper function to check APEX admin role

-- First, create the helper function that safely checks redaction requirements
CREATE OR REPLACE FUNCTION uscis_should_redact_receipt RETURN NUMBER IS
    l_app_id   NUMBER;
    l_is_admin NUMBER := 0;
BEGIN
    -- Check if we're in an APEX session
    l_app_id := TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    
    IF l_app_id IS NULL THEN
        -- Not in APEX session - redact for safety
        RETURN 1;
    END IF;
    
    -- Check if user is administrator
    BEGIN
        IF APEX_ACL.HAS_USER_ROLE(
            p_application_id => l_app_id,
            p_user_name      => SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
            p_role_static_id => 'ADMINISTRATOR'
        ) THEN
            l_is_admin := 1;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- On any error (missing APEX context, etc.), redact for safety
            RETURN 1;
    END;
    
    -- Return 0 to show original (admin), 1 to redact (non-admin)
    RETURN CASE WHEN l_is_admin = 1 THEN 0 ELSE 1 END;
END uscis_should_redact_receipt;
/

BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema       => 'USCIS_APP',
        object_name         => 'V_CASE_CURRENT_STATUS',
        column_name         => 'RECEIPT_NUMBER',
        policy_name         => 'MASK_RECEIPT_POLICY',
        function_type       => DBMS_REDACT.PARTIAL,
        -- PARTIAL format: mask 4 chars starting at position 4, producing IOE****567890 (preserves length)
        -- Note: Unlike mask_receipt_number() which truncates, DBMS_REDACT keeps original 13-char length
        function_parameters => DBMS_REDACT.REDACT_VARCHAR2_PARTIAL_MASK || ',4,4',
        -- Use safe helper function instead of inline APEX_ACL
        expression          => 'uscis_should_redact_receipt() = 1'
    );
END;
/
```

### 8.3 Credential Storage

```sql
-- ============================================================
-- Secure Credential Storage
-- Never store credentials in plain text
-- ============================================================

-- Option 1: APEX Web Credentials (Recommended)
-- Credentials stored encrypted in APEX metadata tables

-- Option 2: Oracle Wallet for stored credentials
-- Store in wallet, reference via wallet alias

-- Option 3: DBMS_CREDENTIAL (for scheduler jobs)
BEGIN
    DBMS_CREDENTIAL.CREATE_CREDENTIAL(
        credential_name => 'USCIS_API_CRED',
        username        => 'client_id_here',
        password        => 'client_secret_here'
    );
END;
/

-- Helper function to retrieve encryption key from Oracle Wallet or secure store
-- IMPORTANT: Never hardcode encryption keys in source code
CREATE OR REPLACE FUNCTION get_encryption_key RETURN RAW IS
    l_key RAW(32);
BEGIN
    -- Option 1: Retrieve from Oracle Wallet credential store
    -- The wallet must be configured with: mkstore -wrl <wallet_location> -createEntry uscis_encrypt_key <key_value>
    BEGIN
        l_key := UTL_RAW.CAST_TO_RAW(
            SYS.DBMS_CREDENTIAL.GET_CREDENTIAL_ATTRIBUTE(
                credential_name => 'USCIS_ENCRYPTION_CRED',
                attribute       => 'password'
            )
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Option 2: Could also use external KMS via REST API or DBMS_CLOUD
            RAISE_APPLICATION_ERROR(-20100, 
                'Encryption key not found in credential store. ' ||
                'Configure USCIS_ENCRYPTION_CRED or use TDE for column encryption.');
    END;
    
    -- Validate key length (AES-256 requires 32 bytes)
    IF l_key IS NULL OR UTL_RAW.LENGTH(l_key) != 32 THEN
        RAISE_APPLICATION_ERROR(-20101, 
            'Invalid encryption key length. Expected 32 bytes for AES-256.');
    END IF;
    
    RETURN l_key;
END get_encryption_key;
/

-- Encrypt sensitive config values using securely-stored key
CREATE OR REPLACE FUNCTION encrypt_value(p_value IN VARCHAR2) RETURN RAW IS
    l_key RAW(32);
    l_iv RAW(16);
BEGIN
    -- Retrieve key from secure store (never hardcoded)
    l_key := get_encryption_key();
    
    -- Generate random IV for this encryption
    l_iv := DBMS_CRYPTO.RANDOMBYTES(16);
    
    RETURN l_iv || DBMS_CRYPTO.ENCRYPT(
        src => UTL_RAW.CAST_TO_RAW(p_value),
        typ => DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
        key => l_key,
        iv => l_iv
    );
END encrypt_value;
/

-- Decrypt sensitive config values
CREATE OR REPLACE FUNCTION decrypt_value(p_encrypted IN RAW) RETURN VARCHAR2 IS
    l_key RAW(32);
    l_iv RAW(16);
    l_ciphertext RAW(32767);
BEGIN
    -- Retrieve key from secure store (never hardcoded)
    l_key := get_encryption_key();
    
    -- Extract IV (first 16 bytes) and ciphertext
    l_iv := UTL_RAW.SUBSTR(p_encrypted, 1, 16);
    l_ciphertext := UTL_RAW.SUBSTR(p_encrypted, 17);
    
    RETURN UTL_RAW.CAST_TO_VARCHAR2(
        DBMS_CRYPTO.DECRYPT(
            src => l_ciphertext,
            typ => DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
            key => l_key,
            iv => l_iv
        )
    );
END decrypt_value;
/

-- Note: Consider using Oracle Transparent Data Encryption (TDE) for column-level
-- encryption as an alternative, which manages keys automatically:
-- ALTER TABLE app_config MODIFY (config_value ENCRYPT USING 'AES256');
```

---

## 9. Migration Strategy

### 9.1 Phase Overview

```
Phase 1: Foundation (Weeks 1-2)
├── Database schema creation
├── PL/SQL package stubs
├── APEX application shell
└── Development environment setup

Phase 2: Core Functionality (Weeks 3-5)
├── USCIS_CASE_PKG implementation
├── Basic APEX pages (List, Details, Add)
├── Local testing with mock data
└── Unit test development

Phase 3: API Integration (Weeks 6-7)
├── OAuth2 token management
├── USCIS API integration
├── Rate limiting implementation
└── Error handling

Phase 4: Advanced Features (Weeks 8-9)
├── Import/Export functionality
├── Scheduler jobs
├── Dashboard and reports
└── Audit logging

Phase 5: Testing & Hardening (Week 10)
├── Integration testing
├── Performance testing
├── Security review
└── UAT

Phase 6: Deployment (Week 11)
├── Production environment setup
├── Data migration (if applicable)
├── Go-live
└── Monitoring setup
```

### 9.2 Data Migration

```sql
-- ============================================================
-- Data Migration from JSON File Storage
-- ============================================================

-- Create staging table for JSON import
CREATE TABLE migration_staging (
    id           NUMBER GENERATED ALWAYS AS IDENTITY,
    json_data    CLOB,
    imported_at  TIMESTAMP DEFAULT SYSTIMESTAMP,
    processed    NUMBER(1) DEFAULT 0,
    error_msg    VARCHAR2(4000)
);

-- Progress tracking table for migration
CREATE TABLE migration_progress (
    id              NUMBER GENERATED ALWAYS AS IDENTITY,
    receipt_number  VARCHAR2(13),
    status          VARCHAR2(20),  -- 'SUCCESS', 'FAILED', 'SKIPPED'
    error_msg       VARCHAR2(4000),
    processed_at    TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Import procedure with duplicate handling, exception handling, batching, and progress tracking
CREATE OR REPLACE PROCEDURE migrate_from_json(
    p_json_data       IN CLOB,
    p_commit_batch_size IN NUMBER DEFAULT 100
) IS
    l_processed   NUMBER := 0;
    l_succeeded   NUMBER := 0;
    l_failed      NUMBER := 0;
    l_skipped     NUMBER := 0;
    l_batch_count NUMBER := 0;
    l_error_msg   VARCHAR2(4000);
BEGIN
    -- Parse JSON array and insert into tables
    FOR rec IN (
        SELECT 
            jt.receipt_number,
            jt.status_updates
        FROM JSON_TABLE(
            p_json_data, '$[*]'
            COLUMNS (
                receipt_number VARCHAR2(13) PATH '$.receiptNumber',
                status_updates CLOB FORMAT JSON PATH '$.statusUpdates'
            )
        ) jt
    ) LOOP
        l_processed := l_processed + 1;
        l_error_msg := NULL;
        
        BEGIN
            -- Insert case history with duplicate handling using MERGE
            BEGIN
                MERGE INTO case_history ch
                USING (SELECT rec.receipt_number AS rn FROM dual) src
                ON (ch.receipt_number = src.rn)
                WHEN NOT MATCHED THEN
                    INSERT (receipt_number, created_by)
                    VALUES (src.rn, 'MIGRATION');
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    -- Case already exists, continue to status updates
                    l_skipped := l_skipped + 1;
            END;
            
            -- Insert status updates with error handling per status record
            FOR status_rec IN (
                SELECT *
                FROM JSON_TABLE(
                    rec.status_updates, '$[*]'
                    COLUMNS (
                        case_type VARCHAR2(100) PATH '$.caseType',
                        current_status VARCHAR2(500) PATH '$.currentStatus',
                        last_updated VARCHAR2(30) PATH '$.lastUpdated',
                        details CLOB PATH '$.details'
                    )
                )
            ) LOOP
                BEGIN
                    INSERT INTO status_updates (
                        receipt_number, case_type, current_status,
                        last_updated, details, source
                    ) VALUES (
                        rec.receipt_number,
                        status_rec.case_type,
                        status_rec.current_status,
                        uscis_util_pkg.parse_iso_timestamp(status_rec.last_updated),
                        status_rec.details,
                        'IMPORT'
                    );
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                        -- Duplicate status update, skip
                        NULL;
                    WHEN OTHERS THEN
                        l_error_msg := 'Status insert error: ' || SQLERRM;
                        -- Log but continue with next status record
                        INSERT INTO migration_progress (receipt_number, status, error_msg)
                        VALUES (rec.receipt_number, 'FAILED', l_error_msg);
                END;
            END LOOP;
            
            l_succeeded := l_succeeded + 1;
            
            -- Log success
            INSERT INTO migration_progress (receipt_number, status)
            VALUES (rec.receipt_number, 'SUCCESS');
            
        EXCEPTION
            WHEN OTHERS THEN
                l_failed := l_failed + 1;
                l_error_msg := 'Receipt ' || rec.receipt_number || ': ' || SQLERRM || ' (SQLCODE: ' || SQLCODE || ')';
                
                -- Log failure and continue
                INSERT INTO migration_progress (receipt_number, status, error_msg)
                VALUES (rec.receipt_number, 'FAILED', l_error_msg);
        END;
        
        -- Batch commit
        l_batch_count := l_batch_count + 1;
        IF l_batch_count >= p_commit_batch_size THEN
            COMMIT;
            l_batch_count := 0;
            DBMS_OUTPUT.PUT_LINE('Progress: Processed=' || l_processed || 
                                 ', Succeeded=' || l_succeeded || 
                                 ', Failed=' || l_failed || 
                                 ', Skipped=' || l_skipped);
        END IF;
    END LOOP;
    
    -- Final commit
    COMMIT;
    
    -- Final progress report
    DBMS_OUTPUT.PUT_LINE('=== Migration Complete ===');
    DBMS_OUTPUT.PUT_LINE('Total Processed: ' || l_processed);
    DBMS_OUTPUT.PUT_LINE('Succeeded: ' || l_succeeded);
    DBMS_OUTPUT.PUT_LINE('Failed: ' || l_failed);
    DBMS_OUTPUT.PUT_LINE('Skipped (duplicates): ' || l_skipped);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log overall failure but preserve partial progress
        DBMS_OUTPUT.PUT_LINE('Migration failed at record ' || l_processed || ': ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/
```

---

## 10. Testing Strategy

### 10.1 Test Categories

| Category | Scope | Tools |
|----------|-------|-------|
| Unit Tests | PL/SQL packages | utPLSQL |
| Integration Tests | API + Database | utPLSQL + APEX |
| UI Tests | APEX pages | Selenium, Cypress |
| Performance Tests | Load testing | Apache JMeter |
| Security Tests | Penetration testing | OWASP ZAP |

### 10.2 utPLSQL Test Examples

```sql
-- ============================================================
-- utPLSQL Test Package for USCIS_CASE_PKG
-- ============================================================

CREATE OR REPLACE PACKAGE ut_uscis_case_pkg AS
    
    -- %suite(USCIS Case Package Tests)
    -- %suitepath(uscis.case)
    
    -- %test(Add case with valid receipt number)
    PROCEDURE test_add_case_valid;
    
    -- %test(Add case with invalid receipt number should fail)
    -- %throws(-20001)
    PROCEDURE test_add_case_invalid;
    
    -- %test(Get case returns correct data)
    PROCEDURE test_get_case;
    
    -- %test(Delete case removes record)
    PROCEDURE test_delete_case;
    
    -- %test(List cases with pagination)
    PROCEDURE test_list_cases_pagination;
    
    -- %test(Receipt number normalization)
    PROCEDURE test_normalize_receipt;
    
    -- %test(Receipt number validation)
    PROCEDURE test_validate_receipt;
    
    -- %test(Receipt number masking)
    PROCEDURE test_mask_receipt;
    
    -- %beforeall
    PROCEDURE setup;
    
    -- %afterall  
    PROCEDURE teardown;

END ut_uscis_case_pkg;
/

CREATE OR REPLACE PACKAGE BODY ut_uscis_case_pkg AS

    gc_test_receipt CONSTANT VARCHAR2(13) := 'TST1234567890';

    PROCEDURE setup IS
    BEGIN
        -- Clean up any existing test data
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
        COMMIT;
    END setup;
    
    PROCEDURE teardown IS
    BEGIN
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
        COMMIT;
    END teardown;
    
    PROCEDURE test_add_case_valid IS
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number => gc_test_receipt,
            p_case_type      => 'I-485',
            p_current_status => 'Case Was Received'
        );
        
        ut.expect(l_receipt).to_equal(gc_test_receipt);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt)).to_be_true();
    END test_add_case_valid;
    
    PROCEDURE test_add_case_invalid IS
        l_receipt VARCHAR2(13);
    BEGIN
        -- This should raise -20001
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number => 'INVALID'
        );
    END test_add_case_invalid;
    PROCEDURE test_get_case IS
        l_cursor  SYS_REFCURSOR;
        l_rec     v_case_current_status%ROWTYPE;
        l_dummy   VARCHAR2(13);
    BEGIN
        -- Setup
        l_dummy := uscis_case_pkg.add_case(
            p_receipt_number => gc_test_receipt,
            p_case_type      => 'I-485',
            p_current_status => 'Test Status'
        );
        
        -- Test
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.receipt_number).to_equal(gc_test_receipt);
        ut.expect(l_rec.case_type).to_equal('I-485');
        ut.expect(l_rec.current_status).to_equal('Test Status');
    END test_get_case;
    
    PROCEDURE test_delete_case IS
        l_dummy VARCHAR2(13);
    BEGIN
        l_dummy := uscis_case_pkg.add_case(gc_test_receipt);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt)).to_be_true();
        
        uscis_case_pkg.delete_case(gc_test_receipt);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt)).to_be_false();
    END test_delete_case;
    
    PROCEDURE test_list_cases_pagination IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
        l_dummy  VARCHAR2(13);  -- For add_case return value
    BEGIN
        -- Add 5 test cases with valid 13-char format (3 letters + 10 digits)
        FOR i IN 1..5 LOOP
            -- Use LPAD to ensure the numeric portion is exactly 10 digits
            l_dummy := uscis_case_pkg.add_case('TST' || LPAD(i, 10, '0'));
        END LOOP;
        
        -- Get page 1 with size 2
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_page_size      => 2,
            p_page           => 1
        );
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(2);
    END test_list_cases_pagination;
    
    PROCEDURE test_normalize_receipt IS
    BEGIN
        ut.expect(uscis_util_pkg.normalize_receipt_number('ioe-123-456-7890'))
            .to_equal('IOE1234567890');
        ut.expect(uscis_util_pkg.normalize_receipt_number('  eac 0987654321  '))
            .to_equal('EAC0987654321');
    END test_normalize_receipt;
    
    PROCEDURE test_validate_receipt IS
    BEGIN
        ut.expect(uscis_util_pkg.validate_receipt_number('IOE1234567890')).to_be_true();
        ut.expect(uscis_util_pkg.validate_receipt_number('ABC123')).to_be_false();
        ut.expect(uscis_util_pkg.validate_receipt_number('1234567890ABC')).to_be_false();
    END test_validate_receipt;
    
    PROCEDURE test_mask_receipt IS
    BEGIN
        ut.expect(uscis_util_pkg.mask_receipt_number('IOE1234567890'))
            .to_equal('IOE****7890');
    END test_mask_receipt;

END ut_uscis_case_pkg;
/
```

---

## 11. Deployment Architecture

### 11.1 Oracle Autonomous Database (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│                 Oracle Cloud Infrastructure                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Autonomous Database (ATP/ADW)              │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │   APEX      │  │   PL/SQL    │  │   Tables    │  │   │
│  │  │   Runtime   │  │   Packages  │  │   & Views   │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  │                                                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │   ORDS      │  │   Wallet    │  │  Scheduler  │  │   │
│  │  │   REST API  │  │   (TLS)     │  │   Jobs      │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                 │
│                            │ HTTPS (TLS 1.2+)               │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Load Balancer / WAF                     │   │
│  │         (Oracle Cloud Guard, WAF Rules)              │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                 │
└────────────────────────────│────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   End Users     │
                    │   (Browsers)    │
                    └─────────────────┘
```

### 11.2 Environment Configuration

```yaml
Development:
  Database: ATP-S (1 OCPU, 1 TB)
  APEX Workspace: DEV
  URL: https://uscis-dev.adb.us-ashburn-1.oraclecloudapps.com/ords/uscis_dev/
  
Staging:
  Database: ATP-S (1 OCPU, 1 TB)
  APEX Workspace: STG
  URL: https://uscis-stg.adb.us-ashburn-1.oraclecloudapps.com/ords/uscis_stg/
  
Production:
  Database: ATP-S (2 OCPU, 2 TB, Auto-scaling)
  APEX Workspace: PROD
  URL: https://uscis.adb.us-ashburn-1.oraclecloudapps.com/ords/uscis/
  Custom Domain: https://casetracker.yourcompany.com
  SSL Certificate: Managed by OCI
  Backup: Daily, 60-day retention
  
USCIS API Endpoints:
  Sandbox: https://api-int.uscis.gov
  Production: https://api.uscis.gov
```

---

## Appendices

### A. Glossary

| Term | Definition |
|------|------------|
| Receipt Number | Unique 13-character identifier for USCIS cases (e.g., IOE1234567890) |
| APEX | Oracle Application Express - low-code development platform |
| ATP | Autonomous Transaction Processing (Oracle Cloud database) |
| ORDS | Oracle REST Data Services |
| VPD | Virtual Private Database |
| ACL | Access Control List |

### B. References

- [Oracle APEX Documentation](https://docs.oracle.com/en/database/oracle/apex/)
- [USCIS Developer API Documentation](https://developer.uscis.gov)
- [Oracle Autonomous Database](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [utPLSQL Testing Framework](https://utplsql.org)

### C. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-03 | Migration Team | Initial draft |

---

*End of Specification*
