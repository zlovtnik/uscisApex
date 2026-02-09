-- ============================================================
-- Page 5 Patch: Check Status Modal
-- ============================================================
-- File: page_patches/page_00005_patch.sql
--
-- Roadmap IDs: 3.3.1 – 3.3.6
--   3.3.1  Build Check Status modal (Page 5)
--   3.3.2  Add receipt number input with validation
--   3.3.3  Add save to database toggle
--   3.3.4  Display API result in modal
--   3.3.5  Handle API errors gracefully
--   3.3.6  Add loading spinner during API call
--
-- Prerequisites:
--   - USCIS_API_PKG (package 06) installed with check_case_status
--   - USCIS_UTIL_PKG (package 02) installed with normalize/validate
--   - USCIS_TEMPLATE_COMPONENTS_PKG (package 09) installed
--   - template_components.css uploaded to Static Application Files
--   - app-styles.css uploaded (contains Check Status section)
--
-- Apply via: Page Designer (create new Page 5 as Modal Dialog)
-- ============================================================

-- ============================================================
-- STEP 1: Create Page 5 — Modal Dialog
-- ============================================================
-- In Page Designer → Create Page:
--   Page Number: 5
--   Name:        Check Status
--   Title:       Check Case Status
--   Page Mode:   Modal Dialog
--
-- Dialog Attributes:
--   Width:   600 (pixels)
--   Height:  Auto
--   CSS Classes: check-status-dialog

-- ============================================================
-- STEP 2: Create Page Items
-- ============================================================
-- Create a region "Input Form" first (see STEP 4), then add
-- these items inside it.

-- 2a. P5_RECEIPT_NUMBER — Text Field
-- Region: Input Form
-- Settings:
--   Label:              Receipt Number
--   Type:               Text Field
--   Subtype:            Text
--   Placeholder:        e.g., IOE1234567890
--   Custom Attributes:  data-receipt-input="true" maxlength="13"
--                        autocomplete="off" spellcheck="false"
--                        style="text-transform:uppercase"
--   Required:           Yes
--   Value Protected:    No
--   Template:           Required - Floating
--   Pre Text:           <span class="t-Icon fa fa-search"></span>
--   Help Text:          Enter your 13-character USCIS receipt number
--                        (3 letters + 10 digits, e.g., IOE1234567890)
--
-- Validation (add under Validations tab):
--   Name:     Validate Receipt Format
--   Type:     Function Returning Boolean
--   PL/SQL:   RETURN uscis_util_pkg.validate_receipt_number(:P5_RECEIPT_NUMBER);
--   Error:    Invalid receipt number format. Expected 3 letters + 10 digits (e.g., IOE1234567890).
--   When:     When Button Pressed = BTN_CHECK

-- 2b. P5_SAVE_TO_DB — Switch
-- Region: Input Form
-- Settings:
--   Label:       Save to my tracked cases
--   Type:        Switch
--   On Value:    Y
--   Off Value:   N
--   Default:     N
--   Help Text:   When enabled, the case will be saved to your tracked
--                 cases for future monitoring.
--   Template:    Optional - Floating

-- 2c. P5_RESULT_STATUS — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2d. P5_RESULT_TYPE — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2e. P5_RESULT_UPDATED — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2f. P5_RESULT_DETAILS — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2g. P5_STATUS_CATEGORY — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2h. P5_STATUS_ICON — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2i. P5_ERROR_MESSAGE — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No

-- 2j. P5_CASE_SAVED — Hidden
-- Settings:
--   Type:            Hidden
--   Value Protected: No
--   (Set to 'Y' when save was successful, used for View Case button)

-- ============================================================
-- STEP 3: Create Buttons
-- ============================================================

-- 3a. BTN_CLOSE
--   Region:    Buttons (Dialog Footer)
--   Position:  Close
--   Label:     Close
--   Action:    Defined by Dynamic Action (close dialog)
--   Template:  Text
--   Hot:       No
--   Icon:      (none)

-- 3b. BTN_CHECK
--   Region:    Buttons (Dialog Footer)
--   Position:  Next
--   Label:     Check Status
--   Action:    Defined by Dynamic Action
--   Template:  Text with Icon
--   Hot:       Yes
--   Icon:      fa-search
--   CSS Classes: js-check-status-btn

-- 3c. BTN_VIEW_CASE
--   Region:    Buttons (Dialog Footer)
--   Position:  Next
--   Label:     View Case Details
--   Action:    Redirect to Page 3
--   Target:    Page 3, P3_RECEIPT_NUMBER=&P5_RECEIPT_NUMBER.
--   Template:  Text with Icon
--   Hot:       No
--   Icon:      fa-external-link
--   Server-side Condition:
--     Type:    Item = Value
--     Item:    P5_CASE_SAVED
--     Value:   Y
--   (Only shown after a successful check + save)

