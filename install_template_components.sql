-- ============================================================
-- USCIS Case Tracker - Template Components Installation
-- ============================================================
-- File: install_template_components.sql
--
-- Purpose:
--   Master installation script for the P7 Template Component
--   enhancement. Run this to install all server-side components.
--   Page Designer changes must be applied manually afterward.
--
-- Prerequisites:
--   - Oracle 19c+ database with APEX 24.2
--   - USCIS_APP schema with existing application (App 102)
--   - Existing packages 01-08 already installed
--
-- Installation Order:
--   1. PL/SQL Package (server-side status classification)
--   2. Static file upload (CSS + JS)
--   3. Documentation of Page Designer changes
--
-- Usage (connect interactively — never embed passwords on the command line):
--   sqlplus uscis_app@db @install_template_components.sql
--
-- The above will prompt for the password securely.  Alternatives:
--   - Oracle Wallet / External Authentication (no password required)
--   - EZCONNECT: sqlplus /@db @install_template_components.sql
--   - Environment variable: export TWO_TASK=db; sqlplus /nolog
--     SQL> CONNECT uscis_app
--
-- NEVER pass credentials via process arguments (visible in ps/history).
--
-- Follows: APEX_CONTEXTUAL_ANCHOR.md P1, P2, P6, P7, P8
-- ============================================================

SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT USCIS Case Tracker - Template Components Installation
PROMPT ============================================================
PROMPT
PROMPT This script installs:
PROMPT   1. USCIS_TEMPLATE_COMPONENTS_PKG (centralized status logic)
PROMPT   2. Template Components CSS/JS (application static files)
PROMPT
PROMPT After running this script, apply page changes via Page Designer.
PROMPT See page_patches/ directory for detailed instructions.
PROMPT ============================================================

TIMING START template_components

-- Step 1: Install the centralized status classification package
PROMPT
PROMPT [1/2] Installing USCIS_TEMPLATE_COMPONENTS_PKG...
@@packages/09_uscis_template_components_pkg.sql

-- Step 2: Upload static files (CSS + JS)
PROMPT
PROMPT [2/2] Uploading Template Component static files...
@@scripts/upload_template_component_files.sql

TIMING STOP

PROMPT
PROMPT ============================================================
PROMPT Installation complete!
PROMPT ============================================================
PROMPT
PROMPT NEXT STEPS (Manual — Page Designer):
PROMPT
PROMPT 1. GLOBAL PAGE (Page 0):
PROMPT    → Page Properties → CSS → File URLs:
PROMPT      #APP_FILES#template_components#MIN#.css
PROMPT    → Page Properties → JavaScript → File URLs:
PROMPT      #APP_FILES#template_components#MIN#.js
PROMPT
PROMPT 2. PAGE 22 (My Cases):
PROMPT    → Update IG query: replace CASE for status_class with
PROMPT      uscis_template_components_pkg.get_status_category()
PROMPT    → Add hidden columns: STATUS_CATEGORY, STATUS_ICON
PROMPT    → Update CURRENT_STATUS HTML Expression to use uscis-badge
PROMPT    → See: page_patches/page_00022_patch.sql
PROMPT
PROMPT 3. PAGE 3 (Case Details):
PROMPT    → Add hidden items: P3_STATUS_CATEGORY, P3_STATUS_ICON,
PROMPT      P3_ACTIVE_TAG_CLASS
PROMPT    → Update Before Header PL/SQL to use package functions
PROMPT    → Update Case Information region source HTML
PROMPT    → See: page_patches/page_00003_patch.sql
PROMPT
PROMPT 4. PAGE 1 (Dashboard):
PROMPT    → Update chart SQL to use get_status_color_from_text()
PROMPT    → Update Summary Cards PL/SQL to use uscis-metric-card
PROMPT    → See: page_patches/page_00001_patch.sql
PROMPT
PROMPT ============================================================
