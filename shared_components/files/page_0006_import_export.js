/**
 * USCIS Case Tracker — Page 6: Import/Export
 * Tasks 4.2.4 (Progress Indicator) + 4.2.6 (Large File Handling)
 *
 * Conventions:
 *   - IIFE wrapping per R-10
 *   - Native messaging per R-08 (apex.message)
 *   - No inline styles per R-11 (CSP compliance)
 *   - apex.util.escapeHTML per R-13
 */
(function (apex, $) {
    "use strict";

    /* ==========================================================
       Namespace
       ========================================================== */
    var USCIS = window.USCIS || (window.USCIS = {});

    USCIS.ImportExport = (function () {

        /* --------------------------------------------------
           Constants
           -------------------------------------------------- */
        var MAX_FILE_SIZE  = 10 * 1024 * 1024, // 10 MB
            ALLOWED_EXTS   = [".json"],
            ITEMS = {
                importFile:       "P6_IMPORT_FILE",
                replaceExisting:  "P6_REPLACE_EXISTING",
                importPreview:    "P6_IMPORT_PREVIEW",
                importResult:     "P6_IMPORT_RESULT",
                importedCount:    "P6_IMPORTED_COUNT",
                importErrors:     "P6_IMPORT_ERRORS",
                importResultMsg:  "P6_IMPORT_RESULT_MSG",
                exportFormat:     "P6_EXPORT_FORMAT",
                exportFilter:     "P6_EXPORT_FILTER",
                includeHistory:   "P6_INCLUDE_HISTORY",
                exportActiveOnly: "P6_EXPORT_ACTIVE_ONLY"
            };

        /* --------------------------------------------------
           Private state
           -------------------------------------------------- */
        var _spinnerEl  = null,
            _exportSpinnerEl = null,
            _initialized = false;

        /* --------------------------------------------------
           Private helpers
           -------------------------------------------------- */

        /**
         * Get the import region container for spinner placement.
         */
        function _getImportRegion() {
            return $("#import_region");
        }

        /**
         * Show a spinner overlay on the import region with a message.
         * Uses APEX native apex.util.showSpinner.
         */
        function _showProgress(message) {
            var $region = _getImportRegion();

            // Add progress overlay class for CSS styling
            $region.addClass("is-importing");

            // Show APEX native spinner scoped to the import region
            _spinnerEl = apex.util.showSpinner($region);

            // Show a status message below the spinner if the element exists
            var $msg = $region.find(".js-import-progress-msg");
            if ($msg.length) {
                $msg.text(message || "Importing cases\u2026").show();
            }
        }

        /**
         * Hide the progress overlay.
         */
        function _hideProgress() {
            var $region = _getImportRegion();
            $region.removeClass("is-importing");

            if (_spinnerEl) {
                _spinnerEl.remove();
                _spinnerEl = null;
            }

            var $msg = $region.find(".js-import-progress-msg");
            if ($msg.length) {
                $msg.hide();
            }
        }

        /**
         * Display import result using APEX native messaging.
         */
        function _showResult(type, msg) {
            apex.message.clearErrors();

            if (type === "SUCCESS") {
                apex.message.showPageSuccess(msg);
            } else if (type === "WARNING") {
                apex.message.showErrors([{
                    type:    "warning",
                    location: "page",
                    message:  msg,
                    unsafe:   false
                }]);
            } else {
                apex.message.showErrors([{
                    type:    "error",
                    location: "page",
                    message:  msg,
                    unsafe:   false
                }]);
            }
        }

        /**
         * Validate file extension.
         */
        function _isAllowedExtension(filename) {
            if (!filename) return false;
            var dotIndex = filename.lastIndexOf(".");
            if (dotIndex <= 0) return false; // no dot, or dot at start (e.g., ".hidden")
            var ext = filename.substring(dotIndex).toLowerCase();
            return ALLOWED_EXTS.indexOf(ext) !== -1;
        }

        /* --------------------------------------------------
           Drag-and-drop enhancement
           -------------------------------------------------- */
        function _setupDragAndDrop() {
            var $container = $(".t-Body-contentInner");
            if (!$container.length) return;

            // Prevent default drag behaviors globally
            $(document).on("dragover drop", function (e) {
                e.preventDefault();
                e.stopPropagation();
            });

            $container
                .on("dragenter dragover", function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    $container.addClass("drag-over");
                })
                .on("dragleave drop", function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    $container.removeClass("drag-over");
                })
                .on("drop", function (e) {
                    var dt = e.originalEvent.dataTransfer;
                    if (!dt || !dt.files || !dt.files.length) return;

                    var file = dt.files[0];

                    // Validate file
                    if (!_isAllowedExtension(file.name)) {
                        _showResult("FAILED",
                            "Invalid file type. Please use a .json file.");
                        return;
                    }
                    if (file.size > MAX_FILE_SIZE) {
                        _showResult("FAILED",
                            "File too large. Maximum size is 10 MB.");
                        return;
                    }

                    // Set the file into the APEX file input item
                    // APEX file browse items accept files via DataTransfer
                    var $fileInput = $("#" + ITEMS.importFile + "_input");
                    if ($fileInput.length && $fileInput[0]) {
                        if (typeof DataTransfer === "function") {
                            var newDt = new DataTransfer();
                            for (var i = 0; i < dt.files.length; i++) {
                                newDt.items.add(dt.files[i]);
                            }
                            $fileInput[0].files = newDt.files;
                            $fileInput.trigger("change");
                        } else {
                            _showResult("FAILED",
                                "Drag-and-drop file upload is not supported in this browser.");
                        }
                    }
                });
        }

        /* --------------------------------------------------
           File validation on selection
           -------------------------------------------------- */
        function _setupFileValidation() {
            $(document).on("change", "#" + ITEMS.importFile, function () {
                // APEX file browse stores the filename in the display span
                // We rely on server-side validation for full enforcement
                apex.message.clearErrors();
            });
        }

        /* --------------------------------------------------
           Import submit hook — show progress on submit
           -------------------------------------------------- */
        function _setupImportProgress() {
            // Hook into the APEX page submit to show spinner
            // when the IMPORT button is clicked
            $(document).on("click", "#BTN_IMPORT", function () {
                // Small delay to allow APEX to start submission
                setTimeout(function () {
                    _showProgress("Importing cases\u2026");
                }, 50);
            });

            // Also hook the PREVIEW button 
            $(document).on("click", "#BTN_PREVIEW", function () {
                setTimeout(function () {
                    _showProgress("Validating file\u2026");
                }, 50);
            });

            // Also hook the EXPORT button
            $(document).on("click", "#BTN_EXPORT", function () {
                setTimeout(function () {
                    _showExportProgress();
                }, 50);
            });
        }

        /**
         * Show a spinner overlay on the export region with the exporting state.
         * Mirrors _showProgress for the import region.
         */
        function _showExportProgress() {
            var $exportRegion = $("#export_region");
            if (!$exportRegion.length) return;

            $exportRegion.addClass("is-exporting");
            _exportSpinnerEl = apex.util.showSpinner($exportRegion);
        }

        /**
         * Hide the export progress spinner and remove the exporting state.
         * Call from the export-completion callback or DA.
         */
        function _hideExportProgress() {
            var $exportRegion = $("#export_region");
            if (_exportSpinnerEl) {
                _exportSpinnerEl.remove();
                _exportSpinnerEl = null;
            }
            $exportRegion.removeClass("is-exporting");
        }

        /**
         * Show results after page load (server set the hidden items).
         * Called from init when the result items have values.
         */
        function _checkForResults() {
            var result    = apex.item(ITEMS.importResult).getValue(),
                resultMsg = apex.item(ITEMS.importResultMsg).getValue(),
                count     = apex.item(ITEMS.importedCount).getValue(),
                errors    = apex.item(ITEMS.importErrors).getValue();

            if (!result) return;

            _hideProgress();

            if (result === "SUCCESS") {
                var msg = count
                    ? count + " case(s) imported successfully."
                    : "Import completed.";
                _showResult("SUCCESS", msg);
            } else if (result === "WARNING") {
                _showResult("WARNING",
                    resultMsg || "No cases were imported.");
            } else if (result === "FAILED") {
                var errMsg = "Import failed.";
                if (errors) {
                    errMsg += " Error ID: " + apex.util.escapeHTML(errors);
                }
                _showResult("FAILED", errMsg);
            }
        }

        /* --------------------------------------------------
           Public API
           -------------------------------------------------- */
        return {

            /**
             * Initialize the Import/Export module.
             * Called from Page DA "Initialize Page JS" on page ready.
             */
            init: function () {
                if (_initialized) return;
                _initialized = true;

                _setupDragAndDrop();
                _setupFileValidation();
                _setupImportProgress();

                // Check if we have results from a server round-trip
                _checkForResults();
            },

            /**
             * Clear all import-related form items and results.
             * Called from DA "Clear Import Form" → BTN_CLEAR click.
             */
            clearImportForm: function () {
                // Clear APEX items
                apex.item(ITEMS.importFile).setValue("");
                apex.item(ITEMS.replaceExisting).setValue("N");
                apex.item(ITEMS.importPreview).setValue("");
                apex.item(ITEMS.importResult).setValue("");
                apex.item(ITEMS.importedCount).setValue("");
                apex.item(ITEMS.importErrors).setValue("");
                apex.item(ITEMS.importResultMsg).setValue("");

                // Clear any messages
                apex.message.clearErrors();
                apex.message.hidePageSuccess();

                // Remove progress state
                _hideProgress();
            },

            /**
             * Show a loading/progress overlay on the import region.
             * Can be called externally (e.g., from DA).
             */
            showProgress: function (message) {
                _showProgress(message);
            },

            /**
             * Hide the progress overlay.
             */
            hideProgress: function () {
                _hideProgress();
            },

            /**
             * Hide the export spinner and remove the exporting state.
             * Call from export-completion DA or callback.
             */
            hideExportProgress: function () {
                _hideExportProgress();
            },

            /**
             * Show a spinner overlay on the export region.
             * Can be called externally (e.g., from DA).
             */
            showExportProgress: function () {
                _showExportProgress();
            }
        };

    })(); // end USCIS.ImportExport IIFE

})(apex, apex.jQuery);
