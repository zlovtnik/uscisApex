-- ============================================================
-- USCIS Case Tracker - Stress Test Seed Data
-- Generates ~500 cases with ~1500 status updates for
-- functional and stress testing.
-- ============================================================
-- File: scripts/seed_stress_test_data.sql
-- Run As: USCIS_APP
-- Prerequisites: install_all_v2.sql must have been run first
-- ============================================================
-- WARNING: This script inserts large volumes of test data.
--          Do NOT run in production environments.
-- ============================================================

SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

PROMPT ============================================================
PROMPT  USCIS Case Tracker - Stress Test Data Seed
PROMPT  Generating ~500 cases with multiple status updates...
PROMPT ============================================================

-- ============================================================
-- STEP 0: Disable audit triggers for bulk load performance
-- ============================================================
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_exists FROM user_triggers WHERE trigger_name = 'TRG_CASE_HISTORY_AUDIT';
    IF l_exists > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_case_history_audit DISABLE';
        DBMS_OUTPUT.PUT_LINE('Disabled trg_case_history_audit');
    END IF;

    SELECT COUNT(*) INTO l_exists FROM user_triggers WHERE trigger_name = 'TRG_STATUS_UPDATES_AUDIT';
    IF l_exists > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_status_updates_audit DISABLE';
        DBMS_OUTPUT.PUT_LINE('Disabled trg_status_updates_audit');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Warning disabling triggers: ' || SQLERRM);
END;
/

