# IoTSmart - PACKAGE INVENTORY

Nhiệm vụ chính:

1. Kiểm soát xuất kho (issue_stock)
1. Kiểm soát nhập kho (receive_stock)
1. Đảm bảo không âm tồn
1. Ghi inventory_transaction
1. Lock row khi concurrent access
```SQL
CREATE OR REPLACE PACKAGE pkg_inventory AS

    PROCEDURE issue_stock(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER,
        p_quantity     IN NUMBER,
        p_employee_id  IN NUMBER
    );

    PROCEDURE receive_stock(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER,
        p_quantity     IN NUMBER,
        p_employee_id  IN NUMBER
    );

    FUNCTION get_stock_balance(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER
    ) RETURN NUMBER;

END pkg_inventory;
/
```

```SQL
CREATE OR REPLACE PACKAGE BODY pkg_inventory AS

    FUNCTION get_stock_balance(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER
    ) RETURN NUMBER
    AS
        v_qty NUMBER;
    BEGIN
        SELECT quantity_on_hand
        INTO v_qty
        FROM stock
        WHERE warehouse_id = p_warehouse_id
        AND product_id = p_product_id;

        RETURN v_qty;
    END;

    PROCEDURE issue_stock(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER,
        p_quantity     IN NUMBER,
        p_employee_id  IN NUMBER
    )
    AS
        v_current_qty NUMBER;
    BEGIN
        SELECT quantity_on_hand
        INTO v_current_qty
        FROM stock
        WHERE warehouse_id = p_warehouse_id
        AND product_id = p_product_id
        FOR UPDATE;

        IF v_current_qty < p_quantity THEN
            RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock');
        END IF;

        UPDATE stock
        SET quantity_on_hand = quantity_on_hand - p_quantity,
            last_updated = SYSDATE
        WHERE warehouse_id = p_warehouse_id
        AND product_id = p_product_id;

        INSERT INTO inventory_transaction
        VALUES (
            seq_txn.NEXTVAL,
            p_warehouse_id,
            p_product_id,
            'ISSUE',
            -p_quantity,
            'ORDER',
            NULL,
            p_employee_id,
            SYSDATE
        );

    END;

    PROCEDURE receive_stock(
        p_warehouse_id IN NUMBER,
        p_product_id   IN NUMBER,
        p_quantity     IN NUMBER,
        p_employee_id  IN NUMBER
    )
    AS
    BEGIN
        UPDATE stock
        SET quantity_on_hand = quantity_on_hand + p_quantity,
            last_updated = SYSDATE
        WHERE warehouse_id = p_warehouse_id
        AND product_id = p_product_id;

        INSERT INTO inventory_transaction
        VALUES (
            seq_txn.NEXTVAL,
            p_warehouse_id,
            p_product_id,
            'RECEIVE',
            p_quantity,
            'PURCHASE',
            NULL,
            p_employee_id,
            SYSDATE
        );

    END;

END pkg_inventory;
/
```

