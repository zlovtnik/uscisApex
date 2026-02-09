# USCIS Case Tracker: APEX 24.2 Code Review

**Review Date:** February 6, 2026  
**Reviewer:** Claude (Automated Review)  
**Scope:** Database scripts, PL/SQL packages, APEX design documents  
**Standards Reference:** APEX_24_REVIEW.md

---

## Executive Summary

This review identifies **10 high-priority issues** (3 critical, 3 high, 4 security) and **6 medium-priority improvements** (4 medium, 2 AI opportunities) across the USCIS Case Tracker codebase. The primary concerns are:

1. **CRITICAL**: Use of internal `wwv_flow_imp` APIs in upload scripts
2. **HIGH**: Missing session context initialization in deployment scripts
3. **HIGH**: Extensive use of `!important` in CSS (30+ rules)
4. **HIGH**: Custom toast implementation instead of native `apex.message`
5. **MEDIUM**: Hardcoded application IDs without parameterization

**Estimated Remediation Effort:** 52-72 hours

---

## Priority 1: Critical Issues (Must Fix Before Production)

### C-1: Internal API Usage in Upload Scripts

**Severity:** 🔴 **CRITICAL**  
**Files:** `scripts/upload_inline.sql`, `scripts/upload_enhanced_files.sql`, `scripts/upload_static_files.sql`  
**Impact:** Application may break on Oracle patch updates  

**Issue:**
All upload scripts use `wwv_flow_imp.create_app_static_file` and `wwv_flow_imp.remove_app_static_file` — these are internal, undocumented APIs reserved for APEX's import/export machinery.

**Current Code (❌ Avoid):**
```sql
wwv_flow_imp.create_app_static_file(
    p_id           => wwv_flow_id.next_val,
    p_flow_id      => l_app_id,
    p_file_name    => 'app-styles.css',
    p_mime_type    => 'text/css',
    p_file_charset => 'utf-8',
    p_file_content => l_blob
);
```

**Recommended Fix (✅ Use):**
```sql
-- Step 1: Delete existing file using public API
BEGIN
  FOR r IN (
    SELECT file_id
      FROM apex_application_static_files
     WHERE application_id = l_app_id
       AND file_name      = 'app-styles.css'
  ) LOOP
    wwv_flow_api.remove_app_static_file(
      p_id      => r.file_id,
      p_flow_id => l_app_id
    );
  END LOOP;
END;

-- Step 2: Create new file using public API
wwv_flow_api.create_app_static_file(
  p_flow_id      => l_app_id,
  p_file_name    => 'app-styles.css',
  p_mime_type    => 'text/css',
  p_file_charset => 'utf-8',
  p_file_content => l_blob
);
```

**Action Items:**
- [x] Update `scripts/upload_inline.sql` (lines 45-52, 78-85)
- [x] Update `scripts/upload_enhanced_files.sql` (lines 38-45)
- [x] Update `scripts/upload_static_files.sql` (lines 28-35)
- [x] Test file upload/deletion with new APIs

**Reference:** APEX_24_REVIEW.md § R-01

---

### C-2: Incomplete Session Context in Deployment Scripts

**Severity:** 🔴 **CRITICAL**  
**Files:** All `scripts/*.sql` that call APEX APIs  
**Impact:** APEX APIs may fail or produce unexpected results  

**Issue:**
Scripts use `apex_util.set_security_group_id(l_workspace_id)` which only sets the security group. APEX 24.2 APIs require full session context (substitution strings, session state, etc.).

**Current Code (❌ Avoid):**
```sql
apex_util.set_security_group_id(l_workspace_id);
```

**Recommended Fix (✅ Use):**
```sql
-- Initialize full APEX session context
apex_session.create_session(
  p_app_id                    => l_app_id,
  p_page_id                   => 1,
  p_username                  => 'ADMIN',
  p_call_post_authentication  => FALSE
);

-- ... perform APEX operations ...

-- Clean up session at end of script
apex_session.delete_session;
```

**Alternative (if session already exists):**
```sql
apex_session.attach(
  p_app_id   => l_app_id,
  p_page_id  => 1,
  p_session_id => v('APP_SESSION')
);
```

**Action Items:**
- [x] Update `scripts/upload_inline.sql` (add session management)
- [x] Update `scripts/upload_enhanced_files.sql` (add session management)
- [x] Update `scripts/upload_static_files.sql` (add session management)
- [ ] Update `install_all_v2.sql` if it calls APEX APIs directly
- [ ] Test deployment with full session context

