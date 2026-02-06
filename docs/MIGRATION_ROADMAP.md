# USCIS Case Tracker: Oracle PL/SQL & APEX Migration Roadmap

**Project Start Date:** 2026-02-04  
**Target Completion:** 12 Weeks  
**Last Updated:** February 5, 2026  

---

## Executive Timeline

```text
Week 1-2    ████████░░░░░░░░░░░░░░░░  Phase 1: Foundation
Week 3-5    ████████████████░░░░░░░░  Phase 2: Core Functionality
Week 6-7    ████████████████████░░░░  Phase 3: API Integration
Week 8-9    ██████████████████████░░  Phase 4: Advanced Features
Week 10-11  ██████████████████████░░  Phase 5: Testing & Hardening
Week 12     ████████████████████████  Phase 6: Deployment
```

---

## Task Categories

- 🗄️ **Database** - Schema, tables, indexes
- 📦 **PL/SQL** - Packages, procedures, functions
- 🖥️ **APEX** - UI pages, regions, components
- 🔌 **Integration** - API, external services
- 🧪 **Testing** - Unit, integration, UAT
- 🚀 **DevOps** - Deployment, monitoring
- 📚 **Documentation** - Specs, guides

> **Dependency Notation:**
> - Comma-separated IDs: `1.2.1, 1.2.2, 1.2.3` (explicit list)
> - Range notation: `1.2.1-1.2.5` (tasks 1.2.1 through 1.2.5 inclusive)
> - "All [Category]" = all P0 and P1 tasks in that category for the current phase
> - "Phase N" = all tasks in the specified phase must complete first
> - "All" = all tasks in all preceding phases must complete first

---

## Phase 1: Foundation (Weeks 1-2)

### Week 1: Environment & Schema Setup

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 1.1.1 | Provision Oracle Autonomous Database (ATP) | 🚀 DevOps | P0 | 2 | None | ⬜ Not Started |
| 1.1.2 | Create database schema user (USCIS_APP) | 🗄️ Database | P0 | 1 | 1.1.1 | ⬜ Not Started |
| 1.1.3 | Configure network ACL for USCIS API access | 🗄️ Database | P0 | 2 | 1.1.2 | ⬜ Not Started |
| 1.1.4 | Set up Oracle Wallet for HTTPS | 🗄️ Database | P1 | 2 | 1.1.2 | ⬜ Not Started |
| 1.1.5 | Create APEX workspace | 🖥️ APEX | P0 | 1 | 1.1.2 | ⬜ Not Started |
| 1.1.6 | Configure APEX Web Credentials for OAuth2 | 🖥️ APEX | P1 | 2 | 1.1.5 | ⬜ Not Started |
| 1.1.7 | Set up development environment (SQL Developer, VS Code) | 🚀 DevOps | P1 | 2 | 1.1.1 | ⬜ Not Started |
| 1.1.8 | Create Git repository for database objects | 🚀 DevOps | P1 | 1 | None | ✅ Complete |

**Week 1 Subtotal:** 13 hours

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 1.2.1 | Create CASE_HISTORY table | 🗄️ Database | P0 | 1 | 1.1.2 | ✅ Complete |
| 1.2.2 | Create STATUS_UPDATES table | 🗄️ Database | P0 | 1 | 1.2.1 | ✅ Complete |
| 1.2.3 | Create OAUTH_TOKENS table | 🗄️ Database | P0 | 1 | 1.1.2 | ✅ Complete |
| 1.2.4 | Create API_RATE_LIMITER table | 🗄️ Database | P1 | 1 | 1.1.2 | ✅ Complete |
| 1.2.5 | Create CASE_AUDIT_LOG table | 🗄️ Database | P1 | 1 | 1.1.2 | ✅ Complete |
| 1.2.6 | Create SCHEDULER_CONFIG table | 🗄️ Database | P1 | 1 | 1.1.2 | ✅ Complete |
| 1.2.7 | Create V_CASE_CURRENT_STATUS view | 🗄️ Database | P0 | 1 | 1.2.1, 1.2.2 | ✅ Complete |
| 1.2.8 | Create V_CASE_DASHBOARD view | 🗄️ Database | P1 | 1 | 1.2.7 | ✅ Complete |
| 1.2.9 | Create V_RECENT_ACTIVITY view | 🗄️ Database | P2 | 1 | 1.2.5 | ✅ Complete |
| 1.2.10 | Create indexes for performance | 🗄️ Database | P1 | 2 | 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6 | ✅ Complete |
| 1.2.11 | Insert default configuration data | 🗄️ Database | P1 | 1 | 1.2.6 | ✅ Complete |
| 1.2.12 | Create database documentation | 📚 Documentation | P2 | 2 | 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6, 1.2.7, 1.2.8, 1.2.9, 1.2.10 | ⬜ Not Started |

