-- ==========================================================
-- FILE: 8_security_roles.sql
-- Mục tiêu: Tạo User/Role và phân quyền truy cập dữ liệu DigiBook
-- Hệ quản trị: Oracle 19c
-- ==========================================================

SET SERVEROUTPUT ON;

-- ==========================================================
-- TỰ ĐỘNG CHUYỂN CONTAINER VỀ PDB MỤC TIÊU
-- Ưu tiên ORCLPDB, nếu không có thì thử ORCLPDB1.
-- Lưu ý: Cần quyền ALTER SESSION SET CONTAINER.
-- ==========================================================
DECLARE
    v_con_name VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CON_NAME');
BEGIN
    IF v_con_name = 'CDB$ROOT' THEN
        BEGIN
            EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ORCLPDB';
            DBMS_OUTPUT.PUT_LINE('INFO: Da chuyen container sang ORCLPDB.');
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ORCLPDB1';
                    DBMS_OUTPUT.PUT_LINE('INFO: Da chuyen container sang ORCLPDB1.');
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(
                            -20081,
                            'Khong the tu dong chuyen sang ORCLPDB/ORCLPDB1. Hay ket noi truc tiep vao PDB roi chay lai script. Loi goc: ' || SQLERRM
                        );
                END;
        END;
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: Dang o container ' || v_con_name || ', bo qua buoc chuyen PDB.');
    END IF;
END;
/

-- ==========================================================
-- CẤU HÌNH CHẠY SCRIPT
-- APP_SCHEMA: Schema chứa bảng/view/procedure của DigiBook.
-- Ví dụ: DIGIBOOK, SYSTEM, hoặc tên schema bạn đã chạy 2_create_tables.sql.
-- Giá trị AUTO sẽ tự dò schema chứa bộ object chính của DigiBook.
-- ==========================================================
DEFINE APP_SCHEMA = 'AUTO';

-- ==========================================================
-- [Dũng/Nam/Hiếu/Phát] THỰC THI TOÀN BỘ BƯỚC PHÂN QUYỀN
-- Thiết kế 1 block để tránh lỗi dây chuyền khi môi trường sai container/schema.
-- ==========================================================
DECLARE
    v_con_name   VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CON_NAME');
    v_owner      VARCHAR2(128) := UPPER('&&APP_SCHEMA');
    v_found      VARCHAR2(128);

    PROCEDURE exec_optional(p_sql IN VARCHAR2) AS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    PROCEDURE exec_required(p_sql IN VARCHAR2, p_step IN VARCHAR2) AS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20100, p_step || ' that bai: ' || SQLERRM);
    END;

    PROCEDURE grant_object_priv(
        p_privs    IN VARCHAR2,
        p_obj_name IN VARCHAR2,
        p_role     IN VARCHAR2
    )
    AS
        v_cnt NUMBER;
        v_sql VARCHAR2(1200);
    BEGIN
        SELECT COUNT(*)
          INTO v_cnt
          FROM ALL_OBJECTS
         WHERE OWNER = v_owner
           AND OBJECT_NAME = UPPER(p_obj_name)
           AND OBJECT_TYPE IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW', 'PROCEDURE', 'FUNCTION', 'PACKAGE');

        IF v_cnt = 0 THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Khong tim thay object ' || v_owner || '.' || UPPER(p_obj_name) || ' - bo qua GRANT.');
            RETURN;
        END IF;

        v_sql := 'GRANT ' || p_privs || ' ON ' || v_owner || '.' || UPPER(p_obj_name) || ' TO ' || UPPER(p_role);
        EXECUTE IMMEDIATE v_sql;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Loi cap quyen ' || p_privs || ' tren ' || v_owner || '.' || UPPER(p_obj_name) || ' -> ' || UPPER(p_role) || ': ' || SQLERRM);
    END;
