-- ============================================================
-- Page 3 Patch: Case Details → Template Components
-- ============================================================
-- File: page_patches/page_00003_patch.sql
--
-- PREREQUISITE:
--   Run scripts/fix_missing_columns.sql FIRST to add
--   check_frequency and notifications_enabled to case_history
--   and recreate dependent views.
--
-- Changes:
--   0. Fix "Load Case Data" process (ORA-00904 on NOTIFICATIONS_ENABLED)
--   1. Add hidden items P3_STATUS_CATEGORY, P3_STATUS_ICON, P3_ACTIVE_TAG_CLASS
--   2. Before Header process: Replace CASE with package call
--   3. Case Information region: Use USCIS Case Card template
--   4. Inline CSS: Remove badge styles (now in static file)
--
-- Apply via: Page Designer (recommended)
-- ============================================================

-- ============================================================
-- CHANGE 0: Fix "Load Case Data" process (Before Header)
-- ============================================================
-- The current process selects check_frequency and
-- notifications_enabled from v_case_current_status, but these
-- columns may not exist in the deployed schema.
--
-- OPTION A (preferred): Run scripts/fix_missing_columns.sql
--   to add the missing columns and recreate views. The existing
--   process will then work as-is.
--
-- OPTION B (defensive): Replace the SELECT in "Load Case Data"
--   with the version below, which uses NVL on the subquery so
--   the page works even if the columns are later dropped.
--
-- In Page Designer → Page 3 → Processing → "Load Case Data":
-- Replace the SELECT ... INTO block with:

/*
    SELECT
      NVL(case_type, 'Unknown'),
      NVL(current_status, 'Unknown'),
      NVL(TO_CHAR(last_updated, 'Mon DD, YYYY HH12":"MI AM'), 'N/A'),
      NVL(TO_CHAR(tracking_since, 'Mon DD, YYYY'), 'N/A'),
      CASE WHEN NVL(is_active, 1) = 1 THEN 'Y' ELSE 'N' END,
      notes,
      NVL(check_frequency, 24),
      CASE WHEN NVL(notifications_enabled, 0) = 1 THEN 'Y' ELSE 'N' END
    INTO
      :P3_CASE_TYPE,
      :P3_CURRENT_STATUS,
      :P3_LAST_UPDATED,
      :P3_TRACKING_SINCE,
      :P3_IS_ACTIVE,
      :P3_NOTES,
      :P3_CHECK_FREQUENCY,
      :P3_NOTIFICATIONS
    FROM v_case_current_status
    WHERE receipt_number = l_receipt;
*/
-- NOTE: This SELECT is valid once scripts/fix_missing_columns.sql
-- has been applied. If you cannot alter the schema, remove the
-- check_frequency and notifications_enabled lines and their
-- corresponding :P3_CHECK_FREQUENCY / :P3_NOTIFICATIONS targets.

-- ============================================================
-- CHANGE 1: Add new hidden page items
-- ============================================================
-- In Page Designer → Page 3 → add these hidden items:
--
--   P3_STATUS_CATEGORY  (Hidden, Value Protected: Yes)
--   P3_STATUS_ICON      (Hidden, Value Protected: Yes)
--   P3_ACTIVE_TAG_CLASS (Hidden, Value Protected: Yes)

-- ============================================================
-- CHANGE 2: Updated Before Header PL/SQL process
-- ============================================================
-- Replace the status classification CASE block with centralized
-- package calls. The existing P3_STATUS_CLASS item is kept for
-- backward compatibility but is now derived from the category.