**Week 2 Subtotal:** 14 hours

---

### Week 2: PL/SQL Package Stubs & APEX Shell

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 1.3.1 | Create USCIS_TYPES_PKG specification | 📦 PL/SQL | P0 | 2 | 1.2.1 | ✅ Complete |
| 1.3.2 | Create USCIS_UTIL_PKG specification | 📦 PL/SQL | P0 | 2 | 1.3.1 | ✅ Complete |
| 1.3.3 | Create USCIS_CASE_PKG specification | 📦 PL/SQL | P0 | 3 | 1.3.1 | ✅ Complete |
| 1.3.4 | Create USCIS_OAUTH_PKG specification | 📦 PL/SQL | P0 | 2 | 1.3.1 | ✅ Complete |
| 1.3.5 | Create USCIS_API_PKG specification | 📦 PL/SQL | P0 | 2 | 1.3.1 | ✅ Complete |
| 1.3.6 | Create USCIS_SCHEDULER_PKG specification | 📦 PL/SQL | P1 | 2 | 1.3.1 | ✅ Complete |
| 1.3.7 | Create USCIS_EXPORT_PKG specification | 📦 PL/SQL | P1 | 2 | 1.3.1 | ✅ Complete |
| 1.3.8 | Create USCIS_AUDIT_PKG specification | 📦 PL/SQL | P1 | 2 | 1.3.1 | ✅ Complete |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 1.4.1 | Create APEX application (App ID, Theme) | 🖥️ APEX | P0 | 2 | 1.1.5 | ✅ Complete |
| 1.4.2 | Configure Global Page (Page 0) | 🖥️ APEX | P0 | 3 | 1.4.1 | ⬜ Not Started |
| 1.4.3 | Create navigation menu structure | 🖥️ APEX | P0 | 2 | 1.4.1 | ✅ Complete |
| 1.4.4 | Set up authentication scheme | 🖥️ APEX | P0 | 2 | 1.4.1 | ✅ Complete |
| 1.4.5 | Create authorization schemes (roles) | 🖥️ APEX | P1 | 2 | 1.4.4 | ✅ Complete |
| 1.4.6 | Configure application settings | 🖥️ APEX | P1 | 1 | 1.4.1 | ⬜ Not Started |
| 1.4.7 | Create placeholder pages (1-8, 101) | 🖥️ APEX | P1 | 3 | 1.4.1 | ⬜ Not Started |

**Phase 1 Total:** ~60 hours

---

## Phase 2: Core Functionality (Weeks 3-5)

### Week 3: USCIS_UTIL_PKG & USCIS_CASE_PKG Implementation

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.1.1 | Implement validate_receipt_number | 📦 PL/SQL | P0 | 1 | 1.3.2 | ✅ Complete |
| 2.1.2 | Implement normalize_receipt_number | 📦 PL/SQL | P0 | 1 | 1.3.2 | ✅ Complete |
| 2.1.3 | Implement mask_receipt_number | 📦 PL/SQL | P0 | 1 | 1.3.2 | ✅ Complete |
| 2.1.4 | Implement get_config/set_config | 📦 PL/SQL | P0 | 2 | 1.3.2, 1.2.6 | ✅ Complete |
| 2.1.5 | Implement parse_iso_timestamp | 📦 PL/SQL | P0 | 1 | 1.3.2 | ✅ Complete |
| 2.1.6 | Implement get_current_user | 📦 PL/SQL | P0 | 1 | 1.3.2 | ✅ Complete |
| 2.1.7 | Implement get_client_ip | 📦 PL/SQL | P1 | 1 | 1.3.2 | ✅ Complete |
| 2.1.8 | Write unit tests for USCIS_UTIL_PKG | 🧪 Testing | P0 | 3 | 2.1.1, 2.1.2, 2.1.3, 2.1.4, 2.1.5, 2.1.6, 2.1.7 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.2.1 | Implement add_case function | 📦 PL/SQL | P0 | 4 | 1.3.3, 2.1.1, 2.1.2, 2.1.3 | ✅ Complete |
| 2.2.2 | Implement add_or_update_case procedure | 📦 PL/SQL | P0 | 3 | 1.3.3, 2.2.1 | ✅ Complete |
| 2.2.3 | Implement get_case function | 📦 PL/SQL | P0 | 3 | 1.3.3, 1.2.7 | ✅ Complete |
| 2.2.4 | Implement list_cases function | 📦 PL/SQL | P0 | 4 | 1.3.3, 1.2.7 | ✅ Complete |
| 2.2.5 | Implement count_cases function | 📦 PL/SQL | P0 | 2 | 1.3.3 | ✅ Complete |
| 2.2.6 | Implement delete_case procedure | 📦 PL/SQL | P0 | 2 | 1.3.3 | ✅ Complete |
| 2.2.7 | Implement case_exists function | 📦 PL/SQL | P0 | 1 | 1.3.3 | ✅ Complete |
| 2.2.8 | Implement get_cases_by_receipts function | 📦 PL/SQL | P1 | 2 | 1.3.3 | ✅ Complete |
| 2.2.9 | Implement update_case_notes procedure | 📦 PL/SQL | P1 | 1 | 1.3.3 | ✅ Complete |
| 2.2.10 | Implement set_case_active procedure | 📦 PL/SQL | P1 | 1 | 1.3.3 | ✅ Complete |
| 2.2.11 | Write unit tests for USCIS_CASE_PKG | 🧪 Testing | P0 | 6 | 2.2.1, 2.2.2, 2.2.3, 2.2.4, 2.2.5, 2.2.6, 2.2.7, 2.2.8, 2.2.9, 2.2.10 | ✅ Complete |