-- ============================================================
-- STEP 1: Generate test cases and status updates
-- ============================================================
DECLARE
    -- Receipt number prefixes (real USCIS service centers)
    TYPE t_prefix_tab IS TABLE OF VARCHAR2(3) INDEX BY PLS_INTEGER;
    l_prefixes t_prefix_tab;

    -- Form types with realistic weights
    TYPE t_form_rec IS RECORD (
        form_type    VARCHAR2(10),
        description  VARCHAR2(100)
    );
    TYPE t_form_tab IS TABLE OF t_form_rec INDEX BY PLS_INTEGER;
    l_forms t_form_tab;

    -- Statuses ordered by typical case lifecycle
    TYPE t_status_tab IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;

    -- Active status chains (ordered progression)
    l_received_statuses   t_status_tab;  -- early lifecycle
    l_mid_statuses        t_status_tab;  -- mid lifecycle
    l_terminal_statuses   t_status_tab;  -- final statuses

    -- Users for created_by
    TYPE t_user_tab IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
    l_users t_user_tab;

    -- Sources
    TYPE t_source_tab IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    l_sources t_source_tab;

    -- IP addresses for audit
    TYPE t_ip_tab IS TABLE OF VARCHAR2(45) INDEX BY PLS_INTEGER;
    l_ips t_ip_tab;

    -- Working variables
    l_receipt       VARCHAR2(13);
    l_prefix        VARCHAR2(3);
    l_form_idx      PLS_INTEGER;
    l_user_idx      PLS_INTEGER;
    l_num_statuses  PLS_INTEGER;
    l_days_ago      NUMBER;
    l_status_text   VARCHAR2(200);
    l_source        VARCHAR2(20);
    l_is_active     NUMBER(1);
    l_case_count    PLS_INTEGER := 0;
    l_status_count  PLS_INTEGER := 0;
    l_audit_count   PLS_INTEGER := 0;
    l_batch_size    CONSTANT PLS_INTEGER := 100;
    l_total_cases   CONSTANT PLS_INTEGER := 500;

    -- Pre-computed scalars (PL/SQL collection methods can't be used in SQL)
    l_form_type     VARCHAR2(10);
    l_form_desc     VARCHAR2(100);
    l_ip_address    VARCHAR2(45);
    l_ip_idx        PLS_INTEGER;
    l_num_ips       CONSTANT PLS_INTEGER := 5;

    -- Notes templates
    TYPE t_notes_tab IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
    l_notes t_notes_tab;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Initializing reference data...');

    -- Service center prefixes
    l_prefixes(1) := 'IOE';  -- Online filing
    l_prefixes(2) := 'LIN';  -- Nebraska
    l_prefixes(3) := 'WAC';  -- California
    l_prefixes(4) := 'EAC';  -- Vermont
    l_prefixes(5) := 'SRC';  -- Texas
    l_prefixes(6) := 'MSC';  -- Missouri

    -- Form types
    l_forms(1).form_type  := 'I-485';   l_forms(1).description  := 'Application to Register Permanent Residence or Adjust Status';
    l_forms(2).form_type  := 'I-765';   l_forms(2).description  := 'Application for Employment Authorization';
    l_forms(3).form_type  := 'I-140';   l_forms(3).description  := 'Immigrant Petition for Alien Workers';
    l_forms(4).form_type  := 'I-130';   l_forms(4).description  := 'Petition for Alien Relative';
    l_forms(5).form_type  := 'I-131';   l_forms(5).description  := 'Application for Travel Document';
    l_forms(6).form_type  := 'I-539';   l_forms(6).description  := 'Application to Extend/Change Nonimmigrant Status';
    l_forms(7).form_type  := 'I-129';   l_forms(7).description  := 'Petition for a Nonimmigrant Worker';
    l_forms(8).form_type  := 'I-751';   l_forms(8).description  := 'Petition to Remove Conditions on Residence';
    l_forms(9).form_type  := 'N-400';   l_forms(9).description  := 'Application for Naturalization';
    l_forms(10).form_type := 'I-821D';  l_forms(10).description := 'Consideration of Deferred Action for Childhood Arrivals';
    l_forms(11).form_type := 'I-20';    l_forms(11).description := 'Certificate of Eligibility';
    l_forms(12).form_type := 'I-90';    l_forms(12).description := 'Application to Replace Permanent Resident Card';

    -- Early lifecycle statuses
    l_received_statuses(1) := 'Case Was Received';
    l_received_statuses(2) := 'Case Was Received And A Receipt Notice Was Sent';
    l_received_statuses(3) := 'Case Was Updated To Show Fingerprints Were Taken';

    -- Mid lifecycle statuses
    l_mid_statuses(1) := 'Case Is Being Actively Reviewed By USCIS';
    l_mid_statuses(2) := 'Request for Initial Evidence Was Sent';
    l_mid_statuses(3) := 'Response To USCIS'' Request For Evidence Was Received';
    l_mid_statuses(4) := 'Interview Was Scheduled';
    l_mid_statuses(5) := 'Interview Was Completed And Case Must Be Reviewed';
    l_mid_statuses(6) := 'Case Was Transferred And A New Office Has Jurisdiction';
    l_mid_statuses(7) := 'Request for Additional Evidence Was Sent';
    l_mid_statuses(8) := 'Case Is Ready To Be Scheduled For An Interview';

    -- Terminal statuses
    l_terminal_statuses(1) := 'Case Was Approved';
    l_terminal_statuses(2) := 'New Card Is Being Produced';
    l_terminal_statuses(3) := 'Card Was Mailed To Me';
    l_terminal_statuses(4) := 'Card Was Picked Up By The United States Postal Service';
    l_terminal_statuses(5) := 'Card Was Delivered To Me By The Post Office';
    l_terminal_statuses(6) := 'Case Was Denied';
    l_terminal_statuses(7) := 'Case Was Rejected Because It Was Improperly Filed';
    l_terminal_statuses(8) := 'Withdrawal Acknowledged';

    -- Test users
    l_users(1) := 'ADMIN';
    l_users(2) := 'TEST_USER_01';
    l_users(3) := 'TEST_USER_02';
    l_users(4) := 'JOHN.DOE';
    l_users(5) := 'JANE.SMITH';
    l_users(6) := 'MIKE.JONES';
    l_users(7) := 'SARA.WILSON';
    l_users(8) := 'APEX_PUBLIC_USER';

    -- Sources with weights (API is most common in prod)
    l_sources(1) := 'MANUAL';
    l_sources(2) := 'API';
    l_sources(3) := 'IMPORT';

    -- IP addresses
    l_ips(1) := '127.0.0.1';
    l_ips(2) := '192.168.1.100';
    l_ips(3) := '10.0.0.50';
    l_ips(4) := '172.16.0.25';
    l_ips(5) := '203.0.113.42';

    -- Notes templates
    l_notes(1) := 'Tracking case filed on behalf of spouse';
    l_notes(2) := 'Employment authorization pending - need for work';
    l_notes(3) := 'Premium processing requested';
    l_notes(4) := 'Attorney handling - Law Office of Smith & Associates';
    l_notes(5) := 'Family-based petition, priority date watch';
    l_notes(6) := 'Concurrent filing with I-485';
    l_notes(7) := 'Need travel document before trip in 3 months';
    l_notes(8) := 'H-1B transfer to new employer';
    l_notes(9) := 'Renewal application - original card expiring soon';
    l_notes(10) := 'DACA renewal - must track timeline carefully';
    l_notes(11) := NULL;  -- some cases have no notes
    l_notes(12) := NULL;

    DBMS_OUTPUT.PUT_LINE('Generating ' || l_total_cases || ' test cases...');
    DBMS_OUTPUT.PUT_LINE('');

    -- ========================================================
    -- Main generation loop
    -- ========================================================
    FOR i IN 1..l_total_cases LOOP
        -- Pick a random prefix (weighted: IOE most common)
        DECLARE
            l_rand NUMBER := DBMS_RANDOM.VALUE(1, 100);
        BEGIN
            IF l_rand <= 40 THEN
                l_prefix := l_prefixes(1);  -- IOE 40%
            ELSIF l_rand <= 60 THEN
                l_prefix := l_prefixes(2);  -- LIN 20%
            ELSIF l_rand <= 75 THEN
                l_prefix := l_prefixes(3);  -- WAC 15%
            ELSIF l_rand <= 85 THEN
                l_prefix := l_prefixes(4);  -- EAC 10%
            ELSIF l_rand <= 95 THEN
                l_prefix := l_prefixes(5);  -- SRC 10%
            ELSE
                l_prefix := l_prefixes(6);  -- MSC 5%
            END IF;
        END;

        -- Build unique receipt number: PREFIX + 10-digit number
        -- Use 70xxxNNNNN pattern to avoid collision with existing seeds
        l_receipt := l_prefix || '70' || LPAD(TO_CHAR(i), 8, '0');

        -- Random form type (weighted: I-485, I-765, I-140 more common)
        DECLARE
            l_rand NUMBER := DBMS_RANDOM.VALUE(1, 100);
        BEGIN
            IF l_rand <= 20 THEN
                l_form_idx := 1;   -- I-485  20%
            ELSIF l_rand <= 40 THEN
                l_form_idx := 2;   -- I-765  20%
            ELSIF l_rand <= 55 THEN
                l_form_idx := 3;   -- I-140  15%
            ELSIF l_rand <= 65 THEN
                l_form_idx := 4;   -- I-130  10%
            ELSIF l_rand <= 72 THEN
                l_form_idx := 5;   -- I-131   7%
            ELSIF l_rand <= 79 THEN
                l_form_idx := 6;   -- I-539   7%
            ELSIF l_rand <= 85 THEN
                l_form_idx := 7;   -- I-129   6%
            ELSIF l_rand <= 90 THEN
                l_form_idx := 8;   -- I-751   5%
            ELSIF l_rand <= 95 THEN
                l_form_idx := 9;   -- N-400   5%
            ELSIF l_rand <= 98 THEN
                l_form_idx := 10;  -- I-821D  3%
            ELSIF l_rand <= 99 THEN
                l_form_idx := 11;  -- I-20    1%
            ELSE
                l_form_idx := 12;  -- I-90    1%
            END IF;
        END;

        -- Random user
        l_user_idx := TRUNC(DBMS_RANDOM.VALUE(1, l_users.COUNT + 1));

        -- Pre-compute form type/description (record fields can't be used in SQL)
        l_form_type := l_forms(l_form_idx).form_type;
        l_form_desc := l_forms(l_form_idx).description;

        -- Active / inactive (85% active, 15% inactive)
        IF DBMS_RANDOM.VALUE(1, 100) <= 85 THEN
            l_is_active := 1;
        ELSE
            l_is_active := 0;
        END IF;

        -- How many days ago the case was created (1-540 days)
        l_days_ago := TRUNC(DBMS_RANDOM.VALUE(1, 541));

        -- Random notes (may be NULL)
        DECLARE
            l_note_idx PLS_INTEGER := TRUNC(DBMS_RANDOM.VALUE(1, l_notes.COUNT + 1));
        BEGIN
            -- Insert case_history
            -- Only use columns guaranteed to exist; check_frequency &
            -- notifications_enabled have defaults and may not be present
            INSERT INTO case_history (
                receipt_number,
                created_at,
                created_by,
                notes,
                is_active
            ) VALUES (
                l_receipt,
                SYSTIMESTAMP - NUMTODSINTERVAL(l_days_ago, 'DAY'),
                l_users(l_user_idx),
                l_notes(l_note_idx),
                l_is_active
            );
        END;

        l_case_count := l_case_count + 1;

        -- ====================================================
        -- Generate 1-5 status updates per case (lifecycle)
        -- ====================================================
        l_num_statuses := TRUNC(DBMS_RANDOM.VALUE(1, 6));

        FOR s IN 1..l_num_statuses LOOP
            -- Determine status text based on position in lifecycle
            IF s = 1 THEN
                -- First status is always "received"
                l_status_text := l_received_statuses(
                    TRUNC(DBMS_RANDOM.VALUE(1, l_received_statuses.COUNT + 1))
                );
            ELSIF s < l_num_statuses THEN
                -- Mid-lifecycle
                l_status_text := l_mid_statuses(
                    TRUNC(DBMS_RANDOM.VALUE(1, l_mid_statuses.COUNT + 1))
                );
            ELSE
                -- Last status is terminal (for multi-status cases) or mid
                IF l_num_statuses >= 3 AND DBMS_RANDOM.VALUE(0, 1) > 0.3 THEN
                    l_status_text := l_terminal_statuses(
                        TRUNC(DBMS_RANDOM.VALUE(1, l_terminal_statuses.COUNT + 1))
                    );
                ELSE
                    l_status_text := l_mid_statuses(
                        TRUNC(DBMS_RANDOM.VALUE(1, l_mid_statuses.COUNT + 1))
                    );
                END IF;
            END IF;

            -- Source: first status usually MANUAL, later ones more likely API
            IF s = 1 THEN
                l_source := 'MANUAL';
            ELSE
                DECLARE
                    l_rand NUMBER := DBMS_RANDOM.VALUE(1, 100);
                BEGIN
                    IF l_rand <= 20 THEN
                        l_source := 'MANUAL';
                    ELSIF l_rand <= 90 THEN
                        l_source := 'API';
                    ELSE
                        l_source := 'IMPORT';
                    END IF;
                END;
            END IF;

            -- Each subsequent status is more recent
            DECLARE
                l_status_days NUMBER := GREATEST(
                    l_days_ago - (s * TRUNC(l_days_ago / (l_num_statuses + 1))),
                    0
                );
                l_status_ts TIMESTAMP := SYSTIMESTAMP - NUMTODSINTERVAL(l_status_days, 'DAY');
            BEGIN
                INSERT INTO status_updates (
                    receipt_number,
                    case_type,
                    current_status,
                    last_updated,
                    details,
                    source
                ) VALUES (
                    l_receipt,
                    l_form_type,
                    l_status_text,
                    l_status_ts,
                    'On ' || TO_CHAR(l_status_ts, 'Month DD, YYYY') ||
                        ', we updated your Form ' || l_form_type ||
                        ', ' || l_form_desc || '. ' ||
                        l_status_text || '.',
                    l_source
                );
            END;

            l_status_count := l_status_count + 1;
        END LOOP;

        -- ====================================================
        -- Insert audit log entry for case creation
        -- ====================================================
        -- Pre-compute IP (collection methods can't be used in SQL)
        l_ip_idx := TRUNC(DBMS_RANDOM.VALUE(1, l_num_ips + 1));
        l_ip_address := l_ips(l_ip_idx);

        INSERT INTO case_audit_log (
            receipt_number,
            action,
            new_values,
            performed_by,
            performed_at,
            ip_address
        ) VALUES (
            l_receipt,
            'INSERT',
            '{"receipt_number":"' || l_receipt ||
                '","case_type":"' || l_form_type ||
                '","is_active":' || l_is_active || '}',
            l_users(l_user_idx),
            SYSTIMESTAMP - NUMTODSINTERVAL(l_days_ago, 'DAY'),
            l_ip_address
        );
        l_audit_count := l_audit_count + 1;

        -- Add a CHECK audit entry for ~60% of cases
        IF DBMS_RANDOM.VALUE(0, 1) > 0.4 THEN
            INSERT INTO case_audit_log (
                receipt_number,
                action,
                new_values,
                performed_by,
                performed_at,
                ip_address
            ) VALUES (
                l_receipt,
                'CHECK',
                '{"receipt_number":"' || l_receipt ||
                    '","source":"API","status":"' ||
                    REPLACE(l_status_text, '''', '''''') || '"}',
                'SCHEDULER',
                SYSTIMESTAMP - NUMTODSINTERVAL(
                    TRUNC(DBMS_RANDOM.VALUE(0, l_days_ago)), 'DAY'
                ),
                '127.0.0.1'
            );
            l_audit_count := l_audit_count + 1;
        END IF;

        -- Commit in batches for performance
        IF MOD(i, l_batch_size) = 0 THEN
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('  ...generated ' || i || ' / ' || l_total_cases || ' cases');
        END IF;

    END LOOP;

    -- Final commit
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  Stress Test Data Generation Complete');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  Cases inserted:         ' || l_case_count);
    DBMS_OUTPUT.PUT_LINE('  Status updates inserted: ' || l_status_count);
    DBMS_OUTPUT.PUT_LINE('  Audit log entries:       ' || l_audit_count);
    DBMS_OUTPUT.PUT_LINE('============================================================');

END;
/

-- ============================================================
-- STEP 2: Re-enable audit triggers
-- ============================================================
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_exists FROM user_triggers WHERE trigger_name = 'TRG_CASE_HISTORY_AUDIT';
    IF l_exists > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_case_history_audit ENABLE';
        DBMS_OUTPUT.PUT_LINE('Re-enabled trg_case_history_audit');
    END IF;

    SELECT COUNT(*) INTO l_exists FROM user_triggers WHERE trigger_name = 'TRG_STATUS_UPDATES_AUDIT';
    IF l_exists > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_status_updates_audit ENABLE';
        DBMS_OUTPUT.PUT_LINE('Re-enabled trg_status_updates_audit');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR re-enabling triggers: ' || SQLERRM);
        RAISE;  -- Don't silently continue with disabled triggers
END;
/

-- ============================================================
-- STEP 3: Verification queries
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT  Verification: Record Counts
PROMPT ============================================================

SELECT 'CASE_HISTORY' AS table_name, COUNT(*) AS row_count FROM case_history
UNION ALL
SELECT 'STATUS_UPDATES', COUNT(*) FROM status_updates
UNION ALL
SELECT 'CASE_AUDIT_LOG', COUNT(*) FROM case_audit_log
ORDER BY 1;

PROMPT
PROMPT Cases by service center prefix:
SELECT SUBSTR(receipt_number, 1, 3) AS prefix,
       COUNT(*) AS case_count
FROM case_history
GROUP BY SUBSTR(receipt_number, 1, 3)
ORDER BY case_count DESC;

PROMPT
PROMPT Cases by form type:
SELECT case_type,
       COUNT(DISTINCT receipt_number) AS case_count
FROM status_updates
GROUP BY case_type
ORDER BY case_count DESC;

PROMPT
PROMPT Cases by current status (from view):
SELECT current_status,
       COUNT(*) AS cnt
FROM v_case_current_status
GROUP BY current_status
ORDER BY cnt DESC
FETCH FIRST 15 ROWS ONLY;

PROMPT
PROMPT Active vs Inactive:
SELECT CASE is_active WHEN 1 THEN 'Active' ELSE 'Inactive' END AS status,
       COUNT(*) AS cnt
FROM case_history
GROUP BY is_active;

PROMPT
PROMPT Status updates per case (distribution):
SELECT num_updates, COUNT(*) AS cases_with_this_count
FROM (
    SELECT receipt_number, COUNT(*) AS num_updates
    FROM status_updates
    GROUP BY receipt_number
)
GROUP BY num_updates
ORDER BY num_updates;

PROMPT
PROMPT ============================================================
PROMPT  Stress Test Seed Complete!
PROMPT ============================================================
