-- ============================================================
-- utPLSQL Stub Package
-- Provides minimal ut.expect() functionality when utPLSQL is not installed
-- ============================================================
-- File: tests/ut_stub_pkg.sql
-- Purpose: Allow unit test packages to compile without full utPLSQL
-- 
-- This is a STUB implementation. For full testing capabilities,
-- install utPLSQL from: https://github.com/utPLSQL/utPLSQL
--
-- To install this stub:
--   @ut_stub_pkg.sql
--
-- ============================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Creating UT Stub Package (utPLSQL compatibility layer)...
PROMPT ============================================================

-- ============================================================
-- Expectation Object Type
-- Uses SQL Object Type with MEMBER FUNCTIONS that return SELF
-- to enable fluent chaining: ut.expect(x).to_equal(y)
-- ============================================================

CREATE OR REPLACE TYPE ut_expectation_result AS OBJECT (
    actual_value     VARCHAR2(32767),
    actual_type      VARCHAR2(100),
    actual_bool      NUMBER,
    actual_number    NUMBER,
    is_negated       NUMBER,
    
    -- Constructor
    CONSTRUCTOR FUNCTION ut_expectation_result(
        p_value IN VARCHAR2 DEFAULT NULL,
        p_type  IN VARCHAR2 DEFAULT 'VARCHAR2'
    ) RETURN SELF AS RESULT,
    
    -- Negation - returns self for chaining
    MEMBER FUNCTION not_ RETURN ut_expectation_result,
    
    -- Matchers - all return SELF to allow chaining in PL/SQL
    MEMBER FUNCTION to_equal(p_expected IN VARCHAR2) RETURN ut_expectation_result,
    MEMBER FUNCTION to_equal(p_expected IN NUMBER) RETURN ut_expectation_result,
    MEMBER FUNCTION to_be_true RETURN ut_expectation_result,
    MEMBER FUNCTION to_be_false RETURN ut_expectation_result,
    MEMBER FUNCTION to_be_null RETURN ut_expectation_result,
    MEMBER FUNCTION not_to_be_null RETURN ut_expectation_result,
    MEMBER FUNCTION to_be_greater_than(p_expected IN NUMBER) RETURN ut_expectation_result,
    MEMBER FUNCTION to_be_less_than(p_expected IN NUMBER) RETURN ut_expectation_result,
    MEMBER FUNCTION to_match(p_pattern IN VARCHAR2) RETURN ut_expectation_result
);
/

