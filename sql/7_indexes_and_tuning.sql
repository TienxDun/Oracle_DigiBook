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

-- ==========================================================
-- INDEX 1 (Dũng) - B-Tree cho truy vấn đơn mới nhất
-- Lý do: Hỗ trợ ORDER BY order_date DESC, order_id DESC + FETCH FIRST
-- ==========================================================
CREATE INDEX idx_orders_recent_date
    ON orders (order_date DESC, order_id DESC);

-- ==========================================================
-- INDEX 2 (Nam) - B-Tree cho bài toán cảnh báo tồn kho thấp
-- Lý do: Tối ưu lọc + sắp xếp theo chi nhánh và số lượng tồn
-- ==========================================================
CREATE INDEX idx_binv_low_stock
    ON branch_inventory (branch_id, quantity_available, low_stock_threshold, book_id);

-- ==========================================================
-- INDEX 3 (Hiếu) - Function-based index cho báo cáo theo ngày
-- Lý do: Query dùng TRUNC(order_date), index thường khó tận dụng
-- ==========================================================
CREATE INDEX idx_orders_trunc_order_date
    ON orders (TRUNC(order_date));

-- ==========================================================
-- INDEX 4 (Phát) - Bitmap index cho cột category_id
-- Lý do: Cardinality thấp, phù hợp truy vấn đọc nhiều theo danh mục
-- ==========================================================
CREATE BITMAP INDEX idx_books_category_bm
    ON books (category_id);

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

