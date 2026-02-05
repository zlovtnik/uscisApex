# USCIS Case Tracker - APEX Shell Setup Guide

**Version:** 1.1.0  
**Scope:** Shell setup (Tasks 1.4.1 - 1.4.7)  
**APEX Version:** Oracle APEX 26 AI  
**Last Updated:** February 2026

---

## Quick Roadmap (Best Path)

Follow these steps in order. Each step builds on the previous one.

| Step | Task | Where in APEX | Outcome |
| ---- | ---- | ------------- | ------- |
| 1 | 1.4.1 | App Builder → Create | App shell created (ID 100, Theme 42, Vita-Slate, Side Nav) |
| 2 | 1.4.6 | Shared Components → Application Definition | Global settings, security, branding, substitution strings |
| 3 | 1.4.2 | Page 0 (Global Page) | Global CSS/JS + application items + user context process |
| 4 | 1.4.5 | Shared Components → Authorization | Authorization schemes ready for pages/components |
| 5 | 1.4.3 | Shared Components → Navigation | Side menu structure aligned to pages |
| 6 | 1.4.7 | App Builder → Create Page | Placeholder pages + login created with proper security |
| 7 | 1.4.4 | Shared Components → Authentication | Confirm dev auth or switch to production auth |

### Why this order?
- **App Definition** and **Global Page** are foundational for every page.
- **Authorization** should exist before you assign it to pages.
- **Navigation** should match the page IDs that already exist.
- **Authentication** is validated last to avoid lockouts during setup.

---

## Prerequisites

Before starting, ensure:

- [ ] Oracle Database with Oracle APEX 26 AI installed
- [ ] Schema `USCIS_APP` created and mapped to APEX workspace
- [ ] Database objects created via `install_all_v2.sql`
- [ ] Workspace name: `USCISAPP` (or your workspace)

### Fix Schema Mapping Issue

If APEX created `WKSP_USCISAPP` but your objects are in `USCIS_APP`:

```sql
-- Run as ADMIN/SYS
BEGIN
    APEX_INSTANCE_ADMIN.ADD_SCHEMA(
        p_workspace => 'USCISAPP',
        p_schema    => 'USCIS_APP'
    );
    COMMIT;
END;
/

-- Verify mapping
SELECT workspace_name, schema 
FROM apex_workspace_schemas 
WHERE workspace_name LIKE '%USCIS%';
```

---

## Task 1.4.1: Create Application

### Navigate To

App Builder → Create → New Application

### Step-by-Step

| Step | Action |
| ---- | ------ |
| 1 | Click **Create** button |
| 2 | Select **New Application** |
| 3 | Enter application details (see table below) |
| 4 | Click **Create Application** |

### Application Properties

| Property | Value |
| -------- | ----- |
| Name | USCIS Case Tracker |
| Application ID | 100 |
| Appearance | Vita - Slate |
| Theme | Universal Theme (42) |
| Theme Style | Vita - Slate |
| Navigation | Side Column |
| Features | ✅ Access Control, ✅ Activity Reporting |
| Authentication | Application Express Accounts |
| Parsing Schema | USCIS_APP |

### Task 1.4.1 Verification

After creation, confirm:

- [ ] Application ID is 100
- [ ] Theme is Universal Theme (42)
- [ ] Color scheme is Vita - Slate
- [ ] Navigation displays on left side

---

## Task 1.4.2: Configure Global Page (Page 0)

### Navigate To

Page Designer → Page 0 (Global Page)

### 2.1: Add CSS Styles

**Location:** Page 0 → Page Properties → CSS → Inline

