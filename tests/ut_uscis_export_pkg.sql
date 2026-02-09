-- ============================================================
-- USCIS Case Tracker - Unit Tests for USCIS_EXPORT_PKG
-- Task 4.1.5: Unit Tests for Export/Import Package
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: tests/ut_uscis_export_pkg.sql
-- Purpose: utPLSQL unit tests for export/import functions
-- Dependencies: utPLSQL framework, USCIS_EXPORT_PKG, USCIS_CASE_PKG
-- ============================================================
-- 
-- To run these tests:
--   exec ut.run('ut_uscis_export_pkg');
-- 
-- Or run specific test:
--   exec ut.run('ut_uscis_export_pkg.test_export_json_basic');
--
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating UT_USCIS_EXPORT_PKG Test Package...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE ut_uscis_export_pkg AS
    
    -- %suite(USCIS Export Package Tests)
    -- %suitepath(uscis.export)
    -- %rollback(manual)
    
    -- ========================================================
    -- Test Constants
    -- ========================================================
    gc_test_receipt_1  CONSTANT VARCHAR2(13) := 'TST0000000001';
    gc_test_receipt_2  CONSTANT VARCHAR2(13) := 'TST0000000002';
    gc_test_receipt_3  CONSTANT VARCHAR2(13) := 'TST0000000003';
    gc_test_receipt_4  CONSTANT VARCHAR2(13) := 'TST0000000004';
    
    -- ========================================================
    -- Setup/Teardown
    -- ========================================================
    
    -- %beforeall
    PROCEDURE setup_suite;
    
    -- %afterall
    PROCEDURE teardown_suite;
    
    -- %beforeeach
    PROCEDURE setup_test;
    
    -- %aftereach
    PROCEDURE teardown_test;
    
    -- ========================================================
    -- export_cases_json Tests (4.1.1)
    -- ========================================================
    
    -- %test(Export JSON returns valid JSON with cases array)
    PROCEDURE test_export_json_basic;
    
    -- %test(Export JSON with no cases returns empty array)
    PROCEDURE test_export_json_empty;
    
    -- %test(Export JSON includes all case fields)
    PROCEDURE test_export_json_all_fields;
    
    -- %test(Export JSON with receipt filter returns matching cases only)
    PROCEDURE test_export_json_filter;
    
    -- %test(Export JSON active only excludes inactive cases)
    PROCEDURE test_export_json_active_only;
    
    -- %test(Export JSON with history includes status_history array)
    PROCEDURE test_export_json_with_history;
    
    -- %test(Export JSON without history omits status_history)
    PROCEDURE test_export_json_no_history;
    
    -- %test(Export JSON includes correct total_cases count)
    PROCEDURE test_export_json_total_count;
    
    -- %test(Export JSON receipt filter escapes wildcards safely)
    PROCEDURE test_export_json_filter_escapes;
    
    -- ========================================================
    -- export_cases_csv Tests (4.1.2)
    -- ========================================================
    
    -- %test(Export CSV returns header row)
    PROCEDURE test_export_csv_header;
    
    -- %test(Export CSV includes case data rows)
    PROCEDURE test_export_csv_data_rows;
    
    -- %test(Export CSV with no cases returns header only)
    PROCEDURE test_export_csv_empty;
    
    -- %test(Export CSV with receipt filter returns matching only)
    PROCEDURE test_export_csv_filter;
    
    -- %test(Export CSV active only excludes inactive cases)
    PROCEDURE test_export_csv_active_only;
    
    -- %test(Export CSV sanitizes formula injection characters)
    PROCEDURE test_export_csv_sanitization;
    
    -- ========================================================
    -- export_case_json Tests
    -- ========================================================
    
    -- %test(Export single case returns valid JSON)
    PROCEDURE test_export_single_case;
    
    -- %test(Export single case returns null for non-existent)
    PROCEDURE test_export_single_case_not_found;
    
    -- %test(Export single case with invalid receipt raises error)
    -- %throws(-20001)
    PROCEDURE test_export_single_invalid_receipt;
    
    -- ========================================================
    -- import_cases_json Tests (4.1.3)
    -- ========================================================
    
    -- %test(Import single case JSON creates case)
    PROCEDURE test_import_single_case;
    
    -- %test(Import array format JSON creates multiple cases)
    PROCEDURE test_import_array_cases;
    
    -- %test(Import with replace_existing replaces case)
    PROCEDURE test_import_replace_existing;
    
    -- %test(Import without replace raises error on duplicate)
    -- %throws(-20003)
    PROCEDURE test_import_duplicate_no_replace;
    
    -- %test(Import returns correct count of imported cases)
    PROCEDURE test_import_returns_count;
    
    -- %test(Import normalizes receipt numbers)
    PROCEDURE test_import_normalizes_receipt;
    
    -- %test(Import preserves all case fields)
    PROCEDURE test_import_preserves_fields;
    
    -- %test(Import sets inactive status correctly)
    PROCEDURE test_import_inactive_case;
    
    -- ========================================================
    -- validate_import_json Tests
    -- ========================================================
    
    -- %test(Validate returns valid for correct array format)
    PROCEDURE test_validate_array_format;
    
    -- %test(Validate returns valid for single case format)
    PROCEDURE test_validate_single_format;
    
    -- %test(Validate returns invalid for null input)
    PROCEDURE test_validate_null_input;
    
    -- %test(Validate returns invalid for malformed JSON)
    PROCEDURE test_validate_malformed_json;
    
    -- %test(Validate returns correct case count)
    PROCEDURE test_validate_case_count;
    
    -- ========================================================
    -- download_export Tests (4.1.4)
    -- ========================================================
    
    -- %test(Download outside APEX context raises error)
    -- %throws(-20040)
    PROCEDURE test_download_no_apex_context;
    
    -- ========================================================
    -- get_export_stats Tests
    -- ========================================================
    
    -- %test(Get export stats returns valid JSON with counts)
    PROCEDURE test_export_stats_basic;
    
    -- %test(Get export stats with filter returns subset)
    PROCEDURE test_export_stats_filtered;
    
    -- %test(Get export stats active only counts correctly)
    PROCEDURE test_export_stats_active_only;
    
    -- ========================================================
    -- Round-trip Tests
    -- ========================================================
    
    -- %test(Export then import produces equivalent data)
    PROCEDURE test_round_trip_json;

