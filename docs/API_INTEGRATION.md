# USCIS API Integration Guide

> **⚠️ INTERNAL USE ONLY** — This document is intended for project developers. Do not distribute publicly. Endpoint URLs shown are for the production public API.

**Version:** 1.0  
**Date:** February 2026  
**Roadmap ID:** 3.4.7  

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Package Dependency Chain](#2-package-dependency-chain)
3. [OAuth2 Authentication](#3-oauth2-authentication)
4. [Case Status API](#4-case-status-api)
5. [Rate Limiting](#5-rate-limiting)
6. [Mock Mode](#6-mock-mode)
7. [Error Handling](#7-error-handling)
8. [Configuration Keys](#8-configuration-keys)
9. [APEX Page Integration](#9-apex-page-integration)
10. [Data Flow Diagrams](#10-data-flow-diagrams)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Architecture Overview

The USCIS API integration stack consists of four PL/SQL packages working in a layered architecture:

```
┌──────────────────────────────────────────────────────────┐
│                    APEX Pages                            │
│   Page 3 (Details)  Page 4 (Add)  Page 5 (Check)        │
│   Page 22 (List — Bulk Refresh)                          │
└────────────────┬─────────────────────────────────────────┘
                 │  PL/SQL calls
                 ▼
┌──────────────────────────────────────────────────────────┐
│               USCIS_API_PKG (06)                         │
│   check_case_status()  check_multiple_cases()            │
│   check_case_status_json()                               │
│   get_mock_response()  parse_api_response()              │
│   call_uscis_api()  [private — makes HTTP request]       │
└──────────┬───────────────────┬───────────────────────────┘
           │                   │
           ▼                   ▼
┌────────────────────┐  ┌──────────────────────────────────┐
│ USCIS_OAUTH_PKG    │  │ USCIS_CASE_PKG (04)              │
│      (05)          │  │  add_or_update_case()            │
│ get_access_token() │  │  update_last_checked()           │
│ fetch_new_token()  │  └──────────────────────────────────┘
│ is_token_valid()   │
│ has_credentials()  │
└────────┬───────────┘
         │  HTTP to USCIS token endpoint
         ▼
┌────────────────────────────────────────┐
│  USCIS API  (api.uscis.gov)              │
│  OAuth2 token endpoint + case status     │
└────────────────────────────────────────┘
```

Supporting infrastructure:
- **USCIS_UTIL_PKG (02):** Validation, normalization, config helpers, logging
- **USCIS_AUDIT_PKG (03):** Audit trail logging to `CASE_AUDIT_LOG`
- **USCIS_TYPES_PKG (01):** Shared record types, error constants, collection types
- **USCIS_ERROR_PKG (10):** APEX application-level error handler callback
- **USCIS_TEMPLATE_COMPONENTS_PKG (09):** Status → CSS class / icon mapping

---

## 2. Package Dependency Chain

Packages must be installed in numbered order — each depends on its predecessors:

```
01_uscis_types_pkg          ← No dependencies (types & constants)
02_uscis_util_pkg           ← 01
03_uscis_audit_pkg          ← 01, 02
04_uscis_case_pkg           ← 01, 02, 03
05_uscis_oauth_pkg          ← 01, 02
06_uscis_api_pkg            ← 01, 02, 03, 04, 05
07_uscis_scheduler_pkg      ← 01, 02, 04, 06
08_uscis_export_pkg         ← 01, 02, 04
09_uscis_template_components_pkg ← 01
10_uscis_error_pkg          ← 01, 02, 03
```

Install all: `make install` (runs `install_all_v2.sql`)  
Install packages only: `make packages-install`

---

## 3. OAuth2 Authentication

### 3.1 Flow

The USCIS API uses **OAuth2 Client Credentials** grant:

1. Client ID + Client Secret stored in `OAUTH_TOKENS` table (service name = `USCIS_API`)
2. `uscis_oauth_pkg.get_access_token()` checks for valid cached token
3. If no valid token, `fetch_new_token()` calls the token endpoint
4. Bearer token attached to all API requests via `APEX_WEB_SERVICE` headers

### 3.2 Token Management

| Function | Purpose |
|----------|---------|
| `get_access_token(p_service)` | Returns valid token, fetching new one if expired |
| `fetch_new_token(p_service)` | Forces a new token fetch from the endpoint |
| `is_token_valid(p_service)` | Checks if current token is still valid |
| `get_token_expiry(p_service)` | Returns expiry timestamp |
| `get_minutes_until_expiry(p_service)` | Minutes remaining on current token |
| `clear_token(p_service)` | Invalidates cached token |
| `refresh_token_if_needed(p_service)` | Refreshes if within expiry window |
| `mark_token_used(p_service)` | Updates last-used timestamp |
| `has_credentials` | Returns TRUE if client_id/secret are configured |
| `get_token_url` | Returns the OAuth2 token endpoint URL |

### 3.3 Token Endpoint

Sandbox: `https://api-int.uscis.gov/oauth/accesstoken`  
Production: Provided when production access is granted.  
Configurable via `scheduler_config` table using key `USCIS_OAUTH_TOKEN_URL`.

### 3.4 Credential Setup

Credentials are stored in the `scheduler_config` table as `USCIS_CLIENT_ID` and `USCIS_CLIENT_SECRET`.
The OAuth package reads them via `uscis_util_pkg.get_config()`.

> **⚠️ Security Warning:** Never commit real secrets to source control or store them in plaintext.
> Use environment variables, Oracle Wallet, or a secret management tool (e.g., OCI Vault, HashiCorp Vault)
> to inject credentials at deployment time. The values below are **placeholders only — DO NOT USE REAL SECRETS**.

Quick setup script: `scripts/setup_sandbox_credentials.sql` (run once after install).

```sql
-- PLACEHOLDER VALUES ONLY — replace with injected secrets at deploy time
MERGE INTO scheduler_config sc
USING (SELECT 'USCIS_CLIENT_ID' AS config_key FROM dual) src
ON (sc.config_key = src.config_key)
WHEN NOT MATCHED THEN
    INSERT (config_key, config_value, description)
    VALUES ('USCIS_CLIENT_ID', 'PLACEHOLDER-client-id', 'USCIS Torch API Client ID');

MERGE INTO scheduler_config sc
USING (SELECT 'USCIS_CLIENT_SECRET' AS config_key FROM dual) src
ON (sc.config_key = src.config_key)
WHEN NOT MATCHED THEN
    INSERT (config_key, config_value, description)
    VALUES ('USCIS_CLIENT_SECRET', 'PLACEHOLDER-client-secret', 'USCIS Torch API Client Secret');

COMMIT;
```

When credentials are absent, the system raises error `-20011` (`gc_err_credentials_missing`) rather than silently falling back to mock data. Mock mode requires **explicit opt-in** by setting `USE_MOCK_API = TRUE` (see §6 for opt-in instructions).

---

## 4. Case Status API

### 4.1 Primary Functions

#### `check_case_status(p_receipt_number, p_save_to_database)`

The main entry point for checking a single case.

```sql
FUNCTION check_case_status(
    p_receipt_number   IN VARCHAR2,
    p_save_to_database IN BOOLEAN DEFAULT TRUE
) RETURN uscis_types_pkg.t_case_status;
```

**Behavior:**
1. Normalizes receipt number (uppercase, trimmed, 13 chars)
2. Validates format (3 letters + 10 digits)
3. Checks mock mode — uses `get_mock_response()` if no API configured
4. In real mode: acquires rate limit slot → gets OAuth token → calls USCIS API → parses response
5. If `p_save_to_database = TRUE`: upserts into `case_history` + `status_updates`, logs to audit
6. Returns `t_case_status` record

**Return type — `t_case_status`:**

| Field | Type | Description |
|-------|------|-------------|
| `receipt_number` | `VARCHAR2(13)` | Normalized receipt number |
| `case_type` | `VARCHAR2(20)` | Form type (e.g., I-485, I-765) |
| `current_status` | `VARCHAR2(200)` | Full status text from USCIS |
| `last_updated` | `TIMESTAMP` | When USCIS last updated the status |
| `details` | `VARCHAR2(4000)` | Extended status details/description |

#### `check_multiple_cases(p_receipt_numbers, p_save_to_database, p_stop_on_error)`

Bulk check for multiple cases:

```sql
PROCEDURE check_multiple_cases(
    p_receipt_numbers  IN uscis_types_pkg.t_receipt_tab,
    p_save_to_database IN BOOLEAN DEFAULT TRUE,
    p_stop_on_error    IN BOOLEAN DEFAULT FALSE
);
```

- Iterates over the collection, calling `check_case_status` for each
- When `p_stop_on_error = FALSE` (default), continues past failures
- Rate limiting applies automatically between calls

#### `check_case_status_json(p_receipt_number, p_save_to_database)`

JSON wrapper for AJAX callbacks:

```sql
FUNCTION check_case_status_json(
    p_receipt_number   IN VARCHAR2,
    p_save_to_database IN BOOLEAN DEFAULT TRUE
) RETURN CLOB;
```

Returns a JSON object with status fields, suitable for `apex.server.process()` consumption.

### 4.2 API Endpoint

- **Base URL:** Configurable via `SCHEDULER_CONFIG` key `USCIS_API_BASE_URL`
- **Sandbox:** `https://api-int.uscis.gov/case-status`
- **Production:** Provided when production access is granted
- **Method:** `GET /{receipt_number}`
- **Auth:** Bearer token (OAuth2 Client Credentials)
- **Response:** JSON

### 4.3 Response Parsing

`parse_api_response(p_json CLOB)` extracts fields from the USCIS JSON response into the `t_case_status` record type. The JSON structure expected:

```json
{
  "CaseNumber": "IOE1234567890",
  "FormType": "I-485",
  "CaseStatus": "Case Was Received",
  "DateFiled": "2024-01-15",
  "Details": "On January 15, 2024, we received your Form I-485..."
}
```

---

## 5. Rate Limiting

### 5.1 Mechanism

Rate limiting is implemented via the `API_RATE_LIMITER` table with atomic slot acquisition:

- The table stores request timestamps in per-row slots
- `can_request_now()` attempts to atomically claim an available slot using `SELECT ... FOR UPDATE SKIP LOCKED`
- If no slots available, exponential backoff is applied (starting at 100ms, capped at 1000ms)
- Maximum retries: 10 (configurable)

### 5.2 Functions

| Function | Purpose |
|----------|---------|
| `apply_rate_limit` | Blocks until a slot is available |
| `can_request_now` | Tries to claim a slot, returns TRUE/FALSE |
| `can_request_now_readonly` | Check-only, no slot acquisition |
| `get_rate_limit_status` | Returns JSON with current rate limiter state |
| `reset_rate_limiter` | Clears all slots (admin function) |

### 5.3 Error on Exhaustion

If all retries are exhausted, `RAISE_APPLICATION_ERROR(-20021, ...)` is raised.  
The error handler maps this to: *"We're checking cases too quickly. Please wait a moment and try again."*

### 5.4 HTTP 429 Handling

If the USCIS API itself returns HTTP 429 (Too Many Requests), the error is raised as `-20021` and the token is preserved for retry.

### 5.5 Sandbox Limits

| Limit | Value |
|-------|-------|
| Daily Quota | 1,000 requests |
| Transactions Per Second | 5 tps |
| Minimum Interval | 200 ms (1 request per 200 ms) |

These are reflected in `uscis_types_pkg` constants (`gc_rate_limit_tps`, `gc_min_interval_ms`, `gc_daily_limit`) and the `scheduler_config` table rows `RATE_LIMIT_REQUESTS_PER_SECOND`, `RATE_LIMIT_MIN_INTERVAL_MS`, `RATE_LIMIT_DAILY_QUOTA`.

---

## 6. Mock Mode

### 6.1 When Active

Mock mode requires **explicit opt-in** and will never activate silently:
1. The config key `USE_MOCK_API` must be set to `TRUE`, **AND**
2. Missing OAuth credentials (`has_credentials = FALSE`) alone will **not** activate mock mode — instead, an error/warning is raised

> **⚠️ Important:** If no OAuth credentials are configured and `USE_MOCK_API` is not `TRUE`, the system will log a `WARNING` and raise `-20011` (`gc_err_credentials_missing`) rather than silently falling back to mock data. This prevents accidental mock usage in production.
>
> **Production safeguard:** In production environments, ensure `USE_MOCK_API` is `FALSE`. If mock mode is inadvertently enabled, a WARNING is logged on every API call. Consider adding a UI indicator (e.g., a banner) when mock mode is active so users are aware they are viewing synthetic data.

### 6.2 Behavior

`get_mock_response()` generates realistic test data:
- Random case types based on receipt number prefix (IOE→I-485/I-765/I-131, etc.)
- Randomized statuses from a realistic set (Case Was Received, Case Was Approved, etc.)
- Pseudo-random timestamps within the last 30 days
- Deterministic enough to test flows, random enough to simulate variety

### 6.3 Checking Mock Mode

```sql
IF uscis_api_pkg.is_mock_mode THEN
    -- Running against mock data
END IF;
```

From APEX page logic:
```sql
:P_IS_MOCK := CASE WHEN uscis_api_pkg.is_mock_mode THEN 'Y' ELSE 'N' END;
```

---

## 7. Error Handling

### 7.1 Error Code Catalog

All application error codes are defined in `USCIS_TYPES_PKG`:

| Code | Constant | Friendly Message |
|------|----------|------------------|
| -20001 | `gc_err_invalid_receipt` | Invalid receipt number format. Expected 3 letters + 10 digits. |
| -20002 | `gc_err_case_not_found` | Case not found. Double-check the receipt number. |
| -20003 | `gc_err_duplicate_case` | This case is already being tracked. |
| -20004 | `gc_err_invalid_frequency` | Invalid check frequency. Use daily, weekly, or monthly. |
| -20010 | `gc_err_auth_failed` | Unable to connect to USCIS. Please try again later. |
| -20011 | `gc_err_credentials_missing` | USCIS API credentials not configured. Contact admin. |
| -20020 | `gc_err_api_error` | USCIS service is temporarily unavailable. Please try later. |
| -20021 | `gc_err_rate_limited` | Checking cases too quickly. Please wait a moment. |
| -20030 | `gc_err_invalid_json` | Received an unexpected response from USCIS. |
| -20040 | `gc_err_export_failed` | Export failed. Please try again. |
| -20041 | `gc_err_import_failed` | Import failed. Check data format and try again. |

### 7.2 USCIS API Error Format (RFC-9457)

The USCIS Torch API returns errors in [RFC-9457](https://www.rfc-editor.org/rfc/rfc9457) Problem Details format:

```json
{
  "errors": [{
    "code": "ERROR_UNIQUE_CODE",
    "message": "ERROR_MESSAGE",
    "category": "SHORT_DESCRIPTION/ERROR_CATEGORY",
    "reference": "API_DOCUMENTATION_LINK",
    "status": "HTTP_STATUS_CODE",
    "traceId": "UUID"
  }]
}
```

`call_uscis_api()` in `USCIS_API_PKG` automatically parses this format on non-200 responses and extracts the `message`, `code`, and `traceId` into the error message. If the response body is not valid RFC-9457 JSON, the error falls back to a generic "API returned status {N}" message.

The `error.message` **must** be displayed to the user (USCIS demo requirement). The app's global error handler (`USCIS_ERROR_PKG`) surfaces these as friendly APEX error messages.

### 7.3 Global Error Handler (USCIS_ERROR_PKG)

Registered in APEX as the application error handling function:

```
Shared Components → Application Definition → Error Handling Function:
  uscis_error_pkg.handle_error
```

Processing order:
1. **Internal APEX errors** → masked with generic message + reference number
2. **ORA-200xx errors** → mapped to friendly text via `get_friendly_message()`
3. **Constraint violations** → mapped to associated page items by constraint name
4. **Other ORA errors** → first error text shown to user
5. **All errors** → logged via autonomous `log_error_detail()` to `CASE_AUDIT_LOG`

### 7.4 Per-Call Error Handling

Each API call logs errors independently:

```sql
uscis_util_pkg.log_error(
    'check_case_status failed for ' || uscis_util_pkg.mask_receipt_number(l_receipt),
    gc_package_name, SQLCODE, SQLERRM
);
```

Receipt numbers are always masked in logs using `mask_receipt_number()` (shows only last 4 digits).

---

## 8. Configuration Keys

Settings stored in `SCHEDULER_CONFIG` table, managed via `uscis_util_pkg`:

| Key | Default | Description |
|-----|---------|-------------|
| `USCIS_API_BASE_URL` | `https://api-int.uscis.gov/case-status` | USCIS Case Status API endpoint (Sandbox) |
| `USCIS_OAUTH_TOKEN_URL` | `https://api-int.uscis.gov/oauth/accesstoken` | OAuth2 token endpoint (Sandbox) |
| `USCIS_CLIENT_ID` | *(none)* | Torch API Client ID |
| `USCIS_CLIENT_SECRET` | *(none)* | Torch API Client Secret |
| `USE_MOCK_API` | `FALSE` | Force mock mode (explicit opt-in only) |
| `RATE_LIMIT_REQUESTS_PER_SECOND` | 5 | Max API requests per second (Sandbox: 5 tps) |
| `RATE_LIMIT_MIN_INTERVAL_MS` | 200 | Min ms between requests (Sandbox: 200 ms) |
| `RATE_LIMIT_DAILY_QUOTA` | 1000 | Daily request quota (Sandbox: 1,000) |
| `MAX_RATE_LIMIT_RETRIES` | 10 | Backoff retries before failure |
| `DEFAULT_CHECK_FREQUENCY` | `daily` | How often scheduler checks cases |

Retrieve configuration values:
```sql
uscis_util_pkg.get_config_value('API_BASE_URL')
uscis_util_pkg.get_config_boolean('USE_MOCK_API', FALSE)
```

---

## 9. APEX Page Integration

### 9.1 Page 3 — Case Details (Refresh Status)

- **Button:** BTN_REFRESH_STATUS
- **Process:** Calls `uscis_api_pkg.check_case_status(:P3_RECEIPT_NUMBER, TRUE)`
- **Result:** Updates page items with fresh status, refreshes detail region
- **Patch:** `page_patches/page_00003_patch.sql`

### 9.2 Page 4 — Add Case (Fetch from USCIS)

- **Toggle:** P4_FETCH_FROM_USCIS (default Y)
- **PATH A (Fetch=Y):** Validates receipt → calls `check_case_status(receipt, TRUE)` → inserts case with live data → shows API-fetched status
- **PATH B (Fetch=N):** Manual entry with user-provided case type and notes
- **Fallback:** If API fails in PATH A, falls back to `uscis_case_pkg.add_case()` with a warning
- **Patch:** `page_patches/page_00004_patch.sql`

### 9.3 Page 5 — Check Status (Modal)

- **Process:** Calls `check_case_status(:P5_RECEIPT_NUMBER, :P5_SAVE_TO_DB = 'Y')`
- **Result:** Displays status in a result card region
- **Patch:** `page_patches/page_00005_patch.sql`

### 9.4 Page 22 — Case List (Bulk Refresh)

- **Button A:** BTN_REFRESH_SELECTED — refreshes selected IG rows
- **Button B:** BTN_REFRESH_ALL_ACTIVE — refreshes all active cases
- **AJAX Process:** Parses receipt CSV from `apex_application.g_x01`, calls `check_case_status()` per row, returns JSON counts
- **JS:** Uses `apex.server.process()`, `apex.region('case_list').refresh()` on success
- **Patch:** `page_patches/page_00022_bulk_refresh_patch.sql`

### 9.5 Scheduler (Background)

- `USCIS_SCHEDULER_PKG (07)` uses DBMS_SCHEDULER to periodically check active cases
- Calls `uscis_api_pkg.check_multiple_cases()` in batches
- Honors rate limiting and respects per-case check frequency settings

---

## 10. Data Flow Diagrams

### 10.1 Single Case Check

```
User clicks "Check Status"
        │
        ▼
  APEX Page Process
        │
        ▼
  uscis_api_pkg.check_case_status(receipt, save=TRUE)
        │
        ├─ normalize + validate receipt
        │
        ├─ is_mock_mode? ──YES──▶ get_mock_response() ──┐
        │                                                 │
        └─NO─▶ call_uscis_api(receipt)                   │
               │                                          │
               ├─ acquire rate limit slot                 │
               ├─ get_access_token()                      │
               │   └─ fetch_new_token() if expired        │
               ├─ APEX_WEB_SERVICE.make_rest_request()    │
               ├─ check HTTP status                       │
               └─ parse_api_response(json)                │
                                                          │
        ◄─────────────── t_case_status ◄──────────────────┘
        │
        ├─ add_or_update_case() → CASE_HISTORY + STATUS_UPDATES
        ├─ update_last_checked()
        └─ uscis_audit_pkg.log_check()
        │
        ▼
  Return to APEX page → update items → refresh regions
```

### 10.2 Bulk Refresh

```
User clicks "Refresh Selected" on IG
        │
        ▼
  JavaScript: collect selected receipt numbers
        │
        ▼
  apex.server.process('Bulk Refresh Cases', {x01: csv})
        │
        ▼
  AJAX Callback (PL/SQL):
    FOR each receipt IN csv LOOP
        BEGIN
            check_case_status(receipt, TRUE)
            checked++
        EXCEPTION
            errors++
        END
    END LOOP
        │
        ▼
  Return JSON: {success, checked, errors, total}
        │
        ▼
  JavaScript: show message → refresh IG
```

---

## 11. Troubleshooting

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Calls raise -20011 / -20012 errors | No credentials in OAUTH_TOKENS and `USE_MOCK_API` ≠ `TRUE` | Missing credentials will **not** enable mock mode automatically — insert client_id/secret for USCIS_API service **or** explicitly set `USE_MOCK_API = TRUE` (see §6.1) |
| "Rate limited" errors | Too many concurrent checks | Wait 60s; or call `reset_rate_limiter` |
| "Authentication failed" errors | Token expired or bad credentials | Verify credentials; call `clear_token` to force refresh |
| API returns HTTP 429 | USCIS rate limit exceeded | Reduce bulk batch size; increase check intervals |
| "Credentials not configured" | OAUTH_TOKENS table empty | Set up OAuth credentials per §3.4 |
| Mock mode even with creds | `USE_MOCK_API` = TRUE | Update config: `UPDATE scheduler_config SET config_value = 'FALSE' WHERE config_key = 'USE_MOCK_API'` |

### Diagnostic Queries

```sql
-- Check if API is configured and in which mode
SELECT CASE WHEN uscis_api_pkg.is_mock_mode THEN 'MOCK' ELSE 'LIVE' END AS api_mode
FROM DUAL;

-- View rate limiter status
SELECT uscis_api_pkg.get_rate_limit_status FROM DUAL;

-- Check recent API errors in audit log
SELECT action_timestamp, receipt_number, action, details
FROM case_audit_log
WHERE action IN ('ERROR', 'API_CHECK')
ORDER BY action_timestamp DESC
FETCH FIRST 20 ROWS ONLY;

-- Check token status
SELECT service_name,
       CASE WHEN uscis_oauth_pkg.is_token_valid('USCIS_API') THEN 'VALID' ELSE 'EXPIRED' END AS token_status,
       uscis_oauth_pkg.get_minutes_until_expiry('USCIS_API') AS mins_remaining
FROM DUAL;
```

---

*This document covers the complete API integration architecture as of packages 01–10 and page patches for pages 3, 4, 5, and 22.*
