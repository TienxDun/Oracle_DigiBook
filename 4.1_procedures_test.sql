-- ==========================================================
-- FILE: 4_procedures_test.sql
-- Mục tiêu: Test case cho 4 stored procedures của DigiBook
-- Hướng dẫn: Chạy file này sau khi đã chạy 4_procedures.sql
-- Oracle: SQL*Plus / SQLcl / SQL Developer
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;

PROMPT ==========================================
PROMPT TC01 - sp_manage_book ADD (happy path)
PROMPT ==========================================
VARIABLE v_book_id NUMBER;
BEGIN
    :v_book_id := NULL;

    sp_manage_book(
        p_action => 'ADD',
        p_book_id => :v_book_id,
        p_title => N'[TC] Oracle PL/SQL Testing Book',
        p_isbn => '9990000000001',
        p_price => 199000,
        p_stock_quantity => 25,
        p_description => N'Sách dùng để test procedure sp_manage_book',
        p_publication_year => 2026,
        p_page_count => 250,
        p_category_id => 10,
        p_publisher_id => 8
    );

    DBMS_OUTPUT.PUT_LINE('TC01 PASS - Tạo mới thành công, book_id=' || :v_book_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC01 FAIL - ' || SQLERRM);
END;
/

SELECT book_id, title, isbn, price, stock_quantity
FROM books
WHERE book_id = :v_book_id;

PROMPT ==========================================
PROMPT TC02 - sp_manage_book UPDATE (happy path)
PROMPT ==========================================
BEGIN
    sp_manage_book(
        p_action => 'UPDATE',
        p_book_id => :v_book_id,
        p_title => N'[TC] Oracle PL/SQL Testing Book - UPDATED',
        p_isbn => '9990000000001',
        p_price => 209000,
        p_stock_quantity => 30,
        p_description => N'Cập nhật để test nhanh',
        p_publication_year => 2026,
        p_page_count => 260,
        p_category_id => 10,
        p_publisher_id => 8
    );

    DBMS_OUTPUT.PUT_LINE('TC02 PASS - Cập nhật thành công, book_id=' || :v_book_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC02 FAIL - ' || SQLERRM);
END;
/

SELECT book_id, title, price, stock_quantity, updated_at
FROM books
WHERE book_id = :v_book_id;

PROMPT ==========================================
PROMPT TC03 - sp_manage_book DELETE (expected fail)
PROMPT ==========================================
VARIABLE v_delete_book_id NUMBER;
EXEC :v_delete_book_id := 1;
BEGIN
    sp_manage_book(
        p_action => 'DELETE',
        p_book_id => :v_delete_book_id,
        p_title => NULL,
        p_isbn => NULL,
        p_price => NULL,
        p_stock_quantity => NULL,
        p_description => NULL,
        p_publication_year => NULL,
        p_page_count => NULL,
        p_category_id => NULL,
        p_publisher_id => NULL
    );

    DBMS_OUTPUT.PUT_LINE('TC03 FAIL - Đáng lẽ phải bị chặn xóa do phát sinh đơn hàng');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC03 PASS - Nhận được lỗi kỳ vọng: ' || SQLERRM);
END;
/

PROMPT ==========================================
PROMPT TC04 - sp_manage_book DELETE (happy path cho ban ghi test)
PROMPT ==========================================
BEGIN
    sp_manage_book(
        p_action => 'DELETE',
        p_book_id => :v_book_id,
        p_title => NULL,
        p_isbn => NULL,
        p_price => NULL,
        p_stock_quantity => NULL,
        p_description => NULL,
        p_publication_year => NULL,
        p_page_count => NULL,
        p_category_id => NULL,
        p_publisher_id => NULL
    );

    DBMS_OUTPUT.PUT_LINE('TC04 PASS - Xóa bản ghi test thành công, book_id=' || :v_book_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - ' || SQLERRM);
END;
/

SELECT COUNT(*) AS remains_after_delete
FROM books
WHERE book_id = :v_book_id;

PROMPT ==========================================
PROMPT TC05 - sp_report_monthly_sales
PROMPT ==========================================
VARIABLE rc REFCURSOR;
EXEC sp_report_monthly_sales(DATE '2026-03-01', DATE '2026-03-31', :rc);
PRINT rc;

PROMPT ==========================================
PROMPT TC06 - sp_print_low_stock_books
PROMPT ==========================================
EXEC sp_print_low_stock_books(50);

PROMPT ==========================================
PROMPT TC07 - sp_calculate_coupon_discount (happy path)
PROMPT ==========================================
VARIABLE v_discount NUMBER;
VARIABLE v_message VARCHAR2(100);
EXEC sp_calculate_coupon_discount('WELCOME10', 500000, :v_discount, :v_message);
PRINT v_discount;
PRINT v_message;

PROMPT ==========================================
PROMPT TC08 - sp_calculate_coupon_discount (expected fail)
PROMPT ==========================================
EXEC sp_calculate_coupon_discount('OLDUSER5', 500000, :v_discount, :v_message);
PRINT v_discount;
PRINT v_message;

PROMPT ==========================================
PROMPT GOI Y CHAY COMMIT/ROLLBACK
PROMPT ==========================================
PROMPT Nếu chỉ test tạm thời thì ROLLBACK;
PROMPT Nếu cần giữ kết quả test thì COMMIT;
