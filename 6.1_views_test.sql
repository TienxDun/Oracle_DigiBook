-- ==========================================================
-- FILE: 6.1_views_test.sql
-- Mục tiêu: Test case cho 3 view ở Bước 6 của DigiBook
-- Hướng dẫn: Chạy file này sau khi đã chạy 6_views.sql
-- Oracle: SQL*Plus / SQLcl / SQL Developer
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;

PROMPT ==========================================
PROMPT THIET LAP MOI TRUONG TEST VIEW
PROMPT ==========================================

VARIABLE v_report_rows NUMBER;
VARIABLE v_secure_rows NUMBER;
VARIABLE v_mview_exists NUMBER;
VARIABLE v_mv_rows NUMBER;
VARIABLE v_customer_id NUMBER;

BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE('VIEW_TEST', 'STEP6');
    DBMS_SESSION.SET_IDENTIFIER('VIEW_TC_STEP6');
END;
/

PROMPT ==========================================
PROMPT TC01 - Kiem tra object VIEW da duoc tao
PROMPT ==========================================
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM user_objects
     WHERE object_name = 'VW_ORDER_SALES_REPORT'
       AND object_type = 'VIEW';

    IF v_count = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC01.1 PASS - VW_ORDER_SALES_REPORT ton tai');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC01.1 FAIL - Chua tim thay VW_ORDER_SALES_REPORT');
    END IF;

    SELECT COUNT(*)
      INTO v_count
      FROM user_objects
     WHERE object_name = 'VW_CUSTOMER_SECURE_PROFILE'
       AND object_type = 'VIEW';

    IF v_count = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC01.2 PASS - VW_CUSTOMER_SECURE_PROFILE ton tai');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC01.2 FAIL - Chua tim thay VW_CUSTOMER_SECURE_PROFILE');
    END IF;

    SELECT COUNT(*)
      INTO :v_mview_exists
      FROM user_objects
     WHERE object_name = 'MV_DAILY_CATEGORY_SALES'
       AND object_type = 'MATERIALIZED VIEW';

    IF :v_mview_exists = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC01.3 PASS - MV_DAILY_CATEGORY_SALES ton tai');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC01.3 SKIP - MV_DAILY_CATEGORY_SALES chua duoc tao, thuong do thieu quyen CREATE MATERIALIZED VIEW');
    END IF;
END;
/

PROMPT ==========================================
PROMPT TC02 - Truy van VIEW bao cao ban hang
PROMPT ==========================================
BEGIN
    SELECT COUNT(*)
      INTO :v_report_rows
      FROM vw_order_sales_report;

    IF :v_report_rows > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC02 PASS - VW_ORDER_SALES_REPORT tra ve ' || :v_report_rows || ' dong');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC02 FAIL - VW_ORDER_SALES_REPORT khong co du lieu');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC02 FAIL - ' || SQLERRM);
END;
/

SELECT *
FROM vw_order_sales_report
FETCH FIRST 5 ROWS ONLY;

PROMPT ==========================================
PROMPT TC03 - Kiem tra logic du lieu trong VIEW bao cao
PROMPT ==========================================
DECLARE
    v_invalid_rows NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_invalid_rows
      FROM vw_order_sales_report
     WHERE customer_name IS NULL
        OR book_title IS NULL
        OR line_subtotal <= 0
        OR line_weight_percent < 0
        OR line_weight_percent > 100;

    IF v_invalid_rows = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC03 PASS - Du lieu JOIN va ti le dong hop le');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC03 FAIL - Co ' || v_invalid_rows || ' dong bat thuong trong VW_ORDER_SALES_REPORT');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC03 FAIL - ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC04 - Truy van VIEW che du lieu nhay cam
PROMPT ==========================================
BEGIN
    SELECT MIN(customer_id), COUNT(*)
      INTO :v_customer_id, :v_secure_rows
      FROM vw_customer_secure_profile;

    IF :v_secure_rows > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC04 PASS - VW_CUSTOMER_SECURE_PROFILE tra ve ' || :v_secure_rows || ' dong');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - VW_CUSTOMER_SECURE_PROFILE khong co du lieu');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - ' || SQLERRM);
END;
/

SELECT *
FROM vw_customer_secure_profile
FETCH FIRST 5 ROWS ONLY;