**Week 3 Subtotal:** 40 hours

---

### Week 4: APEX Core Pages (List, Details, Add)

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.3.1 | Build Case List page (Page 22) - Interactive Grid | 🖥️ APEX | P0 | 6 | 1.2.7, 2.2.4 | ✅ Complete |
| 2.3.2 | Configure IG columns and formatting | 🖥️ APEX | P0 | 2 | 2.3.1 | ✅ Complete |
| 2.3.3 | Add IG inline editing | 🖥️ APEX | P1 | 2 | 2.3.1 | ✅ Complete |
| 2.3.4 | Add IG download options (CSV, Excel) | 🖥️ APEX | P1 | 1 | 2.3.1 | ✅ Complete |
| 2.3.5 | Add IG row actions menu | 🖥️ APEX | P1 | 2 | 2.3.1 | ✅ Complete |
| 2.3.6 | Configure IG search and filtering | 🖥️ APEX | P0 | 2 | 2.3.1 | ✅ Complete |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.4.1 | Build Case Details page (Page 3) - Header | 🖥️ APEX | P0 | 3 | 2.2.3 | ✅ Complete |
| 2.4.2 | Build status timeline region | 🖥️ APEX | P0 | 4 | 2.2.3 | ✅ Complete |
| 2.4.3 | Build notes editor region | 🖥️ APEX | P1 | 2 | 2.2.9 | ✅ Complete |
| 2.4.4 | Add Refresh Status button | 🖥️ APEX | P1 | 2 | 2.4.1 | ✅ Complete |
| 2.4.5 | Add Delete Case button with confirmation | 🖥️ APEX | P0 | 2 | 2.2.6 | ✅ Complete |
| 2.4.6 | Add Active/Inactive toggle | 🖥️ APEX | P1 | 1 | 2.2.10 | ✅ Complete |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.5.1 | Build Add Case modal (Page 4) | 🖥️ APEX | P0 | 4 | 2.2.1 | ✅ Complete |
| 2.5.2 | Add receipt number validation | 🖥️ APEX | P0 | 2 | 2.1.1, 2.5.1 | ✅ Complete |
| 2.5.3 | Add fetch from USCIS toggle logic | 🖥️ APEX | P1 | 3 | 2.5.1 | ✅ Complete |
| 2.5.4 | Add case type dropdown (conditional) | 🖥️ APEX | P1 | 1 | 2.5.1 | ✅ Complete |
| 2.5.5 | Configure modal close and redirect | 🖥️ APEX | P0 | 1 | 2.5.1 | ✅ Complete |

**Week 4 Subtotal:** 40 hours

---

### Week 5: USCIS_AUDIT_PKG & Testing

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.6.1 | Implement log_event procedure | 📦 PL/SQL | P0 | 3 | 1.3.8, 1.2.5 | ✅ Complete |
| 2.6.2 | Implement get_case_audit function | 📦 PL/SQL | P1 | 2 | 1.3.8 | ✅ Complete |
| 2.6.3 | Implement get_recent_activity function | 📦 PL/SQL | P1 | 2 | 1.3.8 | ✅ Complete |
| 2.6.4 | Implement purge_old_records procedure | 📦 PL/SQL | P2 | 2 | 1.3.8 | ✅ Complete |
| 2.6.5 | Add audit triggers on CASE_HISTORY | 🗄️ Database | P1 | 3 | 2.6.1 | ✅ Complete |
| 2.6.6 | Add audit triggers on STATUS_UPDATES | 🗄️ Database | P1 | 2 | 2.6.1 | ✅ Complete |
| 2.6.7 | Write unit tests for USCIS_AUDIT_PKG | 🧪 Testing | P1 | 3 | 2.6.1, 2.6.2, 2.6.3, 2.6.4 | 🔄 In Progress |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 2.7.1 | Add Audit Trail tab to Case Details | 🖥️ APEX | P1 | 3 | 2.6.2, 2.4.1 | ⬜ Not Started |
| 2.7.2 | Local integration testing (mock data) | 🧪 Testing | P0 | 6 | 2.3.1, 2.3.2, 2.3.6, 2.4.1, 2.4.2, 2.4.5, 2.5.1, 2.5.2, 2.5.5 | ⬜ Not Started |
| 2.7.3 | Fix bugs from integration testing | 🖥️ APEX | P0 | 4 | 2.7.2 | ⬜ Not Started |
| 2.7.4 | Create test data scripts | 🧪 Testing | P1 | 2 | 2.2.1 | ⬜ Not Started |
| 2.7.5 | Document APEX pages and components | 📚 Documentation | P2 | 3 | 2.3.1, 2.3.2, 2.3.6, 2.4.1, 2.4.2, 2.4.5, 2.5.1, 2.5.2, 2.5.5 | ⬜ Not Started |
| 2.7.6 | Code review Phase 2 deliverables | 🧪 Testing | P0 | 4 | 2.2.11, 2.3.6, 2.5.5, 2.6.7, 2.7.2 | ⬜ Not Started |

