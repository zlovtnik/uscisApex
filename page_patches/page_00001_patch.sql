-- ============================================================
-- Page 1 Patch: Dashboard → Template Components
-- ============================================================
-- File: page_patches/page_00001_patch.sql
--
-- Changes:
--   1. Chart SQL: Replace hard-coded hex colors with package call
--   2. Summary Cards: Use USCIS Metric Card template markup
--   3. Recent Activity: Use USCIS Activity Item template markup
--   4. Inline CSS: Remove dash-card (now in static file)
--
-- Apply via: Page Designer (recommended)
-- ============================================================

-- ============================================================
-- CHANGE 1: Updated Chart Series SQL
-- ============================================================
-- In Page Designer → Cases by Status chart → Series → SQL:

/*
-- OLD:
SELECT
  NVL(current_status, 'Unknown') AS status_label,
  case_count,
  CASE
    WHEN current_status LIKE '%Approved%' THEN '#2e8540'
    WHEN current_status LIKE '%Denied%'   THEN '#cd2026'
    WHEN current_status LIKE '%RFE%'      THEN '#0071bc'
    WHEN current_status LIKE '%Received%' THEN '#4c2c92'
    WHEN current_status LIKE '%Pending%'  THEN '#fdb81e'
    ELSE '#5b616b'
  END AS status_color
FROM v_case_dashboard
ORDER BY case_count DESC
FETCH FIRST 8 ROWS ONLY


-- NEW (Template Component: centralized color function — P7):
SELECT
  NVL(current_status, 'Unknown') AS status_label,
  case_count,
  uscis_template_components_pkg.get_status_color_from_text(current_status) AS status_color
FROM v_case_dashboard
ORDER BY case_count DESC
FETCH FIRST 8 ROWS ONLY
*/

-- ============================================================
-- CHANGE 2: Updated Summary Cards PL/SQL
-- ============================================================
-- In Page Designer → Summary Cards region → Source:

/*
-- OLD PL/SQL (hard-coded HTML with .dash-card):
DECLARE
  l_total       NUMBER := 0;
  l_active      NUMBER := 0;
  l_today       NUMBER := 0;
  l_stale       NUMBER := 0;
  l_html        VARCHAR2(32767);
BEGIN
  ...
  l_html := '<div class="row">';
  -- Card 1: Total
  l_html := l_html
    || '<div class="col col-3">'
    || '<div class="dash-card"><span class="t-Icon fa fa-briefcase u-color-1-text" style="font-size:24px"></span>'
    || '<div class="card-value">' || l_total || '</div>'
    || '<div class="card-label">Total Cases</div>'
    || '<div class="card-sub">All tracked cases</div>'
    || '</div></div>';
  ...
  htp.p(l_html);
END;


-- NEW PL/SQL (Template Component: USCIS Metric Card — P7):
DECLARE
  l_total       NUMBER := 0;
  l_active      NUMBER := 0;
  l_today       NUMBER := 0;
  l_stale       NUMBER := 0;
  l_html        VARCHAR2(32767);
BEGIN
  -- Total cases
  SELECT COUNT(*) INTO l_total FROM case_history;
  -- Active cases
  SELECT COUNT(*) INTO l_active FROM case_history WHERE is_active = 1;
  -- Updated today
  BEGIN
    SELECT COUNT(*) INTO l_today
    FROM status_updates
    WHERE created_at >= TRUNC(SYSDATE)
      AND created_at <  TRUNC(SYSDATE) + 1;
  EXCEPTION WHEN OTHERS THEN
    -- Log the root cause before defaulting (P3/audit best practice)
    apex_debug.error(
        p_message => 'page_00001 l_today query failed: %s %s',
        p0        => SQLERRM,
        p1        => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
    l_today := 0;
  END;
  -- Stale (not checked in 7+ days)
  SELECT COUNT(*) INTO l_stale
  FROM case_history
  WHERE is_active = 1
    AND (last_checked_at < SYSDATE - 7 OR last_checked_at IS NULL);

  l_html := '<div class="row">';

  -- Card 1: Total Cases (Template Component: uscis-metric-card)
  l_html := l_html
    || '<div class="col col-3">'
    || '<div class="uscis-metric-card">'
    || '<span class="t-Icon fa fa-briefcase u-color-1-text uscis-metric-card__icon"></span>'
    || '<div class="uscis-metric-card__value">' || l_total || '</div>'
    || '<div class="uscis-metric-card__label">Total Cases</div>'
    || '<div class="uscis-metric-card__sub">All tracked cases</div>'
    || '</div></div>';

  -- Card 2: Active Cases
  l_html := l_html
    || '<div class="col col-3">'
    || '<div class="uscis-metric-card">'
    || '<span class="t-Icon fa fa-check-circle u-success-text uscis-metric-card__icon"></span>'
    || '<div class="uscis-metric-card__value">' || l_active || '</div>'
    || '<div class="uscis-metric-card__label">Active Cases</div>'
    || '<div class="uscis-metric-card__sub">Currently monitoring</div>'
    || '</div></div>';

  -- Card 3: Updated Today
  l_html := l_html
    || '<div class="col col-3">'
    || '<div class="uscis-metric-card">'
    || '<span class="t-Icon fa fa-bell u-warning-text uscis-metric-card__icon"></span>'
    || '<div class="uscis-metric-card__value">' || l_today || '</div>'
    || '<div class="uscis-metric-card__label">Updated Today</div>'
    || '<div class="uscis-metric-card__sub">Recent status changes</div>'
    || '</div></div>';

  -- Card 4: Pending Check
  l_html := l_html
    || '<div class="col col-3">'
    || '<div class="uscis-metric-card">'
    || '<span class="t-Icon fa fa-clock-o u-info-text uscis-metric-card__icon"></span>'
    || '<div class="uscis-metric-card__value">' || l_stale || '</div>'
    || '<div class="uscis-metric-card__label">Pending Check</div>'
    || '<div class="uscis-metric-card__sub">Not checked in 7+ days</div>'
    || '</div></div>';

  l_html := l_html || '</div>';

  htp.p(l_html);
END;
*/