```css
/* ============================================================
   USCIS Case Tracker - Global Styles
   ============================================================ */

/* Status Colors */
:root {
    --status-approved: #2e8540;
    --status-denied: #cd2026;
    --status-pending: #fdb81e;
    --status-rfe: #0071bc;
    --status-received: #4c2c92;
    --status-unknown: #5b616b;
}

/* Receipt Number Styling */
.receipt-number {
    font-family: 'Courier New', monospace;
    font-weight: 600;
    letter-spacing: 1px;
}

/* Status Row Highlighting */
.status-approved { background-color: rgba(46, 133, 64, 0.15) !important; }
.status-denied { background-color: rgba(205, 32, 38, 0.15) !important; }
.status-pending { background-color: rgba(253, 184, 30, 0.15) !important; }
.status-rfe { background-color: rgba(0, 113, 188, 0.15) !important; }
.status-received { background-color: rgba(76, 44, 146, 0.15) !important; }

/* Status Badges */
.status-badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
}
.status-badge.approved { background: var(--status-approved); color: white; }
.status-badge.denied { background: var(--status-denied); color: white; }
.status-badge.pending { background: var(--status-pending); color: #1a1a1a; }
.status-badge.rfe { background: var(--status-rfe); color: white; }
.status-badge.received { background: var(--status-received); color: white; }

/* Days Warning */
.days-old-warning { color: #d93900; font-weight: bold; }

/* Card Hover Effect */
.case-card {
    transition: transform 0.2s, box-shadow 0.2s;
}
.case-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

/* Timeline Styling */
.status-timeline .timeline-item {
    border-left: 3px solid var(--status-pending);
    padding-left: 20px;
    margin-left: 10px;
}

/* Mobile Responsive */
@media (max-width: 768px) {
    .a-CardView-items {
        grid-template-columns: 1fr !important;
    }
    .receipt-number {
        font-size: 14px;
    }
}
```

### 2.2: Add JavaScript Utilities

**Location:** Page 0 → Page Properties → JavaScript → Function and Global Variable Declaration

```javascript
/* ============================================================
   USCIS Case Tracker - Global JavaScript Utilities
   ============================================================ */

var USCIS = USCIS || {};

// Copy text to clipboard
USCIS.copyToClipboard = function(text) {
    if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(function() {
            apex.message.showPageSuccess('Copied: ' + text);
        });
    } else {
        // Fallback for older browsers
        var textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        apex.message.showPageSuccess('Copied: ' + text);
    }
};

// Format receipt number with dashes for display
USCIS.formatReceipt = function(receipt) {
    if (!receipt || receipt.length !== 13) return receipt;
    return receipt.substring(0,3) + '-' + 
           receipt.substring(3,6) + '-' + 
           receipt.substring(6,10) + '-' + 
           receipt.substring(10);
};

// Validate receipt number format
USCIS.validateReceipt = function(receipt) {
    var pattern = /^[A-Z]{3}[0-9]{10}$/;
    var normalized = receipt.toUpperCase().replace(/[^A-Z0-9]/g, '');
    return pattern.test(normalized);
};

// Normalize receipt number (uppercase, remove non-alphanumeric)
USCIS.normalizeReceipt = function(receipt) {
    return receipt.toUpperCase().replace(/[^A-Z0-9]/g, '');
};

// Get status CSS class
USCIS.getStatusClass = function(status) {
    if (!status) return 'unknown';
    status = status.toUpperCase();
    if (status.indexOf('APPROVED') >= 0) return 'approved';
    if (status.indexOf('DENIED') >= 0 || status.indexOf('REJECTED') >= 0) return 'denied';
    if (status.indexOf('EVIDENCE') >= 0 || status.indexOf('RFE') >= 0) return 'rfe';
    if (status.indexOf('RECEIVED') >= 0 || status.indexOf('ACCEPTED') >= 0) return 'received';
    if (status.indexOf('PENDING') >= 0 || status.indexOf('REVIEW') >= 0) return 'pending';
    return 'unknown';
};

// Apply row styling based on status
USCIS.applyRowStyling = function(regionStaticId) {
    $('#' + regionStaticId + ' .a-IG-row, #' + regionStaticId + ' tr').each(function() {
        var $row = $(this);
        var statusText = $row.find('[headers*="STATUS"], [data-status]').text();
        var statusClass = USCIS.getStatusClass(statusText);
        $row.addClass('status-' + statusClass);
    });
};

// Confirm dialog wrapper
USCIS.confirm = function(message, callback) {
    apex.message.confirm(message, function(okPressed) {
        if (okPressed && typeof callback === 'function') {
            callback();
        }
    });
};

// Show loading spinner
USCIS.showSpinner = function(regionId) {
    if (regionId) {
        apex.util.showSpinner($('#' + regionId));
    } else {
        apex.util.showSpinner($('body'));
    }
};

console.log('USCIS Case Tracker utilities loaded');
```

### 2.3: Create Application Items

**Navigate:** Shared Components → Application Items → Create

Create each item:

| Name | Scope | Session State Protection | Data Type |
| ---- | ----- | ------------------------ | --------- |
| G_USER_ID | Application | Checksum Required | VARCHAR2 |
| G_USER_NAME | Application | Checksum Required | VARCHAR2 |
| G_USER_ROLE | Application | Checksum Required | VARCHAR2 |
| G_USER_EMAIL | Application | Unrestricted | VARCHAR2 |

