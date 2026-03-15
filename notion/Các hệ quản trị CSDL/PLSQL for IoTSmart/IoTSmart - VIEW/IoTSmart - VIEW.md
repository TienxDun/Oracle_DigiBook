# IoTSmart - VIEW

## 1. View tồn kho realtime theo cửa hàng

View tổng hợp tồn kho theo store/warehouse/product, giúp đọc tồn realtime và cảnh báo mức tồn thấp mà không cần join nhiều bảng ở application.

```SQL
CREATE OR REPLACE VIEW v_stock_overview AS
    SELECT
        s.store_id,
        w.warehouse_id,
        p.product_id,
        p.product_name,
        st.quantity_on_hand,
        p.min_stock_level,

        CASE
            WHEN st.quantity_on_hand<= p.min_stock_level
                THEN'LOW_STOCK'
            ELSE'OK'
        END AS stock_status

    FROM stock st
    JOIN warehouse w ON st.warehouse_id= w.warehouse_id
    JOIN store s ON w.store_id= s.store_id
    JOIN product p ON st.product_id= p.product_id;
```

## 2. View doanh thu theo đơn

View gom `sales_order` và `sales_order_detail` để tính tổng tiền mỗi đơn, cung cấp read-model chuẩn cho báo cáo và dashboard.

```SQL
CREATE OR REPLACE VIEW v_order_summary AS
    SELECT
        o.order_id,
        o.store_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        SUM(d.line_total) AS total_amount
    FROM sales_order o
    JOIN sales_order_detail d
    ON o.order_id= d.order_id
    GROUP BY
        o.order_id,
        o.store_id,
        o.customer_id,
        o.order_date,
        o.order_status;

```

