-- ============================================================
-- Page 4 Patch: Add Case → Fetch from USCIS Integration
-- ============================================================
-- File: page_patches/page_00004_patch.sql
--
-- Roadmap ID: 3.4.2 — Add fetch from USCIS on Page 4
-- Dependencies: 2.5.3 (P4_FETCH_FROM_USCIS toggle), 3.2.4 (check_case_status)
--
-- Prerequisites:
--   - USCIS_API_PKG (package 06) installed with check_case_status
--   - USCIS_UTIL_PKG (package 02) installed
--   - USCIS_TEMPLATE_COMPONENTS_PKG (package 09) installed
--   - Page 4 already has: P4_RECEIPT_NUMBER, P4_FETCH_FROM_USCIS,
--     P4_CASE_TYPE, P4_NOTES, "Add Case" process, "Cancel Dialog" DA,
--     "Toggle Case Type" DA, "Format Receipt Number" DA
--
-- Changes:
--   1. Add hidden items for API result feedback
--   2. Replace "Add Case" process with fetch-aware version
--   3. Add "Result Card" region for post-fetch display
--   4. Add page-level JS for fetch animation
--
-- Apply via: Page Designer (recommended)
-- ============================================================

-- ============================================================
-- CHANGE 1: Add new hidden page items
-- ============================================================
-- In Page Designer → Page 4 → add these hidden items:
--
--   P4_API_STATUS     (Hidden, Value Protected: No)
--   P4_API_CASE_TYPE  (Hidden, Value Protected: No)
--   P4_API_DETAILS    (Hidden, Value Protected: No)
--   P4_API_UPDATED    (Hidden, Value Protected: No)
--   P4_STATUS_CATEGORY (Hidden, Value Protected: No)
--   P4_STATUS_ICON    (Hidden, Value Protected: No)

-- ============================================================
-- CHANGE 2: Replace "Add Case" process
-- ============================================================
-- In Page Designer → Processing → "Add Case" (Process Sequence 10):
-- Replace the PL/SQL Code with the following.
--
-- When P4_FETCH_FROM_USCIS = 'Y', the process calls
-- uscis_api_pkg.check_case_status() which automatically:
--   1. Calls the USCIS API (or uses mock mode)
--   2. Saves the case + status via uscis_case_pkg.add_or_update_case
--   3. Logs the check via uscis_audit_pkg
--
-- When P4_FETCH_FROM_USCIS = 'N', it uses uscis_case_pkg.add_case
-- directly with the user-supplied case type and manual status.
--
-- In both paths, the receipt number is normalized first.

/*
DECLARE
    l_receipt    VARCHAR2(13);
    l_case_type  VARCHAR2(100);
    l_api_status uscis_types_pkg.t_case_status;
    l_category   VARCHAR2(30);
    l_icon       VARCHAR2(50);
    l_result     VARCHAR2(13);
BEGIN
    -- Normalize receipt number
    l_receipt := uscis_util_pkg.normalize_receipt_number(:P4_RECEIPT_NUMBER);

    -- Validate (defensively — validations should catch first)
    IF NOT uscis_util_pkg.validate_receipt_number(l_receipt) THEN
        apex_error.add_error(
            p_message          => 'Invalid receipt number format.',
            p_display_location => apex_error.c_inline_in_notification,
            p_page_item_name   => 'P4_RECEIPT_NUMBER'
        );
        RETURN;
    END IF;

    -- Check for duplicate
    IF uscis_case_pkg.case_exists(l_receipt) THEN
        apex_error.add_error(
            p_message          => 'This case is already being tracked.',
            p_display_location => apex_error.c_inline_in_notification,
            p_page_item_name   => 'P4_RECEIPT_NUMBER'
        );
        RETURN;
    END IF;

    IF NVL(:P4_FETCH_FROM_USCIS, 'N') = 'Y' THEN
        -------------------------------------------------------
        -- PATH A: Fetch from USCIS API (or mock) + save
        -------------------------------------------------------
        BEGIN
            l_api_status := uscis_api_pkg.check_case_status(
                p_receipt_number   => l_receipt,
                p_save_to_database => TRUE
            );

            -- Update notes if user provided them
            IF :P4_NOTES IS NOT NULL THEN
                uscis_case_pkg.update_case_notes(
                    p_receipt_number => l_receipt,
                    p_notes          => :P4_NOTES
                );
            END IF;

            -- Set session state for feedback display
            :P4_API_STATUS     := l_api_status.current_status;
            :P4_API_CASE_TYPE  := NVL(l_api_status.case_type, 'Unknown');
            :P4_API_DETAILS    := SUBSTR(l_api_status.details, 1, 2000);
            :P4_API_UPDATED    := TO_CHAR(l_api_status.last_updated,
                                          'Mon DD, YYYY HH12:MI AM');

            -- Template Component classification
            l_category := uscis_template_components_pkg.get_status_category(
                              l_api_status.current_status);
            l_icon     := uscis_template_components_pkg.get_status_icon(l_category);
            :P4_STATUS_CATEGORY := l_category;
            :P4_STATUS_ICON     := l_icon;

            -- Success message with status
            apex_application.g_print_success_message :=
                'Case ' || apex_escape.html(l_receipt)
                || ' added — Status: '
                || apex_escape.html(l_api_status.current_status);

        EXCEPTION
            WHEN OTHERS THEN
                -- API fetch failed — still save the case with manual status
                apex_debug.error(
                    'Fetch from USCIS failed for %s: %s %s',
                    l_receipt, SQLERRM,
                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

                -- Fallback: add case without API data
                l_result := uscis_case_pkg.add_case(
                    p_receipt_number => l_receipt,
                    p_case_type      => NVL(:P4_CASE_TYPE, 'Unknown'),
                    p_current_status => 'USCIS Fetch Failed',
                    p_notes          => :P4_NOTES,
                    p_source         => uscis_types_pkg.gc_source_manual
                );

                apex_application.g_print_success_message :=
                    'Case added but USCIS status could not be retrieved. '
                    || 'You can refresh the status from the case details page.';
        END;

    ELSE
        -------------------------------------------------------
        -- PATH B: Manual add (no API call)
        -------------------------------------------------------
        l_case_type := NVL(:P4_CASE_TYPE, 'Unknown');

        l_result := uscis_case_pkg.add_case(
            p_receipt_number => l_receipt,
            p_case_type      => l_case_type,
            p_current_status => 'Case Received',
            p_notes          => :P4_NOTES,
            p_source         => uscis_types_pkg.gc_source_manual
        );

        apex_application.g_print_success_message :=
            'Case ' || apex_escape.html(l_receipt) || ' added successfully.';
    END IF;

    -- Update bind for branch redirect
    :P4_RECEIPT_NUMBER := l_receipt;

EXCEPTION
    WHEN OTHERS THEN
        apex_debug.error(
            'Add Case process failed for [%s]: %s %s',
            :P4_RECEIPT_NUMBER, SQLERRM,
            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        apex_error.add_error(
            p_message          => 'An error occurred while adding the case. Please try again.',
            p_display_location => apex_error.c_inline_in_notification
        );
END;
*/

