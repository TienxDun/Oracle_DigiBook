/*
================================================================================
  📦 BƯỚC 5: XÂY DỰNG TRIGGERS — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 5_triggers.sql
  Mục đích: Tạo tối thiểu 3 Triggers chuyên sâu, tránh lỗi Mutating Table.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Chạy file này SAU KHI đã chạy 2_create_tables.sql và 3_insert_data.sql.
  - Lưu ý: File 2_create_tables.sql đã tạo 8 triggers auto-increment (trg_*_auto_id).
    Các trigger trong file này là trigger NGHIỆP VỤ, KHÔNG trùng với trigger auto-ID.
  - Trước khi test, chạy: SET SERVEROUTPUT ON;
================================================================================
  ⚠️ CHIẾN LƯỢC TRÁNH MUTATING TABLE:
  - Trigger 1 (BEFORE): Chỉ đọc/ghi trên dòng hiện tại (:NEW, :OLD) → An toàn.
  - Trigger 2 (COMPOUND): Dùng Compound Trigger để gom dữ liệu ở ROW level,
    xử lý cập nhật ở STATEMENT level → Tránh lỗi Mutating Table.
  - Trigger 3 (AFTER FOR EACH ROW): Ghi log vào bảng AUDIT_LOG khác bảng
    đang trigger → An toàn (không đọc lại bảng đang thay đổi).
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 🗑️ XÓA CÁC ĐỐI TƯỢNG CŨ (NẾU TỒN TẠI)
-- ============================================================================
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_validate_order';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_sync_order_total';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_audit_books';             EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AUDIT_LOG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_audit_log';              EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ✅ Đã dọn dẹp các đối tượng cũ.
PROMPT ================================================

-- ============================================================================
-- 📋 TẠO BẢNG AUDIT_LOG — Lưu vết thao tác lịch sử (dùng cho Trigger 3)
-- Phụ trách: HIẾU
-- ============================================================================
-- Mô tả: Bảng phụ trợ ghi nhận mọi thao tác INSERT/UPDATE/DELETE trên
--         bảng BOOKS. Mỗi dòng log lưu lại: ai đã làm gì, lúc nào,
--         giá trị cũ và giá trị mới.
-- ============================================================================
CREATE TABLE AUDIT_LOG (
    log_id          NUMBER
        CONSTRAINT pk_audit_log PRIMARY KEY,
    table_name      VARCHAR2(50)    NOT NULL,       -- Tên bảng bị tác động
    operation       VARCHAR2(10)    NOT NULL,       -- Loại thao tác: INSERT/UPDATE/DELETE
    record_id       NUMBER,                         -- ID bản ghi bị tác động
    column_changed  VARCHAR2(100),                  -- Tên cột bị thay đổi (nếu UPDATE)
    old_value       NVARCHAR2(1000),                -- Giá trị cũ
    new_value       NVARCHAR2(1000),                -- Giá trị mới
    changed_by      VARCHAR2(100)   DEFAULT USER,   -- Người thực hiện (Oracle user)
    changed_at      TIMESTAMP       DEFAULT SYSTIMESTAMP, -- Thời điểm thay đổi
    description     NVARCHAR2(500)                  -- Mô tả bổ sung
);

COMMENT ON TABLE AUDIT_LOG IS 'Bảng ghi vết lịch sử thao tác trên các bảng quan trọng';

-- Sequence cho AUDIT_LOG
CREATE SEQUENCE seq_audit_log
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Trigger auto-ID cho AUDIT_LOG
CREATE OR REPLACE TRIGGER trg_audit_log_auto_id
    BEFORE INSERT ON AUDIT_LOG
    FOR EACH ROW
BEGIN
    IF :NEW.log_id IS NULL THEN
        :NEW.log_id := seq_audit_log.NEXTVAL;
    END IF;
END;
/

PROMPT ✅ Tạo bảng AUDIT_LOG + Sequence + Auto-ID Trigger thành công!
PROMPT ================================================

-- ============================================================================
-- ⚡ TRIGGER 1: trg_validate_order — KIỂM TRA DỮ LIỆU TRƯỚC KHI TẠO ĐƠN
-- Phụ trách: DŨNG
-- ============================================================================
-- Loại    : BEFORE INSERT OR UPDATE ... FOR EACH ROW
-- Bảng    : ORDERS
-- Mô tả  :
--   Trigger kiểm tra tính hợp lệ của dữ liệu ĐƠN HÀNG trước khi cho phép
--   INSERT hoặc UPDATE. Bao gồm:
--     1. Kiểm tra khách hàng có trạng thái ACTIVE (bằng autonomous transaction
--        hoặc đọc bảng CUSTOMERS - an toàn vì CUSTOMERS khác bảng ORDERS).
--     2. Kiểm tra shipping_address không được rỗng.
--     3. Kiểm tra không được thay đổi trạng thái ngược (VD: DELIVERED → PENDING).
--     4. Tự động gán order_date = SYSDATE nếu không truyền.
--
-- ⚠️ KHÔNG GÂY MUTATING TABLE vì:
--   - Trigger trên bảng ORDERS, đọc bảng CUSTOMERS (bảng khác) → An toàn.
--   - Chỉ thao tác trên :NEW / :OLD → An toàn.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_validate_order
    BEFORE INSERT OR UPDATE ON ORDERS
    FOR EACH ROW
DECLARE
    -- Biến lưu trạng thái khách hàng
    v_cust_status VARCHAR2(20);
    v_cust_name   NVARCHAR2(100);

    -- Mảng ánh xạ thứ tự trạng thái đơn hàng (dùng để kiểm tra chiều hợp lệ)
    -- PENDING(1) → CONFIRMED(2) → SHIPPING(3) → DELIVERED(4)
    -- CANCELLED(-1) là trạng thái đặc biệt, chỉ chuyển từ PENDING/CONFIRMED
    v_old_status_order NUMBER;
    v_new_status_order NUMBER;
BEGIN
    -- ══════════════════════════════════════════════════════════════════════
    -- RULE 1: Kiểm tra trạng thái khách hàng phải là ACTIVE
    -- (Chỉ kiểm tra khi INSERT hoặc khi thay đổi customer_id)
    -- ══════════════════════════════════════════════════════════════════════
    IF INSERTING OR (UPDATING AND :OLD.customer_id != :NEW.customer_id) THEN
        BEGIN
            SELECT status, full_name
            INTO v_cust_status, v_cust_name
            FROM CUSTOMERS
            WHERE customer_id = :NEW.customer_id;

            IF v_cust_status != 'ACTIVE' THEN
                RAISE_APPLICATION_ERROR(-20001,
                    'Khách hàng "' || v_cust_name || '" (ID=' || :NEW.customer_id ||
                    ') đang ở trạng thái ' || v_cust_status ||
                    '. Chỉ khách hàng ACTIVE mới được đặt hàng!');
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002,
                    'Không tìm thấy khách hàng với ID = ' || :NEW.customer_id);
        END;
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- RULE 2: Kiểm tra shipping_address không được rỗng
    -- ══════════════════════════════════════════════════════════════════════
    IF :NEW.shipping_address IS NULL OR LENGTH(TRIM(:NEW.shipping_address)) = 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Địa chỉ giao hàng (shipping_address) không được để trống!');
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- RULE 3: Kiểm tra không được chuyển trạng thái ngược
    -- Luồng hợp lệ: PENDING → CONFIRMED → SHIPPING → DELIVERED
    --               PENDING/CONFIRMED → CANCELLED (chỉ 2 trạng thái này được hủy)
    -- ══════════════════════════════════════════════════════════════════════
    IF UPDATING AND :OLD.status != :NEW.status THEN
        -- Ánh xạ trạng thái cũ sang số thứ tự
        v_old_status_order := CASE :OLD.status
            WHEN 'PENDING'   THEN 1
            WHEN 'CONFIRMED' THEN 2
            WHEN 'SHIPPING'  THEN 3
            WHEN 'DELIVERED'  THEN 4
            WHEN 'CANCELLED' THEN -1
            ELSE 0
        END;

        -- Ánh xạ trạng thái mới sang số thứ tự
        v_new_status_order := CASE :NEW.status
            WHEN 'PENDING'   THEN 1
            WHEN 'CONFIRMED' THEN 2
            WHEN 'SHIPPING'  THEN 3
            WHEN 'DELIVERED'  THEN 4
            WHEN 'CANCELLED' THEN -1
            ELSE 0
        END;

        -- Đơn đã DELIVERED hoặc CANCELLED → không được thay đổi nữa
        IF v_old_status_order = 4 THEN
            RAISE_APPLICATION_ERROR(-20004,
                'Đơn hàng đã DELIVERED, không thể thay đổi trạng thái!');
        END IF;

        IF v_old_status_order = -1 THEN
            RAISE_APPLICATION_ERROR(-20005,
                'Đơn hàng đã CANCELLED, không thể thay đổi trạng thái!');
        END IF;

        -- Không được chuyển ngược (trừ CANCELLED)
        IF v_new_status_order != -1 AND v_new_status_order <= v_old_status_order THEN
            RAISE_APPLICATION_ERROR(-20006,
                'Không thể chuyển trạng thái ngược từ ' || :OLD.status ||
                ' về ' || :NEW.status || '!');
        END IF;

        -- Chỉ PENDING và CONFIRMED mới được chuyển sang CANCELLED
        IF v_new_status_order = -1 AND v_old_status_order > 2 THEN
            RAISE_APPLICATION_ERROR(-20007,
                'Chỉ đơn hàng PENDING hoặc CONFIRMED mới được phép hủy (CANCELLED)!');
        END IF;
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- RULE 4: Tự động gán order_date = SYSDATE nếu không truyền (khi INSERT)
    -- ══════════════════════════════════════════════════════════════════════
    IF INSERTING AND :NEW.order_date IS NULL THEN
        :NEW.order_date := SYSDATE;
    END IF;

END trg_validate_order;
/

PROMPT ✅ Tạo Trigger 1: trg_validate_order (Dũng) thành công!

-- ============================================================================
-- ⚡ TRIGGER 2: trg_sync_order_total — TỰ ĐỘNG CẬP NHẬT TỔNG TIỀN ĐƠN HÀNG
-- Phụ trách: NAM
-- ============================================================================
-- Loại    : COMPOUND TRIGGER trên bảng ORDER_DETAILS
-- Bảng    : ORDER_DETAILS
-- Mô tả  :
--   Khi chi tiết đơn hàng bị thay đổi (INSERT/UPDATE/DELETE), trigger sẽ
--   tự động tính lại tổng tiền (total_amount) trong bảng ORDERS.
--
-- ⚠️ GIẢI PHÁP TRÁNH MUTATING TABLE:
--   Sử dụng COMPOUND TRIGGER với 2 phase:
--     - AFTER EACH ROW: Thu thập danh sách order_id bị ảnh hưởng vào
--       collection (mảng PL/SQL).
--     - AFTER STATEMENT: Duyệt collection, tính lại total_amount cho mỗi
--       order_id bị ảnh hưởng từ bảng ORDER_DETAILS (lúc này bảng đã ổn định,
--       không còn mutating).
--   Cập nhật bảng ORDERS (bảng khác) → An toàn.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_sync_order_total
    FOR INSERT OR UPDATE OR DELETE ON ORDER_DETAILS
    COMPOUND TRIGGER

    -- Kiểu dữ liệu: Bảng PL/SQL lưu danh sách order_id cần cập nhật
    TYPE t_order_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    -- Biến toàn cục trong Compound Trigger
    g_order_ids   t_order_ids;
    g_index       PLS_INTEGER := 0;

    -- ──────────────────────────────────────────────────────────────────
    -- PHASE 1: AFTER EACH ROW
    -- Thu thập tất cả order_id bị ảnh hưởng bởi thao tác DML
    -- ──────────────────────────────────────────────────────────────────
    AFTER EACH ROW IS
    BEGIN
        -- Khi INSERT hoặc UPDATE: lấy order_id từ dòng mới
        IF INSERTING OR UPDATING THEN
            g_index := g_index + 1;
            g_order_ids(g_index) := :NEW.order_id;
        END IF;

        -- Khi DELETE: lấy order_id từ dòng cũ
        IF DELETING THEN
            g_index := g_index + 1;
            g_order_ids(g_index) := :OLD.order_id;
        END IF;

        -- Khi UPDATE mà đổi order_id (hiếm gặp): cần cập nhật cả đơn cũ
        IF UPDATING AND :OLD.order_id != :NEW.order_id THEN
            g_index := g_index + 1;
            g_order_ids(g_index) := :OLD.order_id;
        END IF;
    END AFTER EACH ROW;

    -- ──────────────────────────────────────────────────────────────────
    -- PHASE 2: AFTER STATEMENT
    -- Duyệt danh sách order_id đã thu thập, tính lại total_amount
    -- Lúc này bảng ORDER_DETAILS đã ổn định → Không bị Mutating
    -- ──────────────────────────────────────────────────────────────────
    AFTER STATEMENT IS
        v_new_total NUMBER(12,2);
    BEGIN
        -- Loại bỏ trùng lặp và xử lý từng order_id
        FOR i IN 1 .. g_index LOOP
            -- Tính tổng tiền từ tất cả dòng chi tiết của đơn hàng
            -- subtotal là Virtual Column = quantity * unit_price
            SELECT NVL(SUM(subtotal), 0)
            INTO v_new_total
            FROM ORDER_DETAILS
            WHERE order_id = g_order_ids(i);

            -- Cập nhật total_amount trong bảng ORDERS
            UPDATE ORDERS
            SET total_amount = v_new_total
            WHERE order_id = g_order_ids(i);

            DBMS_OUTPUT.PUT_LINE('🔄 [TRIGGER] Đã cập nhật total_amount cho Order #' ||
                g_order_ids(i) || ' = ' ||
                TO_CHAR(v_new_total, '999,999,999') || ' VNĐ');
        END LOOP;
    END AFTER STATEMENT;

END trg_sync_order_total;
/

PROMPT ✅ Tạo Trigger 2: trg_sync_order_total (Nam) thành công!

-- ============================================================================
-- ⚡ TRIGGER 3: trg_audit_books — GHI NHẬN AUDIT LOG KHI THAO TÁC BẢNG BOOKS
-- Phụ trách: HIẾU
-- ============================================================================
-- Loại    : AFTER INSERT OR UPDATE OR DELETE ... FOR EACH ROW
-- Bảng    : BOOKS
-- Mô tả  :
--   Trigger ghi nhận mọi thao tác trên bảng BOOKS (sản phẩm chính) vào
--   bảng AUDIT_LOG. Bao gồm:
--     INSERT : Ghi log sách mới được thêm.
--     UPDATE : Ghi log từng cột bị thay đổi (title, price, stock_quantity).
--     DELETE : Ghi log sách bị xóa.
--
-- ⚠️ KHÔNG GÂY MUTATING TABLE vì:
--   - Trigger trên bảng BOOKS, ghi vào bảng AUDIT_LOG (bảng khác) → An toàn.
--   - Chỉ đọc :NEW / :OLD (dòng hiện tại) → An toàn.
-- ============================================================================
CREATE OR REPLACE TRIGGER trg_audit_books
    AFTER INSERT OR UPDATE OR DELETE ON BOOKS
    FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    -- Xác định loại thao tác
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSIF DELETING THEN
        v_operation := 'DELETE';
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- TRƯỜNG HỢP INSERT: Ghi log sách mới được thêm vào hệ thống
    -- ══════════════════════════════════════════════════════════════════════
    IF INSERTING THEN
        INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                               column_changed, old_value, new_value, description)
        VALUES ('BOOKS', v_operation, :NEW.book_id,
                'ALL', NULL, :NEW.title,
                'Thêm sách mới: "' || :NEW.title || '" | Giá: ' ||
                TO_CHAR(:NEW.price, '999,999,999') || ' VNĐ | Tồn kho: ' ||
                :NEW.stock_quantity);
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- TRƯỜNG HỢP UPDATE: Ghi log chi tiết từng cột bị thay đổi
    -- ══════════════════════════════════════════════════════════════════════
    IF UPDATING THEN
        -- Ghi log nếu TIÊU ĐỀ thay đổi
        IF :OLD.title != :NEW.title OR (:OLD.title IS NULL AND :NEW.title IS NOT NULL) THEN
            INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                                   column_changed, old_value, new_value, description)
            VALUES ('BOOKS', v_operation, :NEW.book_id,
                    'TITLE', :OLD.title, :NEW.title,
                    'Đổi tiêu đề sách ID=' || :NEW.book_id);
        END IF;

        -- Ghi log nếu GIÁ thay đổi
        IF :OLD.price != :NEW.price THEN
            INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                                   column_changed, old_value, new_value, description)
            VALUES ('BOOKS', v_operation, :NEW.book_id,
                    'PRICE',
                    TO_CHAR(:OLD.price, '999,999,999'),
                    TO_CHAR(:NEW.price, '999,999,999'),
                    'Thay đổi giá sách "' || :NEW.title || '"');
        END IF;

        -- Ghi log nếu TỒN KHO thay đổi
        IF :OLD.stock_quantity != :NEW.stock_quantity THEN
            INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                                   column_changed, old_value, new_value, description)
            VALUES ('BOOKS', v_operation, :NEW.book_id,
                    'STOCK_QUANTITY',
                    TO_CHAR(:OLD.stock_quantity),
                    TO_CHAR(:NEW.stock_quantity),
                    'Thay đổi tồn kho sách "' || :NEW.title || '"');
        END IF;

        -- Ghi log nếu DANH MỤC thay đổi
        IF NVL(:OLD.category_id, -1) != NVL(:NEW.category_id, -1) THEN
            INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                                   column_changed, old_value, new_value, description)
            VALUES ('BOOKS', v_operation, :NEW.book_id,
                    'CATEGORY_ID',
                    TO_CHAR(:OLD.category_id),
                    TO_CHAR(:NEW.category_id),
                    'Thay đổi danh mục sách "' || :NEW.title || '"');
        END IF;

        -- Ghi log nếu NHÀ XUẤT BẢN thay đổi
        IF NVL(:OLD.publisher_id, -1) != NVL(:NEW.publisher_id, -1) THEN
            INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                                   column_changed, old_value, new_value, description)
            VALUES ('BOOKS', v_operation, :NEW.book_id,
                    'PUBLISHER_ID',
                    TO_CHAR(:OLD.publisher_id),
                    TO_CHAR(:NEW.publisher_id),
                    'Thay đổi NXB sách "' || :NEW.title || '"');
        END IF;
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- TRƯỜNG HỢP DELETE: Ghi log sách bị xóa khỏi hệ thống
    -- ══════════════════════════════════════════════════════════════════════
    IF DELETING THEN
        INSERT INTO AUDIT_LOG (table_name, operation, record_id,
                               column_changed, old_value, new_value, description)
        VALUES ('BOOKS', v_operation, :OLD.book_id,
                'ALL', :OLD.title, NULL,
                'Xóa sách: "' || :OLD.title || '" | Giá: ' ||
                TO_CHAR(:OLD.price, '999,999,999') || ' VNĐ | Tồn kho còn: ' ||
                :OLD.stock_quantity);
    END IF;

END trg_audit_books;
/

PROMPT ✅ Tạo Trigger 3: trg_audit_books (Hiếu) thành công!

-- ============================================================================
-- 🧪 PHẦN TEST: KIỂM TRA CÁC TRIGGERS
-- ============================================================================

PROMPT
PROMPT ================================================================
PROMPT 🧪 BẮT ĐẦU CHẠY TEST CÁC TRIGGERS
PROMPT ================================================================

-- ────────────────────────────────────────────────────────────────────
-- TEST TRIGGER 1: trg_validate_order (Dũng)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 1.1: Tạo đơn hàng cho khách BANNED (ID=6) → Expect: LỖI
DECLARE
    v_error_msg VARCHAR2(500);
BEGIN
    INSERT INTO ORDERS (customer_id, total_amount, status, shipping_address, payment_method)
    VALUES (6, 100000, 'PENDING', N'Cầu Giấy, Hà Nội', 'COD');
    DBMS_OUTPUT.PUT_LINE('❌ TEST FAIL — Lẽ ra phải bị chặn!');
EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
        IF INSTR(v_error_msg, 'ACTIVE') > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✅ TEST 1.1 PASS — Trigger đã chặn: ' || v_error_msg);
        ELSE
            DBMS_OUTPUT.PUT_LINE('⚠️ TEST 1.1 — Lỗi khác: ' || v_error_msg);
        END IF;
END;
/

PROMPT 🧪 TEST 1.2: Chuyển đơn DELIVERED → PENDING → Expect: LỖI
DECLARE
    v_error_msg VARCHAR2(500);
BEGIN
    -- Đơn hàng 1 đang DELIVERED (từ dữ liệu mẫu)
    UPDATE ORDERS SET status = 'PENDING' WHERE order_id = 1;
    DBMS_OUTPUT.PUT_LINE('❌ TEST FAIL — Lẽ ra phải bị chặn!');
EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
        IF INSTR(v_error_msg, 'DELIVERED') > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✅ TEST 1.2 PASS — Trigger đã chặn: ' || v_error_msg);
        ELSE
            DBMS_OUTPUT.PUT_LINE('⚠️ TEST 1.2 — Lỗi khác: ' || v_error_msg);
        END IF;
END;
/

PROMPT 🧪 TEST 1.3: Tạo đơn hàng cho khách ACTIVE (ID=1) → Expect: OK
DECLARE
    v_new_id NUMBER;
BEGIN
    INSERT INTO ORDERS (customer_id, total_amount, status, shipping_address, payment_method)
    VALUES (1, 50000, 'PENDING', N'Quận 1, TP.HCM', 'COD')
    RETURNING order_id INTO v_new_id;

    DBMS_OUTPUT.PUT_LINE('✅ TEST 1.3 PASS — Đơn hàng mới ID = ' || v_new_id);

    -- Dọn dẹp đơn test
    DELETE FROM ORDERS WHERE order_id = v_new_id;
    COMMIT;
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST TRIGGER 2: trg_sync_order_total (Nam)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 2.1: Thêm chi tiết đơn hàng → total_amount sẽ tự cập nhật
DECLARE
    v_order_id      NUMBER;
    v_old_total     NUMBER;
    v_new_total     NUMBER;
BEGIN
    -- Lấy đơn hàng 7 (PENDING, hiện tại có dữ liệu)
    SELECT total_amount INTO v_old_total FROM ORDERS WHERE order_id = 7;
    DBMS_OUTPUT.PUT_LINE('   📦 total_amount TRƯỚC: ' || TO_CHAR(v_old_total, '999,999,999') || ' VNĐ');

    -- Thêm 1 dòng chi tiết: sách ID=3 (Đắc Nhân Tâm, 76000) x 1
    INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price)
    VALUES (7, 3, 1, 76000);

    -- Kiểm tra total_amount đã được cập nhật tự động chưa
    SELECT total_amount INTO v_new_total FROM ORDERS WHERE order_id = 7;
    DBMS_OUTPUT.PUT_LINE('   📦 total_amount SAU : ' || TO_CHAR(v_new_total, '999,999,999') || ' VNĐ');

    IF v_new_total > v_old_total THEN
        DBMS_OUTPUT.PUT_LINE('✅ TEST 2.1 PASS — total_amount đã tự động cập nhật!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ TEST 2.1 FAIL — total_amount không thay đổi!');
    END IF;

    -- Dọn dẹp: xóa dòng chi tiết vừa thêm
    DELETE FROM ORDER_DETAILS WHERE order_id = 7 AND book_id = 3;
    COMMIT;
END;
/

-- ────────────────────────────────────────────────────────────────────
-- TEST TRIGGER 3: trg_audit_books (Hiếu)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 🧪 TEST 3.1: Cập nhật giá sách → AUDIT_LOG sẽ ghi nhận
DECLARE
    v_log_count_before  NUMBER;
    v_log_count_after   NUMBER;
BEGIN
    -- Đếm số log hiện tại
    SELECT COUNT(*) INTO v_log_count_before FROM AUDIT_LOG;

    -- Cập nhật giá sách ID=1 (Mắt Biếc)
    UPDATE BOOKS SET price = 135000 WHERE book_id = 1;

    -- Đếm lại log
    SELECT COUNT(*) INTO v_log_count_after FROM AUDIT_LOG;

    IF v_log_count_after > v_log_count_before THEN
        DBMS_OUTPUT.PUT_LINE('✅ TEST 3.1 PASS — AUDIT_LOG đã ghi nhận thay đổi!');
        DBMS_OUTPUT.PUT_LINE('   📝 Số log mới: ' || (v_log_count_after - v_log_count_before));
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ TEST 3.1 FAIL — AUDIT_LOG không ghi nhận!');
    END IF;

    -- Khôi phục giá gốc
    UPDATE BOOKS SET price = 110000 WHERE book_id = 1;
    COMMIT;
END;
/

PROMPT 🧪 TEST 3.2: Hiển thị nội dung AUDIT_LOG
SELECT log_id, operation, record_id, column_changed,
       SUBSTR(old_value, 1, 30) AS old_val,
       SUBSTR(new_value, 1, 30) AS new_val,
       changed_by,
       TO_CHAR(changed_at, 'DD/MM/YYYY HH24:MI:SS') AS changed_at
FROM AUDIT_LOG
ORDER BY log_id;

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 5 HOÀN TẤT — TẠO 3 TRIGGERS NGHIỆP VỤ THÀNH CÔNG!
PROMPT ================================================================
PROMPT    ⚡ Trigger 1: trg_validate_order   (Dũng)
PROMPT       → BEFORE INSERT/UPDATE trên ORDERS
PROMPT       → Validate khách hàng ACTIVE, kiểm tra luồng trạng thái
PROMPT    ⚡ Trigger 2: trg_sync_order_total  (Nam)
PROMPT       → COMPOUND TRIGGER trên ORDER_DETAILS
PROMPT       → Tự động tính lại total_amount (tránh Mutating Table)
PROMPT    ⚡ Trigger 3: trg_audit_books       (Hiếu)
PROMPT       → AFTER INSERT/UPDATE/DELETE trên BOOKS
PROMPT       → Ghi vết lịch sử vào bảng AUDIT_LOG
PROMPT ================================================================
PROMPT    📋 Bảng phụ trợ: AUDIT_LOG (lưu vết thao tác)
PROMPT    🔢 Sequence: seq_audit_log
PROMPT ================================================================
