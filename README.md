# USCIS Case Tracker - Database Scripts

This directory contains the SQL/PL/SQL scripts for setting up the USCIS Case Tracker database schema.

## Prerequisites

- Oracle Database 19c or higher (or Oracle Autonomous Database)
- SQL*Plus, SQL Developer, or VS Code with Oracle extension
- DBA privileges for initial user creation and grants

## Files

| File | Description | Run As |
|------|-------------|--------|
| `00_install.sql` | Master installation script (runs all others) | USCIS_APP |
| `01_grants.sql` | User creation and privilege grants | SYS/DBA |
| `02_tables.sql` | Core application tables | USCIS_APP |
| `03_views.sql` | Application views | USCIS_APP |
| `04_seed_data.sql` | Default configuration data | USCIS_APP |

## Installation Steps

### 1. Create Schema User (DBA Required)

Connect as SYS or a DBA user and run the user creation portion of `01_grants.sql`:

```sql
-- Connect as DBA
sqlplus sys@your_database as sysdba

-- Create user (modify password!)
CREATE USER uscis_app IDENTIFIED BY "YourSecurePassword123!"
    DEFAULT TABLESPACE data
    QUOTA UNLIMITED ON data;

-- Run grants
@01_grants.sql
```

### 2. Install Database Objects

Connect as the USCIS_APP user and run the installation:

```sql
-- Connect as application user
sqlplus uscis_app@your_database

-- Run master installation script
@00_install.sql
```

Or run individual scripts in order:

```sql
@02_tables.sql
@03_views.sql
@04_seed_data.sql
```

### 3. Verify Installation

```sql
-- Check tables
SELECT table_name FROM user_tables ORDER BY table_name;

-- Check views
SELECT view_name FROM user_views ORDER BY view_name;

-- Check configuration
SELECT config_key, config_value FROM scheduler_config;
```

## Tables

### CASE_HISTORY
Master table for tracked USCIS cases. Each receipt number is stored as a single record.

| Column | Type | Description |
|--------|------|-------------|
| receipt_number | VARCHAR2(13) | Primary key (e.g., IOE1234567890) |
| created_at | TIMESTAMP | When case was added |
| created_by | VARCHAR2(255) | APEX username |
| notes | CLOB | User notes |
| is_active | NUMBER(1) | Active flag (0/1) |
| last_checked_at | TIMESTAMP | Last API check |
| check_frequency | NUMBER | Hours between checks |

### STATUS_UPDATES
Historical status changes for each case. Multiple rows per receipt_number.

| Column | Type | Description |
|--------|------|-------------|
| id | NUMBER | Auto-generated PK |
| receipt_number | VARCHAR2(13) | FK to case_history |
| case_type | VARCHAR2(100) | Form type (I-485, etc.) |
| current_status | VARCHAR2(500) | Status from USCIS |
| last_updated | TIMESTAMP | When status changed |
| details | CLOB | Extended description |
| source | VARCHAR2(20) | MANUAL, API, or IMPORT |

### OAUTH_TOKENS
OAuth2 access tokens for USCIS API.

### API_RATE_LIMITER
Rate limiting state for API calls.

### CASE_AUDIT_LOG
Audit trail for all case operations.

### SCHEDULER_CONFIG
Key-value configuration store.

## Views

| View | Description |
|------|-------------|
| V_CASE_CURRENT_STATUS | Cases with latest status |
| V_CASE_DASHBOARD | Statistics by status |
| V_RECENT_ACTIVITY | Last 100 audit entries |
| V_STATUS_HISTORY | Full history with analytics |
| V_CASES_DUE_FOR_CHECK | Cases needing API check |
| V_CASE_TYPE_SUMMARY | Statistics by form type |
| V_TOKEN_STATUS | OAuth token validity |
| V_RATE_LIMIT_STATUS | Rate limiter state |

## Network ACL Configuration

For USCIS API access, the ACL must be configured (requires DBA privileges):

```sql
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'api-int.uscis.gov',
        lower_port => 443,
        upper_port => 443,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'USCIS_APP',
            principal_type => xs_acl.ptype_db
        )
    );
END;
/
```

## Uninstall

To remove all objects:

```sql
-- Drop views first (they depend on tables)
DROP VIEW v_rate_limit_status;
DROP VIEW v_token_status;
DROP VIEW v_case_type_summary;
DROP VIEW v_cases_due_for_check;
DROP VIEW v_status_history;
DROP VIEW v_recent_activity;
DROP VIEW v_case_dashboard;
DROP VIEW v_case_current_status;

-- Drop tables (cascade constraints)
DROP TABLE scheduler_config CASCADE CONSTRAINTS;
DROP TABLE case_audit_log CASCADE CONSTRAINTS;
DROP TABLE api_rate_limiter CASCADE CONSTRAINTS;
DROP TABLE oauth_tokens CASCADE CONSTRAINTS;
DROP TABLE status_updates CASCADE CONSTRAINTS;
DROP TABLE case_history CASCADE CONSTRAINTS;
```

## Troubleshooting

### ORA-01950: no privileges on tablespace

The user doesn't have quota on the tablespace:
```sql
ALTER USER uscis_app QUOTA UNLIMITED ON data;
```

### ORA-24247: network access denied by access control list (ACL)

Network ACL not configured. Run the ACL setup from `01_grants.sql`.

### ORA-29273: HTTP request failed

SSL/TLS certificate issue. Ensure Oracle Wallet is configured with proper CA certificates.

## Next Steps

After database installation:

1. Create PL/SQL packages (in `/database/packages/`)
2. Set up APEX workspace
3. Configure APEX Web Credentials for OAuth2
4. Create APEX application