### 2.4: Create Application Process (Set User Context)

**Navigate:** Shared Components → Application Processes → Create

| Property | Value |
| -------- | ----- |
| Name | Set User Context |
| Sequence | 10 |
| Process Point | After Authentication |
| Type | PL/SQL Code |

**PL/SQL Code:**

```sql
BEGIN
    :G_USER_ID := V('APP_USER');
    :G_USER_NAME := V('APP_USER');
    
    -- Determine user role (customize based on your user table)
    -- Option 1: Check APEX access control
    IF APEX_ACL.HAS_USER_ROLE(
        p_application_id => :APP_ID,
        p_user_name      => :APP_USER,
        p_role_static_id => 'ADMINISTRATOR'
    ) THEN
        :G_USER_ROLE := 'ADMIN';
    ELSIF APEX_ACL.HAS_USER_ROLE(
        p_application_id => :APP_ID,
        p_user_name      => :APP_USER,
        p_role_static_id => 'CONTRIBUTOR'
    ) THEN
        :G_USER_ROLE := 'POWER_USER';
    ELSE
        :G_USER_ROLE := 'USER';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        :G_USER_ROLE := 'USER';
END;
```

### Task 1.4.2 Verification

- [ ] CSS variables and status colors defined
- [ ] JavaScript utilities (USCIS object) loaded
- [ ] 4 Application items created (G_USER_*)
- [ ] Application process sets user context after login

---

## Task 1.4.3: Create Navigation Menu

### Navigate To

Shared Components → Navigation → Navigation Menu → Desktop Navigation Menu

### Step 1: Edit/Clear Existing Entries

1. Click on **Desktop Navigation Menu** (or your main nav list)
2. Delete any auto-generated entries

### Step 2: Create Menu Entries

Click **Create Entry** for each item below:

| Seq | Label | Icon | Target Page | Condition |
| --- | ----- | ---- | ----------- | --------- |
| 10 | Dashboard | fa-home | 1 | — |
| 20 | My Cases | fa-folder-open | 2 | — |
| 30 | Check Status | fa-search | 5 | — |
| 40 | Import/Export | fa-exchange-alt | 6 | — |
| 50 | Settings | fa-cog | 7 | — |
| 60 | Administration | fa-shield-alt | 8 | Admin Only |

### Entry Details (Copy/Paste for Each)

#### 1. Dashboard

| Property | Value |
| -------- | ----- |
| Sequence | 10 |
| Image/Class | fa-home |
| List Entry Label | Dashboard |
| Target Type | Page in this Application |
| Page | 1 |
| Condition Type | (none) |

#### 2. My Cases

| Property | Value |
| -------- | ----- |
| Sequence | 20 |
| Image/Class | fa-folder-open |
| List Entry Label | My Cases |
| Target Type | Page in this Application |
| Page | 2 |
| Condition Type | (none) |

#### 3. Check Status

| Property | Value |
| -------- | ----- |
| Sequence | 30 |
| Image/Class | fa-search |
| List Entry Label | Check Status |
| Target Type | Page in this Application |
| Page | 5 |
| Condition Type | (none) |

#### 4. Import/Export

| Property | Value |
| -------- | ----- |
| Sequence | 40 |
| Image/Class | fa-exchange-alt |
| List Entry Label | Import/Export |
| Target Type | Page in this Application |
| Page | 6 |
| Condition Type | (none) |

#### 5. Settings

| Property | Value |
| -------- | ----- |
| Sequence | 50 |
| Image/Class | fa-cog |
| List Entry Label | Settings |
| Target Type | Page in this Application |
| Page | 7 |
| Condition Type | (none) |

#### 6. Administration (Admin Only)

| Property | Value |
| -------- | ----- |
| Sequence | 60 |
| Image/Class | fa-shield-alt |
| List Entry Label | Administration |
| Target Type | Page in this Application |
| Page | 8 |
| Condition Type | Value of Item = Value |
| Condition Item | G_USER_ROLE |
| Condition Value | ADMIN |

### Menu Preview

```text
📊 Dashboard        → Page 1
📁 My Cases         → Page 2
🔍 Check Status     → Page 5
🔄 Import/Export    → Page 6
⚙️ Settings         → Page 7
🛡️ Administration   → Page 8 (Admin only)
```

### Alternative Icons (Font APEX)

If the icons don't work, try these alternatives:

