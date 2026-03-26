-- ==========================================================
-- FILE: 8.1_security_roles_test.sql
-- Mục tiêu: Test Bước 8 (Phân quyền & Bảo mật) cho DigiBook
-- Hướng dẫn:
--   1) Chạy sau khi đã chạy 8_security_roles.sql
--   2) Chạy bằng user có quyền đọc dictionary view (thường là SYSTEM/SYS)
-- Oracle: SQL*Plus / SQLcl / SQL Developer
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 220;

PROMPT ==========================================
PROMPT STEP 8.1 - SECURITY ROLES TEST
PROMPT ==========================================

-- Có thể đổi thủ công nếu muốn kiểm thử theo schema cụ thể.
DEFINE APP_SCHEMA = 'AUTO';

VARIABLE v_owner VARCHAR2(128);
VARIABLE v_pass NUMBER;
VARIABLE v_fail NUMBER;
VARIABLE v_warn NUMBER;

BEGIN
    :v_pass := 0;
    :v_fail := 0;
    :v_warn := 0;
END;
/

PROMPT ==========================================
PROMPT TC00 - Xac dinh schema ung dung (APP_SCHEMA)
PROMPT ==========================================
DECLARE
    v_owner VARCHAR2(128) := UPPER('&&APP_SCHEMA');
    v_found VARCHAR2(128);
BEGIN
    IF v_owner = 'AUTO' THEN
        BEGIN
            SELECT owner
              INTO v_found
              FROM (
                    SELECT owner, COUNT(*) AS score
                      FROM ALL_OBJECTS
                     WHERE OBJECT_TYPE IN ('TABLE', 'VIEW', 'PROCEDURE')
                       AND OBJECT_NAME IN (
                           'CUSTOMERS', 'BOOKS', 'ORDERS',
                           'VW_ORDER_SALES_REPORT', 'SP_MANAGE_BOOK'
                       )
                     GROUP BY owner
                     ORDER BY score DESC
                   )
             WHERE ROWNUM = 1;

            :v_owner := v_found;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                :v_owner := USER;
        END;
    ELSE
        :v_owner := v_owner;
    END IF;

    DBMS_OUTPUT.PUT_LINE('TC00 INFO - APP_SCHEMA su dung = ' || :v_owner);
END;
/

PROMPT ==========================================
PROMPT TC01 - Kiem tra container hien tai
PROMPT ==========================================
DECLARE
    v_con_name VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CON_NAME');
BEGIN
    IF v_con_name = 'CDB$ROOT' THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC01 FAIL - Dang o CDB$ROOT, can chay o PDB');
    ELSE
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC01 PASS - Dang o container ' || v_con_name);
    END IF;
END;
/

