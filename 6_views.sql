/*
================================================================================
  📦 BƯỚC 6: TẠO VIEWS — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 6_views.sql
  Mục đích: Tạo 3 Views phục vụ báo cáo, bảo mật và tối ưu truy vấn.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Chạy file này SAU KHI đã chạy 2_create_tables.sql và 3_insert_data.sql.
  - Materialized View (View 3) yêu cầu quyền CREATE MATERIALIZED VIEW.
    Nếu chạy trên user thường, DBA cần GRANT trước:
      GRANT CREATE MATERIALIZED VIEW TO <username>;
  - Trước khi test, chạy: SET SERVEROUTPUT ON;
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 🗑️ XÓA CÁC ĐỐI TƯỢNG CŨ (NẾU TỒN TẠI)
-- ============================================================================
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_book_sales_summary'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_order_report';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_customer_safe';     EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ✅ Đã dọn dẹp các View cũ.
PROMPT ================================================

-- ============================================================================
-- 👁️ VIEW 1: vw_order_report — BÁO CÁO ĐƠN HÀNG CHI TIẾT (JOIN NHIỀU BẢNG)
-- Phụ trách: DŨNG
-- ============================================================================
-- Mô tả:
--   View kết hợp dữ liệu từ 5 bảng:
--     ORDERS + ORDER_DETAILS + BOOKS + CUSTOMERS + CATEGORIES
--   để tạo ra một báo cáo đơn hàng tổng hợp phục vụ phân tích kinh doanh.
--
--   Thông tin hiển thị:
--     - Thông tin đơn hàng: mã đơn, ngày đặt, trạng thái, tổng tiền
--     - Thông tin khách hàng: tên, email, SĐT
--     - Chi tiết sản phẩm: tên sách, danh mục, số lượng, đơn giá, thành tiền
--     - Phương thức thanh toán, địa chỉ giao hàng
--
--   Mục đích sử dụng:
--     - Xuất báo cáo doanh số bán hàng
--     - Dashboard quản lý đơn hàng
--     - Phân tích xu hướng mua sách theo danh mục
-- ============================================================================
CREATE OR REPLACE VIEW vw_order_report AS
SELECT
    -- ── Thông tin đơn hàng ──
    o.order_id                                          AS ma_don_hang,
    TO_CHAR(o.order_date, 'DD/MM/YYYY HH24:MI')        AS ngay_dat,
    o.status                                            AS trang_thai,
    o.payment_method                                    AS phuong_thuc_tt,
    o.shipping_address                                  AS dia_chi_giao,

    -- ── Thông tin khách hàng (JOIN CUSTOMERS) ──
    c.customer_id                                       AS ma_kh,
    c.full_name                                         AS ten_kh,
    c.email                                             AS email_kh,
    c.phone                                             AS sdt_kh,

    -- ── Chi tiết sản phẩm (JOIN ORDER_DETAILS + BOOKS) ──
    b.book_id                                           AS ma_sach,
    b.title                                             AS ten_sach,
    cat.category_name                                   AS danh_muc,
    od.quantity                                         AS so_luong,
    od.unit_price                                       AS don_gia,
    od.subtotal                                         AS thanh_tien,

    -- ── Tổng tiền toàn đơn hàng ──
    o.total_amount                                      AS tong_tien_don
FROM ORDERS o
    -- JOIN lấy thông tin khách hàng
    INNER JOIN CUSTOMERS c       ON o.customer_id = c.customer_id
    -- JOIN lấy chi tiết từng dòng sản phẩm
    INNER JOIN ORDER_DETAILS od  ON o.order_id = od.order_id
    -- JOIN lấy thông tin sách
    INNER JOIN BOOKS b           ON od.book_id = b.book_id
    -- LEFT JOIN lấy tên danh mục (có thể NULL nếu sách chưa phân loại)
    LEFT JOIN CATEGORIES cat     ON b.category_id = cat.category_id
ORDER BY o.order_date DESC, o.order_id, od.order_detail_id;

COMMENT ON TABLE vw_order_report IS
    'View báo cáo đơn hàng chi tiết — JOIN 5 bảng phục vụ Dashboard và báo cáo kinh doanh (Dũng)';

PROMPT ✅ Tạo View 1: vw_order_report (Dũng) thành công!

-- ============================================================================
-- 👁️ VIEW 2: vw_customer_safe — VIEW CHE GIẤU CỘT NHẠY CẢM (READ ONLY)
-- Phụ trách: NAM
-- ============================================================================
-- Mô tả:
--   View bảo mật trên bảng CUSTOMERS, che giấu các cột nhạy cảm:
--     ❌ password_hash  (mật khẩu mã hóa — tuyệt đối không lộ)
--     ❌ address         (địa chỉ cá nhân)
--     ⚠️ phone          (hiển thị dạng che: 090***4567)
--     ⚠️ email          (hiển thị dạng che: a***n@email.com)
--
--   Sử dụng mệnh đề WITH READ ONLY để đảm bảo không ai có thể
--   INSERT/UPDATE/DELETE thông qua View này.
--
--   Mục đích sử dụng:
--     - Cung cấp cho nhân viên (STAFF) xem danh sách khách hàng
--       mà không lộ thông tin nhạy cảm.
--     - GRANT SELECT ON vw_customer_safe TO staff_role;
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_safe AS
SELECT
    customer_id                                         AS ma_kh,
    full_name                                           AS ho_ten,

    -- Che giấu email: hiển thị 2 ký tự đầu + *** + phần sau @
    -- VD: an.nguyen@email.com → an***@email.com
    SUBSTR(email, 1, 2) || '***' ||
        SUBSTR(email, INSTR(email, '@'))                AS email_masked,

    -- Che giấu SĐT: hiển thị 3 số đầu + *** + 4 số cuối
    -- VD: 0901234567 → 090***4567
    CASE
        WHEN phone IS NOT NULL AND LENGTH(phone) >= 7 THEN
            SUBSTR(phone, 1, 3) || '***' || SUBSTR(phone, -4)
        ELSE
            'N/A'
    END                                                 AS sdt_masked,

    -- Trạng thái (hiển thị nguyên bản)
    status                                              AS trang_thai,

    -- Ngày tạo tài khoản (format đẹp)
    TO_CHAR(created_at, 'DD/MM/YYYY')                   AS ngay_tao,

    -- Tổng số đơn hàng của khách (subquery)
    (SELECT COUNT(*)
     FROM ORDERS o
     WHERE o.customer_id = CUSTOMERS.customer_id)       AS tong_don_hang,

    -- Tổng chi tiêu (chỉ đơn DELIVERED)
    NVL(
        (SELECT SUM(o.total_amount)
         FROM ORDERS o
         WHERE o.customer_id = CUSTOMERS.customer_id
           AND o.status = 'DELIVERED'),
        0
    )                                                   AS tong_chi_tieu

FROM CUSTOMERS

-- ══════════════════════════════════════════════════════════════════════
-- WITH READ ONLY: Đảm bảo View chỉ đọc, không cho phép DML
-- ══════════════════════════════════════════════════════════════════════
WITH READ ONLY;

COMMENT ON TABLE vw_customer_safe IS
    'View bảo mật khách hàng — Che giấu password_hash, address, email và phone. READ ONLY (Nam)';

PROMPT ✅ Tạo View 2: vw_customer_safe (Nam) thành công!

-- ============================================================================
-- 👁️ VIEW 3: mv_book_sales_summary — MATERIALIZED VIEW BÁO CÁO BÁN HÀNG
-- Phụ trách: HIẾU
-- ============================================================================
-- Mô tả:
--   Materialized View lưu trữ vật lý kết quả tính toán thống kê bán hàng
--   cho mỗi cuốn sách. Dữ liệu được "snapshot" lại, giúp truy vấn nhanh
--   mà không cần JOIN lại mỗi lần.
--
--   Thông tin bao gồm:
--     - Thông tin sách: tên, ISBN, giá, tồn kho
--     - Tên danh mục, tên NXB, danh sách tác giả
--     - Thống kê bán hàng: tổng SL bán, tổng doanh thu, số đơn hàng
--     - Thống kê đánh giá: điểm TB, số lượt đánh giá
--
--   Cơ chế REFRESH:
--     - REFRESH COMPLETE ON DEMAND: Làm mới toàn bộ dữ liệu khi gọi thủ công
--       EXEC DBMS_MVIEW.REFRESH('mv_book_sales_summary', 'C');
--     - Phù hợp cho Dashboard, báo cáo chạy định kỳ (ngày/tuần)
--
--   Lưu ý:
--     - Cần GRANT CREATE MATERIALIZED VIEW cho user
--     - Dữ liệu trong MV là "ảnh chụp", có thể không phản ánh real-time
-- ============================================================================
CREATE MATERIALIZED VIEW mv_book_sales_summary
    BUILD IMMEDIATE           -- Tạo dữ liệu ngay khi tạo MV
    REFRESH COMPLETE          -- Làm mới toàn bộ khi REFRESH
    ON DEMAND                 -- Chỉ refresh khi được gọi thủ công
    AS
SELECT
    -- ── Thông tin sách ──
    b.book_id,
    b.title                                             AS ten_sach,
    b.isbn,
    b.price                                             AS gia_ban,
    b.stock_quantity                                    AS ton_kho,
    b.publication_year                                  AS nam_xb,

    -- ── Danh mục (JOIN CATEGORIES) ──
    NVL(cat.category_name, 'Chưa phân loại')            AS danh_muc,

    -- ── Nhà xuất bản (JOIN PUBLISHERS) ──
    NVL(pub.publisher_name, 'Chưa cập nhật')            AS nha_xuat_ban,

    -- ── Danh sách tác giả (JOIN BOOK_AUTHORS + AUTHORS, LISTAGG) ──
    NVL(
        (SELECT LISTAGG(a.author_name, ', ')
             WITHIN GROUP (ORDER BY a.author_name)
         FROM BOOK_AUTHORS ba
         INNER JOIN AUTHORS a ON ba.author_id = a.author_id
         WHERE ba.book_id = b.book_id),
        'Chưa cập nhật'
    )                                                   AS tac_gia,

    -- ── Thống kê bán hàng (từ đơn hàng DELIVERED) ──
    NVL(
        (SELECT SUM(od.quantity)
         FROM ORDER_DETAILS od
         INNER JOIN ORDERS o ON od.order_id = o.order_id
         WHERE od.book_id = b.book_id
           AND o.status = 'DELIVERED'),
        0
    )                                                   AS tong_sl_ban,

    NVL(
        (SELECT SUM(od.subtotal)
         FROM ORDER_DETAILS od
         INNER JOIN ORDERS o ON od.order_id = o.order_id
         WHERE od.book_id = b.book_id
           AND o.status = 'DELIVERED'),
        0
    )                                                   AS tong_doanh_thu,

    NVL(
        (SELECT COUNT(DISTINCT od.order_id)
         FROM ORDER_DETAILS od
         INNER JOIN ORDERS o ON od.order_id = o.order_id
         WHERE od.book_id = b.book_id
           AND o.status = 'DELIVERED'),
        0
    )                                                   AS so_don_hang,

    -- ── Thống kê đánh giá ──
    NVL(
        (SELECT ROUND(AVG(r.rating), 1)
         FROM REVIEWS r
         WHERE r.book_id = b.book_id),
        0
    )                                                   AS diem_tb,

    NVL(
        (SELECT COUNT(*)
         FROM REVIEWS r
         WHERE r.book_id = b.book_id),
        0
    )                                                   AS so_danh_gia

FROM BOOKS b
    LEFT JOIN CATEGORIES cat ON b.category_id = cat.category_id
    LEFT JOIN PUBLISHERS pub ON b.publisher_id = pub.publisher_id;

COMMENT ON MATERIALIZED VIEW mv_book_sales_summary IS
    'Materialized View tổng hợp thông tin sách + doanh số + đánh giá. REFRESH COMPLETE ON DEMAND (Hiếu)';

PROMPT ✅ Tạo View 3: mv_book_sales_summary (Hiếu) thành công!

-- ============================================================================
-- 🧪 PHẦN TEST: KIỂM TRA CÁC VIEWS
-- ============================================================================

PROMPT
PROMPT ================================================================
PROMPT 🧪 BẮT ĐẦU CHẠY TEST CÁC VIEWS
PROMPT ================================================================

-- ────────────────────────────────────────────────────────────────────
-- TEST VIEW 1: vw_order_report (Dũng)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 1: Truy vấn báo cáo đơn hàng (Top 5 dòng gần nhất)
SELECT ma_don_hang, ngay_dat, ten_kh, ten_sach, danh_muc,
       so_luong, don_gia, thanh_tien, trang_thai
FROM vw_order_report
WHERE ROWNUM <= 5;

PROMPT 🧪 TEST 1.2: Tổng doanh thu theo trạng thái đơn hàng
SELECT trang_thai,
       COUNT(DISTINCT ma_don_hang) AS so_don,
       TO_CHAR(SUM(thanh_tien), '999,999,999,999') AS tong_doanh_thu
FROM vw_order_report
GROUP BY trang_thai
ORDER BY tong_doanh_thu DESC;

-- ────────────────────────────────────────────────────────────────────
-- TEST VIEW 2: vw_customer_safe (Nam)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 2.1: Danh sách khách hàng (thông tin đã che giấu)
SELECT ma_kh, ho_ten, email_masked, sdt_masked,
       trang_thai, tong_don_hang, tong_chi_tieu
FROM vw_customer_safe
ORDER BY tong_chi_tieu DESC;

PROMPT 🧪 TEST 2.2: Thử INSERT qua View READ ONLY → Expect: LỖI
BEGIN
    EXECUTE IMMEDIATE
        'INSERT INTO vw_customer_safe (ma_kh, ho_ten) VALUES (999, ''Test'')';
    DBMS_OUTPUT.PUT_LINE('❌ TEST FAIL — Lẽ ra phải bị chặn!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✅ TEST 2.2 PASS — View READ ONLY đã chặn INSERT!');
        DBMS_OUTPUT.PUT_LINE('   Lỗi: ' || SQLERRM);
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST VIEW 3: mv_book_sales_summary (Hiếu)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 3.1: Top 5 sách bán chạy nhất (từ Materialized View)
SELECT ten_sach, tac_gia, danh_muc,
       gia_ban, ton_kho, tong_sl_ban,
       TO_CHAR(tong_doanh_thu, '999,999,999') AS doanh_thu,
       diem_tb, so_danh_gia
FROM mv_book_sales_summary
ORDER BY tong_sl_ban DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT 🧪 TEST 3.2: Thống kê theo danh mục
SELECT danh_muc,
       COUNT(*) AS so_sach,
       SUM(tong_sl_ban) AS tong_ban,
       TO_CHAR(SUM(tong_doanh_thu), '999,999,999,999') AS tong_dt
FROM mv_book_sales_summary
GROUP BY danh_muc
ORDER BY tong_ban DESC;

PROMPT 🧪 TEST 3.3: Refresh Materialized View
BEGIN
    DBMS_MVIEW.REFRESH('mv_book_sales_summary', 'C');
    DBMS_OUTPUT.PUT_LINE('✅ TEST 3.3 PASS — Refresh MV thành công!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠️ TEST 3.3 — ' || SQLERRM);
END;
/

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 6 HOÀN TẤT — TẠO 3 VIEWS THÀNH CÔNG!
PROMPT ================================================================
PROMPT    👁️ View 1: vw_order_report        (Dũng)
PROMPT       → JOIN 5 bảng: ORDERS + ORDER_DETAILS + BOOKS
PROMPT         + CUSTOMERS + CATEGORIES
PROMPT       → Phục vụ báo cáo đơn hàng / Dashboard
PROMPT    👁️ View 2: vw_customer_safe       (Nam)
PROMPT       → Che giấu password_hash, address, email, phone
PROMPT       → WITH READ ONLY — không cho phép DML
PROMPT    👁️ View 3: mv_book_sales_summary  (Hiếu)
PROMPT       → MATERIALIZED VIEW — REFRESH COMPLETE ON DEMAND
PROMPT       → Tổng hợp: sách + doanh số + tác giả + đánh giá
PROMPT ================================================================