**Reference:** APEX_24_REVIEW.md § R-02

---

### C-3: LOB Memory Leaks in Upload Scripts

**Severity:** 🟡 **HIGH**  
**Files:** `scripts/upload_inline.sql`  
**Impact:** Session-level memory leaks on error  

**Issue:**
If `create_app_static_file` raises an error, control jumps to `EXCEPTION` block without calling `DBMS_LOB.FREETEMPORARY(l_blob)`.

**Current Code (❌ Avoid):**
```sql
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
    -- ... write to LOB ...
    wwv_flow_api.create_app_static_file(..., p_file_content => l_blob);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
```

**Recommended Fix (✅ Use):**
```sql
DECLARE
    l_blob BLOB;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
    -- ... write to LOB ...
    wwv_flow_api.create_app_static_file(..., p_file_content => l_blob);
    
    -- Success path: free LOB
    IF DBMS_LOB.ISTEMPORARY(l_blob) = 1 THEN
        DBMS_LOB.FREETEMPORARY(l_blob);
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Error path: ensure LOB cleanup
        BEGIN
            IF l_blob IS NOT NULL AND DBMS_LOB.ISTEMPORARY(l_blob) = 1 THEN
                DBMS_LOB.FREETEMPORARY(l_blob);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL; -- LOB cleanup is best-effort
        END;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
```

**Action Items:**
- [x] Update `scripts/upload_inline.sql` (all LOB operations)
- [x] Verify no other scripts have similar pattern
- [ ] Test error scenarios to confirm cleanup

**Reference:** APEX_24_REVIEW.md § R-04

---

## Priority 2: High-Priority Issues (Fix Before Launch)

### H-1: CSS Anti-Pattern: Excessive `!important` Usage

**Severity:** 🟡 **HIGH**  
**Files:** `APEX_FRONTEND_DESIGN.md` (CSS section), static CSS files  
**Impact:** Maintenance burden, conflicts with Universal Theme upgrades  

**Issue:**
The design document specifies 30+ CSS rules using `!important` to override Universal Theme defaults. APEX 24.2 provides `--ut-*` CSS Custom Properties specifically for customization.

**Current Code (❌ Avoid):**
```css
.t-Header {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3) !important;
}
```

**Recommended Fix (✅ Use):**
```css
:root {
  /* Theme-level customization — no !important needed */
  --ut-palette-primary:          #0f172a;
  --ut-palette-primary-contrast: #ffffff;
  --ut-palette-primary-shade:    #1e293b;
  --ut-header-background-color:  #0f172a;
  --ut-nav-background-color:     #1b2638;
  --ut-login-background-color:   #0c1929;
  --ut-focus-outline-color:      rgba(59, 130, 246, 0.6);
  --ut-link-text-color:          #3b82f6;
  --ut-body-content-background-color: rgba(248, 250, 252, 0.95);
}
```

**Action Items:**
- [x] Audit all CSS in `APEX_FRONTEND_DESIGN.md` Section 3.3
- [x] Replace `!important` rules with `--ut-*` variables
- [x] Use Theme Roller for base palette (see § R-06)
- [ ] Test theme survives APEX upgrades
- [x] Document custom variables in code comments

**Reference:** APEX_24_REVIEW.md § R-05

---

### H-2: Custom Toast Implementation vs Native API

**Severity:** 🟡 **HIGH**  
**Files:** `APEX_FRONTEND_DESIGN.md` Section 3.3 (JavaScript), `app-scripts.js`  
**Impact:** Not accessible, not theme-aware, maintenance burden  

**Issue:**
`showToast()` function creates custom DOM elements with inline styles and injects `<style>` tags at runtime. Does not meet WCAG accessibility requirements.

**Current Code (❌ Avoid):**
```javascript
function showToast(message, type, duration) {
    const toast = document.createElement('div');
    toast.className = 'custom-toast custom-toast-' + type;
    // ... manual DOM + style injection
}
```

