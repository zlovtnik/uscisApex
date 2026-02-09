-- ============================================================
-- Button Standardization Patch — All Pages
-- ============================================================
-- File: page_patches/button_standardization_patch.sql
--
-- Purpose:
--   Unify button styling across every page in the application.
--   Previously, buttons used inconsistent template options,
--   icon choices, and CSS class approaches across pages.
--
-- CRITICAL FIX: Pages 6, 7, 8 used the "HTML button (legacy -
--   APEX 5 migration)" template (ID 13349797865298420) which
--   renders as raw <input type="button"> with NO t-Button class,
--   NO icon support, and NO Universal Theme styling.
--   All buttons are now switched to the theme default button
--   template (ID 4072362960822175091).
--
-- Standard conventions applied:
--   ┌──────────────────────────────────────────────────────────┐
--   │ Button Template  : Theme default (4072362960822175091)   │
--   │                    NEVER the legacy APEX 5 template      │
--   │ Template Options : #DEFAULT#:t-Button--iconLeft          │
--   │                    (ALL buttons get an icon on the left) │
--   │ Hot              : Only the primary CTA per region/page  │
--   │ Danger class     : p_button_css_classes => t-Button--danger│
--   │                    (destructive actions: delete, purge,  │
--   │                     drop jobs)                           │
--   │ Warning class    : p_button_css_classes => t-Button--warning│
--   │                    (caution actions: clear cache, test,  │
--   │                     force refresh)                       │
--   │ Cancel/Back      : Position PREVIOUS, icon fa-chevron-left│
--   │                    or fa-times                           │
--   │ Delete icon      : fa-trash (not fa-trash-o)             │
--   └──────────────────────────────────────────────────────────┘
--
-- Apply via: Page Designer (apply each change per-button)
-- ============================================================


-- ============================================================
-- CRITICAL: BUTTON TEMPLATE FIX (Pages 6, 7, 8)
-- ============================================================
-- All 13 buttons on Pages 6, 7, 8 were using the WRONG template:
--   "HTML button (legacy - APEX 5 migration)"
--   Internal name: HTML_BUTTON_LEGACY_APEX_5_MIGRATION
--   ID: wwv_flow_imp.id(13349797865298420)
--
-- This template renders as:
--   <input type="button" value="Label" class="t-Button--iconLeft"/>
-- Missing: t-Button base class, icon <span>, proper UT markup
--
-- FIX: Change button template to the theme default in Page Designer:
--   Appearance → Template → select "Text with Icon" (or first
--   non-legacy option matching the theme default).
--
-- Affected buttons:
--   Page 6: BTN_PREVIEW, BTN_EXPORT, BTN_IMPORT, BTN_CLEAR
--   Page 7: BTN_SAVE, BTN_CANCEL, BTN_TEST_API
--   Page 8: BTN_CLEAR_TOKEN, BTN_PURGE_AUDIT, BTN_RUN_NOW,
--           BTN_CREATE_JOBS, BTN_DROP_JOBS, BTN_FORCE_REFRESH_TOKEN
-- ============================================================


-- ============================================================
-- PAGE 9999 — Login
-- ============================================================
-- Button: LOGIN ("Sign In")
--
-- BEFORE:
--   Template Options : #DEFAULT#
--   Icon             : (none)
--   Hot              : Yes
--
-- AFTER:
--   Template Options : #DEFAULT#:t-Button--iconLeft
--   Icon             : fa-sign-in
--   Hot              : Yes (primary CTA — correct)
--
-- Steps in Page Designer:
--   1. Page 9999 → LOGIN button
--   2. Appearance → Template Options → check "Icon Left"
--   3. Appearance → Icon CSS Classes → fa-sign-in
-- ============================================================


-- ============================================================
-- PAGE 1 — Dashboard
-- ============================================================
-- All three buttons are already consistent. No changes needed.
--
-- BTN_ADD_CASE  : Hot, fa-plus, #DEFAULT#:t-Button--iconLeft  ✓
-- BTN_VIEW_CASES: Normal, fa-table, #DEFAULT#:t-Button--iconLeft  ✓
-- BTN_IMPORT_EXPORT: Normal, fa-exchange, #DEFAULT#:t-Button--iconLeft  ✓
-- ============================================================