CREATE OR REPLACE TYPE BODY ut_expectation_result AS

    CONSTRUCTOR FUNCTION ut_expectation_result(
        p_value IN VARCHAR2 DEFAULT NULL,
        p_type  IN VARCHAR2 DEFAULT 'VARCHAR2'
    ) RETURN SELF AS RESULT IS
    BEGIN
        SELF.actual_value := p_value;
        SELF.actual_type := p_type;
        SELF.actual_bool := NULL;
        SELF.actual_number := NULL;
        SELF.is_negated := 0;
        RETURN;
    END;
    
    MEMBER FUNCTION not_ RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        l_result := ut_expectation_result(SELF.actual_value, SELF.actual_type);
        l_result.actual_bool := SELF.actual_bool;
        l_result.actual_number := SELF.actual_number;
        l_result.is_negated := 1;
        RETURN l_result;
    END;
    
    MEMBER FUNCTION to_equal(p_expected IN VARCHAR2) RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_value = p_expected) OR (SELF.actual_value IS NULL AND p_expected IS NULL);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            IF SELF.is_negated = 1 THEN
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: Expected NOT "' || p_expected || '" but got "' || SELF.actual_value || '"');
            ELSE
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: Expected "' || p_expected || '" but got "' || SELF.actual_value || '"');
            END IF;
        END IF;
        
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_equal(p_expected IN NUMBER) RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_number = p_expected) OR (SELF.actual_number IS NULL AND p_expected IS NULL);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            IF SELF.is_negated = 1 THEN
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: Expected NOT ' || p_expected || ' but got ' || SELF.actual_number);
            ELSE
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: Expected ' || p_expected || ' but got ' || SELF.actual_number);
            END IF;
        END IF;
        
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_be_true RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_bool IS NOT NULL AND SELF.actual_bool = 1);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            RAISE_APPLICATION_ERROR(-20900, 
                'Assertion failed: Expected ' || CASE WHEN SELF.is_negated = 1 THEN 'NOT TRUE' ELSE 'TRUE' END || 
                ' but got ' || CASE WHEN SELF.actual_bool = 1 THEN 'TRUE' WHEN SELF.actual_bool = 0 THEN 'FALSE' ELSE 'NULL' END);
        END IF;
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_be_false RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_bool IS NOT NULL AND SELF.actual_bool = 0);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            RAISE_APPLICATION_ERROR(-20900, 
                'Assertion failed: Expected ' || CASE WHEN SELF.is_negated = 1 THEN 'NOT FALSE' ELSE 'FALSE' END ||
                ' but got ' || CASE WHEN SELF.actual_bool = 1 THEN 'TRUE' WHEN SELF.actual_bool = 0 THEN 'FALSE' ELSE 'NULL' END);
        END IF;
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_be_null RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_value IS NULL AND SELF.actual_number IS NULL AND SELF.actual_bool IS NULL);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            RAISE_APPLICATION_ERROR(-20900, 
                'Assertion failed: Expected NULL but got "' || 
                NVL(SELF.actual_value, NVL(TO_CHAR(SELF.actual_number), TO_CHAR(SELF.actual_bool))) || '"');
        END IF;
        
        RETURN SELF;
    END;
    
    MEMBER FUNCTION not_to_be_null RETURN ut_expectation_result IS
        l_pass BOOLEAN;
        l_error_msg VARCHAR2(200);
    BEGIN
        l_pass := NOT (SELF.actual_value IS NULL AND SELF.actual_number IS NULL AND SELF.actual_bool IS NULL);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            -- Select appropriate error message based on negation state
            IF SELF.is_negated = 1 THEN
                l_error_msg := 'Assertion failed: Expected NULL but got NOT NULL';
            ELSE
                l_error_msg := 'Assertion failed: Expected NOT NULL but got NULL';
            END IF;
            RAISE_APPLICATION_ERROR(-20900, l_error_msg);
        END IF;
        
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_be_greater_than(p_expected IN NUMBER) RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_number IS NOT NULL AND SELF.actual_number > p_expected);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            RAISE_APPLICATION_ERROR(-20900, 
                'Assertion failed: Expected ' || CASE WHEN SELF.is_negated = 1 THEN 'NOT ' ELSE '' END ||
                '> ' || p_expected || ' but got ' || SELF.actual_number);
        END IF;
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_be_less_than(p_expected IN NUMBER) RETURN ut_expectation_result IS
        l_pass BOOLEAN;
    BEGIN
        l_pass := (SELF.actual_number IS NOT NULL AND SELF.actual_number < p_expected);
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            RAISE_APPLICATION_ERROR(-20900, 
                'Assertion failed: Expected ' || CASE WHEN SELF.is_negated = 1 THEN 'NOT ' ELSE '' END ||
                '< ' || p_expected || ' but got ' || SELF.actual_number);
        END IF;
        RETURN SELF;
    END;
    
    MEMBER FUNCTION to_match(p_pattern IN VARCHAR2) RETURN ut_expectation_result IS
        l_match BOOLEAN;
        l_pass  BOOLEAN;
    BEGIN
        l_match := (SELF.actual_value IS NOT NULL AND REGEXP_LIKE(SELF.actual_value, p_pattern));
        l_pass := l_match;
        
        IF SELF.is_negated = 1 THEN
            l_pass := NOT l_pass;
        END IF;
        
        IF NOT l_pass THEN
            IF SELF.is_negated = 1 THEN
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: "' || SELF.actual_value || '" should NOT match pattern "' || p_pattern || '"');
            ELSE
                RAISE_APPLICATION_ERROR(-20900, 
                    'Assertion failed: "' || SELF.actual_value || '" does not match pattern "' || p_pattern || '"');
            END IF;
        END IF;
        RETURN SELF;
    END;