END ut_uscis_export_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY ut_uscis_export_pkg AS

    -- --------------------------------------------------------
    -- Setup/Teardown Procedures
    -- --------------------------------------------------------
    
    PROCEDURE setup_suite IS
    BEGIN
        -- Ensure clean state before all tests
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
        COMMIT;
    END setup_suite;
    
    PROCEDURE teardown_suite IS
    BEGIN
        -- Clean up all test data after suite
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
        COMMIT;
    END teardown_suite;
    
    PROCEDURE setup_test IS
    BEGIN
        -- Clean test data before each test
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%' OR receipt_number LIKE 'IOE%';
    END setup_test;
    
    PROCEDURE teardown_test IS
    BEGIN
        -- Rollback any uncommitted changes
        ROLLBACK;
    END teardown_test;
    
    -- --------------------------------------------------------
    -- Helper: Create a test case
    -- --------------------------------------------------------
    PROCEDURE create_test_case(
        p_receipt   IN VARCHAR2,
        p_case_type IN VARCHAR2 DEFAULT 'I-485',
        p_status    IN VARCHAR2 DEFAULT 'Case Was Received',
        p_notes     IN VARCHAR2 DEFAULT NULL,
        p_is_active IN BOOLEAN  DEFAULT TRUE
    ) IS
        l_dummy VARCHAR2(13);
    BEGIN
        l_dummy := uscis_case_pkg.add_case(
            p_receipt_number => p_receipt,
            p_case_type      => p_case_type,
            p_current_status => p_status,
            p_notes          => p_notes
        );
        IF NOT p_is_active THEN
            uscis_case_pkg.set_case_active(p_receipt, FALSE);
        END IF;
    END create_test_case;
    
    -- --------------------------------------------------------
    -- Helper: Count occurrences of substring in CLOB
    -- --------------------------------------------------------
    FUNCTION count_occurrences(
        p_clob   IN CLOB,
        p_search IN VARCHAR2
    ) RETURN NUMBER IS
        l_count NUMBER := 0;
        l_pos   NUMBER := 1;
    BEGIN
        LOOP
            l_pos := INSTR(p_clob, p_search, l_pos);
            EXIT WHEN l_pos = 0 OR l_pos IS NULL;
            l_count := l_count + 1;
            l_pos := l_pos + LENGTH(p_search);
        END LOOP;
        RETURN l_count;
    END count_occurrences;
    
    -- --------------------------------------------------------
    -- export_cases_json Tests (4.1.1)
    -- --------------------------------------------------------
    
    PROCEDURE test_export_json_basic IS
        l_json   CLOB;
        l_count  NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2, 'I-765', 'Card Being Produced');
        
        l_json := uscis_export_pkg.export_cases_json;
        
        -- Should contain cases array and metadata
        ut.expect(l_json).to_be_like('%"cases":[%');
        ut.expect(l_json).to_be_like('%"export_date":%');
        ut.expect(l_json).to_be_like('%"total_cases":2%');
        
        -- Should parse as valid JSON
        SELECT COUNT(*) INTO l_count
        FROM JSON_TABLE(l_json, '$.cases[*]' COLUMNS (rn VARCHAR2(13) PATH '$.receipt_number'));
        ut.expect(l_count).to_equal(2);
    END test_export_json_basic;
    
    PROCEDURE test_export_json_empty IS
        l_json CLOB;
    BEGIN
        -- No test data inserted
        l_json := uscis_export_pkg.export_cases_json(p_receipt_filter => 'TST');
        
        ut.expect(l_json).to_be_like('%"cases":[]%');
        ut.expect(l_json).to_be_like('%"total_cases":0%');
    END test_export_json_empty;
    
    PROCEDURE test_export_json_all_fields IS
        l_json CLOB;
        l_rn   VARCHAR2(13);
        l_ct   VARCHAR2(100);
        l_st   VARCHAR2(500);
        l_act  NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1, 'I-765', 'Card Being Produced', 'Test export notes');
        
        l_json := uscis_export_pkg.export_cases_json(p_receipt_filter => 'TST');
        
        -- Parse and verify fields
        SELECT 
            JSON_VALUE(l_json, '$.cases[0].receipt_number'),
            JSON_VALUE(l_json, '$.cases[0].case_type'),
            JSON_VALUE(l_json, '$.cases[0].current_status'),
            JSON_VALUE(l_json, '$.cases[0].is_active' RETURNING NUMBER)
        INTO l_rn, l_ct, l_st, l_act
        FROM dual;
        
        ut.expect(l_rn).to_equal(gc_test_receipt_1);
        ut.expect(l_ct).to_equal('I-765');
        ut.expect(l_st).to_equal('Card Being Produced');
        ut.expect(l_act).to_equal(1);
        
        -- Verify notes, tracking_since, exported_by are present
        ut.expect(l_json).to_be_like('%"notes":%');
        ut.expect(l_json).to_be_like('%"tracking_since":%');
        ut.expect(l_json).to_be_like('%"exported_by":%');
    END test_export_json_all_fields;
    
    PROCEDURE test_export_json_filter IS
        l_json  CLOB;
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case('IOE1234567890');
        
        -- Filter to TST prefix only
        l_json := uscis_export_pkg.export_cases_json(p_receipt_filter => 'TST');
        
        ut.expect(l_json).to_be_like('%"total_cases":2%');
        -- Should not contain the IOE case
        ut.expect(l_json).not_to_be_like('%IOE1234567890%');
    END test_export_json_filter;
    
    PROCEDURE test_export_json_active_only IS
        l_json CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2, p_is_active => FALSE);
        
        l_json := uscis_export_pkg.export_cases_json(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        
        ut.expect(l_json).to_be_like('%"total_cases":1%');
        ut.expect(l_json).to_be_like('%' || gc_test_receipt_1 || '%');
        ut.expect(l_json).not_to_be_like('%' || gc_test_receipt_2 || '%');
    END test_export_json_active_only;
    
    PROCEDURE test_export_json_with_history IS
        l_json CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        -- Add a status update to create history
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Case Is Being Actively Reviewed'
        );
        
        l_json := uscis_export_pkg.export_cases_json(
            p_receipt_filter  => 'TST',
            p_include_history => TRUE
        );
        
        ut.expect(l_json).to_be_like('%"status_history":[%');
    END test_export_json_with_history;
    
    PROCEDURE test_export_json_no_history IS
        l_json CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        l_json := uscis_export_pkg.export_cases_json(
            p_receipt_filter  => 'TST',
            p_include_history => FALSE
        );
        
        -- Should NOT contain status_history
        ut.expect(l_json).not_to_be_like('%"status_history"%');
    END test_export_json_no_history;
    
    PROCEDURE test_export_json_total_count IS
        l_json  CLOB;
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case(gc_test_receipt_3);
        
        l_json := uscis_export_pkg.export_cases_json(p_receipt_filter => 'TST');
        
        SELECT JSON_VALUE(l_json, '$.total_cases' RETURNING NUMBER)
        INTO l_count
        FROM dual;
        
        ut.expect(l_count).to_equal(3);
    END test_export_json_total_count;
    
    PROCEDURE test_export_json_filter_escapes IS
        l_json CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        -- Filter containing SQL wildcard characters should be escaped
        -- Should not match anything via wildcard injection
        l_json := uscis_export_pkg.export_cases_json(p_receipt_filter => '%');
        
        -- The '%' itself doesn't start with any receipt prefix, so should match nothing (or everything depending on impl)
        -- Since filter is literal '%' followed by wildcard '%', it looks for receipt_number LIKE '\%%'
        -- which means receipts starting with literal '%' — none exist
        ut.expect(l_json).to_be_like('%"total_cases":0%');
    END test_export_json_filter_escapes;
    
    -- --------------------------------------------------------
    -- export_cases_csv Tests (4.1.2)
    -- --------------------------------------------------------
    
    PROCEDURE test_export_csv_header IS
        l_csv       CLOB;
        l_first_line VARCHAR2(4000);
    BEGIN
        l_csv := uscis_export_pkg.export_cases_csv(p_receipt_filter => 'TST');
        
        -- Extract first line (header) — handle both CRLF and LF line endings
        DECLARE
            l_pos NUMBER;
        BEGIN
            l_pos := INSTR(l_csv, CHR(13));
            IF l_pos = 0 OR l_pos IS NULL THEN
                l_pos := INSTR(l_csv, CHR(10));
            END IF;
            -- If no newline found, treat the entire string as the first line
            IF l_pos = 0 OR l_pos IS NULL THEN
                l_pos := LENGTH(l_csv) + 1;
            END IF;
            l_first_line := SUBSTR(l_csv, 1, l_pos - 1);
        END;
        
        ut.expect(l_first_line).to_equal(
            'Receipt Number,Case Type,Current Status,Last Updated,Is Active,Check Frequency,Tracking Since,Created By,Notes'
        );
    END test_export_csv_header;
    
    PROCEDURE test_export_csv_data_rows IS
        l_csv       CLOB;
        l_line_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        
        l_csv := uscis_export_pkg.export_cases_csv(p_receipt_filter => 'TST');
        
        -- Count lines: 1 header + 2 data rows (each ending with CRLF)
        l_line_count := count_occurrences(l_csv, CHR(10));
        ut.expect(l_line_count).to_equal(3);  -- header + 2 data rows
        
        -- Verify receipt numbers appear
        ut.expect(l_csv).to_be_like('%' || gc_test_receipt_1 || '%');
        ut.expect(l_csv).to_be_like('%' || gc_test_receipt_2 || '%');
    END test_export_csv_data_rows;
    
    PROCEDURE test_export_csv_empty IS
        l_csv CLOB;
    BEGIN
        l_csv := uscis_export_pkg.export_cases_csv(p_receipt_filter => 'TST');
        
        -- Should only contain header row
        ut.expect(count_occurrences(l_csv, CHR(10))).to_equal(1);
    END test_export_csv_empty;
    
    PROCEDURE test_export_csv_filter IS
        l_csv CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case('IOE1234567890');
        
        l_csv := uscis_export_pkg.export_cases_csv(p_receipt_filter => 'TST');
        
        ut.expect(l_csv).to_be_like('%' || gc_test_receipt_1 || '%');
        ut.expect(l_csv).not_to_be_like('%IOE1234567890%');
    END test_export_csv_filter;
    
    PROCEDURE test_export_csv_active_only IS
        l_csv CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2, p_is_active => FALSE);
        
        l_csv := uscis_export_pkg.export_cases_csv(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        
        ut.expect(l_csv).to_be_like('%' || gc_test_receipt_1 || '%');
        ut.expect(l_csv).not_to_be_like('%' || gc_test_receipt_2 || '%');
    END test_export_csv_active_only;
    
    PROCEDURE test_export_csv_sanitization IS
        l_csv  CLOB;
        l_dummy VARCHAR2(13);
    BEGIN
        -- Create case with formula-injection notes
        l_dummy := uscis_case_pkg.add_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Case Was Received',
            p_notes          => '=CMD("calc")'
        );
        
        l_csv := uscis_export_pkg.export_cases_csv(p_receipt_filter => 'TST');
        
        -- Notes starting with '=' should be prefixed with single quote
        ut.expect(l_csv).to_be_like('%''=CMD%');
        -- Should NOT contain bare =CMD
        ut.expect(l_csv).not_to_be_like('%"=CMD%');
    END test_export_csv_sanitization;
    
    -- --------------------------------------------------------
    -- export_case_json Tests
    -- --------------------------------------------------------
    
    PROCEDURE test_export_single_case IS
        l_json CLOB;
        l_rn   VARCHAR2(13);
    BEGIN
        create_test_case(gc_test_receipt_1, 'I-765', 'Card Being Produced');
        
        l_json := uscis_export_pkg.export_case_json(gc_test_receipt_1);
        
        ut.expect(l_json).is_not_null();
        
        SELECT JSON_VALUE(l_json, '$.receipt_number')
        INTO l_rn
        FROM dual;
        
        ut.expect(l_rn).to_equal(gc_test_receipt_1);
    END test_export_single_case;
    
    PROCEDURE test_export_single_case_not_found IS
        l_json CLOB;
    BEGIN
        l_json := uscis_export_pkg.export_case_json(gc_test_receipt_1);
        ut.expect(l_json).to_be_null();
    END test_export_single_case_not_found;
    
    PROCEDURE test_export_single_invalid_receipt IS
        l_json CLOB;
    BEGIN
        -- Should raise -20001 for invalid receipt format
        l_json := uscis_export_pkg.export_case_json('INVALID');
    END test_export_single_invalid_receipt;
    
    -- --------------------------------------------------------
    -- import_cases_json Tests (4.1.3)
    -- --------------------------------------------------------
    
    PROCEDURE test_import_single_case IS
        l_count   NUMBER;
        l_json    CLOB;
        l_exists  BOOLEAN;
    BEGIN
        l_json := '{"receipt_number":"' || gc_test_receipt_1 || '",' ||
                  '"case_type":"I-485",' ||
                  '"current_status":"Case Was Received",' ||
                  '"last_updated":"2025-01-15T10:30:00Z",' ||
                  '"details":"Your case was received",' ||
                  '"notes":"Test import",' ||
                  '"is_active":1,' ||
                  '"check_frequency":24}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        ut.expect(l_count).to_equal(1);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
    END test_import_single_case;
    
    PROCEDURE test_import_array_cases IS
        l_count NUMBER;
        l_json  CLOB;
    BEGIN
        l_json := '{"cases":[' ||
            '{"receipt_number":"' || gc_test_receipt_1 || '","case_type":"I-485","current_status":"Case Was Received","is_active":1,"check_frequency":24},' ||
            '{"receipt_number":"' || gc_test_receipt_2 || '","case_type":"I-765","current_status":"Card Being Produced","is_active":1,"check_frequency":12}' ||
        ']}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        ut.expect(l_count).to_equal(2);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_2)).to_be_true();
    END test_import_array_cases;
    
    PROCEDURE test_import_replace_existing IS
        l_count  NUMBER;
        l_json   CLOB;
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        -- Create existing case
        create_test_case(gc_test_receipt_1, 'I-485', 'Case Was Received');
        
        -- Import with replace
        l_json := '{"receipt_number":"' || gc_test_receipt_1 || '",' ||
                  '"case_type":"I-765",' ||
                  '"current_status":"Card Being Produced",' ||
                  '"is_active":1,"check_frequency":12}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json, p_replace_existing => TRUE);
        
        ut.expect(l_count).to_equal(1);
        
        -- Verify replaced data
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.case_type).to_equal('I-765');
        ut.expect(l_rec.current_status).to_equal('Card Being Produced');
    END test_import_replace_existing;
    
    PROCEDURE test_import_duplicate_no_replace IS
        l_count NUMBER;
        l_json  CLOB;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        l_json := '{"receipt_number":"' || gc_test_receipt_1 || '",' ||
                  '"case_type":"I-485","current_status":"Case Was Received"}';
        
        -- Should raise -20003 (duplicate case)
        l_count := uscis_export_pkg.import_cases_json(l_json, p_replace_existing => FALSE);
    END test_import_duplicate_no_replace;
    
    PROCEDURE test_import_returns_count IS
        l_count NUMBER;
        l_json  CLOB;
    BEGIN
        l_json := '{"cases":[' ||
            '{"receipt_number":"' || gc_test_receipt_1 || '","case_type":"I-485","current_status":"Received","is_active":1},' ||
            '{"receipt_number":"' || gc_test_receipt_2 || '","case_type":"I-765","current_status":"Approved","is_active":1},' ||
            '{"receipt_number":"' || gc_test_receipt_3 || '","case_type":"I-140","current_status":"Pending","is_active":1}' ||
        ']}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        ut.expect(l_count).to_equal(3);
    END test_import_returns_count;
    
    PROCEDURE test_import_normalizes_receipt IS
        l_count NUMBER;
        l_json  CLOB;
    BEGIN
        -- Use lowercase receipt number
        l_json := '{"receipt_number":"tst0000000001",' ||
                  '"case_type":"I-485","current_status":"Case Was Received"}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        ut.expect(l_count).to_equal(1);
        ut.expect(uscis_case_pkg.case_exists('TST0000000001')).to_be_true();
    END test_import_normalizes_receipt;
    
    PROCEDURE test_import_preserves_fields IS
        l_count  NUMBER;
        l_json   CLOB;
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        l_json := '{"receipt_number":"' || gc_test_receipt_1 || '",' ||
                  '"case_type":"I-765",' ||
                  '"current_status":"Card Being Produced",' ||
                  '"last_updated":"2025-06-15T14:30:00Z",' ||
                  '"details":"Your card is being produced",' ||
                  '"notes":"Important note",' ||
                  '"is_active":1,' ||
                  '"check_frequency":12}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.case_type).to_equal('I-765');
        ut.expect(l_rec.current_status).to_equal('Card Being Produced');
        ut.expect(l_rec.notes).to_equal('Important note');
        ut.expect(l_rec.check_frequency).to_equal(12);
    END test_import_preserves_fields;
    
    PROCEDURE test_import_inactive_case IS
        l_count  NUMBER;
        l_json   CLOB;
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        l_json := '{"receipt_number":"' || gc_test_receipt_1 || '",' ||
                  '"case_type":"I-485",' ||
                  '"current_status":"Case Was Received",' ||
                  '"is_active":0,' ||
                  '"check_frequency":24}';
        
        l_count := uscis_export_pkg.import_cases_json(l_json);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.is_active).to_equal(0);
    END test_import_inactive_case;
    
    -- --------------------------------------------------------
    -- validate_import_json Tests
    -- --------------------------------------------------------
    
    PROCEDURE test_validate_array_format IS
        l_result CLOB;
        l_valid  VARCHAR2(10);
        l_format VARCHAR2(20);
    BEGIN
        l_result := uscis_export_pkg.validate_import_json(
            '{"cases":[{"receipt_number":"TST0000000001"},{"receipt_number":"TST0000000002"}]}'
        );
        
        SELECT 
            JSON_VALUE(l_result, '$.valid'),
            JSON_VALUE(l_result, '$.format')
        INTO l_valid, l_format
        FROM dual;
        
        ut.expect(l_valid).to_equal('true');
        ut.expect(l_format).to_equal('array');
    END test_validate_array_format;
    
    PROCEDURE test_validate_single_format IS
        l_result CLOB;
        l_valid  VARCHAR2(10);
        l_format VARCHAR2(20);
    BEGIN
        l_result := uscis_export_pkg.validate_import_json(
            '{"receipt_number":"TST0000000001","case_type":"I-485"}'
        );
        
        SELECT 
            JSON_VALUE(l_result, '$.valid'),
            JSON_VALUE(l_result, '$.format')
        INTO l_valid, l_format
        FROM dual;
        
        ut.expect(l_valid).to_equal('true');
        ut.expect(l_format).to_equal('single');
    END test_validate_single_format;
    
    PROCEDURE test_validate_null_input IS
        l_result CLOB;
        l_valid  VARCHAR2(10);
    BEGIN
        l_result := uscis_export_pkg.validate_import_json(NULL);
        
        SELECT JSON_VALUE(l_result, '$.valid')
        INTO l_valid
        FROM dual;
        
        ut.expect(l_valid).to_equal('false');
    END test_validate_null_input;
    
    PROCEDURE test_validate_malformed_json IS
        l_result CLOB;
        l_valid  VARCHAR2(10);
    BEGIN
        l_result := uscis_export_pkg.validate_import_json('not valid json{{{');
        
        SELECT JSON_VALUE(l_result, '$.valid')
        INTO l_valid
        FROM dual;
        
        ut.expect(l_valid).to_equal('false');
    END test_validate_malformed_json;
    
    PROCEDURE test_validate_case_count IS
        l_result CLOB;
        l_count  NUMBER;
    BEGIN
        l_result := uscis_export_pkg.validate_import_json(
            '{"cases":[{"receipt_number":"A"},{"receipt_number":"B"},{"receipt_number":"C"}]}'
        );
        
        SELECT JSON_VALUE(l_result, '$.case_count' RETURNING NUMBER)
        INTO l_count
        FROM dual;
        
        ut.expect(l_count).to_equal(3);
    END test_validate_case_count;
    
    -- --------------------------------------------------------
    -- download_export Tests (4.1.4)
    -- --------------------------------------------------------
    
    PROCEDURE test_download_no_apex_context IS
    BEGIN
        -- Outside APEX, g_flow_id is NULL so download should fail
        uscis_export_pkg.download_export(p_format => 'JSON');
    END test_download_no_apex_context;
    
    -- --------------------------------------------------------
    -- get_export_stats Tests
    -- --------------------------------------------------------
    
    PROCEDURE test_export_stats_basic IS
        l_stats   CLOB;
        l_total   NUMBER;
        l_active  NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1, 'I-485', 'Case Was Received');
        create_test_case(gc_test_receipt_2, 'I-765', 'Card Being Produced');
        create_test_case(gc_test_receipt_3, 'I-485', 'Approved', p_is_active => FALSE);
        
        l_stats := uscis_export_pkg.get_export_stats(p_receipt_filter => 'TST');
        
        SELECT 
            JSON_VALUE(l_stats, '$.total_cases' RETURNING NUMBER),
            JSON_VALUE(l_stats, '$.active_cases' RETURNING NUMBER)
        INTO l_total, l_active
        FROM dual;
        
        ut.expect(l_total).to_equal(3);
        ut.expect(l_active).to_equal(2);
        
        -- Should include by_type and by_status arrays
        ut.expect(l_stats).to_be_like('%"by_type":%');
        ut.expect(l_stats).to_be_like('%"by_status":%');
    END test_export_stats_basic;
    
    PROCEDURE test_export_stats_filtered IS
        l_stats CLOB;
        l_total NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case('IOE1234567890');
        
        l_stats := uscis_export_pkg.get_export_stats(p_receipt_filter => 'TST');
        
        SELECT JSON_VALUE(l_stats, '$.total_cases' RETURNING NUMBER)
        INTO l_total
        FROM dual;
        
        ut.expect(l_total).to_equal(1);
    END test_export_stats_filtered;
    
    PROCEDURE test_export_stats_active_only IS
        l_stats    CLOB;
        l_total    NUMBER;
        l_inactive NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2, p_is_active => FALSE);
        
        l_stats := uscis_export_pkg.get_export_stats(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        
        SELECT 
            JSON_VALUE(l_stats, '$.total_cases' RETURNING NUMBER),
            JSON_VALUE(l_stats, '$.inactive_cases' RETURNING NUMBER)
        INTO l_total, l_inactive
        FROM dual;
        
        ut.expect(l_total).to_equal(1);
        ut.expect(l_inactive).to_equal(0);
    END test_export_stats_active_only;
    
    -- --------------------------------------------------------
    -- Round-trip Tests
    -- --------------------------------------------------------
    
    PROCEDURE test_round_trip_json IS
        l_export_json CLOB;
        l_import_count NUMBER;
        l_orig_cursor  SYS_REFCURSOR;
        l_new_cursor   SYS_REFCURSOR;
        l_orig_rec     v_case_current_status%ROWTYPE;
        l_new_rec      v_case_current_status%ROWTYPE;
    BEGIN
        -- Create test cases
        create_test_case(gc_test_receipt_1, 'I-485', 'Case Was Received', 'Notes A');
        create_test_case(gc_test_receipt_2, 'I-765', 'Card Being Produced', 'Notes B');
        
        -- Export
        l_export_json := uscis_export_pkg.export_cases_json(
            p_receipt_filter  => 'TST',
            p_include_history => FALSE
        );
        
        -- Read original data for comparison
        l_orig_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_orig_cursor INTO l_orig_rec;
        CLOSE l_orig_cursor;
        
        -- Delete original cases
        uscis_case_pkg.delete_case(gc_test_receipt_1);
        uscis_case_pkg.delete_case(gc_test_receipt_2);
        
        -- Re-import
        l_import_count := uscis_export_pkg.import_cases_json(l_export_json);
        ut.expect(l_import_count).to_equal(2);
        
        -- Verify imported data matches original
        l_new_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_new_cursor INTO l_new_rec;
        CLOSE l_new_cursor;
        
        ut.expect(l_new_rec.receipt_number).to_equal(l_orig_rec.receipt_number);
        ut.expect(l_new_rec.case_type).to_equal(l_orig_rec.case_type);
        ut.expect(l_new_rec.current_status).to_equal(l_orig_rec.current_status);
        ut.expect(l_new_rec.is_active).to_equal(l_orig_rec.is_active);
    END test_round_trip_json;

END ut_uscis_export_pkg;
/

SHOW ERRORS PACKAGE ut_uscis_export_pkg
SHOW ERRORS PACKAGE BODY ut_uscis_export_pkg

PROMPT ============================================================
PROMPT UT_USCIS_EXPORT_PKG created successfully
PROMPT Run with: exec ut.run('ut_uscis_export_pkg');
PROMPT ============================================================