PROMPT ==========================================
PROMPT TC02 - Kiem tra ton tai 3 ROLE
PROMPT ==========================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM dba_roles
     WHERE role IN ('ADMIN_ROLE', 'STAFF_ROLE', 'GUEST_ROLE');

    IF v_cnt = 3 THEN
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC02 PASS - Da tim thay du 3 role');
    ELSE
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC02 FAIL - So role tim thay = ' || v_cnt || ' (mong doi = 3)');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC02 FAIL - Khong doc duoc DBA_ROLES: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC03 - Kiem tra ton tai 3 USER
PROMPT ==========================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM dba_users
     WHERE username IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST');

    IF v_cnt = 3 THEN
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC03 PASS - Da tim thay du 3 user');
    ELSE
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC03 FAIL - So user tim thay = ' || v_cnt || ' (mong doi = 3)');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC03 FAIL - Khong doc duoc DBA_USERS: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC04 - Kiem tra user da duoc gan role dung
PROMPT ==========================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM dba_role_privs
     WHERE (grantee = 'DIGIBOOK_ADMIN' AND granted_role = 'ADMIN_ROLE')
        OR (grantee = 'DIGIBOOK_STAFF' AND granted_role = 'STAFF_ROLE')
        OR (grantee = 'DIGIBOOK_GUEST' AND granted_role = 'GUEST_ROLE');

    IF v_cnt = 3 THEN
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC04 PASS - Da gan role dung cho 3 user');
    ELSE
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - So role grant dung = ' || v_cnt || ' (mong doi = 3)');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - Khong doc duoc DBA_ROLE_PRIVS: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC05 - Kiem tra CREATE SESSION tren 3 role
PROMPT ==========================================
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM dba_sys_privs
     WHERE grantee IN ('ADMIN_ROLE', 'STAFF_ROLE', 'GUEST_ROLE')
       AND privilege = 'CREATE SESSION';

    IF v_cnt = 3 THEN
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC05 PASS - Ca 3 role deu co CREATE SESSION');
    ELSE
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC05 FAIL - So role co CREATE SESSION = ' || v_cnt || ' (mong doi = 3)');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC05 FAIL - Khong doc duoc DBA_SYS_PRIVS: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC06 - Kiem tra grant SELECT tren cac object public cho GUEST_ROLE
PROMPT ==========================================
DECLARE
    v_missing NUMBER := 0;
    v_owner_local VARCHAR2(128) := :v_owner;

    PROCEDURE check_select(p_obj IN VARCHAR2) AS
        v_exist  NUMBER;
        v_grant  NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_exist
          FROM all_objects
                 WHERE owner = v_owner_local
           AND object_name = UPPER(p_obj)
           AND object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

        IF v_exist = 0 THEN
            :v_warn := :v_warn + 1;
                        DBMS_OUTPUT.PUT_LINE('TC06 WARN - Object khong ton tai: ' || v_owner_local || '.' || UPPER(p_obj));
            RETURN;
        END IF;

        SELECT COUNT(*)
          INTO v_grant
          FROM dba_tab_privs
                 WHERE owner = v_owner_local
           AND table_name = UPPER(p_obj)
           AND grantee = 'GUEST_ROLE'
           AND privilege = 'SELECT';

        IF v_grant = 1 THEN
            DBMS_OUTPUT.PUT_LINE('TC06 PASS - GUEST_ROLE co SELECT tren ' || p_obj);
        ELSE
            v_missing := v_missing + 1;
            DBMS_OUTPUT.PUT_LINE('TC06 FAIL - GUEST_ROLE thieu SELECT tren ' || p_obj);
        END IF;
    END;
BEGIN
    check_select('CATEGORIES');
    check_select('AUTHORS');
    check_select('PUBLISHERS');
    check_select('BOOKS');
    check_select('BOOK_IMAGES');
    check_select('VW_CUSTOMER_SECURE_PROFILE');

    IF v_missing = 0 THEN
        :v_pass := :v_pass + 1;
    ELSE
        :v_fail := :v_fail + 1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC06 FAIL - Loi khi kiem tra guest grants: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC07 - Kiem tra EXECUTE procedure cho ADMIN_ROLE va STAFF_ROLE
PROMPT ==========================================
DECLARE
    v_missing NUMBER := 0;
    v_owner_local VARCHAR2(128) := :v_owner;

    PROCEDURE check_exec(p_role IN VARCHAR2, p_proc IN VARCHAR2) AS
        v_exist  NUMBER;
        v_grant  NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_exist
          FROM all_objects
                 WHERE owner = v_owner_local
           AND object_name = UPPER(p_proc)
           AND object_type = 'PROCEDURE';

        IF v_exist = 0 THEN
            :v_warn := :v_warn + 1;
                        DBMS_OUTPUT.PUT_LINE('TC07 WARN - Procedure khong ton tai: ' || v_owner_local || '.' || UPPER(p_proc));
            RETURN;
        END IF;

        SELECT COUNT(*)
          INTO v_grant
          FROM dba_tab_privs
                 WHERE owner = v_owner_local
           AND table_name = UPPER(p_proc)
           AND grantee = UPPER(p_role)
           AND privilege = 'EXECUTE';

        IF v_grant = 1 THEN
            DBMS_OUTPUT.PUT_LINE('TC07 PASS - ' || p_role || ' co EXECUTE tren ' || p_proc);
        ELSE
            v_missing := v_missing + 1;
            DBMS_OUTPUT.PUT_LINE('TC07 FAIL - ' || p_role || ' thieu EXECUTE tren ' || p_proc);
        END IF;
    END;
