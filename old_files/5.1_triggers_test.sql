-- ==========================================================
-- FILE: 5.1_triggers_test.sql
-- Mục tiêu: Test case cho 3 trigger ở Bước 5 của DigiBook
-- Hướng dẫn: Chạy file này sau khi đã chạy 5_triggers.sql
-- Oracle: SQL*Plus / SQLcl / SQL Developer
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;

PROMPT ==========================================
PROMPT THIET LAP MOI TRUONG TEST
PROMPT ==========================================

VARIABLE v_test_order_id NUMBER;
VARIABLE v_test_detail_id NUMBER;
VARIABLE v_audit_count NUMBER;

BEGIN
    -- Gắn thông tin phiên làm việc để dễ lọc dữ liệu audit trong lúc test
    DBMS_APPLICATION_INFO.SET_MODULE('TRIGGER_TEST', 'STEP5');
    DBMS_SESSION.SET_IDENTIFIER('TRIGGER_TC_STEP5');
END;
/

PROMPT ==========================================
PROMPT TC01 - Validation shipping_address (expected fail)
PROMPT ==========================================
BEGIN
    INSERT INTO orders (
        order_id,
        customer_id,
        coupon_id,
        order_date,
        total_amount,
        status,
        shipping_address,
        payment_method,
        payment_status,
        shipping_fee,
        discount_amount,
        updated_at
    )
    VALUES (
        NULL,
        1,
        NULL,
        SYSDATE,
        0,
        'PENDING',
        N'Qua ngan',
        NULL,
        'PENDING',
        30000,
        0,
        NULL
    );

    DBMS_OUTPUT.PUT_LINE('TC01 FAIL - Trigger phai chan shipping_address qua ngan');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC01 PASS - Nhan duoc loi ky vong: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC02 - Validation DELIVERED nhung chua PAID (expected fail)
PROMPT ==========================================
BEGIN
    UPDATE orders
       SET status = 'DELIVERED',
           payment_status = 'PENDING',
           payment_method = 'COD'
     WHERE order_id = 7;

    DBMS_OUTPUT.PUT_LINE('TC02 FAIL - Trigger phai chan don DELIVERED chua PAID');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC02 PASS - Nhan duoc loi ky vong: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC03 - Tao don hang hop le de test recalc va audit
PROMPT ==========================================
BEGIN
    INSERT INTO orders (
        order_id,
        customer_id,
        coupon_id,
        order_date,
        total_amount,
        status,
        shipping_address,
        payment_method,
        payment_status,
        shipping_fee,
        discount_amount,
        updated_at
    )
    VALUES (
        NULL,
        1,
        NULL,
        SYSDATE,
        0,
        'PENDING',
        N'[TC Trigger] 123 Nguyen Van A, Quan 1, TP HCM',
        NULL,
        'PENDING',
        30000,
        10000,
        NULL
    )
    RETURNING order_id INTO :v_test_order_id;

    DBMS_OUTPUT.PUT_LINE('TC03 PASS - Tao don test thanh cong, order_id=' || :v_test_order_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC03 FAIL - ' || SQLERRM);
END;
/

SELECT order_id, customer_id, status, shipping_fee, discount_amount, total_amount
FROM orders
WHERE order_id = :v_test_order_id;

PROMPT ==========================================
PROMPT TC04 - Insert order_detail, trigger phai tinh lai total_amount
PROMPT ==========================================
BEGIN
    INSERT INTO order_details (
        order_detail_id,
        order_id,
        book_id,
        quantity,
        unit_price
    )
    VALUES (
        NULL,
        :v_test_order_id,
        1,
        2,
        100000
    )
    RETURNING order_detail_id INTO :v_test_detail_id;

    DBMS_OUTPUT.PUT_LINE('TC04 PASS - Them order_detail thanh cong, detail_id=' || :v_test_detail_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - ' || SQLERRM);
END;
/

SELECT order_id, total_amount, shipping_fee, discount_amount
FROM orders
WHERE order_id = :v_test_order_id;

PROMPT ==========================================
PROMPT TC05 - Update order_detail, trigger phai tinh lai total_amount
PROMPT ==========================================
BEGIN
    UPDATE order_details
       SET quantity = 3,
           unit_price = 100000
     WHERE order_detail_id = :v_test_detail_id;

    DBMS_OUTPUT.PUT_LINE('TC05 PASS - Cap nhat order_detail thanh cong');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC05 FAIL - ' || SQLERRM);
END;
/

SELECT order_id, total_amount, shipping_fee, discount_amount
FROM orders
WHERE order_id = :v_test_order_id;

PROMPT ==========================================
PROMPT TC06 - Update order status hop le, trigger audit phai ghi log
PROMPT ==========================================
BEGIN
    UPDATE orders
       SET status = 'CONFIRMED',
           payment_method = 'COD',
           payment_status = 'PENDING'
     WHERE order_id = :v_test_order_id;

    DBMS_OUTPUT.PUT_LINE('TC06 PASS - Cap nhat orders thanh cong de test audit');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC06 FAIL - ' || SQLERRM);
END;
/

SELECT audit_id, order_id, action_type, old_status, new_status, action_by, action_at
FROM orders_audit_log
WHERE order_id = :v_test_order_id
ORDER BY audit_id;

PROMPT ==========================================
PROMPT TC07 - Delete order_detail, trigger phai tinh lai total_amount
PROMPT ==========================================
BEGIN
    DELETE FROM order_details
     WHERE order_detail_id = :v_test_detail_id;

    DBMS_OUTPUT.PUT_LINE('TC07 PASS - Xoa order_detail thanh cong');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC07 FAIL - ' || SQLERRM);
END;
/

SELECT order_id, total_amount, shipping_fee, discount_amount
FROM orders
WHERE order_id = :v_test_order_id;

PROMPT ==========================================
PROMPT TC08 - Xoa order test, trigger audit phai ghi log DELETE
PROMPT ==========================================
BEGIN
    DELETE FROM orders
     WHERE order_id = :v_test_order_id;

    DBMS_OUTPUT.PUT_LINE('TC08 PASS - Xoa order test thanh cong');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC08 FAIL - ' || SQLERRM);
END;
/

SELECT audit_id, order_id, action_type, old_status, new_status, action_by, action_at
FROM orders_audit_log
WHERE order_id = :v_test_order_id
ORDER BY audit_id;

BEGIN
    SELECT COUNT(*)
      INTO :v_audit_count
      FROM orders_audit_log
     WHERE order_id = :v_test_order_id;

    DBMS_OUTPUT.PUT_LINE('So ban ghi audit cho order test = ' || :v_audit_count);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Khong the dem audit log: ' || SQLERRM);
END;
/

PRINT v_test_order_id;
PRINT v_test_detail_id;
PRINT v_audit_count;

PROMPT ==========================================
PROMPT GOI Y KET THUC PHIEN TEST
PROMPT ==========================================
PROMPT Neu chi test tam thoi thi ROLLBACK;
PROMPT Neu muon giu du lieu audit va du lieu test thi COMMIT;