| Menu Item | Primary | Alt Icon 1 | Alt Icon 2 |
| --------- | ------- | ---------- | ---------- |
| Dashboard | fa-home | fa-tachometer-alt | fa-chart-line |
| My Cases | fa-folder-open | fa-list | fa-briefcase |
| Check Status | fa-search | fa-sync | fa-binoculars |
| Import/Export | fa-exchange-alt | fa-file-import | fa-arrows-alt-h |
| Settings | fa-cog | fa-sliders-h | fa-wrench |
| Administration | fa-shield-alt | fa-user-shield | fa-lock |

### Task 1.4.3 Verification

- [ ] 6 menu entries created
- [ ] Run your app
- [ ] Check side navigation shows all 6 items
- [ ] Click each to verify page navigation
- [ ] Test Administration visibility (should only show for admin users)

---

## Task 1.4.4: Configure Authentication

### Navigate To

Shared Components → Authentication Schemes

### Default Setup (Development)

Use the default **Application Express Accounts** scheme for development.

### Custom Authentication (Production)

Create a new scheme for production:

| Property | Value |
| -------- | ----- |
| Name | Custom USCIS Auth |
| Scheme Type | Custom |
| Authentication Function Name | custom_auth |

**Authentication Function Body:**

```sql
FUNCTION custom_auth (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    l_valid BOOLEAN := FALSE;
BEGIN
    -- Option 1: Use APEX accounts
    l_valid := APEX_UTIL.IS_LOGIN_PASSWORD_VALID(
        p_username => p_username,
        p_password => p_password
    );
    
    -- Option 2: Custom user table (uncomment to use)
    -- SELECT COUNT(*) INTO l_count
    -- FROM app_users
    -- WHERE username = UPPER(p_username)
    --   AND password_hash = your_hash_function(p_password)
    --   AND is_active = 1;
    -- l_valid := (l_count > 0);
    
    RETURN l_valid;
END custom_auth;
```

**Post-Authentication Procedure Name:** (leave blank or create)

```sql
-- This runs after successful login
apex_util.set_session_state('G_USER_NAME', :APP_USER);
```

### Task 1.4.4 Verification

- [ ] Login page works
- [ ] Session created on login
- [ ] Logout works
- [ ] Invalid credentials show error

---

## Task 1.4.5: Create Authorization Schemes

### Navigate To

Shared Components → Security → Authorization Schemes

### Create Each Authorization Scheme

Click **Create** for each one:

#### 1. IS_AUTHENTICATED

| Field | Value |
| ----- | ----- |
| Name | IS_AUTHENTICATED |
| Scheme Type | PL/SQL Function Returning Boolean |
| PL/SQL Function Body | (see below) |
| Identify error message | You must be logged in to access this page. |
| Caching | Once per session |

**PL/SQL Function Body:**

```sql
RETURN APEX_AUTHENTICATION.IS_AUTHENTICATED;
```

Click **Create Authorization Scheme**

#### 2. IS_ADMIN

| Field | Value |
| ----- | ----- |
| Name | IS_ADMIN |
| Scheme Type | PL/SQL Function Returning Boolean |
| PL/SQL Function Body | (see below) |
| Identify error message | Administrator privileges required. |
| Caching | Once per session |

**PL/SQL Function Body:**

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') = 'ADMIN';
```

Click **Create Authorization Scheme**

#### 3. IS_POWER_USER

| Field | Value |
| ----- | ----- |
| Name | IS_POWER_USER |
| Scheme Type | PL/SQL Function Returning Boolean |
| PL/SQL Function Body | (see below) |
| Identify error message | Power User or Administrator privileges required. |
| Caching | Once per session |

**PL/SQL Function Body:**

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') IN ('ADMIN', 'POWER_USER');
```

Click **Create Authorization Scheme**

#### 4. CAN_EDIT_CASES

| Field | Value |
| ----- | ----- |
| Name | CAN_EDIT_CASES |
| Scheme Type | PL/SQL Function Returning Boolean |
| PL/SQL Function Body | (see below) |
| Identify error message | You do not have permission to edit cases. |
| Caching | Once per session |

**PL/SQL Function Body:**

```sql
-- All authenticated users can edit cases
-- Modify this if you need more restrictive permissions
RETURN APEX_AUTHENTICATION.IS_AUTHENTICATED;
```

Click **Create Authorization Scheme**

### Authorization Summary Table

After creation, you should see:

| Name | Error Message | Caching |
| ---- | ------------- | ------- |
| IS_AUTHENTICATED | You must be logged in... | Once per session |
| IS_ADMIN | Administrator privileges... | Once per session |
| IS_POWER_USER | Power User or Admin... | Once per session |
| CAN_EDIT_CASES | You do not have permission... | Once per session |

### Apply Authorization Schemes to Pages

| Page | Page Name | Authorization Scheme |
| ---- | --------- | -------------------- |
| 1 | Dashboard | IS_AUTHENTICATED |
| 2 | My Cases | IS_AUTHENTICATED |
| 3 | Case Details | IS_AUTHENTICATED |
| 4 | Add Case | CAN_EDIT_CASES |
| 5 | Check Status | IS_AUTHENTICATED |
| 6 | Import/Export | IS_POWER_USER |
| 7 | Settings | IS_AUTHENTICATED |
| 8 | Administration | IS_ADMIN |
| 101 | Login | (none - public) |

**To Apply to a Page:**

1. Open the page in Page Designer
2. Click on Page properties (root node in left panel)
3. Find Security → Authorization Scheme
4. Select the appropriate scheme
5. Save

### Apply to Buttons/Regions (Examples)

| Component | Authorization Scheme |
| --------- | -------------------- |
| Delete Case button | CAN_EDIT_CASES |
| Bulk Refresh button | IS_POWER_USER |
| Audit Logs region | IS_ADMIN |
| Scheduler Settings | IS_ADMIN |

**To Apply to a Button/Region:**

1. Select the component in Page Designer
2. Find Security → Authorization Scheme
3. Select the appropriate scheme
4. Save

### Testing Authorization

**Login as DEMO user (role = USER):**

- Should see: Dashboard, Cases, Check Status, Settings
- Should NOT see: Administration, Import/Export

**Login as ADMIN user (role = ADMIN):**

- Should see: All pages including Administration

**Not logged in:**

- Should redirect to Login page

### Task 1.4.5 Verification

- [ ] All 4 authorization schemes created
- [ ] Page 8 (Admin) requires IS_ADMIN
- [ ] Page 6 (Import/Export) requires IS_POWER_USER
- [ ] Other pages require IS_AUTHENTICATED
- [ ] Navigation menu hides Admin for non-admin users
- [ ] Unauthorized access shows proper error message

---

## Task 1.4.6: Configure Application Settings

### 6.1: Application Definition

**Navigate To:** Shared Components → Application Definition → Edit Application Properties

#### Name Tab

| Field | Value |
| ----- | ----- |
| Name | USCIS Case Tracker |
| Application Alias | USCIS_TRACKER |
| Version | 1.0.0 |
| Application Group | (leave default or create one) |

### 6.2: Logo Configuration

**Navigate To:** Shared Components → User Interface Attributes → Desktop

Or: Application Definition → Logo

| Field | Value |
| ----- | ----- |
| Logo Type | Text |
| Logo | USCIS Case Tracker |

**Alternative - Image Logo:**

| Field | Value |
| ----- | ----- |
| Logo Type | Image |
| Logo Image | Upload logo or use `#APP_FILES#img/logo.png` |
| Logo Link | `f?p=&APP_ID.:1:&SESSION.` |

### 6.3: Substitution Strings

**Navigate To:** Shared Components → Application Definition → Substitution Strings

Click **Create** for each:

| Substitution String | Value |
| ------------------- | ----- |
| APP_VERSION | 1.0.0 |
| APP_ENV | DEVELOPMENT |
| USCIS_API_URL | `https://api-int.uscis.gov` |
| SUPPORT_EMAIL | `support@example.com` |
| COPYRIGHT_YEAR | 2026 |
| APP_TITLE | USCIS Case Tracker |

**Usage in pages/regions:**

```html
Version: &APP_VERSION.
Environment: &APP_ENV.
&copy; &COPYRIGHT_YEAR. &APP_TITLE.
```

### 6.4: Security Settings

**Navigate To:** Shared Components → Security Attributes

#### Session Management

| Setting | Value |
| ------- | ----- |
| Maximum Session Idle Time (seconds) | 1800 (30 min) |
| Maximum Session Length (seconds) | 28800 (8 hours) |
| Session Timeout URL | `f?p=&APP_ID.:101:&SESSION.` |

#### Session State Protection

| Setting | Value |
| ------- | ----- |
| Session State Protection | Enabled |

#### Browser Security