**Recommended Fix (✅ Use):**
```javascript
/**
 * Show notification using APEX's native message API.
 * Respects theme, meets WCAG, integrates with error handling.
 */
function showToast(message, type, duration) {
    duration = duration || 4000;
    apex.message.clearErrors();

    if (type === 'success') {
        apex.message.showPageSuccess(message);
    } else if (type === 'error') {
        apex.message.showErrors([{
            type:     'error',
            location: 'page',
            message:  message
        }]);
    } else {
        apex.message.showPageSuccess(message);
    }

    if (duration > 0) {
        setTimeout(function() {
            apex.message.hidePageSuccess();
            apex.message.clearErrors();
        }, duration);
    }
}
```

**Action Items:**
- [ ] Replace `showToast()` in JavaScript global utilities
- [ ] Update all calls to use `apex.message` API
- [ ] Remove custom CSS for `.custom-toast`
- [ ] Test accessibility with screen readers
- [ ] Verify theme compatibility in Dark Mode

**Reference:** APEX_24_REVIEW.md § R-08

---

### H-3: Status Badges Should Use Template Components

**Severity:** 🟡 **HIGH**  
**Files:** `APEX_FRONTEND_DESIGN.md` Page 2 (Case List), CSS for status badges  
**Impact:** Duplicated logic across client/server, maintainability  

**Issue:**
50+ lines of custom CSS for status badges plus a custom JS `getStatusClass()` mapping function. Duplicates logic across client and server.

**Current Approach (❌ Avoid):**
```css
.status-badge--approved { background: #2e8540; color: white; }
.status-badge--denied { background: #cd2026; color: white; }
/* ... 10+ more variants ... */
```

```javascript
function getStatusClass(status) {
    if (!status) return 'unknown';
    status = status.toUpperCase();
    if (status.includes('APPROVED')) return 'approved';
    // ... 10+ more checks
}
```

**Recommended Fix (✅ Use Template Components):**

**Step 1:** Create Shared Component → Template Component named `Status Badge`:
```html
<span class="u-pill {case STATUS/}
  {when APPROVED/}u-success
  {when DENIED/}u-danger
  {when PENDING/}u-warning
  {when RFE/}u-info
  {when RECEIVED/}u-color-14
  {otherwise/}u-color-7
{endcase/}">
  <span class="u-pill-label">#STATUS#</span>
</span>
```

**Step 2:** Reference in Interactive Grid using Template Component column type (no JavaScript needed).

**Utility Classes (built-in, Dark Mode compatible):**

| Class | Color | Status |
|-------|-------|--------|
| `u-success` | Green | Approved |
| `u-danger` | Red | Denied |
| `u-warning` | Amber | Pending |
| `u-info` | Blue | RFE |
| `u-color-14` | Purple | Received |
| `u-color-7` | Gray | Unknown |

**Action Items:**
- [ ] Create Template Component in Shared Components
- [ ] Update Case List (Page 2) to use Template Component
- [ ] Remove custom CSS for `.status-badge-*`
- [ ] Remove `getStatusClass()` JavaScript function
- [ ] Update Case Details (Page 3) to use Template Component
- [ ] Test Dark Mode appearance

**Reference:** APEX_24_REVIEW.md § R-07

---

## Priority 3: Medium-Priority Issues (Improve Quality)

### M-1: Hardcoded Application IDs

**Severity:** 🟢 **MEDIUM**  
**Files:** `scripts/upload_inline.sql`, `scripts/upload_enhanced_files.sql`  
**Impact:** Breaks in multi-environment setups  

**Issue:**
`l_app_id NUMBER := 102;` is hardcoded. Won't work in TEST/PROD if app IDs differ.

**Recommended Fix (✅ Use):**
```sql
-- Option 1: SQLcl/SQL*Plus substitution variable
DEFINE APP_ID = 102

-- Inside PL/SQL block:
l_app_id NUMBER := &APP_ID.;
```

**Option 2: Configuration table:**
```sql
SELECT config_value INTO l_app_id
  FROM app_config
 WHERE config_key = 'APEX_APP_ID';
```

**Action Items:**
- [ ] Add `DEFINE APP_ID` at top of upload scripts
- [ ] Update all `l_app_id := 102` to use `&APP_ID.`
- [ ] Document in deployment guide

**Reference:** APEX_24_REVIEW.md § R-03

---

### M-2: Legacy Event Binding in JavaScript

**Severity:** 🟢 **MEDIUM**  
**Files:** `APEX_FRONTEND_DESIGN.md` Section 3.3 (JavaScript)  
**Impact:** Uses deprecated patterns  

**Issue:**
`apex.jQuery(document).on('apexreadyend', ...)` is a legacy event binding pattern.

