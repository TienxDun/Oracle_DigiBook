-- ==========================================================
-- FILE: 7_indexes_and_tuning.sql
-- Mục tiêu: Tạo index và mô phỏng tối ưu truy vấn bằng EXPLAIN PLAN
-- Hệ quản trị: Oracle 19c
-- Ghi chú:
--   - Không tạo lại index ngầm đã có từ PRIMARY KEY / UNIQUE.
--   - Tập trung vào các truy vấn báo cáo, dashboard và vận hành thực tế.
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
-- [Dung] Dọn các index tùy biến cũ để script có thể chạy lặp lại
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
    EXECUTE IMMEDIATE 'DROP INDEX idx_books_low_stock';
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

-- Truy vấn này bám sát API /api/summary, lấy 5 đơn mới nhất để lên dashboard.
EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_BEFORE' FOR
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
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- [Dung] INDEX 1 - B-Tree cho đơn hàng mới nhất
-- Lý do:
--   - Hỗ trợ ORDER BY order_date DESC, order_id DESC + FETCH FIRST.
--   - Phù hợp dashboard xem nhanh các đơn gần nhất.
-- ==========================================================
CREATE INDEX idx_orders_recent_date
    ON orders (order_date DESC, order_id DESC);

PROMPT ==========================================
PROMPT Q1 AFTER - Recent orders dashboard
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_AFTER' FOR
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
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q2 BEFORE - Low stock books
PROMPT ==========================================

-- Truy vấn này bám procedure sp_print_low_stock_books và endpoint testing low-stock.
EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_BEFORE' FOR
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
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- [Nam] INDEX 2 - B-Tree cho bài toán tồn kho thấp
-- Lý do:
--   - Hỗ trợ điều kiện stock_quantity <= ngưỡng.
--   - Đồng thời hỗ trợ ORDER BY stock_quantity, book_id mà không cần sort lớn.
-- ==========================================================
CREATE INDEX idx_books_low_stock
    ON books (stock_quantity, book_id);

PROMPT ==========================================
PROMPT Q2 AFTER - Low stock books
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_AFTER' FOR
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
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q3 BEFORE - Daily sales report by day
PROMPT ==========================================

-- Truy vấn này mô phỏng dashboard theo ngày với biểu thức TRUNC(order_date).
EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_BEFORE' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.total_amount) AS gross_amount
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-07'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- [Hieu] INDEX 3 - Function-based index cho báo cáo theo ngày
-- Lý do:
--   - Khi truy vấn dùng TRUNC(order_date), Oracle khó tận dụng index thường.
--   - Function-based index giúp tránh full scan cho các báo cáo nhóm theo ngày.
-- ==========================================================
CREATE INDEX idx_orders_trunc_order_date
    ON orders (TRUNC(order_date));

PROMPT ==========================================
PROMPT Q3 AFTER - Daily sales report by day
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_AFTER' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.total_amount) AS gross_amount
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-07'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q4 BEFORE - Category filter report
PROMPT ==========================================

-- Truy vấn này mô phỏng báo cáo theo danh mục sách có cardinality thấp.
EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_BEFORE' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 9, 10)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q4_BEFORE', 'BASIC +PREDICATE +NOTE'));

-- ==========================================================
-- [Phat] INDEX 4 - Bitmap index cho lọc và nhóm theo category
-- Lý do:
--   - category_id có số lượng giá trị khác nhau thấp và ít thay đổi.
--   - Bitmap index phù hợp cho truy vấn đọc nhiều, lọc/nhóm theo danh mục.
--   - Tránh dùng kiểu này trên cột cập nhật liên tục như status đơn hàng.
-- ==========================================================
CREATE BITMAP INDEX idx_books_category_bm
    ON books (category_id);

PROMPT ==========================================
PROMPT Q4 AFTER - Category filter report
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_AFTER' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 9, 10)
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
    'IDX_BOOKS_LOW_STOCK',
    'IDX_ORDERS_TRUNC_ORDER_DATE',
    'IDX_BOOKS_CATEGORY_BM'
)
ORDER BY index_name;

PROMPT ==========================================
PROMPT GIAI THICH NGAN VE LUA CHON INDEX
PROMPT ==========================================

-- 1) idx_orders_recent_date:
--    Dùng cho dashboard lấy đơn mới nhất, giảm chi phí sort khi chỉ cần vài dòng đầu.
-- 2) idx_books_low_stock:
--    Dùng cho nghiệp vụ kiểm kho và cảnh báo sách sắp hết hàng.
-- 3) idx_orders_trunc_order_date:
--    Dùng cho báo cáo theo ngày khi truy vấn có TRUNC(order_date).
-- 4) idx_books_category_bm:
--    Dùng cho báo cáo đọc nhiều theo danh mục có cardinality thấp.

PROMPT ==========================================
PROMPT KET THUC BUOC 7
PROMPT ==========================================