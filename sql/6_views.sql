-- ==========================================================
-- FILE: 6_views.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Tạo 3 Views phục vụ báo cáo, bảo mật và tối ưu đọc
-- ==========================================================

-- ==========================================================
-- DỌN DẸP OBJECT CŨ ĐỂ SCRIPT CÓ THỂ CHẠY LẶP LẠI
-- ==========================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_daily_branch_sales';
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
-- View 1 (Dũng): JOIN nhiều bảng cho báo cáo bán hàng
-- Mục tiêu:
-- - Tổng hợp dữ liệu theo từng dòng hàng trong đơn.
-- - Hỗ trợ báo cáo doanh thu theo sách/danh mục/chi nhánh.
-- ==========================================================
CREATE OR REPLACE VIEW vw_order_sales_report AS
SELECT
    o.order_id,
    o.order_code,
    o.order_date,
    o.status_code,
    o.branch_id,
    br.branch_name,
    o.customer_id,
    c.full_name AS customer_name,
    c.email AS customer_email,
    o.coupon_id,
    cp.coupon_code,
    o.total_amount,
    o.discount_amount,
    o.shipping_fee,
    o.final_amount,
    od.detail_id,
    od.book_id,
    b.title AS book_title,
    b.isbn,
    cat.category_id,
    cat.category_name,
    pub.publisher_id,
    pub.publisher_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) AS line_subtotal,
    CASE
        WHEN o.total_amount > 0 THEN ROUND((od.quantity * od.unit_price) / o.total_amount * 100, 2)
        ELSE 0
    END AS line_weight_percent
FROM orders o
JOIN branches br
    ON br.branch_id = o.branch_id
JOIN customers c
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON od.order_id = o.order_id
JOIN books b
    ON b.book_id = od.book_id
LEFT JOIN categories cat
    ON cat.category_id = b.category_id
LEFT JOIN publishers pub
    ON pub.publisher_id = b.publisher_id
LEFT JOIN coupons cp
    ON cp.coupon_id = o.coupon_id;
/

-- ==========================================================
-- View 2 (Nam): Che giấu dữ liệu nhạy cảm của khách hàng
-- Mục tiêu:
-- - Mask email/phone/address cho mục đích tra cứu.
-- - Chặn DML trực tiếp thông qua WITH READ ONLY.
-- ==========================================================
CREATE OR REPLACE VIEW vw_customer_secure_profile AS
SELECT
    c.customer_id,
    c.full_name,
    CASE
        WHEN c.email IS NULL THEN NULL
        WHEN INSTR(c.email, '@') > 3 THEN SUBSTR(c.email, 1, 2) || '***' || SUBSTR(c.email, INSTR(c.email, '@'))
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
    c.province,
    c.district,
    c.created_at,
    c.updated_at,
    NVL(s.total_orders, 0) AS total_orders,
    NVL(s.total_spent, 0) AS total_spent,
    CASE
        WHEN NVL(s.total_spent, 0) >= 5000000 THEN 'VIP'
        WHEN NVL(s.total_spent, 0) >= 1500000 THEN 'LOYAL'
        ELSE 'STANDARD'
    END AS customer_segment
FROM customers c
LEFT JOIN (
    SELECT
        o.customer_id,
        COUNT(*) AS total_orders,
        SUM(o.final_amount) AS total_spent
    FROM orders o
    WHERE o.status_code <> 'CANCELLED'
    GROUP BY o.customer_id
) s
    ON s.customer_id = c.customer_id
WITH READ ONLY;
/

-- ==========================================================
-- View 3 (Hiếu): MATERIALIZED VIEW tổng hợp doanh thu theo ngày/chi nhánh
-- Mục tiêu:
-- - Phục vụ dashboard đọc nhanh dữ liệu tổng hợp.
-- - Dùng REFRESH COMPLETE ON DEMAND để đơn giản triển khai.
-- ==========================================================
CREATE MATERIALIZED VIEW mv_daily_branch_sales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    TRUNC(o.order_date) AS sale_date,
    o.branch_id,
    br.branch_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.status_code = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN o.status_code = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(od.quantity) AS total_units_sold,
    SUM(od.quantity * od.unit_price) AS gross_merchandise_value,
    SUM(o.discount_amount) AS total_discount_amount,
    SUM(o.shipping_fee) AS total_shipping_fee,
    SUM(o.final_amount) AS total_final_amount
FROM orders o
JOIN branches br
    ON br.branch_id = o.branch_id
JOIN order_details od
    ON od.order_id = o.order_id
GROUP BY
    TRUNC(o.order_date),
    o.branch_id,
    br.branch_name;
/

-- ==========================================================
-- GỢI Ý KIỂM TRA NHANH SAU KHI TẠO VIEW
-- ==========================================================
-- SELECT * FROM vw_order_sales_report FETCH FIRST 10 ROWS ONLY;
-- SELECT * FROM vw_customer_secure_profile FETCH FIRST 10 ROWS ONLY;
-- SELECT * FROM mv_daily_branch_sales ORDER BY sale_date, branch_id;
-- EXEC DBMS_MVIEW.REFRESH('MV_DAILY_BRANCH_SALES', 'C');

