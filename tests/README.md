# USCIS Case Tracker - Unit Tests

This directory contains utPLSQL unit tests for the USCIS Case Tracker PL/SQL packages.

## Prerequisites

1. **utPLSQL Framework** - Install from https://github.com/utPLSQL/utPLSQL
2. **Oracle Database** - 19c or higher (or Autonomous Database)
3. **USCIS_APP Schema** - All packages must be installed

## Test Files

| File | Package Under Test | Tests |
|------|-------------------|-------|
| `ut_uscis_case_pkg.sql` | USCIS_CASE_PKG | 40+ tests for case management |
| `ut_uscis_util_pkg.sql` | USCIS_UTIL_PKG | Utility function tests (TBD) |
| `ut_uscis_api_pkg.sql` | USCIS_API_PKG | API integration tests (TBD) |
| `ut_uscis_oauth_pkg.sql` | USCIS_OAUTH_PKG | OAuth token tests (TBD) |

## Installation

```sql
-- Install test packages
@tests/ut_uscis_case_pkg.sql
```

## Running Tests

### Run All Tests in a Package
```sql
exec ut.run('ut_uscis_case_pkg');
```

### Run Specific Test
```sql
exec ut.run('ut_uscis_case_pkg.test_add_case_valid');
```

### Run All USCIS Tests
```sql
exec ut.run('ut_uscis%');
```

### Run Tests with HTML Report
```sql
SELECT * FROM TABLE(ut.run('ut_uscis_case_pkg', ut_html_reporter()));
```

### Run with Code Coverage
```sql
exec ut.run(
    a_path => 'ut_uscis_case_pkg',
    a_reporter => ut_coverage_html_reporter()
);
```

## Test Conventions

### Test Data
- All test data uses receipt numbers starting with `TST` prefix
- Example: `TST0000000001`, `TST0000000002`
- Test data is cleaned up in `setup_test` and `teardown_test` procedures

### Test Naming
- `test_<function>_<scenario>` - e.g., `test_add_case_valid`
- `test_<function>_<error_condition>` - e.g., `test_add_case_invalid_receipt`

### Annotations Used
- `%suite` - Test suite name
- `%suitepath` - Hierarchical path for grouping
- `%test` - Individual test description
- `%throws` - Expected exception code
- `%beforeall` / `%afterall` - Suite setup/teardown
- `%beforeeach` / `%aftereach` - Test setup/teardown
- `%rollback(manual)` - Manual transaction control

## Coverage Goals

| Package | Target Coverage |
|---------|----------------|
| USCIS_CASE_PKG | 90%+ |
| USCIS_UTIL_PKG | 95%+ |
| USCIS_API_PKG | 85%+ |
| USCIS_OAUTH_PKG | 80%+ |

## Continuous Integration

Tests can be integrated with CI/CD pipelines:

```bash
# Using SQLcl with secure credential handling
# Option 1: Use environment variable (recommended for CI/CD)
# Ensure DB_PASSWORD is set via CI secrets manager (e.g., GitHub Secrets, Jenkins credentials)
export DB_PASSWORD="your_secure_password"  # Set via CI/CD secret, not in code
sql -s uscis_app/"${DB_PASSWORD}"@dbhost:1521/dbname <<EOF
set serveroutput on
exec ut.run('ut_uscis%');
EOF

# Option 2: Use Oracle Wallet for password-less authentication
# Configure wallet with: mkstore -wrl /path/to/wallet -createCredential dbhost:1521/dbname uscis_app
# sql -s /@dbhost:1521/dbname <<EOF
# set serveroutput on
# exec ut.run('ut_uscis%');
# EOF

# NOTE: Never hardcode passwords in scripts or version control.
# Use CI secret management or Oracle Wallet for secure authentication.
```

## Troubleshooting

### Tests fail with "insufficient privileges"
Grant required privileges to test user:
```sql
GRANT SELECT ON v_case_current_status TO uscis_app;
GRANT EXECUTE ON uscis_types_pkg TO uscis_app;
```

### "Package ut does not exist"
Install utPLSQL framework first:
```sql
@utPLSQL/source/install_headless.sql
```

### Cleanup test data manually
```sql
DELETE FROM status_updates WHERE receipt_number LIKE 'TST%';
DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
COMMIT;
```