-- ============================================================
-- CHANGE 3: Update hint text for "Fetch from USCIS" toggle
-- ============================================================
-- In Page Designer → P4_FETCH_FROM_USCIS → Help Text:
-- Replace current text with:

/*
When enabled, the case will be added and the current status
will be automatically fetched from the USCIS system.
If the USCIS API is unavailable, the case will still be saved
and you can refresh the status later from the Case Details page.
When disabled, the case is added with manual entry only.
*/

-- ============================================================
-- CHANGE 4: Update branch to redirect to Case Details
-- ============================================================
-- In Page Designer → Branches → "Go To Page 22":
--   Edit to redirect to Page 3 (Case Details) when API was
--   fetched, or Page 22 when manually added.
--
-- OPTION A (simple — always go to Case Details):
--   Target:   Page 3
--   Items:    P3_RECEIPT_NUMBER = &P4_RECEIPT_NUMBER.
--   (Leave existing branch as-is if you prefer returning to list)
--
-- OPTION B (keep existing redirect to Page 22):
--   No change needed. The success message will show the result.

-- ============================================================
-- CHANGE 5: Page-level JavaScript — Function and Global
--            Variable Declaration
-- ============================================================
-- In Page Designer → Page 4 → JavaScript →
--   "Function and Global Variable Declaration":
-- Add the following (keeps existing behavior, adds spinner logic):

/*
(function(apex, $) {
    "use strict";

    var SAVE_LABEL = 'Save';

    // Re-enable the SAVE button on page load / re-render in case a
    // previous validation failure left it disabled.
    function resetSaveButton() {
        var $btn = $('#SAVE');
        if ($btn.length && $btn.prop('disabled')) {
            $btn.prop('disabled', false).removeClass('apex_disabled');
            $btn.find('.t-Button-label').text(SAVE_LABEL);
        }
    }

    // Reset on initial page load (deferred until DOM is ready
    // so that the #SAVE element exists when resetSaveButton runs)
    $(resetSaveButton);

    // Reset after any APEX refresh (covers server-side validation
    // failures that re-render the page).
    $(document).on('apexafterrefresh', resetSaveButton);

    // Use the APEX-specific page-submit event so we only act on the
    // SAVE request when USCIS fetch is enabled.
    $(apex.gPageContext$).on('apexbeforepagesubmit', function(e, request) {
        if (request === 'SAVE' &&
            apex.item('P4_FETCH_FROM_USCIS').getValue() === 'Y') {
            var $btn = $('#SAVE');
            if ($btn.length) {
                $btn.prop('disabled', true).addClass('apex_disabled');
                $btn.find('.t-Button-label').text('Checking USCIS...');
            }
        }
    });
})(apex, apex.jQuery);
*/

-- ============================================================
-- CHANGE 6: Page-level CSS — Inline CSS (Minimal)
-- ============================================================
-- In Page Designer → Page 4 → CSS → Inline:
-- Keep the existing receipt-input style, no additions needed.
-- The existing inline CSS is sufficient:
--
-- .receipt-input {
--   font-family: "Courier New", monospace;
--   letter-spacing: 1px;
--   text-transform: uppercase;
-- }

PROMPT ============================================================
PROMPT Page 4 (Add Case) patch for USCIS fetch documented.
PROMPT Apply changes in Page Designer.
PROMPT ============================================================