-- ============================================================
-- CHANGE 3: Updated Recent Activity PL/SQL
-- ============================================================
-- In Page Designer → Recent Activity region → Source:

/*
-- OLD activity markup:
  || '<div class="activity-item">'
  || '<span class="t-Icon ' || rec.icon_cls || '" style="margin-right:6px"></span>'
  || '<span class="activity-desc">' || ... || '</span>'
  || '<div class="activity-time">' || ... || '</div>'
  || '</div>';

-- NEW activity markup (Template Component: uscis-activity-item):
-- NOTE: rec.icon_cls is sourced from a controlled CASE expression in the
-- cursor query (e.g., 'fa fa-plus', 'fa fa-refresh') — it is never
-- user-supplied input. We escape it defensively per P8/P7 best practice.
  || '<div class="uscis-activity-item">'
  || '<span class="t-Icon ' || apex_escape.html_attribute(rec.icon_cls) || ' uscis-activity-item__icon"></span>'
  || '<span class="uscis-activity-item__desc">' || apex_escape.html(rec.action_description) || '</span>'
  || '<div class="uscis-activity-item__time">' || apex_escape.html(rec.event_time) || '</div>'
  || '</div>';

-- Note: The "no activity" empty state also uses the new class:
  || '<div style="padding:24px;text-align:center">'
  || '<span class="t-Icon fa fa-info-circle" style="font-size:20px;color:var(--ut-component-text-muted-color,#999)"></span><br>'
  || 'No recent activity yet. Add a case to get started!'
  || '</div>';
*/

-- ============================================================
-- CHANGE 4: Simplified Inline CSS
-- ============================================================
-- Remove .dash-card, .card-value, .card-label, .card-sub,
-- .activity-item, .activity-time, .activity-desc
-- All these are now in template_components.css

/*
-- NEW inline CSS for Page 1 (can be empty or minimal):
-- All styling is handled by template_components.css
-- Only add page-specific overrides here if needed.
*/

PROMPT ============================================================
PROMPT Page 1 patch documented. Apply changes in Page Designer.
PROMPT ============================================================
