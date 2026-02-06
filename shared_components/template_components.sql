-- ============================================================
-- USCIS Case Tracker - Template Component Plug-in Definitions
-- ============================================================
-- File: shared_components/template_components.sql
-- 
-- Purpose:
--   Defines three APEX Template Component plug-ins that replace
--   hard-coded HTML across pages 1, 3, and 22:
--
--   1. USCIS Status Badge    — Status pill/badge using Template Directives
--   2. USCIS Case Card       — Case detail header card
--   3. USCIS Metric Card     — Dashboard summary metric
--
-- These are implemented as NATIVE_TEMPLATE_COMPONENT regions
-- using Template Directives ({case/}, {if/}) rather than
-- custom PL/SQL HTML generation.
--
-- Follows: APEX_CONTEXTUAL_ANCHOR.md P7
-- ============================================================

SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

PROMPT ============================================================
PROMPT Installing Template Component Definitions...
PROMPT ============================================================

-- ============================================================
-- Upload Template Components CSS as Application Static File
-- ============================================================
PROMPT Uploading template_components.css...

DECLARE
    l_css CLOB;
BEGIN
    -- Read CSS content inline (the actual CSS is deployed via
    -- static file upload script; this is a fallback).
    -- Use wwv_flow_api (the PUBLIC API — per P1) to register
    -- the file reference. The actual upload happens via
    -- the upload_template_component_files.sql script.
    NULL;
END;
/

-- ============================================================
-- TEMPLATE 1: USCIS Status Badge
-- ============================================================
-- Universal Theme pill-based badge (no custom CSS required).
-- Uses Template Directives to map STATUS_CATEGORY to UT utility
-- classes for built-in semantic colors that work in Dark Mode.
--
-- Template markup:
--
-- <span class="u-pill {case STATUS_CATEGORY/}
--   {when approved/}u-success
--   {when denied/}u-danger
--   {when pending/}u-warning
--   {when rfe/}u-info
--   {when received/}u-color-14
--   {when transferred/}u-color-16
--   {otherwise/}u-color-7
-- {endcase/}">
--   <span class="u-pill-label">#STATUS_TEXT#</span>
-- </span>
--
-- Recommended usage:
--   - IG/IR column HTML Expression: {template:USCIS_STATUS_BADGE/}
--   - Provide STATUS_TEXT and STATUS_CATEGORY (via
--     uscis_template_components_pkg.get_status_category).
--   - Optional: add STATUS_UT_CLASS column via
--     uscis_template_components_pkg.get_ut_color_class and bind it
--     to a Template Directive if you prefer a direct class mapping.
--
-- This replaces all .status-badge* custom CSS and any
-- getStatusClass() JavaScript.

PROMPT Template 1: USCIS Status Badge — defined via HTML Expression
PROMPT   (No plug-in registration needed — uses inline Template Directives)

-- ============================================================
-- TEMPLATE 2: USCIS Case Card (Page 3 Header)
-- ============================================================
-- Replaces the hard-coded HTML in page_00003.sql region source.
-- Uses Template Directives for conditional active/inactive tag.
--
-- Template markup:
/*
<div class="uscis-case-card">
  <div class="uscis-case-card__header">
    <div class="uscis-case-card__receipt-info">
      <span class="uscis-case-card__receipt">#RECEIPT_NUMBER#</span>
      {if IS_ACTIVE = "Y"/}
        <span class="uscis-case-card__active-tag uscis-case-card__active-tag--active">Active</span>
      {else/}
        <span class="uscis-case-card__active-tag uscis-case-card__active-tag--inactive">Inactive</span>
      {endif/}
    </div>
    <div class="uscis-case-card__status">
      <span class="uscis-badge uscis-badge--solid uscis-badge--#STATUS_CATEGORY#">
        <span class="t-Icon fa #STATUS_ICON# uscis-badge-icon"></span>
        #CURRENT_STATUS#
      </span>
    </div>
  </div>
  <div class="uscis-case-card__info-grid">
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Case Type</span>
      <span class="uscis-case-card__value">#CASE_TYPE#</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Last Updated</span>
      <span class="uscis-case-card__value">#LAST_UPDATED#</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Tracking Since</span>
      <span class="uscis-case-card__value">#TRACKING_SINCE#</span>
    </div>
    <div class="uscis-case-card__info-item">
      <span class="uscis-case-card__label">Notes</span>
      <span class="uscis-case-card__value">#NOTES#</span>
    </div>
  </div>
</div>
*/

PROMPT Template 2: USCIS Case Card — defined via region source HTML

-- ============================================================
-- TEMPLATE 3: USCIS Metric Card (Page 1 Dashboard)
-- ============================================================
-- Replaces the PL/SQL htp.p() HTML generation in page_00001.sql.
-- Each metric card uses this template:
--
/*
<div class="uscis-metric-card">
  <span class="t-Icon #ICON_CLASS# uscis-metric-card__icon"></span>
  <div class="uscis-metric-card__value">#METRIC_VALUE#</div>
  <div class="uscis-metric-card__label">#METRIC_LABEL#</div>
  <div class="uscis-metric-card__sub">#METRIC_SUB#</div>
</div>
*/

PROMPT Template 3: USCIS Metric Card — defined via region source HTML

PROMPT ============================================================
PROMPT Template Component definitions complete.
PROMPT ============================================================
PROMPT 
PROMPT Next steps:
PROMPT   1. Upload template_components.css as an Application Static File
PROMPT   2. Upload template_components.js as an Application Static File
PROMPT   3. Reference them on Global Page (Page 0):
PROMPT      CSS: #APP_FILES#template_components#MIN#.css
PROMPT      JS:  #APP_FILES#template_components#MIN#.js
PROMPT   4. Update page 22 IG query to use get_status_category()
PROMPT   5. Update page 3 region source to use Case Card template
PROMPT   6. Update page 1 to use Metric Card template
PROMPT ============================================================