**Week 5 Subtotal:** 39 hours  
**Phase 2 Total:** ~119 hours

---

## Phase 3: API Integration (Weeks 6-7)

### Week 6: OAuth2 & USCIS API Integration

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 3.1.1 | Implement fetch_new_token function | 📦 PL/SQL | P0 | 4 | 1.3.4, 1.1.3 | ✅ Complete |
| 3.1.2 | Implement get_access_token function | 📦 PL/SQL | P0 | 3 | 3.1.1, 1.2.3 | ✅ Complete |
| 3.1.3 | Implement is_token_valid function | 📦 PL/SQL | P0 | 2 | 1.3.4 | ✅ Complete |
| 3.1.4 | Implement clear_token procedure | 📦 PL/SQL | P1 | 1 | 1.3.4 | ✅ Complete |
| 3.1.5 | Implement has_credentials function | 📦 PL/SQL | P0 | 1 | 1.3.4 | ✅ Complete |
| 3.1.6 | Write unit tests for USCIS_OAUTH_PKG | 🧪 Testing | P0 | 4 | 3.1.1-3.1.5 | 🔄 In Progress |
| 3.1.7 | Test OAuth2 flow with sandbox credentials | 🔌 Integration | P0 | 3 | 3.1.1-3.1.2 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 3.2.1 | Implement apply_rate_limit procedure | 📦 PL/SQL | P0 | 3 | 1.3.5, 1.2.4 | ✅ Complete |
| 3.2.2 | Implement call_uscis_api internal function | 📦 PL/SQL | P0 | 4 | 3.1.2 | ✅ Complete |
| 3.2.3 | Implement parse_api_response function | 📦 PL/SQL | P0 | 4 | 1.3.5 | ✅ Complete |
| 3.2.4 | Implement check_case_status function | 📦 PL/SQL | P0 | 5 | 3.2.1-3.2.3 | ✅ Complete |
| 3.2.5 | Implement get_mock_response function | 📦 PL/SQL | P0 | 2 | 1.3.5 | ✅ Complete |
| 3.2.6 | Implement check_multiple_cases procedure | 📦 PL/SQL | P1 | 3 | 3.2.4 | ✅ Complete |
| 3.2.7 | Write unit tests for USCIS_API_PKG | 🧪 Testing | P0 | 4 | 3.2.1-3.2.6 | 🔄 In Progress |

**Week 6 Subtotal:** 43 hours

---

### Week 7: Check Status Page & Error Handling

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 3.3.1 | Build Check Status modal (Page 5) | 🖥️ APEX | P0 | 4 | 3.2.4 | ⬜ Not Started |
| 3.3.2 | Add receipt number input with validation | 🖥️ APEX | P0 | 2 | 2.1.1 | ⬜ Not Started |
| 3.3.3 | Add save to database toggle | 🖥️ APEX | P0 | 1 | 3.3.1 | ⬜ Not Started |
| 3.3.4 | Display API result in modal | 🖥️ APEX | P0 | 3 | 3.3.1 | ⬜ Not Started |
| 3.3.5 | Handle API errors gracefully | 🖥️ APEX | P0 | 3 | 3.3.1 | ⬜ Not Started |
| 3.3.6 | Add loading spinner during API call | 🖥️ APEX | P1 | 1 | 3.3.1 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 3.4.1 | Wire Refresh Status button on Page 3 | 🖥️ APEX | P0 | 2 | 2.4.4, 3.2.4 | ✅ Complete |
| 3.4.2 | Add fetch from USCIS on Page 4 | 🖥️ APEX | P0 | 3 | 2.5.3, 3.2.4 | ⬜ Not Started |
| 3.4.3 | Add bulk refresh action on Page 2 | 🖥️ APEX | P1 | 4 | 3.2.6 | ⬜ Not Started |
| 3.4.4 | Create global error handler | 📦 PL/SQL | P0 | 3 | None | ⬜ Not Started |
| 3.4.5 | Add APEX error page template | 🖥️ APEX | P1 | 2 | 3.4.4 | ⬜ Not Started |
| 3.4.6 | Integration testing with USCIS sandbox | 🔌 Integration | P0 | 6 | 3.3.1-3.4.3 | ⬜ Not Started |
| 3.4.7 | Document API integration | 📚 Documentation | P2 | 3 | 3.1.1-3.2.7 | ⬜ Not Started |

