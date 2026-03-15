/*
================================================================================
  📦 BƯỚC 9: TRANSACTION & XỬ LÝ ĐỒNG THỜI (Concurrency) — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 9_transaction_demo.sql
  Mục đích: Mô phỏng Transaction liên hoàn (Trừ kho → Tạo đơn → Cộng tiền)
            với khối BEGIN...EXCEPTION...ROLLBACK/COMMIT và ISOLATION LEVEL.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Chạy file này SAU KHI đã chạy 2_create_tables.sql và 3_insert_data.sql.
  - Bật SET SERVEROUTPUT ON trước khi chạy để thấy output từ DBMS_OUTPUT.
  - Các demo sử dụng SAVEPOINT và ROLLBACK TO để minh họa từng tình huống.
================================================================================
  📚 KIẾN THỨC NỀN (ISOLATION LEVEL TRONG ORACLE 19c):
  ─────────────────────────────────────────────────────────────────────────────
  Oracle 19c hỗ trợ 2 mức Isolation Level:
  
  1. READ COMMITTED (Mặc định):
     - Mỗi câu lệnh SQL thấy dữ liệu đã COMMIT tại thời điểm bắt đầu
       thực thi câu lệnh đó.
     - Câu lệnh tiếp theo trong cùng transaction có thể thấy dữ liệu
       khác nếu có session khác COMMIT xen giữa.
     - Phù hợp cho hầu hết nghiệp vụ OLTP.
  
  2. SERIALIZABLE:
     - Toàn bộ transaction thấy "ảnh chụp" (snapshot) dữ liệu tại thời
       điểm BẮT ĐẦU transaction.
     - Nếu có xung đột (session khác đã sửa dùng đó), Oracle ném lỗi
       ORA-08177: "can't serialize access for this transaction".
     - Phù hợp cho nghiệp vụ yêu cầu tính nhất quán tuyệt đối
       (ví dụ: chuyển khoản ngân hàng, đối soát tài chính).
  
  ⚠️ Oracle KHÔNG hỗ trợ READ UNCOMMITTED (dirty read) và
     REPEATABLE READ (dùng SERIALIZABLE thay thế).
  ─────────────────────────────────────────────────────────────────────────────
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 📌 DEMO 1: TRANSACTION LIÊN HOÀN — ĐẶT HÀNG ĐẦY ĐỦ
-- Phụ trách: DŨNG, NAM
-- ============================================================================
-- Mô tả:
--   Mô phỏng quy trình đặt hàng gồm nhiều bước liên hoàn:
--     Bước 1: Kiểm tra khách hàng hợp lệ (ACTIVE)
--     Bước 2: Kiểm tra sách tồn tại và đủ tồn kho
--     Bước 3: Tạo đơn hàng (INSERT ORDERS)
--     Bước 4: Tạo chi tiết đơn hàng (INSERT ORDER_DETAILS) — 2 sách
--     Bước 5: Trừ tồn kho (UPDATE BOOKS.stock_quantity)
--     Bước 6: Cập nhật tổng tiền đơn hàng (UPDATE ORDERS.total_amount)
--   Nếu BẤT KỲ bước nào thất bại → ROLLBACK toàn bộ.
--   Nếu tất cả thành công → COMMIT.
--
--   Isolation Level: READ COMMITTED (mặc định của Oracle)
-- ============================================================================
PROMPT
PROMPT ================================================================
PROMPT 📌 DEMO 1: Transaction liên hoàn — Đặt hàng đầy đủ
PROMPT    Isolation Level: READ COMMITTED
PROMPT ================================================================

DECLARE
    -- Biến lưu thông tin kiểm tra
    v_cust_status       VARCHAR2(20);
    v_cust_name         NVARCHAR2(100);
    v_book1_title       NVARCHAR2(300);
    v_book1_price       NUMBER(10,2);
    v_book1_stock       NUMBER;
    v_book2_title       NVARCHAR2(300);
    v_book2_price       NUMBER(10,2);
    v_book2_stock       NUMBER;

    -- Biến lưu kết quả transaction
    v_new_order_id      NUMBER;
    v_total_amount      NUMBER(12,2);

    -- Tham số nghiệp vụ
    c_customer_id   CONSTANT NUMBER := 1;       -- Nguyễn Văn An (ACTIVE)
    c_book1_id      CONSTANT NUMBER := 3;       -- Đắc Nhân Tâm
    c_book1_qty     CONSTANT NUMBER := 2;       -- Mua 2 cuốn
    c_book2_id      CONSTANT NUMBER := 5;       -- Sapiens
    c_book2_qty     CONSTANT NUMBER := 1;       -- Mua 1 cuốn
    c_ship_address  CONSTANT NVARCHAR2(200) := N'123 Nguyễn Huệ, Quận 1, TP.HCM';
    c_pay_method    CONSTANT VARCHAR2(20) := 'CREDIT_CARD';

    -- Exception tùy chỉnh
    ex_customer_invalid EXCEPTION;
    ex_insufficient_stock EXCEPTION;
BEGIN
    -- Khai báo Isolation Level cho transaction này
    -- READ COMMITTED: Mỗi câu lệnh thấy dữ liệu đã commit tại thời điểm
    -- bắt đầu chạy câu lệnh đó (mặc định Oracle)
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED NAME 'DEMO1_DAT_HANG';

    DBMS_OUTPUT.PUT_LINE('🔄 Bắt đầu Transaction: DEMO1_DAT_HANG');
    DBMS_OUTPUT.PUT_LINE('📋 Isolation Level: READ COMMITTED');
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');

    -- ══════════════════════════════════════════════════════════════════
    -- SAVEPOINT: Đánh dấu điểm an toàn trước khi bắt đầu xử lý
    -- Nếu có lỗi ở bất kỳ bước nào → ROLLBACK TO điểm này
    -- ══════════════════════════════════════════════════════════════════
    SAVEPOINT sp_before_transaction;

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 1: Kiểm tra khách hàng
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 1: Kiểm tra khách hàng...');
    BEGIN
        SELECT full_name, status
        INTO v_cust_name, v_cust_status
        FROM CUSTOMERS
        WHERE customer_id = c_customer_id;

        IF v_cust_status != 'ACTIVE' THEN
            RAISE ex_customer_invalid;
        END IF;
        DBMS_OUTPUT.PUT_LINE('   ✅ Khách hàng: ' || v_cust_name || ' (' || v_cust_status || ')');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('   ❌ Không tìm thấy khách hàng!');
            ROLLBACK TO sp_before_transaction;
            RETURN;
    END;

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 2: Kiểm tra tồn kho 2 sách
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 2: Kiểm tra tồn kho...');

    -- Sách 1
    SELECT title, price, stock_quantity
    INTO v_book1_title, v_book1_price, v_book1_stock
    FROM BOOKS WHERE book_id = c_book1_id;

    IF v_book1_stock < c_book1_qty THEN
        DBMS_OUTPUT.PUT_LINE('   ❌ "' || v_book1_title || '" không đủ tồn kho!');
        RAISE ex_insufficient_stock;
    END IF;
    DBMS_OUTPUT.PUT_LINE('   ✅ Sách 1: ' || v_book1_title ||
        ' | Kho: ' || v_book1_stock || ' | Mua: ' || c_book1_qty);

    -- Sách 2
    SELECT title, price, stock_quantity
    INTO v_book2_title, v_book2_price, v_book2_stock
    FROM BOOKS WHERE book_id = c_book2_id;

    IF v_book2_stock < c_book2_qty THEN
        DBMS_OUTPUT.PUT_LINE('   ❌ "' || v_book2_title || '" không đủ tồn kho!');
        RAISE ex_insufficient_stock;
    END IF;
    DBMS_OUTPUT.PUT_LINE('   ✅ Sách 2: ' || v_book2_title ||
        ' | Kho: ' || v_book2_stock || ' | Mua: ' || c_book2_qty);

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 3: Tạo đơn hàng (INSERT ORDERS)
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 3: Tạo đơn hàng...');

    v_total_amount := (c_book1_qty * v_book1_price) + (c_book2_qty * v_book2_price);

    INSERT INTO ORDERS (customer_id, order_date, total_amount, status,
                        shipping_address, payment_method)
    VALUES (c_customer_id, SYSDATE, v_total_amount, 'PENDING',
            c_ship_address, c_pay_method)
    RETURNING order_id INTO v_new_order_id;

    DBMS_OUTPUT.PUT_LINE('   ✅ Đã tạo Order #' || v_new_order_id);

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 4: Tạo chi tiết đơn hàng (INSERT ORDER_DETAILS)
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 4: Tạo chi tiết đơn hàng...');

    -- Chi tiết 1: Sách Đắc Nhân Tâm x2
    INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price)
    VALUES (v_new_order_id, c_book1_id, c_book1_qty, v_book1_price);

    -- Chi tiết 2: Sách Sapiens x1
    INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price)
    VALUES (v_new_order_id, c_book2_id, c_book2_qty, v_book2_price);

    DBMS_OUTPUT.PUT_LINE('   ✅ Đã thêm 2 dòng chi tiết vào Order #' || v_new_order_id);

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 5: Trừ tồn kho (UPDATE BOOKS)
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 5: Trừ tồn kho...');

    UPDATE BOOKS
    SET stock_quantity = stock_quantity - c_book1_qty
    WHERE book_id = c_book1_id;

    UPDATE BOOKS
    SET stock_quantity = stock_quantity - c_book2_qty
    WHERE book_id = c_book2_id;

    DBMS_OUTPUT.PUT_LINE('   ✅ "' || v_book1_title || '": ' ||
        v_book1_stock || ' → ' || (v_book1_stock - c_book1_qty));
    DBMS_OUTPUT.PUT_LINE('   ✅ "' || v_book2_title || '": ' ||
        v_book2_stock || ' → ' || (v_book2_stock - c_book2_qty));

    -- ══════════════════════════════════════════════════════════════════
    -- COMMIT: Tất cả các bước đã thành công → Lưu vĩnh viễn
    -- ══════════════════════════════════════════════════════════════════
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║   ✅ TRANSACTION COMMIT THÀNH CÔNG!     ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════╝');
    DBMS_OUTPUT.PUT_LINE('   🆔 Mã đơn hàng   : ' || v_new_order_id);
    DBMS_OUTPUT.PUT_LINE('   👤 Khách hàng     : ' || v_cust_name);
    DBMS_OUTPUT.PUT_LINE('   📖 Sách 1         : ' || v_book1_title || ' x' || c_book1_qty);
    DBMS_OUTPUT.PUT_LINE('   📖 Sách 2         : ' || v_book2_title || ' x' || c_book2_qty);
    DBMS_OUTPUT.PUT_LINE('   💰 Tổng tiền      : ' ||
        TO_CHAR(v_total_amount, '999,999,999') || ' VNĐ');

EXCEPTION
    -- ══════════════════════════════════════════════════════════════════
    -- KHỐI XỬ LÝ NGOẠI LỆ — ROLLBACK KHI CÓ LỖI
    -- ══════════════════════════════════════════════════════════════════
    WHEN ex_customer_invalid THEN
        ROLLBACK TO sp_before_transaction;
        DBMS_OUTPUT.PUT_LINE('❌ ROLLBACK — Khách hàng không hợp lệ (status: ' || v_cust_status || ')');

    WHEN ex_insufficient_stock THEN
        ROLLBACK TO sp_before_transaction;
        DBMS_OUTPUT.PUT_LINE('❌ ROLLBACK — Không đủ tồn kho để đặt hàng!');

    WHEN OTHERS THEN
        ROLLBACK TO sp_before_transaction;
        DBMS_OUTPUT.PUT_LINE('❌ ROLLBACK — Lỗi hệ thống: ' || SQLERRM);
END;
/

-- ============================================================================
-- 📌 DEMO 2: TRANSACTION VỚI ISOLATION LEVEL SERIALIZABLE
-- Phụ trách: HIẾU, PHÁT
-- ============================================================================
-- Mô tả:
--   Mô phỏng nghiệp vụ "Chuyển sách giữa 2 danh mục" dưới mức
--   SERIALIZABLE để đảm bảo tính nhất quán tuyệt đối.
--   
--   Tình huống: Chuyển sách "1984" (ID=9) từ danh mục "Tiểu thuyết" (ID=1)
--   sang danh mục "Khoa học - Viễn tưởng" (ID=6).
--   
--   Khi dùng SERIALIZABLE:
--     - Transaction thấy "ảnh chụp" dữ liệu tại thời điểm bắt đầu.
--     - Nếu session khác đã sửa cùng dòng dữ liệu và COMMIT trước,
--       session này sẽ nhận lỗi ORA-08177.
--   
--   Quy trình:
--     1. Kiểm tra sách tồn tại
--     2. Kiểm tra danh mục đích tồn tại
--     3. Cập nhật category_id của sách
--     4. Ghi log thao tác
-- ============================================================================
PROMPT
PROMPT ================================================================
PROMPT 📌 DEMO 2: Transaction Serializable — Chuyển danh mục sách
PROMPT    Isolation Level: SERIALIZABLE
PROMPT ================================================================

DECLARE
    -- Tham số nghiệp vụ
    c_book_id           CONSTANT NUMBER := 9;   -- 1984 (George Orwell)
    c_old_cat_id        CONSTANT NUMBER := 1;   -- Tiểu thuyết
    c_new_cat_id        CONSTANT NUMBER := 6;   -- Khoa học - Viễn tưởng

    -- Biến kiểm tra
    v_book_title        NVARCHAR2(300);
    v_current_cat_id    NUMBER;
    v_old_cat_name      NVARCHAR2(100);
    v_new_cat_name      NVARCHAR2(100);
    v_count             NUMBER;
BEGIN
    -- Khai báo Isolation Level SERIALIZABLE
    -- Transaction này sẽ thấy snapshot dữ liệu tại thời điểm bắt đầu
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE NAME 'DEMO2_CHUYEN_DANH_MUC';

    DBMS_OUTPUT.PUT_LINE('🔄 Bắt đầu Transaction: DEMO2_CHUYEN_DANH_MUC');
    DBMS_OUTPUT.PUT_LINE('📋 Isolation Level: SERIALIZABLE');
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');

    SAVEPOINT sp_before_transfer;

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 1: Kiểm tra sách tồn tại và lấy thông tin
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 1: Kiểm tra sách...');

    SELECT title, category_id
    INTO v_book_title, v_current_cat_id
    FROM BOOKS
    WHERE book_id = c_book_id;

    DBMS_OUTPUT.PUT_LINE('   ✅ Sách: "' || v_book_title || '" (ID=' || c_book_id || ')');
    DBMS_OUTPUT.PUT_LINE('   📂 Danh mục hiện tại: ID=' || v_current_cat_id);

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 2: Kiểm tra danh mục đích tồn tại
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 2: Kiểm tra danh mục đích...');

    SELECT category_name INTO v_new_cat_name
    FROM CATEGORIES WHERE category_id = c_new_cat_id;

    SELECT category_name INTO v_old_cat_name
    FROM CATEGORIES WHERE category_id = v_current_cat_id;

    DBMS_OUTPUT.PUT_LINE('   ✅ Danh mục cũ : ' || v_old_cat_name);
    DBMS_OUTPUT.PUT_LINE('   ✅ Danh mục mới: ' || v_new_cat_name);

    -- ──────────────────────────────────────────────────────────────────
    -- BƯỚC 3: Cập nhật danh mục sách
    -- ──────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE('📍 Bước 3: Chuyển danh mục...');

    UPDATE BOOKS
    SET category_id = c_new_cat_id
    WHERE book_id = c_book_id;

    DBMS_OUTPUT.PUT_LINE('   ✅ Đã chuyển "' || v_book_title || '"');
    DBMS_OUTPUT.PUT_LINE('      ' || v_old_cat_name || ' → ' || v_new_cat_name);

    -- COMMIT
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║   ✅ TRANSACTION COMMIT THÀNH CÔNG!     ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════╝');

    -- ──────────────────────────────────────────────────────────────────
    -- Khôi phục lại danh mục gốc (cho mục đích demo)
    -- ──────────────────────────────────────────────────────────────────
    UPDATE BOOKS SET category_id = c_old_cat_id WHERE book_id = c_book_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('🔄 Đã khôi phục lại danh mục gốc cho demo.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_before_transfer;
        DBMS_OUTPUT.PUT_LINE('❌ ROLLBACK — Lỗi: ' || SQLERRM);
        -- Kiểm tra lỗi ORA-08177 (Serializable conflict)
        IF SQLCODE = -8177 THEN
            DBMS_OUTPUT.PUT_LINE('   ⚠️ ORA-08177: Xung đột Serializable!');
            DBMS_OUTPUT.PUT_LINE('   ℹ️ Một session khác đã sửa dữ liệu này trước.');
            DBMS_OUTPUT.PUT_LINE('   💡 Giải pháp: Retry transaction sau khi session kia hoàn tất.');
        END IF;
END;
/

-- ============================================================================
-- 📌 DEMO 3: TRANSACTION THẤT BẠI — ROLLBACK TOÀN BỘ
-- Phụ trách: PHÁT
-- ============================================================================
-- Mô tả:
--   Mô phỏng tình huống đặt hàng thất bại giữa chừng:
--     - Khách hàng ID=6 (Vũ Tuấn Phong) có trạng thái BANNED
--     - Transaction sẽ bị ROLLBACK hoàn toàn
--   Minh họa: Không có dữ liệu nào bị thay đổi sau khi ROLLBACK.
-- ============================================================================
PROMPT
PROMPT ================================================================
PROMPT 📌 DEMO 3: Transaction thất bại — ROLLBACK toàn bộ
PROMPT    Mô phỏng: Khách BANNED cố đặt hàng
PROMPT ================================================================

DECLARE
    v_cust_status   VARCHAR2(20);
    v_book_stock_before NUMBER;
    v_book_stock_after  NUMBER;

    ex_banned EXCEPTION;
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED NAME 'DEMO3_ROLLBACK';

    DBMS_OUTPUT.PUT_LINE('🔄 Bắt đầu Transaction: DEMO3_ROLLBACK');
    SAVEPOINT sp_demo3;

    -- Lấy tồn kho sách trước khi thao tác
    SELECT stock_quantity INTO v_book_stock_before
    FROM BOOKS WHERE book_id = 1;
    DBMS_OUTPUT.PUT_LINE('   📦 Tồn kho sách ID=1 TRƯỚC: ' || v_book_stock_before);

    -- Kiểm tra khách hàng
    SELECT status INTO v_cust_status
    FROM CUSTOMERS WHERE customer_id = 6;

    DBMS_OUTPUT.PUT_LINE('   👤 Khách hàng ID=6, trạng thái: ' || v_cust_status);

    IF v_cust_status = 'BANNED' THEN
        -- Giả lập: đã trừ kho nhưng phát hiện lỗi
        UPDATE BOOKS SET stock_quantity = stock_quantity - 1 WHERE book_id = 1;
        DBMS_OUTPUT.PUT_LINE('   ⚠️ Đã trừ kho (tạm thời)...');

        -- Phát hiện khách BANNED → RAISE exception để ROLLBACK
        RAISE ex_banned;
    END IF;

    COMMIT;

EXCEPTION
    WHEN ex_banned THEN
        -- ROLLBACK toàn bộ về SAVEPOINT → Tồn kho được khôi phục
        ROLLBACK TO sp_demo3;

        -- Xác nhận tồn kho đã được khôi phục
        SELECT stock_quantity INTO v_book_stock_after
        FROM BOOKS WHERE book_id = 1;

        DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');
        DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════╗');
        DBMS_OUTPUT.PUT_LINE('║   ❌ TRANSACTION ĐÃ ROLLBACK!          ║');
        DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════╝');
        DBMS_OUTPUT.PUT_LINE('   ❌ Lý do: Khách hàng bị BANNED');
        DBMS_OUTPUT.PUT_LINE('   📦 Tồn kho sách ID=1 SAU ROLLBACK: ' || v_book_stock_after);

        IF v_book_stock_before = v_book_stock_after THEN
            DBMS_OUTPUT.PUT_LINE('   ✅ XÁC NHẬN: Tồn kho ĐÃ KHÔI PHỤC đúng!');
            DBMS_OUTPUT.PUT_LINE('      (Dữ liệu không bị ảnh hưởng bởi transaction thất bại)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('   ❌ CẢNH BÁO: Tồn kho CHƯA khôi phục!');
        END IF;

    WHEN OTHERS THEN
        ROLLBACK TO sp_demo3;
        DBMS_OUTPUT.PUT_LINE('❌ ROLLBACK — Lỗi: ' || SQLERRM);
END;
/

-- ============================================================================
-- 📌 DEMO 4: MÔ PHỎNG DEADLOCK VÀ XỬ LÝ (Concurrency)
-- Phụ trách: NAM
-- ============================================================================
-- Mô tả:
--   Giải thích và mô phỏng cách Oracle xử lý deadlock.
--   Trong thực tế, deadlock xảy ra khi 2 session khóa chéo nhau.
--   Oracle tự động phát hiện và ném ORA-00060 cho 1 trong 2 session.
--
--   Demo này mô phỏng XỬ LÝ khi nhận ORA-00060:
--     - Bắt lỗi DEADLOCK_DETECTED
--     - ROLLBACK và retry (pattern: Retry Loop)
-- ============================================================================
PROMPT
PROMPT ================================================================
PROMPT 📌 DEMO 4: Mô phỏng xử lý Deadlock (Retry Pattern)
PROMPT ================================================================

DECLARE
    -- Số lần retry tối đa
    c_max_retries CONSTANT NUMBER := 3;
    v_retry_count NUMBER := 0;
    v_success     BOOLEAN := FALSE;
    v_book_price  NUMBER(10,2);

    -- Oracle error code cho Deadlock
    DEADLOCK_DETECTED EXCEPTION;
    PRAGMA EXCEPTION_INIT(DEADLOCK_DETECTED, -60);
BEGIN
    DBMS_OUTPUT.PUT_LINE('🔄 Bắt đầu Transaction với Retry Pattern');
    DBMS_OUTPUT.PUT_LINE('   Số lần retry tối đa: ' || c_max_retries);
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');

    -- ══════════════════════════════════════════════════════════════════
    -- RETRY LOOP: Thử lại transaction nếu bị deadlock
    -- ══════════════════════════════════════════════════════════════════
    WHILE v_retry_count < c_max_retries AND NOT v_success LOOP
        BEGIN
            SAVEPOINT sp_retry_point;

            -- Giả lập nghiệp vụ: Cập nhật giá sách
            SELECT price INTO v_book_price
            FROM BOOKS WHERE book_id = 2 FOR UPDATE WAIT 5;
            -- FOR UPDATE WAIT 5: Khóa dòng, chờ tối đa 5 giây nếu bị khóa

            -- Tăng giá 10%
            UPDATE BOOKS
            SET price = price * 1.1
            WHERE book_id = 2;

            COMMIT;
            v_success := TRUE;
            DBMS_OUTPUT.PUT_LINE('   ✅ Lần ' || (v_retry_count + 1) || ': Cập nhật giá thành công!');
            DBMS_OUTPUT.PUT_LINE('   💰 Giá mới: ' ||
                TO_CHAR(v_book_price * 1.1, '999,999,999') || ' VNĐ');

        EXCEPTION
            WHEN DEADLOCK_DETECTED THEN
                ROLLBACK TO sp_retry_point;
                v_retry_count := v_retry_count + 1;
                DBMS_OUTPUT.PUT_LINE('   ⚠️ Lần ' || v_retry_count ||
                    ': Deadlock detected! Đang retry...');

                -- Chờ ngẫu nhiên trước khi retry (backoff)
                DBMS_SESSION.SLEEP(v_retry_count * 0.5);

            WHEN OTHERS THEN
                ROLLBACK TO sp_retry_point;
                IF SQLCODE = -30006 THEN  -- ORA-30006: resource busy
                    v_retry_count := v_retry_count + 1;
                    DBMS_OUTPUT.PUT_LINE('   ⚠️ Lần ' || v_retry_count ||
                        ': Resource busy! Đang retry...');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('   ❌ Lỗi không xử lý được: ' || SQLERRM);
                    EXIT;
                END IF;
        END;
    END LOOP;

    -- Kiểm tra kết quả cuối cùng
    IF v_success THEN
        DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');
        DBMS_OUTPUT.PUT_LINE('✅ Transaction hoàn tất sau ' || (v_retry_count + 1) || ' lần thử.');

        -- Khôi phục giá gốc (cho mục đích demo)
        UPDATE BOOKS SET price = 85000 WHERE book_id = 2;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('🔄 Đã khôi phục giá gốc cho demo.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('────────────────────────────────────────────');
        DBMS_OUTPUT.PUT_LINE('❌ Transaction thất bại sau ' || c_max_retries || ' lần retry!');
    END IF;
END;
/

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 9 HOÀN TẤT — TRANSACTION & CONCURRENCY DEMO!
PROMPT ================================================================
PROMPT    📌 Demo 1: Transaction liên hoàn (READ COMMITTED)
PROMPT       → Trừ kho → Tạo đơn → Cộng tiền → COMMIT
PROMPT    📌 Demo 2: SERIALIZABLE Isolation Level
PROMPT       → Chuyển danh mục sách + xử lý ORA-08177
PROMPT    📌 Demo 3: Transaction ROLLBACK hoàn toàn
PROMPT       → Khách BANNED → ROLLBACK → Xác nhận dữ liệu khôi phục
PROMPT    📌 Demo 4: Deadlock Retry Pattern
PROMPT       → FOR UPDATE WAIT + EXCEPTION_INIT + Retry Loop
PROMPT ================================================================
