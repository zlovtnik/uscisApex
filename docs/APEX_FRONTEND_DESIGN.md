# USCIS Case Tracker: Oracle APEX Frontend Design

**Version:** 1.0  
**Date:** February 3, 2026  

---

## Table of Contents

1. [Application Overview](#1-application-overview)
2. [Application Properties](#2-application-properties)
3. [Theme & Styling](#3-theme--styling)
4. [Page Designs](#4-page-designs)
5. [Shared Components](#5-shared-components)
6. [Mobile Responsiveness](#6-mobile-responsiveness)
7. [Accessibility](#7-accessibility)
8. [Wireframes](#8-wireframes)

---

## 1. Application Overview

### 1.1 Application Purpose

The USCIS Case Tracker APEX application provides a modern, responsive web interface for:

- Tracking USCIS immigration case statuses
- Viewing case history and timelines
- Checking live status from USCIS API
- Managing case notes and preferences
- Importing/exporting case data
- Administrative functions

### 1.2 User Personas

| Persona      | Role                          | Primary Actions                      |
|---------------|-------------------------------|-------------------------------------|
| Case User    | End user tracking their cases | View cases, add cases, check status |
| Power User   | User with many cases          | Bulk operations, import/export, advanced filtering |
| Administrator| System admin                   | User management, audit logs, scheduler configuration |

### 1.3 Application Map

```text
                              ┌─────────────────┐
                              │   Login (101)   │
                              └────────┬────────┘
                                       │
                                       ▼
              ┌────────────────────────┴────────────────────────┐
              │                  Dashboard (1)                   │
              │  [Summary Cards] [Charts] [Recent Activity]     │
              └───┬────────┬─────────┬─────────┬───────────────┘
                  │        │         │         │
        ┌─────────┴─┐ ┌────┴────┐ ┌──┴───┐ ┌───┴───────┐
        │ Case List │ │ Import/ │ │ Set- │ │  Admin    │
        │   (2)     │ │ Export  │ │ tings│ │   (8)     │
        └─────┬─────┘ │  (6)    │ │ (7)  │ └───────────┘
              │       └─────────┘ └──────┘
              ▼
        ┌───────────┐
        │  Case     │
        │ Details   │
        │   (3)     │
        └───────────┘
              
        Modal Dialogs:
        ┌──────────┐  ┌──────────────┐
        │ Add Case │  │ Check Status │
        │   (4)    │  │     (5)      │
        └──────────┘  └──────────────┘
```

---

## 2. Application Properties

### 2.1 Application Definition

```yaml
Application:
  ID: 100  # Adjust as needed
  Name: USCIS Case Tracker
  Alias: USCIS_TRACKER
  Version: 1.0.0
  
Appearance:
  Theme: Universal Theme (Theme 42)
  Theme Style: Vita - Slate
  Template Options:
    - Navigation: Side Navigation
    - Header: Fixed
    - Footer: Hidden
    
Globalization:
  Primary Language: English (en)
  Date Format: DD-MON-YYYY
  Timestamp Format: DD-MON-YYYY HH24:MI
  
Security:
  Authentication: APEX Accounts (Dev) / Custom (Prod)
  Session Timeout: 30 minutes (idle), 8 hours (max)
  Cookie Settings:
    Secure: Yes
    HttpOnly: Yes
    SameSite: Strict
```

### 2.2 Application Items (Global)

| Item Name             | Scope       | Purpose                  |
|-----------------------|-------------|--------------------------|
| G_USER_ROLE          | Application | Current user's role     |
| G_AUTO_CHECK_ENABLED | Application | Whether auto-check is enabled |
| G_USCIS_API_MODE     | Application | 'SANDBOX' or 'PRODUCTION' |
| G_APP_VERSION        | Application | Current app version      |

### 2.3 Application Processes

| Name             | Point         | Purpose                      |
|------------------|---------------|------------------------------|
| Set User Context| Before Header | Load user role and preferences |
| Log Page View   | After Header  | Audit page access            |
| Cleanup Temp Data| On Demand     | Clear temporary tables       |

---

## 3. Theme & Styling

### 3.1 Color Palette

```css
:root {
  /* Primary Colors */
  --uscis-primary: #003366;        /* Navy Blue - USCIS brand */
  --uscis-secondary: #0071bc;      /* Medium Blue */
  --uscis-accent: #02bfe7;         /* Light Blue */
  
  /* Status Colors */
  --status-approved: #2e8540;      /* Green */
  --status-denied: #cd2026;        /* Red */
  --status-pending: #fdb81e;       /* Yellow */
  --status-rfe: #0071bc;           /* Blue */
  --status-received: #4c2c92;      /* Purple */
  --status-unknown: #5b616b;       /* Gray */
  
  /* Neutral Colors */
  --neutral-100: #ffffff;
  --neutral-200: #f1f1f1;
  --neutral-300: #d6d7d9;
  --neutral-700: #5b616b;
  --neutral-900: #212121;
  
  /* Semantic Colors */
  --success: #2e8540;
  --warning: #fdb81e;
  --danger: #cd2026;
  --info: #0071bc;
}
```

### 3.2 Custom CSS

```css
/* ==========================================================
   USCIS Case Tracker - Custom Styles
   ========================================================== */

/* ---------- Global Overrides ---------- */
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, 
               "Source Sans Pro", "Helvetica Neue", Arial, sans-serif;
}

.t-Header-logo {
  background-color: var(--uscis-primary);
}

.t-NavigationBar {
  background-color: var(--uscis-primary);
}

/* ---------- Receipt Number Styling ---------- */
.receipt-number {
  font-family: 'Roboto Mono', 'Courier New', monospace;
  font-weight: 600;
  font-size: 1.1em;
  letter-spacing: 1px;
  color: var(--uscis-secondary);
}

.receipt-number--link {
  text-decoration: none;
  border-bottom: 2px solid transparent;
  transition: border-color 0.2s ease;
}

.receipt-number--link:hover {
  border-bottom-color: var(--uscis-accent);
}

/* ---------- Status Badges ---------- */
.status-badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-badge--approved {
  background-color: var(--status-approved);
  color: white;
}

.status-badge--denied {
  background-color: var(--status-denied);
  color: white;
}

.status-badge--pending {
  background-color: var(--status-pending);
  color: var(--neutral-900);
}

.status-badge--rfe {
  background-color: var(--status-rfe);
  color: white;
}

.status-badge--received {
  background-color: var(--status-received);
  color: white;
}

.status-badge--unknown {
  background-color: var(--status-unknown);
  color: white;
}

/* ---------- Cards ---------- */
.case-card {
  border-left: 4px solid var(--uscis-secondary);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.case-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.summary-card {
  text-align: center;
  padding: 20px;
}

.summary-card__number {
  font-size: 48px;
  font-weight: 700;
  color: var(--uscis-primary);
}

.summary-card__label {
  font-size: 14px;
  color: var(--neutral-700);
  text-transform: uppercase;
  letter-spacing: 1px;
}

/* ---------- Timeline ---------- */
.status-timeline {
  position: relative;
  padding-left: 30px;
}

.status-timeline::before {
  content: '';
  position: absolute;
  left: 10px;
  top: 0;
  bottom: 0;
  width: 2px;
  background-color: var(--neutral-300);
}

.timeline-item {
  position: relative;
  padding-bottom: 20px;
}

.timeline-item::before {
  content: '';
  position: absolute;
  left: -24px;
  top: 5px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: var(--uscis-secondary);
  border: 2px solid white;
  box-shadow: 0 0 0 2px var(--uscis-secondary);
}

.timeline-item--latest::before {
  background-color: var(--uscis-accent);
  box-shadow: 0 0 0 2px var(--uscis-accent);
}

.timeline-date {
  font-size: 12px;
  color: var(--neutral-700);
}

.timeline-status {
  font-size: 16px;
  font-weight: 600;
  color: var(--neutral-900);
}

.timeline-details {
  font-size: 14px;
  color: var(--neutral-700);
  margin-top: 4px;
}

/* ---------- Interactive Grid Customization ---------- */
.a-IG .status-approved {
  background-color: rgba(46, 133, 64, 0.1);
}

.a-IG .status-denied {
  background-color: rgba(205, 32, 38, 0.1);
}

.a-IG .status-rfe {
  background-color: rgba(0, 113, 188, 0.1);
}

/* Row hover highlight */
.a-IG-row:hover {
  --a-ig-row-hover-background-color: rgba(0, 51, 102, 0.05);
}

/* ---------- Loading Spinner ---------- */
.uscis-spinner {
  display: inline-block;
  width: 40px;
  height: 40px;
  border: 4px solid var(--neutral-300);
  border-top-color: var(--uscis-secondary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ---------- Empty State ---------- */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--neutral-700);
}

.empty-state__icon {
  font-size: 64px;
  margin-bottom: 16px;
  color: var(--neutral-300);
}

.empty-state__title {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.empty-state__description {
  font-size: 16px;
  margin-bottom: 24px;
}

/* ---------- Mobile Responsive ---------- */
@media (max-width: 768px) {
  .summary-card__number {
    font-size: 32px;
  }
  
  .receipt-number {
    font-size: 1em;
  }
  
  .a-CardView-items {
    --a-cv-columns: 1;
  }
}

/* ---------- Print Styles ---------- */
@media print {
  .t-Header,
  .t-NavigationBar,
  .t-Body-actions,
  .js-regionCollapse {
    display: none !important;
  }
  
  .t-Body-content {
    margin: 0 !important;
    padding: 20px !important;
  }
}
```

### 3.3 JavaScript Utilities

```javascript
/* ==========================================================
   USCIS Case Tracker - JavaScript Utilities
   ========================================================== */

// Namespace
var USCIS = USCIS || {};

/**
 * Format a receipt number with visual grouping
 * @param {string} receipt - The receipt number
 * @returns {string} Formatted receipt
 */
USCIS.formatReceipt = function(receipt) {
    if (!receipt || receipt.length !== 13) return receipt;
    return receipt.substring(0, 3) + '-' + 
           receipt.substring(3, 7) + '-' + 
           receipt.substring(7);
};

/**
 * Get appropriate CSS class for a status
 * @param {string} status - The case status text
 * @returns {string} CSS class suffix
 */
USCIS.getStatusClass = function(status) {
    if (!status) return 'unknown';
    var s = status.toLowerCase();
    if (s.includes('approved') || s.includes('card was delivered')) return 'approved';
    if (s.includes('denied') || s.includes('rejected')) return 'denied';
    if (s.includes('rfe') || s.includes('evidence')) return 'rfe';
    if (s.includes('received') || s.includes('accepted')) return 'received';
    if (s.includes('pending') || s.includes('review')) return 'pending';
    return 'unknown';
};

/**
 * Show loading overlay
 * @param {string} message - Optional loading message
 */
USCIS.showLoading = function(message) {
    apex.util.showSpinner($('#wwvFlowForm'));
    if (message) {
        // Custom message handling if needed
    }
};

/**
 * Hide loading overlay
 */
USCIS.hideLoading = function() {
    apex.util.delayLinger.finish('spinner');
};

/**
 * Validate receipt number format
 * @param {string} receipt - The receipt number
 * @returns {boolean} True if valid
 */
USCIS.validateReceipt = function(receipt) {
    if (!receipt) return false;
    var normalized = receipt.toUpperCase().replace(/[^A-Z0-9]/g, '');
    return /^[A-Z]{3}[0-9]{10}$/.test(normalized);
};

/**
 * Normalize receipt number input
 * @param {string} input - User input
 * @returns {string} Normalized receipt
 */
USCIS.normalizeReceipt = function(input) {
    if (!input) return '';
    return input.toUpperCase().replace(/[^A-Z0-9]/g, '');
};

/**
 * Copy text to clipboard with feedback
 * Uses modern Clipboard API with permission handling and secure fallback
 * @param {string} text - Text to copy
 * @param {function} callback - Optional callback after copy
 */
USCIS.copyToClipboard = function(text, callback) {
    var showSuccess = function() {
        apex.message.showPageSuccess('Copied to clipboard');
        if (callback) callback();
    };
    var showError = function(msg) {
        apex.message.showErrors([{
            type: 'error',
            location: 'page',
            message: msg || 'Failed to copy to clipboard'
        }]);
    };
    
    // Secure fallback using temporary textarea (for non-HTTPS or unsupported browsers)
    var fallbackCopy = function() {
        var textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-9999px';
        textarea.style.top = '0';
        textarea.setAttribute('readonly', '');
        document.body.appendChild(textarea);
        try {
            textarea.select();
            textarea.setSelectionRange(0, textarea.value.length);
            var success = document.execCommand('copy');
            if (success) {
                showSuccess();
            } else {
                showError('Copy command failed. Please copy manually.');
            }
        } catch (err) {
            showError('Unable to copy: ' + err.message);
        } finally {
            document.body.removeChild(textarea);
        }
    };
    
    // Check for modern Clipboard API support
    if (!navigator.clipboard || !navigator.clipboard.writeText) {
        // Clipboard API not available (likely non-HTTPS context)
        // Allow localhost, 127.0.0.1, and ::1 (IPv6 localhost) as local addresses
        var isLocalHost = window.location.hostname === 'localhost' || 
                          window.location.hostname === '127.0.0.1' || 
                          window.location.hostname === '::1';
        if (window.location.protocol !== 'https:' && !isLocalHost) {
            showError('Clipboard requires HTTPS. Please copy manually.');
            return;
        }
        fallbackCopy();
        return;
    }
    
    // Try permission query if available (non-blocking)
    var attemptClipboardWrite = function() {
        navigator.clipboard.writeText(text).then(function() {
            showSuccess();
        }).catch(function(err) {
            // Permission denied or other error - try fallback
            if (err.name === 'NotAllowedError') {
                fallbackCopy();
            } else {
                showError('Failed to copy: ' + err.message);
            }
        });
    };
    
    if (navigator.permissions && navigator.permissions.query) {
        navigator.permissions.query({name: 'clipboard-write'}).then(function(result) {
            if (result.state === 'granted' || result.state === 'prompt') {
                attemptClipboardWrite();
            } else {
                fallbackCopy();
            }
        }).catch(function() {
            // Permission query failed, try clipboard anyway
            attemptClipboardWrite();
        });
    } else {
        attemptClipboardWrite();
    }
};

/**
 * Relative time formatting (e.g., "2 days ago")
 * @param {Date|string} date - The date
 * @returns {string} Relative time string
 */
USCIS.relativeTime = function(date) {
    if (!date) return '';
    var d = typeof date === 'string' ? new Date(date) : date;
    var now = new Date();
    var diff = now - d;
    var seconds = Math.floor(diff / 1000);
    var minutes = Math.floor(seconds / 60);
    var hours = Math.floor(minutes / 60);
    var days = Math.floor(hours / 24);
    
    if (days > 30) return d.toLocaleDateString();
    if (days > 0) return days + ' day' + (days > 1 ? 's' : '') + ' ago';
    if (hours > 0) return hours + ' hour' + (hours > 1 ? 's' : '') + ' ago';
    if (minutes > 0) return minutes + ' minute' + (minutes > 1 ? 's' : '') + ' ago';
    return 'Just now';
};

/**
 * Refresh case status from USCIS API
 * @param {string} receiptNumber - The receipt number to refresh
 */
USCIS.refreshCase = function(receiptNumber) {
    if (!receiptNumber) {
        apex.message.showErrors([{
            type: 'error',
            location: 'page',
            message: 'No receipt number provided'
        }]);
        return;
    }
    
    if (!USCIS.validateReceipt(receiptNumber)) {
        // SECURITY: Do not include user input in error messages to prevent XSS
        // Note: APEX escapes HTML by default, but we avoid including user input as best practice
        apex.message.showErrors([{
            type: 'error',
            location: 'page',
            message: 'Invalid receipt number format'
        }]);
        return;
    }
    
    USCIS.showLoading('Refreshing case status...');
    
    apex.server.process('REFRESH_CASE_STATUS', {
        x01: USCIS.normalizeReceipt(receiptNumber)
    }, {
        dataType: 'json',
        success: function(data) {
            USCIS.hideLoading();
            if (data.success) {
                apex.message.showPageSuccess('Case status refreshed successfully');
                // Refresh the Cases region to show updated data
                if (apex.region('Cases')) {
                    apex.region('Cases').refresh();
                }
                // Also refresh Case Details region if on details page
                if (apex.region('CaseDetails')) {
                    apex.region('CaseDetails').refresh();
                }
            } else {
                apex.message.showErrors([{
                    type: 'error',
                    location: 'page',
                    message: data.message || 'Failed to refresh case status'
                }]);
            }
        },
        error: function(xhr, status, error) {
            USCIS.hideLoading();
            // Log detailed error for debugging (not visible to users)
            console.error('[USCIS Tracker] Case refresh error:', error, status, xhr);
            // Show generic message to users without sensitive details
            apex.message.showErrors([{
                type: 'error',
                location: 'page',
                message: 'An error occurred while refreshing the case. Please try again.'
            }]);
        }
    });
};

// Initialize on page load
$(document).ready(function() {
    // Add status badge classes dynamically
    $('.js-status-text').each(function() {
        var $el = $(this);
        var status = $el.text();
        var className = 'status-badge status-badge--' + USCIS.getStatusClass(status);
        $el.addClass(className);
    });
    
    // Receipt number input normalization (delegated for dynamic elements)
    $(document).on('blur', 'input[data-receipt-input]', function() {
        var $input = $(this);
        $input.val(USCIS.normalizeReceipt($input.val()));
    });
});
```

---

## 4. Page Designs

### 4.1 Page 0: Global Page

```yaml
Page:
  Number: 0
  Name: Global Page
  Mode: Global
  
Regions:
  - Name: Navigation Menu
    Position: Navigation Bar
    Type: List
    List: Desktop Navigation Menu
    Template: Side Navigation Menu
    
  - Name: Page Header
    Position: Header
    Template: Hero
    Items:
      - Logo (SVG/Image)
      - Application Title
      
  - Name: User Info
    Position: Header Right
    Template: Standard
    Items:
      - Username Display
      - Logout Button
      
Breadcrumbs:
  Position: Breadcrumb Bar
  Template: Breadcrumb
  
Page Items:
  - P0_RECEIPT_SEARCH
    Type: Text Field
    Placeholder: "Search by receipt #..."
    Template: Hidden Label
    Position: Header (Search)
    
Dynamic Actions:
  - Name: Receipt Search
    Event: Enter key on P0_RECEIPT_SEARCH
    Action: Redirect to Page 3 with P3_RECEIPT_NUMBER
```

### 4.2 Page 1: Dashboard

```yaml
Page:
  Number: 1
  Name: Dashboard
  Title: USCIS Case Tracker
  Mode: Normal
  Alias: home
  
Regions:
  - Name: Welcome Banner
    Type: Static Content
    Position: Body (top)
    Template: Alert
    Condition: First login of day
    Source: |
      <h2>Welcome back, &APP_USER.!</h2>
      <p>You have <strong>#ACTIVE_CASES#</strong> active cases being tracked.</p>
    
  - Name: Summary Cards
    Type: Cards
    Position: Body
    Template: Standard
    Source:
      Type: SQL Query
      SQL: |
        SELECT 
          'fa-briefcase' AS card_icon,
          'u-color-1' AS card_color,
          'Total Cases' AS card_title,
          TO_CHAR(COUNT(*)) AS card_value,
          'All tracked cases' AS card_subtitle,
          APEX_PAGE.GET_URL(p_page => 2) AS card_link
        FROM case_history
        UNION ALL
        SELECT 
          'fa-check-circle',
          'u-color-4',
          'Active Cases',
          TO_CHAR(COUNT(*)),
          'Currently monitoring',
          APEX_PAGE.GET_URL(
            p_page   => 2,
            p_clear_cache => 'RP',
            p_items  => 'P2_FILTER',
            p_values => 'ACTIVE'
          )
        FROM case_history WHERE is_active = 1
        UNION ALL
        SELECT 
          'fa-bell',
          'u-color-9',
          'Updated Today',
          TO_CHAR(COUNT(*)),
          'Recent status changes',
          APEX_PAGE.GET_URL(
            p_page   => 2,
            p_clear_cache => 'RP',
            p_items  => 'P2_FILTER',
            p_values => 'TODAY'
          )
        FROM status_updates
        WHERE created_at >= TRUNC(SYSDATE) AND created_at < TRUNC(SYSDATE) + 1
        UNION ALL
        SELECT 
          'fa-clock-o',
          'u-color-13',
          'Pending Check',
          TO_CHAR(COUNT(*)),
          'Not checked in 7+ days',
          APEX_PAGE.GET_URL(
            p_page   => 2,
            p_clear_cache => 'RP',
            p_items  => 'P2_FILTER',
            p_values => 'STALE'
          )
        FROM case_history
        WHERE last_checked_at < SYSDATE - 7 OR last_checked_at IS NULL
    Attributes:
      Card Primary Key: card_title
      Title Column: card_value
      Subtitle Column: card_title
      Body Column: card_subtitle
      Icon Source: card_icon
      Icon CSS Classes: card_color
      Card Link: card_link
      
  - Name: Status Distribution
    Type: Chart
    Position: Body (left 60%)
    Template: Standard
    Title: Cases by Status
    Chart:
      Type: Donut
      Legend Position: Bottom
      Data Labels: Yes (percentage)
    Source:
      Type: SQL Query
      SQL: |
        SELECT 
          NVL(current_status, 'Unknown') AS status_label,
          COUNT(*) AS case_count,
          CASE 
            WHEN current_status LIKE '%Approved%' THEN '#2e8540'
            WHEN current_status LIKE '%Denied%' THEN '#cd2026'
            WHEN current_status LIKE '%RFE%' THEN '#0071bc'
            WHEN current_status LIKE '%Received%' THEN '#4c2c92'
            ELSE '#5b616b'
          END AS status_color
        FROM v_case_current_status
        WHERE is_active = 1
        GROUP BY current_status
        ORDER BY case_count DESC
        FETCH FIRST 8 ROWS ONLY
      Series:
        - Name: Cases
          Value Column: CASE_COUNT
          Label Column: STATUS_LABEL
          Color Column: STATUS_COLOR
          
  - Name: Recent Activity
    Type: Timeline
    Position: Body (right 40%)
    Template: Standard
    Title: Recent Activity
    Max Rows: 10
    Source:
      Type: SQL Query
      SQL: |
        SELECT 
          performed_at AS event_date,
          CASE action
            WHEN 'INSERT' THEN 'Added: ' || receipt_number
            WHEN 'DELETE' THEN 'Removed: ' || receipt_number
            WHEN 'CHECK' THEN 'Checked: ' || receipt_number
            ELSE 'Updated: ' || receipt_number
          END AS event_title,
          performed_by AS event_user,
          CASE action
            WHEN 'INSERT' THEN 'fa-plus-circle u-success-text'
            WHEN 'DELETE' THEN 'fa-minus-circle u-danger-text'
            WHEN 'CHECK' THEN 'fa-refresh u-info-text'
            ELSE 'fa-edit u-warning-text'
          END AS event_icon,
          action AS event_type
        FROM case_audit_log
        ORDER BY performed_at DESC
        FETCH FIRST 10 ROWS ONLY
    Attributes:
      Date Column: EVENT_DATE
      Title Column: EVENT_TITLE
      User Column: EVENT_USER
      Icon CSS Column: EVENT_ICON
      Type Column: EVENT_TYPE
      
  - Name: Quick Actions
    Type: Button Group
    Position: Body (bottom)
    Template: Standard
    Buttons:
      - Name: BTN_ADD_CASE
        Label: Add New Case
        Icon: fa-plus
        Style: Hot
        Action: Redirect (Modal) to Page 4
        
      - Name: BTN_CHECK_STATUS  
        Label: Check Status
        Icon: fa-search
        Style: Normal
        Action: Redirect (Modal) to Page 5
        
      - Name: BTN_REFRESH_ALL
        Label: Refresh All Active
        Icon: fa-refresh
        Style: Normal
        Confirm: This will check status for all active cases. Continue?
        Action: Execute PL/SQL
        PL/SQL: uscis_scheduler_pkg.run_auto_check;
        Condition: User has ADMIN role
```

### 4.3 Page 2: Case List

```yaml
Page:
  Number: 2
  Name: Case List
  Title: My Cases
  Mode: Normal
  Alias: cases
  
Items:
  - Name: P2_FILTER
    Type: Hidden
    Source: URL Parameter
    
Regions:
  - Name: Cases
    Type: Interactive Grid
    Position: Body
    Template: Standard
    Source:
      Type: SQL Query
      SQL: |
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
          AND (:P2_FILTER IS NULL 
               OR (:P2_FILTER = 'ACTIVE' AND is_active = 1)
               OR (:P2_FILTER = 'TODAY' AND TRUNC(last_updated) = TRUNC(SYSDATE))
               OR (:P2_FILTER = 'STALE' AND (last_checked_at < SYSDATE - 7 OR last_checked_at IS NULL))
          )
        ORDER BY last_updated DESC NULLS LAST
        
    Columns:
      - Name: RECEIPT_NUMBER
        Label: Receipt #
        Type: Link
        Link Target: 
          Page: 3
          Items: P3_RECEIPT_NUMBER = #RECEIPT_NUMBER#
        CSS Class: receipt-number
        Width: 150px
        Frozen: Yes
        
      - Name: CASE_TYPE
        Label: Form Type
        Type: Plain Text
        Width: 200px
        
      - Name: CURRENT_STATUS
        Label: Status
        Type: Plain Text
        HTML Expression: |
          <!-- STATUS_CLASS computed server-side via SQL: LOWER(REGEXP_REPLACE(CURRENT_STATUS, '[^a-zA-Z0-9]+', '-')) -->
          <span class="status-badge status-badge--#STATUS_CLASS#" data-status="#CURRENT_STATUS#">
            #CURRENT_STATUS#
          </span>
        Width: 200px
        Escape Special Characters: Yes
        Note: |
          SECURITY: Both #CURRENT_STATUS# and #STATUS_CLASS# MUST be HTML-escaped to prevent XSS.
          
          Implementation Requirements:
          1. Enable "Escape Special Characters" in the Interactive Grid column settings
             OR use APEX_ESCAPE.HTML() wrapper in the SQL source
          2. Add STATUS_CLASS to the SQL query with sanitization:
             REGEXP_REPLACE(LOWER(REGEXP_REPLACE(current_status, '[^a-zA-Z0-9]+', '-')), '[^a-z0-9-]', '') AS status_class
          3. The REGEXP_REPLACE for STATUS_CLASS already produces only safe characters (a-z, 0-9, hyphen)
          4. CURRENT_STATUS should be escaped at the source using:
             APEX_ESCAPE.HTML(current_status) AS current_status
             OR enable column-level escaping in IG properties
          5. Validate that user-controlled values are properly encoded before storage
        
      - Name: LAST_UPDATED
        Label: Last Updated
        Type: Plain Text
        Format: SINCE
        Width: 120px
        
      - Name: IS_ACTIVE
        Label: Active
        Type: Switch
        Width: 80px
        On Value: 1
        Off Value: 0
        Inline Edit: Yes
        
      - Name: TOTAL_UPDATES
        Label: Updates
        Type: Plain Text
        Alignment: Center
        Width: 80px
        
      - Name: LAST_CHECKED_AT
        Label: Last Checked
        Type: Plain Text
        Format: SINCE
        Width: 120px
        
      - Name: ACTIONS
        Label: Actions
        Type: Hidden
        
    Row Actions:
      - Name: View Details
        Icon: fa-eye
        Action: Redirect to Page 3
        
      - Name: Refresh Status
        Icon: fa-refresh
        Action: Execute JavaScript
        JavaScript: |
          // Use data-receipt attribute set on row to safely get receipt number
          var receiptNumber = this.data.RECEIPT_NUMBER || this.triggeringElement.closest('tr').dataset.receipt;
          if (receiptNumber) {
              USCIS.refreshCase(receiptNumber);
          }
        
      - Name: Delete
        Icon: fa-trash
        Action: Execute PL/SQL
        Items to Submit: P2_SELECTED_RECEIPT
        Set Items:
          # APEX Row Action "Set Items" configuration (not pseudocode)
          - Target Item: P2_SELECTED_RECEIPT
            Value: '#RECEIPT_NUMBER#'  # Source substitution - only used to populate the page item
        PL/SQL: |
          -- SECURITY: Use bind variable instead of substitution string to prevent SQL injection
          uscis_case_pkg.delete_case(p_receipt_number => :P2_SELECTED_RECEIPT);
        Confirm: Delete this case?
        Note: |
          APEX ROW ACTION CONFIGURATION:
          In APEX Builder, configure the Row Action's "Set Items" property:
          - Target Item: P2_SELECTED_RECEIPT
          - Value: #RECEIPT_NUMBER# (substitution string used only to set the page item value)
          
          SECURITY: The PL/SQL code MUST use the bind variable :P2_SELECTED_RECEIPT.
          Never use raw substitution strings like '#RECEIPT_NUMBER#' directly in PL/SQL.
          The substitution populates the page item, which is then safely bound.
        
    IG Attributes:
      Toolbar:
        Buttons:
          - Search Field
          - Actions Menu
          - Add Row (hidden)
          - Save (for inline edits)
          - Reset
          
        Custom Buttons:
          - Name: BTN_ADD
            Label: Add Case
            Icon: fa-plus
            Position: Column Selection
            Action: Redirect (Modal) to Page 4
            Style: Hot
            
          - Name: BTN_BULK_REFRESH
            Label: Refresh Selected
            Icon: fa-refresh
            Position: Column Selection
            Condition: Rows selected
            Action: Execute JavaScript
            
          - Name: BTN_EXPORT
            Label: Export
            Icon: fa-download
            Position: Column Selection
            Action: Redirect to Page 6
            
      Pagination:
        Type: Page
        Rows Per Page: 25
        Rows Per Page Selector: Yes (10, 25, 50, 100)
        
      Features:
        Row Selector: Checkbox
        Row Highlighting: Yes
        Sticky Header: Yes
        Download: CSV, Excel
        
    Processing:
      - Name: Save IG Changes
        Type: Interactive Grid - Automatic Row Processing
        Table: CASE_HISTORY
        
      - Name: REFRESH_CASE_STATUS
        Type: AJAX Callback
        Point: On Demand
        PL/SQL: |
          -- AJAX process for refreshing case status from USCIS API
          DECLARE
            l_receipt_number VARCHAR2(13);
            l_status         uscis_types_pkg.t_case_status;
            l_result         VARCHAR2(4000);
            l_is_authorized  BOOLEAN := FALSE;
          BEGIN
            -- Get receipt number from AJAX request (x01 parameter)
            l_receipt_number := APEX_APPLICATION.G_X01;
            
            -- Validate receipt number format
            IF NOT uscis_util_pkg.validate_receipt_number(l_receipt_number) THEN
              APEX_JSON.OPEN_OBJECT;
              APEX_JSON.WRITE('success', FALSE);
              APEX_JSON.WRITE('message', 'Invalid receipt number format');
              APEX_JSON.CLOSE_OBJECT;
              RETURN;
            END IF;
            
            -- Normalize the receipt number
            l_receipt_number := uscis_util_pkg.normalize_receipt_number(l_receipt_number);
            
            -- SECURITY: Authorization check - ensure current user can access this case
            l_is_authorized := uscis_case_pkg.user_can_access_case(
              p_receipt_number => l_receipt_number,
              p_user           => APEX_APPLICATION.G_USER
            );
            
            IF NOT l_is_authorized THEN
              APEX_JSON.OPEN_OBJECT;
              APEX_JSON.WRITE('success', FALSE);
              APEX_JSON.WRITE('message', 'Not authorized to access this case');
              APEX_JSON.CLOSE_OBJECT;
              RETURN;
            END IF;
            
            -- Call USCIS API to get current status
            BEGIN
              l_status := uscis_api_pkg.check_case_status(l_receipt_number);
              
              -- Update the case with new status (no commit yet)
              uscis_case_pkg.add_or_update_case(
                p_receipt_number => l_receipt_number,
                p_case_type      => l_status.case_type,
                p_current_status => l_status.current_status,
                p_last_updated   => l_status.last_updated,
                p_details        => l_status.details,
                p_source         => uscis_types_pkg.gc_source_api
              );
              
              -- COMMIT BEFORE writing JSON response to ensure data integrity
              -- If COMMIT fails, the exception handler will ROLLBACK and return error
              COMMIT;
              
              -- Write success response AFTER successful commit
              APEX_JSON.OPEN_OBJECT;
              APEX_JSON.WRITE('success', TRUE);
              APEX_JSON.WRITE('message', 'Status refreshed successfully');
              APEX_JSON.WRITE('status', l_status.current_status);
              APEX_JSON.WRITE('lastUpdated', TO_CHAR(l_status.last_updated, 'YYYY-MM-DD"T"HH24:MI:SS'));
              APEX_JSON.CLOSE_OBJECT;
              
            EXCEPTION
              WHEN OTHERS THEN
                ROLLBACK;
                -- Log the full error details server-side (not exposed to user)
                apex_debug.error('REFRESH_CASE_STATUS failed for case ' || 
                  uscis_util_pkg.mask_receipt_number(l_receipt_number) || 
                  ': ' || SQLERRM || CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                
                -- Return generic error message (no SQLERRM exposure)
                APEX_JSON.OPEN_OBJECT;
                APEX_JSON.WRITE('success', FALSE);
                APEX_JSON.WRITE('message', 'Failed to refresh case status. Please try again or contact support.');
                APEX_JSON.CLOSE_OBJECT;
            END;
          END;
        Note: |
          This AJAX callback process handles the USCIS.refreshCase() JavaScript calls.
          
          SECURITY FEATURES:
          1. Authorization check: Verifies user can access the case before refresh
          2. COMMIT placement: Occurs BEFORE writing JSON response to ensure data integrity;
             if COMMIT fails, the EXCEPTION handler will ROLLBACK and return an error message
          3. Error handling: Logs full SQLERRM server-side, returns generic message to user
          4. Rollback: On error, rolls back any pending changes
          
    Validations:
      - Name: Valid Receipt Format
        Type: PL/SQL Function
        Column: RECEIPT_NUMBER
        PL/SQL: RETURN uscis_util_pkg.validate_receipt_number(:RECEIPT_NUMBER);
        Error: Invalid receipt number format
```

### 4.4 Page 3: Case Details

```yaml
Page:
  Number: 3
  Name: Case Details
  Title: Case: &P3_RECEIPT_NUMBER.
  Mode: Normal
  Alias: case
  
Items:
  - Name: P3_RECEIPT_NUMBER
    Type: Hidden
    Source: URL Parameter
    Session State: Request
    
Regions:
  - Name: Case Header
    Type: Static Content
    Position: Body
    Template: Hero
    Source:
      Type: PL/SQL Function Body
      PL/SQL: |
        DECLARE
          l_case v_case_current_status%ROWTYPE;
          l_receipt_html    VARCHAR2(100);
          l_receipt_data    VARCHAR2(100);
          l_type_html       VARCHAR2(500);
          l_status_html     VARCHAR2(500);
          l_status_class    VARCHAR2(100);
          l_updated_html    VARCHAR2(100);
        BEGIN
          SELECT * INTO l_case 
          FROM v_case_current_status 
          WHERE receipt_number = :P3_RECEIPT_NUMBER;
          
          -- Escape all user-controlled values for HTML context
          l_receipt_html := APEX_ESCAPE.HTML(l_case.receipt_number);
          l_receipt_data := APEX_ESCAPE.HTML_ATTRIBUTE(l_case.receipt_number);
          l_type_html    := APEX_ESCAPE.HTML(l_case.case_type);
          l_status_html  := APEX_ESCAPE.HTML(l_case.current_status);
          l_updated_html := APEX_ESCAPE.HTML(TO_CHAR(l_case.last_updated, 'Mon DD, YYYY HH:MI AM'));
          
          -- Sanitize status class: only allow lowercase letters, numbers, and hyphens
          l_status_class := REGEXP_REPLACE(
            LOWER(REGEXP_REPLACE(l_case.current_status, '[^a-zA-Z0-9]+', '-')),
            '[^a-z0-9-]', ''
          );
          
          RETURN '
            <div class="case-header">
              <div class="case-header__receipt">
                <span class="receipt-number">' || l_receipt_html || '</span>
                <button class="t-Button t-Button--noUI js-copy-receipt" 
                        data-receipt="' || l_receipt_data || '"
                        type="button" aria-label="Copy receipt number">
                  <span class="fa fa-copy"></span>
                </button>
              </div>
              <div class="case-header__type">' || l_type_html || '</div>
              <div class="case-header__status">
                <span class="status-badge status-badge--' || l_status_class || '">
                  ' || l_status_html || '
                </span>
              </div>
              <div class="case-header__updated">
                Last updated: ' || l_updated_html || '
              </div>
            </div>';
        END;
        
    Dynamic Actions:
      - Name: Copy Receipt Handler
        Event: Click
        Selection Type: jQuery Selector
        Selector: .js-copy-receipt
        Action: Execute JavaScript Code
        Code: |
          var receipt = $(this.triggeringElement).data('receipt');
          if (receipt) {
              USCIS.copyToClipboard(receipt);
          }
        
    Buttons:
      - Name: BTN_REFRESH
        Label: Refresh Status
        Icon: fa-refresh
        Position: Right of Title
        Style: Normal
        
      - Name: BTN_DELETE
        Label: Delete
        Icon: fa-trash
        Position: Right of Title
        Style: Danger
        Confirm: Are you sure you want to delete this case?
        
      - Name: BTN_TOGGLE_ACTIVE
        Label: &P3_ACTIVE_LABEL.
        Icon: &P3_ACTIVE_ICON.
        Position: Right of Title
        
  - Name: Status Timeline
    Type: Timeline
    Position: Body (Main Content - 70%)
    Template: Standard
    Title: Status History
    Source:
      Type: SQL Query  
      SQL: |
        SELECT 
          last_updated AS event_date,
          current_status AS event_title,
          details AS event_description,
          CASE source
            WHEN 'API' THEN 'Checked via USCIS API'
            WHEN 'IMPORT' THEN 'Imported from file'
            ELSE 'Manually entered'
          END AS event_source,
          CASE source
            WHEN 'API' THEN 'fa-cloud'
            WHEN 'IMPORT' THEN 'fa-upload'
            ELSE 'fa-pencil'
          END AS event_icon,
          CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY last_updated DESC) = 1 
            THEN 'timeline-item--latest'
            ELSE ''
          END AS item_class
        FROM status_updates
        WHERE receipt_number = :P3_RECEIPT_NUMBER
        ORDER BY last_updated DESC
    Attributes:
      Date Column: EVENT_DATE
      Title Column: EVENT_TITLE
      Description Column: EVENT_DESCRIPTION
      Type Column: EVENT_SOURCE
      Icon CSS Column: EVENT_ICON
      Item CSS Class Column: ITEM_CLASS
      
  - Name: Case Details Tabs
    Type: Region Display Selector
    Position: Body (Side Panel - 30%)
    Sub-Regions:
      - Name: Notes
        Type: Rich Text Editor
        Item: P3_NOTES
        Source: 
          SQL: SELECT notes FROM case_history WHERE receipt_number = :P3_RECEIPT_NUMBER
        Save Process: Yes (AJAX on blur)
        
      - Name: Audit Trail
        Type: Interactive Report
        Source:
          SQL: |
            SELECT 
              performed_at,
              action,
              performed_by,
              old_values,
              new_values
            FROM case_audit_log
            WHERE receipt_number = :P3_RECEIPT_NUMBER
            ORDER BY performed_at DESC
        Pagination: Scroll (50 rows)
        
      - Name: Settings
        Type: Static Content
        Items:
          - P3_CHECK_FREQUENCY
            Type: Select List
            Label: Auto-check frequency
            LOV: 6 hours, 12 hours, 24 hours, 48 hours, Weekly, Never
          - P3_NOTIFICATIONS
            Type: Switch
            Label: Email notifications
            
Buttons:
  Actions:
    - Name: BTN_REFRESH
      Process: Refresh Case Status
      PL/SQL: |
        DECLARE
          l_status uscis_types_pkg.t_case_status;
        BEGIN
          l_status := uscis_api_pkg.check_case_status(:P3_RECEIPT_NUMBER, TRUE);
          :P3_SUCCESS_MSG := 'Status refreshed: ' || l_status.current_status;
        END;
      After: Refresh Timeline Region + Show Success Message
      
    - Name: BTN_DELETE
      Process: Delete Case
      PL/SQL: |
        BEGIN
          uscis_case_pkg.delete_case(:P3_RECEIPT_NUMBER);
        END;
      After: Redirect to Page 2 with Success Message
      
    - Name: BTN_TOGGLE_ACTIVE
      Process: Toggle Active
      PL/SQL: |
        DECLARE
          l_is_active NUMBER;
        BEGIN
          SELECT is_active INTO l_is_active 
          FROM case_history 
          WHERE receipt_number = :P3_RECEIPT_NUMBER;
          
          uscis_case_pkg.set_case_active(
            :P3_RECEIPT_NUMBER, 
            CASE WHEN l_is_active = 1 THEN FALSE ELSE TRUE END
          );
        END;
      After: Refresh Header Region
      
Computations:
  - Name: Set Active Button Label
    Item: P3_ACTIVE_LABEL
    Type: SQL Query
    SQL: |
      SELECT CASE WHEN is_active = 1 THEN 'Deactivate' ELSE 'Activate' END
      FROM case_history WHERE receipt_number = :P3_RECEIPT_NUMBER
      
  - Name: Set Active Button Icon
    Item: P3_ACTIVE_ICON
    Type: SQL Query
    SQL: |
      SELECT CASE WHEN is_active = 1 THEN 'fa-toggle-on' ELSE 'fa-toggle-off' END
      FROM case_history WHERE receipt_number = :P3_RECEIPT_NUMBER
```

### 4.5 Page 4: Add Case (Modal)

```yaml
Page:
  Number: 4
  Name: Add Case
  Title: Add Case
  Mode: Modal Dialog
  Dialog:
    Width: 500px
    Height: Auto
    
Items:
  - Name: P4_RECEIPT_NUMBER
    Type: Text Field
    Label: Receipt Number
    Placeholder: "e.g., IOE1234567890"
    Required: Yes
    Template: Required - Above
    Help: Enter the 13-character receipt number from your USCIS notice
    Format Mask: AAANNNNNNNNNNN
    Custom Attributes: data-receipt-input="true"
    
  - Name: P4_FETCH_FROM_USCIS
    Type: Switch
    Label: Fetch status from USCIS
    On Value: Y
    Off Value: N
    On Label: Yes
    Off Label: No
    Default: Y
    Help: When enabled, we'll check the USCIS system for the current case status
    
  - Name: P4_CASE_TYPE
    Type: Select List
    Label: Case Type
    Required: Yes (when manual)
    Condition: P4_FETCH_FROM_USCIS = 'N'
    LOV:
      Static:
        - I-130 (Petition for Alien Relative)
        - I-140 (Immigrant Petition for Alien Workers)
        - I-485 (Adjustment of Status)
        - I-539 (Change/Extend Nonimmigrant Status)
        - I-765 (Employment Authorization)
        - I-797 (Approval Notice)
        - I-821D (DACA)
        - Other
        
  - Name: P4_CURRENT_STATUS
    Type: Text Field
    Label: Current Status
    Condition: P4_FETCH_FROM_USCIS = 'N'
    Placeholder: "e.g., Case Was Received"
    
  - Name: P4_DETAILS
    Type: Textarea
    Label: Status Details
    Condition: P4_FETCH_FROM_USCIS = 'N'
    Height: 3 lines
    
  - Name: P4_NOTES
    Type: Textarea
    Label: Personal Notes (Optional)
    Height: 2 lines
    Help: Add any personal notes about this case

Buttons:
  - Name: BTN_CANCEL
    Label: Cancel
    Position: Create (left)
    Action: Close Dialog
    
  - Name: BTN_ADD
    Label: Add Case
    Position: Create (right)
    Style: Hot
    Action: Submit
    
Validations:
  - Name: Receipt Number Format
    Type: PL/SQL Function (Returning Error Text)
    Item: P4_RECEIPT_NUMBER
    PL/SQL: |
      DECLARE
        l_normalized VARCHAR2(13);
      BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);
        IF NOT uscis_util_pkg.validate_receipt_number(l_normalized) THEN
          RETURN 'Invalid receipt number format. Expected: 3 letters + 10 digits (e.g., IOE1234567890)';
        END IF;
        RETURN NULL;
      END;
      
  - Name: Case Not Exists
    Type: PL/SQL Function (Returning Error Text)
    Item: P4_RECEIPT_NUMBER
    PL/SQL: |
      DECLARE
        l_normalized VARCHAR2(13);
      BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);
        IF uscis_case_pkg.case_exists(l_normalized) THEN
          RETURN 'This case is already being tracked.';
        END IF;
        RETURN NULL;
      END;
      
Processes:
  - Name: Normalize Receipt
    Point: Before Validation
    Type: PL/SQL
    PL/SQL: |
      :P4_RECEIPT_NUMBER := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);
      
  - Name: Add Case
    Point: Processing
    Type: PL/SQL
    When Button: BTN_ADD
    PL/SQL: |
      DECLARE
        l_receipt VARCHAR2(13);
      BEGIN
        l_receipt := uscis_case_pkg.add_case(
          p_receipt_number   => :P4_RECEIPT_NUMBER,
          p_case_type        => :P4_CASE_TYPE,
          p_current_status   => :P4_CURRENT_STATUS,
          p_details          => :P4_DETAILS,
          p_notes            => :P4_NOTES,
          p_fetch_from_uscis => :P4_FETCH_FROM_USCIS = 'Y'
        );
        
        -- Set items for redirect
        apex_util.set_session_state('P3_RECEIPT_NUMBER', l_receipt);
      END;
      
  - Name: Close Dialog
    Point: After Processing
    Type: Close Dialog
    Items to Return: P3_RECEIPT_NUMBER
    
Branches:
  - Name: Redirect to Case Details
    Point: After Processing
    Target: Page 3
    Items: P3_RECEIPT_NUMBER = &P4_RECEIPT_NUMBER.
    
Dynamic Actions:
  - Name: Toggle Manual Fields
    Event: Change on P4_FETCH_FROM_USCIS
    True Action: Hide P4_CASE_TYPE, P4_CURRENT_STATUS, P4_DETAILS
    False Action: Show P4_CASE_TYPE, P4_CURRENT_STATUS, P4_DETAILS
```

### 4.6 Page 5: Check Status (Modal)

```yaml
Page:
  Number: 5
  Name: Check Status
  Title: Check Case Status
  Mode: Modal Dialog
  Dialog:
    Width: 600px
    Height: Auto
    
Items:
  - Name: P5_RECEIPT_NUMBER
    Type: Text Field
    Label: Receipt Number
    Placeholder: "e.g., IOE1234567890"
    Required: Yes
    Custom Attributes: data-receipt-input="true"
    
  - Name: P5_SAVE_TO_DB
    Type: Switch
    Label: Save to my tracked cases
    On Value: Y
    Off Value: N
    Default: N
    
  - Name: P5_RESULT_STATUS
    Type: Display Only
    Label: Current Status
    Template: Display Only - Heading
    Condition: P5_RESULT_STATUS IS NOT NULL
    
  - Name: P5_RESULT_TYPE
    Type: Display Only
    Label: Case Type
    Condition: P5_RESULT_STATUS IS NOT NULL
    
  - Name: P5_RESULT_UPDATED
    Type: Display Only
    Label: Last Updated
    Condition: P5_RESULT_STATUS IS NOT NULL
    
  - Name: P5_RESULT_DETAILS
    Type: Display Only
    Label: Details
    Template: Standard
    Condition: P5_RESULT_STATUS IS NOT NULL
    
Regions:
  - Name: Input Form
    Type: Static Content
    Position: Body
    Template: Blank with Attributes
    
  - Name: Result Card
    Type: Static Content
    Position: Body
    Template: Standard
    Title: Status Result
    Condition: P5_RESULT_STATUS IS NOT NULL
    CSS Class: case-card
    
  - Name: Loading Indicator
    Type: Static Content
    Position: Body
    Condition: Show with JavaScript
    Source: |
      <div class="loading-state" id="check-loading">
        <div class="uscis-spinner"></div>
        <p>Checking USCIS for status...</p>
      </div>

Buttons:
  - Name: BTN_CLOSE
    Label: Close
    Position: Create (left)
    Action: Close Dialog
    
  - Name: BTN_CHECK
    Label: Check Status
    Position: Create (right)
    Style: Hot
    Icon: fa-search
    Action: Submit (AJAX)
    
  - Name: BTN_VIEW_CASE
    Label: View Case Details
    Position: Create (right)
    Condition: P5_SAVE_TO_DB = 'Y' AND P5_RESULT_STATUS IS NOT NULL
    Action: Redirect to Page 3
    
Processes:
  - Name: Check Status
    Type: PL/SQL
    Point: Processing (AJAX)
    When Button: BTN_CHECK
    PL/SQL: |
      DECLARE
        l_status uscis_types_pkg.t_case_status;
        l_normalized VARCHAR2(13);
      BEGIN
        l_normalized := uscis_util_pkg.normalize_receipt_number(:P5_RECEIPT_NUMBER);
        
        l_status := uscis_api_pkg.check_case_status(
          p_receipt_number   => l_normalized,
          p_save_to_database => :P5_SAVE_TO_DB = 'Y'
        );
        
        :P5_RECEIPT_NUMBER := l_status.receipt_number;
        :P5_RESULT_STATUS := l_status.current_status;
        :P5_RESULT_TYPE := l_status.case_type;
        :P5_RESULT_UPDATED := TO_CHAR(l_status.last_updated, 'Month DD, YYYY');
        :P5_RESULT_DETAILS := l_status.details;
        
      EXCEPTION
        WHEN OTHERS THEN
          -- Log detailed error internally for debugging
          apex_debug.error('Check status error for receipt %s: %s', :P5_RECEIPT_NUMBER, SQLERRM);
          -- Show generic error to users without database details
          apex_error.add_error(
            p_message => 'An unexpected error occurred while checking status. Please try again.',
            p_display_location => apex_error.c_on_error_page
          );
      END;
      
Dynamic Actions:
  - Name: Show Loading
    Event: Click on BTN_CHECK (Before AJAX)
    Action: 
      - Execute JavaScript: $('#check-loading').show();
      - Hide Region: Result Card
      
  - Name: Hide Loading
    Event: After Refresh (After AJAX)
    Action:
      - Execute JavaScript: $('#check-loading').hide();
      - Show Region: Result Card
      - Refresh: Result Card items
```

### 4.7 Page 6: Import/Export

```yaml
Page:
  Number: 6
  Name: Import/Export
  Title: Import & Export Cases
  Mode: Normal
  Alias: transfer
  
Regions:
  - Name: Export Cases
    Type: Static Content
    Position: Body (50% left)
    Template: Standard
    Title: Export Cases
    Items:
      - P6_EXPORT_FORMAT
        Type: Radio Group
        Label: Format
        LOV:
          - JSON
          - CSV
        Default: JSON
        Layout: Horizontal
        
      - P6_EXPORT_FILTER
        Type: Text Field
        Label: Receipt Number Filter (Optional)
        Placeholder: "e.g., IOE, LIN"
        Help: Leave empty to export all cases
        
      - P6_INCLUDE_HISTORY
        Type: Switch
        Label: Include full status history
        Default: Y
        
    Buttons:
      - BTN_EXPORT
        Label: Download Export
        Icon: fa-download
        Style: Hot
        Action: Submit (triggers download)
        
  - Name: Import Cases
    Type: Static Content
    Position: Body (50% right)
    Template: Standard
    Title: Import Cases
    Items:
      - P6_IMPORT_FILE
        Type: File Browse
        Label: Select File
        Accept: .json, .csv
        Max Size: 10M
        Required: Yes (for import)
        
      - P6_REPLACE_EXISTING
        Type: Switch
        Label: Replace existing cases with same receipt number
        Default: N
        Help: If disabled, existing cases will be skipped
        
      - P6_IMPORT_PREVIEW
        Type: Display Only
        Label: Preview
        Template: Standard
        Read Only: Yes
        
    Buttons:
      - BTN_PREVIEW
        Label: Preview Import
        Icon: fa-eye
        Action: Submit (AJAX - populates preview)
        
      - BTN_IMPORT
        Label: Import Cases
        Icon: fa-upload
        Style: Hot
        Condition: P6_IMPORT_PREVIEW IS NOT NULL
        Confirm: Import selected cases?
        Action: Submit
        
  - Name: Import Progress
    Type: Static Content
    Position: Body (bottom)
    Template: Alert (Success)
    Condition: P6_IMPORT_RESULT IS NOT NULL
    Source: |
      <h3>Import Complete</h3>
      <p>Successfully imported <strong>&P6_IMPORTED_COUNT.</strong> cases.</p>
      <p><a href="f?p=&APP_ID.:2:&SESSION.">View your cases</a></p>

Processes:
  - Name: Validate Import File
    Type: PL/SQL
    When Button: BTN_PREVIEW or BTN_IMPORT
    Sequence: 5
    Point: Before Processing
    PL/SQL: |
      DECLARE
        l_blob      BLOB;
        l_mime_type VARCHAR2(255);
        l_filename  VARCHAR2(400);
        l_file_size NUMBER;
        c_max_size  CONSTANT NUMBER := 10 * 1024 * 1024; -- 10MB limit
      BEGIN
        -- Get file metadata from temp files
        BEGIN
          SELECT blob_content, mime_type, filename, DBMS_LOB.GETLENGTH(blob_content)
          INTO l_blob, l_mime_type, l_filename, l_file_size
          FROM apex_application_temp_files
          WHERE name = :P6_IMPORT_FILE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            apex_error.add_error(
              p_message          => 'No file uploaded. Please select a file to import.',
              p_display_location => apex_error.c_inline_with_field,
              p_page_item_name   => 'P6_IMPORT_FILE'
            );
            RETURN;
        END;
        
        -- Validate file size (10MB max)
        IF l_file_size > c_max_size THEN
          apex_error.add_error(
            p_message          => 'File size exceeds 10MB limit. Current size: ' || 
                                  ROUND(l_file_size / 1024 / 1024, 2) || 'MB',
            p_display_location => apex_error.c_inline_with_field,
            p_page_item_name   => 'P6_IMPORT_FILE'
          );
          RETURN;
        END IF;
        
        -- Validate MIME type matches file extension
        IF LOWER(l_filename) LIKE '%.json' THEN
          IF l_mime_type NOT IN ('application/json', 'text/json', 'text/plain') THEN
            apex_error.add_error(
              p_message          => 'Invalid MIME type for JSON file: ' || l_mime_type,
              p_display_location => apex_error.c_inline_with_field,
              p_page_item_name   => 'P6_IMPORT_FILE'
            );
            RETURN;
          END IF;
        ELSIF LOWER(l_filename) LIKE '%.csv' THEN
          IF l_mime_type NOT IN ('text/csv', 'text/plain', 'application/csv') THEN
            apex_error.add_error(
              p_message          => 'Invalid MIME type for CSV file: ' || l_mime_type,
              p_display_location => apex_error.c_inline_with_field,
              p_page_item_name   => 'P6_IMPORT_FILE'
            );
            RETURN;
          END IF;
        ELSE
          apex_error.add_error(
            p_message          => 'Unsupported file type. Please upload a .json or .csv file.',
            p_display_location => apex_error.c_inline_with_field,
            p_page_item_name   => 'P6_IMPORT_FILE'
          );
          RETURN;
        END IF;
        
        -- File is valid, continue processing
      END;
    Note: |
      SECURITY: This validation process runs BEFORE Import or Preview processing.
      It enforces:
      1. File size limit (10MB max)
      2. MIME type validation matching file extension
      3. Allowed file types (.json, .csv only)
      
  - Name: Export Cases
    Type: PL/SQL
    When Button: BTN_EXPORT
    PL/SQL: |
      DECLARE
        l_clob      CLOB;
        l_user      VARCHAR2(255) := V('APP_USER');
        l_client_ip VARCHAR2(50);
        l_xff       VARCHAR2(500);
        l_remote    VARCHAR2(50);
        -- TRUSTED PROXY CONFIGURATION
        -- Proxies are loaded from uscis_config table with key 'TRUSTED_PROXY_IPS'
        -- Format: comma-separated IP addresses (e.g., '203.0.113.1,203.0.113.2')
        -- To update: INSERT/UPDATE uscis_config SET config_value = '...' WHERE config_key = 'TRUSTED_PROXY_IPS'
        -- IMPORTANT: Obtain authoritative IPs from infrastructure/Terraform team before deployment
        l_trusted_proxy_csv VARCHAR2(4000);
        TYPE t_proxy_list IS TABLE OF VARCHAR2(50);
        l_trusted_proxies t_proxy_list := t_proxy_list();
        l_is_trusted_proxy BOOLEAN := FALSE;
        
        -- Strict IPv4 validation: each octet 0-255 (forward-declared for use in load_trusted_proxies)
        FUNCTION is_valid_ipv4(p_ip VARCHAR2) RETURN BOOLEAN IS
          l_parts APEX_T_VARCHAR2;
          l_octet NUMBER;
        BEGIN
          IF p_ip IS NULL OR NOT REGEXP_LIKE(p_ip, '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') THEN
            RETURN FALSE;
          END IF;
          l_parts := APEX_STRING.SPLIT(p_ip, '.');
          FOR i IN 1..4 LOOP
            l_octet := TO_NUMBER(l_parts(i));
            IF l_octet < 0 OR l_octet > 255 THEN RETURN FALSE; END IF;
          END LOOP;
          RETURN TRUE;
        EXCEPTION WHEN OTHERS THEN RETURN FALSE;
        END is_valid_ipv4;
        
        -- Robust IPv6 validation using Oracle's UTL_INADDR to validate
        -- Handles all valid forms: zero-compression (::), shortened segments, IPv4-mapped (::ffff:x.x.x.x)
        FUNCTION is_valid_ipv6(p_ip VARCHAR2) RETURN BOOLEAN IS
            l_result VARCHAR2(100);
        BEGIN
            IF p_ip IS NULL OR LENGTH(TRIM(p_ip)) = 0 THEN
                RETURN FALSE;
            END IF;
            -- UTL_INADDR.GET_HOST_ADDRESS validates IPv6 format when given a valid IPv6
            -- If the input is a valid IPv6 address, it returns the address; otherwise it raises an exception
            BEGIN
                l_result := UTL_INADDR.GET_HOST_ADDRESS(TRIM(p_ip));
                -- Check if result looks like IPv6 (contains colons)
                RETURN INSTR(l_result, ':') > 0 OR INSTR(TRIM(p_ip), ':') > 0;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Fallback: comprehensive regex for RFC-compliant IPv6
                    -- Covers: full form, zero-compression anywhere, IPv4-mapped addresses
                    RETURN REGEXP_LIKE(TRIM(p_ip), 
                        '^(' ||
                        -- Full form: 8 groups of 1-4 hex digits
                        '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|' ||
                        -- Leading :: with up to 7 groups
                        '::([0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}|' ||
                        -- :: only (all zeros)
                        '::|' ||
                        -- Groups before ::, groups after
                        '([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|' ||
                        '([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|' ||
                        '([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|' ||
                        '([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|' ||
                        '([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|' ||
                        '[0-9a-fA-F]{1,4}:(:[0-9a-fA-F]{1,4}){1,6}|' ||
                        -- Trailing ::
                        '([0-9a-fA-F]{1,4}:){1,7}:|' ||
                        -- IPv4-mapped: ::ffff:x.x.x.x
                        '::([fF]{4}:)?((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' ||
                        ')$');
            END;
        EXCEPTION
            WHEN OTHERS THEN RETURN FALSE;
        END is_valid_ipv6;
        
        -- Helper to parse comma-separated proxy IPs from config
        -- Includes validation: max CSV length, max proxy count, IP format checks
        PROCEDURE load_trusted_proxies IS
            l_idx NUMBER := 1;
            l_ip  VARCHAR2(50);
            c_max_csv_length CONSTANT NUMBER := 2000;  -- Max length of CSV string
            c_max_proxies    CONSTANT NUMBER := 50;    -- Max number of trusted proxies
        BEGIN
            l_trusted_proxy_csv := uscis_util_pkg.get_config('TRUSTED_PROXY_IPS', '');
            
            -- Enforce max CSV length for safety, truncating at last complete token boundary
            IF l_trusted_proxy_csv IS NOT NULL AND LENGTH(l_trusted_proxy_csv) > c_max_csv_length THEN
                DECLARE
                    l_truncated VARCHAR2(4000);
                    l_last_comma NUMBER;
                BEGIN
                    l_truncated := SUBSTR(l_trusted_proxy_csv, 1, c_max_csv_length);
                    l_last_comma := INSTR(l_truncated, ',', -1);  -- Search backwards for last comma
                    IF l_last_comma > 0 THEN
                        l_trusted_proxy_csv := SUBSTR(l_truncated, 1, l_last_comma - 1);
                        apex_debug.warn('TRUSTED_PROXY_IPS exceeds max length (%s), truncated to last complete token at position %s', c_max_csv_length, l_last_comma - 1);
                    ELSE
                        -- No comma found, cannot safely split - set to empty to avoid partial IP
                        l_trusted_proxy_csv := '';
                        apex_debug.warn('TRUSTED_PROXY_IPS exceeds max length (%s) with no comma boundary, cleared to empty', c_max_csv_length);
                    END IF;
                END;
            END IF;
            
            IF l_trusted_proxy_csv IS NOT NULL AND LENGTH(l_trusted_proxy_csv) > 0 THEN
                FOR proxy IN (
                    SELECT TRIM(REGEXP_SUBSTR(l_trusted_proxy_csv, '[^,]+', 1, LEVEL)) AS ip
                    FROM dual
                    CONNECT BY REGEXP_SUBSTR(l_trusted_proxy_csv, '[^,]+', 1, LEVEL) IS NOT NULL
                ) LOOP
                    -- Enforce max proxy count
                    IF l_idx > c_max_proxies THEN
                        apex_debug.warn('Exceeded max trusted proxies (%s), ignoring remaining', c_max_proxies);
                        EXIT;
                    END IF;
                    
                    l_ip := proxy.ip;
                    
                    -- Validate IP format before adding
                    IF is_valid_ipv4(l_ip) OR is_valid_ipv6(l_ip) THEN
                        l_trusted_proxies.EXTEND;
                        l_trusted_proxies(l_idx) := l_ip;
                        l_idx := l_idx + 1;
                    ELSE
                        apex_debug.warn('Invalid proxy IP format, skipping: %s', l_ip);
                    END IF;
                END LOOP;
            END IF;
        END load_trusted_proxies;
        
      BEGIN
        -- SECURITY: Get client IP with proper trusted proxy validation
        -- Load trusted proxies from uscis_config table
        load_trusted_proxies;
        
        l_remote := OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR');
        
        -- Check if REMOTE_ADDR is a trusted proxy
        FOR i IN 1..l_trusted_proxies.COUNT LOOP
          IF l_remote = l_trusted_proxies(i) THEN
            l_is_trusted_proxy := TRUE;
            EXIT;
          END IF;
        END LOOP;
        
        -- Only parse X-Forwarded-For if request came from trusted proxy
        IF l_is_trusted_proxy THEN
          l_xff := OWA_UTIL.GET_CGI_ENV('HTTP_X_FORWARDED_FOR');
          IF l_xff IS NOT NULL THEN
            -- X-Forwarded-For format: "client, proxy1, proxy2, ..."
            -- The leftmost IP is the original client
            l_client_ip := TRIM(REGEXP_SUBSTR(l_xff, '[^,]+', 1, 1));
            -- Validate IP format strictly
            IF NOT (is_valid_ipv4(l_client_ip) OR is_valid_ipv6(l_client_ip)) THEN
              l_client_ip := l_remote;  -- Fall back to proxy IP if invalid
            END IF;
          ELSE
            l_client_ip := l_remote;
          END IF;
        ELSE
          -- Not from trusted proxy: use REMOTE_ADDR directly (don't trust X-Forwarded-For)
          l_client_ip := l_remote;
        END IF;
        -- NOTE: Update TRUSTED_PROXY_IPS in uscis_config table with your actual proxy IPs
        
        -- SECURITY: Authorization check - ensure exports are scoped to current user's cases
        -- The export functions should internally filter by the current user
        -- Log audit entry for the export action
        -- NOTE: client_ip is anonymized (hashed) to avoid persisting raw PII
        -- The uscis_audit_pkg.purge_old_records procedure will also nullify
        -- any stored client_ip values older than the retention period (90 days)
        uscis_audit_pkg.log_event(
          p_receipt_number => NULL,  -- NULL indicates bulk operation
          p_action         => 'EXPORT',
          p_new_values     => JSON_OBJECT(
            'format' VALUE :P6_EXPORT_FORMAT,
            'filter' VALUE NVL(:P6_EXPORT_FILTER, 'ALL'),
            'include_history' VALUE :P6_INCLUDE_HISTORY,
            'exported_by' VALUE l_user,
            'client_ip_hash' VALUE RAWTOHEX(DBMS_CRYPTO.HASH(
              UTL_RAW.CAST_TO_RAW(l_client_ip || uscis_util_pkg.get_config('AUDIT_IP_SALT', 'default_salt')),
              DBMS_CRYPTO.HASH_SH256
            )),
            'timestamp' VALUE TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
          )
        );
        
        IF :P6_EXPORT_FORMAT = 'JSON' THEN
          -- Export functions MUST filter by current user (p_user => l_user)
          l_clob := uscis_export_pkg.export_cases_json(
            p_receipt_filter  => :P6_EXPORT_FILTER,
            p_include_history => :P6_INCLUDE_HISTORY = 'Y',
            p_user            => l_user  -- REQUIRED: Scope to current user
          );
        ELSE
          l_clob := uscis_export_pkg.export_cases_csv(
            p_receipt_filter => :P6_EXPORT_FILTER,
            p_user           => l_user  -- REQUIRED: Scope to current user
          );
        END IF;
        
        -- Trigger download
        owa_util.mime_header(
          CASE WHEN :P6_EXPORT_FORMAT = 'JSON' 
               THEN 'application/json' 
               ELSE 'text/csv' 
          END, 
          FALSE
        );
        htp.p('Content-Disposition: attachment; filename="uscis-cases-' || 
              TO_CHAR(SYSDATE, 'YYYYMMDD') || 
              CASE WHEN :P6_EXPORT_FORMAT = 'JSON' THEN '.json' ELSE '.csv' END || '"');
        owa_util.http_header_close;
        
        htp.prn(l_clob);
        apex_application.stop_apex_engine;
      END;
    Note: |
      SECURITY: Export authorization and auditing requirements:
      1. ALWAYS pass p_user parameter to scope exports to current user's cases only
      2. The export package functions MUST filter cases by the p_user parameter
      3. Every export MUST be logged via uscis_audit_pkg.log_event
      4. Log includes: format, filter, user, client IP, timestamp
      5. Update uscis_export_pkg.export_cases_json and export_cases_csv to:
         - Accept p_user parameter (required)
         - Filter WHERE created_by = p_user OR user has ADMIN role
         - Raise exception if unauthorized
      
  - Name: Preview Import
    Type: PL/SQL
    When Button: BTN_PREVIEW
    PL/SQL: |
      DECLARE
        l_blob BLOB;
        l_preview VARCHAR2(4000);
        l_count NUMBER;
      BEGIN
        -- Read uploaded file
        SELECT blob_content INTO l_blob
        FROM apex_application_temp_files
        WHERE name = :P6_IMPORT_FILE;
        
        -- Parse and generate preview
        -- (simplified - actual implementation would parse JSON/CSV)
        :P6_IMPORT_PREVIEW := 'File contains approximately ' || l_count || ' cases to import.';
      END;
      
  - Name: Import Cases
    Type: PL/SQL
    When Button: BTN_IMPORT
    Sequence: 20
    PL/SQL: |
      DECLARE
        l_blob        BLOB;
        l_clob        CLOB;
        l_count       NUMBER;
        l_user        VARCHAR2(255) := V('APP_USER');
        l_filename    VARCHAR2(400);
        l_errors      CLOB := '';
        l_error_count NUMBER := 0;
        c_max_records CONSTANT NUMBER := 1000;  -- Per-import record limit
        c_max_field_len CONSTANT NUMBER := 4000;  -- Max field length
      BEGIN
        -- Get file content
        SELECT blob_content, filename INTO l_blob, l_filename
        FROM apex_application_temp_files
        WHERE name = :P6_IMPORT_FILE;
        
        -- Convert BLOB to CLOB
        l_clob := apex_util.blob_to_clob(l_blob);
        
        -- SECURITY: Log import attempt
        uscis_audit_pkg.log_event(
          p_receipt_number => NULL,
          p_action         => 'IMPORT_START',
          p_new_values     => JSON_OBJECT(
            'filename' VALUE l_filename,
            'size_bytes' VALUE DBMS_LOB.GETLENGTH(l_blob),
            'imported_by' VALUE l_user,
            'replace_existing' VALUE :P6_REPLACE_EXISTING,
            'timestamp' VALUE TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
          )
        );
        
        -- SECURITY: Import with validation and per-record error handling
        -- The import_cases_json function MUST:
        -- 1. Parse JSON/CSV safely with graceful error handling for malformed data
        -- 2. Validate each record before insert (receipt number format, field lengths)
        -- 3. Sanitize all input values (strip control chars, validate encoding)
        -- 4. Enforce record limit (c_max_records) to prevent memory exhaustion
        -- 5. Enforce field length limits (c_max_field_len)
        -- 6. Return error details for failed records without stopping entire import
        l_count := uscis_export_pkg.import_cases_json(
          p_json_data        => l_clob,
          p_replace_existing => :P6_REPLACE_EXISTING = 'Y',
          p_user             => l_user,
          p_max_records      => c_max_records,
          p_max_field_length => c_max_field_len,
          p_error_log        => l_errors,
          p_error_count      => l_error_count
        );
        
        -- Log import completion
        uscis_audit_pkg.log_event(
          p_receipt_number => NULL,
          p_action         => 'IMPORT_COMPLETE',
          p_new_values     => JSON_OBJECT(
            'records_imported' VALUE l_count,
            'records_failed' VALUE l_error_count,
            'imported_by' VALUE l_user
          )
        );
        
        :P6_IMPORTED_COUNT := l_count;
        
        -- Show errors if any and set appropriate result status
        IF l_error_count > 0 THEN
          :P6_IMPORT_ERRORS := 'Warning: ' || l_error_count || 
            ' records failed to import. Check audit log for details.';
          -- Set partial success when some records failed
          IF l_count > 0 THEN
            :P6_IMPORT_RESULT := 'PARTIAL_SUCCESS';
          ELSE
            :P6_IMPORT_RESULT := 'COMPLETED_WITH_ERRORS';
          END IF;
        ELSE
          :P6_IMPORT_RESULT := 'SUCCESS';
        END IF;
        
        -- Clean up temp file with error handling
        BEGIN
          DELETE FROM apex_application_temp_files WHERE name = :P6_IMPORT_FILE;
        EXCEPTION
          WHEN OTHERS THEN
            -- Log cleanup error but don't fail the import
            uscis_util_pkg.log_error('Temp file cleanup failed: ' || SQLERRM);
        END;
        
      EXCEPTION
        WHEN OTHERS THEN
          :P6_IMPORT_RESULT := 'FAILED';
          uscis_util_pkg.log_error('Import failed: ' || SQLERRM);
          :P6_IMPORT_ERRORS := 'Import failed, please contact support';
          -- Always clean up temp file, even on error
          BEGIN
            DELETE FROM apex_application_temp_files WHERE name = :P6_IMPORT_FILE;
          EXCEPTION
            WHEN OTHERS THEN
              uscis_util_pkg.log_error('Temp file cleanup in exception failed: ' || SQLERRM);
          END;
          RAISE;
      END;
    Note: |
      SECURITY: Import cases validation requirements:
      1. File validation runs BEFORE this process (Validate Import File process)
      2. The import_cases_json function MUST implement:
         - Graceful JSON/CSV parsing with try/catch for malformed data
         - Per-record validation of receipt number format (using uscis_util_pkg.validate_receipt_number)
         - Field length limits (max 4000 chars per field)
         - Record count limit (max 1000 records per import to prevent memory exhaustion)
         - Input sanitization: strip control characters, validate UTF-8 encoding
         - Error collection: track failed records without stopping entire import
      3. All imports logged to audit trail with user, timestamp, file info
```

### 4.8 Page 7: Settings

```yaml
Page:
  Number: 7
  Name: Settings
  Title: Settings
  Mode: Normal
  Authorization: ADMIN_ROLE
  
Regions:
  - Name: API Configuration
    Type: Static Content
    Position: Body
    Template: Collapsible
    Title: USCIS API Configuration
    Items:
      - P7_API_MODE
        Type: Radio Group
        Label: API Mode
        LOV:
          - Sandbox (Testing)
          - Production
        Source: Config USCIS_API_MODE
        
      - P7_API_BASE_URL
        Type: Display Only
        Label: API Base URL
        Source: Computed based on P7_API_MODE
        
      - P7_HAS_CREDENTIALS
        Type: Display Only
        Label: Credentials Status
        Source: |
          CASE WHEN uscis_oauth_pkg.has_credentials 
               THEN '<span class="u-success">✓ Configured</span>'
               ELSE '<span class="u-danger">✗ Not configured</span>'
          END
          
      - P7_TEST_API
        Type: Button
        Label: Test API Connection
        Action: Execute AJAX + Show Result
        
  - Name: Scheduler Configuration
    Type: Static Content
    Position: Body
    Template: Collapsible
    Title: Automatic Status Checking
    Items:
      - P7_AUTO_CHECK_ENABLED
        Type: Switch
        Label: Enable automatic status checks
        Source: Config AUTO_CHECK_ENABLED
        
      - P7_AUTO_CHECK_INTERVAL
        Type: Select List
        Label: Check interval
        LOV:
          - Every 6 hours
          - Every 12 hours
          - Every 24 hours
          - Every 48 hours
          - Weekly
        Source: Config AUTO_CHECK_INTERVAL_HOURS
        Condition: P7_AUTO_CHECK_ENABLED = 'Y'
        
      - P7_AUTO_CHECK_BATCH_SIZE
        Type: Number Field
        Label: Cases per batch
        Source: Config AUTO_CHECK_BATCH_SIZE
        Condition: P7_AUTO_CHECK_ENABLED = 'Y'
        
      - P7_NEXT_RUN
        Type: Display Only
        Label: Next scheduled check
        Source: |
          SELECT TO_CHAR(next_run_date, 'Mon DD, YYYY HH:MI AM')
          FROM user_scheduler_jobs
          WHERE job_name = 'USCIS_AUTO_CHECK_JOB'
          
  - Name: Rate Limiting
    Type: Static Content
    Position: Body
    Template: Collapsible
    Title: Rate Limiting
    Items:
      - P7_RATE_LIMIT_RPS
        Type: Display Only
        Label: Requests per second
        Source: Config RATE_LIMIT_REQUESTS_PER_SECOND
        
      - P7_RATE_LIMIT_DAILY
        Type: Display Only
        Label: Daily quota
        Source: "400,000 requests"
        
      - P7_REQUESTS_TODAY
        Type: Display Only
        Label: Requests today
        Source: |
          SELECT request_count || ' / 400,000'
          FROM api_rate_limiter
          WHERE service_name = 'USCIS_CASE_STATUS'
            AND TRUNC(window_start) = TRUNC(SYSDATE)

Buttons:
  - Name: BTN_SAVE
    Label: Save Settings
    Position: Region (bottom)
    Style: Hot
    Action: Submit
    
Processes:
  - Name: Save Settings
    Type: PL/SQL
    PL/SQL: |
      BEGIN
        uscis_util_pkg.set_config('AUTO_CHECK_ENABLED', :P7_AUTO_CHECK_ENABLED);
        uscis_util_pkg.set_config('AUTO_CHECK_INTERVAL_HOURS', :P7_AUTO_CHECK_INTERVAL);
        uscis_util_pkg.set_config('AUTO_CHECK_BATCH_SIZE', :P7_AUTO_CHECK_BATCH_SIZE);
        
        -- Update scheduler job
        IF :P7_AUTO_CHECK_ENABLED = 'Y' THEN
          uscis_scheduler_pkg.create_auto_check_job(:P7_AUTO_CHECK_INTERVAL);
        ELSE
          uscis_scheduler_pkg.set_auto_check_enabled(FALSE);
        END IF;
        
        apex_util.set_session_state('P7_SAVED', 'Y');
      END;
```

### 4.9 Page 8: Administration

```yaml
Page:
  Number: 8
  Name: Administration
  Title: Administration
  Mode: Normal
  Authorization: ADMIN_ROLE
  Alias: admin
  
Regions:
  - Name: Admin Tabs
    Type: Region Display Selector
    Position: Body
    
    Sub-Regions:
      - Name: System Health
        Type: Static Content
        Template: Cards
        Source:
          SQL: |
            SELECT 
              'Database' AS component,
              'Healthy' AS status,
              'fa-database u-success' AS icon_class,
              (SELECT TO_CHAR(SUM(bytes)/1024/1024, '999,999') || ' MB' 
               FROM user_segments) AS detail
            FROM dual
            UNION ALL
            SELECT 
              'Scheduler Jobs',
              (SELECT DECODE(COUNT(*), 0, 'No jobs', 'Running') 
               FROM user_scheduler_running_jobs),
              'fa-clock-o u-info',
              (SELECT COUNT(*) || ' active jobs' FROM user_scheduler_jobs WHERE enabled = 'TRUE')
            FROM dual
            UNION ALL
            SELECT 
              'API Connection',
              CASE WHEN uscis_oauth_pkg.has_credentials THEN 'Configured' ELSE 'Not configured' END,
              CASE WHEN uscis_oauth_pkg.has_credentials THEN 'fa-plug u-success' ELSE 'fa-plug u-warning' END,
              (SELECT 'Token expires: ' || TO_CHAR(expires_at, 'HH:MI AM')
               FROM oauth_tokens WHERE service_name = 'USCIS_CASE_STATUS')
            FROM dual
            
      - Name: Audit Logs
        Type: Interactive Report
        Source:
          SQL: |
            SELECT 
              audit_id,
              performed_at,
              action,
              receipt_number,
              performed_by,
              ip_address,
              old_values,
              new_values
            FROM case_audit_log
            ORDER BY performed_at DESC
        Pagination: Scroll (100 rows)
        Download: Yes
        Search: Yes
        
        Column Groups:
          - When/Who: performed_at, performed_by, ip_address
          - What: action, receipt_number
          - Details: old_values, new_values
          
      - Name: Scheduler Jobs
        Type: Interactive Report
        Source:
          SQL: |
            SELECT 
              job_name,
              job_action,
              start_date,
              repeat_interval,
              next_run_date,
              last_start_date,
              last_run_duration,
              enabled,
              state
            FROM user_scheduler_jobs
            ORDER BY job_name
        
        Row Actions:
          - Run Now
          - Enable/Disable
          - View History
          
      - Name: User Sessions
        Type: Interactive Report
        Source:
          SQL: |
            SELECT 
              s.session_id,
              s.user_name,
              s.authentication_method,
              s.session_created,
              s.session_idle_timeout_on,
              s.remote_addr
            FROM apex_workspace_sessions s
            WHERE s.workspace_name = :WORKSPACE_NAME
            ORDER BY s.session_created DESC
        
Buttons:
  - Name: BTN_PURGE_AUDIT
    Label: Purge Old Audit Logs
    Region: Audit Logs
    Confirm: Delete audit logs older than 90 days?
    Action: Execute PL/SQL
    PL/SQL: uscis_audit_pkg.purge_old_records(90);
    
  - Name: BTN_CLEAR_TOKEN
    Label: Clear OAuth Token
    Region: System Health
    Confirm: Force token refresh?
    Action: Execute PL/SQL
    PL/SQL: uscis_oauth_pkg.clear_token;
```

---

## 5. Shared Components

### 5.1 Navigation Menu

```yaml
Navigation Menu:
  Name: Desktop Navigation Menu
  Template: Side Navigation Menu
  
  Entries:
    - Label: Dashboard
      Icon: fa-home
      Target: Page 1
      
    - Label: My Cases
      Icon: fa-briefcase
      Target: Page 2
      
    - Label: Import / Export
      Icon: fa-exchange
      Target: Page 6
      Authorization: USER_ROLE
      
    - Label: Settings
      Icon: fa-cog
      Target: Page 7
      Authorization: ADMIN_ROLE
      
    - Label: Administration
      Icon: fa-shield
      Target: Page 8
      Authorization: ADMIN_ROLE
```

### 5.2 Lists of Values

```yaml
LOVs:
  - Name: CASE_TYPES
    Type: Static
    Values:
      - I-130 (Petition for Alien Relative)
      - I-140 (Immigrant Petition for Alien Workers)
      - I-485 (Adjustment of Status)
      - I-539 (Change/Extend Nonimmigrant Status)
      - I-765 (Employment Authorization)
      - I-797 (Approval Notice)
      - I-821D (DACA)
      - N-400 (Naturalization)
      - Other

  - Name: CHECK_FREQUENCIES
    Type: Static
    Values:
      - display: Every 6 hours, return: 6
      - display: Every 12 hours, return: 12
      - display: Every 24 hours, return: 24
      - display: Every 48 hours, return: 48
      - display: Weekly, return: 168
      - display: Never, return: 0
      
  - Name: EXPORT_FORMATS
    Type: Static
    Values:
      - JSON
      - CSV
```

### 5.3 Templates

```yaml
Custom Templates:
  - Name: Case Card Template
    Type: Report
    Before Rows: <div class="case-cards">
    Row Template: |
      <div class="case-card">
        <div class="case-card__receipt receipt-number">#RECEIPT_NUMBER#</div>
        <div class="case-card__type">#CASE_TYPE#</div>
        <div class="case-card__status">
          <span class="status-badge js-status-text">#CURRENT_STATUS#</span>
        </div>
        <div class="case-card__updated">#LAST_UPDATED#</div>
      </div>
    After Rows: </div>
    
  - Name: Timeline Item Template
    Type: Report
    Row Template: |
      <div class="timeline-item #ITEM_CLASS#">
        <div class="timeline-icon"><span class="fa #EVENT_ICON#"></span></div>
        <div class="timeline-content">
          <div class="timeline-date">#EVENT_DATE#</div>
          <div class="timeline-status">#EVENT_TITLE#</div>
          <div class="timeline-details">#EVENT_DESCRIPTION#</div>
          <div class="timeline-source">#EVENT_SOURCE#</div>
        </div>
      </div>
```

### 5.4 Plug-ins

```yaml
Recommended Plugins:
  - Name: APEX-IG-Excel-Download
    Type: Dynamic Action
    Purpose: Enhanced Excel export for Interactive Grids
    Source: https://github.com/nicloay/APEX-IG-Excel-Download
    
  - Name: Pretius APEX Context Menu
    Type: Region
    Purpose: Right-click context menus
    
  - Name: APEX Clipboard
    Type: Dynamic Action
    Purpose: Copy to clipboard functionality
```

---

## 6. Mobile Responsiveness

### 6.1 Breakpoints

```css
/* Mobile-first breakpoints */
/* Extra small (phones) */
@media (max-width: 480px) { ... }

/* Small (large phones, small tablets) */
@media (min-width: 481px) and (max-width: 768px) { ... }

/* Medium (tablets) */
@media (min-width: 769px) and (max-width: 1024px) { ... }

/* Large (desktops) */
@media (min-width: 1025px) { ... }
```

### 6.2 Mobile Optimizations

| Feature        | Desktop       | Mobile                   |
|----------------|---------------|--------------------------|
| Navigation    | Side menu     | Hamburger menu           |
| Case List     | Interactive Grid | Cards layout            |
| Dashboard Cards| 4 columns     | 2 columns / stacked      |
| Forms         | Side labels   | Stacked labels           |
| Buttons       | Text + Icon   | Icon only (tooltips)     |
| Timeline | Vertical | Compact vertical |

### 6.3 PWA Configuration

```yaml
PWA:
  Enabled: Yes
  Name: USCIS Tracker
  Short Name: USCIS
  Description: Track your USCIS case status
  Theme Color: #003366
  Background Color: #ffffff
  Display: standalone
  Start URL: f?p=100:1
  
  Icons:
    - 192x192 PNG
    - 512x512 PNG
    
  Offline:
    Enabled: Yes
    Pages: Dashboard, Case List
    Message: "You're offline. Some features may be unavailable."
```

---

## 7. Accessibility

### 7.1 WCAG 2.1 AA Compliance

| Requirement       | Implementation                              |
|-------------------|---------------------------------------------|
| Color contrast   | Minimum 4.5:1 ratio                        |
| Focus indicators | Visible focus ring on all interactive elements |
| Keyboard navigation| All actions accessible via keyboard         |
| Screen readers   | ARIA labels on dynamic content              |
| Form labels      | All inputs have associated labels           |
| Error messages   | Associated with fields, announced to screen readers |
| Skip links       | Skip to main content link                   |

### 7.2 ARIA Attributes

```html
<!-- Status badges -->
<span class="status-badge" role="status" aria-label="Case status: Approved">
  Approved
</span>

<!-- Loading states -->
<div class="loading-state" role="alert" aria-live="polite" aria-busy="true">
  Loading...
</div>

<!-- Timeline -->
<ol class="status-timeline" role="list" aria-label="Status history">
  <li role="listitem">...</li>
</ol>

<!-- Modal dialogs -->
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Add Case</h2>
</div>
```

---

## 8. Wireframes

### 8.1 Dashboard (Desktop)

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ [Logo] USCIS Case Tracker                            [Search] [User ▼] [Logout] │
├──────────────┬──────────────────────────────────────────────────────────────────┤
│              │                                                                   │
│ ▣ Dashboard  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│              │  │    12    │ │    10    │ │    3     │ │    2     │            │
│ ▢ My Cases   │  │  Total   │ │  Active  │ │ Updated  │ │ Pending  │            │
│              │  │  Cases   │ │  Cases   │ │  Today   │ │  Check   │            │
│ ▢ Import/    │  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
│   Export     │                                                                   │
│              │  ┌─────────────────────────────┬─────────────────────────────┐   │
│ ─────────    │  │                             │                             │   │
│              │  │    Status Distribution      │     Recent Activity         │   │
│ ▢ Settings   │  │                             │                             │   │
│              │  │      ┌─────────┐           │  ● Added: IOE1234567890     │   │
│ ▢ Admin      │  │      │   ◕    │           │    2 minutes ago            │   │
│              │  │      │  Chart  │           │  ○ Checked: SRC0987654321   │   │
│              │  │      └─────────┘           │    15 minutes ago           │   │
│              │  │                             │  ○ Updated: EAC5432109876   │   │
│              │  │  ■ Approved (5)            │    1 hour ago               │   │
│              │  │  ■ Pending (4)             │                             │   │
│              │  │  ■ RFE (2)                 │                             │   │
│              │  │  ■ Other (1)               │                             │   │
│              │  └─────────────────────────────┴─────────────────────────────┘   │
│              │                                                                   │
│              │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│              │  │ + Add Case   │  │ 🔍 Check     │  │ 🔄 Refresh   │           │
│              │  │              │  │   Status     │  │   All        │           │
│              │  └──────────────┘  └──────────────┘  └──────────────┘           │
│              │                                                                   │
└──────────────┴──────────────────────────────────────────────────────────────────┘
```

### 8.2 Case List (Desktop)

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ [Logo] USCIS Case Tracker                            [Search] [User ▼] [Logout] │
├──────────────┬──────────────────────────────────────────────────────────────────┤
│              │  My Cases                                                         │
│ ▢ Dashboard  │  ─────────────────────────────────────────────────────────────── │
│              │  [+ Add Case]  [🔄 Refresh Selected]  [📥 Export]   🔍 Search... │
│ ▣ My Cases   │                                                                   │
│              │  ┌────────────┬────────────────┬──────────────┬─────────┬──────┐ │
│ ▢ Import/    │  │ Receipt #  │ Form Type      │ Status       │ Updated │ ⚙    │ │
│   Export     │  ├────────────┼────────────────┼──────────────┼─────────┼──────┤ │
│              │  │ ☐ IOE-1234-│ I-485          │ ▓ Approved   │ 2 days  │ ⋮    │ │
│ ─────────    │  │    567890  │ Adjustment     │              │ ago     │      │ │
│              │  ├────────────┼────────────────┼──────────────┼─────────┼──────┤ │
│ ▢ Settings   │  │ ☐ SRC-0987-│ I-140          │ ▓ Pending    │ 1 week  │ ⋮    │ │
│              │  │    654321  │ Immigrant Pet. │              │ ago     │      │ │
│ ▢ Admin      │  ├────────────┼────────────────┼──────────────┼─────────┼──────┤ │
│              │  │ ☑ EAC-5432-│ I-765          │ ▓ RFE        │ 3 days  │ ⋮    │ │
│              │  │    109876  │ Employment Auth│              │ ago     │      │ │
│              │  ├────────────┼────────────────┼──────────────┼─────────┼──────┤ │
│              │  │ ☐ LIN-1111-│ I-130          │ ▓ Received   │ Today   │ ⋮    │ │
│              │  │    222333  │ Alien Relative │              │         │      │ │
│              │  └────────────┴────────────────┴──────────────┴─────────┴──────┘ │
│              │                                                                   │
│              │  Showing 1-4 of 12 cases          [< 1 2 3 >]    Rows: [25 ▼]    │
│              │                                                                   │
└──────────────┴──────────────────────────────────────────────────────────────────┘
```

### 8.3 Case Details (Desktop)

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ [Logo] USCIS Case Tracker                            [Search] [User ▼] [Logout] │
├──────────────┬──────────────────────────────────────────────────────────────────┤
│              │  ← Back to Cases                                                  │
│ ▢ Dashboard  │                                                                   │
│              │  ╔═══════════════════════════════════════════════════════════╗   │
│ ▣ My Cases   │  ║  IOE-1234-567890                        [🔄] [🗑] [⏸]     ║   │
│              │  ║  ──────────────────────────────────────────────────────── ║   │
│ ▢ Import/    │  ║  I-485 (Adjustment of Status)                             ║   │
│   Export     │  ║                                                            ║   │
│              │  ║  ┌─────────────────────────────────────────────────────┐  ║   │
│ ─────────    │  ║  │               ▓▓▓▓▓ APPROVED ▓▓▓▓▓                 │  ║   │
│              │  ║  └─────────────────────────────────────────────────────┘  ║   │
│ ▢ Settings   │  ║  Last updated: January 15, 2026                           ║   │
│              │  ╚═══════════════════════════════════════════════════════════╝   │
│ ▢ Admin      │                                                                   │
│              │  ┌─────────────────────────────────┬─────────────────────────┐   │
│              │  │                                 │  [Notes] [Audit] [⚙]   │   │
│              │  │  Status History                 │ ─────────────────────── │   │
│              │  │  ───────────────                │                         │   │
│              │  │                                 │  Personal notes about   │   │
│              │  │  ● Jan 15, 2026                │  this case...           │   │
│              │  │    Case Was Approved            │                         │   │
│              │  │    We approved your I-485...    │  [Save Notes]           │   │
│              │  │                                 │                         │   │
│              │  │  ○ Dec 20, 2025                │                         │   │
│              │  │    Interview Scheduled          │                         │   │
│              │  │    Your interview is...         │                         │   │
│              │  │                                 │                         │   │
│              │  │  ○ Oct 5, 2025                 │                         │   │
│              │  │    Fingerprints Taken           │                         │   │
│              │  │    We received your...          │                         │   │
│              │  │                                 │                         │   │
│              │  │  ○ Aug 1, 2025                 │                         │   │
│              │  │    Case Was Received            │                         │   │
│              │  │    We received your Form...     │                         │   │
│              │  │                                 │                         │   │
│              │  └─────────────────────────────────┴─────────────────────────┘   │
│              │                                                                   │
└──────────────┴──────────────────────────────────────────────────────────────────┘
```

### 8.4 Mobile Views

```text
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│ ≡  USCIS Tracker  ⚙ │      │ ≡  My Cases      🔍 │      │ ←  IOE1234567890    │
├─────────────────────┤      ├─────────────────────┤      ├─────────────────────┤
│                     │      │ [+ Add]  [🔄 Refresh]│      │                     │
│   ┌───────────────┐ │      │                     │      │  I-485              │
│   │      12       │ │      │ ┌─────────────────┐ │      │  Adjustment of      │
│   │  Total Cases  │ │      │ │ IOE1234567890   │ │      │  Status             │
│   └───────────────┘ │      │ │ I-485           │ │      │                     │
│                     │      │ │ ▓ Approved      │ │      │ ┌─────────────────┐ │
│   ┌───────────────┐ │      │ │ 2 days ago      │ │      │ │    APPROVED     │ │
│   │      10       │ │      │ └─────────────────┘ │      │ └─────────────────┘ │
│   │ Active Cases  │ │      │                     │      │                     │
│   └───────────────┘ │      │ ┌─────────────────┐ │      │ Updated: Jan 15     │
│                     │      │ │ SRC0987654321   │ │      │                     │
│  ┌────────────────┐ │      │ │ I-140           │ │      │ ─────────────────── │
│  │   [◕]          │ │      │ │ ▓ Pending       │ │      │                     │
│  │  Status Chart  │ │      │ │ 1 week ago      │ │      │ ● Jan 15, 2026     │
│  └────────────────┘ │      │ └─────────────────┘ │      │   Approved          │
│                     │      │                     │      │                     │
│ Recent Activity     │      │ ┌─────────────────┐ │      │ ○ Dec 20, 2025     │
│ ● Added IOE...      │      │ │ EAC5432109876   │ │      │   Interview         │
│ ○ Checked SRC...    │      │ │ I-765           │ │      │                     │
│                     │      │ │ ▓ RFE           │ │      │ ○ Oct 5, 2025      │
│ ┌─────┐  ┌─────┐   │      │ │ 3 days ago      │ │      │   Fingerprints      │
│ │ +   │  │ 🔍  │   │      │ └─────────────────┘ │      │                     │
│ │ Add │  │Check│   │      │                     │      │ [🔄 Refresh] [🗑]   │
│ └─────┘  └─────┘   │      │      Load more...   │      │                     │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
     Dashboard                    Case List                  Case Details
```

---

## Document History

| Version | Date       | Author         | Changes      |
|---------|------------|----------------|---------------|
| 1.0    | 2026-02-03 | Migration Team | Initial design |

---

## End of APEX Frontend Design Document
