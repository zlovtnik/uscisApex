/* ============================================================
   USCIS Case Tracker - Template Components JavaScript
   ============================================================
   File: shared_components/files/template_components.js
   
   Purpose:
     Single source of truth for client-side status classification.
     Replaces getStatusClass() duplicated across:
       - upload_inline.sql
       - upload_enhanced_files.sql
       - upload-static-files.sh
   
   Uses the apex.* namespace exclusively (P4).
   Wrapped in IIFE (P6/R-10). CSP compliant.
   ============================================================ */

(function(apex, $) {
    "use strict";

    /**
     * USCIS Template Components namespace.
     * Provides client-side equivalents of USCIS_TEMPLATE_COMPONENTS_PKG functions.
     */
    var USCIS_TC = window.USCIS_TC || {};

    /**
     * Status classification rules — mirrors 
     * uscis_template_components_pkg.get_status_category exactly.
     * Order matters: denied must be checked before approved
     * so "NOT APPROVED" resolves correctly.
     */
    var STATUS_RULES = [
        { category: "denied",      patterns: ["NOT APPROVED", "DENIED", "REJECT", "TERMINAT", "WITHDRAWN", "REVOKED"] },
        { category: "approved",    patterns: ["APPROVED", "CARD WAS PRODUCED", "CARD IS BEING PRODUCED", "CARD WAS DELIVERED", "CARD WAS MAILED", "CARD WAS PICKED UP", "OATH CEREMONY", "WELCOME NOTICE"] },
        { category: "rfe",         patterns: ["EVIDENCE", "RFE"] },
        { category: "received",    patterns: ["RECEIVED", "ACCEPTED", "FEE WAS"] },
        { category: "pending",     patterns: ["FINGERPRINT", "INTERVIEW", "PROCESSING", "REVIEW", "PENDING", "SCHEDULED"] },
        { category: "transferred", patterns: ["TRANSFER", "RELOCATED", "SENT TO"] }
    ];

    /**
     * Classify a raw status string into a category key.
     * @param {string} status - Raw USCIS status text
     * @returns {string} Category key: approved|denied|rfe|received|pending|transferred|unknown
     */
    USCIS_TC.getStatusCategory = function(status) {
        if (!status) return "unknown";
        var upper = status.toUpperCase();
        for (var i = 0; i < STATUS_RULES.length; i++) {
            var rule = STATUS_RULES[i];
            for (var j = 0; j < rule.patterns.length; j++) {
                if (upper.indexOf(rule.patterns[j]) !== -1) {
                    return rule.category;
                }
            }
        }
        return "unknown";
    };

    /**
     * Get the CSS badge class (new BEM naming).
     * @param {string} status - Raw status text
     * @returns {string} e.g. "uscis-badge--approved"
     */
    USCIS_TC.getBadgeClass = function(status) {
        return "uscis-badge--" + USCIS_TC.getStatusCategory(status);
    };

    /**
     * Get the backward-compatible CSS class.
     * @param {string} status - Raw status text
     * @returns {string} e.g. "status-approved"
     */
    USCIS_TC.getStatusClass = function(status) {
        return "status-" + USCIS_TC.getStatusCategory(status);
    };

    /**
     * Apply status badge styling to all matching elements on the page.
     * Call on page load or after AJAX refreshes.
     * @param {string} [selector=".js-status-text"] - CSS selector for status elements
     */
    USCIS_TC.applyStatusBadges = function(selector) {
        selector = selector || ".js-status-text";
        $(selector).each(function() {
            var $el = $(this);
            var statusText = $.trim($el.text());
            if (statusText) {
                var category = USCIS_TC.getStatusCategory(statusText);
                // Remove any existing status classes
                $el.removeClass(function(i, cls) {
                    return (cls.match(/(^|\s)(uscis-badge--|status-)\S+/g) || []).join(" ");
                });
                // Add new BEM class + base class
                $el.addClass("uscis-badge uscis-badge--" + category);
            }
        });
    };

    // Backward compatibility: expose as USCIS.getStatusClass if USCIS namespace exists
    if (window.USCIS) {
        window.USCIS.getStatusClass = function(status) {
            // Return CSS class format (e.g., "status-approved") for backward compat
            return "status-" + USCIS_TC.getStatusCategory(status);
        };
    }

    // Export namespace
    window.USCIS_TC = USCIS_TC;

    // Auto-apply on page ready (for existing .js-status-text elements)
    $(function() {
        USCIS_TC.applyStatusBadges();
    });

})(apex, apex.jQuery);
