# USCIS Case Tracker - Oracle APEX 24.2 Development Instructions

This project uses **Oracle APEX 24.2** (Application Express) with **Oracle Database 19c+**. Follow these guidelines when working with the codebase.

---

## Project Documentation Index

### Core Project Documentation

| Document | Purpose | When to Reference |
|----------|---------|-------------------|
| [README.md](../README.md) | Database tables, installation, schema user setup | Initial setup, understanding data model |
| [APEX_INSTRUCTIONS.md](../APEX_INSTRUCTIONS.md) | Complete APEX instructions (1146 lines) | New developers, step-by-step setup guide |
| [ORACLE_APEX_MIGRATION_SPEC.md](../ORACLE_APEX_MIGRATION_SPEC.md) | Full migration specification (2884 lines) | Architecture decisions, API integration |
| [APEX_FRONTEND_DESIGN.md](../APEX_FRONTEND_DESIGN.md) | UI/UX design specification (2914 lines) | Page design, CSS, status colors, wireframes |
| [APEX_SETUP_GUIDE.md](../APEX_SETUP_GUIDE.md) | APEX shell setup tasks 1.4.1-1.4.7 (953 lines) | Global Page, navigation, authentication |
| [APEX_SHELL_SETUP.md](../APEX_SHELL_SETUP.md) | Detailed shell setup guide (1307 lines) | Application creation, authorization schemes |
| [MIGRATION_ROADMAP.md](../MIGRATION_ROADMAP.md) | Task tracking, roadmap, priorities (524 lines) | Project planning, task status |
| [tests/README.md](../tests/README.md) | utPLSQL testing guide | Writing and running tests |

### Reference by Task Type