**Week 7 Subtotal:** 37 hours  
**Phase 3 Total:** ~80 hours

---

## Phase 4: Advanced Features (Weeks 8-9)

### Week 8: Import/Export & Dashboard

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 4.1.1 | Implement export_cases_json function | 📦 PL/SQL | P0 | 4 | 1.3.7, 2.2.4 | ✅ Complete |
| 4.1.2 | Implement export_cases_csv function | 📦 PL/SQL | P1 | 3 | 1.3.7 | ✅ Complete |
| 4.1.3 | Implement import_cases_json function | 📦 PL/SQL | P0 | 5 | 1.3.7, 2.2.2 | ✅ Complete |
| 4.1.4 | Implement download_export procedure | 📦 PL/SQL | P0 | 2 | 4.1.1, 4.1.2 | ✅ Complete |
| 4.1.5 | Write unit tests for USCIS_EXPORT_PKG | 🧪 Testing | P0 | 3 | 4.1.1-4.1.4 | 🔄 In Progress |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 4.2.1 | Build Import/Export page (Page 6) | 🖥️ APEX | P0 | 4 | 4.1.4 | ✅ Complete |
| 4.2.2 | Add export section with format selection | 🖥️ APEX | P0 | 2 | 4.2.1 | ✅ Complete |
| 4.2.3 | Add file upload component for import | 🖥️ APEX | P0 | 3 | 4.2.1 | ✅ Complete |
| 4.2.4 | Add import progress indicator | 🖥️ APEX | P1 | 2 | 4.2.3 | ⬜ Not Started |
| 4.2.5 | Add replace existing toggle | 🖥️ APEX | P1 | 1 | 4.2.3 | ✅ Complete |
| 4.2.6 | Handle large file imports | 📦 PL/SQL | P1 | 3 | 4.1.3 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 4.3.1 | Build Dashboard page (Page 1) | 🖥️ APEX | P0 | 4 | 1.2.8 | ✅ Complete |
| 4.3.2 | Add summary cards region | 🖥️ APEX | P0 | 3 | 4.3.1 | ✅ Complete |
| 4.3.3 | Add status distribution chart | 🖥️ APEX | P0 | 3 | 4.3.1 | ✅ Complete |
| 4.3.4 | Add recent activity timeline | 🖥️ APEX | P1 | 3 | 4.3.1, 2.6.3 | ✅ Complete |
| 4.3.5 | Add quick action buttons | 🖥️ APEX | P0 | 2 | 4.3.1 | ✅ Complete |
| 4.3.6 | Make dashboard responsive | 🖥️ APEX | P1 | 2 | 4.3.1-4.3.5 | ⬜ Not Started |

**Week 8 Subtotal:** 49 hours

---

### Week 9: Scheduler Jobs & Administration

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 4.4.1 | Implement create_auto_check_job procedure | 📦 PL/SQL | P0 | 3 | 1.3.6 | ✅ Complete |
| 4.4.2 | Implement run_auto_check procedure | 📦 PL/SQL | P0 | 4 | 3.2.6 | ✅ Complete |
| 4.4.3 | Implement create_token_refresh_job | 📦 PL/SQL | P1 | 2 | 1.3.6 | ✅ Complete |
| 4.4.4 | Implement create_cleanup_job | 📦 PL/SQL | P2 | 2 | 1.3.6, 2.6.4 | ✅ Complete |
| 4.4.5 | Implement set_auto_check_enabled | 📦 PL/SQL | P0 | 2 | 1.3.6 | ✅ Complete |
| 4.4.6 | Implement get_job_status function | 📦 PL/SQL | P1 | 2 | 1.3.6 | ✅ Complete |
| 4.4.7 | Implement drop_all_jobs procedure | 📦 PL/SQL | P1 | 1 | 1.3.6 | ✅ Complete |
| 4.4.8 | Write unit tests for USCIS_SCHEDULER_PKG | 🧪 Testing | P1 | 3 | 4.4.1, 4.4.2, 4.4.3, 4.4.4, 4.4.5, 4.4.6, 4.4.7 | 🔄 In Progress |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 4.5.1 | Build Settings page (Page 7) | 🖥️ APEX | P0 | 4 | 2.1.4 | ⬜ Not Started |
| 4.5.2 | Add API configuration section | 🖥️ APEX | P0 | 2 | 4.5.1 | ⬜ Not Started |
| 4.5.3 | Add scheduler settings section | 🖥️ APEX | P0 | 3 | 4.5.1, 4.4.5 | ⬜ Not Started |
| 4.5.4 | Build Administration page (Page 8) | 🖥️ APEX | P1 | 4 | None | ⬜ Not Started |
| 4.5.5 | Add audit logs viewer | 🖥️ APEX | P1 | 3 | 4.5.4, 2.6.3 | ⬜ Not Started |
| 4.5.6 | Add job scheduler status panel | 🖥️ APEX | P1 | 3 | 4.5.4, 4.4.6 | ⬜ Not Started |
| 4.5.7 | Add system health indicators | 🖥️ APEX | P2 | 2 | 4.5.4 | ⬜ Not Started |