-- ============================================================
-- STEP 4: Create Regions
-- ============================================================

-- 4a. Input Form
--   Type:      Static Content
--   Position:  Body
--   Template:  Blank with Attributes
--   Sequence:  10
--   Source:    (leave blank — items render automatically)
--   (Contains P5_RECEIPT_NUMBER, P5_SAVE_TO_DB)

-- 4b. Loading Indicator
--   Type:      Static Content
--   Position:  Body
--   Template:  Blank with Attributes
--   Sequence:  20
--   Static ID: check-loading-region
--   CSS Classes: check-status-loading
--   Server-side Condition: Never (controlled by JS show/hide)
--   Source (HTML):

/*
<div class="check-status-loading-content" id="check-loading">
  <div class="loading-spinner"></div>
  <p class="loading-text">Checking USCIS for status&hellip;</p>
  <div class="loading-dots">
    <span></span><span></span><span></span>
  </div>
</div>
*/

-- 4c. Result Card
--   Type:      Static Content
--   Position:  Body
--   Template:  Standard
--   Title:     Status Result
--   Sequence:  30
--   Static ID: check-result-region
--   CSS Classes: check-status-result
--   Server-side Condition:
--     Type:    Item is NOT NULL
--     Item:    P5_RESULT_STATUS
--   Source (HTML):

/*
<div class="check-result-card">

  <div class="check-result-card__header">
    <div class="check-result-card__receipt-info">
      <span class="uscis-receipt">&P5_RECEIPT_NUMBER!HTML.</span>
    </div>
    <div>
      <span class="uscis-badge uscis-badge--solid uscis-badge--&P5_STATUS_CATEGORY!ATTR.">
        <span class="t-Icon fa &P5_STATUS_ICON!ATTR. uscis-badge-icon"></span>
        &P5_RESULT_STATUS!HTML.
      </span>
    </div>
  </div>

  <div class="check-result-card__body">
    <div class="check-result-card__grid">
      <div class="check-result-card__item">
        <span class="check-result-card__label">Case Type</span>
        <span class="check-result-card__value">&P5_RESULT_TYPE!HTML.</span>
      </div>
      <div class="check-result-card__item">
        <span class="check-result-card__label">Last Updated</span>
        <span class="check-result-card__value">&P5_RESULT_UPDATED!HTML.</span>
      </div>
    </div>
    <div class="check-result-card__details">
      <span class="check-result-card__label">Details</span>
      <p class="check-result-card__detail-text">&P5_RESULT_DETAILS!HTML.</p>
    </div>
  </div>

</div>
*/

-- 4d. Error Card
--   Type:      Static Content
--   Position:  Body
--   Template:  Blank with Attributes
--   Sequence:  25
--   Static ID: check-error-region
--   CSS Classes: check-status-error
--   Server-side Condition:
--     Type:    Item is NOT NULL
--     Item:    P5_ERROR_MESSAGE
--   Source (HTML):

/*
<div class="check-error-card" id="check-error" role="alert">
  <div class="check-error-card__icon">
    <span class="t-Icon fa fa-exclamation-triangle"></span>
  </div>
  <div class="check-error-card__content">
    <h3 class="check-error-card__title">Unable to Check Status</h3>
    <p class="check-error-card__message">&P5_ERROR_MESSAGE!HTML.</p>
    <p class="check-error-card__hint">Please verify the receipt number and try again.
       If the problem persists, the USCIS API may be temporarily unavailable.</p>
  </div>
</div>
*/

-- ============================================================
-- STEP 5: Create AJAX Callback Process
-- ============================================================

-- Process Name: Check Status
-- Type:         PL/SQL Code
-- Point:        Processing
-- When Button:  BTN_CHECK
-- Execution:    AJAX Callback
-- (Create as an AJAX Callback process, NOT a page submit process)

-- PL/SQL Code:

