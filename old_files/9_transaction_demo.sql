-- ==========================================================
-- BƯỚC 9: TRANSACTION & XỬ LÝ ĐỒNG THỜI (CONCURRENCY)
-- Mục tiêu: Mô phỏng nghiệp vụ "Trừ kho - Cộng tiền" cho DigiBook
-- Phụ trách: Phát
-- Oracle version: 19c
-- ==========================================================

SET SERVEROUTPUT ON;

-- Đóng transaction còn tồn đọng trong session (nếu có)
-- để SET TRANSACTION luôn là lệnh đầu tiên của transaction mới.
ROLLBACK;

-- Đặt mức cô lập cho transaction hiện tại.
-- Có thể đổi sang READ COMMITTED nếu muốn giảm mức khóa.
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DECLARE
    -- Số lượng cần mua trong demo
    v_quantity         NUMBER := 2;

    -- Biến nghiệp vụ
    v_customer_id      customers.customer_id%TYPE;
    v_book_id          books.book_id%TYPE;
    v_order_id         orders.order_id%TYPE;
    v_stock_before     books.stock_quantity%TYPE;
    v_stock_after      books.stock_quantity%TYPE;
    v_unit_price       books.price%TYPE;

    -- Exception tùy chỉnh
    e_insufficient_stock EXCEPTION;
    e_resource_busy      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_resource_busy, -54); -- ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired
BEGIN
    -- Bước 1: Lấy 1 khách hàng bất kỳ để lập đơn demo
    SELECT c.customer_id
      INTO v_customer_id
      FROM customers c
     WHERE ROWNUM = 1;

    -- Bước 2: Chọn 1 sách còn đủ tồn kho và khóa dòng để tránh race condition.
    -- WAIT 5: chờ tối đa 5 giây nếu có session khác đang giữ lock.
    SELECT b.book_id, b.stock_quantity, b.price
      INTO v_book_id, v_stock_before, v_unit_price
      FROM books b
     WHERE b.stock_quantity >= v_quantity
       AND ROWNUM = 1
     FOR UPDATE WAIT 5;

    -- Bước 3: Kiểm tra tồn kho lần cuối trước khi trừ kho
    IF v_stock_before < v_quantity THEN
        RAISE e_insufficient_stock;
    END IF;

    -- Bước 4: Tạo đơn hàng mới (order_id được trigger gán tự động)
    INSERT INTO orders (
        customer_id,
        order_date,
        total_amount,
        status,
        shipping_address,
        payment_method,
        payment_status,
        shipping_fee,
        discount_amount,
        updated_at
    ) VALUES (
        v_customer_id,
        SYSDATE,
        0,
        'PENDING',
        N'Demo giao dịch Bước 9 - Oracle 19c',
        'BANK_TRANSFER',
        'PENDING',
        0,
        0,
        SYSDATE
    )
    RETURNING order_id INTO v_order_id;

    -- Bước 5: Thêm chi tiết đơn hàng.
    -- Trigger trg_aiud_order_details_recalc_order sẽ tự tính lại tổng tiền cho ORDERS.
    INSERT INTO order_details (
        order_id,
        book_id,
        quantity,
        unit_price
    ) VALUES (
        v_order_id,
        v_book_id,
        v_quantity,
        v_unit_price
    );

    -- Bước 6: Trừ tồn kho sách
    UPDATE books
       SET stock_quantity = stock_quantity - v_quantity,
           updated_at = SYSDATE
     WHERE book_id = v_book_id;

    -- Bước 7: Ghi nhận giao dịch kho xuất (OUT) theo đơn hàng
    INSERT INTO inventory_transactions (
        book_id,
        txn_type,
        reference_id,
        reference_type,
        quantity,
        created_at,
        note
    ) VALUES (
        v_book_id,
        'OUT',
        v_order_id,
        'ORDER',
        v_quantity,
        SYSDATE,
        N'Bước 9 - Trừ kho khi tạo đơn demo'
    );

    -- Bước 8: Cập nhật trạng thái đơn để mô phỏng "cộng tiền" (đánh dấu đã thanh toán)
    UPDATE orders
       SET status = 'CONFIRMED',
           payment_status = 'PAID',
           updated_at = SYSDATE
     WHERE order_id = v_order_id;

    -- Bước 9: Ghi lịch sử trạng thái đơn hàng
    INSERT INTO order_status_history (
        order_id,
        old_status,
        new_status,
        changed_at,
        changed_by,
        changed_source,
        note
    ) VALUES (
        v_order_id,
        'PENDING',
        'CONFIRMED',
        SYSDATE,
        v_customer_id,
        'SYSTEM',
        N'Bước 9 - Xác nhận đơn sau khi thanh toán demo'
    );

    -- Bước 10: Đọc lại tồn kho sau cập nhật để in log
    SELECT b.stock_quantity
      INTO v_stock_after
      FROM books b
     WHERE b.book_id = v_book_id;

    -- Thành công: commit toàn bộ transaction
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('=== TRANSACTION THÀNH CÔNG ===');
    DBMS_OUTPUT.PUT_LINE('Order ID      : ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('Customer ID   : ' || v_customer_id);
    DBMS_OUTPUT.PUT_LINE('Book ID       : ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('So luong mua  : ' || v_quantity);
    DBMS_OUTPUT.PUT_LINE('Don gia       : ' || v_unit_price);
    DBMS_OUTPUT.PUT_LINE('Ton kho truoc : ' || v_stock_before);
    DBMS_OUTPUT.PUT_LINE('Ton kho sau   : ' || v_stock_after);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Không tìm thấy khách hàng/sách phù hợp để chạy demo
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Khong tim thay du lieu phu hop de tao giao dich demo.');

    WHEN e_insufficient_stock THEN
        -- Không đủ hàng trong kho
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ton kho khong du de xu ly don hang.');

    WHEN e_resource_busy THEN
        -- Dòng dữ liệu đang bị session khác khóa
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ban ghi dang bi khoa boi session khac (ORA-00054).');

    WHEN OTHERS THEN
        -- Bắt lỗi còn lại để đảm bảo tính toàn vẹn dữ liệu
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Loi khac - ' || SQLERRM);
END;
/

-- ==========================================================
-- KẾT THÚC FILE
-- ==========================================================