PROMPT ==========================================
PROMPT TC05 - Kiem tra email, phone, address da duoc mask
PROMPT ==========================================
DECLARE
    v_raw_email        customers.email%TYPE;
    v_raw_phone        customers.phone%TYPE;
    v_raw_address      customers.address%TYPE;
    v_masked_email     VARCHAR2(150);
    v_masked_phone     VARCHAR2(30);
    v_masked_address   NVARCHAR2(500);
BEGIN
    SELECT email, phone, address
      INTO v_raw_email, v_raw_phone, v_raw_address
      FROM customers
     WHERE customer_id = :v_customer_id;

    SELECT masked_email, masked_phone, masked_address
      INTO v_masked_email, v_masked_phone, v_masked_address
      FROM vw_customer_secure_profile
     WHERE customer_id = :v_customer_id;

    IF v_masked_email = v_raw_email THEN
        DBMS_OUTPUT.PUT_LINE('TC05.1 FAIL - Email chua duoc mask');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC05.1 PASS - Email da duoc mask');
    END IF;

    IF v_raw_phone IS NOT NULL AND v_masked_phone = v_raw_phone THEN
        DBMS_OUTPUT.PUT_LINE('TC05.2 FAIL - So dien thoai chua duoc mask');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC05.2 PASS - So dien thoai da duoc mask');
    END IF;

    IF v_raw_address IS NOT NULL AND v_masked_address = v_raw_address THEN
        DBMS_OUTPUT.PUT_LINE('TC05.3 FAIL - Dia chi chua duoc mask');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC05.3 PASS - Dia chi da duoc mask');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC05 FAIL - ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC06 - Thu DML tren VIEW read only (expected fail)
PROMPT ==========================================
BEGIN
    UPDATE vw_customer_secure_profile
       SET full_name = full_name
     WHERE customer_id = :v_customer_id;

    DBMS_OUTPUT.PUT_LINE('TC06 FAIL - VIEW read only khong chan UPDATE');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC06 PASS - Nhan duoc loi ky vong: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC07 - Kiem tra MATERIALIZED VIEW neu object ton tai
PROMPT ==========================================
DECLARE
    v_invalid_rows NUMBER;
BEGIN
    IF :v_mview_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC07 SKIP - Bo qua vi MV_DAILY_CATEGORY_SALES chua ton tai');
        RETURN;
    END IF;

    SELECT COUNT(*)
      INTO :v_mv_rows
      FROM mv_daily_category_sales;

    DBMS_OUTPUT.PUT_LINE('TC07.1 PASS - Materialized view tra ve ' || :v_mv_rows || ' dong');

    SELECT COUNT(*)
      INTO v_invalid_rows
      FROM mv_daily_category_sales
     WHERE total_orders <= 0
        OR total_units_sold <= 0
        OR gross_merchandise_value <= 0;

    IF v_invalid_rows = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC07.2 PASS - So lieu tong hop hop le');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC07.2 FAIL - Co ' || v_invalid_rows || ' dong tong hop bat thuong');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC07 FAIL - ' || SQLERRM);
END;
/

PROMPT Bo qua truy van preview MV bang lenh SELECT truc tiep neu object chua ton tai.
PROMPT Neu TC07 PASS, co the chay tay: SELECT * FROM mv_daily_category_sales ORDER BY sale_date, category_id FETCH FIRST 10 ROWS ONLY;

PROMPT ==========================================
PROMPT TC08 - Thu refresh MATERIALIZED VIEW neu object ton tai
PROMPT ==========================================
BEGIN
    IF :v_mview_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC08 SKIP - Khong refresh vi MV_DAILY_CATEGORY_SALES chua ton tai');
        RETURN;
    END IF;

    DBMS_MVIEW.REFRESH('MV_DAILY_CATEGORY_SALES', 'C');
    DBMS_OUTPUT.PUT_LINE('TC08 PASS - Refresh MV_DAILY_CATEGORY_SALES thanh cong');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC08 FAIL - ' || SQLERRM);
END;
/

PRINT v_report_rows;
PRINT v_secure_rows;
PRINT v_mview_exists;
PRINT v_mv_rows;
PRINT v_customer_id;

PROMPT ==========================================
PROMPT GOI Y KET THUC PHIEN TEST
PROMPT ==========================================
PROMPT Neu TC07 va TC08 bi SKIP thi can cap quyen CREATE MATERIALIZED VIEW roi chay lai 6_views.sql.
PROMPT Neu cac view thuong da tao duoc thi co the demo truoc bang VW_ORDER_SALES_REPORT va VW_CUSTOMER_SECURE_PROFILE.
