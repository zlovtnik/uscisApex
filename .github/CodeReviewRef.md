# APEX 24.2 Quick Reference Guide

**For:** USCIS Case Tracker Development Team  
**Date:** February 6, 2026

---

## Before vs. After Patterns (Quick Reference)

### 1. Static File Upload

❌ **AVOID (Internal API):**
```sql
wwv_flow_imp.create_app_static_file(
    p_id => wwv_flow_id.next_val,
    p_flow_id => l_app_id,
    p_file_name => 'app.css',
    p_file_content => l_blob
);
```

✅ **USE (Public API):**
```sql
wwv_flow_api.create_app_static_file(
    p_flow_id => l_app_id,
    p_file_name => 'app.css',
    p_file_content => l_blob
);
```

---

### 2. Session Initialization

❌ **AVOID (Incomplete):**
```sql
apex_util.set_security_group_id(l_workspace_id);
```

✅ **USE (Full Context):**
```sql
apex_session.create_session(
    p_app_id   => l_app_id,
    p_page_id  => 1,
    p_username => 'ADMIN'
);
-- ... operations ...
apex_session.delete_session;
```

---

### 3. CSS Customization

❌ **AVOID (!important Overrides):**
```css
.t-Header {
    background: #0f172a !important;
    color: white !important;
}
```

✅ **USE (CSS Variables):**
```css
:root {
    --ut-header-background-color: #0f172a;
    --ut-palette-primary-contrast: white;
}
```

---

### 4. Notifications

❌ **AVOID (Custom DOM):**
```javascript
function showToast(msg, type) {
    const div = document.createElement('div');
    div.className = 'custom-toast';
    document.body.appendChild(div);
}
```

✅ **USE (Native API):**
```javascript
apex.message.showPageSuccess('Operation complete');
apex.message.showErrors([{
    type: 'error',
    message: 'Operation failed'
}]);
```

---

### 5. Status Badges

❌ **AVOID (Custom CSS + JS):**
```css
.status-approved { background: green; }
.status-denied { background: red; }
```
```javascript
function getStatusClass(status) {
    if (status.includes('APPROVED')) return 'approved';
    // ... 10+ checks
}
```

✅ **USE (Template Component):**
```html
<!-- Shared Components → Template Components -->
<span class="u-pill {case STATUS/}
    {when APPROVED/}u-success
    {when DENIED/}u-danger
    {otherwise/}u-color-7
{endcase/}">
    <span class="u-pill-label">#STATUS#</span>
</span>
```

---

### 6. JavaScript Initialization

❌ **AVOID (Legacy Event):**
```javascript
apex.jQuery(document).on('apexreadyend', function() {
    init();
});
```

✅ **USE (Modern Pattern):**
```javascript
apex.jQuery(function() {
    init();
});
// Or:
apex.page.ready(function() {
    init();
});
```

---

### 7. Global Functions

❌ **AVOID (Namespace Pollution):**
```javascript
function formatReceipt(r) { ... }
function validateReceipt(r) { ... }
```

✅ **USE (IIFE Module):**
```javascript
(function(apex, $) {
    "use strict";
    
    function formatReceipt(r) { ... }
    
    window.USCIS = {
        formatReceipt: formatReceipt
    };
})(apex, apex.jQuery);

// Usage:
USCIS.formatReceipt('IOE1234567890');
```

---

### 8. SQL Injection Prevention

❌ **AVOID (Substitution Strings):**
```sql
-- Row Action PL/SQL:
BEGIN
    delete_case('#RECEIPT_NUMBER#');
END;
```

✅ **USE (Bind Variables):**
```yaml
# Row Action "Set Items":
P2_SELECTED_RECEIPT = #RECEIPT_NUMBER#

# Row Action PL/SQL:
BEGIN
    delete_case(:P2_SELECTED_RECEIPT);
END;
```

---

### 9. XSS Prevention

❌ **AVOID (Raw Output):**
```sql
RETURN '<div>' || user_input || '</div>';
```

✅ **USE (Escaped Output):**
```sql
RETURN '<div>' || APEX_ESCAPE.HTML(user_input) || '</div>';
```

For columns:
```yaml
Column Settings:
    Security > Escape Special Characters: Yes
```

---

### 10. LOB Management

❌ **AVOID (Memory Leak):**
```sql
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
    -- ... operations ...
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
```