END;
/

SHOW ERRORS TYPE ut_expectation_result
SHOW ERRORS TYPE BODY ut_expectation_result

-- ============================================================
-- UT Package Specification
-- ============================================================

CREATE OR REPLACE PACKAGE ut AS
    
    -- ========================================================
    -- Expectation Functions - return object for fluent assertions
    -- ========================================================
    
    -- Create expectation for VARCHAR2
    FUNCTION expect(p_actual IN VARCHAR2) RETURN ut_expectation_result;
    
    -- Create expectation for NUMBER
    FUNCTION expect(p_actual IN NUMBER) RETURN ut_expectation_result;
    
    -- Create expectation for BOOLEAN
    FUNCTION expect(p_actual IN BOOLEAN) RETURN ut_expectation_result;
    
    -- Create expectation for CLOB
    FUNCTION expect(p_actual IN CLOB) RETURN ut_expectation_result;
    
    -- Create expectation for TIMESTAMP
    FUNCTION expect(p_actual IN TIMESTAMP) RETURN ut_expectation_result;
    
    -- ========================================================
    -- Test Runner
    -- ========================================================
    
    -- Run all tests in a package
    PROCEDURE run(p_package_name IN VARCHAR2);
    
    -- Run a specific test
    PROCEDURE run(p_package_name IN VARCHAR2, p_test_name IN VARCHAR2);
    
    -- ========================================================
    -- Test Output
    -- ========================================================
    
    -- Report a test pass
    PROCEDURE pass(p_message IN VARCHAR2 DEFAULT NULL);
    
    -- Report a test failure
    PROCEDURE fail(p_message IN VARCHAR2);

END ut;
/

-- ============================================================
-- UT Package Body
-- ============================================================

