-- ============================================================
-- USCIS Case Tracker - Template Components Helper Package
-- Task P7: Centralized status classification & Template
--          Component rendering support
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: packages/09_uscis_template_components_pkg.sql
-- Purpose: Single source of truth for status-to-CSS-class mapping,
--          status color resolution, and Template Component helpers.
--          Eliminates triplicated CASE logic across pages 1, 3, 22
--          and 3+ JavaScript files.
-- Dependencies: USCIS_TYPES_PKG
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating USCIS_TEMPLATE_COMPONENTS_PKG...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE uscis_template_components_pkg
AUTHID CURRENT_USER
AS
    -- ========================================================
    -- Package Version
    -- ========================================================
    gc_version      CONSTANT VARCHAR2(10) := '1.0.0';
    gc_package_name CONSTANT VARCHAR2(40) := 'USCIS_TEMPLATE_COMPONENTS_PKG';

    -- ========================================================
    -- Status Category Constants
    -- ========================================================
    gc_status_approved    CONSTANT VARCHAR2(20) := 'approved';
    gc_status_denied      CONSTANT VARCHAR2(20) := 'denied';
    gc_status_rfe         CONSTANT VARCHAR2(20) := 'rfe';
    gc_status_received    CONSTANT VARCHAR2(20) := 'received';
    gc_status_pending     CONSTANT VARCHAR2(20) := 'pending';
    gc_status_transferred CONSTANT VARCHAR2(20) := 'transferred';
    gc_status_unknown     CONSTANT VARCHAR2(20) := 'unknown';

    -- ========================================================
    -- Status Classification (Single Source of Truth)
    -- ========================================================

    /**
     * Classify a raw USCIS status string into a status category.
     * Returns one of: approved, denied, rfe, received, pending,
     *                  transferred, unknown
     *
     * This replaces the duplicated CASE logic in:
     *   - page_00022.sql  (SQL CASE in IG query)
     *   - page_00003.sql  (PL/SQL CASE in Before Header process)
     *   - getStatusClass() in 3 JavaScript files
     *
     * @param p_status  Raw status text from USCIS API or manual entry
     * @return Status category key (no prefix, no CSS class — just the key)
     */
    FUNCTION get_status_category(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    /**
     * Get the CSS class name for a given status category.
     * Returns 'status-{category}' (e.g. 'status-approved').
     * Suitable for direct use in class="" attributes.
     *
     * @param p_status  Raw status text
     * @return CSS class name with 'status-' prefix
     */
    FUNCTION get_status_css_class(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    /**
     * Get the Universal Theme utility class for a status category.
     * Maps to UT semantic color classes for Template Components.
     *
     * @param p_status_category  Status category key (from get_status_category)
     * @return UT utility class (e.g. 'u-success', 'u-danger')
     */
    FUNCTION get_ut_color_class(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    /**
     * Get the Font Awesome icon class for a status category.
     *
     * @param p_status_category  Status category key
     * @return FA icon class (e.g. 'fa-check-circle')
     */
    FUNCTION get_status_icon(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    /**
     * Get the hex color code for a status category.
     * Used by chart regions and anywhere raw color is needed.
     *
     * @param p_status_category  Status category key
     * @return Hex color code (e.g. '#2e8540')
     */
    FUNCTION get_status_color(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    /**
     * Get the hex color for a raw status string (convenience wrapper).
     *
     * @param p_status  Raw status text
     * @return Hex color code
     */
    FUNCTION get_status_color_from_text(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

END uscis_template_components_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY uscis_template_components_pkg AS

    -- --------------------------------------------------------
    -- get_status_category
    -- Single source of truth for status classification
    -- --------------------------------------------------------
    FUNCTION get_status_category(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
        l_upper VARCHAR2(4000) := UPPER(p_status);
    BEGIN
        IF l_upper IS NULL THEN
            RETURN gc_status_unknown;
        END IF;

        -- Denied / Negative outcomes (check before Approved — 
        -- "NOT APPROVED" must match denied, not approved)
        IF    l_upper LIKE '%NOT APPROVED%'
           OR l_upper LIKE '%DENIED%'
           OR l_upper LIKE '%REJECT%'
           OR l_upper LIKE '%TERMINAT%'
           OR l_upper LIKE '%WITHDRAWN%'
           OR l_upper LIKE '%REVOKED%'
        THEN
            RETURN gc_status_denied;
        END IF;

        -- Approved / Positive outcomes
        IF    l_upper LIKE '%APPROVED%'
           OR l_upper LIKE '%CARD WAS PRODUCED%'
           OR l_upper LIKE '%CARD IS BEING PRODUCED%'
           OR l_upper LIKE '%CARD WAS DELIVERED%'
           OR l_upper LIKE '%CARD WAS MAILED%'
           OR l_upper LIKE '%CARD WAS PICKED UP%'
           OR l_upper LIKE '%OATH CEREMONY%'
           OR l_upper LIKE '%WELCOME NOTICE%'
        THEN
            RETURN gc_status_approved;
        END IF;

        -- Request for Evidence
        IF    l_upper LIKE '%EVIDENCE%'
           OR l_upper LIKE '%RFE%'
        THEN
            RETURN gc_status_rfe;
        END IF;

        -- Received / Accepted
        IF    l_upper LIKE '%RECEIVED%'
           OR l_upper LIKE '%ACCEPTED%'
           OR l_upper LIKE '%FEE WAS%'
        THEN
            RETURN gc_status_received;
        END IF;

        -- Pending / In Progress
        IF    l_upper LIKE '%FINGERPRINT%'
           OR l_upper LIKE '%INTERVIEW%'
           OR l_upper LIKE '%PROCESSING%'
           OR l_upper LIKE '%REVIEW%'
           OR l_upper LIKE '%PENDING%'
           OR l_upper LIKE '%SCHEDULED%'
        THEN
            RETURN gc_status_pending;
        END IF;

        -- Transferred
        IF    l_upper LIKE '%TRANSFER%'
           OR l_upper LIKE '%RELOCATED%'
           OR l_upper LIKE '%SENT TO%'
        THEN
            RETURN gc_status_transferred;
        END IF;

        RETURN gc_status_unknown;
    END get_status_category;

    -- --------------------------------------------------------
    -- get_status_css_class
    -- --------------------------------------------------------
    FUNCTION get_status_css_class(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN 'status-' || get_status_category(p_status);
    END get_status_css_class;

    -- --------------------------------------------------------
    -- get_ut_color_class
    -- Maps status category to Universal Theme semantic class
    -- --------------------------------------------------------
    FUNCTION get_ut_color_class(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN CASE p_status_category
            WHEN gc_status_approved    THEN 'u-success'
            WHEN gc_status_denied      THEN 'u-danger'
            WHEN gc_status_rfe         THEN 'u-info'
            WHEN gc_status_received    THEN 'u-color-14'
            WHEN gc_status_pending     THEN 'u-warning'
            WHEN gc_status_transferred THEN 'u-color-16'
            ELSE 'u-color-7'
        END;
    END get_ut_color_class;

    -- --------------------------------------------------------
    -- get_status_icon
    -- --------------------------------------------------------
    FUNCTION get_status_icon(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN CASE p_status_category
            WHEN gc_status_approved    THEN 'fa-check-circle'
            WHEN gc_status_denied      THEN 'fa-times-circle'
            WHEN gc_status_rfe         THEN 'fa-file-text-o'
            WHEN gc_status_received    THEN 'fa-inbox'
            WHEN gc_status_pending     THEN 'fa-clock-o'
            WHEN gc_status_transferred THEN 'fa-exchange'
            ELSE 'fa-question-circle'
        END;
    END get_status_icon;

    -- --------------------------------------------------------
    -- get_status_color
    -- --------------------------------------------------------
    FUNCTION get_status_color(
        p_status_category IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN CASE p_status_category
            WHEN gc_status_approved    THEN '#2e8540'
            WHEN gc_status_denied      THEN '#cd2026'
            WHEN gc_status_rfe         THEN '#0071bc'
            WHEN gc_status_received    THEN '#4c2c92'
            WHEN gc_status_pending     THEN '#fdb81e'
            WHEN gc_status_transferred THEN '#006064'
            ELSE '#5b616b'
        END;
    END get_status_color;

    -- --------------------------------------------------------
    -- get_status_color_from_text
    -- --------------------------------------------------------
    FUNCTION get_status_color_from_text(
        p_status IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN get_status_color(get_status_category(p_status));
    END get_status_color_from_text;

END uscis_template_components_pkg;
/

SHOW ERRORS PACKAGE uscis_template_components_pkg
SHOW ERRORS PACKAGE BODY uscis_template_components_pkg

PROMPT ============================================================
PROMPT USCIS_TEMPLATE_COMPONENTS_PKG created successfully
PROMPT ============================================================