| Setting | Value |
| ------- | ----- |
| Browser Cache | Disabled |
| Embed in Frames | Deny |
| HTTP Response Headers | (see below) |

**HTTP Response Headers:**

```text
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
```

#### Authorization

| Setting | Value |
| ------- | ----- |
| Authorization Scheme | IS_AUTHENTICATED |
| Deep Linking | Enabled |
| Rejoin Sessions | Enabled |

#### Database Session

| Setting | Value |
| ------- | ----- |
| Parsing Schema | USCIS_APP |

### 6.5: Globalization Settings

**Navigate To:** Shared Components → Globalization Attributes

| Setting | Value |
| ------- | ----- |
| Application Primary Language | English (en) |
| Application Language Derived From | Application Primary Language |
| Application Date Format | DD-MON-YYYY |
| Application Date Time Format | DD-MON-YYYY HH24:MI |
| Application Timestamp Format | DD-MON-YYYY HH24:MI:SS |

### 6.6: Build Options (Optional)

**Navigate To:** Shared Components → Build Options

Create build options to enable/disable features:

| Build Option | Status | Purpose |
| ------------ | ------ | ------- |
| DEV_ONLY | Include | Development features |
| SHOW_DEBUG | Include | Debug regions |
| ENABLE_SCHEDULER | Include | Auto-check scheduler |

### 6.7: Application Comments

**Navigate To:** Shared Components → Application Definition → Edit Application Properties → Comments

```text
USCIS Case Tracker v1.0.0
========================
Oracle APEX application for tracking USCIS immigration case statuses.

Features:
- Track multiple cases
- Check live status from USCIS API
- Import/export case data
- Status history timeline
- Automated status checking

Author: Migration Team
Created: February 2026
```

### Quick Reference - Where Things Are

| Setting | Location |
| ------- | -------- |
| App Name/Alias | Application Definition → Name |
| Version | Application Definition → Name |
| Logo | User Interface Attributes → Desktop |
| Substitution Strings | Application Definition → Substitution Strings |
| Security | Security Attributes |
| Session Timeout | Security Attributes → Session Management |
| Date Formats | Globalization Attributes |
| Build Options | Build Options |

### Task 1.4.6 Verification

- [ ] Application name shows as "USCIS Case Tracker"
- [ ] Version set to 1.0.0
- [ ] Logo displays in header
- [ ] Substitution strings work (test: `&APP_VERSION.`)
- [ ] Session timeout configured (30 min idle)
- [ ] Security headers enabled
- [ ] Date format shows correctly (DD-MON-YYYY)

---

## Task 1.4.7: Create Placeholder Pages

### Navigate to Page Creation

App Builder → Application 100 → Create Page

### Page Summary

| Page | Name | Mode | Template | Authorization |
| ---- | ---- | ---- | -------- | ------------- |
| 0 | Global Page | Global | — | — |
| 1 | Dashboard | Normal | Left Side Column | IS_AUTHENTICATED |
| 2 | My Cases | Normal | Left Side Column | IS_AUTHENTICATED |
| 3 | Case Details | Normal | Left Side Column | IS_AUTHENTICATED |
| 4 | Add Case | Modal Dialog | Modal | CAN_EDIT_CASES |
| 5 | Check Status | Modal Dialog | Modal | IS_AUTHENTICATED |
| 6 | Import Export | Normal | Left Side Column | IS_POWER_USER |
| 7 | Settings | Normal | Left Side Column | IS_AUTHENTICATED |
| 8 | Administration | Normal | Left Side Column | IS_ADMIN |
| 101 | Login | Normal | Login | (none - public) |

### Create Each Page

#### Page 1: Dashboard (Home)

| Step | Action |
| ---- | ------ |
| 1 | Click **Create Page** |
| 2 | Select **Blank Page** |
| 3 | Page Number: **1** |
| 4 | Name: **Dashboard** |
| 5 | Page Mode: **Normal** |
| 6 | Click **Next** |
| 7 | Navigation: ✅ Use Breadcrumb |
| 8 | Parent Entry: **- No Parent Selected -** |
| 9 | Entry Name: **Dashboard** |
| 10 | Click **Create Page** |

**After creation, set properties:**

- Page → Security → Authorization Scheme: **IS_AUTHENTICATED**
- Page → Appearance → Page Template: **Left Side Column**

#### Page 2: My Cases (Case List)

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **2** |
| 3 | Name: **My Cases** |
| 4 | Page Mode: **Normal** |
| 5 | Breadcrumb Entry: **My Cases** |
| 6 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_AUTHENTICATED**
- Page Template: **Left Side Column**