| Task | Primary Doc | Supporting Docs |
|------|-------------|-----------------|
| **Database Schema** | README.md | ORACLE_APEX_MIGRATION_SPEC.md §4 |
| **PL/SQL Packages** | ORACLE_APEX_MIGRATION_SPEC.md §5 | packages/*.sql |
| **APEX Pages** | APEX_FRONTEND_DESIGN.md §4 | APEX_SETUP_GUIDE.md, pages/*.sql |
| **Shared Components** | APEX_SHELL_SETUP.md | shared_components/**/*.sql |
| **Security/Auth** | APEX_SETUP_GUIDE.md §1.4.4-1.4.5 | ORACLE_APEX_MIGRATION_SPEC.md §8 |
| **USCIS API** | ORACLE_APEX_MIGRATION_SPEC.md §7 | packages/05_uscis_oauth_pkg.sql, packages/06_uscis_api_pkg.sql |
| **Testing** | tests/README.md | MIGRATION_ROADMAP.md Phase 5 |
| **Deployment** | APEX_INSTRUCTIONS.md §8 | deployment/*.sql |

---

## Oracle APEX 24.2 Local Documentation Reference

The `apex_24doc/` folder contains the complete Oracle APEX 24.2 documentation for offline reference. **This folder is gitignored and must exist locally only.**

### Documentation Structure

```
apex_24doc/content/
├── aeapi/    → PL/SQL API Reference (APEX_* packages)
├── aexjs/    → JavaScript API Reference (apex.* namespaces)
├── htmdb/    → App Builder User's Guide (building applications)
├── htmig/    → Installation & Upgrade Guide
├── htmrn/    → Release Notes (what's new in 24.2)
├── aeadm/    → Administration Guide
├── aeeug/    → End User's Guide
├── aeacc/    → Accessibility Guide
├── aelim/    → Oracle APEX Limits
├── aeutl/    → SQL Workshop & Utilities Guide
└── sp_common/→ Shared resources
```

### Quick Doc Lookup by Topic

| Topic | Local Path | Key Files |
|-------|-----------|-----------|
| **APEX_AI** (Generative AI) | `aeapi/APEX_AI.html` | GENERATE, CHAT, GET_VECTOR_EMBEDDINGS |
| **APEX_EXEC** (SQL/DML) | `aeapi/APEX_EXEC.html` | OPEN_QUERY_CONTEXT, EXECUTE_DML |
| **APEX_JSON** | `aeapi/APEX_JSON.html` | GET_CLOB, GET_VARCHAR2, WRITE |
| **APEX_COLLECTION** | `aeapi/APEX_COLLECTION.html` | CREATE_COLLECTION, ADD_MEMBER |
| **APEX_WEB_SERVICE** | `aeapi/APEX_WEB_SERVICE.html` | MAKE_REST_REQUEST, OAuth |
| **APEX_MAIL** | `aeapi/APEX_MAIL.html` | SEND (Email) |
| **APEX_WORKFLOW** | `aeapi/APEX_WORKFLOW.html` | START_WORKFLOW, GET_WORKFLOWS |
| **APEX_HUMAN_TASK** | `aeapi/APEX_HUMAN_TASK.html` | CREATE_TASK, APPROVE_TASK |
| **APEX_AUTOMATION** | `aeapi/APEX_AUTOMATION.html` | EXECUTE, ABORT, RESCHEDULE |
| **APEX_DEBUG** | `aeapi/APEX_DEBUG.html` | ENABLE, MESSAGE, INFO, ERROR |
| **APEX_DATA_PARSER** | `aeapi/APEX_DATA_PARSER.html` | PARSE (CSV/JSON/XML) |
| **JavaScript API** | `aexjs/` | apex.page, apex.region, apex.item |
| **Interactive Grids** | `htmdb/managing-interactive-grids.html` | IG configuration |
| **REST Data Sources** | `htmdb/managing-REST-data-sources.html` | External APIs |
| **Authentication** | `htmdb/establishing-user-identity-through-authentication.html` | Auth schemes |
| **Authorization** | `htmdb/providing-security-through-authorization.html` | Auth schemes |
| **Workflows** | `htmdb/managing-workflows-and-tasks.html` | APEX 24.2 workflows |
| **Page Designer** | `htmdb/using-page-designer.html` | UI development |
| **PWA** | `htmdb/creating-a-progressive-web-app.html` | Mobile apps |

### PL/SQL API Documentation Lookup

For any APEX PL/SQL API, find documentation at:
```
apex_24doc/content/aeapi/APEX_{PACKAGE_NAME}.html
```

**Examples:**
- `APEX_EXEC.OPEN_QUERY_CONTEXT` → `aeapi/APEX_EXEC.OPEN_QUERY_CONTEXT-Function-1.html`
- `APEX_JSON.GET_CLOB` → `aeapi/APEX_JSON.GET_CLOB-Function.html`
- `APEX_WEB_SERVICE.MAKE_REST_REQUEST` → `aeapi/MAKE_REST_REQUEST-Function.html`

### JavaScript API Documentation Lookup

For JavaScript APIs, see:
```
apex_24doc/content/aexjs/
```

Key JavaScript namespaces: `apex.page`, `apex.region`, `apex.item`, `apex.server`, `apex.message`

---

## APEX Application Structure

### Page Files (`pages/`)
| File | Purpose |
|------|---------|
| `page_00000.sql` | Global Page - CSS/JS on all pages |
| `page_00001.sql` | Home/Dashboard page |
| `page_00006.sql` | Import/Export page |
| `page_00022.sql` | Application page |
| `page_09999.sql` | Login page |
| `page_groups.sql` | Page group configurations |

### Shared Components (`shared_components/`)
```
shared_components/
├── files/                  # Static application files (JS, CSS)
│   ├── app_scripts_js.sql
│   └── app_scripts_min_js.sql
├── globalization/          # Translation and language settings
├── logic/                  # Application settings, build options
├── navigation/             # Menus, breadcrumbs, lists, tabs
├── security/               # Authentication and authorization schemes
└── user_interface/         # Themes, templates, template options
```

### Project PL/SQL Packages (`packages/`)
| Package | File | Purpose |
|---------|------|---------|
| `USCIS_TYPES_PKG` | `01_uscis_types_pkg.sql` | Custom types and collections |
| `USCIS_UTIL_PKG` | `02_uscis_util_pkg.sql` | Utility functions (validation, masking) |
| `USCIS_AUDIT_PKG` | `03_uscis_audit_pkg.sql` | Audit logging |
| `USCIS_CASE_PKG` | `04_uscis_case_pkg.sql` | Core case CRUD operations |
| `USCIS_OAUTH_PKG` | `05_uscis_oauth_pkg.sql` | OAuth2 token management |
| `USCIS_API_PKG` | `06_uscis_api_pkg.sql` | USCIS API integration |
| `USCIS_SCHEDULER_PKG` | `07_uscis_scheduler_pkg.sql` | DBMS_SCHEDULER jobs |
| `USCIS_EXPORT_PKG` | `08_uscis_export_pkg.sql` | Import/export functionality |

### Deployment (`deployment/`)
| File | Purpose |
|------|---------|
| `buildoptions.sql` | Build option definitions |
| `checks.sql` | Pre-deployment validation |
| `definition.sql` | Application definition export |

---

## APEX PL/SQL API Packages

Common packages (see `apex_24doc/content/aeapi/` for full documentation):

| Package | Purpose | Key Doc |
|---------|---------|---------|
| `APEX_APPLICATION` | Application-level operations and global variables | `APEX_APPLICATION.html` |
| `APEX_UTIL` | Utility functions (users, sessions, caching) | `APEX_UTIL.html` |
| `APEX_COLLECTION` | Session-state collections | `APEX_COLLECTION.html` |
| `APEX_DEBUG` | Debug logging | `APEX_DEBUG.html` |
| `APEX_ERROR` | Error handling | `APEX_ERROR.html` |
| `APEX_JSON` | JSON generation and parsing | `APEX_JSON.html` |
| `APEX_MAIL` | Email functionality | `APEX_MAIL.html` |
| `APEX_PAGE` | Page-level operations | `APEX_PAGE.html` |
| `APEX_REGION` | Region operations | `APEX_REGION.html` |
| `APEX_SESSION` | Session management | `APEX_SESSION.html` |
| `APEX_STRING` | String utilities | `APEX_STRING.html` |
| `APEX_EXEC` | Execute queries and DML | `APEX_EXEC.html` |
| `APEX_DATA_PARSER` | Parse CSV, JSON, XML data | `APEX_DATA_PARSER.html` |
| `APEX_WEB_SERVICE` | REST and SOAP web service calls | `APEX_WEB_SERVICE.html` |
| `APEX_WORKFLOW` | Workflow engine (24.2) | `APEX_WORKFLOW.html` |
| `APEX_HUMAN_TASK` | Task/approval management (24.2) | `APEX_HUMAN_TASK.html` |
| `APEX_AI` | Generative AI integration (24.2) | `APEX_AI.html` |
| `APEX_PWA` | Progressive Web App features | `APEX_PWA.html` |
| `APEX_AUTOMATION` | Automation engine | `APEX_AUTOMATION.html` |
| `APEX_IG` | Interactive Grid programmatic control | `APEX_IG.html` |
| `APEX_IR` | Interactive Report programmatic control | `APEX_IR.html` |

---

## APEX JavaScript APIs

Client-side APIs (see `apex_24doc/content/aexjs/` for details):

```javascript
// Common namespaces
apex.page        // Page operations, submit, validate
apex.region      // Region interactions (refresh, focus)
apex.item        // Item get/set values, enable/disable
apex.server      // AJAX calls to server (process, plugin)
apex.message     // Display messages, alerts, confirmations
apex.navigation  // Page navigation, redirects
apex.actions     // Action framework for buttons/menus
apex.debug       // Client-side debugging
apex.util        // Utility functions (escaping, formatting)
apex.widget      // Widget APIs (IG, IR, etc.)
apex.jQuery      // jQuery reference
```

### JavaScript API Doc Files
| Namespace | Local Doc | Common Methods |
|-----------|-----------|----------------|
| `apex.page` | `aexjs/apex.page.html` | submit, validate, confirm |
| `apex.region` | `aexjs/apex.region.html` | refresh, focus, widget |
| `apex.item` | `aexjs/apex.item.html` | getValue, setValue, enable, disable |
| `apex.server` | `aexjs/apex.server.html` | process, plugin, chunk |
| `apex.message` | `aexjs/apex.message.html` | alert, confirm, showPageSuccess |

---

## Project-Specific Patterns

### USCIS Receipt Number Validation
```sql
-- Use USCIS_UTIL_PKG for receipt number operations
USCIS_UTIL_PKG.validate_receipt_number(p_receipt => 'IOE1234567890')
USCIS_UTIL_PKG.normalize_receipt_number(p_receipt => 'ioe-1234567890')
USCIS_UTIL_PKG.mask_receipt_number(p_receipt => 'IOE1234567890') -- Returns IOE****567890
```

### Case Management Operations
```sql
-- Core case operations via USCIS_CASE_PKG
USCIS_CASE_PKG.add_case(p_receipt_number, p_notes, p_fetch_from_api)
USCIS_CASE_PKG.get_case(p_receipt_number)
USCIS_CASE_PKG.list_cases(p_user, p_status_filter, p_page, p_page_size)
USCIS_CASE_PKG.delete_case(p_receipt_number)
```

### USCIS API Integration
```sql
-- OAuth token management
USCIS_OAUTH_PKG.get_valid_token  -- Returns cached or fresh token

-- API calls
USCIS_API_PKG.check_case_status(p_receipt_number) -- Live USCIS lookup
```

### Status Color CSS Classes
From [APEX_FRONTEND_DESIGN.md](../APEX_FRONTEND_DESIGN.md):
```css
.status-approved  { background: #2e8540; }  /* Green */
.status-denied    { background: #cd2026; }  /* Red */
.status-pending   { background: #fdb81e; }  /* Yellow */
.status-rfe       { background: #0071bc; }  /* Blue - Request for Evidence */
.status-received  { background: #4c2c92; }  /* Purple */
.status-unknown   { background: #5b616b; }  /* Gray */
```

---

## Page Designer Best Practices

1. **Regions**: Use appropriate region types (Static Content, Cards, Interactive Grid, etc.)
2. **Items**: Select correct item types (Text Field, Select List, Popup LOV, etc.)
3. **Dynamic Actions**: Prefer declarative over JavaScript when possible
4. **Processes**: Use PL/SQL processes for server-side logic
5. **Validations**: Add both client-side and server-side validations
6. **Computations**: Use for calculating values before/after submit

See local docs: `htmdb/using-page-designer.html`, `htmdb/about-page-designer.html`

## Template Directives

APEX uses template directives for dynamic content:
- `#COLUMN_NAME#` - Substitution strings
- `{if CONDITION/}...{endif/}` - Conditional rendering
- `{loop/}...{endloop/}` - Loop constructs

See local docs: `htmdb/using-template-directives.html`

## Security Guidelines

1. **Authentication**: Configure in Shared Components > Security > Authentication
2. **Authorization**: Use authorization schemes to control access
3. **Session State Protection**: Enable checksum protection for items
4. **Escaping**: Use `apex_escape` package for output escaping
5. **SQL Injection Prevention**: Use bind variables in SQL

See local docs:
- `htmdb/establishing-user-identity-through-authentication.html`
- `htmdb/providing-security-through-authorization.html`
- `htmdb/cross-site-scripting-protection.html`

## REST Data Sources

For external API integration:
1. Define Remote Server in Shared Components
2. Create Web Credentials for authentication
3. Configure REST Data Source with operations
4. Use in reports, forms, or PL/SQL via `APEX_EXEC`

See local docs:
- `htmdb/managing-REST-data-sources.html`
- `htmdb/creating-web-credentials.html`
- `aeapi/APEX_WEB_SERVICE.html`

## Generative AI (APEX 24.2)

New in APEX 24.2 - AI integration capabilities:
- Configure AI Services in Shared Components
- Use `APEX_AI` package for programmatic access
- Create AI-powered assistants and chat interfaces
- Generate content using `APEX_AI.GENERATE` function

See local docs:
- `htmdb/including-generative-ai-in-applications.html`
- `htmdb/managing-generative-ai-in-apex.html`
- `aeapi/APEX_AI.html`

## Workflows and Tasks (APEX 24.2)

Human-centric workflow capabilities:
- Design workflows in Workflow Designer
- Create task definitions for approvals
- Use `APEX_WORKFLOW` and `APEX_HUMAN_TASK` packages
- Monitor via Workflow Console

See local docs:
- `htmdb/managing-workflows-and-tasks.html`
- `htmdb/about-workflows.html`
- `htmdb/about-task-definitions.html`
- `aeapi/APEX_WORKFLOW.html`
- `aeapi/APEX_HUMAN_TASK.html`

## Debugging

1. Enable Debug Mode: `apex_debug.enable`
2. Log messages: `apex_debug.message`, `apex_debug.info`, `apex_debug.error`
3. View Debug output in Developer Toolbar
4. Use Session > Debug in App Builder

See local docs:
- `htmdb/debugging-an-application.html`
- `htmdb/utilizing-debug-mode.html`
- `aeapi/APEX_DEBUG.html`

---

## Database Schema (Summary)

From [README.md](../README.md) - full details in [ORACLE_APEX_MIGRATION_SPEC.md](../ORACLE_APEX_MIGRATION_SPEC.md) §4:

### Core Tables
| Table | Purpose |
|-------|---------|
| `CASE_HISTORY` | Master table for tracked cases (receipt_number PK) |
| `STATUS_UPDATES` | Historical status changes per case |
| `OAUTH_TOKENS` | Cached OAuth2 tokens for USCIS API |
| `API_RATE_LIMITER` | Rate limiting tracking |
| `CASE_AUDIT_LOG` | Audit trail for all operations |
| `SCHEDULER_CONFIG` | Configuration for DBMS_SCHEDULER jobs |

### Key Views
| View | Purpose |
|------|---------|
| `V_CASE_CURRENT_STATUS` | Cases with latest status (for reports) |
| `V_CASE_DASHBOARD` | Aggregated dashboard data |
| `V_RECENT_ACTIVITY` | Recent audit activity |

---

## File Naming Conventions

- Page files: `page_NNNNN.sql` (5-digit zero-padded)
- Package files: `NN_package_name.sql` (numbered for installation order)
- Static files: descriptive names with extensions
- SQL scripts: lowercase with underscores

## Common Substitution Strings

| String | Description |
|--------|-------------|
| `&APP_ID.` | Application ID |
| `&APP_PAGE_ID.` | Current page ID |
| `&APP_SESSION.` | Session ID |
| `&APP_USER.` | Current username |
| `&REQUEST.` | Request value |
| `&ITEM_NAME.` | Item value |
| `#WORKSPACE_FILES#` | Workspace files path |
| `#APP_FILES#` | Application files path |

---

## Quick Reference Links

When working with this codebase, consult:

### Local Documentation (Preferred)
```
apex_24doc/content/
├── aeapi/     # PL/SQL API Reference
├── aexjs/     # JavaScript API Reference  
├── htmdb/     # App Builder User's Guide
└── htmrn/     # Release Notes (24.2 features)
```

### Online Documentation
- APEX Docs Home: https://docs.oracle.com/en/database/oracle/apex/24.2/
- PL/SQL API: https://docs.oracle.com/en/database/oracle/apex/24.2/aeapi/
- JavaScript API: https://docs.oracle.com/en/database/oracle/apex/24.2/aexjs/
- App Builder Guide: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/

### Project-Specific Scripts
| Script | Purpose |
|--------|---------|
| `scripts/connect.sh` | Connect to database |
| `scripts/apex-import.sh` | Import APEX application |
| `scripts/apex-export.sh` | Export APEX application |
| `scripts/deploy.sh` | Run deployment |
| `install_all_v2.sql` | Master installation script |
| `Makefile` | Build automation |
