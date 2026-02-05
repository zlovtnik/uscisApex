-- ============================================================
-- USCIS Case Tracker - Unit Tests for USCIS_CASE_PKG
-- Task 2.2.11: Unit Tests for Case Management Package
-- Oracle 19c+ / Autonomous Database Compatible
-- ============================================================
-- File: tests/ut_uscis_case_pkg.sql
-- Purpose: utPLSQL unit tests for case management functions
-- Dependencies: utPLSQL framework, USCIS_CASE_PKG
-- ============================================================
-- 
-- To run these tests:
--   exec ut.run('ut_uscis_case_pkg');
-- 
-- Or run specific test:
--   exec ut.run('ut_uscis_case_pkg.test_add_case_valid');
--
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating UT_USCIS_CASE_PKG Test Package...
PROMPT ============================================================

CREATE OR REPLACE PACKAGE ut_uscis_case_pkg AS
    
    -- %suite(USCIS Case Package Tests)
    -- %suitepath(uscis.case)
    -- %rollback(manual)
    
    -- ========================================================
    -- Test Constants
    -- ========================================================
    gc_test_receipt_1  CONSTANT VARCHAR2(13) := 'TST0000000001';
    gc_test_receipt_2  CONSTANT VARCHAR2(13) := 'TST0000000002';
    gc_test_receipt_3  CONSTANT VARCHAR2(13) := 'TST0000000003';
    gc_invalid_receipt CONSTANT VARCHAR2(10) := 'INVALID';
    
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
    -- add_case Tests (2.2.1)
    -- ========================================================
    
    -- %test(Add case with valid receipt number succeeds)
    PROCEDURE test_add_case_valid;
    
    -- %test(Add case with invalid receipt number raises exception)
    -- %throws(-20001)
    PROCEDURE test_add_case_invalid_receipt;
    
    -- %test(Add duplicate case raises exception)
    -- %throws(-20003)
    PROCEDURE test_add_case_duplicate;
    
    -- %test(Add case with all optional parameters)
    PROCEDURE test_add_case_with_options;
    
    -- %test(Add case normalizes receipt number)
    PROCEDURE test_add_case_normalizes_receipt;
    
    -- ========================================================
    -- add_or_update_case Tests (2.2.2)
    -- ========================================================
    
    -- %test(Add or update creates new case when not exists)
    PROCEDURE test_add_or_update_creates_new;
    
    -- %test(Add or update adds status to existing case)
    PROCEDURE test_add_or_update_adds_status;
    
    -- %test(Add or update handles concurrent inserts)
    PROCEDURE test_add_or_update_concurrent;
    
    -- ========================================================
    -- get_case Tests (2.2.3)
    -- ========================================================
    
    -- %test(Get case returns current status)
    PROCEDURE test_get_case_current_status;
    
    -- %test(Get case with history returns all statuses)
    PROCEDURE test_get_case_with_history;
    
    -- %test(Get non-existent case returns empty cursor)
    PROCEDURE test_get_case_not_found;
    
    -- %test(Get case validates receipt format)
    -- %throws(-20001)
    PROCEDURE test_get_case_invalid_receipt;
    
    -- ========================================================
    -- list_cases Tests (2.2.4)
    -- ========================================================
    
    -- %test(List cases returns all active cases)
    PROCEDURE test_list_cases_all;
    
    -- %test(List cases with receipt filter)
    PROCEDURE test_list_cases_filtered;
    
    -- %test(List cases with status filter)
    PROCEDURE test_list_cases_status_filter;
    
    -- %test(List cases pagination works correctly)
    PROCEDURE test_list_cases_pagination;
    
    -- %test(List cases includes inactive when requested)
    PROCEDURE test_list_cases_include_inactive;
    
    -- %test(List cases order by validation prevents injection)
    PROCEDURE test_list_cases_order_by_safe;
    
    -- ========================================================
    -- count_cases Tests (2.2.5)
    -- ========================================================
    
    -- %test(Count cases returns correct total)
    PROCEDURE test_count_cases_total;
    
    -- %test(Count cases with filter)
    PROCEDURE test_count_cases_filtered;
    
    -- %test(Count cases active only)
    PROCEDURE test_count_cases_active_only;
    
    -- ========================================================
    -- delete_case Tests (2.2.6)
    -- ========================================================
    
    -- %test(Delete case removes case and status history)
    PROCEDURE test_delete_case_success;
    
    -- %test(Delete non-existent case raises exception)
    -- %throws(-20002)
    PROCEDURE test_delete_case_not_found;
    
    -- %test(Delete case with invalid receipt raises exception)
    -- %throws(-20001)
    PROCEDURE test_delete_case_invalid_receipt;
    
    -- ========================================================
    -- case_exists Tests (2.2.7)
    -- ========================================================
    
    -- %test(Case exists returns true for existing case)
    PROCEDURE test_case_exists_true;
    
    -- %test(Case exists returns false for non-existent case)
    PROCEDURE test_case_exists_false;
    
    -- %test(Case exists normalizes receipt number)
    PROCEDURE test_case_exists_normalizes;
    
    -- ========================================================
    -- get_cases_by_receipts Tests (2.2.8)
    -- ========================================================
    
    -- %test(Get cases by receipts returns matching cases)
    PROCEDURE test_get_cases_by_receipts;
    
    -- %test(Get cases by receipts with empty array returns empty)
    PROCEDURE test_get_cases_by_receipts_empty;
    
    -- %test(Get cases by receipts with null returns empty)
    PROCEDURE test_get_cases_by_receipts_null;
    
    -- ========================================================
    -- update_case_notes Tests (2.2.9)
    -- ========================================================
    
    -- %test(Update case notes succeeds)
    PROCEDURE test_update_notes_success;
    
    -- %test(Update notes for non-existent case raises exception)
    -- %throws(-20002)
    PROCEDURE test_update_notes_not_found;
    
    -- %test(Update notes with null clears notes)
    PROCEDURE test_update_notes_null;
    
    -- ========================================================
    -- set_case_active Tests (2.2.10)
    -- ========================================================
    
    -- %test(Set case active to false deactivates case)
    PROCEDURE test_set_case_inactive;
    
    -- %test(Set case active to true activates case)
    PROCEDURE test_set_case_active;
    
    -- %test(Set active for non-existent case raises exception)
    -- %throws(-20002)
    PROCEDURE test_set_active_not_found;
    
    -- ========================================================
    -- Additional Function Tests
    -- ========================================================
    
    -- %test(Get status history returns ordered results)
    PROCEDURE test_get_status_history;
    
    -- %test(Get latest status returns most recent)
    PROCEDURE test_get_latest_status;
    
    -- %test(Count status updates returns correct count)
    PROCEDURE test_count_status_updates;
    
    -- %test(Update last checked timestamp)
    PROCEDURE test_update_last_checked;
    
    -- %test(Set check frequency with valid range)
    PROCEDURE test_set_check_frequency;
    
    -- %test(Set check frequency out of range raises error)
    -- %throws(-20100)
    PROCEDURE test_set_check_frequency_invalid;
    
    -- %test(Delete multiple cases)
    PROCEDURE test_delete_cases_bulk;
    
    -- %test(Purge inactive cases older than threshold)
    PROCEDURE test_purge_inactive_cases;
    
    -- %test(Get cases due for check)
    PROCEDURE test_get_cases_due_for_check;