**Week 9 Subtotal:** 40 hours  
**Phase 4 Total:** ~89 hours

---

## Phase 5: Testing & Hardening (Weeks 10-11)

> **Note:** Phase 5 is extended to 1.5-2 weeks to allow adequate time for comprehensive testing, bug fixes, and UAT feedback cycles.

> **⚠️ Unit-Test Policy:** Unit tests **must** be completed per-package immediately after each package implementation, before any dependent features proceed to Phase 5. Tasks 2.6.7 (USCIS_AUDIT_PKG), 3.1.6 (USCIS_OAUTH_PKG), 3.2.7 (USCIS_API_PKG), 4.1.5 (USCIS_EXPORT_PKG), and 4.4.8 (USCIS_SCHEDULER_PKG) are now in progress and must be completed within their respective phases. Deferring unit tests to Phase 5 creates compounding technical debt and risks late-stage rework.

### Week 10: Unit & Integration Testing

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 5.1.1 | Verify all per-package unit tests pass (no new authoring—tests completed in-phase) | 🧪 Testing | P0 | 2 | 2.2.11, 2.6.7, 3.1.6, 3.2.7, 4.1.5, 4.4.8 | ⬜ Not Started |
| 5.1.2 | Run full utPLSQL test suite | 🧪 Testing | P0 | 2 | 5.1.1 | ⬜ Not Started |
| 5.1.3 | Fix bugs from unit test failures | 📦 PL/SQL | P0 | 4 | 5.1.2 | ⬜ Not Started |
| 5.1.4 | Integration testing: APEX + PL/SQL | 🧪 Testing | P0 | 6 | 4.3.6, 4.5.7 | ⬜ Not Started |
| 5.1.5 | Integration testing: APEX + USCIS API | 🔌 Integration | P0 | 4 | 5.1.4 | ⬜ Not Started |
| 5.1.6 | Fix bugs from integration testing | 🖥️ APEX | P0 | 4 | 5.1.4, 5.1.5 | ⬜ Not Started |
| 5.1.7 | Retest after bug fixes | 🧪 Testing | P0 | 4 | 5.1.6 | ⬜ Not Started |

---

### Week 10-11: Performance & Security Testing

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 5.2.1 | Performance testing: page load times | 🧪 Testing | P0 | 3 | 5.1.4 | ⬜ Not Started |
| 5.2.2 | Performance testing: API response times | 🧪 Testing | P0 | 2 | 3.2.4 | ⬜ Not Started |
| 5.2.3 | Performance testing: large data sets | 🧪 Testing | P1 | 3 | 2.2.4, 4.1.3 | ⬜ Not Started |
| 5.2.4 | Add database indexes if needed | 🗄️ Database | P1 | 2 | 5.2.1, 5.2.2, 5.2.3 | ⬜ Not Started |
| 5.2.5 | Optimize slow queries | 📦 PL/SQL | P1 | 3 | 5.2.1, 5.2.2, 5.2.3 | ⬜ Not Started |
| 5.2.6 | Performance retest after optimization | 🧪 Testing | P1 | 2 | 5.2.4, 5.2.5 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 5.3.1 | Security review: SQL injection | 🧪 Testing | P0 | 2 | 5.1.1 | ⬜ Not Started |
| 5.3.2 | Security review: XSS vulnerabilities | 🧪 Testing | P0 | 2 | 5.1.4 | ⬜ Not Started |
| 5.3.3 | Security review: authorization bypass | 🧪 Testing | P0 | 2 | 1.4.5 | ⬜ Not Started |
| 5.3.4 | Security review: credential handling | 🧪 Testing | P0 | 2 | 3.1.1 | ⬜ Not Started |
| 5.3.5 | Fix security issues | 📦 PL/SQL | P0 | 4 | 5.3.1, 5.3.2, 5.3.3, 5.3.4 | ⬜ Not Started |
| 5.3.6 | Security retest after fixes | 🧪 Testing | P0 | 2 | 5.3.5 | ⬜ Not Started |