/*
-- FIND AND REPLACE this section in the Before Header process:

-- OLD CODE (approximately lines 784-830):
  -- Status CSS class (use raw value for matching)
  :P3_STATUS_CLASS := CASE
    WHEN UPPER(l_raw_status) LIKE '%NOT APPROVED%'
      OR UPPER(l_raw_status) LIKE '%DENIED%'
      OR UPPER(l_raw_status) LIKE '%REJECT%'
      OR UPPER(l_raw_status) LIKE '%TERMINATED%'
      OR UPPER(l_raw_status) LIKE '%WITHDRAWN%'
      OR UPPER(l_raw_status) LIKE '%REVOKED%' THEN 'status-denied'
    WHEN UPPER(l_raw_status) LIKE '%APPROVED%'
      OR UPPER(l_raw_status) LIKE '%CARD%PRODUCED%'
      OR UPPER(l_raw_status) LIKE '%CARD%BEING PRODUCED%'
      OR UPPER(l_raw_status) LIKE '%CARD%DELIVERED%'
      OR UPPER(l_raw_status) LIKE '%CARD%MAILED%'
      OR UPPER(l_raw_status) LIKE '%CARD%PICKED UP%'
      OR UPPER(l_raw_status) LIKE '%OATH CEREMONY%'
      OR UPPER(l_raw_status) LIKE '%WELCOME NOTICE%' THEN 'status-approved'
    WHEN UPPER(l_raw_status) LIKE '%RFE%'
      OR UPPER(l_raw_status) LIKE '%EVIDENCE%' THEN 'status-rfe'
    WHEN UPPER(l_raw_status) LIKE '%RECEIVED%'
      OR UPPER(l_raw_status) LIKE '%ACCEPTED%'
      OR UPPER(l_raw_status) LIKE '%FEE WAS%' THEN 'status-received'
    WHEN UPPER(l_raw_status) LIKE '%PENDING%'
      OR UPPER(l_raw_status) LIKE '%REVIEW%'
      OR UPPER(l_raw_status) LIKE '%FINGERPRINT%'
      OR UPPER(l_raw_status) LIKE '%INTERVIEW%'
      OR UPPER(l_raw_status) LIKE '%PROCESSING%'
      OR UPPER(l_raw_status) LIKE '%SCHEDULED%' THEN 'status-pending'
    WHEN UPPER(l_raw_status) LIKE '%TRANSFERRED%'
      OR UPPER(l_raw_status) LIKE '%RELOCATED%'
      OR UPPER(l_raw_status) LIKE '%SENT TO%' THEN 'status-pending'
    ELSE 'status-unknown'
  END;

  -- Active display
  :P3_ACTIVE_DISPLAY := CASE WHEN :P3_IS_ACTIVE = 'Y'
    THEN 'Active' ELSE 'Inactive' END;
  :P3_ACTIVE_CLASS := CASE WHEN :P3_IS_ACTIVE = 'Y'
    THEN 'active-tag' ELSE 'inactive-tag' END;


-- NEW CODE (replace with):
  -- Template Component: Centralized status classification (P7)
  :P3_STATUS_CATEGORY := uscis_template_components_pkg.get_status_category(l_raw_status);
  :P3_STATUS_ICON     := uscis_template_components_pkg.get_status_icon(:P3_STATUS_CATEGORY);
  -- Backward compat: keep P3_STATUS_CLASS derived from category
  :P3_STATUS_CLASS    := 'status-' || :P3_STATUS_CATEGORY;

  -- Active display using Template Component class names
  :P3_ACTIVE_DISPLAY   := CASE WHEN :P3_IS_ACTIVE = 'Y' THEN 'Active' ELSE 'Inactive' END;
  :P3_ACTIVE_CLASS     := CASE WHEN :P3_IS_ACTIVE = 'Y' THEN 'active-tag' ELSE 'inactive-tag' END;
  :P3_ACTIVE_TAG_CLASS := CASE WHEN :P3_IS_ACTIVE = 'Y' THEN 'active' ELSE 'inactive' END;
*/

-- ============================================================
-- CHANGE 3: Updated "Case Information" region source HTML
-- ============================================================
-- In Page Designer → Case Information region → Source → HTML:

/*
-- OLD REGION SOURCE:
<div class="case-detail-card">
  <div class="case-header-row">
    <div class="case-receipt-info">
      <span class="receipt-number">&P3_RECEIPT_NUMBER.</span>
      <span class="&P3_ACTIVE_CLASS.">&P3_ACTIVE_DISPLAY.</span>
    </div>
    <div class="case-status-display">
      <span class="status-badge &P3_STATUS_CLASS.">&P3_CURRENT_STATUS.</span>
    </div>
  </div>
  <div class="case-info-grid">
    <div class="info-item">
      <span class="info-label">Case Type</span>
      <span class="info-value">&P3_CASE_TYPE.</span>
    </div>
    <div class="info-item">
      <span class="info-label">Last Updated</span>
      <span class="info-value">&P3_LAST_UPDATED.</span>
    </div>
    <div class="info-item">
      <span class="info-label">Tracking Since</span>
      <span class="info-value">&P3_TRACKING_SINCE.</span>
    </div>
    <div class="info-item">
      <span class="info-label">Notes</span>
      <span class="info-value">&P3_NOTES.</span>
    </div>
  </div>
</div>


-- NEW REGION SOURCE (Template Component: USCIS Case Card):
<div class="uscis-case-card">
  <div class="uscis-case-card__header">
    <div class="uscis-case-card__receipt-info">
      <span class="uscis-case-card__receipt">&P3_RECEIPT_NUMBER.</span>
      <span class="uscis-case-card__active-tag uscis-case-card__active-tag--&P3_ACTIVE_TAG_CLASS.">&P3_ACTIVE_DISPLAY.</span>
    </div>
    <div>
      <span class="uscis-badge uscis-badge--solid uscis-badge--&P3_STATUS_CATEGORY.">
        <span class="t-Icon fa &P3_STATUS_ICON. uscis-badge-icon"></span>
        &P3_CURRENT_STATUS.
      </span>
    </div>
  </div>
  <div class="uscis-case-card__info-grid">
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Case Type</span>
      <span class="uscis-case-card__value">&P3_CASE_TYPE.</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Last Updated</span>
      <span class="uscis-case-card__value">&P3_LAST_UPDATED.</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Tracking Since</span>
      <span class="uscis-case-card__value">&P3_TRACKING_SINCE.</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Notes</span>
      <span class="uscis-case-card__value">&P3_NOTES.</span>
    </div>
  </div>
</div>
*/

-- ============================================================
-- CHANGE 4: Simplified Inline CSS
-- ============================================================
-- Remove status-badge, receipt-number, active-tag,
-- inactive-tag, case-detail-card, case-header-row, etc.
-- Keep only layout styles not covered by template_components.css:

/*
-- NEW inline CSS for Page 3 (replace existing):

/* Status History Table */
.status-history-table {
  width: 100%;
  border-collapse: collapse;
}
.status-history-table th {
  padding: 8px;
  text-align: left;
  border-bottom: 2px solid var(--ut-component-border-color, #e0e0e0);
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--ut-component-text-muted-color, #666);
}
.status-history-table td {
  padding: 8px;
  border-bottom: 1px solid var(--ut-component-border-color, #f0f0f0);
  font-size: 13px;
}

/* Audit Trail Table */
.audit-history-table {
  width: 100%;
  border-collapse: collapse;
}
.audit-history-table th {
  padding: 8px;
  text-align: left;
  border-bottom: 2px solid var(--ut-component-border-color, #e0e0e0);
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--ut-component-text-muted-color, #666);
}
.audit-history-table td {
  padding: 8px;
  border-bottom: 1px solid var(--ut-component-border-color, #f0f0f0);
  font-size: 13px;
  vertical-align: top;
}
.audit-history-table .audit-values {
  max-width: 280px;
  word-break: break-word;
}
*/

PROMPT ============================================================
PROMPT Page 3 patch documented. Apply changes in Page Designer.
PROMPT ============================================================