END ut_uscis_case_pkg;
/

-- ============================================================
-- Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY ut_uscis_case_pkg AS

    -- --------------------------------------------------------
    -- Setup/Teardown Procedures
    -- --------------------------------------------------------
    
    PROCEDURE setup_suite IS
    BEGIN
        -- Ensure clean state before all tests
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
        COMMIT;
    END setup_suite;
    
    PROCEDURE teardown_suite IS
    BEGIN
        -- Clean up all test data after suite
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
        COMMIT;
    END teardown_suite;
    
    PROCEDURE setup_test IS
    BEGIN
        -- Clean test data before each test
        DELETE FROM status_updates WHERE receipt_number LIKE 'TST%';
        DELETE FROM case_history WHERE receipt_number LIKE 'TST%';
    END setup_test;
    
    PROCEDURE teardown_test IS
    BEGIN
        -- Rollback any uncommitted changes
        ROLLBACK;
    END teardown_test;
    
    -- --------------------------------------------------------
    -- Helper Procedures
    -- --------------------------------------------------------
    
    PROCEDURE create_test_case(
        p_receipt IN VARCHAR2,
        p_status  IN VARCHAR2 DEFAULT 'Case Was Received'
    ) IS
        l_dummy VARCHAR2(13);
    BEGIN
        l_dummy := uscis_case_pkg.add_case(
            p_receipt_number => p_receipt,
            p_case_type      => 'I-485',
            p_current_status => p_status
        );
    END create_test_case;
    
    -- --------------------------------------------------------
    -- add_case Tests (2.2.1)
    -- --------------------------------------------------------
    
    PROCEDURE test_add_case_valid IS
        l_receipt VARCHAR2(13);
    BEGIN
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Case Was Received'
        );
        
        ut.expect(l_receipt).to_equal(gc_test_receipt_1);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
    END test_add_case_valid;
    
    PROCEDURE test_add_case_invalid_receipt IS
        l_receipt VARCHAR2(13);
    BEGIN
        -- This should raise -20001
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number => gc_invalid_receipt
        );
    END test_add_case_invalid_receipt;
    
    PROCEDURE test_add_case_duplicate IS
        l_receipt VARCHAR2(13);
    BEGIN
        -- First insert should succeed
        l_receipt := uscis_case_pkg.add_case(p_receipt_number => gc_test_receipt_1);
        
        -- Second insert should raise -20003
        l_receipt := uscis_case_pkg.add_case(p_receipt_number => gc_test_receipt_1);
    END test_add_case_duplicate;
    
    PROCEDURE test_add_case_with_options IS
        l_receipt VARCHAR2(13);
        l_cursor  SYS_REFCURSOR;
        l_rec     v_case_current_status%ROWTYPE;
    BEGIN
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number  => gc_test_receipt_1,
            p_case_type       => 'I-765',
            p_current_status  => 'Card Being Produced',
            p_details         => 'Your card is being produced',
            p_notes           => 'Test notes',
            p_source          => 'API',
            p_check_frequency => 12
        );
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.case_type).to_equal('I-765');
        ut.expect(l_rec.current_status).to_equal('Card Being Produced');
        ut.expect(l_rec.notes).to_equal('Test notes');
        ut.expect(l_rec.check_frequency).to_equal(12);
    END test_add_case_with_options;
    
    PROCEDURE test_add_case_normalizes_receipt IS
        l_receipt VARCHAR2(13);
    BEGIN
        -- Input with lowercase should be normalized
        l_receipt := uscis_case_pkg.add_case(
            p_receipt_number => 'tst0000000001'
        );
        
        ut.expect(l_receipt).to_equal('TST0000000001');
        ut.expect(uscis_case_pkg.case_exists('TST0000000001')).to_be_true();
    END test_add_case_normalizes_receipt;
    
    -- --------------------------------------------------------
    -- add_or_update_case Tests (2.2.2)
    -- --------------------------------------------------------
    
    PROCEDURE test_add_or_update_creates_new IS
    BEGIN
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_false();
        
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Case Received'
        );
        
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
    END test_add_or_update_creates_new;
    
    PROCEDURE test_add_or_update_adds_status IS
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Status 1');
        
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Status 2'
        );
        
        l_count := uscis_case_pkg.count_status_updates(gc_test_receipt_1);
        ut.expect(l_count).to_equal(2);
    END test_add_or_update_adds_status;
    
    PROCEDURE test_add_or_update_concurrent IS
    BEGIN
        -- Simulate concurrent insert by calling add_or_update twice quickly
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Status 1'
        );
        
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Status 2'
        );
        
        -- Should have 1 case with 2 status updates
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
        ut.expect(uscis_case_pkg.count_status_updates(gc_test_receipt_1)).to_equal(2);
    END test_add_or_update_concurrent;
    
    -- --------------------------------------------------------
    -- get_case Tests (2.2.3)
    -- --------------------------------------------------------
    
    PROCEDURE test_get_case_current_status IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Test Status');
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        
        ut.expect(l_cursor%FOUND).to_be_true();
        ut.expect(l_rec.receipt_number).to_equal(gc_test_receipt_1);
        ut.expect(l_rec.current_status).to_equal('Test Status');
        
        CLOSE l_cursor;
    END test_get_case_current_status;
    
    PROCEDURE test_get_case_with_history IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        -- Declare typed variables for each cursor column
        l_receipt_number   VARCHAR2(13);
        l_case_type        VARCHAR2(50);
        l_current_status   VARCHAR2(500);
        l_last_updated     TIMESTAMP;
        l_details          CLOB;
        l_source           VARCHAR2(50);
        l_tracking_since   TIMESTAMP;
        l_created_by       VARCHAR2(255);
        l_notes            CLOB;
        l_is_active        NUMBER;
        l_check_frequency  NUMBER;
        l_last_checked_at  TIMESTAMP;
        l_total_updates    NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Status 1');
        
        uscis_case_pkg.add_or_update_case(
            p_receipt_number => gc_test_receipt_1,
            p_case_type      => 'I-485',
            p_current_status => 'Status 2'
        );
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, TRUE);
        
        LOOP
            FETCH l_cursor INTO l_receipt_number, l_case_type, l_current_status, l_last_updated,
                               l_details, l_source, l_tracking_since, l_created_by, l_notes,
                               l_is_active, l_check_frequency, l_last_checked_at, l_total_updates;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(2);
    END test_get_case_with_history;
    
    PROCEDURE test_get_case_not_found IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        l_cursor := uscis_case_pkg.get_case('TST9999999999', FALSE);
        FETCH l_cursor INTO l_rec;
        
        ut.expect(l_cursor%NOTFOUND).to_be_true();
        
        CLOSE l_cursor;
    END test_get_case_not_found;
    
    PROCEDURE test_get_case_invalid_receipt IS
        l_cursor SYS_REFCURSOR;
    BEGIN
        l_cursor := uscis_case_pkg.get_case(gc_invalid_receipt, FALSE);
    END test_get_case_invalid_receipt;
    
    -- --------------------------------------------------------
    -- list_cases Tests (2.2.4)
    -- --------------------------------------------------------
    
    PROCEDURE test_list_cases_all IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case(gc_test_receipt_3);
        
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(3);
    END test_list_cases_all;
    
    PROCEDURE test_list_cases_filtered IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST0000000001'
        );
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(1);
    END test_list_cases_filtered;
    
    PROCEDURE test_list_cases_status_filter IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Case Approved');
        create_test_case(gc_test_receipt_2, 'Case Denied');
        create_test_case(gc_test_receipt_3, 'Case Approved');
        
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_status_filter  => 'Approved'
        );
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(2);
    END test_list_cases_status_filter;
    
    PROCEDURE test_list_cases_pagination IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
        l_dummy  VARCHAR2(13);
    BEGIN
        -- Create 5 test cases
        FOR i IN 1..5 LOOP
            l_dummy := uscis_case_pkg.add_case('TST000000000' || i);
        END LOOP;
        
        -- Get page 1 with size 2
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_page_size      => 2,
            p_page           => 1
        );
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(2);
    END test_list_cases_pagination;
    
    PROCEDURE test_list_cases_include_inactive IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        
        -- Deactivate one case
        uscis_case_pkg.set_case_active(gc_test_receipt_1, FALSE);
        
        -- Count active only
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        ut.expect(l_count).to_equal(1);
        
        -- Count all
        l_count := 0;
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_active_only    => FALSE
        );
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        ut.expect(l_count).to_equal(2);
    END test_list_cases_include_inactive;
    
    PROCEDURE test_list_cases_order_by_safe IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        -- Try SQL injection in order_by - should use default safely
        l_cursor := uscis_case_pkg.list_cases(
            p_receipt_filter => 'TST',
            p_order_by       => 'RECEIPT_NUMBER; DROP TABLE case_history;--'
        );
        
        -- Should still return results (injection blocked)
        FETCH l_cursor INTO l_rec;
        ut.expect(l_rec.receipt_number).to_equal(gc_test_receipt_1);
        CLOSE l_cursor;
    END test_list_cases_order_by_safe;
    
    -- --------------------------------------------------------
    -- count_cases Tests (2.2.5)
    -- --------------------------------------------------------
    
    PROCEDURE test_count_cases_total IS
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case(gc_test_receipt_3);
        
        l_count := uscis_case_pkg.count_cases(p_receipt_filter => 'TST');
        ut.expect(l_count).to_equal(3);
    END test_count_cases_total;
    
    PROCEDURE test_count_cases_filtered IS
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        
        l_count := uscis_case_pkg.count_cases(p_receipt_filter => 'TST0000000001');
        ut.expect(l_count).to_equal(1);
    END test_count_cases_filtered;
    
    PROCEDURE test_count_cases_active_only IS
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        
        uscis_case_pkg.set_case_active(gc_test_receipt_1, FALSE);
        
        l_count := uscis_case_pkg.count_cases(
            p_receipt_filter => 'TST',
            p_active_only    => TRUE
        );
        ut.expect(l_count).to_equal(1);
        
        l_count := uscis_case_pkg.count_cases(
            p_receipt_filter => 'TST',
            p_active_only    => FALSE
        );
        ut.expect(l_count).to_equal(2);
    END test_count_cases_active_only;
    
    -- --------------------------------------------------------
    -- delete_case Tests (2.2.6)
    -- --------------------------------------------------------
    
    PROCEDURE test_delete_case_success IS
    BEGIN
        create_test_case(gc_test_receipt_1);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
        
        uscis_case_pkg.delete_case(gc_test_receipt_1);
        
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_false();
    END test_delete_case_success;
    
    PROCEDURE test_delete_case_not_found IS
    BEGIN
        uscis_case_pkg.delete_case('TST9999999999');
    END test_delete_case_not_found;
    
    PROCEDURE test_delete_case_invalid_receipt IS
    BEGIN
        uscis_case_pkg.delete_case(gc_invalid_receipt);
    END test_delete_case_invalid_receipt;
    
    -- --------------------------------------------------------
    -- case_exists Tests (2.2.7)
    -- --------------------------------------------------------
    
    PROCEDURE test_case_exists_true IS
    BEGIN
        create_test_case(gc_test_receipt_1);
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_true();
    END test_case_exists_true;
    
    PROCEDURE test_case_exists_false IS
    BEGIN
        ut.expect(uscis_case_pkg.case_exists('TST9999999999')).to_be_false();
    END test_case_exists_false;
    
    PROCEDURE test_case_exists_normalizes IS
    BEGIN
        create_test_case(gc_test_receipt_1);
        -- Check with lowercase
        ut.expect(uscis_case_pkg.case_exists('tst0000000001')).to_be_true();
    END test_case_exists_normalizes;
    
    -- --------------------------------------------------------
    -- get_cases_by_receipts Tests (2.2.8)
    -- --------------------------------------------------------
    
    PROCEDURE test_get_cases_by_receipts IS
        l_receipts uscis_types_pkg.t_receipt_tab;
        l_cursor   SYS_REFCURSOR;
        l_count    NUMBER := 0;
        l_rec      v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case(gc_test_receipt_3);
        
        l_receipts := uscis_types_pkg.t_receipt_tab(gc_test_receipt_1, gc_test_receipt_2);
        
        l_cursor := uscis_case_pkg.get_cases_by_receipts(l_receipts);
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(2);
    END test_get_cases_by_receipts;
    
    PROCEDURE test_get_cases_by_receipts_empty IS
        l_receipts uscis_types_pkg.t_receipt_tab := uscis_types_pkg.t_receipt_tab();
        l_cursor   SYS_REFCURSOR;
        l_rec      v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        l_cursor := uscis_case_pkg.get_cases_by_receipts(l_receipts);
        FETCH l_cursor INTO l_rec;
        
        ut.expect(l_cursor%NOTFOUND).to_be_true();
        CLOSE l_cursor;
    END test_get_cases_by_receipts_empty;
    
    PROCEDURE test_get_cases_by_receipts_null IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        l_cursor := uscis_case_pkg.get_cases_by_receipts(NULL);
        FETCH l_cursor INTO l_rec;
        
        ut.expect(l_cursor%NOTFOUND).to_be_true();
        CLOSE l_cursor;
    END test_get_cases_by_receipts_null;
    
    -- --------------------------------------------------------
    -- update_case_notes Tests (2.2.9)
    -- --------------------------------------------------------
    
    PROCEDURE test_update_notes_success IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        uscis_case_pkg.update_case_notes(gc_test_receipt_1, 'Updated notes');
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.notes).to_equal('Updated notes');
    END test_update_notes_success;
    
    PROCEDURE test_update_notes_not_found IS
    BEGIN
        uscis_case_pkg.update_case_notes('TST9999999999', 'Notes');
    END test_update_notes_not_found;
    
    PROCEDURE test_update_notes_null IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
        l_dummy  VARCHAR2(13);
    BEGIN
        l_dummy := uscis_case_pkg.add_case(
            p_receipt_number => gc_test_receipt_1,
            p_notes          => 'Initial notes'
        );
        
        uscis_case_pkg.update_case_notes(gc_test_receipt_1, NULL);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.notes).to_be_null();
    END test_update_notes_null;
    
    -- --------------------------------------------------------
    -- set_case_active Tests (2.2.10)
    -- --------------------------------------------------------
    
    PROCEDURE test_set_case_inactive IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        uscis_case_pkg.set_case_active(gc_test_receipt_1, FALSE);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.is_active).to_equal(0);
    END test_set_case_inactive;
    
    PROCEDURE test_set_case_active IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        uscis_case_pkg.set_case_active(gc_test_receipt_1, FALSE);
        uscis_case_pkg.set_case_active(gc_test_receipt_1, TRUE);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.is_active).to_equal(1);
    END test_set_case_active;
    
    PROCEDURE test_set_active_not_found IS
    BEGIN
        uscis_case_pkg.set_case_active('TST9999999999', TRUE);
    END test_set_active_not_found;
    
    -- --------------------------------------------------------
    -- Additional Function Tests
    -- --------------------------------------------------------
    
    PROCEDURE test_get_status_history IS
        l_cursor SYS_REFCURSOR;
        l_count  NUMBER := 0;
        l_rec    v_status_history%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Status 1');
        
        uscis_case_pkg.add_or_update_case(
            gc_test_receipt_1, 'I-485', 'Status 2'
        );
        uscis_case_pkg.add_or_update_case(
            gc_test_receipt_1, 'I-485', 'Status 3'
        );
        
        l_cursor := uscis_case_pkg.get_status_history(gc_test_receipt_1);
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_count).to_equal(3);
    END test_get_status_history;
    
    PROCEDURE test_get_latest_status IS
        l_status uscis_types_pkg.t_case_status;
    BEGIN
        create_test_case(gc_test_receipt_1, 'Old Status');
        
        uscis_case_pkg.add_or_update_case(
            gc_test_receipt_1, 'I-485', 'Latest Status'
        );
        
        l_status := uscis_case_pkg.get_latest_status(gc_test_receipt_1);
        
        ut.expect(l_status.current_status).to_equal('Latest Status');
    END test_get_latest_status;
    
    PROCEDURE test_count_status_updates IS
        l_count NUMBER;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        uscis_case_pkg.add_or_update_case(
            gc_test_receipt_1, 'I-485', 'Status 2'
        );
        
        l_count := uscis_case_pkg.count_status_updates(gc_test_receipt_1);
        ut.expect(l_count).to_equal(2);
    END test_count_status_updates;
    
    PROCEDURE test_update_last_checked IS
        l_cursor      SYS_REFCURSOR;
        l_rec         v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        uscis_case_pkg.update_last_checked(gc_test_receipt_1);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.last_checked_at).not_to_be_null();
    END test_update_last_checked;
    
    PROCEDURE test_set_check_frequency IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_case_current_status%ROWTYPE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        uscis_case_pkg.set_check_frequency(gc_test_receipt_1, 48);
        
        l_cursor := uscis_case_pkg.get_case(gc_test_receipt_1, FALSE);
        FETCH l_cursor INTO l_rec;
        CLOSE l_cursor;
        
        ut.expect(l_rec.check_frequency).to_equal(48);
    END test_set_check_frequency;
    
    PROCEDURE test_set_check_frequency_invalid IS
    BEGIN
        create_test_case(gc_test_receipt_1);
        -- 800 hours is out of range (max 720)
        uscis_case_pkg.set_check_frequency(gc_test_receipt_1, 800);
    END test_set_check_frequency_invalid;
    
    PROCEDURE test_delete_cases_bulk IS
        l_receipts uscis_types_pkg.t_receipt_tab;
    BEGIN
        create_test_case(gc_test_receipt_1);
        create_test_case(gc_test_receipt_2);
        create_test_case(gc_test_receipt_3);
        
        l_receipts := uscis_types_pkg.t_receipt_tab(gc_test_receipt_1, gc_test_receipt_2);
        
        uscis_case_pkg.delete_cases(l_receipts);
        
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_false();
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_2)).to_be_false();
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_3)).to_be_true();
    END test_delete_cases_bulk;
    
    PROCEDURE test_purge_inactive_cases IS
        l_dummy VARCHAR2(13);
    BEGIN
        -- Create an old inactive case by manipulating created_at
        l_dummy := uscis_case_pkg.add_case(gc_test_receipt_1);
        uscis_case_pkg.set_case_active(gc_test_receipt_1, FALSE);
        
        -- Manually update created_at to make it old
        -- Note: Use NUMTODSINTERVAL for values > 99 days (INTERVAL literal default precision is 2 digits)
        UPDATE case_history
        SET created_at = SYSTIMESTAMP - NUMTODSINTERVAL(400, 'DAY')
        WHERE receipt_number = gc_test_receipt_1;
        
        -- Create a recent inactive case
        l_dummy := uscis_case_pkg.add_case(gc_test_receipt_2);
        uscis_case_pkg.set_case_active(gc_test_receipt_2, FALSE);
        
        -- Purge cases older than 365 days
        uscis_case_pkg.purge_inactive_cases(365);
        
        -- Old case should be deleted, recent should remain
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_1)).to_be_false();
        ut.expect(uscis_case_pkg.case_exists(gc_test_receipt_2)).to_be_true();
    END test_purge_inactive_cases;
    
    PROCEDURE test_get_cases_due_for_check IS
        l_cursor SYS_REFCURSOR;
        l_rec    v_cases_due_for_check%ROWTYPE;
        l_found  BOOLEAN := FALSE;
    BEGIN
        create_test_case(gc_test_receipt_1);
        
        -- Case with null last_checked_at should be due
        l_cursor := uscis_case_pkg.get_cases_due_for_check(10);
        
        LOOP
            FETCH l_cursor INTO l_rec;
            EXIT WHEN l_cursor%NOTFOUND;
            IF l_rec.receipt_number = gc_test_receipt_1 THEN
                l_found := TRUE;
            END IF;
        END LOOP;
        CLOSE l_cursor;
        
        ut.expect(l_found).to_be_true();
    END test_get_cases_due_for_check;

END ut_uscis_case_pkg;
/

SHOW ERRORS PACKAGE ut_uscis_case_pkg
SHOW ERRORS PACKAGE BODY ut_uscis_case_pkg

PROMPT ============================================================
PROMPT UT_USCIS_CASE_PKG test package created successfully
PROMPT ============================================================
PROMPT
PROMPT To run all tests:
PROMPT   exec ut.run('ut_uscis_case_pkg');
PROMPT
PROMPT To run a specific test:
PROMPT   exec ut.run('ut_uscis_case_pkg.test_add_case_valid');
PROMPT
PROMPT ============================================================
