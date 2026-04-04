-- ==========================================================
-- FILE: 7_indexes_and_tuning.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Tạo INDEX và mô phỏng EXPLAIN PLAN trước/sau tối ưu
-- ==========================================================

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 220;

PROMPT ==========================================
PROMPT BUOC 7 - INDEXING VA TOI UU HOA
PROMPT ==========================================

-- ==========================================================
-- Dọn index cũ để script có thể chạy lặp lại
-- ==========================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_orders_recent_date';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_binv_low_stock';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_orders_trunc_order_date';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_books_category_bm';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

PROMPT ==========================================
PROMPT Q1 BEFORE - Recent orders dashboard
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_BEFORE' FOR
SELECT
    o.order_id,
    o.order_code,
    c.full_name,
    o.final_amount,
    o.status_code,
    o.order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id DESC
FETCH FIRST 5 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- INDEX 1 (Dũng) - B-Tree cho truy vấn đơn mới nhất
-- Lý do: Hỗ trợ ORDER BY order_date DESC, order_id DESC + FETCH FIRST
-- ==========================================================
CREATE INDEX idx_orders_recent_date
    ON orders (order_date DESC, order_id DESC);

PROMPT ==========================================
PROMPT Q1 AFTER - Recent orders dashboard
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_AFTER' FOR
SELECT
    o.order_id,
    o.order_code,
    c.full_name,
    o.final_amount,
    o.status_code,
    o.order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id DESC
FETCH FIRST 5 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q2 BEFORE - Low stock inventory by branch
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_BEFORE' FOR
SELECT
    bi.branch_id,
    bi.book_id,
    bi.quantity_available,
    bi.low_stock_threshold
FROM branch_inventory bi
WHERE bi.quantity_available <= bi.low_stock_threshold
ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- INDEX 2 (Nam) - B-Tree cho bài toán cảnh báo tồn kho thấp
-- Lý do: Tối ưu lọc + sắp xếp theo chi nhánh và số lượng tồn
-- ==========================================================
CREATE INDEX idx_binv_low_stock
    ON branch_inventory (branch_id, quantity_available, low_stock_threshold, book_id);

PROMPT ==========================================
PROMPT Q2 AFTER - Low stock inventory by branch
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_AFTER' FOR
SELECT
    bi.branch_id,
    bi.book_id,
    bi.quantity_available,
    bi.low_stock_threshold
FROM branch_inventory bi
WHERE bi.quantity_available <= bi.low_stock_threshold
ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q3 BEFORE - Daily sales by date
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_BEFORE' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.final_amount) AS total_revenue
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- INDEX 3 (Hiếu) - Function-based index cho báo cáo theo ngày
-- Lý do: Query dùng TRUNC(order_date), index thường khó tận dụng
-- ==========================================================
CREATE INDEX idx_orders_trunc_order_date
    ON orders (TRUNC(order_date));

PROMPT ==========================================
PROMPT Q3 AFTER - Daily sales by date
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_AFTER' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.final_amount) AS total_revenue
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q4 BEFORE - Category analytics
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_BEFORE' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 7, 8)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q4_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- INDEX 4 (Phát) - Bitmap index cho cột category_id
-- Lý do: Cardinality thấp, phù hợp truy vấn đọc nhiều theo danh mục
-- ==========================================================
CREATE BITMAP INDEX idx_books_category_bm
    ON books (category_id);

PROMPT ==========================================
PROMPT Q4 AFTER - Category analytics
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_AFTER' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 7, 8)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q4_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT KIEM TRA CAC INDEX VUA TAO
PROMPT ==========================================

SELECT
    index_name,
    index_type,
    table_name,
    status,
    visibility
FROM user_indexes
WHERE index_name IN (
    'IDX_ORDERS_RECENT_DATE',
    'IDX_BINV_LOW_STOCK',
    'IDX_ORDERS_TRUNC_ORDER_DATE',
    'IDX_BOOKS_CATEGORY_BM'
)
ORDER BY index_name;

