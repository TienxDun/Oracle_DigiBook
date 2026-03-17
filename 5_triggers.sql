-- ==========================================================
-- FILE: 5_triggers.sql
-- Mục tiêu: Xây dựng 3 trigger nghiệp vụ chuyên sâu cho Oracle 19c
-- Chủ đề: DigiBook
--
-- Trigger 1 (Dũng): Validation BEFORE INSERT/UPDATE trên ORDERS
-- Trigger 2 (Nam): Tự động tính/cập nhật tổng tiền ORDER từ ORDER_DETAILS
--                    bằng COMPOUND TRIGGER để tránh mutating table
-- Trigger 3 (Hiếu): Audit log lịch sử thao tác trên ORDERS
-- ==========================================================

-- ==========================================================
-- [Dũng] TRIGGER 1: Validation BEFORE INSERT/UPDATE
-- Bảng tác động: ORDERS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_biu_orders_validate
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
BEGIN
    -- Tự động cập nhật thời gian cập nhật cho bản ghi đơn hàng
    :NEW.updated_at := SYSDATE;

    -- Chuẩn hóa địa chỉ giao hàng và kiểm tra độ dài tối thiểu
    IF :NEW.shipping_address IS NOT NULL THEN
        :NEW.shipping_address := TRIM(:NEW.shipping_address);
    END IF;

    IF :NEW.shipping_address IS NULL OR LENGTH(:NEW.shipping_address) < 10 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Dia chi giao hang phai co it nhat 10 ky tu.');
    END IF;

    -- Khi đơn đã xác nhận trở lên thì bắt buộc phải có phương thức thanh toán
    IF :NEW.status IN ('CONFIRMED', 'SHIPPING', 'DELIVERED') AND :NEW.payment_method IS NULL THEN
        RAISE_APPLICATION_ERROR(-20502, 'Don hang da xac nhan phai co payment_method.');
    END IF;

    -- Không cho phép đơn DELIVERED nhưng payment_status chưa PAID
    IF :NEW.status = 'DELIVERED' AND :NEW.payment_status <> 'PAID' THEN
        RAISE_APPLICATION_ERROR(-20503, 'Don DELIVERED bat buoc payment_status = PAID.');
    END IF;

    -- Chuẩn hóa trị mặc định để tránh null gây sai lệch nghiệp vụ
    IF :NEW.shipping_fee IS NULL THEN
        :NEW.shipping_fee := 0;
    END IF;

    IF :NEW.discount_amount IS NULL THEN
        :NEW.discount_amount := 0;
    END IF;

    IF :NEW.total_amount IS NULL THEN
        :NEW.total_amount := 0;
    END IF;
END;
/

-- ==========================================================
-- [Nam] TRIGGER 2: AFTER INSERT/UPDATE/DELETE tính lại total_amount
-- Bảng nguồn: ORDER_DETAILS
-- Bảng đích: ORDERS
-- Kỹ thuật: COMPOUND TRIGGER để gom order_id theo statement
--           rồi cập nhật cuối statement, tránh mutating table.
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_aiud_order_details_recalc_order
FOR INSERT OR UPDATE OR DELETE ON order_details
COMPOUND TRIGGER
    TYPE t_order_map IS TABLE OF NUMBER INDEX BY VARCHAR2(40);
    g_order_ids t_order_map;

    PROCEDURE mark_order(p_order_id IN NUMBER) IS
    BEGIN
        IF p_order_id IS NOT NULL THEN
            g_order_ids(TO_CHAR(p_order_id)) := p_order_id;
        END IF;
    END mark_order;

AFTER EACH ROW IS
BEGIN
    -- Gom danh sách order_id bị ảnh hưởng trong cùng câu lệnh DML
    IF INSERTING OR UPDATING THEN
        mark_order(:NEW.order_id);
    END IF;

    IF DELETING OR UPDATING THEN
        mark_order(:OLD.order_id);
    END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
    v_key            VARCHAR2(40);
    v_order_id       NUMBER;
    v_items_total    NUMBER(12,2);
    v_shipping_fee   NUMBER(10,2);
    v_discount_amt   NUMBER(10,2);
BEGIN
    -- Duyệt từng order_id đã gom để tính lại tổng tiền cuối cùng
    v_key := g_order_ids.FIRST;
    WHILE v_key IS NOT NULL LOOP
        v_order_id := g_order_ids(v_key);

        SELECT NVL(SUM(od.quantity * od.unit_price), 0)
          INTO v_items_total
          FROM order_details od
         WHERE od.order_id = v_order_id;

        SELECT NVL(o.shipping_fee, 0), NVL(o.discount_amount, 0)
          INTO v_shipping_fee, v_discount_amt
          FROM orders o
         WHERE o.order_id = v_order_id
           FOR UPDATE;

        UPDATE orders
           SET total_amount = GREATEST(v_items_total + v_shipping_fee - v_discount_amt, 0),
               updated_at = SYSDATE
         WHERE order_id = v_order_id;

        v_key := g_order_ids.NEXT(v_key);
    END LOOP;
END AFTER STATEMENT;
END trg_aiud_order_details_recalc_order;
/

-- ==========================================================
-- [Hiếu] TRIGGER 3: Audit log thao tác INSERT/UPDATE/DELETE trên ORDERS
-- Tạo bảng log + sequence phục vụ lưu vết thay đổi
-- ==========================================================

-- Tạo sequence cho bảng audit (idempotent)
BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_orders_audit_log START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -955 THEN
            RAISE;
        END IF;
END;
/

-- Tạo bảng audit (idempotent)
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE orders_audit_log (
            audit_id            NUMBER PRIMARY KEY,
            order_id            NUMBER,
            action_type         VARCHAR2(10) NOT NULL,
            old_status          VARCHAR2(20),
            new_status          VARCHAR2(20),
            old_total_amount    NUMBER(12,2),
            new_total_amount    NUMBER(12,2),
            old_payment_status  VARCHAR2(20),
            new_payment_status  VARCHAR2(20),
            action_by           VARCHAR2(128) DEFAULT USER NOT NULL,
            action_at           DATE DEFAULT SYSDATE NOT NULL,
            module_name         VARCHAR2(64),
            client_identifier   VARCHAR2(64),
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
    -- Xác định loại hành động đang xảy ra trên bản ghi ORDERS
    IF INSERTING THEN
        v_action_type := 'INSERT';
    ELSIF UPDATING THEN
        v_action_type := 'UPDATE';
    ELSE
        v_action_type := 'DELETE';
    END IF;

    -- Ghi nhật ký đầy đủ trạng thái trước/sau để phục vụ truy vết lịch sử
    INSERT INTO orders_audit_log (
        audit_id,
        order_id,
        action_type,
        old_status,
        new_status,
        old_total_amount,
        new_total_amount,
        old_payment_status,
        new_payment_status,
        action_by,
        action_at,
        module_name,
        client_identifier,
        note
    )
    VALUES (
        seq_orders_audit_log.NEXTVAL,
        NVL(:NEW.order_id, :OLD.order_id),
        v_action_type,
        :OLD.status,
        :NEW.status,
        :OLD.total_amount,
        :NEW.total_amount,
        :OLD.payment_status,
        :NEW.payment_status,
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYSDATE,
        SYS_CONTEXT('USERENV', 'MODULE'),
        SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
        'Audit tu trigger trg_aiud_orders_audit'
    );
END;
/

-- ==========================================================
-- KẾT THÚC FILE
-- ==========================================================
