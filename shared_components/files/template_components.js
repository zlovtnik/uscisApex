/* ============================================================
   USCIS Case Tracker - Template Components JavaScript
   ============================================================
   File: shared_components/files/template_components.js
   
     Purpose:
         Status classification now happens server-side via
         USCIS_TEMPLATE_COMPONENTS_PKG and the Status Badge template
         component uses Universal Theme pill classes. Client-side
         helpers are intentionally minimal (no custom CSS/JS mapping).
   ============================================================ */

(function(apex, $) {
    "use strict";

    // Minimal namespace to avoid runtime errors if referenced.
    // Legacy callers may invoke getStatusCategory, getBadgeClass, or getStatusClass;
    // these stubs return safe defaults so external code does not throw.
    window.USCIS_TC = {
        applyStatusBadges: function() {
            // No client-side classification; badges rendered via template component.
            return null;
        },
        getStatusCategory: function(/* statusText */) {
            // Legacy: previously classified raw status text client-side.
            // Now handled server-side by USCIS_TEMPLATE_COMPONENTS_PKG.GET_STATUS_CATEGORY.
            return null;
        },
        getBadgeClass: function(/* statusCategory */) {
            // Legacy: returned CSS badge class for a status category.
            // Now derived server-side; returns empty string as safe default.
            return '';
        },
        getStatusClass: function(/* statusText */) {
            // Legacy: returned 'status-{category}' CSS class for raw status text.
            // Now derived server-side via GET_STATUS_CSS_CLASS; returns empty string.
            return '';
        }
    };

})(apex, apex.jQuery);
