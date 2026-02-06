# USCIS Case Tracker: APEX Setup Guide

**Tasks Covered:** 1.4.1 through 1.4.7  
**Prerequisites:** APEX Workspace created (Task 1.1.5)  
**Last Updated:** February 4, 2026  

---

## Task 1.4.1: Create APEX Application (App ID, Theme)

### Navigate To
**APEX Home → App Builder → Create**

### Step-by-Step Instructions

1. **Click "Create" → "New Application"**

2. **Application Definition:**
   | Field | Value |
   |-------|-------|
   | Name | `USCIS Case Tracker` |
   | Application ID | `100` (or auto-assigned) |
   | Application Alias | `USCIS_TRACKER` |
   | Schema | `USCIS_APP` |

3. **Pages Section:**
   - Check "Home Page" (will create Page 1)
   - **Uncheck** all other options for now (we'll create pages manually)

4. **Features Section:**
   - Check: ✅ Access Control
   - Check: ✅ Activity Reporting  
   - Uncheck: ❌ Email (unless needed)
   - Uncheck: ❌ Feedback

5. **Appearance:**
   | Setting | Value |
   |---------|-------|
   | Theme | Universal Theme (42) |
   | Theme Style | **Vita - Slate** |
   | Navigation | **Side Column** |
   | Header | Visible |

6. **Click "Create Application"**

### Post-Creation Configuration

After creation, configure additional settings:

**Navigate To:** App Builder → [Your App] → Shared Components → Application Definition

```
Application Properties:
├── Name: USCIS Case Tracker
├── Version: 1.0.0
├── Application Alias: USCIS_TRACKER
└── Logging: Yes
```

### Verification
- [ ] Application loads without errors
- [ ] Universal Theme 42 applied
- [ ] Side navigation visible
- [ ] Home page renders

---

## Task 1.4.2: Configure Global Page (Page 0)

### Navigate To
**App Builder → [Your App] → Page 0 (Global Page)**

### Purpose
Page 0 is the "Global Page" - content here appears on ALL pages. Use it for:
- Global CSS/JavaScript
- Application-wide header/footer
- Common components

### Step-by-Step Instructions

#### 1. Add Custom CSS

**Navigate To:** Page 0 → CSS → Inline

```css
/* USCIS Case Tracker - Global Styles */

:root {
  /* Primary Colors - USCIS Brand */
  --uscis-primary: #003366;
  --uscis-secondary: #0071bc;
  --uscis-accent: #02bfe7;
  
  /* Status Colors */
  --status-approved: #2e8540;
  --status-denied: #cd2026;
  --status-pending: #fdb81e;
  --status-rfe: #0071bc;
  --status-received: #4c2c92;
  --status-unknown: #5b616b;
}

/* Header Brand Styling */
.t-Header-logo {
  background-color: var(--uscis-primary) !important;
}

/* Status Badge Styling */
.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.status-approved { background: var(--status-approved); color: white; }
.status-denied { background: var(--status-denied); color: white; }
.status-pending { background: var(--status-pending); color: #1a1a1a; }
.status-rfe { background: var(--status-rfe); color: white; }
.status-received { background: var(--status-received); color: white; }
.status-unknown { background: var(--status-unknown); color: white; }

/* Receipt Number Formatting */
.receipt-number {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 14px;
  letter-spacing: 0.5px;
}

/* Card Enhancements */
.t-Card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  transform: translateY(-2px);
  transition: all 0.2s ease;
}

/* Timeline Styling for Status History */
.timeline-container {
  position: relative;
  padding-left: 30px;
}

.timeline-container::before {
  content: '';
  position: absolute;
  left: 10px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--uscis-secondary);
}

.timeline-item {
  position: relative;
  margin-bottom: 20px;
  padding: 10px 15px;
  background: #f8f9fa;
  border-radius: 6px;
}

.timeline-item::before {
  content: '';
  position: absolute;
  left: -24px;
  top: 15px;
  width: 12px;
  height: 12px;
  background: var(--uscis-secondary);
  border-radius: 50%;
  border: 2px solid white;
}
```

#### 2. Add Global JavaScript

**Navigate To:** Page 0 → JavaScript → Function and Global Variable Declaration

```javascript
// USCIS Case Tracker - Global JavaScript

// Format receipt numbers with visual grouping
function formatReceiptNumber(receiptNum) {
    if (!receiptNum || receiptNum.length !== 13) return receiptNum;
    return receiptNum.substring(0, 3) + '-' + 
           receiptNum.substring(3, 6) + '-' + 
           receiptNum.substring(6);
}

// Copy to clipboard utility with fallback for non-HTTPS/older browsers
function copyToClipboard(text, successMsg) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function() {
            apex.message.showPageSuccess(successMsg || 'Copied to clipboard!');
        }).catch(function(err) {
            // Try fallback on clipboard API failure
            fallbackCopyToClipboard(text, successMsg, err);
        });
    } else {
        fallbackCopyToClipboard(text, successMsg, null);
    }
    
    function fallbackCopyToClipboard(text, successMsg, originalErr) {
        var textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-9999px';
        textarea.style.top = '0';
        document.body.appendChild(textarea);
        textarea.focus();
        textarea.select();
        try {
            var successful = document.execCommand('copy');
            if (successful) {
                apex.message.showPageSuccess(successMsg || 'Copied to clipboard!');
            } else {
                var errMsg = originalErr ? ('Failed to copy: ' + originalErr) : 'Failed to copy to clipboard';
                apex.message.showErrors([{type: 'error', message: errMsg}]);
            }
        } catch (err) {
            var errMsg = originalErr ? ('Failed to copy: ' + originalErr + ', fallback error: ' + err) : ('Failed to copy: ' + err);
            apex.message.showErrors([{type: 'error', message: errMsg}]);
        }
        document.body.removeChild(textarea);
    }
}

// Status color mapping
function getStatusClass(status) {
    if (!status) return 'status-unknown';
    const s = status.toLowerCase();
    if (s.includes('approved') || s.includes('card was produced') || s.includes('card is being produced') || s.includes('new card')) return 'status-approved';
    if (s.includes('not approved') || s.includes('denied') || s.includes('rejected')) return 'status-denied';
    if (s.includes('rfe') || s.includes('evidence')) return 'status-rfe';
    if (s.includes('received')) return 'status-received';
    if (s.includes('pending') || s.includes('processing')) return 'status-pending';
    return 'status-unknown';
}

// Confirm action helper
function confirmAction(message, callback) {
    apex.message.confirm(message, function(okPressed) {
        if (okPressed) {
            callback();
        }
    });
}

// Auto-refresh page item with cleanup support
var autoRefreshTimer = null;

function scheduleRefresh(intervalSeconds) {
    // Clear any existing timer first
    if (autoRefreshTimer) {
        clearInterval(autoRefreshTimer);
        autoRefreshTimer = null;
    }
    
    autoRefreshTimer = setInterval(function() {
        var region = apex.region('case_list');
        if (region) {
            region.refresh();
        }
    }, intervalSeconds * 1000);
    
    return autoRefreshTimer;
}

function stopAutoRefresh() {
    if (autoRefreshTimer) {
        clearInterval(autoRefreshTimer);
        autoRefreshTimer = null;
    }
}

// Cleanup timer on page unload
$(document).on('apexbeforeunload', function() {
    stopAutoRefresh();
});
```

#### 3. Add Application Items for Global State

**Navigate To:** Shared Components → Application Items → Create

| Item Name | Scope | Session State | Security |
|-----------|-------|---------------|----------|
| `G_USER_ROLE` | Application | Per Session | Unrestricted |
| `G_AUTO_CHECK_ENABLED` | Application | Per Session | Unrestricted |
| `G_USCIS_API_MODE` | Application | Per Session | Unrestricted |

#### 4. Add Before Header Process (Set User Context)

**Navigate To:** Page 0 → Processing → Create Process

| Property | Value |
|----------|-------|
| Name | `Set User Context` |
| Type | PL/SQL Code |
| Point | Before Header |

```sql
BEGIN
    -- Set user role (will integrate with authorization later)
    :G_USER_ROLE := NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER');
    
    -- Load auto-check setting from config
    BEGIN
        SELECT config_value 
        INTO :G_AUTO_CHECK_ENABLED
        FROM scheduler_config 
        WHERE config_key = 'AUTO_CHECK_ENABLED';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :G_AUTO_CHECK_ENABLED := 'N';
    END;
    
    -- Set API mode (SANDBOX/PRODUCTION)
    BEGIN
        SELECT config_value 
        INTO :G_USCIS_API_MODE
        FROM scheduler_config 
        WHERE config_key = 'API_MODE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :G_USCIS_API_MODE := 'SANDBOX';
    END;
END;
```

### Verification
- [ ] CSS styles appear on all pages
- [ ] JavaScript functions available globally
- [ ] Application items populated on session start

---

## Task 1.4.3: Create Navigation Menu Structure

### Navigate To
**Shared Components → Navigation → Navigation Menu → Desktop Navigation Menu**

### Step-by-Step Instructions

#### Delete Default Entries
Remove auto-generated entries, then create:

#### Create Menu Entries

Click **Create Entry** for each:

| Seq | Entry | Target | Icon | Condition |
|-----|-------|--------|------|-----------|
| 10 | Dashboard | Page 1 | `fa-home` | Always |
| 20 | My Cases | Page 2 | `fa-folder-open` | Always |
| 30 | Check Status | Page 5 | `fa-search` | Always |
| 40 | Import/Export | Page 6 | `fa-exchange` | Always |
| 50 | --- | - | - | Separator |
| 60 | Settings | Page 7 | `fa-cog` | Always |
| 70 | Administration | Page 8 | `fa-shield` | `G_USER_ROLE = 'ADMIN'` |

#### Creating Each Entry

**Example: Dashboard Entry**

| Property | Value |
|----------|-------|
| Sequence | 10 |
| Image/Class | `fa-home` |
| List Entry Label | `Dashboard` |
| Target Type | Page in this Application |
| Page | 1 |
| Clear Cache | &mdash; |
| Authorization Scheme | &mdash; (None - visible to all) |

**Example: Administration Entry (Admin Only)**

| Property | Value |
|----------|-------|
| Sequence | 70 |
| Image/Class | `fa-shield` |
| List Entry Label | `Administration` |
| Target Type | Page in this Application |
| Page | 8 |
| Condition Type | Item = Value |
| Expression 1 | `G_USER_ROLE` |
| Expression 2 | `ADMIN` |

### Menu Structure Preview
```
📊 Dashboard
📁 My Cases
🔍 Check Status  
↔️ Import/Export
─────────────
⚙️ Settings
🛡️ Administration (Admin only)
```

---

## Task 1.4.4: Set Up Authentication Scheme

### Navigate To
**Shared Components → Security → Authentication Schemes**

### Development Environment Setup

#### Option 1: APEX Accounts (Recommended for Development)

1. **Create New Authentication Scheme:**
   - Name: `APEX Account Authentication`
   - Scheme Type: `Application Express Accounts`
   - Click **Create**

2. **Set as Current:**
   - Click the scheme → Make Current

#### Option 2: Custom PL/SQL Authentication (Production)

1. **Create New Authentication Scheme:**

| Property | Value |
|----------|-------|
| Name | `Custom Authentication` |
| Scheme Type | Custom |

2. **Authentication Function (PL/SQL):**

```sql
-- Constant-time comparison function to prevent timing attacks
FUNCTION constant_time_compare(s1 VARCHAR2, s2 VARCHAR2) RETURN BOOLEAN IS
    l_len1  NUMBER := NVL(LENGTH(s1), 0);
    l_len2  NUMBER := NVL(LENGTH(s2), 0);
    l_diff  NUMBER := 0;
    l_max_len NUMBER := GREATEST(l_len1, l_len2);
BEGIN
    -- Return FALSE for unequal lengths (still performs full work)
    IF l_len1 != l_len2 THEN
        -- Perform dummy comparison to maintain timing
        FOR i IN 1..l_max_len LOOP
            l_diff := l_diff + 1; -- Dummy operation
        END LOOP;
        RETURN FALSE;
    END IF;

    -- Constant-time comparison of all characters
    FOR i IN 1..l_len1 LOOP
        l_diff := l_diff + ABS(ASCII(SUBSTR(s1, i, 1)) - ASCII(SUBSTR(s2, i, 1)));
    END LOOP;

    RETURN l_diff = 0;
END constant_time_compare;

FUNCTION custom_authenticate (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    l_stored_hash   VARCHAR2(256);
    l_salt          VARCHAR2(64);
    l_user_role     VARCHAR2(50);
    l_input_hash    VARCHAR2(256);
    l_valid         BOOLEAN := FALSE;
BEGIN
    -- Lookup user credentials from users table (use bind variables for security)
    BEGIN
        SELECT password_hash, password_salt, user_role
        INTO l_stored_hash, l_salt, l_user_role
        FROM app_users
        WHERE UPPER(username) = UPPER(p_username)
          AND is_active = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- User not found - return false without revealing which field failed
            RETURN FALSE;
    END;

    -- Hash the provided password with the stored salt using PBKDF2
    -- This provides much stronger protection than single SHA-256
    l_input_hash := RAWTOHEX(
        DBMS_CRYPTO.PBKDF2(
            password => UTL_RAW.CAST_TO_RAW(p_password || l_salt),
            salt => UTL_RAW.CAST_TO_RAW(l_salt),
            rounds => 10000,  -- High iteration count for security
            key_len => 32,    -- 256-bit key
            mac => DBMS_CRYPTO.HMAC_SH256
        )
    );

    -- Use constant-time comparison to prevent timing attacks
    IF constant_time_compare(l_input_hash, l_stored_hash) THEN
        l_valid := TRUE;
        APEX_UTIL.SET_SESSION_STATE('G_USER_ROLE', l_user_role);
    END IF;

    RETURN l_valid;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error server-side, return false without exposing details
        apex_debug.error('Authentication error: %s', SQLERRM);
        RETURN FALSE;
END custom_authenticate;
```

3. **Post-Authentication Procedure:**

```sql
-- Autonomous transaction procedure for audit logging
-- Isolates audit commit from main transaction
PROCEDURE log_audit_entry_autonomous (
    p_action_type  IN VARCHAR2,
    p_user_name    IN VARCHAR2,
    p_ip_address   IN VARCHAR2,
    p_details      IN VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO case_audit_log (
        action_type,
        user_name,
        ip_address,
        action_timestamp,
        details
    ) VALUES (
        p_action_type,
        p_user_name,
        p_ip_address,
        SYSTIMESTAMP,
        p_details
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Always commit/rollback in autonomous transaction
        ROLLBACK;
        -- Log error but don't propagate - audit failure shouldn't break auth
        apex_debug.error('Audit log failed: %s', SQLERRM);
END log_audit_entry_autonomous;

PROCEDURE post_auth IS
BEGIN
    -- Log successful login using autonomous transaction
    log_audit_entry_autonomous(
        p_action_type => 'LOGIN',
        p_user_name   => APEX_APPLICATION.G_USER,
        p_ip_address  => OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR'),
        p_details     => 'User logged in successfully'
    );
    -- No COMMIT here - autonomous transaction handles its own commit
END post_auth;
```

4. **Configure Session Settings:**

| Property | Value |
|----------|-------|
| Session Not Valid URL | `f?p=&APP_ID.:101` |
| Session Idle Timeout | 1800 (30 min) |
| Session Maximum Length | 28800 (8 hrs) |

### Verification
- [ ] Login page appears when accessing app
- [ ] Valid credentials grant access
- [ ] Invalid credentials show error
- [ ] Session expires after timeout

---

## Task 1.4.5: Create Authorization Schemes (Roles)

### Navigate To
**Shared Components → Security → Authorization Schemes**

### Create Authorization Schemes

#### 1. IS_AUTHENTICATED

| Property | Value |
|----------|-------|
| Name | `IS_AUTHENTICATED` |
| Scheme Type | Is In Group |
| Error Message | `You must be logged in to access this page.` |

**Evaluation:**
```sql
RETURN apex_authentication.is_authenticated;
```

#### 2. IS_ADMIN

| Property | Value |
|----------|-------|
| Name | `IS_ADMIN` |
| Scheme Type | PL/SQL Function Returning Boolean |
| PL/SQL Code | See below |
| Error Message | `Administrator privileges required.` |
| Caching | Once per session |

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') = 'ADMIN';
```

#### 3. IS_POWER_USER

| Property | Value |
|----------|-------|
| Name | `IS_POWER_USER` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | `Power User or Admin privileges required.` |
| Caching | Once per session |

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') IN ('ADMIN', 'POWER_USER');
```

#### 4. CAN_EDIT_CASES

| Property | Value |
|----------|-------|
| Name | `CAN_EDIT_CASES` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | `You do not have permission to edit cases.` |
| Caching | Once per session |

```sql
-- All authenticated users can edit their own cases
RETURN apex_authentication.is_authenticated;
```

#### 5. CAN_VIEW_AUDIT_LOGS

| Property | Value |
|----------|-------|
| Name | `CAN_VIEW_AUDIT_LOGS` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | `You do not have permission to view audit logs.` |
| Caching | Once per session |

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') = 'ADMIN';
```

### Apply to Components

| Component | Authorization Scheme |
|-----------|---------------------|
| Administration Page (8) | `IS_ADMIN` |
| Audit Logs Region | `CAN_VIEW_AUDIT_LOGS` |
| Delete Case Button | `CAN_EDIT_CASES` |
| Settings Page (7) | `IS_AUTHENTICATED` |

---

## Task 1.4.6: Configure Application Settings

### Navigate To
**Shared Components → Application Definition → Properties**

### General Settings

| Tab | Setting | Value |
|-----|---------|-------|
| Name | Application Name | `USCIS Case Tracker` |
| Name | Application Alias | `USCIS_TRACKER` |
| Name | Version | `1.0.0` |
| Appearance | Logo Type | Text |
| Appearance | Logo Text | `USCIS Case Tracker` |
| Availability | Status | Available |
| Availability | Build Status | Run and Build Application |

### Security Settings

**Navigate To:** Shared Components → Security Attributes

| Setting | Value |
|---------|-------|
| Session State Protection | Enabled |
| Maximum Session Length | 28800 |
| Maximum Session Idle | 1800 |
| Session Checksum | Enabled |
| Deep Linking | Enabled |
| Browser Cache | Disabled (for dev) |

### Substitution Strings

**Navigate To:** Shared Components → Application Definition → Substitution Strings

| Substitution String | Value |
|--------------------|-------|
| APP_VERSION | 1.0.0 |
| APP_ENV | DEVELOPMENT |
| USCIS_API_URL | https://api-int.uscis.gov |
| SUPPORT_EMAIL | support@uscis.gov |

### Error Handling

**Navigate To:** Shared Components → Application Definition → Error Handling

| Setting | Value |
|---------|-------|
| Error Handling Function | `uscis_util_pkg.handle_apex_error` |
| Show Technical Info | No (Production) / Yes (Dev) |

---

## Task 1.4.7: Create Placeholder Pages (1-8, 101)

### Navigate To
**App Builder → [Your App] → Create Page**

### Page Creation Overview

| Page | Name | Type | Authorization |
|------|------|------|---------------|
| 1 | Dashboard | Blank | IS_AUTHENTICATED |
| 2 | Case List | Blank | IS_AUTHENTICATED |
| 3 | Case Details | Blank | IS_AUTHENTICATED |
| 4 | Add Case | Modal Dialog | IS_AUTHENTICATED |
| 5 | Check Status | Modal Dialog | IS_AUTHENTICATED |
| 6 | Import/Export | Blank | IS_AUTHENTICATED |
| 7 | Settings | Blank | IS_AUTHENTICATED |
| 8 | Administration | Blank | IS_ADMIN |
| 101 | Login | Login Page | Public |

### Creating Each Page

#### Page 1: Dashboard

1. **Create Page → Blank Page**

| Property | Value |
|----------|-------|
| Page Number | 1 |
| Name | Dashboard |
| Page Mode | Normal |
| Page Template | Standard |
| Navigation | Yes |

2. **Add Placeholder Region:**

| Property | Value |
|----------|-------|
| Type | Static Content |
| Title | Welcome to USCIS Case Tracker |
| Template | Standard |

**Source (HTML):**
```html
<div class="t-Alert t-Alert--wizard t-Alert--info">
    <div class="t-Alert-wrap">
        <div class="t-Alert-icon">
            <span class="t-Icon t-Icon--info"></span>
        </div>
        <div class="t-Alert-content">
            <div class="t-Alert-title">Dashboard Coming Soon</div>
            <div class="t-Alert-body">
                This page will display:
                <ul>
                    <li>Summary cards with case statistics</li>
                    <li>Status distribution charts</li>
                    <li>Recent activity timeline</li>
                    <li>Quick action buttons</li>
                </ul>
            </div>
        </div>
    </div>
</div>
```

#### Page 2: Case List

| Property | Value |
|----------|-------|
| Page Number | 2 |
| Name | Case List |
| Page Mode | Normal |

**Placeholder Content:**
```html
<div class="t-Alert t-Alert--wizard t-Alert--info">
    <div class="t-Alert-wrap">
        <div class="t-Alert-icon">
            <span class="t-Icon t-Icon--info"></span>
        </div>
        <div class="t-Alert-content">
            <div class="t-Alert-title">Case List Coming Soon</div>
            <div class="t-Alert-body">
                This page will display an Interactive Grid with all tracked cases.
                <br>Features: Search, Filter, Inline Edit, Export
            </div>
        </div>
    </div>
</div>
```

#### Page 3: Case Details

| Property | Value |
|----------|-------|
| Page Number | 3 |
| Name | Case Details |
| Page Mode | Normal |

**Add Page Item:**
| Item | Type | Purpose |
|------|------|---------|
| P3_RECEIPT_NUMBER | Hidden | Primary key |

#### Page 4: Add Case (Modal Dialog)

1. **Create Page → Blank Page**

| Property | Value |
|----------|-------|
| Page Number | 4 |
| Name | Add Case |
| Page Mode | **Modal Dialog** |
| Dialog Template | Drawer |
| Dialog Width | 600 |

#### Page 5: Check Status (Modal Dialog)

| Property | Value |
|----------|-------|
| Page Number | 5 |
| Name | Check Status |
| Page Mode | **Modal Dialog** |
| Dialog Width | 700 |

#### Page 6: Import/Export

| Property | Value |
|----------|-------|
| Page Number | 6 |
| Name | Import/Export |
| Page Mode | Normal |

#### Page 7: Settings

| Property | Value |
|----------|-------|
| Page Number | 7 |
| Name | Settings |
| Page Mode | Normal |

#### Page 8: Administration

| Property | Value |
|----------|-------|
| Page Number | 8 |
| Name | Administration |
| Page Mode | Normal |
| **Authorization Scheme** | **IS_ADMIN** |

#### Page 101: Login

1. **Create Page → Login Page**

| Property | Value |
|----------|-------|
| Page Number | 101 |
| Name | Login |

2. **Customize Login Page:**

**Navigate To:** Page 101 → Region → Login → Source

Update the page title:
- **Title:** `USCIS Case Tracker`
- Add subtitle/description as needed

---

## Quick Reference: Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│                         Header                               │
│  [Logo: USCIS Case Tracker]                    [User Menu]  │
├───────────────┬─────────────────────────────────────────────┤
│               │                                             │
│   Navigation  │              Page Content                   │
│               │                                             │
│  📊 Dashboard │   ┌─────────────────────────────────────┐   │
│  📁 My Cases  │   │                                     │   │
│  🔍 Check     │   │          Region Content             │   │
│  ↔️ Import    │   │                                     │   │
│  ──────────   │   │                                     │   │
│  ⚙️ Settings  │   └─────────────────────────────────────┘   │
│  🛡️ Admin     │                                             │
│               │                                             │
├───────────────┴─────────────────────────────────────────────┤
│                         Footer                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Verification Checklist

### Task 1.4.1 ⬜
- [ ] Application created with ID 100 (or assigned ID)
- [ ] Universal Theme 42 applied
- [ ] Vita - Slate style selected
- [ ] Side navigation layout configured

### Task 1.4.2 ⬜
- [ ] Custom CSS on Page 0
- [ ] Global JavaScript functions
- [ ] Application items created
- [ ] Before Header process working

### Task 1.4.3 ⬜
- [ ] All menu entries created
- [ ] Icons displaying correctly
- [ ] Admin menu conditional
- [ ] Pages linked correctly

### Task 1.4.4 ⬜
- [ ] Authentication scheme configured
- [ ] Login redirects work
- [ ] Session timeout configured
- [ ] Logout works properly

### Task 1.4.5 ⬜
- [ ] IS_AUTHENTICATED scheme works
- [ ] IS_ADMIN restricts admin pages
- [ ] Authorization applied to pages

### Task 1.4.6 ⬜
- [ ] Application properties set
- [ ] Security settings configured
- [ ] Substitution strings defined

### Task 1.4.7 ⬜
- [ ] All 9 pages created (1-8, 101)
- [ ] Modal dialogs for pages 4, 5
- [ ] Authorization on page 8
- [ ] Navigation links working

---

## Next Steps

After completing these tasks, proceed to:

1. **Phase 2: PL/SQL Package Stubs** (Tasks 1.3.1 - 1.3.8)
2. **Phase 2: Core Pages Implementation** (Tasks 2.3.x - 2.5.x)

---

*End of APEX Setup Guide*