#### Page 3: Case Details

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **3** |
| 3 | Name: **Case Details** |
| 4 | Page Mode: **Normal** |
| 5 | Breadcrumb Entry: **Case Details** |
| 6 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_AUTHENTICATED**
- Page Template: **Left Side Column**

#### Page 4: Add Case (Modal Dialog)

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **4** |
| 3 | Name: **Add Case** |
| 4 | Page Mode: **Modal Dialog** ⬅️ Important! |
| 5 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **CAN_EDIT_CASES**
- Dialog Template: **Drawer** (or Modal Dialog)

#### Page 5: Check Status (Modal Dialog)

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **5** |
| 3 | Name: **Check Status** |
| 4 | Page Mode: **Modal Dialog** |
| 5 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_AUTHENTICATED**

#### Page 6: Import/Export

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **6** |
| 3 | Name: **Import Export** |
| 4 | Page Mode: **Normal** |
| 5 | Breadcrumb Entry: **Import/Export** |
| 6 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_POWER_USER**
- Page Template: **Left Side Column**

#### Page 7: Settings

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **7** |
| 3 | Name: **Settings** |
| 4 | Page Mode: **Normal** |
| 5 | Breadcrumb Entry: **Settings** |
| 6 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_AUTHENTICATED**
- Page Template: **Left Side Column**

#### Page 8: Administration

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Blank Page** |
| 2 | Page Number: **8** |
| 3 | Name: **Administration** |
| 4 | Page Mode: **Normal** |
| 5 | Breadcrumb Entry: **Administration** |
| 6 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **IS_ADMIN**
- Page Template: **Left Side Column**

#### Page 101: Login

| Step | Action |
| ---- | ------ |
| 1 | Create Page → **Login Page** ⬅️ Use Login template! |
| 2 | Page Number: **101** |
| 3 | Name: **Login** |
| 4 | Click **Create Page** |

**Properties:**

- Authorization Scheme: **(none)** - public access
- This page auto-configures with APEX authentication

### Set Application Home Page

After creating Page 1:

1. Go to Shared Components → Application Definition
2. Set Home URL: `f?p=&APP_ID.:1:&SESSION.`

### Verify All Pages

Once complete, you should see in App Builder → Pages:

```text
Page 0   - Global Page (Page Zero)
Page 1   - Dashboard
Page 2   - My Cases
Page 3   - Case Details
Page 4   - Add Case
Page 5   - Check Status
Page 6   - Import Export
Page 7   - Settings
Page 8   - Administration
Page 101 - Login
```

### Task 1.4.7 Verification

- [ ] Pages 1-8 and 101 exist
- [ ] Modal pages (4, 5) open as dialogs
- [ ] Breadcrumbs work
- [ ] Authorization applied to each page
- [ ] Home page set to Page 1

---

## Final Verification Checklist

### Task 1.4.1: Application

- [ ] App ID is 100
- [ ] Theme is Universal Theme (42) - Vita Slate
- [ ] Navigation is Side Column

### Task 1.4.2: Global Page

- [ ] CSS variables and status colors defined
- [ ] JavaScript utilities (USCIS object) loaded
- [ ] Application items created (G_USER_*)
- [ ] Application process sets user context

### Task 1.4.3: Navigation Menu

- [ ] 6 menu entries created
- [ ] Icons display correctly
- [ ] Administration hidden for non-admins
- [ ] All links navigate correctly

### Task 1.4.4: Authentication

- [ ] Login page works
- [ ] Session created on login
- [ ] Logout works

### Task 1.4.5: Authorization

- [ ] 4 schemes created
- [ ] Page 8 requires IS_ADMIN
- [ ] Page 6 requires IS_POWER_USER
- [ ] Error messages display correctly

### Task 1.4.6: Application Settings

- [ ] Version shows as 1.0.0
- [ ] Substitution strings work (test: `&APP_VERSION.`)
- [ ] Logo displays in header
- [ ] Session timeout configured
- [ ] Security headers enabled

### Task 1.4.7: Pages

- [ ] Pages 1-8 and 101 exist
- [ ] Modal pages (4, 5) open as dialogs
- [ ] Breadcrumbs work
- [ ] Authorization applied to each page

---

## Test Scenarios

### Test 1: Normal User Access

1. Login as a regular user
2. Verify Dashboard, My Cases, Check Status, Settings visible
3. Verify Import/Export and Administration NOT visible
4. Try to access Page 8 directly - should see error