---

### Week 11: UAT & Final Hardening

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 5.4.1 | UAT with stakeholders (Session 1) | 🧪 Testing | P0 | 4 | 5.1.7, 5.3.6 | ⬜ Not Started |
| 5.4.2 | Address UAT Session 1 feedback | 🖥️ APEX | P0 | 4 | 5.4.1 | ⬜ Not Started |
| 5.4.3 | UAT with stakeholders (Session 2) | 🧪 Testing | P0 | 4 | 5.4.2 | ⬜ Not Started |
| 5.4.4 | Address UAT Session 2 feedback | 🖥️ APEX | P0 | 3 | 5.4.3 | ⬜ Not Started |
| 5.4.5 | Final regression testing | 🧪 Testing | P0 | 4 | 5.4.4 | ⬜ Not Started |
| 5.4.6 | Bug investigation & retesting buffer | 🧪 Testing | P1 | 6 | 5.4.5 | ⬜ Not Started |
| 5.4.7 | Test documentation & sign-off | 📚 Documentation | P0 | 2 | 5.4.5 | ⬜ Not Started |

**Phase 5 Total:** ~86 hours

---

## Phase 6: Deployment (Week 12)

### Week 12: Staging Deployment & Validation

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 6.0.1 | Deploy to Staging environment | 🚀 DevOps | P0 | 2 | Phase 5 | ⬜ Not Started |
| 6.0.2 | Smoke test in Staging | 🧪 Testing | P0 | 2 | 6.0.1 | ⬜ Not Started |
| 6.0.3 | Sign-off to Promote to Production | 📚 Documentation | P0 | 1 | 6.0.2 | ⬜ Not Started |

### Rollback Preparation

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 6.0.4 | Create DB rollback scripts | 🗄️ Database | P0 | 3 | 6.0.3 | ⬜ Not Started |
| 6.0.5 | APEX version rollback procedure | 🖥️ APEX | P0 | 2 | 6.0.3 | ⬜ Not Started |
| 6.0.6 | Data restoration procedures | 🗄️ Database | P0 | 2 | 6.0.3 | ⬜ Not Started |
| 6.0.7 | Deployment runbook with rollback triggers | 📚 Documentation | P0 | 3 | 6.0.3, 6.0.4, 6.0.5, 6.0.6 | ⬜ Not Started |

### Week 12: Production Deployment

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 6.1.1 | Provision production ATP instance | 🚀 DevOps | P0 | 2 | 6.0.3 | ⬜ Not Started |
| 6.1.2 | Configure production network ACLs | 🗄️ Database | P0 | 2 | 6.1.1 | ⬜ Not Started |
| 6.1.3 | Set up production APEX workspace | 🖥️ APEX | P0 | 2 | 6.1.1 | ⬜ Not Started |
| 6.1.4 | Configure production OAuth credentials | 🖥️ APEX | P0 | 2 | 6.1.3 | ⬜ Not Started |
| 6.1.5 | Deploy database schema | 🗄️ Database | P0 | 2 | 6.1.1 | ⬜ Not Started |
| 6.1.6 | Deploy PL/SQL packages | 📦 PL/SQL | P0 | 2 | 6.1.5 | ⬜ Not Started |
| 6.1.7 | Deploy APEX application | 🖥️ APEX | P0 | 2 | 6.1.6 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 6.2.1 | Configure custom domain (optional) | 🚀 DevOps | P2 | 2 | 6.1.7 | ⬜ Not Started |
| 6.2.2 | Configure SSL certificate | 🚀 DevOps | P0 | 1 | 6.1.7 | ⬜ Not Started |
| 6.2.3 | Set up database backup schedule | 🚀 DevOps | P0 | 1 | 6.1.1 | ⬜ Not Started |
| 6.2.4 | Configure monitoring/alerts with automated rollback triggers | 🚀 DevOps | P0 | 4 | 6.1.7, 6.0.7 | ⬜ Not Started |
| 6.2.5 | Smoke testing with automated rollback on failure | 🧪 Testing | P0 | 4 | 6.1.7, 6.0.4 | ⬜ Not Started |
| 6.2.6 | Create scheduler jobs in production | 📦 PL/SQL | P0 | 1 | 6.1.6 | ⬜ Not Started |

---