**Current Code (❌ Avoid):**
```javascript
apex.jQuery(document).on('apexreadyend', function() {
    initVisualEnhancements();
});
```

**Recommended Fix (✅ Use):**
```javascript
// APEX 24.2 idiomatic initialization
apex.jQuery(function() {
    initVisualEnhancements();
});

// Or for page-specific after Dynamic Actions:
apex.page.ready(function() {
    initVisualEnhancements();
});
```

**Action Items:**
- [ ] Replace `apexreadyend` with `apex.jQuery(fn)` or `apex.page.ready(fn)`
- [ ] Test initialization timing with Dynamic Actions

**Reference:** APEX_24_REVIEW.md § R-09

---

### M-3: Global Namespace Pollution in JavaScript

**Severity:** 🟢 **MEDIUM**  
**Files:** `APEX_FRONTEND_DESIGN.md` Section 3.3 (JavaScript), `app-scripts.js`  
**Impact:** Risk of collision with other libraries  

**Issue:**
All functions declared in global scope. Risks collision with APEX internal functions or other libraries.

**Current Code (❌ Avoid):**
```javascript
function formatReceiptNumber(receiptNum) { /* ... */ }
function normalizeReceiptNumber(receiptNum) { /* ... */ }
// ... 10+ global functions
```

**Recommended Fix (✅ Use IIFE):**
```javascript
/**
 * USCIS Case Tracker — Application JavaScript Utilities
 * Wrapped IIFE to avoid global namespace pollution.
 */
(function(apex, $) {
    "use strict";

    // === Receipt Number Utilities ===
    function formatReceiptNumber(receiptNum) { /* ... */ }
    function normalizeReceiptNumber(receiptNum) { /* ... */ }
    function isValidReceiptNumber(receiptNum) { /* ... */ }
    function getStatusClass(status) { /* ... */ }

    // Expose only what pages need on window object
    window.USCIS = {
        formatReceiptNumber:    formatReceiptNumber,
        normalizeReceiptNumber: normalizeReceiptNumber,
        isValidReceiptNumber:   isValidReceiptNumber,
        getStatusClass:         getStatusClass,
        showToast:              showToast
    };

    // Initialize on APEX ready
    $(function() {
        initVisualEnhancements();
    });

})(apex, apex.jQuery);
```

**Usage from Dynamic Actions:**
```javascript
USCIS.showToast('Case added successfully!', 'success');
```

**Action Items:**
- [ ] Wrap all JavaScript utilities in IIFE
- [ ] Expose minimal API via `window.USCIS`
- [ ] Update Dynamic Actions to use `USCIS.*` calls
- [ ] Test no conflicts with APEX/jQuery

**Reference:** APEX_24_REVIEW.md § R-10

---

### M-4: CSP Violation from Runtime Style Injection

**Severity:** 🟢 **MEDIUM**  
**Files:** `APEX_FRONTEND_DESIGN.md` JavaScript (showToast, showConfetti)  
**Impact:** Violates Content Security Policy if enabled  

**Issue:**
Dynamically creates `<style>` elements via `document.createElement('style')` and appends to `<head>`. Violates CSP `style-src` directive.

**Recommended Fix:**
Move all animation styles (`@keyframes toastIn`, `@keyframes confettiFall`, etc.) into static `app-styles.css` file. Remove runtime `<style>` injection.

**APEX 24.2 CSP Configuration:**
```
Content-Security-Policy:
  default-src 'self';
  style-src 'self';  ← Remove 'unsafe-inline' once styles are static
  script-src 'self' 'unsafe-eval';
```

**Action Items:**
- [ ] Move all `@keyframes` to `app-styles.css`
- [ ] Remove `document.createElement('style')` calls
- [ ] Enable CSP in Shared Components → Security
- [ ] Test all animations work with CSP

**Reference:** APEX_24_REVIEW.md § R-11

---

## Priority 4: Security Findings

### S-1: SQL Injection Risk in Row Actions

**Severity:** 🔴 **CRITICAL**  
**Files:** `APEX_FRONTEND_DESIGN.md` Page 2 (Case List) — Row Actions (implementation also referenced in `APEX_INSTRUCTIONS.md`)  
**Impact:** SQL injection vulnerability  

**Issue:**
The "Delete" row action uses substitution string `#RECEIPT_NUMBER#` directly in PL/SQL, which is vulnerable to SQL injection if not properly bound.

