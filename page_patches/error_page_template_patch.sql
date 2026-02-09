-- ============================================================
-- APEX Error Page Template Configuration
-- ============================================================
-- File: page_patches/error_page_template_patch.sql
--
-- Roadmap ID: 3.4.5 — Add APEX error page template
-- Dependencies: 3.4.4 (uscis_error_pkg — ✅ Complete)
--
-- Purpose:
--   Configure the Application-level Error Handling function and
--   customize the APEX error page for a user-friendly experience
--   consistent with the application's design language.
--
-- This patch covers five areas:
--   A. Application Definition → Error Handling settings
--   B. Error-page region customization (optional error page)
--   C. CSS additions for error display styling
--   D. Inline Error Display Enhancement (Page 0 / Global)
--   E. Notification Preferences (Page 0 / Global)
--
-- Apply via: Page Designer / Shared Components editor
-- ============================================================

-- ============================================================
-- PART A: Application-Level Error Settings
-- ============================================================
-- Navigate to:
--   Shared Components → Application Definition → Properties
--   → Error Handling (section)
--
-- Set these properties:
--
--   Error Handling Function:
--     uscis_error_pkg.handle_error
--
--   Error Page Template Custom:
--     Yes (to allow HTML markup in the error page)
--
--   Show Error Details:
--     No  (production — masks internal ORA/APEX errors)
--     Yes (development — shows full backtrace for debugging)

-- ============================================================
-- PART B: Application Error-Page Region (Page 0 or Global Page)
-- ============================================================
-- By default, APEX renders its own error page when
-- apex_error.c_on_error_page is used.
-- To customize the look:
--
-- Option 1 (RECOMMENDED): Use the built-in error page but
-- register the error handler (Part A). The handler in
-- uscis_error_pkg.handle_error already:
--   • Masks internal errors with a reference number
--   • Maps -200xx codes to user-friendly text
--   • Logs error details via autonomous transaction
--   • Maps constraint violations to associated items
--
-- This gives the standard UT theme error page with improved
-- messages. No new page required.
--
-- Option 2 (OPTIONAL): Create a dedicated error page for
-- custom layout. Steps:
--
-- 2a. Create Page 20 — Application Error Page
--   Page Type:      Blank Page (no tabs, no breadcrumb)
--   Page Name:      Application Error
--   Page Alias:     error-page
--   Page Template:  Minimal (No Navigation)
--   Authentication: Public

-- 2b. Add a Static Content region:
--   Region Name:    Error Details
--   Template:       Standard
--   Static ID:      error_region
--   Source → HTML:

/*
<div class="uscis-error-page">
  <div class="uscis-error-icon">
    <span class="t-Icon fa fa-exclamation-triangle" aria-hidden="true"></span>
  </div>
  <h2 class="uscis-error-title">Something went wrong</h2>
  <p class="uscis-error-message">&APP_ERROR_MESSAGE.</p>
  <div class="uscis-error-actions">
    <a href="f?p=&APP_ID.:1:&APP_SESSION.::NO:::"
       class="t-Button t-Button--hot t-Button--stretch">
      <span class="t-Button-label">Return to Dashboard</span>
    </a>
    <a href="javascript:void(0);" onclick="history.back();"
       class="t-Button t-Button--stretch">
      <span class="t-Button-label">Go Back</span>
    </a>
  </div>
  <div class="uscis-error-reference">
    <small>If this problem persists, please note the reference number
    shown above and contact your administrator.</small>
  </div>
</div>
*/

-- NOTE: &APP_ERROR_MESSAGE. is a built-in substitution that
-- contains the error text returned by the error handler.

-- 2c. If using Option 2, set in Application Definition:
--   Error Page:     20
--   (Shared Components → Application Definition → Properties →
--    Error Handling → Custom Error Page → Page 20)

-- ============================================================
-- PART C: Error Page CSS
-- ============================================================
-- Add the following to shared_components/files/app-styles.css
-- (or Page 20 → CSS → Inline if Option 2):

/*
-- ------------------------------------------------------------ --
-- Error Page Styles                                            --
-- ------------------------------------------------------------ --
.uscis-error-page {
    max-width: 600px;
    margin: 80px auto;
    text-align: center;
    padding: var(--a-region-padding, 24px);
}

.uscis-error-icon .t-Icon {
    font-size: 64px;
    color: var(--ut-palette-warning, #fdb81e);
    margin-bottom: 16px;
}

.uscis-error-title {
    font-size: var(--a-fs-5, 24px);
    font-weight: var(--a-base-font-weight-bold, 700);
    color: var(--ut-heading-text-color, #1a1a2e);
    margin-bottom: 12px;
}

.uscis-error-message {
    font-size: var(--a-fs-3, 16px);
    color: var(--ut-body-text-color, #404040);
    margin-bottom: 24px;
    line-height: 1.6;
}

.uscis-error-actions {
    display: flex;
    gap: 12px;
    justify-content: center;
    flex-wrap: wrap;
    margin-bottom: 24px;
}

.uscis-error-actions .t-Button {
    min-width: 180px;
}

.uscis-error-reference {
    color: var(--ut-component-text-muted-color, #707070);
    font-size: var(--a-fs-1, 12px);
}
*/

-- ============================================================
-- PART D: Inline Error Display Enhancement (Page 0 / Global)
-- ============================================================
-- For errors that display INLINE (not on the error page),
-- the uscis_error_pkg already returns proper messages.
-- To further improve inline display on all pages:
--
-- Page 0 (Global Page) → JavaScript → Execute when Page Loads:

/*
(function(apex, $) {
    "use strict";

    // Override the default error region rendering to add
    // status-aware styling for USCIS-specific errors
    $(document).on('apexaftershow', '.t-Body-alert', function() {
        var $alert = $(this);
        // Add animation for smooth appearance
        $alert.find('.t-Alert').addClass('animate-fadein');
    });

})(apex, apex.jQuery);
*/

-- ============================================================
-- PART E: Notification Preferences (Page 0 / Global)
-- ============================================================
-- The error handler in uscis_error_pkg uses
-- apex_error.c_inline_with_field_and_notification by default
-- for application errors. This shows:
--   1. A page-level notification banner
--   2. A highlight on the associated field (if mapped)
--
-- No additional configuration needed for this — it is handled
-- by the error handler's result.display_location setting.

PROMPT ============================================================
PROMPT Error page template patch documented.
PROMPT Apply settings in Shared Components → Application Definition.
PROMPT Optionally create Page 20 for custom error page layout.
PROMPT ============================================================
