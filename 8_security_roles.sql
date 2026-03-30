-- ==========================================================
-- FILE: 8_security_roles.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Tạo User/Role và phân quyền bảo mật
-- ==========================================================

SET SERVEROUTPUT ON;

-- ==========================================================
-- Cấu hình schema ứng dụng
-- Nếu để AUTO script sẽ tự dò owner từ các object chính
-- ==========================================================
DEFINE APP_SCHEMA = 'AUTO';

DECLARE
    v_owner  VARCHAR2(128) := UPPER('&&APP_SCHEMA');
    v_found  VARCHAR2(128);

    PROCEDURE exec_optional(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    PROCEDURE exec_required(p_sql IN VARCHAR2, p_step IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20800, p_step || ' that bai: ' || SQLERRM);
    END;

    PROCEDURE grant_object_priv(p_privs IN VARCHAR2, p_obj IN VARCHAR2, p_role IN VARCHAR2) IS
        v_cnt NUMBER;
        v_sql VARCHAR2(1000);
    BEGIN
        SELECT COUNT(*)
          INTO v_cnt
          FROM all_objects
         WHERE owner = v_owner
           AND object_name = UPPER(p_obj)
           AND object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW', 'PROCEDURE');

        IF v_cnt = 0 THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Khong tim thay object ' || v_owner || '.' || UPPER(p_obj) || ', bo qua.');
            RETURN;
        END IF;

        v_sql := 'GRANT ' || p_privs || ' ON ' || v_owner || '.' || UPPER(p_obj) || ' TO ' || UPPER(p_role);
        EXECUTE IMMEDIATE v_sql;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Grant loi (' || p_obj || ' -> ' || p_role || '): ' || SQLERRM);
    END;
BEGIN
    -- Auto detect owner nếu cần.
    IF v_owner = 'AUTO' THEN
        BEGIN
            SELECT owner
              INTO v_found
              FROM (
                    SELECT owner, COUNT(*) AS score
                      FROM all_objects
                     WHERE object_name IN (
                           'BOOKS', 'ORDERS', 'CUSTOMERS',
                           'VW_ORDER_SALES_REPORT', 'SP_MANAGE_BOOK'
                       )
                     GROUP BY owner
                     ORDER BY score DESC
                   )
             WHERE ROWNUM = 1;
            v_owner := v_found;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_owner := USER;
        END;
    END IF;

    DBMS_OUTPUT.PUT_LINE('INFO: APP_SCHEMA = ' || v_owner);

    -- Dọn role/user cũ để chạy lại thuận tiện.
    exec_optional('DROP USER DIGIBOOK_GUEST CASCADE');
    exec_optional('DROP USER DIGIBOOK_STAFF CASCADE');
    exec_optional('DROP USER DIGIBOOK_ADMIN CASCADE');
    exec_optional('DROP ROLE GUEST_ROLE');
    exec_optional('DROP ROLE STAFF_ROLE');
    exec_optional('DROP ROLE ADMIN_ROLE');

    -- Tạo role.
    exec_required('CREATE ROLE ADMIN_ROLE', 'CREATE ROLE ADMIN_ROLE');
    exec_required('CREATE ROLE STAFF_ROLE', 'CREATE ROLE STAFF_ROLE');
    exec_required('CREATE ROLE GUEST_ROLE', 'CREATE ROLE GUEST_ROLE');

    -- Quyền hệ thống cơ bản.
    exec_required('GRANT CREATE SESSION TO ADMIN_ROLE', 'GRANT CREATE SESSION ADMIN_ROLE');
    exec_required('GRANT CREATE SESSION TO STAFF_ROLE', 'GRANT CREATE SESSION STAFF_ROLE');
    exec_required('GRANT CREATE SESSION TO GUEST_ROLE', 'GRANT CREATE SESSION GUEST_ROLE');

    -- ADMIN_ROLE: toàn quyền DML trên bảng lõi.
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BRANCHES', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'USERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'STAFF', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOKS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CUSTOMERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDER_DETAILS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BRANCH_INVENTORY', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'INVENTORY_TRANSACTIONS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'COUPONS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'PAYMENT_TRANSACTIONS', 'ADMIN_ROLE');

    -- STAFF_ROLE: quyền tác nghiệp.
    grant_object_priv('SELECT', 'BRANCHES', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'BOOKS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'CUSTOMERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDER_DETAILS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'ORDER_STATUS_HISTORY', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'BRANCH_INVENTORY', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'INVENTORY_TRANSACTIONS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'PAYMENT_TRANSACTIONS', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'COUPONS', 'STAFF_ROLE');

    -- GUEST_ROLE: chỉ đọc dữ liệu công khai.
    grant_object_priv('SELECT', 'BOOKS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'BOOK_IMAGES', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'CATEGORIES', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'AUTHORS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'PUBLISHERS', 'GUEST_ROLE');

    -- Quyền trên view/materialized view.
    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_BRANCH_SALES', 'ADMIN_ROLE');

    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_BRANCH_SALES', 'STAFF_ROLE');

    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'GUEST_ROLE');

    -- Quyền EXECUTE trên stored procedure.
    grant_object_priv('EXECUTE', 'SP_MANAGE_BOOK', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_INVENTORY', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'ADMIN_ROLE');

    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_INVENTORY', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'STAFF_ROLE');

    -- Tạo user.
    exec_required('CREATE USER DIGIBOOK_ADMIN IDENTIFIED BY "DigiBook#Admin2026"', 'CREATE USER ADMIN');
    exec_required('CREATE USER DIGIBOOK_STAFF IDENTIFIED BY "DigiBook#Staff2026"', 'CREATE USER STAFF');
    exec_required('CREATE USER DIGIBOOK_GUEST IDENTIFIED BY "DigiBook#Guest2026"', 'CREATE USER GUEST');

    -- Gán role.
    exec_required('GRANT ADMIN_ROLE TO DIGIBOOK_ADMIN', 'GRANT ADMIN_ROLE');
    exec_required('GRANT STAFF_ROLE TO DIGIBOOK_STAFF', 'GRANT STAFF_ROLE');
    exec_required('GRANT GUEST_ROLE TO DIGIBOOK_GUEST', 'GRANT GUEST_ROLE');

    exec_required('ALTER USER DIGIBOOK_ADMIN DEFAULT ROLE ALL', 'ALTER USER ADMIN DEFAULT ROLE');
    exec_required('ALTER USER DIGIBOOK_STAFF DEFAULT ROLE ALL', 'ALTER USER STAFF DEFAULT ROLE');
    exec_required('ALTER USER DIGIBOOK_GUEST DEFAULT ROLE ALL', 'ALTER USER GUEST DEFAULT ROLE');

    DBMS_OUTPUT.PUT_LINE('INFO: Hoan tat buoc 8.');
END;
/