| ID | Task | Category | Priority | Est. Hours | Dependencies | Status |
|----|------|----------|----------|------------|--------------|--------|
| 6.3.1a | Data migration rehearsal in Staging | 🗄️ Database | P0 | 4 | 6.0.1 | ⬜ Not Started |
| 6.3.1b | Production data migration | 🗄️ Database | P0 | 4 | 6.1.5, 6.3.1a | ⬜ Not Started |
| 6.3.2 | Validate migrated data | 🧪 Testing | P0 | 2 | 6.3.1b | ⬜ Not Started |
| 6.3.3 | Create production user accounts | 🖥️ APEX | P0 | 1 | 6.1.3 | ⬜ Not Started |
| 6.3.4 | Final production verification | 🧪 Testing | P0 | 2 | All | ⬜ Not Started |
| 6.3.5 | Go-live announcement | 📚 Documentation | P0 | 1 | 6.3.4 | ⬜ Not Started |
| 6.3.6 | Create user documentation | 📚 Documentation | P0 | 4 | All | ⬜ Not Started |
| 6.3.7 | Create admin operations guide | 📚 Documentation | P0 | 3 | All | ⬜ Not Started |
| 6.3.8 | Project handoff & knowledge transfer | 📚 Documentation | P0 | 4 | All | ⬜ Not Started |

**Phase 6 Total:** ~46 hours

---

## Summary

### Total Estimated Hours by Phase

| Phase | Description | Hours | Weeks |
|-------|-------------|-------|-------|
| 1 | Foundation | 60 | 1-2 |
| 2 | Core Functionality | 119 | 3-5 |
| 3 | API Integration | 80 | 6-7 |
| 4 | Advanced Features | 89 | 8-9 |
| 5 | Testing & Hardening | 86 | 10-11 |
| 6 | Deployment | 46 | 12 |
| **Total** | | **480** | **12** |

### Hours by Category

| Category | Hours | Percentage |
|----------|-------|------------|
| 🗄️ Database | 48 | 10% |
| 📦 PL/SQL | 135 | 28% |
| 🖥️ APEX | 128 | 27% |
| 🔌 Integration | 13 | 3% |
| 🧪 Testing | 110 | 23% |
| 🚀 DevOps | 22 | 4% |
| 📚 Documentation | 24 | 5% |

### Critical Path

```text
1.1.1 → 1.1.2 → 1.2.1 → 1.3.1 → 1.3.2 → 2.1.1 → 2.2.1 → 2.2.4 → 2.3.1 → 3.1.1 → 3.2.4 → 3.3.1 → 4.3.1 → 4.3.6 → 4.5.7 → 5.1.4 → 6.0.1 → 6.0.3 → 6.1.1 → 6.1.7
```

> **Note:** Critical path updated to:
> - Fix 2.1.1 dependency from 1.3.3 to 1.3.2 (USCIS_UTIL_PKG)
> - Include Phase 4 tasks (4.3.1, 4.3.6, 4.5.7) before 5.1.4
> - Add staging deployment (6.0.1, 6.0.3) before production

### Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| USCIS API changes | Medium | High | Abstract API layer, version checking |
| Performance issues with large datasets | Medium | Medium | Early performance testing, indexing |
| OAuth2 token expiry issues | Low | High | Robust token refresh, error handling |
| APEX version compatibility | Low | Medium | Document supported versions |
| Data migration errors | Medium | High | Validation scripts, rollback plan |

---

## Task Status Legend

| Status | Description |
|--------|-------------|
| ⬜ Not Started | Task has not been started |
| 🔄 In Progress | Task is currently being worked on |
| ✅ Completed | Task has been completed and verified |
| ⏸️ Blocked | Task is blocked by dependency or issue |
| ❌ Cancelled | Task has been cancelled |

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-03 | 1.0 | Migration Team | Initial roadmap created |
| 2026-02-04 | 1.1 | Migration Team | Completed tasks 1.3.1-1.3.8: All PL/SQL package specifications created |
| 2026-02-04 | 1.2 | Migration Team | Completed tasks 2.1.1-2.1.7: USCIS_UTIL_PKG body implementation (validate_receipt_number, normalize_receipt_number, mask_receipt_number, get_config/set_config, parse_iso_timestamp, get_current_user, get_client_ip) |
| 2026-02-05 | 1.3 | Migration Team | Completed tasks 2.2.1-2.2.11: USCIS_CASE_PKG body implementation (add_case, add_or_update_case, get_case, list_cases, count_cases, delete_case, case_exists, get_cases_by_receipts, update_case_notes, set_case_active) and unit tests |
| 2026-02-05 | 1.4 | Migration Team | Enforced per-package unit-test policy: moved tasks 2.6.7, 3.1.6, 3.2.7, 4.1.5, 4.4.8 to 🔄 In Progress; updated Phase 5 task 5.1.1 to verification-only; added unit-test policy note requiring tests before Phase 5 |

---

*End of Roadmap*
