-- ==========================================================
-- FILE: 5_triggers.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Xây dựng 3 Trigger nghiệp vụ chuyên sâu
-- ==========================================================

-- ==========================================================
-- Trigger 1 (Dũng) - VALIDATION BEFORE INSERT/UPDATE
-- Bảng tác động: ORDERS
-- Mục tiêu:
--   1) Kiểm tra logic số tiền và ngày tháng.
--   2) Chuẩn hóa một số cột mặc định tránh dữ liệu null.
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_biu_orders_validation
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
BEGIN
    -- Chuẩn hóa các giá trị tiền tệ mặc định.
    :NEW.total_amount := NVL(:NEW.total_amount, 0);
    :NEW.discount_amount := NVL(:NEW.discount_amount, 0);
    :NEW.shipping_fee := NVL(:NEW.shipping_fee, 0);
    :NEW.final_amount := NVL(:NEW.final_amount, 0);

    -- Tự động cập nhật thời gian chỉnh sửa cho thao tác UPDATE.
    IF UPDATING THEN
        :NEW.updated_at := SYSDATE;
    END IF;

    -- Kiểm tra số tiền không âm và final phải khớp công thức.
    IF :NEW.total_amount < 0 OR :NEW.discount_amount < 0 OR :NEW.shipping_fee < 0 OR :NEW.final_amount < 0 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Gia tri tien te trong ORDERS khong duoc am.');
    END IF;

    IF ROUND(:NEW.final_amount, 2) <> ROUND(:NEW.total_amount - :NEW.discount_amount + :NEW.shipping_fee, 2) THEN
        RAISE_APPLICATION_ERROR(-20502, 'final_amount phai = total_amount - discount_amount + shipping_fee.');
    END IF;

    -- Kiểm tra trạng thái giao hàng theo timeline nghiệp vụ.
    IF :NEW.delivered_at IS NOT NULL AND :NEW.shipped_at IS NULL THEN
        RAISE_APPLICATION_ERROR(-20503, 'Khong the co delivered_at khi chua co shipped_at.');
    END IF;

    IF :NEW.cancelled_at IS NOT NULL AND :NEW.status_code <> 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20504, 'cancelled_at chi hop le khi status_code = CANCELLED.');
    END IF;

    IF :NEW.status_code = 'CANCELLED' AND :NEW.cancelled_at IS NULL THEN
        :NEW.cancelled_at := SYSDATE;
    END IF;
END;
/

-- ==========================================================
-- Trigger 2 (Nam) - AFTER INSERT/UPDATE/DELETE
-- Bảng nguồn: BRANCH_INVENTORY
-- Bảng đích: BOOKS
-- Mục tiêu: Đồng bộ cột denormalized books.stock_quantity
-- Công thức: SUM(quantity_available) theo toàn bộ chi nhánh cho từng book
-- Kỹ thuật: COMPOUND TRIGGER để tránh lỗi mutating table (ORA-04091)
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_aiud_branch_inventory_sync_book_stock
FOR INSERT OR UPDATE OR DELETE ON branch_inventory
COMPOUND TRIGGER
    TYPE t_book_map IS TABLE OF NUMBER INDEX BY VARCHAR2(40);
    g_book_ids t_book_map;

    PROCEDURE mark_book(p_book_id IN NUMBER) IS
    BEGIN
        IF p_book_id IS NOT NULL THEN
            g_book_ids(TO_CHAR(p_book_id)) := p_book_id;
        END IF;
    END mark_book;

AFTER EACH ROW IS
BEGIN
    -- Gom các book_id bị ảnh hưởng trong statement hiện tại.
    IF INSERTING OR UPDATING THEN
        mark_book(:NEW.book_id);
    END IF;

    IF DELETING OR UPDATING THEN
        mark_book(:OLD.book_id);
    END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_key          VARCHAR2(40);
    v_book_id      NUMBER;
    v_total_stock  NUMBER;
BEGIN
    -- Chỉ đọc branch_inventory ở mức statement để tránh mutating table.
    v_key := g_book_ids.FIRST;
    WHILE v_key IS NOT NULL LOOP
        v_book_id := g_book_ids(v_key);

        SELECT NVL(SUM(quantity_available), 0)
          INTO v_total_stock
          FROM branch_inventory
         WHERE book_id = v_book_id;

        UPDATE books
           SET stock_quantity = v_total_stock,
               updated_at = SYSDATE
         WHERE book_id = v_book_id;

        v_key := g_book_ids.NEXT(v_key);
    END LOOP;
END AFTER STATEMENT;
END trg_aiud_branch_inventory_sync_book_stock;
/

-- ==========================================================
-- Trigger 3 (Hiếu) - AUDIT LOG AFTER INSERT/UPDATE/DELETE
-- Bảng tác động: ORDERS
-- Mục tiêu: Lưu vết thay đổi trạng thái/số tiền của đơn hàng
-- ==========================================================

-- Tạo sequence cho audit log (idempotent).
BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_orders_audit_log START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -955 THEN
            RAISE;
        END IF;
END;
/

-- Tạo bảng audit log (idempotent).
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE orders_audit_log (
            audit_id            NUMBER PRIMARY KEY,
            order_id            NUMBER NOT NULL,
            action_type         VARCHAR2(10) NOT NULL,
            old_status_code     VARCHAR2(20),
            new_status_code     VARCHAR2(20),
            old_final_amount    NUMBER(12,2),
            new_final_amount    NUMBER(12,2),
            old_discount_amount NUMBER(12,2),
            new_discount_amount NUMBER(12,2),
            old_shipping_fee    NUMBER(10,2),
            new_shipping_fee    NUMBER(10,2),
            action_by           VARCHAR2(128) DEFAULT USER NOT NULL,
            action_at           DATE DEFAULT SYSDATE NOT NULL,
            module_name         VARCHAR2(64),
            client_identifier   VARCHAR2(64),
            ip_address          VARCHAR2(64),
            note                NVARCHAR2(500)
        )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -955 THEN
            RAISE;
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_aiud_orders_audit
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
DECLARE
    v_action_type VARCHAR2(10);
BEGIN
    -- Xác định loại thao tác để ghi log.
    IF INSERTING THEN
        v_action_type := 'INSERT';
    ELSIF UPDATING THEN
        v_action_type := 'UPDATE';
    ELSE
        v_action_type := 'DELETE';
    END IF;

    INSERT INTO orders_audit_log (
        audit_id,
        order_id,
        action_type,
        old_status_code,
        new_status_code,
        old_final_amount,
        new_final_amount,
        old_discount_amount,
        new_discount_amount,
        old_shipping_fee,
        new_shipping_fee,
        action_by,
        action_at,
        module_name,
        client_identifier,
        ip_address,
        note
    )
    VALUES (
        seq_orders_audit_log.NEXTVAL,
        COALESCE(:NEW.order_id, :OLD.order_id),
        v_action_type,
        :OLD.status_code,
        :NEW.status_code,
        :OLD.final_amount,
        :NEW.final_amount,
        :OLD.discount_amount,
        :NEW.discount_amount,
        :OLD.shipping_fee,
        :NEW.shipping_fee,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYSDATE,
        SYS_CONTEXT('USERENV', 'MODULE'),
        SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        N'Audit tu trigger trg_aiud_orders_audit'
    );
END;
/

-- ==========================================================
-- KẾT THÚC FILE 5_triggers.sql
-- ==========================================================