BEGIN
    check_exec('ADMIN_ROLE', 'SP_MANAGE_BOOK');
    check_exec('ADMIN_ROLE', 'SP_REPORT_MONTHLY_SALES');
    check_exec('ADMIN_ROLE', 'SP_PRINT_LOW_STOCK_BOOKS');
    check_exec('ADMIN_ROLE', 'SP_CALCULATE_COUPON_DISCOUNT');

    check_exec('STAFF_ROLE', 'SP_MANAGE_BOOK');
    check_exec('STAFF_ROLE', 'SP_REPORT_MONTHLY_SALES');
    check_exec('STAFF_ROLE', 'SP_PRINT_LOW_STOCK_BOOKS');
    check_exec('STAFF_ROLE', 'SP_CALCULATE_COUPON_DISCOUNT');

    IF v_missing = 0 THEN
        :v_pass := :v_pass + 1;
    ELSE
        :v_fail := :v_fail + 1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC07 FAIL - Loi khi kiem tra execute grants: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC08 - Kiem tra GUEST_ROLE KHONG co EXECUTE tren procedure
PROMPT ==========================================
DECLARE
    v_cnt NUMBER;
    v_owner_local VARCHAR2(128) := :v_owner;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM dba_tab_privs
     WHERE owner = v_owner_local
       AND table_name IN (
           'SP_MANAGE_BOOK',
           'SP_REPORT_MONTHLY_SALES',
           'SP_PRINT_LOW_STOCK_BOOKS',
           'SP_CALCULATE_COUPON_DISCOUNT'
       )
       AND grantee = 'GUEST_ROLE'
       AND privilege = 'EXECUTE';

    IF v_cnt = 0 THEN
        :v_pass := :v_pass + 1;
        DBMS_OUTPUT.PUT_LINE('TC08 PASS - GUEST_ROLE khong co EXECUTE tren procedures nghiep vu');
    ELSE
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC08 FAIL - GUEST_ROLE dang co ' || v_cnt || ' quyen EXECUTE khong mong muon');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :v_fail := :v_fail + 1;
        DBMS_OUTPUT.PUT_LINE('TC08 FAIL - Loi khi kiem tra execute cua guest: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TONG KET KET QUA TEST BUOC 8
PROMPT ==========================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('SO LUONG PASS = ' || :v_pass);
    DBMS_OUTPUT.PUT_LINE('SO LUONG FAIL = ' || :v_fail);
    DBMS_OUTPUT.PUT_LINE('SO LUONG WARN = ' || :v_warn);

    IF :v_fail = 0 THEN
        DBMS_OUTPUT.PUT_LINE('KET LUAN: DAT - Khong co test case FAIL.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('KET LUAN: CHUA DAT - Can xu ly cac test case FAIL.');
    END IF;
END;
/

PRINT v_owner;
PRINT v_pass;
PRINT v_fail;
PRINT v_warn;

PROMPT ==========================================
PROMPT GOI Y DOI SOAT NHANH
PROMPT ==========================================
PROMPT SELECT * FROM dba_role_privs WHERE grantee IN ('DIGIBOOK_ADMIN','DIGIBOOK_STAFF','DIGIBOOK_GUEST');
PROMPT SELECT * FROM dba_tab_privs WHERE grantee IN ('ADMIN_ROLE','STAFF_ROLE','GUEST_ROLE') ORDER BY grantee, owner, table_name, privilege;
PROMPT SELECT * FROM dba_sys_privs WHERE grantee IN ('ADMIN_ROLE','STAFF_ROLE','GUEST_ROLE');