✅ **USE (Proper Cleanup):**
```sql
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
    -- ... operations ...
    IF DBMS_LOB.ISTEMPORARY(l_blob) = 1 THEN
        DBMS_LOB.FREETEMPORARY(l_blob);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            IF l_blob IS NOT NULL AND 
               DBMS_LOB.ISTEMPORARY(l_blob) = 1 THEN
                DBMS_LOB.FREETEMPORARY(l_blob);
            END IF;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        ROLLBACK;
        RAISE;
END;
```

---

## Universal Theme Utility Classes (APEX 24.2)

### Colors (Built-in, Dark Mode Compatible)

| Class | Color | Use Case |
|-------|-------|----------|
| `u-success` | Green | Approved, Completed |
| `u-danger` | Red | Denied, Error |
| `u-warning` | Amber | Pending, Warning |
| `u-info` | Blue | Information, RFE |
| `u-color-14` | Purple | Custom (Received) |
| `u-color-7` | Gray | Unknown, Inactive |

### Pills/Badges

```html
<span class="u-pill u-success">
    <span class="u-pill-label">Approved</span>
</span>
```

---

## CSS Custom Properties Reference

### Primary Colors
```css
--ut-palette-primary          /* Main brand color */
--ut-palette-primary-contrast /* Text on primary */
--ut-palette-primary-shade    /* Darker variant */
```

### Component Colors
```css
--ut-header-background-color
--ut-nav-background-color
--ut-login-background-color
--ut-body-content-background-color
--ut-focus-outline-color
--ut-link-text-color
```

### Full list: APEX Builder → Theme Roller → CSS Variables tab

---

## Security Checklist

### Every PL/SQL Process
- [ ] Uses bind variables (`:ITEM`), never substitution strings (`#ITEM#`)
- [ ] Escapes HTML output with `APEX_ESCAPE.HTML()`
- [ ] Has authorization scheme assigned
- [ ] Validates input format
- [ ] Logs sensitive operations to audit

### Every JavaScript Function
- [ ] Wrapped in IIFE or module
- [ ] Escapes user input with `apex.util.escapeHTML()`
- [ ] Uses `textContent` over `innerHTML` when possible
- [ ] No `eval()` or `new Function()`
- [ ] No inline event handlers

### Every Interactive Grid/Report Column
- [ ] "Escape Special Characters" enabled
- [ ] Link targets validated
- [ ] Authorization on sensitive columns
- [ ] No direct HTML concatenation

---

## Common Mistakes

### ❌ Mistake: Forgetting to escape in Template Components
```html
<!-- WRONG -->
<span class="label">#USER_INPUT#</span>

<!-- RIGHT -->
<span class="label">&USER_INPUT.</span>
```

### ❌ Mistake: Using app ID in links
```javascript
// WRONG
apex.navigation.redirect('f?p=102:1:' + sessionId);

// RIGHT
apex.navigation.redirect('f?p=' + $v('pFlowId') + ':1:' + sessionId);
```

### ❌ Mistake: Hardcoding APEX session
```javascript
// WRONG
var session = '12345678901234';

// RIGHT
var session = $v('pInstance');
```

---

## Useful APEX 24.2 APIs

### Navigation
```javascript
apex.navigation.redirect('f?p=&APP_ID.:1:&SESSION.');
apex.navigation.dialog('f?p=&APP_ID.:4:&SESSION.', ...);
apex.page.submit('SAVE');
```

### Messages
```javascript
apex.message.showPageSuccess('Saved successfully');
apex.message.showErrors([{type:'error', message:'...'}]);
apex.message.clearErrors();
```

### Regions
```javascript
apex.region('myRegion').refresh();
apex.region('myGrid').widget().interactiveGrid('getViews', 'grid').model.clearChanges();
```

### Items
```javascript
apex.item('P1_NAME').setValue('John');
apex.item('P1_NAME').getValue();
apex.item('P1_NAME').disable();
apex.item('P1_NAME').show();
```

---

## Testing Commands

### SQL Injection Test
```
Input: '; DROP TABLE case_history; --
Expected: Error or escaped output
```

### XSS Test
```
Input: <script>alert('XSS')</script>
Expected: Rendered as text, not executed
```

### Authorization Test
```
1. Login as regular user
2. Try accessing admin page via URL
Expected: Redirect to unauthorized page
```

---

## Resources

- **APEX Documentation:** https://docs.oracle.com/en/database/oracle/apex/
- **Universal Theme:** Builder → Shared Components → Themes → Universal Theme
- **Theme Roller:** Developer Toolbar → Theme Roller
- **CSS Variables:** Theme Roller → CSS Variables tab
- **Review Standards:** APEX_24_REVIEW.md

---

**Last Updated:** February 6, 2026  
**For Questions:** See APEX_24_CODE_REVIEW.md