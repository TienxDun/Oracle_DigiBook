-- ==========================================================
-- FILE: 6_views.sql
-- Mục tiêu: Tạo 3 view phục vụ báo cáo, bảo mật và tổng hợp dữ liệu
-- Hệ quản trị: Oracle 19c
--
-- View 1 (Dũng): View JOIN nhiều bảng để phục vụ báo cáo bán hàng
-- View 2 (Nam): View che giấu dữ liệu nhạy cảm, dùng WITH READ ONLY
-- View 3 (Hiếu): MATERIALIZED VIEW tổng hợp doanh thu theo ngày
-- ==========================================================

-- ==========================================================
-- DỌN DẸP OBJECT CŨ ĐỂ SCRIPT CÓ THỂ CHẠY LẶP LẠI
-- ==========================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_daily_category_sales';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT IN (-12003, -942) THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_secure_profile';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_order_sales_report';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -942 THEN
            RAISE;
        END IF;
END;
/

-- ==========================================================
-- [Dũng] VIEW 1: Báo cáo bán hàng chi tiết theo dòng đơn hàng
-- Mục tiêu:
-- - Kết hợp dữ liệu từ ORDERS, ORDER_DETAILS, CUSTOMERS, BOOKS,
--   CATEGORIES, PUBLISHERS và COUPONS.
-- - Phục vụ truy vấn báo cáo doanh thu, danh mục bán chạy và lịch sử mua hàng.
-- ==========================================================
CREATE OR REPLACE VIEW vw_order_sales_report AS
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.full_name AS customer_name,
    c.email AS customer_email,
    o.status AS order_status,
    o.payment_method,
    o.payment_status,
    cp.coupon_code,
    cp.discount_type,
    b.book_id,
    b.title AS book_title,
    cat.category_id,
    cat.category_name,
    p.publisher_id,
    p.publisher_name,
    od.order_detail_id,
    od.quantity,
    od.unit_price,
    od.subtotal AS line_subtotal,
    o.shipping_fee,
    o.discount_amount,
    o.total_amount AS order_total_amount,
    CASE
        WHEN o.total_amount > 0 THEN ROUND((od.subtotal / o.total_amount) * 100, 2)
        ELSE 0
    END AS line_weight_percent
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON od.order_id = o.order_id
JOIN books b
    ON b.book_id = od.book_id
LEFT JOIN categories cat
    ON cat.category_id = b.category_id
LEFT JOIN publishers p
    ON p.publisher_id = b.publisher_id
LEFT JOIN coupons cp
    ON cp.coupon_id = o.coupon_id;
/

-- ==========================================================
-- [Nam] VIEW 2: Che giấu cột nhạy cảm của khách hàng
-- Mục tiêu:
-- - Không lộ password_hash và thông tin liên hệ nguyên bản.
-- - Chỉ cung cấp dữ liệu đã mask để bộ phận hỗ trợ có thể tra cứu.
-- - Dùng WITH READ ONLY để chặn thao tác DML trực tiếp qua view.
-- ==========================================================
CREATE OR REPLACE VIEW vw_customer_secure_profile AS
SELECT
    c.customer_id,
    c.full_name,
    CASE
        WHEN c.email IS NULL THEN NULL
        WHEN INSTR(c.email, '@') > 4 THEN SUBSTR(c.email, 1, 3) || '***' || SUBSTR(c.email, INSTR(c.email, '@'))
        ELSE '***' || SUBSTR(c.email, INSTR(c.email, '@'))
    END AS masked_email,
    CASE
        WHEN c.phone IS NULL THEN NULL
        WHEN LENGTH(c.phone) >= 7 THEN SUBSTR(c.phone, 1, 3) || '****' || SUBSTR(c.phone, -3)
        ELSE '***MASKED***'
    END AS masked_phone,
    CASE
        WHEN c.address IS NULL THEN NULL
        WHEN INSTR(c.address, ',') > 0 THEN N'***, ' || TRIM(SUBSTR(c.address, INSTR(c.address, ',') + 1))
        ELSE N'***MASKED ADDRESS***'
    END AS masked_address,
    c.status,
    c.created_at,
    c.updated_at,
    NVL(stats.total_orders, 0) AS total_orders,
    NVL(stats.total_spent, 0) AS total_spent,
    CASE
        WHEN NVL(stats.total_spent, 0) >= 2000000 THEN 'VIP'
        WHEN NVL(stats.total_spent, 0) >= 800000 THEN 'LOYAL'
        ELSE 'STANDARD'
    END AS customer_segment
FROM customers c
LEFT JOIN (
    SELECT
        o.customer_id,
        COUNT(*) AS total_orders,
        SUM(o.total_amount) AS total_spent
    FROM orders o
    WHERE o.status <> 'CANCELLED'
    GROUP BY o.customer_id
) stats
    ON stats.customer_id = c.customer_id
WITH READ ONLY;
/

-- ==========================================================
-- [Hiếu] VIEW 3: Materialized view tổng hợp doanh thu theo ngày và danh mục
-- Mục tiêu:
-- - Phục vụ dashboard/report cần đọc nhanh dữ liệu tổng hợp.
-- - Dùng REFRESH COMPLETE ON DEMAND để tương thích đơn giản với Oracle 19c
--   mà không cần tạo MATERIALIZED VIEW LOG.
-- ==========================================================
CREATE MATERIALIZED VIEW mv_daily_category_sales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    TRUNC(o.order_date) AS sale_date,
    cat.category_id,
    cat.category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS total_units_sold,
    SUM(od.subtotal) AS gross_merchandise_value,
    ROUND(AVG(od.unit_price), 2) AS avg_unit_price,
    MAX(o.order_date) AS latest_order_at
FROM orders o
JOIN order_details od
    ON od.order_id = o.order_id
JOIN books b
    ON b.book_id = od.book_id
LEFT JOIN categories cat
    ON cat.category_id = b.category_id
WHERE o.status IN ('CONFIRMED', 'SHIPPING', 'DELIVERED')
GROUP BY
    TRUNC(o.order_date),
    cat.category_id,
    cat.category_name;
/

-- ==========================================================
-- GỢI Ý KIỂM TRA NHANH SAU KHI TẠO VIEW
-- ==========================================================
-- SELECT * FROM vw_order_sales_report FETCH FIRST 10 ROWS ONLY;
-- SELECT * FROM vw_customer_secure_profile FETCH FIRST 10 ROWS ONLY;
-- SELECT * FROM mv_daily_category_sales ORDER BY sale_date, category_id;
-- EXEC DBMS_MVIEW.REFRESH(''MV_DAILY_CATEGORY_SALES'', ''C'');