/*
DECLARE
    l_status    uscis_types_pkg.t_case_status;
    l_receipt   VARCHAR2(13);
    l_save      BOOLEAN;
    l_category  VARCHAR2(30);
    l_icon      VARCHAR2(50);
BEGIN
    -- Normalize receipt number
    l_receipt := uscis_util_pkg.normalize_receipt_number(:P5_RECEIPT_NUMBER);
    l_save    := (:P5_SAVE_TO_DB = 'Y');

    -- Validate
    IF NOT uscis_util_pkg.validate_receipt_number(l_receipt) THEN
        apex_json.open_object;
        apex_json.write('success', FALSE);
        apex_json.write('error', 'Invalid receipt number format. '
            || 'Expected 3 letters + 10 digits (e.g., IOE1234567890).');
        apex_json.close_object;
        RETURN;
    END IF;

    -- Call API
    l_status := uscis_api_pkg.check_case_status(
        p_receipt_number   => l_receipt,
        p_save_to_database => l_save
    );

    -- Derive status category and icon via Template Components pkg
    l_category := uscis_template_components_pkg.get_status_category(
                      l_status.current_status);
    l_icon     := uscis_template_components_pkg.get_status_icon(l_category);

    -- Return JSON result
    apex_json.open_object;
    apex_json.write('success', TRUE);
    apex_json.write('receiptNumber', l_status.receipt_number);
    apex_json.write('caseType', NVL(l_status.case_type, 'Unknown'));
    apex_json.write('currentStatus', l_status.current_status);
    apex_json.write('lastUpdated',
        TO_CHAR(l_status.last_updated, 'Month DD, YYYY'));
    apex_json.write('details',
        SUBSTR(l_status.details, 1, 2000));
    apex_json.write('statusCategory', l_category);
    apex_json.write('statusIcon', l_icon);
    apex_json.write('saved', CASE WHEN l_save THEN TRUE ELSE FALSE END);
    apex_json.close_object;

EXCEPTION
    WHEN OTHERS THEN
        -- Log internally
        apex_debug.error('Check status failed for %s: %s %s',
            :P5_RECEIPT_NUMBER, SQLERRM,
            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

        -- Return sanitized error (no DB internals exposed)
        apex_json.open_object;
        apex_json.write('success', FALSE);
        apex_json.write('error',
            CASE
                WHEN SQLCODE = uscis_types_pkg.gc_err_invalid_receipt THEN
                    'Invalid receipt number format.'
                WHEN SQLCODE = uscis_types_pkg.gc_err_rate_limited THEN
                    'Too many requests. Please wait a moment and try again.'
                WHEN SQLCODE = uscis_types_pkg.gc_err_api_error THEN
                    'The USCIS API is temporarily unavailable. Please try again later.'
                WHEN SQLCODE = uscis_types_pkg.gc_err_auth_failed THEN
                    'API authentication failed. Please contact the administrator.'
                ELSE
                    'An unexpected error occurred while checking status. Please try again.'
            END);
        apex_json.close_object;
END;
*/

-- ============================================================
-- STEP 6: Create Dynamic Actions
-- ============================================================

-- 6a. DA: "Check Status — AJAX Submit"
-- ---------------------------------------------------------------
-- Fires when BTN_CHECK is clicked. Validates client-side, shows
-- spinner, calls the AJAX process, and renders the result.
--
-- Event:       Click
-- Selection:   Button → BTN_CHECK
-- Condition:   JavaScript expression
--              apex.item('P5_RECEIPT_NUMBER').getValue().trim().length > 0
--
-- True Actions (sequence order):
--
--   1) Execute JavaScript Code (Before AJAX)
--      Code: (see below — "beforeCheckStatus")
--
--   2) Execute Server-side Code
--      (NOT used — we use manual apex.server.process instead,
--       embedded in the JS from action 1. See STEP 7.)

-- 6b. DA: "Clear Results on Receipt Change"
-- ---------------------------------------------------------------
-- Resets the result region when the user edits the receipt number.
--
-- Event:       Change
-- Selection:   Item → P5_RECEIPT_NUMBER
--
-- True Actions:
--   1) Execute JavaScript Code:

/*
(function(apex, $) {
    // Hide result and error cards when receipt changes
    $('#check-result-region').hide();
    $('#check-error-region').hide();
    // Reset hidden items
    apex.item('P5_RESULT_STATUS').setValue('');
    apex.item('P5_ERROR_MESSAGE').setValue('');
    apex.item('P5_CASE_SAVED').setValue('');
    // Hide View Case button
    $('#BTN_VIEW_CASE').closest('.t-Button').hide();
})(apex, apex.jQuery);
*/

-- 6c. DA: "Close Dialog"
-- ---------------------------------------------------------------
-- Event:       Click
-- Selection:   Button → BTN_CLOSE
-- True Actions:
--   1) Close Dialog

-- 6d. DA: "Format Receipt on Blur"
-- ---------------------------------------------------------------
-- Normalizes receipt number (uppercase, strip non-alphanumeric)
-- when the user tabs out of the field.
--
-- Event:       Lose Focus
-- Selection:   Item → P5_RECEIPT_NUMBER
-- True Actions:
--   1) Execute JavaScript Code:

/*
(function(apex) {
    var item = apex.item('P5_RECEIPT_NUMBER');
    var val = item.getValue();
    if (val) {
        item.setValue(val.toUpperCase().replace(/[^A-Z0-9]/g, ''));
    }
})(apex);
*/

-- ============================================================
-- STEP 7: Page-Level JavaScript — Function and Global
--         Variable Declaration
-- ============================================================
-- In Page Designer → Page 5 → JavaScript →
--   "Function and Global Variable Declaration":
-- Paste the entire block below.
-- This handles the AJAX call, spinner, result rendering, and
-- error display; all wrapped in an IIFE per R-10.

/*
(function(apex, $) {
    "use strict";

    // --------------------------------------------------------
    // Check Status AJAX handler
    // Called by the BTN_CHECK click Dynamic Action
    // --------------------------------------------------------
    window.uscisCheckStatus = function() {
        var receiptItem = apex.item('P5_RECEIPT_NUMBER');
        var receipt = (receiptItem.getValue() || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

        // Client-side validation
        if (!receipt || receipt.length === 0) {
            apex.message.showErrors([{
                type:     'error',
                location: ['page', 'inline'],
                pageItem: 'P5_RECEIPT_NUMBER',
                message:  'Please enter a receipt number.'
            }]);
            return;
        }

        if (!/^[A-Z]{3}[0-9]{10}$/.test(receipt)) {
            apex.message.showErrors([{
                type:     'error',
                location: ['page', 'inline'],
                pageItem: 'P5_RECEIPT_NUMBER',
                message:  'Invalid format. Expected 3 letters + 10 digits (e.g., IOE1234567890).'
            }]);
            return;
        }

        // Normalize
        receiptItem.setValue(receipt);

        // Clear previous messages
        apex.message.clearErrors();

        // Show loading, hide results/errors
        $('#check-loading-region').show();
        $('#check-result-region').hide();
        $('#check-error-region').hide();
        $('#BTN_VIEW_CASE').closest('.t-Button').hide();

        // Disable check button during call
        var $btn = $('#BTN_CHECK');
        $btn.prop('disabled', true).addClass('apex_disabled');

        // AJAX call to server process
        apex.server.process('Check Status', {
            pageItems: '#P5_RECEIPT_NUMBER,#P5_SAVE_TO_DB'
        }, {
            dataType: 'json',
            success: function(data) {
                // Hide spinner
                $('#check-loading-region').hide();
                $btn.prop('disabled', false).removeClass('apex_disabled');

                if (data.success) {
                    // Populate hidden items
                    apex.item('P5_RECEIPT_NUMBER').setValue(data.receiptNumber);
                    apex.item('P5_RESULT_STATUS').setValue(data.currentStatus);
                    apex.item('P5_RESULT_TYPE').setValue(data.caseType);
                    apex.item('P5_RESULT_UPDATED').setValue(data.lastUpdated);
                    apex.item('P5_RESULT_DETAILS').setValue(data.details);
                    apex.item('P5_STATUS_CATEGORY').setValue(data.statusCategory);
                    apex.item('P5_STATUS_ICON').setValue(data.statusIcon);
                    apex.item('P5_ERROR_MESSAGE').setValue('');

                    // Render result card with server data
                    var resultHtml = renderResultCard(data);
                    $('#check-result-region .t-Region-body').html(resultHtml);
                    $('#check-result-region').show();

                    // Show View Case button if saved
                    if (data.saved) {
                        apex.item('P5_CASE_SAVED').setValue('Y');
                        $('#BTN_VIEW_CASE').closest('.t-Button').show();
                    }

                    // Success toast
                    apex.message.showPageSuccess(
                        'Status retrieved for ' + apex.util.escapeHTML(data.receiptNumber)
                    );
                } else {
                    // Show error card
                    showError(data.error || 'An unknown error occurred.');
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                // Hide spinner
                $('#check-loading-region').hide();
                $btn.prop('disabled', false).removeClass('apex_disabled');

                showError('Unable to reach the server. Please check your connection and try again.');
                apex.debug.error('Check Status AJAX error:', textStatus, errorThrown);
            }
        });
    };

    // --------------------------------------------------------
    // Render Result Card HTML
    // --------------------------------------------------------
    function renderResultCard(data) {
        var esc = apex.util.escapeHTML;
        return '<div class="check-result-card">'
            + '  <div class="check-result-card__header">'
            + '    <div class="check-result-card__receipt-info">'
            + '      <span class="uscis-receipt">' + esc(data.receiptNumber) + '</span>'
            + '    </div>'
            + '    <div>'
            + '      <span class="uscis-badge uscis-badge--solid uscis-badge--' + esc(data.statusCategory) + '">'
            + '        <span class="t-Icon fa ' + esc(data.statusIcon) + ' uscis-badge-icon"></span>'
            + '        ' + esc(data.currentStatus)
            + '      </span>'
            + '    </div>'
            + '  </div>'
            + '  <div class="check-result-card__body">'
            + '    <div class="check-result-card__grid">'
            + '      <div class="check-result-card__item">'
            + '        <span class="check-result-card__label">Case Type</span>'
            + '        <span class="check-result-card__value">' + esc(data.caseType || 'Unknown') + '</span>'
            + '      </div>'
            + '      <div class="check-result-card__item">'
            + '        <span class="check-result-card__label">Last Updated</span>'
            + '        <span class="check-result-card__value">' + esc(data.lastUpdated || 'N/A') + '</span>'
            + '      </div>'
            + '    </div>'
            + (data.details
                ? '    <div class="check-result-card__details">'
                + '      <span class="check-result-card__label">Details</span>'
                + '      <p class="check-result-card__detail-text">' + esc(data.details) + '</p>'
                + '    </div>'
                : '')
            + '  </div>'
            + '</div>';
    }

    // --------------------------------------------------------
    // Show Error Card
    // --------------------------------------------------------
    function showError(message) {
        var esc = apex.util.escapeHTML;
        apex.item('P5_ERROR_MESSAGE').setValue(message);
        apex.item('P5_RESULT_STATUS').setValue('');

        var html = '<div class="check-error-card" role="alert">'
            + '  <div class="check-error-card__icon">'
            + '    <span class="t-Icon fa fa-exclamation-triangle"></span>'
            + '  </div>'
            + '  <div class="check-error-card__content">'
            + '    <h3 class="check-error-card__title">Unable to Check Status</h3>'
            + '    <p class="check-error-card__message">' + esc(message) + '</p>'
            + '    <p class="check-error-card__hint">Please verify the receipt number and try again. '
            + '       If the problem persists, the USCIS API may be temporarily unavailable.</p>'
            + '  </div>'
            + '</div>';

        var $region = $('#check-error-region');
        var $body = $region.find('.t-Region-body');
        if ($body.length) {
            $body.html(html);
        } else {
            $region.html(html);
        }
        $region.show();
        $('#check-result-region').hide();
    }

    // --------------------------------------------------------
    // Enter key submits
    // --------------------------------------------------------
    $(document).on('keydown', '#P5_RECEIPT_NUMBER', function(e) {
        if (e.which === 13) {
            e.preventDefault();
            window.uscisCheckStatus();
        }
    });

})(apex, apex.jQuery);
*/

