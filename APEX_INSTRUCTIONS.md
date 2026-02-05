# USCIS Case Tracker: Complete Oracle APEX Instructions

**Version:** 1.0.0  
**Last Updated:** February 4, 2026  
**APEX Version:** Oracle APEX 26 AI  
**Application ID:** 102

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Prerequisites](#2-prerequisites)
3. [Environment Setup](#3-environment-setup)
4. [Application Setup](#4-application-setup)
5. [Page Development](#5-page-development)
6. [Security Configuration](#6-security-configuration)
7. [Development Workflow](#7-development-workflow)
8. [Deployment](#8-deployment)
9. [Troubleshooting](#9-troubleshooting)
10. [Reference](#10-reference)

---

## 1. Quick Start

### For New Developers

```bash
# 1. Clone the repository
git clone https://github.com/zlovtnik/uscis-case-tracker-2.git
cd uscis-case-tracker-2/apex/static/database

# 2. Configure your environment
cp apex.env.local.template apex.env.local
# Edit apex.env.local with your credentials

# 3. Connect to database and run installation
./scripts/connect.sh
# In SQLcl:
SQL> @install_all_v2.sql

# 4. Import the APEX application
./scripts/apex-import.sh 102

# 5. Open APEX and run the application
# Navigate to: https://your-apex-instance/ords/f?p=102
```

### Recommended Setup Order

| Step | Task | Time | Section |
|------|------|------|---------|
| 1 | Provision database & create schema | 15 min | [Prerequisites](#2-prerequisites) |
| 2 | Configure environment | 10 min | [Environment Setup](#3-environment-setup) |
| 3 | Install database objects | 5 min | [Environment Setup](#3-environment-setup) |
| 4 | Create APEX workspace & app | 15 min | [Application Setup](#4-application-setup) |
| 5 | Configure Global Page | 20 min | [Application Setup](#4-application-setup) |
| 6 | Create authorization schemes | 15 min | [Security Configuration](#6-security-configuration) |
| 7 | Build navigation menu | 10 min | [Application Setup](#4-application-setup) |
| 8 | Create placeholder pages | 30 min | [Page Development](#5-page-development) |
| 9 | Configure authentication | 15 min | [Security Configuration](#6-security-configuration) |

---

## 2. Prerequisites

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| Oracle Database | 19c+ or ATP | Data storage |
| Oracle APEX | 23.2+ (26 AI recommended) | Application platform |
| SQLcl | 23.x+ | Database scripting |
| Git | 2.x+ | Version control |

### Optional Software

| Software | Purpose |
|----------|---------|
| VS Code + Oracle Extension | Local development |
| SQL Developer | Database management |
| Docker | Local Oracle XE for testing |

### Database Requirements

Before APEX setup, ensure:

- [ ] Oracle Database is provisioned
- [ ] Schema user `USCIS_APP` created with appropriate privileges
- [ ] Network ACL configured for USCIS API access (port 443)
- [ ] Oracle Wallet configured for HTTPS (if using ATP)
- [ ] Database objects installed via `install_all_v2.sql`

### Create Schema User (DBA Required)

```sql
-- Connect as SYS or DBA
sqlplus sys@your_database as sysdba

-- Create application user
CREATE USER uscis_app IDENTIFIED BY "YourSecurePassword123!"
    DEFAULT TABLESPACE data
    QUOTA UNLIMITED ON data;

-- Grant privileges
GRANT CREATE SESSION TO uscis_app;
GRANT CREATE TABLE TO uscis_app;
GRANT CREATE VIEW TO uscis_app;
GRANT CREATE PROCEDURE TO uscis_app;
GRANT CREATE SEQUENCE TO uscis_app;
GRANT CREATE TRIGGER TO uscis_app;
GRANT CREATE TYPE TO uscis_app;
GRANT CREATE JOB TO uscis_app;
GRANT EXECUTE ON DBMS_CRYPTO TO uscis_app;

-- Configure network ACL for USCIS API
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'api-int.uscis.gov',
        lower_port => 443,
        upper_port => 443,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'USCIS_APP',
            principal_type => xs_acl.ptype_db
        )
    );
END;
/
```

---

## 3. Environment Setup

### 3.1 Configure Local Environment

```bash
# Navigate to database directory
cd apex/static/database

# Copy template to local config
cp apex.env.local.template apex.env.local

# Edit with your credentials
nano apex.env.local  # or use your preferred editor
```

**Required environment variables:**

```bash
# Database Connection
export DB_CONNECTION_NAME="USCIS_APP"
export DB_USER="uscis_app"
export DB_PASSWORD="your_secure_password"
export DB_CONNECTION="uscis_tracker_high"  # TNS alias

# For Autonomous Database only
export TNS_ADMIN="/path/to/your/wallet"

# APEX Settings
export APEX_WORKSPACE="USCISAPP"
export APEX_APP_ID="102"
```

### 3.2 Install Database Objects

```bash
# Connect to database
./scripts/connect.sh

# Run master installation script
SQL> @install_all_v2.sql
```

The installation creates:
- 6 tables (case_history, status_updates, oauth_tokens, etc.)
- 8 views (v_case_current_status, v_case_dashboard, etc.)
- 8 PL/SQL packages (uscis_types_pkg, uscis_case_pkg, etc.)
- Required indexes and seed data

### 3.3 Verify Installation

```sql
-- Check tables
SELECT table_name FROM user_tables ORDER BY table_name;

-- Expected: 6 tables
-- API_RATE_LIMITER, CASE_AUDIT_LOG, CASE_HISTORY, 
-- OAUTH_TOKENS, SCHEDULER_CONFIG, STATUS_UPDATES

-- Check views
SELECT view_name FROM user_views ORDER BY view_name;

-- Expected: 8+ views
-- V_CASE_CURRENT_STATUS, V_CASE_DASHBOARD, V_RECENT_ACTIVITY, etc.

-- Check packages
SELECT object_name FROM user_objects 
WHERE object_type = 'PACKAGE' ORDER BY object_name;

-- Expected: 8 packages
-- USCIS_API_PKG, USCIS_AUDIT_PKG, USCIS_CASE_PKG, etc.

-- Check configuration
SELECT config_key, config_value FROM scheduler_config;
```

---

## 4. Application Setup

### 4.1 Create APEX Workspace

**Navigate to:** APEX Administration → Manage Workspaces → Create Workspace

| Setting | Value |
|---------|-------|
| Workspace Name | `USCISAPP` |
| Workspace ID | (auto-generated) |
| Schema | `USCIS_APP` |
| Space Quota | 100 MB |
| Administrator | Your email |

**If schema mapping issues occur:**

```sql
-- Run as APEX admin
BEGIN
    APEX_INSTANCE_ADMIN.ADD_SCHEMA(
        p_workspace => 'USCISAPP',
        p_schema    => 'USCIS_APP'
    );
    COMMIT;
END;
/
```

### 4.2 Create Application

**Navigate to:** App Builder → Create → New Application

| Setting | Value |
|---------|-------|
| Name | `USCIS Case Tracker` |
| Application ID | `102` |
| Application Alias | `USCIS_TRACKER` |
| Schema | `USCIS_APP` |
| Theme | Universal Theme (42) |
| Theme Style | Vita - Slate |
| Navigation | Side Column |
| Features | ✅ Access Control, ✅ Activity Reporting |
| Authentication | Application Express Accounts |

### 4.3 Configure Application Definition

**Navigate to:** Shared Components → Application Definition → Properties

#### Name Tab

| Setting | Value |
|---------|-------|
| Application Name | `USCIS Case Tracker` |
| Application Alias | `USCIS_TRACKER` |
| Version | `1.0.0` |

#### Appearance Tab

| Setting | Value |
|---------|-------|
| Logo Type | Text |
| Logo | `USCIS Case Tracker` |

#### Substitution Strings

**Navigate to:** Shared Components → Application Definition → Substitution Strings

| Substitution String | Value |
|--------------------|-------|
| `APP_VERSION` | `1.0.0` |
| `APP_ENV` | `DEVELOPMENT` |
| `USCIS_API_URL` | `https://api-int.uscis.gov` |
| `SUPPORT_EMAIL` | `support@example.com` |
| `COPYRIGHT_YEAR` | `2026` |

### 4.4 Configure Global Page (Page 0)

**Navigate to:** Page Designer → Page 0 (Global Page)

#### Add Custom CSS

**Location:** Page 0 → Page Properties → CSS → Inline

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

/* Receipt Number Styling */
.receipt-number {
    font-family: 'Courier New', monospace;
    font-weight: 600;
    letter-spacing: 1px;
}

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

/* Status Row Highlighting */
.status-approved { background-color: rgba(46, 133, 64, 0.15) !important; }
.status-denied { background-color: rgba(205, 32, 38, 0.15) !important; }
.status-pending { background-color: rgba(253, 184, 30, 0.15) !important; }
.status-rfe { background-color: rgba(0, 113, 188, 0.15) !important; }
.status-received { background-color: rgba(76, 44, 146, 0.15) !important; }

/* Card Hover Effect */
.case-card {
    transition: transform 0.2s, box-shadow 0.2s;
}
.case-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

/* Days Warning */
.days-old-warning { color: #d93900; font-weight: bold; }

/* Mobile Responsive */
@media (max-width: 768px) {
    .a-CardView-items { grid-template-columns: 1fr !important; }
    .receipt-number { font-size: 14px; }
}
```

#### Add Global JavaScript

**Location:** Page 0 → Page Properties → JavaScript → Function and Global Variable Declaration

```javascript
/* USCIS Case Tracker - Global JavaScript Utilities */
var USCIS = USCIS || {};

// Format receipt number with visual grouping
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
    if (status.includes('APPROVED')) return 'approved';
    if (status.includes('DENIED') || status.includes('REJECTED')) return 'denied';
    if (status.includes('EVIDENCE') || status.includes('RFE')) return 'rfe';
    if (status.includes('RECEIVED') || status.includes('ACCEPTED')) return 'received';
    if (status.includes('PENDING') || status.includes('REVIEW')) return 'pending';
    return 'unknown';
};

// Copy to clipboard with fallback
USCIS.copyToClipboard = function(text) {
    if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(function() {
            apex.message.showPageSuccess('Copied: ' + text);
        });
    } else {
        var textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        apex.message.showPageSuccess('Copied: ' + text);
    }
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

// Refresh case from USCIS API
USCIS.refreshCase = function(receiptNumber) {
    if (!receiptNumber || !USCIS.validateReceipt(receiptNumber)) {
        apex.message.showErrors([{
            type: 'error',
            location: 'page',
            message: 'Invalid receipt number format'
        }]);
        return;
    }
    
    USCIS.showSpinner();
    
    apex.server.process('REFRESH_CASE_STATUS', {
        x01: USCIS.normalizeReceipt(receiptNumber)
    }, {
        dataType: 'json',
        success: function(data) {
            apex.util.delayLinger.finish('spinner');
            if (data.success) {
                apex.message.showPageSuccess('Case status refreshed');
                if (apex.region('Cases')) apex.region('Cases').refresh();
            } else {
                apex.message.showErrors([{
                    type: 'error',
                    location: 'page',
                    message: data.message || 'Failed to refresh'
                }]);
            }
        },
        error: function() {
            apex.util.delayLinger.finish('spinner');
            apex.message.showErrors([{
                type: 'error',
                location: 'page',
                message: 'An error occurred. Please try again.'
            }]);
        }
    });
};

console.log('USCIS Case Tracker utilities loaded');
```

### 4.5 Create Application Items

**Navigate to:** Shared Components → Application Items → Create

| Name | Scope | Session State Protection | Data Type |
|------|-------|-------------------------|-----------|
| `G_USER_ID` | Application | Checksum Required | VARCHAR2 |
| `G_USER_NAME` | Application | Checksum Required | VARCHAR2 |
| `G_USER_ROLE` | Application | Checksum Required | VARCHAR2 |
| `G_USER_EMAIL` | Application | Unrestricted | VARCHAR2 |

### 4.6 Create Application Process (Set User Context)

**Navigate to:** Shared Components → Application Processes → Create

| Property | Value |
|----------|-------|
| Name | `Set User Context` |
| Sequence | 10 |
| Process Point | After Authentication |
| Type | PL/SQL Code |

```sql
BEGIN
    :G_USER_ID := V('APP_USER');
    :G_USER_NAME := V('APP_USER');
    
    -- Determine user role
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

### 4.7 Create Navigation Menu

**Navigate to:** Shared Components → Navigation → Navigation Menu → Desktop Navigation Menu

Delete any auto-generated entries, then create:

| Seq | Label | Icon | Target Page | Condition |
|-----|-------|------|-------------|-----------|
| 10 | Dashboard | `fa-home` | 1 | — |
| 20 | My Cases | `fa-folder-open` | 2 | — |
| 30 | Check Status | `fa-search` | 5 | — |
| 40 | Import/Export | `fa-exchange-alt` | 6 | — |
| 50 | Settings | `fa-cog` | 7 | — |
| 60 | Administration | `fa-shield-alt` | 8 | Admin Only* |

*For Administration entry, set:
- Condition Type: `Value of Item = Value`
- Condition Item: `G_USER_ROLE`
- Condition Value: `ADMIN`

---

## 5. Page Development

### 5.1 Page Summary

| Page | Name | Mode | Template | Authorization |
|------|------|------|----------|---------------|
| 0 | Global Page | Global | — | — |
| 1 | Dashboard | Normal | Left Side Column | IS_AUTHENTICATED |
| 2 | My Cases | Normal | Left Side Column | IS_AUTHENTICATED |
| 3 | Case Details | Normal | Left Side Column | IS_AUTHENTICATED |
| 4 | Add Case | Modal Dialog | Modal | CAN_EDIT_CASES |
| 5 | Check Status | Modal Dialog | Modal | IS_AUTHENTICATED |
| 6 | Import/Export | Normal | Left Side Column | IS_POWER_USER |
| 7 | Settings | Normal | Left Side Column | IS_AUTHENTICATED |
| 8 | Administration | Normal | Left Side Column | IS_ADMIN |
| 101 | Login | Normal | Login | (public) |

### 5.2 Create Placeholder Pages

#### Creating Each Page

**Navigate to:** App Builder → Create Page → Blank Page

For each page, set:

| Step | Action |
|------|--------|
| 1 | Page Number: (as shown above) |
| 2 | Name: (as shown above) |
| 3 | Page Mode: Normal or Modal Dialog |
| 4 | Breadcrumb Entry: Yes (except modals) |
| 5 | Click Create Page |

After creation:
- Set Authorization Scheme in Page Properties → Security
- Set Page Template to "Left Side Column"

#### Page 1: Dashboard

**Placeholder HTML for static content region:**
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

#### Page 2: Case List (Interactive Grid)

**SQL Source for Interactive Grid:**
```sql
SELECT 
    receipt_number,
    case_type,
    current_status,
    last_updated,
    tracking_since,
    is_active,
    total_updates,
    notes,
    last_checked_at
FROM v_case_current_status
WHERE 1=1
ORDER BY last_updated DESC NULLS LAST
```

**Column Configuration:**

| Column | Type | Width | Features |
|--------|------|-------|----------|
| RECEIPT_NUMBER | Link | 150px | Link to Page 3, Frozen |
| CASE_TYPE | Plain Text | 200px | — |
| CURRENT_STATUS | Plain Text | 200px | Status badge styling |
| LAST_UPDATED | Plain Text | 120px | Format: SINCE |
| IS_ACTIVE | Switch | 80px | Inline edit |
| TOTAL_UPDATES | Plain Text | 80px | Center align |
| LAST_CHECKED_AT | Plain Text | 120px | Format: SINCE |

#### Page 4: Add Case (Modal)

| Item | Type | Required | Notes |
|------|------|----------|-------|
| P4_RECEIPT_NUMBER | Text | Yes | Placeholder: "e.g., IOE1234567890" |
| P4_FETCH_FROM_USCIS | Switch | No | Default: Y |
| P4_CASE_TYPE | Select List | Conditional | Show when P4_FETCH_FROM_USCIS = 'N' |
| P4_CURRENT_STATUS | Text | Conditional | Show when P4_FETCH_FROM_USCIS = 'N' |
| P4_NOTES | Textarea | No | — |

**Validation PL/SQL:**
```sql
DECLARE
    l_normalized VARCHAR2(13);
BEGIN
    l_normalized := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);
    IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN
        RETURN 'Invalid receipt number format';
    END IF;
    RETURN NULL;
END;
```

#### Page 101: Login

**Navigate to:** Create Page → Login Page

The login page is auto-configured with APEX authentication.

---

## 6. Security Configuration

### 6.1 Authorization Schemes

**Navigate to:** Shared Components → Security → Authorization Schemes

#### IS_AUTHENTICATED

| Property | Value |
|----------|-------|
| Name | `IS_AUTHENTICATED` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | You must be logged in to access this page. |
| Caching | Once per session |

```sql
RETURN APEX_AUTHENTICATION.IS_AUTHENTICATED;
```

#### IS_ADMIN

| Property | Value |
|----------|-------|
| Name | `IS_ADMIN` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | Administrator privileges required. |
| Caching | Once per session |

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') = 'ADMIN';
```

#### IS_POWER_USER

| Property | Value |
|----------|-------|
| Name | `IS_POWER_USER` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | Power User or Administrator privileges required. |
| Caching | Once per session |

```sql
RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'USER') IN ('ADMIN', 'POWER_USER');
```

#### CAN_EDIT_CASES

| Property | Value |
|----------|-------|
| Name | `CAN_EDIT_CASES` |
| Scheme Type | PL/SQL Function Returning Boolean |
| Error Message | You do not have permission to edit cases. |
| Caching | Once per session |

```sql
RETURN APEX_AUTHENTICATION.IS_AUTHENTICATED;
```

### 6.2 Apply Authorization to Pages

| Page | Authorization Scheme |
|------|---------------------|
| 1 (Dashboard) | IS_AUTHENTICATED |
| 2 (My Cases) | IS_AUTHENTICATED |
| 3 (Case Details) | IS_AUTHENTICATED |
| 4 (Add Case) | CAN_EDIT_CASES |
| 5 (Check Status) | IS_AUTHENTICATED |
| 6 (Import/Export) | IS_POWER_USER |
| 7 (Settings) | IS_AUTHENTICATED |
| 8 (Administration) | IS_ADMIN |
| 101 (Login) | (none - public) |

### 6.3 Security Attributes

**Navigate to:** Shared Components → Security Attributes

#### Session Management

| Setting | Value |
|---------|-------|
| Maximum Session Idle Time | 1800 (30 min) |
| Maximum Session Length | 28800 (8 hours) |
| Session Timeout URL | `f?p=&APP_ID.:101:&SESSION.` |

#### Session State Protection

| Setting | Value |
|---------|-------|
| Session State Protection | Enabled |

#### Browser Security

| Setting | Value |
|---------|-------|
| Browser Cache | Disabled |
| Embed in Frames | Deny |
| HTTP Response Headers | `X-Content-Type-Options: nosniff` |

### 6.4 Authentication Scheme

**Navigate to:** Shared Components → Authentication Schemes

#### Development (APEX Accounts)

Use default "Application Express Accounts" for development.

#### Production (Custom)

Create custom authentication for production:

| Property | Value |
|----------|-------|
| Name | `Custom USCIS Auth` |
| Scheme Type | Custom |

**Authentication Function:**
```sql
FUNCTION custom_auth (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
BEGIN
    RETURN APEX_UTIL.IS_LOGIN_PASSWORD_VALID(
        p_username => p_username,
        p_password => p_password
    );
END custom_auth;
```

---

## 7. Development Workflow

### 7.1 Script-Based Development

The project includes shell scripts for APEX development:

```bash
cd apex/static/database

# Export APEX app to SQL files
./scripts/apex-export.sh 102

# Import SQL files to APEX
./scripts/apex-import.sh 102

# Watch mode: auto-import on file save
./scripts/apex-watch.sh 102

# Open interactive SQLcl session
./scripts/connect.sh

# Full deployment (DB + packages + APEX)
./scripts/deploy.sh
```

### 7.2 File Structure

After export, the APEX application structure:

```
apex/static/database/
├── apex/
│   └── f102/
│       ├── install.sql
│       └── application/
│           ├── create_application.sql
│           ├── pages/
│           │   ├── page_00001.sql
│           │   ├── page_00002.sql
│           │   └── ...
│           └── shared_components/
│               ├── navigation/
│               ├── security/
│               └── user_interface/
├── packages/
│   ├── 01_uscis_types_pkg.sql
│   ├── 02_uscis_util_pkg.sql
│   └── ...
├── scripts/
│   ├── apex-export.sh
│   ├── apex-import.sh
│   └── ...
└── apex.env.local
```

### 7.3 Git Workflow

```bash
# After making changes in APEX
./scripts/apex-export.sh 102
git add apex/
git commit -m "feat(apex): Add case list interactive grid"
git push

# After pulling team changes
git pull
./scripts/apex-import.sh 102
```

### 7.4 Development Best Practices

1. **Always export before committing** - Ensures APEX changes are captured
2. **Use meaningful commit messages** - Follow conventional commits
3. **Test in development first** - Never deploy untested changes
4. **Keep SQL files synchronized** - Run export after any APEX Builder changes
5. **Use Static IDs** - Assign static IDs to regions and items for JavaScript references

---

## 8. Deployment

### 8.1 Staging Deployment

```bash
# 1. Export from development
./scripts/apex-export.sh 102

# 2. Connect to staging
export DB_CONNECTION="staging_connection"
./scripts/connect.sh

# 3. Deploy database objects
SQL> @install_all_v2.sql

# 4. Import APEX application
./scripts/apex-import.sh 102

# 5. Smoke test
# - Navigate to application URL
# - Test login
# - Test core functionality
```

### 8.2 Production Deployment

#### Pre-Deployment Checklist

- [ ] All unit tests pass
- [ ] Integration tests complete
- [ ] UAT sign-off obtained
- [ ] Rollback scripts prepared
- [ ] Backup of existing data taken
- [ ] Deployment runbook reviewed

#### Deployment Steps

```bash
# 1. Provision production ATP (if new)
# Use OCI Console or Terraform

# 2. Configure production connection
export DB_CONNECTION="production_connection"
export TNS_ADMIN="/path/to/production/wallet"

# 3. Deploy database objects
./scripts/connect.sh
SQL> @install_all_v2.sql

# 4. Import APEX application
./scripts/apex-import.sh 102

# 5. Configure production settings
# - Update substitution strings (APP_ENV = PRODUCTION)
# - Configure OAuth credentials
# - Set up scheduler jobs
# - Enable monitoring

# 6. Post-deployment verification
# - Run smoke tests
# - Verify all pages load
# - Test API integration
# - Check scheduler jobs
```

### 8.3 Rollback Procedure

```sql
-- If rollback needed:

-- 1. Drop APEX application
BEGIN
    APEX_APPLICATION_INSTALL.SET_WORKSPACE('USCISAPP');
    APEX_APPLICATION_INSTALL.REMOVE_APPLICATION(102);
END;
/

-- 2. Restore from backup
-- (use your backup/restore procedure)

-- 3. Reimport previous version
-- ./scripts/apex-import.sh 102 (from previous Git commit)
```

---

## 9. Troubleshooting

### 9.1 Common Issues

#### Schema Not Visible in APEX

```sql
-- Check current schema mapping
SELECT workspace_name, schema 
FROM apex_workspace_schemas
WHERE workspace_name = 'USCISAPP';

-- Add schema if missing
BEGIN
    APEX_INSTANCE_ADMIN.ADD_SCHEMA(
        p_workspace => 'USCISAPP',
        p_schema    => 'USCIS_APP'
    );
END;
/
```

#### View Does Not Exist (ORA-00942)

```sql
-- Verify view exists
SELECT owner, view_name 
FROM all_views 
WHERE view_name = 'V_CASE_CURRENT_STATUS';

-- If missing, reinstall
@install_all_v2.sql
```

#### Network Access Denied (ORA-24247)

```sql
-- Check ACL configuration
SELECT * FROM dba_network_acls;

-- Reconfigure if needed
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'api-int.uscis.gov',
        lower_port => 443,
        upper_port => 443,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'USCIS_APP',
            principal_type => xs_acl.ptype_db
        )
    );
END;
/
```

#### Authorization Scheme Errors

- Check `G_USER_ROLE` is being set in the application process
- Verify the process point is "After Authentication"
- Clear session cache and re-login
- Check caching setting is "Once per session"

#### Navigation Menu Not Showing

- Verify condition item (`G_USER_ROLE`) exists
- Check condition value matches exactly (case-sensitive)
- Ensure application items are populated

### 9.2 Debug Mode

Enable debug mode for troubleshooting:

1. **URL Debug:** Add `&DEBUG=YES` to URL
2. **Page Debug:** Enable in Page Designer → Page Properties
3. **Application Debug:** Shared Components → Application Definition → Debugging

### 9.3 Logs

```sql
-- Check APEX debug logs
SELECT * FROM apex_debug_messages
WHERE application_id = 102
ORDER BY message_timestamp DESC
FETCH FIRST 100 ROWS ONLY;

-- Check application error log
SELECT * FROM apex_workspace_activity_log
WHERE application_id = 102
ORDER BY view_date DESC
FETCH FIRST 50 ROWS ONLY;
```

---

## 10. Reference

### 10.1 PL/SQL Packages

| Package | Purpose |
|---------|---------|
| `uscis_types_pkg` | Type definitions and constants |
| `uscis_util_pkg` | Utility functions (validation, formatting) |
| `uscis_case_pkg` | Case CRUD operations |
| `uscis_oauth_pkg` | OAuth2 token management |
| `uscis_api_pkg` | USCIS API integration |
| `uscis_scheduler_pkg` | Job scheduling |
| `uscis_export_pkg` | Import/export operations |
| `uscis_audit_pkg` | Audit logging |

### 10.2 Database Views

| View | Purpose |
|------|---------|
| `v_case_current_status` | Cases with latest status |
| `v_case_dashboard` | Statistics by status |
| `v_recent_activity` | Last 100 audit entries |
| `v_status_history` | Full history with analytics |
| `v_cases_due_for_check` | Cases needing API check |
| `v_case_type_summary` | Statistics by form type |
| `v_token_status` | OAuth token validity |
| `v_rate_limit_status` | Rate limiter state |

### 10.3 Icon Reference (Font APEX)

| Icon | Class | Usage |
|------|-------|-------|
| Home | `fa-home` | Dashboard |
| Folder | `fa-folder-open` | Cases |
| Search | `fa-search` | Check Status |
| Exchange | `fa-exchange-alt` | Import/Export |
| Cog | `fa-cog` | Settings |
| Shield | `fa-shield-alt` | Admin |
| Plus | `fa-plus` | Add |
| Refresh | `fa-refresh` | Refresh |
| Trash | `fa-trash` | Delete |
| Check | `fa-check-circle` | Approved |
| Times | `fa-times-circle` | Denied |
| Clock | `fa-clock-o` | Pending |

### 10.4 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| USCIS Primary | `#003366` | Header, branding |
| USCIS Secondary | `#0071bc` | Links, accents |
| USCIS Accent | `#02bfe7` | Highlights |
| Approved | `#2e8540` | Success status |
| Denied | `#cd2026` | Error status |
| Pending | `#fdb81e` | Warning status |
| RFE | `#0071bc` | Info status |
| Received | `#4c2c92` | Purple status |
| Unknown | `#5b616b` | Gray status |

### 10.5 Related Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| Database Setup | `apex/static/database/README.md` | Database installation |
| Migration Roadmap | `apex/static/database/MIGRATION_ROADMAP.md` | Project timeline |
| Frontend Design | `apex/static/database/APEX_FRONTEND_DESIGN.md` | UI specifications |
| Shell Setup | `apex/static/database/APEX_SHELL_SETUP.md` | Detailed setup steps |
| Setup Guide | `apex/static/database/APEX_SETUP_GUIDE.md` | Task-based guide |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-04 | Migration Team | Initial consolidated document |

---

*End of APEX Instructions*