**Current Code (❌ INSECURE):**
```sql
-- Row Action: Delete
PL/SQL: |
  BEGIN
    uscis_case_pkg.delete_case('#RECEIPT_NUMBER#');  -- SQL INJECTION RISK
  END;
```

**Recommended Fix (✅ SECURE):**

**Step 1:** Configure Row Action "Set Items":
```yaml
Row Action: Delete
Set Items:
  - Target Item: P2_SELECTED_RECEIPT
    Value: #RECEIPT_NUMBER#  # Only used to populate page item
```

**Step 2:** Use bind variable in PL/SQL:
```sql
PL/SQL: |
  -- SECURITY: Use bind variable instead of substitution string
  BEGIN
    uscis_case_pkg.delete_case(p_receipt_number => :P2_SELECTED_RECEIPT);
  END;
```

**Action Items:**
- [ ] Update all Row Actions to use "Set Items" + bind variables — ⏳ pending test verification
- [ ] Audit all PL/SQL processes for substitution string usage — ⏳ pending test verification
- [ ] Test Row Actions and PL/SQL with malicious input
- [ ] Document secure pattern in developer guide — ⏳ **blocked:** cannot mark complete until Row Actions and PL/SQL items are validated with malicious-input tests and evidence is attached (see evidence requirement below)

> **Note:** Implementation items above must remain unchecked until the malicious-input test is performed and evidence (logs/screenshots/test report) is attached confirming queries are parameterized and no injection occurs.
>
> **Evidence requirement:** Test with payload `'; DROP TABLE case_history; --` against all updated Row Actions and PL/SQL procedures. Attach logs, screenshots, or a test report proving no injection occurred. The "Document secure pattern" item cannot be checked until this evidence is recorded.
>
> **Test steps:** Run targeted tests against updated Row Actions and PL/SQL procedures using payloads such as `'; DROP TABLE case_history; --`, capture test logs/screenshots, and attach evidence before marking implementation items complete.

**Reference:** APEX_24_REVIEW.md § R-12, APEX_FRONTEND_DESIGN.md Page 2 Row Actions

---

### S-2: XSS Risk in Case Details Display

**Severity:** 🔴 **CRITICAL**  
**Files:** `APEX_INSTRUCTIONS.md` Page 3 (Case Details)  
**Impact:** Cross-site scripting vulnerability  

**Issue:**
Case Details page uses PL/SQL Function Body to generate HTML without escaping user-controlled values (notes, status).

**Current Code (❌ INSECURE):**
```sql
RETURN '<div class="case-header__notes">' || l_case.notes || '</div>';
```

**Recommended Fix (✅ SECURE):**
```sql
DECLARE
  l_notes_html VARCHAR2(4000);
BEGIN
  -- Escape all user-controlled values
  l_notes_html := APEX_ESCAPE.HTML(l_case.notes);
  
  RETURN '<div class="case-header__notes">' || l_notes_html || '</div>';
END;
```

**For Interactive Grid/Report columns:**
```yaml
Column: CURRENT_STATUS
Security:
  Escape Special Characters: Yes  # Enable in column settings
```

**Action Items:**
- [x] Implemented: `apex_escape.html()` applied to P3_CASE_TYPE, P3_CURRENT_STATUS, P3_LAST_UPDATED, P3_TRACKING_SINCE, P3_NOTES, status history and audit trail loop columns
- [ ] Verified with XSS tests: server-side escaping prevents injection (run XSS payloads and attach evidence)
- [x] Implemented: Server-side pre-escaping via `apex_escape.html()` + `!RAW` substitution pattern on Page 3 PL/SQL-generated HTML tables
- [ ] Verified with XSS tests: `apex_escape.html()` + `!RAW` substitution pattern blocks injection (run XSS payloads and attach evidence)
- [x] Implemented: `showToast()` uses `textContent` (inherently XSS-safe); `confirmDelete()` delegates to `apex.message.confirm()`; `apex.util.escapeHTML()` applied where needed
- [ ] Verified with XSS tests: client-side functions behave safely with XSS payloads (test and attach evidence)
- [ ] Test with malicious input (e.g., `<script>alert('XSS')</script>`) — run XSS payload tests against all fields listed above; record test evidence in completion notes; only then mark "Verified" checkboxes above complete

