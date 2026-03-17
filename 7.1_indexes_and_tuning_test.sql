-- ==========================================================
-- FILE: 7.1_indexes_and_tuning_test.sql
-- Mục tiêu: Test riêng cho Bước 7 (Indexing & Tuning)
-- Hệ quản trị: Oracle 19c
-- Hướng dẫn:
--   1) Chạy sau khi đã chạy 2_create_tables.sql, 3_insert_data.sql
--   2) Chạy 7_indexes_and_tuning.sql trước để tạo index
--   3) Chạy file này để kiểm tra index và execution plan
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 220;

PROMPT ==========================================
PROMPT STEP 7.1 - INDEXES & TUNING TEST
PROMPT ==========================================

-- ==========================================================
-- [Dung] TC01 - Kiểm tra tồn tại đủ 4 index của Bước 7
-- ==========================================================
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM user_indexes
     WHERE index_name IN (
         'IDX_ORDERS_RECENT_DATE',
         'IDX_BOOKS_LOW_STOCK',
         'IDX_ORDERS_TRUNC_ORDER_DATE',
         'IDX_BOOKS_CATEGORY_BM'
     );

    IF v_count = 4 THEN
        DBMS_OUTPUT.PUT_LINE('TC01 PASS - Da tim thay du 4 index cua Buoc 7');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC01 FAIL - So index tim thay = ' || v_count || ' (mong doi = 4)');
    END IF;
END;
/

-- ==========================================================
-- [Nam] TC02 - Kiểm tra kiểu index (NORMAL / FUNCTION-BASED / BITMAP)
-- ==========================================================
DECLARE
    v_cnt_recent       NUMBER;
    v_cnt_low_stock    NUMBER;
    v_cnt_bitmap       NUMBER;
    v_cnt_fbi          NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_cnt_recent
      FROM user_indexes
     WHERE index_name = 'IDX_ORDERS_RECENT_DATE'
       AND index_type = 'NORMAL';

    SELECT COUNT(*)
      INTO v_cnt_low_stock
      FROM user_indexes
     WHERE index_name = 'IDX_BOOKS_LOW_STOCK'
       AND index_type = 'NORMAL';

    SELECT COUNT(*)
      INTO v_cnt_bitmap
      FROM user_indexes
     WHERE index_name = 'IDX_BOOKS_CATEGORY_BM'
       AND index_type = 'BITMAP';

    SELECT COUNT(*)
      INTO v_cnt_fbi
      FROM user_ind_expressions
     WHERE index_name = 'IDX_ORDERS_TRUNC_ORDER_DATE'
       AND UPPER(column_expression) LIKE '%TRUNC("ORDER_DATE")%';

    IF v_cnt_recent = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC02.1 PASS - IDX_ORDERS_RECENT_DATE co kieu NORMAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC02.1 FAIL - IDX_ORDERS_RECENT_DATE sai kieu index');
    END IF;

    IF v_cnt_low_stock = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC02.2 PASS - IDX_BOOKS_LOW_STOCK co kieu NORMAL');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC02.2 FAIL - IDX_BOOKS_LOW_STOCK sai kieu index');
    END IF;

    IF v_cnt_fbi = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC02.3 PASS - IDX_ORDERS_TRUNC_ORDER_DATE la function-based index');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC02.3 FAIL - IDX_ORDERS_TRUNC_ORDER_DATE khong dung bieu thuc TRUNC(order_date)');
    END IF;

    IF v_cnt_bitmap = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC02.4 PASS - IDX_BOOKS_CATEGORY_BM co kieu BITMAP');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC02.4 FAIL - IDX_BOOKS_CATEGORY_BM khong phai BITMAP');
    END IF;
END;
/

-- ==========================================================
-- [Hieu] TC03 - Kiểm tra thứ tự cột trong index
-- ==========================================================
DECLARE
    v_recent_col1 NUMBER;
    v_recent_col2 NUMBER;
    v_low_col1    NUMBER;
    v_low_col2    NUMBER;
    v_bm_col1     NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_recent_col1
      FROM user_ind_columns
     WHERE index_name = 'IDX_ORDERS_RECENT_DATE'
       AND column_position = 1
       AND column_name = 'ORDER_DATE';

    SELECT COUNT(*)
      INTO v_recent_col2
      FROM user_ind_columns
     WHERE index_name = 'IDX_ORDERS_RECENT_DATE'
       AND column_position = 2
       AND column_name = 'ORDER_ID';

    SELECT COUNT(*)
      INTO v_low_col1
      FROM user_ind_columns
     WHERE index_name = 'IDX_BOOKS_LOW_STOCK'
       AND column_position = 1
       AND column_name = 'STOCK_QUANTITY';

    SELECT COUNT(*)
      INTO v_low_col2
      FROM user_ind_columns
     WHERE index_name = 'IDX_BOOKS_LOW_STOCK'
       AND column_position = 2
       AND column_name = 'BOOK_ID';

    SELECT COUNT(*)
      INTO v_bm_col1
      FROM user_ind_columns
     WHERE index_name = 'IDX_BOOKS_CATEGORY_BM'
       AND column_position = 1
       AND column_name = 'CATEGORY_ID';

    IF v_recent_col1 = 1 AND v_recent_col2 = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC03.1 PASS - IDX_ORDERS_RECENT_DATE dung thu tu cot (ORDER_DATE, ORDER_ID)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC03.1 FAIL - IDX_ORDERS_RECENT_DATE sai thu tu cot');
    END IF;

    IF v_low_col1 = 1 AND v_low_col2 = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC03.2 PASS - IDX_BOOKS_LOW_STOCK dung thu tu cot (STOCK_QUANTITY, BOOK_ID)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC03.2 FAIL - IDX_BOOKS_LOW_STOCK sai thu tu cot');
    END IF;

    IF v_bm_col1 = 1 THEN
        DBMS_OUTPUT.PUT_LINE('TC03.3 PASS - IDX_BOOKS_CATEGORY_BM danh tren CATEGORY_ID');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC03.3 FAIL - IDX_BOOKS_CATEGORY_BM sai cot index');
    END IF;
