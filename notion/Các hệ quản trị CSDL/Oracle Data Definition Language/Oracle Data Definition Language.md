# Oracle Data Definition Language

```SQL
/* =====================================================
   1. CREATE USER & GRANT PRIVILEGES
   ===================================================== */

-- Chạy bằng SYS hoặc SYSTEM

CREATE USER iotsmart IDENTIFIED BY iotsmart123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE TO iotsmart;
GRANT CREATE VIEW TO iotsmart;
GRANT CREATE SEQUENCE TO iotsmart;
GRANT CREATE TRIGGER TO iotsmart;
GRANT CREATE PROCEDURE TO iotsmart;

-- Sau đó đăng nhập bằng user iotsmart
-- CONNECT iotsmart/iotsmart123;
```

```SQL
/* =====================================================
   2. MASTER DATA MODULE
   ===================================================== */

CREATE TABLE store (
    store_id NUMBER(10) PRIMARY KEY,
    store_name VARCHAR2(100) NOT NULL,
    address VARCHAR2(255),
    phone VARCHAR2(20),
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    created_at DATE DEFAULT SYSDATE,
    CONSTRAINT chk_store_status CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE warehouse (
    warehouse_id NUMBER(10) PRIMARY KEY,
    store_id NUMBER(10) NOT NULL,
    warehouse_name VARCHAR2(100) NOT NULL,
    location_note VARCHAR2(100),
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    CONSTRAINT fk_wh_store FOREIGN KEY (store_id)
        REFERENCES store(store_id)
);

CREATE TABLE product (
    product_id NUMBER(10) PRIMARY KEY,
    sku VARCHAR2(50) NOT NULL,
    product_name VARCHAR2(200) NOT NULL,
    category VARCHAR2(100),
    purchase_price NUMBER(12,2) NOT NULL,
    selling_price NUMBER(12,2) NOT NULL,
    min_stock_level NUMBER(10) DEFAULT 0,
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    created_at DATE DEFAULT SYSDATE,
    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT chk_product_status CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE customer (
    customer_id NUMBER(10) PRIMARY KEY,
    customer_name VARCHAR2(150) NOT NULL,
    phone VARCHAR2(20),
    email VARCHAR2(150),
    customer_type VARCHAR2(20),
    created_at DATE DEFAULT SYSDATE
);

CREATE TABLE employee (
    employee_id NUMBER(10) PRIMARY KEY,
    store_id NUMBER(10) NOT NULL,
    full_name VARCHAR2(150) NOT NULL,
    role VARCHAR2(50),
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    hired_date DATE,
    CONSTRAINT fk_emp_store FOREIGN KEY (store_id)
        REFERENCES store(store_id)
);


/* =====================================================
   3. INVENTORY MODULE
   ===================================================== */

CREATE TABLE stock (
    warehouse_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity_on_hand NUMBER(12) DEFAULT 0 NOT NULL,
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT pk_stock PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_stock_wh FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(warehouse_id),
    CONSTRAINT fk_stock_product FOREIGN KEY (product_id)
        REFERENCES product(product_id),
    CONSTRAINT chk_stock_qty CHECK (quantity_on_hand >= 0)
);

CREATE TABLE inventory_transaction (
    txn_id NUMBER(12) PRIMARY KEY,
    warehouse_id NUMBER(10) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    txn_type VARCHAR2(20) NOT NULL,
    quantity_change NUMBER(12) NOT NULL,
    reference_type VARCHAR2(20),
    reference_id NUMBER(12),
    employee_id NUMBER(10),
    created_at DATE DEFAULT SYSDATE,
    CONSTRAINT fk_inv_wh FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(warehouse_id),
    CONSTRAINT fk_inv_product FOREIGN KEY (product_id)
        REFERENCES product(product_id),
    CONSTRAINT fk_inv_employee FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
);


/* =====================================================
   4. SALES MODULE
   ===================================================== */

CREATE TABLE sales_order (
    order_id NUMBER(12) PRIMARY KEY,
    store_id NUMBER(10) NOT NULL,
    customer_id NUMBER(10) NOT NULL,
    order_date DATE DEFAULT SYSDATE,
    order_channel VARCHAR2(20) NOT NULL,
    order_status VARCHAR2(20) DEFAULT 'DRAFT',
    total_amount NUMBER(14,2),
    CONSTRAINT fk_order_store FOREIGN KEY (store_id)
        REFERENCES store(store_id),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
);

CREATE TABLE sales_order_detail (
    order_id NUMBER(12) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity NUMBER(10) NOT NULL,
    unit_price NUMBER(12,2) NOT NULL,
    line_total NUMBER(14,2),
    CONSTRAINT pk_sod PRIMARY KEY (order_id, product_id),
    CONSTRAINT fk_sod_order FOREIGN KEY (order_id)
        REFERENCES sales_order(order_id),
    CONSTRAINT fk_sod_product FOREIGN KEY (product_id)
        REFERENCES product(product_id)
);


/* =====================================================
   5. ONLINE EXTENSION
   ===================================================== */

CREATE TABLE cart (
    cart_id NUMBER(12) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    created_at DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'OPEN',
    CONSTRAINT fk_cart_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
);

CREATE TABLE cart_item (
    cart_id NUMBER(12) NOT NULL,
    product_id NUMBER(10) NOT NULL,
    quantity NUMBER(10) NOT NULL,
    unit_price NUMBER(12,2),
    CONSTRAINT pk_cart_item PRIMARY KEY (cart_id, product_id),
    CONSTRAINT fk_ci_cart FOREIGN KEY (cart_id)
        REFERENCES cart(cart_id),
    CONSTRAINT fk_ci_product FOREIGN KEY (product_id)
        REFERENCES product(product_id)
);

CREATE TABLE payment (
    payment_id NUMBER(12) PRIMARY KEY,
    order_id NUMBER(12) NOT NULL,
    customer_id NUMBER(10) NOT NULL,
    amount NUMBER(14,2) NOT NULL,
    payment_method VARCHAR2(50),
    payment_status VARCHAR2(20),
    paid_at DATE,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES sales_order(order_id),
    CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
);

CREATE TABLE shipment (
    shipment_id NUMBER(12) PRIMARY KEY,
    order_id NUMBER(12) NOT NULL,
    shipping_address VARCHAR2(255),
    shipping_status VARCHAR2(20),
    shipped_at DATE,
    delivered_at DATE,
    CONSTRAINT fk_shipment_order FOREIGN KEY (order_id)
        REFERENCES sales_order(order_id)
);


/* =====================================================
   6. INVOICE & TAX
   ===================================================== */

CREATE TABLE tax_rate (
    tax_code VARCHAR2(20) PRIMARY KEY,
    tax_percentage NUMBER(5,2) NOT NULL,
    effective_date DATE NOT NULL
);

CREATE TABLE invoice (
    invoice_id NUMBER(12) PRIMARY KEY,
    order_id NUMBER(12) NOT NULL,
    invoice_number VARCHAR2(50) NOT NULL,
    issue_date DATE DEFAULT SYSDATE,
    vat_amount NUMBER(14,2),
    total_with_vat NUMBER(14,2),
    invoice_status VARCHAR2(20),
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id)
        REFERENCES sales_order(order_id)
);


/* =====================================================
   7. AUDIT & CONTROL
   ===================================================== */

CREATE TABLE error_log (
    error_id NUMBER(12) PRIMARY KEY,
    module_name VARCHAR2(100),
    error_message VARCHAR2(4000),
    created_at DATE DEFAULT SYSDATE
);


/* =====================================================
   8. SEQUENCES
   ===================================================== */

CREATE SEQUENCE seq_store START WITH 1;
CREATE SEQUENCE seq_warehouse START WITH 1;
CREATE SEQUENCE seq_product START WITH 1;
CREATE SEQUENCE seq_customer START WITH 1;
CREATE SEQUENCE seq_employee START WITH 1;
CREATE SEQUENCE seq_order START WITH 1;
CREATE SEQUENCE seq_txn START WITH 1;
CREATE SEQUENCE seq_invoice START WITH 1;
CREATE SEQUENCE seq_payment START WITH 1;
CREATE SEQUENCE seq_cart START WITH 1;
CREATE SEQUENCE seq_shipment START WITH 1;
CREATE SEQUENCE seq_error START WITH 1;
```