> **Note:** "Implemented" checkboxes indicate code changes are done. "Verified" checkboxes must remain unchecked until XSS payload tests are performed and evidence (test logs/screenshots/test report) is attached confirming all user-controlled values are properly escaped. No "Verified" item should be marked complete without recorded proof of XSS-safe behavior.

**Reference:** APEX_24_REVIEW.md § R-13

---

### S-3: Authorization Bypass Risk in VPD Policy

**Severity:** 🟡 **HIGH**  
**Files:** `ORACLE_APEX_MIGRATION_SPEC.md` Section 8.2 (VPD Policy)  
**Impact:** Logic error allows unauthorized data access  

**Issue:**
The VPD policy function `uscis_vpd_policy` calls `V('APP_USER')` and `APEX_ACL.HAS_USER_ROLE()` without first confirming an APEX session exists. If called outside APEX (e.g., SQL*Plus), these may return NULL or fail, potentially bypassing security.

**Current Code (❌ INSECURE):**
```sql
BEGIN
    l_app_user := V('APP_USER');  -- Returns NULL if not in APEX session
    
    l_is_admin := APEX_ACL.HAS_USER_ROLE(
        p_application_id => :APP_ID,  -- May be NULL
        p_user_name      => l_app_user,
        p_role_static_id => 'ADMINISTRATOR'
    );
    
    IF l_is_admin THEN
        RETURN '1=1';  -- BYPASS: Admins see all
    END IF;
    -- ...
END;
```

**Recommended Fix (✅ SECURE):**
```sql
FUNCTION uscis_vpd_policy(
    p_schema  IN VARCHAR2,
    p_table   IN VARCHAR2
) RETURN VARCHAR2 IS
    l_predicate VARCHAR2(400);
    l_app_user  VARCHAR2(255);
    l_app_id    NUMBER;
    l_is_admin  BOOLEAN := FALSE;
BEGIN
    -- Consistently use SYS_CONTEXT for APEX session detection
    BEGIN
        l_app_id := TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    EXCEPTION
        WHEN OTHERS THEN
            l_app_id := NULL;
    END;
    
    IF l_app_id IS NOT NULL THEN
        -- We are in an APEX session
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
                l_is_admin := FALSE;
        END;
        
        IF l_is_admin THEN
            RETURN '1=1';
        END IF;
        
        -- Use bind variable style for safety
        RETURN 'created_by = SYS_CONTEXT(''APEX$SESSION'', ''APP_USER'')';
    ELSE
        -- Not in APEX session - use database user
        RETURN 'created_by = USER';
    END IF;
END;
```

**Action Items:**
- [ ] Update VPD policy to use `SYS_CONTEXT('APEX$SESSION', ...)`
- [ ] Add exception handling for APEX_ACL calls
- [ ] Test policy in SQL*Plus (should not bypass)
- [ ] Test policy in APEX (should enforce user isolation)

**Reference:** ORACLE_APEX_MIGRATION_SPEC.md § 8.2

---

### S-4: Client IP Validation Missing in Export Audit

**Severity:** 🟢 **MEDIUM**  
**Files:** `APEX_INSTRUCTIONS.md` Page 6 (Export Process)  
**Impact:** IP spoofing possible if proxy headers not validated  

**Issue:**
Export process reads `HTTP_X_FORWARDED_FOR` header without validating the request came from a trusted proxy. Attackers can spoof this header.

**Current Code (❌ INSECURE):**
```sql
-- No validation of proxy source
l_client_ip := OWA_UTIL.GET_CGI_ENV('HTTP_X_FORWARDED_FOR');
```