BEGIN
    -- Chỉ chạy tại PDB. Nếu đang ở CDB$ROOT thì thông báo và dừng an toàn.
    IF v_con_name = 'CDB$ROOT' THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Dang o CDB$ROOT. Hay ket noi vao PDB (vi du ORCLPDB1) va chay lai script.');
        RETURN;
    END IF;

    -- Auto-detect schema nếu APP_SCHEMA='AUTO'.
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

            v_owner := v_found;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_owner := USER;
        END;
    END IF;

    DBMS_OUTPUT.PUT_LINE('INFO: Current container = ' || v_con_name);
    DBMS_OUTPUT.PUT_LINE('INFO: APP_SCHEMA duoc su dung = ' || v_owner);

    -- Dọn dẹp cũ
    exec_optional('DROP USER DIGIBOOK_GUEST CASCADE');
    exec_optional('DROP USER DIGIBOOK_STAFF CASCADE');
    exec_optional('DROP USER DIGIBOOK_ADMIN CASCADE');
    exec_optional('DROP ROLE GUEST_ROLE');
    exec_optional('DROP ROLE STAFF_ROLE');
    exec_optional('DROP ROLE ADMIN_ROLE');

    -- Tạo role + quyền hệ thống cơ bản
    exec_required('CREATE ROLE ADMIN_ROLE', 'CREATE ROLE ADMIN_ROLE');
    exec_required('CREATE ROLE STAFF_ROLE', 'CREATE ROLE STAFF_ROLE');
    exec_required('CREATE ROLE GUEST_ROLE', 'CREATE ROLE GUEST_ROLE');

    exec_required('GRANT CREATE SESSION TO ADMIN_ROLE', 'GRANT CREATE SESSION TO ADMIN_ROLE');
    exec_required('GRANT CREATE SESSION TO STAFF_ROLE', 'GRANT CREATE SESSION TO STAFF_ROLE');
    exec_required('GRANT CREATE SESSION TO GUEST_ROLE', 'GRANT CREATE SESSION TO GUEST_ROLE');

    -- ADMIN: Toan quyen DML tren toan bo bang
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CUSTOMERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CATEGORIES', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CARTS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CART_ITEMS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'AUTHORS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'PUBLISHERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'COUPONS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOKS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOK_IMAGES', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOK_AUTHORS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDER_DETAILS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDER_STATUS_HISTORY', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'REVIEWS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'INVENTORY_TRANSACTIONS', 'ADMIN_ROLE');

    -- STAFF: Quyen tac nghiep hang ngay
    grant_object_priv('SELECT', 'CUSTOMERS', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'CATEGORIES', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'AUTHORS', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'PUBLISHERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'BOOKS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'BOOK_IMAGES', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOK_AUTHORS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'COUPONS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'CARTS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CART_ITEMS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDER_DETAILS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'ORDER_STATUS_HISTORY', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'REVIEWS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'INVENTORY_TRANSACTIONS', 'STAFF_ROLE');

    -- GUEST: Chi duoc xem du lieu cong khai
    grant_object_priv('SELECT', 'CATEGORIES', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'AUTHORS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'PUBLISHERS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'BOOKS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'BOOK_IMAGES', 'GUEST_ROLE');

    -- Quyen tren VIEW/MVIEW
    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_CATEGORY_SALES', 'ADMIN_ROLE');

    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_CATEGORY_SALES', 'STAFF_ROLE');

    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'GUEST_ROLE');

    -- Quyen EXECUTE tren Stored Procedures
    grant_object_priv('EXECUTE', 'SP_MANAGE_BOOK', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_BOOKS', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'ADMIN_ROLE');

    grant_object_priv('EXECUTE', 'SP_MANAGE_BOOK', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_BOOKS', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'STAFF_ROLE');

    -- Tạo user và gán role
    exec_required('CREATE USER DIGIBOOK_ADMIN IDENTIFIED BY "DigiBook#Admin2026"', 'CREATE USER DIGIBOOK_ADMIN');
    exec_required('CREATE USER DIGIBOOK_STAFF IDENTIFIED BY "DigiBook#Staff2026"', 'CREATE USER DIGIBOOK_STAFF');
    exec_required('CREATE USER DIGIBOOK_GUEST IDENTIFIED BY "DigiBook#Guest2026"', 'CREATE USER DIGIBOOK_GUEST');

    exec_required('GRANT ADMIN_ROLE TO DIGIBOOK_ADMIN', 'GRANT ADMIN_ROLE TO DIGIBOOK_ADMIN');
    exec_required('GRANT STAFF_ROLE TO DIGIBOOK_STAFF', 'GRANT STAFF_ROLE TO DIGIBOOK_STAFF');
    exec_required('GRANT GUEST_ROLE TO DIGIBOOK_GUEST', 'GRANT GUEST_ROLE TO DIGIBOOK_GUEST');

    exec_required('ALTER USER DIGIBOOK_ADMIN DEFAULT ROLE ALL', 'ALTER USER DIGIBOOK_ADMIN DEFAULT ROLE ALL');
    exec_required('ALTER USER DIGIBOOK_STAFF DEFAULT ROLE ALL', 'ALTER USER DIGIBOOK_STAFF DEFAULT ROLE ALL');
    exec_required('ALTER USER DIGIBOOK_GUEST DEFAULT ROLE ALL', 'ALTER USER DIGIBOOK_GUEST DEFAULT ROLE ALL');

    DBMS_OUTPUT.PUT_LINE('INFO: Hoan tat phan quyen Bước 8 thanh cong.');
END;
/

-- ==========================================================
-- GOI Y KIEM TRA NHANH
-- ==========================================================
-- SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_container FROM dual;
-- SELECT * FROM dba_role_privs WHERE grantee IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST');
-- SELECT * FROM dba_tab_privs WHERE grantee IN ('ADMIN_ROLE', 'STAFF_ROLE', 'GUEST_ROLE');
-- SELECT * FROM dba_sys_privs WHERE grantee IN ('ADMIN_ROLE', 'STAFF_ROLE', 'GUEST_ROLE');
