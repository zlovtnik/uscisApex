# APEX 24.2 Code Review — Standards & Enhancement Guide

> **Reviewed:** February 5, 2026
> **Scope:** `scripts/upload_inline.sql`, static CSS/JS assets, deployment scripts
> **Applies to:** All PL/SQL, SQL, JavaScript, and APEX Component code in this project

---

## Table of Contents

1. [Review Priority Hierarchy](#review-priority-hierarchy)
2. [PL/SQL & Deployment Scripts](#plsql--deployment-scripts)
   - [R-01: Public APIs over Internal APIs](#r-01-public-apis-over-internal-apis)
   - [R-02: Full Session Context](#r-02-full-session-context)
   - [R-03: Parameterized Application IDs](#r-03-parameterized-application-ids)
   - [R-04: LOB Memory Safety](#r-04-lob-memory-safety)
3. [CSS & Universal Theme](#css--universal-theme)
   - [R-05: Use UT CSS Custom Properties](#r-05-use-ut-css-custom-properties)
   - [R-06: Theme Roller for Base Palette](#r-06-theme-roller-for-base-palette)
   - [R-07: Status Badges via Template Components](#r-07-status-badges-via-template-components)
4. [JavaScript](#javascript)
   - [R-08: Native apex.message over Custom Toasts](#r-08-native-apexmessage-over-custom-toasts)
   - [R-09: Modern Initialization Pattern](#r-09-modern-initialization-pattern)
   - [R-10: IIFE Module Wrapping](#r-10-iife-module-wrapping)
5. [Security](#security)
   - [R-11: Content Security Policy Compliance](#r-11-content-security-policy-compliance)
   - [R-12: Bind Variables in All SQL](#r-12-bind-variables-in-all-sql)
   - [R-13: Output Escaping](#r-13-output-escaping)
6. [AI Integration Opportunities](#ai-integration-opportunities)
   - [R-14: AI Assistant for Case Search](#r-14-ai-assistant-for-case-search)
   - [R-15: RAG-Powered Status Insights](#r-15-rag-powered-status-insights)
7. [Quick Reference: Before vs. After Patterns](#quick-reference-before-vs-after-patterns)
8. [Affected Files](#affected-files)

---

## Review Priority Hierarchy

When reviewing or writing code for this project, always prioritize in this order:

1. **Native over Custom** — If a task can be done with a native Dynamic Action (e.g., `Show AI Assistant`, `Generate Text with AI`), use it over custom PL/SQL or JavaScript.
2. **AI Integration** — Identify opportunities to use Retrieval-Augmented Generation (RAG) or AI-powered search in the UI.
3. **Modern UI** — Use the Universal Theme, `--ut-*` CSS variables, and Template Components.
4. **Security** — All SQL uses bind variables; adhere to the APEX Security Checklist.

---

## PL/SQL & Deployment Scripts

### R-01: Public APIs over Internal APIs

| | Detail |
|---|--------|
| **Severity** | **HIGH** |
| **Files** | `scripts/upload_inline.sql`, `scripts/upload_enhanced_files.sql`, `scripts/upload_static_files.sql` |
| **Problem** | Scripts call `wwv_flow_imp.create_app_static_file` and `wwv_flow_imp.remove_app_static_file` — these are internal, undocumented APIs that Oracle reserves for import/export machinery. They may change or break on patch upgrades without notice. |

**Why APEX 24.x is better:** The public `WWV_FLOW_API` package provides supported equivalents that are guaranteed stable across patch releases.

**Before (avoid):**
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

**After (preferred):**
```sql
-- DELETE: Use the supported public view + API
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

-- CREATE: supported public API
wwv_flow_api.create_app_static_file(
  p_flow_id      => l_app_id,
  p_file_name    => 'app-styles.css',
  p_mime_type    => 'text/css',
  p_file_charset => 'utf-8',
  p_file_content => l_blob
);
```

**Rule:** Never call `wwv_flow_imp.*` in hand-written scripts. If APEX's own export files use it, that's fine — those are machine-generated.

---

### R-02: Full Session Context

| | Detail |
|---|--------|
| **Severity** | **MEDIUM** |
| **Files** | All `scripts/*.sql` that call APEX APIs |
| **Problem** | `apex_util.set_security_group_id(l_workspace_id)` sets only the security group. Many APEX 24.2 APIs require a full session context. |

**Why APEX 24.x is better:** `APEX_SESSION.CREATE_SESSION` initializes the full APEX engine context (substitution strings, session state, etc.), making all `APEX_*` APIs available.

**Before (avoid):**
```sql
apex_util.set_security_group_id(l_workspace_id);
```

**After (preferred):**
```sql
apex_session.create_session(
  p_app_id                    => l_app_id,
  p_page_id                   => 1,
  p_username                  => 'ADMIN',
  p_call_post_authentication  => FALSE
);
```

> **Note:** Always call `apex_session.delete_session` at the end of your script if you created one, or use `apex_session.attach` if a session already exists.

---

### R-03: Parameterized Application IDs

| | Detail |
|---|--------|
| **Severity** | **LOW** |
| **Files** | `scripts/upload_inline.sql`, `scripts/upload_enhanced_files.sql` |
| **Problem** | `l_app_id NUMBER := 102;` is hardcoded. Breaks in multi-environment setups. |

**After (preferred):**
```sql
-- At the top of the script (SQLcl / SQL*Plus):
DEFINE APP_ID = 102

-- Inside the PL/SQL block:
l_app_id NUMBER := &APP_ID.;
```

Or read from a configuration table:
```sql
SELECT config_value INTO l_app_id
  FROM app_config
 WHERE config_key = 'APEX_APP_ID';
```

---

### R-04: LOB Memory Safety

| | Detail |
|---|--------|
| **Severity** | **MEDIUM** |
| **Files** | `scripts/upload_inline.sql` |
| **Problem** | If `create_app_static_file` raises an error, control jumps to the `EXCEPTION` block without calling `DBMS_LOB.FREETEMPORARY(l_blob)`. The temporary LOB leaks for the session duration. |

**After (preferred):**
```sql
EXCEPTION
    WHEN OTHERS THEN
        -- Free any temporary LOBs to prevent session-level memory leaks
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

**Rule:** Every `DBMS_LOB.CREATETEMPORARY` must have a corresponding `FREETEMPORARY` on both the success and error paths.

---

## CSS & Universal Theme

### R-05: Use UT CSS Custom Properties

| | Detail |
|---|--------|
| **Severity** | **HIGH** |
| **Files** | `scripts/upload_inline.sql` (CSS content), `app-styles.css` |
| **Problem** | 30+ CSS rules use `!important` to override Universal Theme defaults. This creates a maintenance burden and conflicts with UT patch updates. |

**Why APEX 24.x is better:** APEX 24.2's Universal Theme exposes 60+ `--ut-*` CSS Custom Properties specifically designed for customization. Overriding these requires no `!important` and survives theme upgrades.

**Before (avoid):**
```css
.t-Header {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3) !important;
}
```

**After (preferred):**
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

**Rule:** Before writing a CSS rule with `!important` against a `.t-*` class, check if a `--ut-*` variable exists for the same purpose. See: `apex_24doc/content/htmrn/` for the full variable list.

---

### R-06: Theme Roller for Base Palette

| | Detail |
|---|--------|
| **Severity** | **LOW** |
| **Recommendation** | Use **Theme Roller** (Shared Components > Themes > Theme Roller) to define the color palette declaratively. Settings export with the application and require zero custom CSS for basic theming. |

**Steps:**
1. Open App Builder → Shared Components → Themes
2. Click **Theme Roller** (the paint roller icon in the developer toolbar)
3. Set Primary, Header, Nav, Login colors
4. Click **Save As** to create a Theme Style
5. Set as the default style

**Benefit:** The palette survives APEX upgrades and is exported/imported with the application.

---

### R-07: Status Badges via Template Components

| | Detail |
|---|--------|
| **Severity** | **MEDIUM** |
| **Files** | CSS (`.status-approved`, etc.) + JS (`getStatusClass()`) |
| **Problem** | 50+ lines of custom CSS for status badges + a custom JS mapping function. Duplicates logic across client and server. |

**Why APEX 24.2 Template Components are better:** Template Components (Partial type) are reusable, declarative HTML snippets defined once in Shared Components. They use Template Directives and UT's built-in utility classes.

**Step 1: Create a Shared Component → Template Component** named `Status Badge`:
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

**Step 2: Reference in Classic Report / Cards / IG** using the Template Component column type — no JavaScript needed.

**UT utility classes used:**
| Class | Color | Status |
|-------|-------|--------|
| `u-success` | Green | Approved |
| `u-danger` | Red | Denied |
| `u-warning` | Amber | Pending |
| `u-info` | Blue | RFE |
| `u-color-14` | Purple | Received |
| `u-color-7` | Gray | Unknown |

These automatically adapt to Dark Mode in APEX 24.2.

---

## JavaScript

### R-08: Native `apex.message` over Custom Toasts

| | Detail |
|---|--------|
| **Severity** | **MEDIUM** |
| **Files** | `app-scripts.js` (`showToast()` function) |
| **Problem** | `showToast()` creates custom DOM elements with inline styles, injects `<style>` tags at runtime. Not accessible, not theme-aware. |

**Why the native approach is better:** `apex.message` respects the theme style, meets WCAG accessibility requirements, and integrates with APEX's error handling.

**Before (avoid):**
```javascript
function showToast(message, type, duration) {
    const toast = document.createElement('div');
    toast.className = 'custom-toast custom-toast-' + type;
    // ... manual DOM + style injection
}
```

**After (preferred):**
```javascript
/**
 * Show a notification using APEX's native message API.
 * @param {string} message - Message text
 * @param {string} type    - 'success' | 'error' | 'info'
 * @param {number} duration - Auto-dismiss in ms (default: 4000)
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
        // Info / warning — use page success styling
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

---

### R-09: Modern Initialization Pattern

| | Detail |
|---|--------|
| **Severity** | **LOW** |
| **Files** | `app-scripts.js` |
| **Problem** | `apex.jQuery(document).on('apexreadyend', ...)` — legacy event binding. |

**After (preferred):**
```javascript
// APEX 24.2 idiomatic initialization
apex.jQuery(function() {
    initVisualEnhancements();
});
```

Or for page-specific initialization after Dynamic Actions fire:
```javascript
apex.page.ready(function() {
    initVisualEnhancements();
});
```

---

### R-10: IIFE Module Wrapping

| | Detail |
|---|--------|
| **Severity** | **LOW** |
| **Files** | `app-scripts.js` |
| **Problem** | All functions are declared in global scope. Risks collision with other libraries or APEX internal functions. |

**After (preferred):**
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

    // Expose only what pages need on the window object
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

---

## Security

### R-11: Content Security Policy Compliance

| | Detail |
|---|--------|
| **Severity** | **MEDIUM** |
| **Files** | `app-scripts.js` (`showToast()`, `showConfetti()`) |
| **Problem** | Dynamically creates `<style>` elements via `document.createElement('style')` and appends to `<head>`. Violates CSP `style-src` directive if you enable APEX 24.2's HTTP Security Headers. |

**Fix:** Move all animation styles (`@keyframes toastIn`, `@keyframes confettiFall`, etc.) into the static `app-styles.css` file. Remove runtime `<style>` injection entirely.

**APEX 24.2 CSP setup in Shared Components > Security:**
```
Content-Security-Policy:
  default-src 'self';
  style-src 'self' 'unsafe-inline';   ← Remove 'unsafe-inline' once styles are static
  script-src 'self' 'unsafe-eval';
```

---

### R-12: Bind Variables in All SQL

**Rule (enforced):** Every SQL statement in PL/SQL packages (`packages/*.sql`) and APEX processes must use bind variables. Never concatenate user input into SQL strings.

**Before (INSECURE):**
```sql
EXECUTE IMMEDIATE 'SELECT * FROM cases WHERE receipt = ''' || p_receipt || '''';
```

**After (SECURE):**
```sql
EXECUTE IMMEDIATE 'SELECT * FROM cases WHERE receipt = :1' USING p_receipt;
```

**APEX-specific:** In page processes and report queries, use `:P1_ITEM_NAME` bind syntax:
```sql
SELECT * FROM case_history WHERE receipt_number = :P1_RECEIPT_NUMBER;
```

---

### R-13: Output Escaping

**Rule:** Always escape user-supplied data in HTML regions, PL/SQL report columns, and JavaScript output.

```sql
-- PL/SQL: Use APEX_ESCAPE
htp.p(apex_escape.html(l_user_input));

-- In reports: Enable "Escape Special Characters" on every column
-- In Classic Reports: Set Column > Security > Escape special characters = Yes
```

**JavaScript:** Use `apex.util.escapeHTML()` instead of inserting raw text into HTML:
```javascript
element.innerHTML = apex.util.escapeHTML(userText);
// Or better: use textContent when no HTML formatting is needed
element.textContent = userText;
```

---

## AI Integration Opportunities

### R-14: AI Assistant for Case Search

**APEX 24.2 Feature:** Add a native AI Assistant to the dashboard so users can ask natural-language questions about their cases.

**Implementation (declarative — no custom code):**
1. **Shared Components → AI Services** — Configure an OpenAI/Cohere/OCI Gen AI provider
2. **Page 1 (Dashboard) → Add Region** — Type: "AI Assistant"
3. **Dynamic Action on Button** — Action: "Show AI Assistant"
4. The assistant context uses the page's data source (e.g., `V_CASE_CURRENT_STATUS`)

**Example user prompts the assistant handles:**
- "Show me all cases pending more than 6 months"
- "Which cases were approved last week?"
- "Summarize the status changes for IOE1234567890"

### R-15: RAG-Powered Status Insights

Use `APEX_AI.GENERATE` with Retrieval-Augmented Generation to provide smart summaries:

```sql
-- In a PL/SQL Process or Computation:
l_summary := APEX_AI.GENERATE(
    p_prompt        => 'Summarize the case status timeline for receipt '
                       || :P1_RECEIPT_NUMBER,
    p_system_prompt => 'You are a USCIS case status analyst. Be concise.',
    p_ai_provider   => 'MY_AI_SERVICE'  -- defined in Shared Components
);
```

**Use case:** Auto-generate a plain-English summary card on the Case Detail page describing what each status change means and estimated next steps.

---

## Quick Reference: Before vs. After Patterns

| # | Issue | Severity | Old Pattern | APEX 24.2 Pattern |
|---|-------|----------|-------------|-------------------|
| R-01 | Internal API usage | **HIGH** | `wwv_flow_imp.*` | `wwv_flow_api.*` |
| R-02 | Incomplete session | **MED** | `apex_util.set_security_group_id` | `apex_session.create_session` |
| R-03 | Hardcoded app ID | LOW | `l_app_id := 102` | `&APP_ID.` substitution |
| R-04 | LOB leak on error | **MED** | No cleanup in EXCEPTION | `DBMS_LOB.FREETEMPORARY` in handler |
| R-05 | CSS `!important` abuse | **HIGH** | Override `.t-*` classes | `--ut-*` CSS variables |
| R-06 | Manual color theming | LOW | Hand-coded gradients | Theme Roller |
| R-07 | Custom status badges | **MED** | CSS + JS mapping | Template Components + `u-*` classes |
| R-08 | Custom toast UI | **MED** | DOM creation + inline styles | `apex.message.showPageSuccess` |
| R-09 | Legacy event binding | LOW | `apexreadyend` event | `apex.jQuery(fn)` |
| R-10 | Global namespace | LOW | Global functions | IIFE + `window.USCIS` |
| R-11 | CSP violation | **MED** | Runtime `<style>` injection | Static CSS file |
| R-12 | SQL injection risk | **HIGH** | String concatenation | Bind variables |
| R-13 | XSS risk | **HIGH** | Raw HTML output | `apex_escape.html()` |
| R-14 | No AI features | Opportunity | — | Native AI Assistant |
| R-15 | No smart summaries | Opportunity | — | `APEX_AI.GENERATE` with RAG |

---

## Affected Files

| File | Findings |
|------|----------|
| `scripts/upload_inline.sql` | R-01, R-02, R-03, R-04, R-05, R-08, R-09, R-10, R-11 |
| `scripts/upload_enhanced_files.sql` | R-01, R-02, R-03 |
| `scripts/upload_static_files.sql` | R-01, R-02 |
| `scripts/simple_upload.sql` | R-02 |
| Static CSS (all variants) | R-05, R-06, R-07, R-11 |
| Static JS (all variants) | R-08, R-09, R-10, R-11 |
| PL/SQL packages (`packages/*.sql`) | R-12, R-13 (verify) |
| APEX Pages (all) | R-07, R-14, R-15 |