### Test 2: Admin User Access

1. Login as admin user (G_USER_ROLE = 'ADMIN')
2. Verify ALL menu items visible
3. Verify can access Page 8

### Test 3: Session Timeout

1. Login and wait 31 minutes idle
2. Try to navigate - should redirect to login

### Test 4: Modal Pages

1. From Page 2, click to open Add Case (Page 4)
2. Verify opens as modal dialog
3. Close modal and verify return to Page 2

---

## Troubleshooting

### Schema Not Visible

```sql
-- Check current schema mapping
SELECT workspace_name, schema 
FROM apex_workspace_schemas;

-- Add your schema
BEGIN
    APEX_INSTANCE_ADMIN.ADD_SCHEMA(
        p_workspace => 'USCISAPP',
        p_schema    => 'USCIS_APP'
    );
END;
/
```

### View Does Not Exist (ORA-00942)

```sql
-- Verify view exists in correct schema
SELECT owner, view_name 
FROM all_views 
WHERE view_name = 'V_CASE_CURRENT_STATUS';

-- If missing, run install script
@install_all_v2.sql
```

### Authorization Scheme Errors

- Check G_USER_ROLE is set correctly
- Verify application process runs after authentication
- Check caching is set to "Once per session"

### Navigation Not Showing

- Verify condition items exist (G_USER_ROLE)
- Check condition syntax (`ADMIN` not `'ADMIN'`)
- Clear cache and re-login

---

## Next Steps (Development Roadmap)

After completing the shell setup, build in this order to minimize rework:

1. **Foundation UI (Pages 1–2):**
    - Dashboard cards and charts
    - Interactive Grid for My Cases
2. **Core Workflows (Pages 3–5):**
    - Case Details timeline
    - Add Case modal
    - Check Status modal
3. **Operations (Pages 6–8):**
    - Import/Export utilities
    - Settings
    - Administration (audit, scheduler)
4. **Hardening:**
    - Security review (roles, session, headers)
    - Performance checks (IG query tuning, indexes)
    - UAT checklist

### Optional (Oracle APEX 26 AI)
If you enable AI features, document it separately in your workspace for compliance:
- Which pages use AI components
- Prompt sources and guardrails
- Audit/logging requirements

---

## File-Based Development Workflow

For faster development and proper Git version control, use SQLcl to export your APEX app to SQL files, edit locally, and import back.

### Quick Setup

```bash
# 1. Install SQLcl (if not already installed)
brew install --cask sqlcl

# 2. Navigate to the database directory
cd apex/static/database

# 3. Copy and configure environment
cp apex.env apex.env.local
# Edit apex.env.local with your credentials

# 4. Make scripts executable (already done)
chmod +x scripts/*.sh
```

### Daily Workflow

```bash
# Export your app to files
./scripts/apex-export.sh 100

# This creates f100/ with:
#   f100/application/pages/page_00001.sql
#   f100/application/pages/page_00002.sql
#   f100/shared_components/...
#   f100/install.sql

# Edit files in VS Code
code f100/

# Import changes back to APEX
./scripts/apex-import.sh 100

# Watch mode: auto-import on file save
./scripts/apex-watch.sh 100
```

### Available Scripts

| Script | Purpose |
| ------ | ------- |
| `scripts/apex-export.sh` | Export APEX app to SQL files |
| `scripts/apex-import.sh` | Import SQL files to APEX |
| `scripts/apex-watch.sh` | Watch files and auto-import on change |
| `scripts/connect.sh` | Open interactive SQLcl session |
| `scripts/deploy.sh` | Full deployment (DB + packages + APEX) |

### Git Workflow

```bash
# After making changes in APEX or locally
./scripts/apex-export.sh 100
git add f100/
git commit -m "feat(apex): Add status chart to dashboard"
git push

# After pulling team changes
git pull
./scripts/apex-import.sh 100
```

### Environment Configuration

Edit `apex.env.local` with your credentials:

```bash
export DB_USER="uscis_app"
export DB_PASSWORD="your_password_here"
export DB_CONNECTION="uscis_tracker_high"  # TNS alias
export TNS_ADMIN="/path/to/wallet"         # For Autonomous DB
export APEX_APP_ID="100"
```

See [apex.env](apex.env) for all configuration options.

---

**Document Version:** 1.2.0  
**Last Updated:** February 2026  
**Author:** Migration Team
