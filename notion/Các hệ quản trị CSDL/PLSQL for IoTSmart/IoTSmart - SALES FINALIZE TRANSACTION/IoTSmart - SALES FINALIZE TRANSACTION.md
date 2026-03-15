# IoTSmart - SALES FINALIZE TRANSACTION

```SQL
-- Specification

CREATE OR REPLACE PACKAGE pkg_sales_support AS

    PROCEDURE finalize_order(
        p_order_id    IN NUMBER,
        p_employee_id IN NUMBER
    );

END pkg_sales_support;
/


-- Body

CREATE OR REPLACE PACKAGE BODY pkg_sales_support AS

    PROCEDURE finalize_order(
        p_order_id    IN NUMBER,
        p_employee_id IN NUMBER
    )
    AS
    BEGIN
        FOR rec IN (
            SELECT product_id, quantity
            FROM sales_order_detail
            WHERE order_id = p_order_id
        )
        LOOP
            pkg_inventory.issue_stock(
                p_warehouse_id => 1,
                p_product_id   => rec.product_id,
                p_quantity     => rec.quantity,
                p_employee_id  => p_employee_id
            );
        END LOOP;

        UPDATE sales_order
        SET order_status = 'COMPLETED'
        WHERE order_id = p_order_id;

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END;

END pkg_sales_support;
/
```

