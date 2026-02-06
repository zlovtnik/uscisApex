-- ============================================================
-- USCIS Case Tracker - Page Updates for Template Components
-- ============================================================
-- File: scripts/apply_template_components.sql
--
-- Purpose:
--   Master script that applies Template Component patterns to
--   all three main pages. Run this AFTER:
--     1. packages/09_uscis_template_components_pkg.sql
--     2. scripts/upload_template_component_files.sql
--
-- What changes:
--   Page 0 (Global Page)    — Add CSS/JS file references
--   Page 1 (Dashboard)      — Use Metric Card template + centralized colors
--   Page 3 (Case Details)   — Use Case Card template + centralized status class
--   Page 22 (My Cases IG)   — Use Badge template + centralized status_category
--
-- IMPORTANT: These changes are applied via APEX_PAGE APIs where
-- possible, or documented as Page Designer changes where APIs
-- don't support direct modification.
--
-- Follows: APEX_CONTEXTUAL_ANCHOR.md P1, P2, P7, P8
-- ============================================================

SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Applying Template Component updates to pages...
PROMPT ============================================================

-- ============================================================
-- STEP 1: Add CSS/JS references to Global Page (Page 0)
-- ============================================================
-- NOTE: Global Page file references should be added via
-- Page Designer or the APEX export/import process.
-- The references to add are:
--
--   Page Properties → CSS → File URLs:
--     #APP_FILES#template_components#MIN#.css
--
--   Page Properties → JavaScript → File URLs:
--     #APP_FILES#template_components#MIN#.js
--
-- This ensures the Template Component CSS and JS are loaded
-- on every page without duplicating in each page's inline CSS.

PROMPT Step 1: Global Page (Page 0) — Add these file references in Page Designer:
PROMPT   CSS: #APP_FILES#template_components#MIN#.css
PROMPT   JS:  #APP_FILES#template_components#MIN#.js

-- ============================================================
-- STEP 2: Update Page 22 (My Cases) IG Query
-- ============================================================
-- Replace the inline CASE expression for status_class with
-- a call to uscis_template_components_pkg.get_status_category().
-- Also add STATUS_ICON column for badge icons.
--
-- OLD (in IG SQL):
--   CASE
--     WHEN UPPER(v.current_status) LIKE '%DENIED%' ... THEN 'denied'
--     WHEN UPPER(v.current_status) LIKE '%APPROVED%' ... THEN 'approved'
--     ...
--   END AS status_class
--
-- NEW (in IG SQL):
--   uscis_template_components_pkg.get_status_category(v.current_status) AS status_category,
--   uscis_template_components_pkg.get_status_icon(
--       uscis_template_components_pkg.get_status_category(v.current_status)
--   ) AS status_icon
--
-- OLD (HTML Expression for CURRENT_STATUS column):
--   <span class="status-badge status-&STATUS_CLASS.">&CURRENT_STATUS.</span>
--
-- NEW (HTML Expression):
--   <span class="uscis-badge uscis-badge--&STATUS_CATEGORY."><span class="t-Icon fa &STATUS_ICON. uscis-badge-icon"></span>&CURRENT_STATUS.</span>
--
-- OLD (HTML Expression for RECEIPT_NUMBER column):
--   <a href="&DETAIL_URL." class="receipt-link">&RECEIPT_NUMBER.</a>
--
-- NEW (HTML Expression):
--   <a href="&DETAIL_URL." class="uscis-receipt-link">&RECEIPT_NUMBER.</a>

PROMPT Step 2: Page 22 (My Cases) — Update IG query and HTML expressions
PROMPT   See page_patches/page_00022_patch.sql for full details

-- ============================================================
-- STEP 3: Update Page 3 (Case Details)
-- ============================================================
-- Replace the PL/SQL CASE for status_class with package call.
-- Replace the hard-coded case-detail-card HTML with the
-- USCIS Case Card template markup.
--
-- OLD (PL/SQL Before Header):
--   :P3_STATUS_CLASS := CASE
--     WHEN UPPER(l_raw_status) LIKE '%NOT APPROVED%' ... THEN 'status-denied'
--     ...
--   END;
--
-- NEW:
--   :P3_STATUS_CATEGORY := uscis_template_components_pkg.get_status_category(l_raw_status);
--   :P3_STATUS_ICON := uscis_template_components_pkg.get_status_icon(:P3_STATUS_CATEGORY);
--   :P3_STATUS_CLASS := 'uscis-badge--' || :P3_STATUS_CATEGORY;
--
-- OLD (Region source HTML):
--   <div class="case-detail-card">
--     <span class="status-badge &P3_STATUS_CLASS.">&P3_CURRENT_STATUS.</span>
--     ...
--   </div>
--
-- NEW (Region source HTML):
--   <div class="uscis-case-card">
--     <div class="uscis-case-card__header">
--       <div class="uscis-case-card__receipt-info">
--         <span class="uscis-case-card__receipt">&P3_RECEIPT_NUMBER.</span>
--         <span class="uscis-case-card__active-tag uscis-case-card__active-tag--&P3_ACTIVE_TAG_CLASS.">&P3_ACTIVE_DISPLAY.</span>
--       </div>
--       <div>
--         <span class="uscis-badge uscis-badge--solid uscis-badge--&P3_STATUS_CATEGORY.">
--           <span class="t-Icon fa &P3_STATUS_ICON. uscis-badge-icon"></span>&P3_CURRENT_STATUS.</span>
--       </div>
--     </div>
--     <div class="uscis-case-card__info-grid">
--       <div class="uscis-case-card__info-item">
--         <span class="uscis-case-card__label">Case Type</span>
--         <span class="uscis-case-card__value">&P3_CASE_TYPE.</span>
--       </div>
--       <div class="uscis-case-card__info-item">
--         <span class="uscis-case-card__label">Last Updated</span>
--         <span class="uscis-case-card__value">&P3_LAST_UPDATED.</span>
--       </div>
--       <div class="uscis-case-card__info-item">
--         <span class="uscis-case-card__label">Tracking Since</span>
--         <span class="uscis-case-card__value">&P3_TRACKING_SINCE.</span>
--       </div>
--       <div class="uscis-case-card__info-item">
--         <span class="uscis-case-card__label">Notes</span>
--         <span class="uscis-case-card__value">&P3_NOTES!HTML.</span>
--       </div>
--     </div>
--   </div>

PROMPT Step 3: Page 3 (Case Details) — Update region source and PL/SQL process
PROMPT   See page_patches/page_00003_patch.sql for full details

-- ============================================================
-- STEP 4: Update Page 1 (Dashboard)
-- ============================================================
-- Replace PL/SQL htp.p() HTML generation with Template Component
-- markup using the USCIS Metric Card pattern.
-- Replace hard-coded chart colors with package function call.
--
-- OLD (Chart SQL):
--   CASE
--     WHEN current_status LIKE '%Approved%' THEN '#2e8540'
--     ...
--   END AS status_color
--
-- NEW (Chart SQL):
--   uscis_template_components_pkg.get_status_color_from_text(current_status) AS status_color
--
-- OLD (Summary Cards PL/SQL):
--   l_html := ... hard-coded <div class="dash-card"> 
--
-- NEW (Summary Cards PL/SQL):
--   l_html := ... uses <div class="uscis-metric-card"> template

PROMPT Step 4: Page 1 (Dashboard) — Update chart SQL and summary cards PL/SQL
PROMPT   See page_patches/page_00001_patch.sql for full details

PROMPT ============================================================
PROMPT Template Component page updates documented.
PROMPT Review page_patches/ directory for detailed patch scripts.
PROMPT ============================================================