CREATE OR REPLACE PACKAGE BODY ut AS

    -- --------------------------------------------------------
    -- Expectation Functions
    -- --------------------------------------------------------
    
    FUNCTION expect(p_actual IN VARCHAR2) RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        l_result := ut_expectation_result(p_actual, 'VARCHAR2');
        RETURN l_result;
    END expect;
    
    FUNCTION expect(p_actual IN NUMBER) RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        l_result := ut_expectation_result(TO_CHAR(p_actual), 'NUMBER');
        l_result.actual_number := p_actual;
        RETURN l_result;
    END expect;
    
    FUNCTION expect(p_actual IN BOOLEAN) RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        l_result := ut_expectation_result(
            CASE WHEN p_actual IS NULL THEN NULL
                 WHEN p_actual THEN 'TRUE' 
                 ELSE 'FALSE' 
            END,
            'BOOLEAN'
        );
        l_result.actual_bool := CASE WHEN p_actual IS NULL THEN NULL
                                     WHEN p_actual THEN 1 
                                     ELSE 0 
                                END;
        RETURN l_result;
    END expect;
    
    FUNCTION expect(p_actual IN CLOB) RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        IF p_actual IS NULL THEN
            l_result := ut_expectation_result(NULL, 'CLOB');
        ELSE
            l_result := ut_expectation_result(DBMS_LOB.SUBSTR(p_actual, 32767, 1), 'CLOB');
        END IF;
        RETURN l_result;
    END expect;
    
    FUNCTION expect(p_actual IN TIMESTAMP) RETURN ut_expectation_result IS
        l_result ut_expectation_result;
    BEGIN
        IF p_actual IS NULL THEN
            l_result := ut_expectation_result(NULL, 'TIMESTAMP');
        ELSE
            l_result := ut_expectation_result(TO_CHAR(p_actual, 'YYYY-MM-DD HH24:MI:SS.FF'), 'TIMESTAMP');
        END IF;
        RETURN l_result;
    END expect;
    
    -- --------------------------------------------------------
    -- Test Runner
    -- --------------------------------------------------------
    
    PROCEDURE run(p_package_name IN VARCHAR2) IS
        l_sql VARCHAR2(4000);
        l_proc_name VARCHAR2(128);
        l_passed NUMBER := 0;
        l_failed NUMBER := 0;
        l_start_time TIMESTAMP;
        l_end_time TIMESTAMP;
        l_safe_package_name VARCHAR2(128);
    BEGIN
        -- Validate package name to prevent SQL injection
        l_safe_package_name := DBMS_ASSERT.SQL_OBJECT_NAME(p_package_name);
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('============================================================');
        DBMS_OUTPUT.PUT_LINE('Running tests for: ' || UPPER(l_safe_package_name));
        DBMS_OUTPUT.PUT_LINE('============================================================');
        DBMS_OUTPUT.PUT_LINE('');
        
        l_start_time := SYSTIMESTAMP;
        
        -- Find all test procedures (those starting with 'TEST_')
        FOR rec IN (
            SELECT procedure_name
            FROM user_procedures
            WHERE object_name = UPPER(l_safe_package_name)
              AND procedure_name LIKE 'TEST_%'
            ORDER BY procedure_name
        ) LOOP
            BEGIN
                l_sql := 'BEGIN ' || l_safe_package_name || '.' || rec.procedure_name || '; END;';
                EXECUTE IMMEDIATE l_sql;
                
                l_passed := l_passed + 1;
                DBMS_OUTPUT.PUT_LINE('  [PASS] ' || rec.procedure_name);
                
            EXCEPTION
                WHEN OTHERS THEN
                    l_failed := l_failed + 1;
                    DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || rec.procedure_name);
                    DBMS_OUTPUT.PUT_LINE('         ' || SQLERRM);
            END;
        END LOOP;
        
        l_end_time := SYSTIMESTAMP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Results: ' || l_passed || ' passed, ' || l_failed || ' failed');
        DBMS_OUTPUT.PUT_LINE('Duration: ' || 
            EXTRACT(SECOND FROM (l_end_time - l_start_time)) || ' seconds');
        DBMS_OUTPUT.PUT_LINE('============================================================');
        
        IF l_failed > 0 THEN
            RAISE_APPLICATION_ERROR(-20901, l_failed || ' test(s) failed');
        END IF;
    END run;
    
    PROCEDURE run(p_package_name IN VARCHAR2, p_test_name IN VARCHAR2) IS
        l_sql  VARCHAR2(4000);
        l_pkg  VARCHAR2(128);
        l_test VARCHAR2(128);
    BEGIN
        -- Validate inputs to prevent SQL injection
        l_pkg  := DBMS_ASSERT.SQL_OBJECT_NAME(p_package_name);
        l_test := DBMS_ASSERT.SIMPLE_SQL_NAME(p_test_name);
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Running: ' || l_pkg || '.' || l_test);
        DBMS_OUTPUT.PUT_LINE('');
        
        l_sql := 'BEGIN ' || l_pkg || '.' || l_test || '; END;';
        EXECUTE IMMEDIATE l_sql;
        
        DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_test_name);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  [FAIL] ' || p_test_name);
            DBMS_OUTPUT.PUT_LINE('         ' || SQLERRM);
            RAISE;
    END run;
    
    -- --------------------------------------------------------
    -- Test Output
    -- --------------------------------------------------------
    
    PROCEDURE pass(p_message IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        IF p_message IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('  [PASS] ' || p_message);
        END IF;
    END pass;
    
    PROCEDURE fail(p_message IN VARCHAR2) IS
    BEGIN
        RAISE_APPLICATION_ERROR(-20900, 'Test failed: ' || p_message);
    END fail;

END ut;
/

SHOW ERRORS PACKAGE ut
SHOW ERRORS PACKAGE BODY ut

PROMPT ============================================================
PROMPT UT Stub Package created successfully
PROMPT ============================================================
PROMPT
PROMPT This is a minimal stub for utPLSQL compatibility.
PROMPT For full testing capabilities, install utPLSQL from:
PROMPT   https://github.com/utPLSQL/utPLSQL
PROMPT
PROMPT Usage:
PROMPT   -- Run all tests in a package:
PROMPT   exec ut.run('ut_uscis_case_pkg');
PROMPT
PROMPT   -- Run a specific test:
PROMPT   exec ut.run('ut_uscis_case_pkg', 'test_add_case_valid');
PROMPT
PROMPT ============================================================
