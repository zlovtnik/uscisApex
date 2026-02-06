-- ============================================================
-- Page 22 Patch: My Cases IG → Template Components
-- ============================================================
-- File: page_patches/page_00022_patch.sql
--
-- Changes:
--   1. IG query: Replace inline CASE with package function call
--   2. CURRENT_STATUS column: New badge HTML Expression
--   3. RECEIPT_NUMBER column: New receipt link class
--   4. Inline CSS: Simplified (badge styles now in static file)
--
-- Apply via: Page Designer (recommended) or re-export after edit
-- ============================================================

-- ============================================================
-- CHANGE 1: Updated IG SQL Query
-- ============================================================
-- Replace the source SQL of the "Case List" IG region.
-- The CASE expression for status_class is replaced by
-- two function calls that return status_category and status_icon.

/*
-- OLD STATUS COLUMNS (remove these):
    CASE
        WHEN UPPER(v.current_status) LIKE '%DENIED%' OR UPPER(v.current_status) LIKE '%NOT APPROVED%' OR UPPER(v.current_status) LIKE '%REJECT%' OR UPPER(v.current_status) LIKE '%TERMINAT%' OR UPPER(v.current_status) LIKE '%WITHDRAWN%' OR UPPER(v.current_status) LIKE '%REVOKED%' THEN 'denied'
        WHEN UPPER(v.current_status) LIKE '%APPROVED%' OR UPPER(v.current_status) LIKE '%CARD WAS PRODUCED%' OR UPPER(v.current_status) LIKE '%CARD IS BEING PRODUCED%' OR UPPER(v.current_status) LIKE '%CARD WAS DELIVERED%' OR UPPER(v.current_status) LIKE '%CARD WAS MAILED%' OR UPPER(v.current_status) LIKE '%CARD WAS PICKED UP%' OR UPPER(v.current_status) LIKE '%OATH CEREMONY%' OR UPPER(v.current_status) LIKE '%WELCOME NOTICE%' THEN 'approved'
        WHEN UPPER(v.current_status) LIKE '%EVIDENCE%' OR UPPER(v.current_status) LIKE '%RFE%' THEN 'rfe'
        WHEN UPPER(v.current_status) LIKE '%RECEIVED%' OR UPPER(v.current_status) LIKE '%ACCEPTED%' OR UPPER(v.current_status) LIKE '%FEE%' THEN 'received'
        WHEN UPPER(v.current_status) LIKE '%FINGERPRINT%' OR UPPER(v.current_status) LIKE '%INTERVIEW%' OR UPPER(v.current_status) LIKE '%PROCESSING%' OR UPPER(v.current_status) LIKE '%REVIEW%' OR UPPER(v.current_status) LIKE '%PENDING%' OR UPPER(v.current_status) LIKE '%SCHEDULED%' THEN 'pending'
        WHEN UPPER(v.current_status) LIKE '%TRANSFER%' THEN 'transferred'
        ELSE 'unknown'
    END AS status_class,

-- NEW STATUS COLUMNS (add these):
    uscis_template_components_pkg.get_status_category(v.current_status) AS status_category,
    uscis_template_components_pkg.get_status_icon(
        uscis_template_components_pkg.get_status_category(v.current_status)
    ) AS status_icon,
*/