**Recommended Fix (✅ SECURE):**
```sql
DECLARE
    l_remote    VARCHAR2(50);
    l_xff       VARCHAR2(500);
    l_client_ip VARCHAR2(50);
    
    -- TRUSTED PROXY CONFIGURATION
    -- Load from uscis_config: TRUSTED_PROXY_IPS = '203.0.113.1,203.0.113.2'
    l_trusted_proxy_csv VARCHAR2(4000);
    l_trusted_proxies   APEX_T_VARCHAR2;
    l_is_trusted_proxy  BOOLEAN := FALSE;
BEGIN
    -- Get actual remote address
    l_remote := OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR');
    
    -- Load trusted proxies from config
    l_trusted_proxy_csv := uscis_util_pkg.get_config('TRUSTED_PROXY_IPS', '');
    l_trusted_proxies := APEX_STRING.SPLIT(l_trusted_proxy_csv, ',');
    
    -- Check if request came from trusted proxy
    FOR i IN 1..l_trusted_proxies.COUNT LOOP
        IF l_remote = TRIM(l_trusted_proxies(i)) THEN
            l_is_trusted_proxy := TRUE;
            EXIT;
        END IF;
    END LOOP;
    
    -- Only trust X-Forwarded-For if from known proxy
    IF l_is_trusted_proxy THEN
        l_xff := OWA_UTIL.GET_CGI_ENV('HTTP_X_FORWARDED_FOR');
        IF l_xff IS NOT NULL THEN
            -- Leftmost IP is original client
            l_client_ip := TRIM(REGEXP_SUBSTR(l_xff, '[^,]+', 1, 1));
        ELSE
            l_client_ip := l_remote;
        END IF;
    ELSE
        -- Don't trust X-Forwarded-For from untrusted sources
        l_client_ip := l_remote;
    END IF;
    
    -- Use l_client_ip for audit logging
END;
```

**Action Items:**
- [ ] Add `TRUSTED_PROXY_IPS` to `scheduler_config`
- [ ] Update export process with proxy validation
- [ ] Update `uscis_util_pkg.get_client_ip()` with same logic
- [ ] Document trusted proxy IPs in deployment guide

**Reference:** APEX_INSTRUCTIONS.md § Page 6 Export Process

---

## Priority 5: AI Integration Opportunities

### AI-1: Missing AI Assistant for Case Search

**Severity:** 💡 **OPPORTUNITY**  
**Files:** `APEX_FRONTEND_DESIGN.md` Dashboard  
**Impact:** Improved user experience  

**APEX 24.2 Feature:** Add native AI Assistant to dashboard for natural-language case queries.

**Implementation (declarative):**

**Step 1:** Configure AI service in Shared Components → AI Services  
**Step 2:** Add Region on Dashboard (Page 1):
```yaml
Region:
  Type: AI Assistant
  Data Source: V_CASE_CURRENT_STATUS
```

**Step 3:** Add Dynamic Action:
```yaml
Button: Show AI Assistant
Action: Show AI Assistant
```

**Example user prompts:**
- "Show me all cases pending more than 6 months"
- "Which cases were approved last week?"
- "Summarize the status changes for IOE1234567890"

**Action Items:**
- [ ] Configure OpenAI/Cohere/OCI Gen AI provider
- [ ] Add AI Assistant region to Dashboard
- [ ] Test natural language queries
- [ ] Add to user documentation

**Reference:** APEX_24_REVIEW.md § R-14

---

### AI-2: RAG-Powered Status Insights

**Severity:** 💡 **OPPORTUNITY**  
**Files:** `APEX_FRONTEND_DESIGN.md` Case Details  
**Impact:** Smart summaries for users  

**Use Case:** Auto-generate plain-English summary on Case Details page explaining what each status change means and estimated next steps.

**Implementation:**
```sql
-- In PL/SQL Process or Computation
DECLARE
    l_summary CLOB;
BEGIN
    l_summary := APEX_AI.GENERATE(
        p_prompt        => 'Summarize the case status timeline for receipt ' || 
                           :P3_RECEIPT_NUMBER,
        p_system_prompt => 'You are a USCIS case status analyst. Be concise.',
        p_ai_provider   => 'MY_AI_SERVICE'
    );
    
    :P3_AI_SUMMARY := l_summary;
END;
```

**Action Items:**
- [ ] Add AI summary region to Case Details (Page 3)
- [ ] Configure system prompt for USCIS context
- [ ] Test summary quality with sample cases
- [ ] Add disclaimer about AI-generated content

**Reference:** APEX_24_REVIEW.md § R-15

---

## Summary of Action Items by File

### `scripts/upload_inline.sql`
- [ ] Replace `wwv_flow_imp.*` with `wwv_flow_api.*` (C-1)
- [ ] Add `apex_session.create_session()` (C-2)
- [ ] Add LOB cleanup in exception handler (C-3)
- [ ] Add `DEFINE APP_ID` parameter (M-1)

### `scripts/upload_enhanced_files.sql`
- [ ] Replace `wwv_flow_imp.*` with `wwv_flow_api.*` (C-1)
- [ ] Add `apex_session.create_session()` (C-2)
- [ ] Add `DEFINE APP_ID` parameter (M-1)