-- ============================================================
-- PAGE 3 — Case Details
-- ============================================================

-- Button: BTN_BACK ("Back to Cases")
-- Already correct: fa-chevron-left, position PREVIOUS, iconLeft  ✓
-- No changes needed.

-- Button: BTN_SAVE_NOTES ("Save Notes")
-- Already correct: fa-save, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_SAVE_ACTIVE ("Update Settings")
-- Already correct: fa-toggle-on, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_REFRESH ("Refresh Status")
-- Already correct: Hot, fa-refresh, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_DELETE ("Delete Case")
--
-- BEFORE:
--   Template Options : #DEFAULT#:t-Button--iconLeft:t-Button--danger
--   CSS Classes      : (none)
--   Icon             : fa-trash-o
--
-- AFTER:
--   Template Options : #DEFAULT#:t-Button--iconLeft
--   CSS Classes      : t-Button--danger
--   Icon             : fa-trash
--
-- Rationale: Move danger class to CSS Classes (consistent with Pages
--   7/8), and use fa-trash (not fa-trash-o) for consistency.
--
-- Steps in Page Designer:
--   1. Page 3 → BTN_DELETE button
--   2. Appearance → Template Options → UNCHECK "Danger"
--      (leave only #DEFAULT# and Icon Left checked)
--   3. Appearance → CSS Classes → t-Button--danger
--   4. Appearance → Icon CSS Classes → change fa-trash-o to fa-trash
-- ============================================================


-- ============================================================
-- PAGE 4 — Add Case (Modal Dialog)
-- ============================================================

-- Button: CANCEL ("Cancel")
--
-- BEFORE:
--   Template Options : #DEFAULT#
--   Icon             : (none)
--   Position         : NEXT
--
-- AFTER:
--   Template Options : #DEFAULT#:t-Button--iconLeft
--   Icon             : fa-times
--   Position         : PREVIOUS
--
-- Rationale: All cancel/back buttons should have an icon and be
--   positioned PREVIOUS (left side) per the standard.
--
-- Steps in Page Designer:
--   1. Page 4 → CANCEL button
--   2. Appearance → Template Options → check "Icon Left"
--   3. Appearance → Icon CSS Classes → fa-times
--   4. Layout → Button Position → Previous
-- ============================================================

-- Button: SAVE ("Add Case")
-- Already correct: Hot, fa-plus, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.


-- ============================================================
-- PAGE 6 — Import / Export
-- ============================================================
-- All four buttons are already consistent. No changes needed.
--
-- BTN_PREVIEW : Normal, fa-eye, #DEFAULT#:t-Button--iconLeft  ✓
-- BTN_EXPORT  : Hot, fa-download, #DEFAULT#:t-Button--iconLeft  ✓
-- BTN_IMPORT  : Hot, fa-upload, #DEFAULT#:t-Button--iconLeft  ✓
-- BTN_CLEAR   : Normal, fa-times, #DEFAULT#:t-Button--iconLeft  ✓
-- ============================================================


-- ============================================================
-- PAGE 7 — Settings
-- ============================================================

-- Button: BTN_SAVE ("Save Settings")
-- Already correct: Hot, fa-save, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_CANCEL ("Cancel")
--
-- BEFORE:
--   Template Options : #DEFAULT#
--   Icon             : (none)
--   Position         : PREVIOUS
--
-- AFTER:
--   Template Options : #DEFAULT#:t-Button--iconLeft
--   Icon             : fa-chevron-left
--   Position         : PREVIOUS (already correct)
--
-- Rationale: Cancel/back buttons need an icon per the standard.
--
-- Steps in Page Designer:
--   1. Page 7 → BTN_CANCEL button
--   2. Appearance → Template Options → check "Icon Left"
--   3. Appearance → Icon CSS Classes → fa-chevron-left
-- ============================================================

-- Button: BTN_TEST_API ("Test API Connection")
-- Already correct: fa-plug, t-Button--warning (CSS Classes),
--   #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.


-- ============================================================
-- PAGE 8 — Administration
-- ============================================================

-- Button: BTN_CLEAR_TOKEN ("Clear OAuth Token Cache")
--
-- BEFORE:
--   Icon             : fa-trash-o
--   CSS Classes      : t-Button--warning
--
-- AFTER:
--   Icon             : fa-trash
--   CSS Classes      : t-Button--warning (no change)
--
-- Rationale: Use fa-trash (not fa-trash-o) for consistency.
--
-- Steps in Page Designer:
--   1. Page 8 → BTN_CLEAR_TOKEN button
--   2. Appearance → Icon CSS Classes → change fa-trash-o to fa-trash
-- ============================================================

-- Button: BTN_PURGE_AUDIT ("Purge Old Audit Logs")
--
-- BEFORE:
--   Icon             : fa-eraser
--   CSS Classes      : t-Button--danger
--
-- AFTER:
--   Icon             : fa-trash
--   CSS Classes      : t-Button--danger (no change)
--
-- Rationale: All destructive/purge actions use fa-trash.
--
-- Steps in Page Designer:
--   1. Page 8 → BTN_PURGE_AUDIT button
--   2. Appearance → Icon CSS Classes → change fa-eraser to fa-trash
-- ============================================================

-- Button: BTN_RUN_NOW ("Run Now")
-- Already correct: Hot, fa-play, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_CREATE_JOBS ("Create Scheduler Jobs")
-- Already correct: Normal, fa-plus-circle, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.

-- Button: BTN_DROP_JOBS ("Drop All Jobs")
--
-- BEFORE:
--   Icon             : fa-times-circle
--   CSS Classes      : t-Button--danger
--
-- AFTER:
--   Icon             : fa-trash
--   CSS Classes      : t-Button--danger (no change)
--
-- Rationale: Drop/delete/purge actions all use fa-trash.
--
-- Steps in Page Designer:
--   1. Page 8 → BTN_DROP_JOBS button
--   2. Appearance → Icon CSS Classes → change fa-times-circle to fa-trash
-- ============================================================

-- Button: BTN_FORCE_REFRESH_TOKEN ("Force Token Refresh")
-- Already correct: fa-bolt, t-Button--warning, #DEFAULT#:t-Button--iconLeft  ✓
-- No changes needed.


-- ============================================================
-- PAGE 22 — My Cases (Interactive Grid)
-- ============================================================
-- All three buttons are already consistent. No changes needed.
--
-- ADD_CASE     : Hot, fa-plus, #DEFAULT#:t-Button--iconLeft  ✓
-- APPLY_FILTER : Normal, fa-filter, #DEFAULT#:t-Button--iconLeft  ✓
-- EXPORT       : Normal, fa-download, #DEFAULT#:t-Button--iconLeft  ✓
-- ============================================================


-- ============================================================
-- SUMMARY OF CHANGES
-- ============================================================
--
-- Total buttons audited: 27
-- Buttons modified:      20 (13 template fixes + 7 style fixes)
--
-- TEMPLATE FIX (legacy APEX 5 → theme default):
-- Page  | Buttons affected
-- ------|----------------------------------------------------
-- 6     | BTN_PREVIEW, BTN_EXPORT, BTN_IMPORT, BTN_CLEAR
-- 7     | BTN_SAVE, BTN_CANCEL, BTN_TEST_API
-- 8     | BTN_CLEAR_TOKEN, BTN_PURGE_AUDIT, BTN_RUN_NOW,
--       | BTN_CREATE_JOBS, BTN_DROP_JOBS, BTN_FORCE_REFRESH_TOKEN
--
-- STYLE FIXES:
-- Page  | Button              | Change
-- ------|---------------------|------------------------------------------
-- 9999  | LOGIN               | Add icon fa-sign-in, add iconLeft
-- 3     | BTN_DELETE           | Move danger to CSS Classes, fa-trash-o → fa-trash
-- 4     | CANCEL              | Add icon fa-times, add iconLeft, move to PREVIOUS
-- 7     | BTN_CANCEL           | Add icon fa-chevron-left, add iconLeft
-- 8     | BTN_CLEAR_TOKEN      | fa-trash-o → fa-trash
-- 8     | BTN_PURGE_AUDIT      | fa-eraser → fa-trash
-- 8     | BTN_DROP_JOBS        | fa-times-circle → fa-trash
--
-- ============================================================
