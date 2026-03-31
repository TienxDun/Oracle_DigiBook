-- ==========================================================
-- FILE: 9_transaction_demo.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Demo transaction "Trừ kho - Cộng tiền" + xử lý đồng thời
-- ==========================================================

SET SERVEROUTPUT ON;

-- Đảm bảo transaction mới bắt đầu sạch.
ROLLBACK;

-- Thiết lập mức cô lập cho transaction hiện tại.
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DECLARE
    -- Tham số demo.
    v_branch_id       NUMBER := 1;
    v_quantity        NUMBER := 2;
    v_ship_fee        NUMBER := 25000;

    -- Biến dữ liệu.
    v_customer_id     customers.customer_id%TYPE;
    v_staff_id        staff.staff_id%TYPE;
    v_book_id         books.book_id%TYPE;
    v_unit_price      books.price%TYPE;
    v_order_id        orders.order_id%TYPE;
    v_order_code      orders.order_code%TYPE;
    v_avail_before    branch_inventory.quantity_available%TYPE;
    v_avail_after     branch_inventory.quantity_available%TYPE;

    -- Exception tùy chỉnh.
    e_insufficient_stock EXCEPTION;
    e_resource_busy      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_resource_busy, -54); -- ORA-00054
BEGIN
    -- B1. Lấy khách hàng và nhân viên để tạo đơn demo.
    SELECT customer_id
      INTO v_customer_id
      FROM customers
     WHERE ROWNUM = 1;

    SELECT staff_id
      INTO v_staff_id
      FROM staff
     WHERE branch_id = v_branch_id
       AND ROWNUM = 1;

    -- B2. Khóa 1 dòng tồn kho đủ hàng tại chi nhánh để tránh race condition.
    SELECT bi.book_id,
           bi.quantity_available,
           b.price
      INTO v_book_id, v_avail_before, v_unit_price
      FROM branch_inventory bi
      JOIN books b
        ON b.book_id = bi.book_id
     WHERE bi.branch_id = v_branch_id
       AND bi.quantity_available >= v_quantity
       AND ROWNUM = 1
     FOR UPDATE WAIT 5;

    IF v_avail_before < v_quantity THEN
        RAISE e_insufficient_stock;
    END IF;

    -- B3. Tạo order_code duy nhất dạng DEMO_YYYYMMDDHH24MISS.
    v_order_code := 'DEMO_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

    -- B4. Tạo đơn hàng.
    INSERT INTO orders (
        order_code,
        customer_id,
        branch_id,
        status_code,
        shipping_method_id,
        total_amount,
        discount_amount,
        shipping_fee,
        final_amount,
        order_date,
        ship_address,
        ship_province,
        ship_district,
        ship_phone,
        created_by
    ) VALUES (
        v_order_code,
        v_customer_id,
        v_branch_id,
        'PENDING',
        1,
        0,
        0,
        v_ship_fee,
        v_ship_fee,
        SYSDATE,
        N'Demo transaction Oracle 19c',
        N'TP. Hồ Chí Minh',
        N'Quận 1',
        '0900000000',
        v_staff_id
    )
    RETURNING order_id INTO v_order_id;

    -- B5. Thêm chi tiết đơn hàng.
    INSERT INTO order_details (order_id, book_id, quantity, unit_price)
    VALUES (v_order_id, v_book_id, v_quantity, v_unit_price);

    -- B6. Cập nhật tổng tiền đơn (subtotal + ship - discount).
    UPDATE orders
       SET total_amount = (v_quantity * v_unit_price),
           final_amount = (v_quantity * v_unit_price) + shipping_fee - discount_amount,
           updated_at = SYSDATE,
           updated_by = v_staff_id
     WHERE order_id = v_order_id;

    -- B7. Trừ tồn kho theo chi nhánh.
    UPDATE branch_inventory
       SET quantity_available = quantity_available - v_quantity,
           quantity_reserved = quantity_reserved + v_quantity,
           updated_at = SYSDATE,
           updated_by = v_staff_id
     WHERE branch_id = v_branch_id
       AND book_id = v_book_id;

    -- B8. Ghi nhận giao dịch kho.
    INSERT INTO inventory_transactions (
        branch_id,
        book_id,
        txn_type,
        reference_id,
        reference_type,
        quantity,
        unit_cost,
        total_cost,
        notes,
        created_by
    ) VALUES (
        v_branch_id,
        v_book_id,
        'OUT',
        v_order_id,
        'ORDER',
        -v_quantity,
        v_unit_price,
        (v_quantity * v_unit_price),
        N'Buoc 9 - Tru kho cho don demo',
        v_staff_id
    );

    -- B9. Lưu lịch sử trạng thái.
    INSERT INTO order_status_history (
        order_id,
        old_status,
        new_status,
        changed_by,
        changed_at,
        reason
    ) VALUES (
        v_order_id,
        NULL,
        'PENDING',
        v_staff_id,
        SYSDATE,
        N'Tao don demo transaction'
    );

    -- B10. Đọc lại tồn kho để in log.
    SELECT quantity_available
      INTO v_avail_after
      FROM branch_inventory
     WHERE branch_id = v_branch_id
       AND book_id = v_book_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('=== TRANSACTION THANH CONG ===');
    DBMS_OUTPUT.PUT_LINE('Order ID         : ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('Order Code       : ' || v_order_code);
    DBMS_OUTPUT.PUT_LINE('Branch ID        : ' || v_branch_id);
    DBMS_OUTPUT.PUT_LINE('Book ID          : ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('So luong mua     : ' || v_quantity);
    DBMS_OUTPUT.PUT_LINE('Ton truoc giao dich: ' || v_avail_before);
    DBMS_OUTPUT.PUT_LINE('Ton sau giao dich  : ' || v_avail_after);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Khong tim thay du lieu dau vao phu hop.');
    WHEN e_insufficient_stock THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ton kho khong du.');
    WHEN e_resource_busy THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ban ghi dang bi khoa boi session khac (ORA-00054).');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Loi khac - ' || SQLERRM);
END;
/