### `APEX_FRONTEND_DESIGN.md` (CSS)
- [x] Replace 30+ `!important` rules with `--ut-*` variables (H-1)
- [ ] Remove `.custom-toast` styles (H-2) — ⏳ blocked: detailed task "Remove custom CSS for .custom-toast" not yet implemented
- [ ] Remove `.status-badge-*` styles (H-3) — ⏳ blocked: detailed task "Create Template Component" and "Remove custom CSS for .status-badge-*" not yet implemented
- [ ] Move `@keyframes` to static file (M-4) — ⏳ blocked: detailed task "Move all @keyframes to app-styles.css" not yet implemented

### `APEX_FRONTEND_DESIGN.md` (JavaScript)
- [ ] Replace `showToast()` with `apex.message` (H-2) — ⏳ detailed task not yet implemented
- [ ] Create Template Component for status badges (H-3) — ⏳ detailed task not yet implemented
- [ ] Replace `apexreadyend` with `apex.page.ready()` (M-2) — ⏳ detailed task not yet implemented
- [ ] Wrap utilities in IIFE (M-3) — ⏳ detailed task not yet implemented
- [ ] Remove runtime `<style>` injection (M-4) — ⏳ detailed task not yet implemented

> **⚠️ Summary ↔ Detail Consistency Rule:** Summary checkboxes in this section must match the corresponding detailed section checkboxes. Do not mark a summary item complete unless every related detailed task is also checked. When completing detailed tasks, update the summary to match.

### `APEX_INSTRUCTIONS.md` (Page 2)
- [ ] Update Row Actions to use bind variables (S-1)
- [ ] Enable "Escape Special Characters" on columns (S-2)

### `APEX_INSTRUCTIONS.md` (Page 3)
- [ ] Add `APEX_ESCAPE.HTML()` to PL/SQL output (S-2)

### `APEX_INSTRUCTIONS.md` (Page 6)
- [ ] Add trusted proxy validation to export (S-4)

### `ORACLE_APEX_MIGRATION_SPEC.md` (VPD)
- [ ] Fix VPD policy to check APEX session (S-3)

---

## Remediation Effort Estimate

| Priority | Issues | Estimated Hours |
|----------|--------|-----------------|
| Critical (C-1 to C-3) | 3 | 12-16 hours |
| High (H-1 to H-3) | 3 | 16-20 hours |
| Medium (M-1 to M-4) | 4 | 8-12 hours |
| Security (S-1 to S-4) | 4 | 12-16 hours |
| AI Opportunities | 2 | 4-8 hours (optional) |
| **Total** | **16 issues** | **52-72 hours** |

---

## Testing Checklist

After remediation, verify:

### Functional Testing
- [ ] Upload scripts work with public APIs
- [ ] Session context properly initialized
- [ ] LOBs freed on error paths
- [ ] All Dynamic Actions fire correctly

### Security Testing
- [ ] SQL injection test on Row Actions (e.g., `'; DROP TABLE case_history; --`)
- [ ] XSS test on user input (e.g., `<script>alert('XSS')</script>`)
- [ ] VPD policy blocks unauthorized access (test in SQL*Plus)
- [ ] Proxy IP spoofing blocked (test with fake X-Forwarded-For)

### UI/UX Testing
- [ ] Theme Roller colors applied correctly
- [ ] Status badges use Template Components
- [ ] Toast messages use `apex.message`
- [ ] Dark Mode appearance correct
- [ ] Screen reader accessibility (WCAG 2.1 AA)

### Performance Testing
- [ ] Page load time < 2 seconds
- [ ] No console errors from CSP violations
- [ ] No JavaScript namespace collisions

---

## Next Steps

1. **Immediate:** Fix all Critical (C-*) issues before any production deployment
2. **High Priority:** Complete High (H-*) issues before launch
3. **Before UAT:** Address all Security (S-*) findings
4. **Enhancement:** Consider AI opportunities for v1.1

**Estimated Timeline:**
- Week 1: Critical fixes (12-16 hours)
- Week 2: High-priority fixes (16-20 hours)
- Week 3: Medium + Security fixes (20-28 hours)
- Week 4: Testing + validation (8-12 hours)

**Total:** 4 weeks for full remediation

---

**Review Completed:** February 6, 2026  
**Reviewed By:** Claude  
**Standards:** APEX_24_REVIEW.md (APEX 24.2 Code Review Standards)