END;
/

-- ==========================================================
-- [Phat] TC04 - Kiểm tra trạng thái index đang hợp lệ
-- ==========================================================
DECLARE
    v_bad_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_bad_count
      FROM user_indexes
     WHERE index_name IN (
         'IDX_ORDERS_RECENT_DATE',
         'IDX_BOOKS_LOW_STOCK',
         'IDX_ORDERS_TRUNC_ORDER_DATE',
         'IDX_BOOKS_CATEGORY_BM'
     )
       AND (status <> 'VALID' OR visibility <> 'VISIBLE');

    IF v_bad_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC04 PASS - Tat ca index dang VALID va VISIBLE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC04 FAIL - Co ' || v_bad_count || ' index khong o trang thai VALID/VISIBLE');
    END IF;
END;
/

-- ==========================================================
-- [Dung] Chuẩn bị optimizer stats để plan ổn định hơn
-- ==========================================================
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'BOOKS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CUSTOMERS', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CATEGORIES', cascade => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PUBLISHERS', cascade => TRUE);
    DBMS_OUTPUT.PUT_LINE('INFO - Da gather stats cho cac bang lien quan');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARN - Khong gather duoc stats: ' || SQLERRM);
END;
/

-- ==========================================================
-- [Nam] TC05 - EXPLAIN PLAN Q1 (recent orders)
-- ==========================================================
EXPLAIN PLAN SET STATEMENT_ID = 'B7T_Q1' FOR
SELECT
    o.order_id,
    c.full_name,
    o.total_amount,
    o.status,
    o.order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id DESC
FETCH FIRST 5 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7T_Q1', 'BASIC +PREDICATE +NOTE'));

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM plan_table
     WHERE statement_id = 'B7T_Q1'
       AND object_name = 'IDX_ORDERS_RECENT_DATE';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC05 PASS - Plan Q1 co su dung IDX_ORDERS_RECENT_DATE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC05 WARN - Plan Q1 chua hien index (co the do bang nho/chi phi full scan thap)');
    END IF;
END;
/

-- ==========================================================
-- [Hieu] TC06 - EXPLAIN PLAN Q2 (low stock)
-- ==========================================================
EXPLAIN PLAN SET STATEMENT_ID = 'B7T_Q2' FOR
SELECT
    b.book_id,
    b.title,
    b.stock_quantity,
    c.category_name,
    p.publisher_name
FROM books b
LEFT JOIN categories c
    ON c.category_id = b.category_id
LEFT JOIN publishers p
    ON p.publisher_id = b.publisher_id
WHERE b.stock_quantity <= 50
ORDER BY b.stock_quantity ASC, b.book_id ASC;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7T_Q2', 'BASIC +PREDICATE +NOTE'));

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM plan_table
     WHERE statement_id = 'B7T_Q2'
       AND object_name = 'IDX_BOOKS_LOW_STOCK';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC06 PASS - Plan Q2 co su dung IDX_BOOKS_LOW_STOCK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC06 WARN - Plan Q2 chua hien index (co the do du lieu mau con it)');
    END IF;
END;
/

-- ==========================================================
-- [Phat] TC07 - EXPLAIN PLAN Q3 (report theo ngay)
-- ==========================================================
EXPLAIN PLAN SET STATEMENT_ID = 'B7T_Q3' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.total_amount) AS gross_amount
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-07'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7T_Q3', 'BASIC +PREDICATE +NOTE'));

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM plan_table
     WHERE statement_id = 'B7T_Q3'
       AND object_name = 'IDX_ORDERS_TRUNC_ORDER_DATE';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC07 PASS - Plan Q3 co su dung IDX_ORDERS_TRUNC_ORDER_DATE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC07 WARN - Plan Q3 chua hien function-based index');
    END IF;
END;
/

-- ==========================================================
-- [Dung] TC08 - EXPLAIN PLAN Q4 (category filter)
-- ==========================================================
EXPLAIN PLAN SET STATEMENT_ID = 'B7T_Q4' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 9, 10)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7T_Q4', 'BASIC +PREDICATE +NOTE'));

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM plan_table
     WHERE statement_id = 'B7T_Q4'
       AND object_name = 'IDX_BOOKS_CATEGORY_BM';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TC08 PASS - Plan Q4 co su dung IDX_BOOKS_CATEGORY_BM');
    ELSE
        DBMS_OUTPUT.PUT_LINE('TC08 WARN - Plan Q4 chua hien bitmap index');
    END IF;
END;
/

PROMPT ==========================================
PROMPT KIEM TRA NHANH THONG TIN INDEX
PROMPT ==========================================

SELECT
    ui.index_name,
    ui.index_type,
    ui.table_name,
    ui.status,
    ui.visibility,
    ui.num_rows,
    ui.last_analyzed
FROM user_indexes ui
WHERE ui.index_name IN (
    'IDX_ORDERS_RECENT_DATE',
    'IDX_BOOKS_LOW_STOCK',
    'IDX_ORDERS_TRUNC_ORDER_DATE',
    'IDX_BOOKS_CATEGORY_BM'
)
ORDER BY ui.index_name;

PROMPT ==========================================
PROMPT KET THUC STEP 7.1 TEST
PROMPT ==========================================