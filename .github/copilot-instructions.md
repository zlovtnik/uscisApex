# USCIS Case Tracker — AI Agent Instructions

Oracle APEX 24.2 app (ID 102) on Oracle DB 19c+. Schema: `USCIS_APP`. Tracks USCIS immigration case statuses via the USCIS API with OAuth2.

## Architecture

- **Database layer:** 6 tables (`CASE_HISTORY` PK=receipt_number, `STATUS_UPDATES`, `OAUTH_TOKENS`, `API_RATE_LIMITER`, `CASE_AUDIT_LOG`, `SCHEDULER_CONFIG`), 3 key views (`V_CASE_CURRENT_STATUS`, `V_CASE_DASHBOARD`, `V_RECENT_ACTIVITY`)
- **PL/SQL packages** (`packages/01-10`): Installed in numbered order — each depends on predecessors. Core flow: `USCIS_UTIL_PKG` (validation) → `USCIS_CASE_PKG` (CRUD) → `USCIS_OAUTH_PKG` + `USCIS_API_PKG` (external API). `USCIS_TEMPLATE_COMPONENTS_PKG` (09) is the **single source of truth** for status→CSS class mapping. `USCIS_ERROR_PKG` (10) is the APEX application-level error handler.
- **APEX app export:** `apex/f102/` — machine-generated SQL. **Never hand-edit** files there (they contain `wwv_flow_imp` calls which are fine in exports only).
- **Page patches** (`page_patches/`): Human-readable change descriptions meant to be applied manually via Page Designer, not run as scripts.
- **Static files:** `shared_components/files/` contains `app-styles.css`, `template_components.css`, `template_components.js`.

## Developer Workflows

All commands use **SQLcl** (not SQL*Plus). Connection config: `apex.env` (template) → copy to `apex.env.local` (gitignored, real credentials).

```sh
make install          # Full DB install (tables + packages 01-10) — runs install_all_v2.sql
make packages-install # Reinstall all PL/SQL packages (01-10), including USCIS_TEMPLATE_COMPONENTS_PKG (09) and USCIS_ERROR_PKG (10)
make import           # Import APEX app from apex/f102/
make upload           # Upload static CSS/JS files
make deploy           # import + upload
make test             # Run utPLSQL tests: exec ut.run()
make connect          # Interactive SQLcl session
make info             # Show app/connection/APEX version info
make export           # Export APEX app back to SQL files
```

Override defaults: `make import CONNECTION=ADMIN APP_ID=200`

## Mandatory Coding Rules

Read `docs/APEX_24_REVIEW.md` for full before/after examples. Read `docs/APEX_CONTEXTUAL_ANCHOR.md` for AI-specific principles.

| Rule | What to do |
|------|-----------|
| **No internal APIs** (R-01) | Never call `wwv_flow_imp.*` in hand-written code; use `wwv_flow_api.*` or `APEX_*` packages |
| **Session context** (R-02) | Use `apex_session.create_session(...)` — not `apex_util.set_security_group_id` |
| **Bind variables** (R-12) | Always `:P1_ITEM` or `:bind` — never concatenate user input into SQL |
| **Escape output** (R-13) | PL/SQL: `apex_escape.html()` — JS: `apex.util.escapeHTML()` |
| **CSS variables** (R-05) | Override `--ut-*` / `--a-*` custom properties — never `!important` on `.t-*` classes |
| **JS IIFE wrapping** (R-10) | `(function(apex, $){ ... })(apex, apex.jQuery)` |
| **Native messaging** (R-08) | `apex.message.showPageSuccess()` / `.showErrors()` — no custom toast DOM |
| **LOB cleanup** (R-04) | Every `DBMS_LOB.CREATETEMPORARY` needs `FREETEMPORARY` in both success and exception paths |
| **CSP compliance** (R-11) | No inline `<style>`, no `eval()`, no `javascript:` URIs — all CSS in static files |

## Key Domain Patterns

- **Receipt numbers:** 3 letters + 10 digits (e.g., `IOE1234567890`). Always validate/normalize via `USCIS_UTIL_PKG.validate_receipt_number()` / `normalize_receipt_number()`.
- **Status classification:** Call `USCIS_TEMPLATE_COMPONENTS_PKG.get_status_category(p_status)` — returns `approved|denied|rfe|received|pending|transferred|unknown`. Never duplicate CASE logic.
- **Status CSS:** `get_status_css_class()` returns `status-approved`, `status-denied`, etc. Colors: green=#2e8540, red=#cd2026, yellow=#fdb81e, blue=#0071bc, purple=#4c2c92, gray=#5b616b.
- **All packages** use `AUTHID CURRENT_USER`, define `gc_version`/`gc_package_name` constants, and use custom exceptions with `PRAGMA EXCEPTION_INIT`.

## Testing

utPLSQL framework. Test files in `tests/`. Convention: test receipt numbers use `TST` prefix.

```sql
exec ut.run('ut_uscis_case_pkg');       -- One package
exec ut.run('ut_uscis%');               -- All USCIS tests
```

## Documentation Lookup

- **APEX PL/SQL API:** `apex_24doc/content/aeapi/APEX_{PKG}.html` (e.g., `APEX_AI.html`, `APEX_EXEC.html`)
- **APEX JS API:** `apex_24doc/content/aexjs/` (`apex.page`, `apex.region`, `apex.item`, `apex.server`)
- **App Builder guide:** `apex_24doc/content/htmdb/`
- **Project design docs:** `docs/APEX_FRONTEND_DESIGN.md` (UI/CSS), `docs/ORACLE_APEX_MIGRATION_SPEC.md` (architecture), `docs/MIGRATION_ROADMAP.md` (task status)
