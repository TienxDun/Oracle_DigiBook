/*
================================================================================
  📦 BƯỚC 4: XÂY DỰNG STORED PROCEDURES (PL/SQL) — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 4_procedures.sql
  Mục đích: Tạo tối thiểu 4 Stored Procedures xử lý nghiệp vụ phức tạp.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Chạy file này SAU KHI đã chạy 2_create_tables.sql và 3_insert_data.sql.
  - Mỗi SP có khối EXCEPTION để xử lý lỗi an toàn.
  - Dùng DBMS_OUTPUT.PUT_LINE để in kết quả ra console.
  - Trước khi test, chạy: SET SERVEROUTPUT ON;
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 🗑️ XÓA CÁC PROCEDURES CŨ (NẾU TỒN TẠI)
-- ============================================================================
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_manage_book';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_revenue_report';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_list_books_by_cat'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_place_order';       EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ✅ Đã dọn dẹp các Procedure cũ.
PROMPT ================================================

-- ============================================================================
-- 📌 SP 1: sp_manage_book — THÊM / SỬA / XÓA SÁCH
-- Phụ trách: DŨNG
-- ============================================================================
-- Mô tả:
--   Procedure đa năng quản lý sách với 3 hành động:
--     'INSERT' : Thêm sách mới vào bảng BOOKS
--     'UPDATE' : Cập nhật tiêu đề và giá của sách theo book_id
--     'DELETE' : Xóa sách theo book_id (cascade xóa BOOK_AUTHORS, ORDER_DETAILS)
--   Có đầy đủ logic kiểm tra Exception:
--     - Validate hành động hợp lệ
--     - Validate dữ liệu đầu vào (giá > 0, tiêu đề không rỗng)
--     - Kiểm tra tồn tại (khi UPDATE/DELETE)
--     - Xử lý lỗi FK vi phạm, lỗi trùng ISBN, ...
-- Tham số:
--   p_action       : 'INSERT', 'UPDATE', 'DELETE'
--   p_book_id      : Mã sách (cần cho UPDATE, DELETE)
--   p_title        : Tiêu đề sách (cần cho INSERT, UPDATE)
--   p_isbn         : Mã ISBN (cần cho INSERT)
--   p_price        : Giá bán (cần cho INSERT, UPDATE)
--   p_stock        : Số lượng tồn kho (cần cho INSERT)
--   p_pub_year     : Năm xuất bản (cần cho INSERT)
--   p_page_count   : Số trang (cần cho INSERT)
--   p_category_id  : Mã danh mục (cần cho INSERT)
--   p_publisher_id : Mã NXB (cần cho INSERT)
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_manage_book (
    p_action        IN VARCHAR2,
    p_book_id       IN NUMBER    DEFAULT NULL,
    p_title         IN NVARCHAR2 DEFAULT NULL,
    p_isbn          IN VARCHAR2  DEFAULT NULL,
    p_price         IN NUMBER    DEFAULT NULL,
    p_stock         IN NUMBER    DEFAULT 0,
    p_pub_year      IN NUMBER    DEFAULT NULL,
    p_page_count    IN NUMBER    DEFAULT NULL,
    p_category_id   IN NUMBER    DEFAULT NULL,
    p_publisher_id  IN NUMBER    DEFAULT NULL
)
AS
    -- Biến đếm để kiểm tra sự tồn tại của bản ghi
    v_count         NUMBER := 0;
    -- Biến lưu ID sách vừa tạo (dùng cho INSERT)
    v_new_id        NUMBER;

    -- Exception tùy chỉnh: Hành động không hợp lệ
    ex_invalid_action EXCEPTION;
    -- Exception tùy chỉnh: Dữ liệu không hợp lệ
    ex_invalid_data   EXCEPTION;
    -- Exception tùy chỉnh: Không tìm thấy sách
    ex_not_found      EXCEPTION;
BEGIN
    -- ═══════════════════════════════════════════════════════════════════════
    -- BƯỚC 1: KIỂM TRA HÀNH ĐỘNG HỢP LỆ
    -- ═══════════════════════════════════════════════════════════════════════
    IF UPPER(p_action) NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
        RAISE ex_invalid_action;
    END IF;

    -- ═══════════════════════════════════════════════════════════════════════
    -- HÀNH ĐỘNG: INSERT — Thêm sách mới
    -- ═══════════════════════════════════════════════════════════════════════
    IF UPPER(p_action) = 'INSERT' THEN
        -- Validate: Tiêu đề không được rỗng
        IF p_title IS NULL OR LENGTH(TRIM(p_title)) = 0 THEN
            RAISE ex_invalid_data;
        END IF;
        -- Validate: Giá phải lớn hơn 0
        IF p_price IS NULL OR p_price <= 0 THEN
            RAISE ex_invalid_data;
        END IF;

        -- Kiểm tra ISBN trùng lặp (nếu có ISBN)
        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*) INTO v_count
            FROM BOOKS WHERE isbn = p_isbn;
            IF v_count > 0 THEN
                DBMS_OUTPUT.PUT_LINE('❌ LỖI: ISBN "' || p_isbn || '" đã tồn tại trong hệ thống!');
                RETURN;
            END IF;
        END IF;

        -- Thực hiện INSERT
        INSERT INTO BOOKS (title, isbn, price, stock_quantity,
                           publication_year, page_count, category_id, publisher_id)
        VALUES (p_title, p_isbn, p_price, NVL(p_stock, 0),
                p_pub_year, p_page_count, p_category_id, p_publisher_id)
        RETURNING book_id INTO v_new_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✅ THÊM SÁCH THÀNH CÔNG!');
        DBMS_OUTPUT.PUT_LINE('   📖 Book ID  : ' || v_new_id);
        DBMS_OUTPUT.PUT_LINE('   📖 Tiêu đề  : ' || p_title);
        DBMS_OUTPUT.PUT_LINE('   💰 Giá bán  : ' || TO_CHAR(p_price, '999,999,999') || ' VNĐ');

    -- ═══════════════════════════════════════════════════════════════════════
    -- HÀNH ĐỘNG: UPDATE — Cập nhật sách
    -- ═══════════════════════════════════════════════════════════════════════
    ELSIF UPPER(p_action) = 'UPDATE' THEN
        -- Validate: Cần book_id để cập nhật
        IF p_book_id IS NULL THEN
            RAISE ex_invalid_data;
        END IF;

        -- Kiểm tra sách có tồn tại không
        SELECT COUNT(*) INTO v_count
        FROM BOOKS WHERE book_id = p_book_id;

        IF v_count = 0 THEN
            RAISE ex_not_found;
        END IF;

        -- Validate giá nếu có truyền vào
        IF p_price IS NOT NULL AND p_price <= 0 THEN
            RAISE ex_invalid_data;
        END IF;

        -- Cập nhật các trường được truyền vào (giữ nguyên nếu NULL)
        UPDATE BOOKS
        SET title      = NVL(p_title, title),
            price      = NVL(p_price, price),
            isbn       = NVL(p_isbn, isbn),
            stock_quantity  = NVL(p_stock, stock_quantity),
            publication_year = NVL(p_pub_year, publication_year),
            page_count = NVL(p_page_count, page_count),
            category_id  = NVL(p_category_id, category_id),
            publisher_id = NVL(p_publisher_id, publisher_id)
        WHERE book_id = p_book_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✅ CẬP NHẬT SÁCH THÀNH CÔNG!');
        DBMS_OUTPUT.PUT_LINE('   📖 Book ID : ' || p_book_id);

    -- ═══════════════════════════════════════════════════════════════════════
    -- HÀNH ĐỘNG: DELETE — Xóa sách
    -- ═══════════════════════════════════════════════════════════════════════
    ELSIF UPPER(p_action) = 'DELETE' THEN
        -- Validate: Cần book_id để xóa
        IF p_book_id IS NULL THEN
            RAISE ex_invalid_data;
        END IF;

        -- Kiểm tra sách có tồn tại không
        SELECT COUNT(*) INTO v_count
        FROM BOOKS WHERE book_id = p_book_id;

        IF v_count = 0 THEN
            RAISE ex_not_found;
        END IF;

        -- Thực hiện xóa (CASCADE sẽ tự xóa BOOK_AUTHORS, ORDER_DETAILS, REVIEWS)
        DELETE FROM BOOKS WHERE book_id = p_book_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✅ XÓA SÁCH THÀNH CÔNG!');
        DBMS_OUTPUT.PUT_LINE('   🗑️ Đã xóa Book ID: ' || p_book_id);
    END IF;

-- ═══════════════════════════════════════════════════════════════════════════
-- KHỐI XỬ LÝ NGOẠI LỆ (EXCEPTION HANDLING)
-- ═══════════════════════════════════════════════════════════════════════════
EXCEPTION
    WHEN ex_invalid_action THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Hành động "' || p_action || '" không hợp lệ!');
        DBMS_OUTPUT.PUT_LINE('   ℹ️ Chỉ chấp nhận: INSERT, UPDATE, DELETE');

    WHEN ex_invalid_data THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Dữ liệu đầu vào không hợp lệ!');
        DBMS_OUTPUT.PUT_LINE('   ℹ️ Kiểm tra lại: title, price > 0, book_id (cho UPDATE/DELETE).');

    WHEN ex_not_found THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Không tìm thấy sách với Book ID = ' || p_book_id);

    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Vi phạm ràng buộc UNIQUE (ISBN hoặc dữ liệu bị trùng)!');
        ROLLBACK;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI HỆ THỐNG: ' || SQLERRM);
        ROLLBACK;
END sp_manage_book;
/

PROMPT ✅ Tạo SP 1: sp_manage_book (Dũng) thành công!

-- ============================================================================
-- 📌 SP 2: sp_revenue_report — BÁO CÁO DOANH THU TỔNG HỢP
-- Phụ trách: NAM
-- ============================================================================
-- Mô tả:
--   Procedure tính toán và trả về báo cáo doanh thu tổng hợp theo khoảng
--   thời gian. Bao gồm:
--     - Tổng doanh thu đơn hàng đã giao (DELIVERED)
--     - Tổng số đơn hàng / đơn đã giao / đơn bị hủy
--     - Top 3 sách bán chạy nhất
--     - Khách hàng chi tiêu nhiều nhất
-- Tham số:
--   p_from_date : Ngày bắt đầu (mặc định: 30 ngày trước)
--   p_to_date   : Ngày kết thúc (mặc định: hôm nay)
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_revenue_report (
    p_from_date IN DATE DEFAULT SYSDATE - 30,
    p_to_date   IN DATE DEFAULT SYSDATE
)
AS
    -- Biến lưu tổng hợp
    v_total_revenue    NUMBER(15,2) := 0;   -- Tổng doanh thu
    v_total_orders     NUMBER := 0;          -- Tổng số đơn hàng
    v_delivered_orders NUMBER := 0;          -- Số đơn đã giao
    v_cancelled_orders NUMBER := 0;          -- Số đơn bị hủy
    v_total_books_sold NUMBER := 0;          -- Tổng số sách đã bán

    -- Biến lưu thông tin khách hàng chi tiêu nhiều nhất
    v_top_cust_name    NVARCHAR2(100);
    v_top_cust_spent   NUMBER(15,2) := 0;

    -- Biến lưu thông tin top sách bán chạy
    v_book_title       NVARCHAR2(300);
    v_book_qty_sold    NUMBER;
    v_rank             NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║       📊 BÁO CÁO DOANH THU TỔNG HỢP — DigiBook       ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════╝');
    DBMS_OUTPUT.PUT_LINE('📅 Khoảng thời gian: ' ||
        TO_CHAR(p_from_date, 'DD/MM/YYYY') || ' → ' ||
        TO_CHAR(p_to_date, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────────────────');

    -- ══════════════════════════════════════════════════════════════════════
    -- PHẦN 1: TỔNG QUAN ĐƠN HÀNG
    -- ══════════════════════════════════════════════════════════════════════

    -- Tổng số đơn hàng trong khoảng thời gian
    SELECT COUNT(*)
    INTO v_total_orders
    FROM ORDERS
    WHERE order_date BETWEEN p_from_date AND p_to_date;

    -- Số đơn đã giao thành công (DELIVERED)
    SELECT COUNT(*)
    INTO v_delivered_orders
    FROM ORDERS
    WHERE order_date BETWEEN p_from_date AND p_to_date
      AND status = 'DELIVERED';

    -- Số đơn bị hủy (CANCELLED)
    SELECT COUNT(*)
    INTO v_cancelled_orders
    FROM ORDERS
    WHERE order_date BETWEEN p_from_date AND p_to_date
      AND status = 'CANCELLED';

    -- Tổng doanh thu từ đơn hàng DELIVERED
    SELECT NVL(SUM(total_amount), 0)
    INTO v_total_revenue
    FROM ORDERS
    WHERE order_date BETWEEN p_from_date AND p_to_date
      AND status = 'DELIVERED';

    -- Tổng số sách đã bán (từ đơn DELIVERED)
    SELECT NVL(SUM(od.quantity), 0)
    INTO v_total_books_sold
    FROM ORDER_DETAILS od
    INNER JOIN ORDERS o ON od.order_id = o.order_id
    WHERE o.order_date BETWEEN p_from_date AND p_to_date
      AND o.status = 'DELIVERED';

    DBMS_OUTPUT.PUT_LINE('📦 TỔNG QUAN ĐƠN HÀNG:');
    DBMS_OUTPUT.PUT_LINE('   • Tổng số đơn hàng    : ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE('   • Đơn đã giao (✅)     : ' || v_delivered_orders);
    DBMS_OUTPUT.PUT_LINE('   • Đơn bị hủy (❌)      : ' || v_cancelled_orders);
    DBMS_OUTPUT.PUT_LINE('   • Tổng sách đã bán    : ' || v_total_books_sold || ' cuốn');
    DBMS_OUTPUT.PUT_LINE('   • 💰 TỔNG DOANH THU   : ' ||
        TO_CHAR(v_total_revenue, '999,999,999,999') || ' VNĐ');
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────────────────');

    -- ══════════════════════════════════════════════════════════════════════
    -- PHẦN 2: TOP 3 SÁCH BÁN CHẠY NHẤT
    -- ══════════════════════════════════════════════════════════════════════
    DBMS_OUTPUT.PUT_LINE('📚 TOP 3 SÁCH BÁN CHẠY NHẤT:');

    FOR rec IN (
        SELECT b.title, SUM(od.quantity) AS total_qty
        FROM ORDER_DETAILS od
        INNER JOIN BOOKS b ON od.book_id = b.book_id
        INNER JOIN ORDERS o ON od.order_id = o.order_id
        WHERE o.order_date BETWEEN p_from_date AND p_to_date
          AND o.status = 'DELIVERED'
        GROUP BY b.title
        ORDER BY total_qty DESC
        FETCH FIRST 3 ROWS ONLY
    )
    LOOP
        v_rank := v_rank + 1;
        DBMS_OUTPUT.PUT_LINE('   ' || v_rank || '. ' ||
            rec.title || ' — ' || rec.total_qty || ' cuốn');
    END LOOP;

    -- Trường hợp không có dữ liệu
    IF v_rank = 0 THEN
        DBMS_OUTPUT.PUT_LINE('   (Không có dữ liệu bán hàng trong khoảng thời gian này)');
    END IF;

    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────────────────');

    -- ══════════════════════════════════════════════════════════════════════
    -- PHẦN 3: KHÁCH HÀNG CHI TIÊU NHIỀU NHẤT
    -- ══════════════════════════════════════════════════════════════════════
    BEGIN
        SELECT c.full_name, SUM(o.total_amount)
        INTO v_top_cust_name, v_top_cust_spent
        FROM ORDERS o
        INNER JOIN CUSTOMERS c ON o.customer_id = c.customer_id
        WHERE o.order_date BETWEEN p_from_date AND p_to_date
          AND o.status = 'DELIVERED'
        GROUP BY c.full_name
        ORDER BY SUM(o.total_amount) DESC
        FETCH FIRST 1 ROW ONLY;

        DBMS_OUTPUT.PUT_LINE('👑 KHÁCH HÀNG CHI TIÊU NHIỀU NHẤT:');
        DBMS_OUTPUT.PUT_LINE('   • Tên       : ' || v_top_cust_name);
        DBMS_OUTPUT.PUT_LINE('   • Tổng chi  : ' ||
            TO_CHAR(v_top_cust_spent, '999,999,999,999') || ' VNĐ');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('👑 KHÁCH HÀNG CHI TIÊU NHIỀU NHẤT:');
            DBMS_OUTPUT.PUT_LINE('   (Không có dữ liệu)');
    END;

    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('✅ Kết thúc báo cáo.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI KHI TẠO BÁO CÁO: ' || SQLERRM);
END sp_revenue_report;
/

PROMPT ✅ Tạo SP 2: sp_revenue_report (Nam) thành công!

-- ============================================================================
-- 📌 SP 3: sp_list_books_by_cat — LIỆT KÊ SÁCH THEO DANH MỤC (CURSOR)
-- Phụ trách: HIẾU
-- ============================================================================
-- Mô tả:
--   Procedure sử dụng EXPLICIT CURSOR để duyệt và in danh sách sách theo
--   mã danh mục (category_id). Hiển thị thông tin chi tiết bao gồm:
--   tiêu đề, tác giả, giá, tồn kho, NXB. Nếu không truyền category_id
--   thì liệt kê toàn bộ sách, nhóm theo từng danh mục.
-- Tham số:
--   p_category_id : Mã danh mục (NULL = tất cả danh mục)
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_list_books_by_cat (
    p_category_id IN NUMBER DEFAULT NULL
)
AS
    -- ──────────────────────────────────────────────────────────────────────
    -- CURSOR 1: Duyệt danh sách các danh mục
    -- ──────────────────────────────────────────────────────────────────────
    CURSOR cur_categories IS
        SELECT category_id, category_name
        FROM CATEGORIES
        WHERE (p_category_id IS NULL OR category_id = p_category_id)
        ORDER BY category_id;

    -- ──────────────────────────────────────────────────────────────────────
    -- CURSOR 2: Duyệt danh sách sách thuộc một danh mục cụ thể
    -- Kết hợp JOIN lấy tên NXB và danh sách tác giả (LISTAGG)
    -- ──────────────────────────────────────────────────────────────────────
    CURSOR cur_books (c_cat_id NUMBER) IS
        SELECT b.book_id,
               b.title,
               b.price,
               b.stock_quantity,
               NVL(p.publisher_name, 'N/A') AS publisher_name,
               NVL(
                   (SELECT LISTAGG(a.author_name, ', ')
                        WITHIN GROUP (ORDER BY a.author_name)
                    FROM BOOK_AUTHORS ba
                    INNER JOIN AUTHORS a ON ba.author_id = a.author_id
                    WHERE ba.book_id = b.book_id),
                   'Chưa cập nhật'
               ) AS authors
        FROM BOOKS b
        LEFT JOIN PUBLISHERS p ON b.publisher_id = p.publisher_id
        WHERE b.category_id = c_cat_id
        ORDER BY b.title;

    -- Biến đếm
    v_total_books  NUMBER := 0;
    v_cat_count    NUMBER := 0;
    v_book_index   NUMBER;

    -- Biến lưu record từ cursor
    v_cat_rec      cur_categories%ROWTYPE;
    v_book_rec     cur_books%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║         📚 DANH SÁCH SÁCH THEO DANH MỤC               ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════╝');

    -- Mở CURSOR danh mục và duyệt từng danh mục
    OPEN cur_categories;
    LOOP
        FETCH cur_categories INTO v_cat_rec;
        EXIT WHEN cur_categories%NOTFOUND;

        v_cat_count := v_cat_count + 1;
        v_book_index := 0;

        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('📂 DANH MỤC: ' || v_cat_rec.category_name ||
            ' (ID: ' || v_cat_rec.category_id || ')');
        DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────────');

        -- Mở CURSOR sách theo danh mục hiện tại
        OPEN cur_books(v_cat_rec.category_id);
        LOOP
            FETCH cur_books INTO v_book_rec;
            EXIT WHEN cur_books%NOTFOUND;

            v_book_index := v_book_index + 1;
            v_total_books := v_total_books + 1;

            -- In thông tin từng cuốn sách
            DBMS_OUTPUT.PUT_LINE('   ' || v_book_index || '. ' || v_book_rec.title);
            DBMS_OUTPUT.PUT_LINE('      ✍️ Tác giả : ' || v_book_rec.authors);
            DBMS_OUTPUT.PUT_LINE('      💰 Giá     : ' ||
                TO_CHAR(v_book_rec.price, '999,999,999') || ' VNĐ');
            DBMS_OUTPUT.PUT_LINE('      📦 Tồn kho : ' || v_book_rec.stock_quantity || ' cuốn');
            DBMS_OUTPUT.PUT_LINE('      🏢 NXB     : ' || v_book_rec.publisher_name);
        END LOOP;
        CLOSE cur_books;

        -- Nếu danh mục trống
        IF v_book_index = 0 THEN
            DBMS_OUTPUT.PUT_LINE('   (Chưa có sách nào trong danh mục này)');
        END IF;
    END LOOP;
    CLOSE cur_categories;

    -- Tổng kết
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('📊 Tổng kết: ' || v_total_books || ' cuốn sách trong ' ||
        v_cat_count || ' danh mục.');

    -- Trường hợp không tìm thấy danh mục nào
    IF v_cat_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️ Không tìm thấy danh mục với ID = ' || p_category_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Đóng cursor nếu đang mở để tránh rò rỉ tài nguyên
        IF cur_categories%ISOPEN THEN CLOSE cur_categories; END IF;
        IF cur_books%ISOPEN THEN CLOSE cur_books; END IF;
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: ' || SQLERRM);
END sp_list_books_by_cat;
/

PROMPT ✅ Tạo SP 3: sp_list_books_by_cat (Hiếu) thành công!

-- ============================================================================
-- 📌 SP 4: sp_place_order — XỬ LÝ ĐẶT HÀNG (NGHIỆP VỤ BỔ TRỢ)
-- Phụ trách: PHÁT
-- ============================================================================
-- Mô tả:
--   Procedure xử lý toàn bộ luồng đặt hàng cho khách, bao gồm:
--     1. Kiểm tra khách hàng tồn tại và trạng thái ACTIVE
--     2. Kiểm tra sách tồn tại và còn đủ hàng trong kho
--     3. Tạo đơn hàng (ORDERS) với trạng thái PENDING
--     4. Tạo chi tiết đơn hàng (ORDER_DETAILS)
--     5. Trừ số lượng tồn kho (stock_quantity) trong bảng BOOKS
--     6. Cập nhật tổng tiền (total_amount) cho đơn hàng
--   Sử dụng SAVEPOINT và ROLLBACK để đảm bảo tính toàn vẹn dữ liệu.
-- Tham số:
--   p_customer_id    : Mã khách hàng
--   p_book_id        : Mã sách muốn mua
--   p_quantity       : Số lượng mua
--   p_ship_address   : Địa chỉ giao hàng
--   p_payment_method : Phương thức thanh toán
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_place_order (
    p_customer_id       IN NUMBER,
    p_book_id           IN NUMBER,
    p_quantity          IN NUMBER,
    p_ship_address      IN NVARCHAR2,
    p_payment_method    IN VARCHAR2 DEFAULT 'COD'
)
AS
    -- Biến kiểm tra
    v_cust_status   VARCHAR2(20);       -- Trạng thái khách hàng
    v_cust_name     NVARCHAR2(100);     -- Tên khách hàng
    v_book_title    NVARCHAR2(300);     -- Tên sách
    v_book_price    NUMBER(10,2);       -- Giá sách hiện tại
    v_stock         NUMBER;             -- Số lượng tồn kho
    v_new_order_id  NUMBER;             -- ID đơn hàng mới
    v_total         NUMBER(12,2);       -- Tổng tiền

    -- Exception tùy chỉnh
    ex_customer_invalid EXCEPTION;
    ex_book_invalid     EXCEPTION;
    ex_out_of_stock     EXCEPTION;
    ex_invalid_input    EXCEPTION;
BEGIN
    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 0: VALIDATE DỮ LIỆU ĐẦU VÀO
    -- ══════════════════════════════════════════════════════════════════════
    IF p_customer_id IS NULL OR p_book_id IS NULL
       OR p_quantity IS NULL OR p_quantity <= 0
       OR p_ship_address IS NULL THEN
        RAISE ex_invalid_input;
    END IF;

    -- Đặt SAVEPOINT để rollback an toàn nếu có lỗi giữa chừng
    SAVEPOINT sp_before_order;

    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 1: KIỂM TRA KHÁCH HÀNG
    -- ══════════════════════════════════════════════════════════════════════
    BEGIN
        SELECT full_name, status
        INTO v_cust_name, v_cust_status
        FROM CUSTOMERS
        WHERE customer_id = p_customer_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_customer_invalid;
    END;

    -- Kiểm tra trạng thái khách hàng phải là ACTIVE
    IF v_cust_status != 'ACTIVE' THEN
        DBMS_OUTPUT.PUT_LINE('❌ Khách hàng "' || v_cust_name ||
            '" đang ở trạng thái ' || v_cust_status || '! Không thể đặt hàng.');
        RETURN;
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 2: KIỂM TRA SÁCH VÀ TỒN KHO
    -- ══════════════════════════════════════════════════════════════════════
    BEGIN
        SELECT title, price, stock_quantity
        INTO v_book_title, v_book_price, v_stock
        FROM BOOKS
        WHERE book_id = p_book_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_book_invalid;
    END;

    -- Kiểm tra tồn kho đủ không
    IF v_stock < p_quantity THEN
        RAISE ex_out_of_stock;
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 3: TẠO ĐƠN HÀNG
    -- ══════════════════════════════════════════════════════════════════════
    v_total := p_quantity * v_book_price;

    INSERT INTO ORDERS (customer_id, order_date, total_amount, status,
                        shipping_address, payment_method)
    VALUES (p_customer_id, SYSDATE, v_total, 'PENDING',
            p_ship_address, p_payment_method)
    RETURNING order_id INTO v_new_order_id;

    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 4: TẠO CHI TIẾT ĐƠN HÀNG
    -- ══════════════════════════════════════════════════════════════════════
    INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price)
    VALUES (v_new_order_id, p_book_id, p_quantity, v_book_price);

    -- ══════════════════════════════════════════════════════════════════════
    -- BƯỚC 5: TRỪ TỒN KHO
    -- ══════════════════════════════════════════════════════════════════════
    UPDATE BOOKS
    SET stock_quantity = stock_quantity - p_quantity
    WHERE book_id = p_book_id;

    -- COMMIT toàn bộ transaction
    COMMIT;

    -- In thông tin đơn hàng
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║         ✅ ĐẶT HÀNG THÀNH CÔNG!               ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════╝');
    DBMS_OUTPUT.PUT_LINE('   🆔 Mã đơn hàng   : ' || v_new_order_id);
    DBMS_OUTPUT.PUT_LINE('   👤 Khách hàng     : ' || v_cust_name);
    DBMS_OUTPUT.PUT_LINE('   📖 Sách           : ' || v_book_title);
    DBMS_OUTPUT.PUT_LINE('   📦 Số lượng       : ' || p_quantity);
    DBMS_OUTPUT.PUT_LINE('   💰 Đơn giá        : ' ||
        TO_CHAR(v_book_price, '999,999,999') || ' VNĐ');
    DBMS_OUTPUT.PUT_LINE('   💵 Tổng tiền      : ' ||
        TO_CHAR(v_total, '999,999,999') || ' VNĐ');
    DBMS_OUTPUT.PUT_LINE('   📍 Địa chỉ        : ' || p_ship_address);
    DBMS_OUTPUT.PUT_LINE('   💳 Thanh toán      : ' || p_payment_method);
    DBMS_OUTPUT.PUT_LINE('   📦 Tồn kho còn lại: ' || (v_stock - p_quantity) || ' cuốn');

-- ══════════════════════════════════════════════════════════════════════════
-- KHỐI XỬ LÝ NGOẠI LỆ
-- ══════════════════════════════════════════════════════════════════════════
EXCEPTION
    WHEN ex_invalid_input THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Dữ liệu đầu vào không hợp lệ!');
        DBMS_OUTPUT.PUT_LINE('   ℹ️ Cần: customer_id, book_id, quantity > 0, shipping_address.');

    WHEN ex_customer_invalid THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Không tìm thấy khách hàng với ID = ' || p_customer_id);

    WHEN ex_book_invalid THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Không tìm thấy sách với ID = ' || p_book_id);
        ROLLBACK TO sp_before_order;

    WHEN ex_out_of_stock THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI: Sách "' || v_book_title || '" không đủ tồn kho!');
        DBMS_OUTPUT.PUT_LINE('   📦 Tồn kho hiện tại: ' || v_stock ||
            ' | Yêu cầu: ' || p_quantity);
        ROLLBACK TO sp_before_order;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ LỖI HỆ THỐNG: ' || SQLERRM);
        ROLLBACK TO sp_before_order;
END sp_place_order;
/

PROMPT ✅ Tạo SP 4: sp_place_order (Phát) thành công!

-- ============================================================================
-- 🧪 PHẦN TEST: KIỂM TRA CÁC STORED PROCEDURES
-- ============================================================================

PROMPT
PROMPT ================================================================
PROMPT 🧪 BẮT ĐẦU CHẠY TEST CÁC STORED PROCEDURES
PROMPT ================================================================

-- ────────────────────────────────────────────────────────────────────
-- TEST SP 1: sp_manage_book (Dũng)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 1.1: Thêm sách mới (INSERT)
BEGIN
    sp_manage_book(
        p_action     => 'INSERT',
        p_title      => N'Sách Test - Lập Trình Oracle',
        p_isbn       => 'TEST-ISBN-00001',
        p_price      => 199000,
        p_stock      => 50,
        p_pub_year   => 2024,
        p_page_count => 450,
        p_category_id  => 3,
        p_publisher_id => 1
    );
END;
/

PROMPT 🧪 TEST 1.2: Cập nhật sách (UPDATE) — đổi giá
BEGIN
    sp_manage_book(
        p_action   => 'UPDATE',
        p_book_id  => 1,
        p_title    => N'Mắt Biếc (Tái bản 2024)',
        p_price    => 125000
    );
END;
/

PROMPT 🧪 TEST 1.3: Xóa sách không tồn tại (DELETE — error case)
BEGIN
    sp_manage_book(p_action => 'DELETE', p_book_id => 9999);
END;
/

PROMPT 🧪 TEST 1.4: Hành động không hợp lệ (error case)
BEGIN
    sp_manage_book(p_action => 'INVALID_ACTION');
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST SP 2: sp_revenue_report (Nam)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 2: Báo cáo doanh thu 30 ngày gần nhất
BEGIN
    sp_revenue_report(
        p_from_date => SYSDATE - 30,
        p_to_date   => SYSDATE
    );
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST SP 3: sp_list_books_by_cat (Hiếu)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 3.1: Liệt kê sách danh mục "Tiểu thuyết" (ID=1)
BEGIN
    sp_list_books_by_cat(p_category_id => 1);
END;
/

PROMPT 🧪 TEST 3.2: Liệt kê sách danh mục không tồn tại (ID=999)
BEGIN
    sp_list_books_by_cat(p_category_id => 999);
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST SP 4: sp_place_order (Phát)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 4.1: Đặt hàng thành công
BEGIN
    sp_place_order(
        p_customer_id    => 1,
        p_book_id        => 3,
        p_quantity       => 2,
        p_ship_address   => N'Quận 1, TP.HCM',
        p_payment_method => 'E_WALLET'
    );
END;
/

PROMPT 🧪 TEST 4.2: Đặt hàng — khách hàng bị BANNED (error case)
BEGIN
    sp_place_order(
        p_customer_id    => 6,
        p_book_id        => 3,
        p_quantity       => 1,
        p_ship_address   => N'Cầu Giấy, Hà Nội',
        p_payment_method => 'COD'
    );
END;
/

PROMPT 🧪 TEST 4.3: Đặt hàng — không đủ tồn kho (error case)
BEGIN
    sp_place_order(
        p_customer_id    => 1,
        p_book_id        => 15,
        p_quantity       => 5000,
        p_ship_address   => N'Quận 1, TP.HCM',
        p_payment_method => 'COD'
    );
END;
/

-- Dọn dẹp sách test đã thêm ở TEST 1.1
DELETE FROM BOOKS WHERE isbn = 'TEST-ISBN-00001';
-- Khôi phục lại tiêu đề và giá gốc sách ID=1 (sau TEST 1.2)
UPDATE BOOKS SET title = N'Mắt Biếc', price = 110000 WHERE book_id = 1;
COMMIT;

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 4 HOÀN TẤT — TẠO 4 STORED PROCEDURES THÀNH CÔNG!
PROMPT ================================================================
PROMPT    📌 SP 1: sp_manage_book       (Dũng) — CRUD sách + Exception
PROMPT    📌 SP 2: sp_revenue_report    (Nam)  — Báo cáo doanh thu
PROMPT    📌 SP 3: sp_list_books_by_cat (Hiếu) — CURSOR liệt kê sách
PROMPT    📌 SP 4: sp_place_order       (Phát) — Xử lý đặt hàng
PROMPT ================================================================