-- ============================================================
-- STEP 8: Page-Level CSS — Inline CSS
-- ============================================================
-- In Page Designer → Page 5 → CSS → Inline:
-- Keep this minimal; most styles live in app-styles.css.
-- Only layout overrides specific to this modal go here.

/*
/* Ensure loading region uses flex center */
#check-loading-region {
    display: none;
    text-align: center;
    padding: 40px 20px;
}
#check-loading-region .t-Region-body {
    display: flex;
    flex-direction: column;
    align-items: center;
}
*/

-- ============================================================
-- STEP 9: Page-Level Properties
-- ============================================================
-- JavaScript → Execute when Page Loads:

/*
(function(apex, $) {
    // Initially hide result, error, and loading regions
    $('#check-result-region').hide();
    $('#check-error-region').hide();
    $('#check-loading-region').hide();
    $('#BTN_VIEW_CASE').closest('.t-Button').hide();

    // Focus receipt number field
    apex.item('P5_RECEIPT_NUMBER').setFocus();
})(apex, apex.jQuery);
*/

-- ============================================================
-- STEP 10: Navigation Menu Entry
-- ============================================================
-- In Shared Components → Navigation Menu:
-- Add or verify entry:
--   Label:     Check Status
--   Icon:      fa-search
--   Target:    Page 5 (Modal)
--   Sequence:  after "Add Case" entry
--   Parent:    (root)

-- ============================================================
-- STEP 11: Add CSS to app-styles.css (Static File)
-- ============================================================
-- See the CHECK STATUS MODAL section added to
-- shared_components/files/app-styles.css
-- Upload via: make upload

PROMPT ============================================================
PROMPT Page 5 (Check Status) patch documented.
PROMPT Apply changes in Page Designer, then upload static files.
PROMPT ============================================================