-- Full updated query for copy-paste into Page Designer:
-- ============================================================
/*
SELECT 
    ch.ROWID AS row_id,
    v.receipt_number,
    v.case_type,
    APEX_ESCAPE.HTML(v.current_status) AS current_status,
    v.last_updated,
    v.tracking_since,
    ch.is_active,
    ch.notes,
    v.total_updates,
    v.last_update_source,
    v.check_frequency,
    v.last_checked_at,
    v.created_by,
    v.days_since_update,
    NVL(TO_CHAR(v.hours_since_check) || ' hrs ago', 'Never') AS last_check_display,
    -- Template Component: centralized status classification (P7)
    uscis_template_components_pkg.get_status_category(v.current_status) AS status_category,
    uscis_template_components_pkg.get_status_icon(
        uscis_template_components_pkg.get_status_category(v.current_status)
    ) AS status_icon,
    APEX_PAGE.GET_URL(p_page => 3, p_items => 'P3_RECEIPT_NUMBER', p_values => v.receipt_number) AS detail_url
FROM v_case_current_status v
JOIN case_history ch ON ch.receipt_number = v.receipt_number
WHERE (NVL(:P22_ACTIVE_FILTER, 'ALL') = 'ALL' 
       OR (NVL(:P22_ACTIVE_FILTER, 'ALL') = 'ACTIVE' AND ch.is_active = 1)
       OR (NVL(:P22_ACTIVE_FILTER, 'ALL') = 'INACTIVE' AND ch.is_active = 0))
  AND (NVL(:P22_STATUS_FILTER, 'ALL') = 'ALL' OR v.current_status = :P22_STATUS_FILTER)
  AND (:P22_RECEIPT_SEARCH IS NULL OR UPPER(v.receipt_number) LIKE '%' || UPPER(:P22_RECEIPT_SEARCH) || '%')
ORDER BY v.last_updated DESC NULLS LAST
*/

-- ============================================================
-- CHANGE 2: CURRENT_STATUS column HTML Expression
-- ============================================================
-- In Page Designer → Case List IG → Columns → CURRENT_STATUS
-- → Column Attributes → HTML Expression:

/*
-- OLD:
<span class="status-badge status-&STATUS_CLASS.">&CURRENT_STATUS.</span>

-- NEW (Template Component badge with icon):
<span class="uscis-badge uscis-badge--&STATUS_CATEGORY."><span class="t-Icon fa &STATUS_ICON. uscis-badge-icon"></span>&CURRENT_STATUS.</span>
*/

-- ============================================================
-- CHANGE 3: RECEIPT_NUMBER column HTML Expression
-- ============================================================
-- In Page Designer → Case List IG → Columns → RECEIPT_NUMBER
-- → Column Attributes → HTML Expression:

/*
-- OLD:
<a href="&DETAIL_URL." class="receipt-link">&RECEIPT_NUMBER.</a>

-- NEW:
<a href="&DETAIL_URL." class="uscis-receipt-link">&RECEIPT_NUMBER.</a>
*/

-- ============================================================
-- CHANGE 4: Add hidden IG columns for STATUS_CATEGORY and STATUS_ICON
-- ============================================================
-- In Page Designer → Case List IG → right-click Columns → 
-- Create Column:
--   Name: STATUS_CATEGORY
--   Type: Display Only
--   Source: DB Column → STATUS_CATEGORY
--   Visible: No (hidden column, used by HTML Expression)
--
--   Name: STATUS_ICON
--   Type: Display Only
--   Source: DB Column → STATUS_ICON
--   Visible: No (hidden column, used by HTML Expression)

-- ============================================================
-- CHANGE 5: Simplified Inline CSS
-- ============================================================
-- Most badge CSS is now in the global static file.
-- Keep only page-specific styles in inline CSS:

-- NEW inline CSS for Page 22 (replace existing):
-- Page-specific overrides only — badge styles in template_components.css
--
-- .ig-row-inactive {
--   opacity: 0.6;
-- }
--
-- /* Toolbar Button Enhancements */
-- .case-list-toolbar .a-Button--hot {
--   margin-left: 8px;
-- }
--
-- /* Filter Region Styling */
-- .case-filters {
--   padding: 12px 16px;
--   background: var(--ut-region-background-color, #f5f5f5);
--   border-bottom: 1px solid var(--ut-component-border-color, #e0e0e0);
--   display: flex;
--   gap: 16px;
--   flex-wrap: wrap;
--   align-items: flex-end;
-- }
-- .case-filters .t-Form-fieldContainer {
--   margin-bottom: 0;
-- }

PROMPT ============================================================
PROMPT Page 22 patch documented. Apply changes in Page Designer.
PROMPT ============================================================
