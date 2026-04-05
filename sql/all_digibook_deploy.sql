ALTER SESSION SET CONTAINER = ORCLPDB;
CREATE USER DIGIBOOK IDENTIFIED BY "Digibook@123"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
GRANT CONNECT, RESOURCE TO DIGIBOOK;
ALTER USER DIGIBOOK QUOTA UNLIMITED ON USERS;
GRANT UNLIMITED TABLESPACE TO DIGIBOOK;
GRANT CREATE VIEW TO DIGIBOOK;
GRANT CREATE SEQUENCE TO DIGIBOOK;
GRANT CREATE TRIGGER TO DIGIBOOK;
GRANT CREATE PROCEDURE TO DIGIBOOK;
GRANT CREATE MATERIALIZED VIEW TO DIGIBOOK;

CREATE SEQUENCE seq_branches START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_staff START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_categories START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_authors START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_publishers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_books START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_book_images START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_book_authors START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; 
CREATE SEQUENCE seq_customers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_shipping_methods START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_details START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_status_his START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; 
CREATE SEQUENCE seq_carts START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_cart_items START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_branch_inventory START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_inventory_transfers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_transfer_details START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; 
CREATE SEQUENCE seq_inventory_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_payment_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_coupons START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_reviews START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_wishlists START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE branches (
    branch_id           NUMBER,
    branch_code         VARCHAR2(20) NOT NULL,
    branch_name         NVARCHAR2(100) NOT NULL,
    branch_type         VARCHAR2(20) DEFAULT 'STORE' NOT NULL,
    address             NVARCHAR2(500) NOT NULL,
    province            NVARCHAR2(50),
    district            NVARCHAR2(50),
    ward                NVARCHAR2(50),
    phone               VARCHAR2(15) NOT NULL,
    email               VARCHAR2(150),
    manager_id          NUMBER, 
    opening_date        DATE,
    status              VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
    is_main_branch      NUMBER(1) DEFAULT 0,
    tax_code            VARCHAR2(50),
    latitude            NUMBER(10,6),
    longitude           NUMBER(10,6),
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_branches PRIMARY KEY (branch_id),
    CONSTRAINT uq_branch_code UNIQUE (branch_code),
    CONSTRAINT ck_branch_type CHECK (branch_type IN ('STORE', 'WAREHOUSE', 'ONLINE_ONLY')),
    CONSTRAINT ck_branch_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED')),
    CONSTRAINT ck_branch_is_main CHECK (is_main_branch IN (0, 1))
);

CREATE TABLE order_statuses (
    status_code         VARCHAR2(20),
    status_name         NVARCHAR2(50) NOT NULL,
    status_name_vi      NVARCHAR2(50) NOT NULL,
    description         NVARCHAR2(200),
    display_order       NUMBER NOT NULL,
    color_code          VARCHAR2(7) DEFAULT '#000000',
    is_terminal         NUMBER(1) DEFAULT 0,
    allowed_next_status VARCHAR2(200), 
    require_payment     NUMBER(1) DEFAULT 0,
    is_active           NUMBER(1) DEFAULT 1,
    CONSTRAINT pk_order_statuses PRIMARY KEY (status_code),
    CONSTRAINT ck_osts_is_terminal CHECK (is_terminal IN (0, 1)),
    CONSTRAINT ck_osts_require_payment CHECK (require_payment IN (0, 1)),
    CONSTRAINT ck_osts_is_active CHECK (is_active IN (0, 1))
);

CREATE TABLE users (
    user_id          NUMBER,
    username         VARCHAR2(50) NOT NULL,
    email            VARCHAR2(150) NOT NULL,
    password_hash    VARCHAR2(256) NOT NULL,
    full_name        NVARCHAR2(100) NOT NULL,
    role             VARCHAR2(20) DEFAULT 'STAFF' NOT NULL,
    phone            VARCHAR2(15),
    avatar_url       VARCHAR2(500),
    is_active        NUMBER(1) DEFAULT 1 NOT NULL,
    last_login_at    DATE,
    created_by       NUMBER,
    created_at       DATE DEFAULT SYSDATE,
    updated_at       DATE,
    updated_by       NUMBER,
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_role CHECK (role IN ('ADMIN', 'MANAGER', 'STAFF', 'SUPPORT')),
    CONSTRAINT ck_users_is_active CHECK (is_active IN (0, 1))
);

CREATE TABLE staff (
    staff_id            NUMBER,
    user_id             NUMBER NOT NULL,
    branch_id           NUMBER NOT NULL,
    staff_code          VARCHAR2(20) NOT NULL,
    job_title           NVARCHAR2(50),
    department          VARCHAR2(30),
    hire_date           DATE NOT NULL,
    resignation_date    DATE,
    base_salary         NUMBER(12,2),
    status              VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
    can_approve_order   NUMBER(1) DEFAULT 0,
    can_manage_stock    NUMBER(1) DEFAULT 0,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT uq_staff_code UNIQUE (staff_code),
    CONSTRAINT fk_staff_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_staff_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT ck_staff_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    CONSTRAINT ck_staff_approve CHECK (can_approve_order IN (0, 1)),
    CONSTRAINT ck_staff_stock CHECK (can_manage_stock IN (0, 1))
);

ALTER TABLE branches ADD CONSTRAINT fk_branch_manager 
    FOREIGN KEY (manager_id) REFERENCES staff(staff_id);

ALTER TABLE users ADD CONSTRAINT fk_users_created_by 
    FOREIGN KEY (created_by) REFERENCES users(user_id);
ALTER TABLE users ADD CONSTRAINT fk_users_updated_by 
    FOREIGN KEY (updated_by) REFERENCES users(user_id);

CREATE TABLE categories (
    category_id         NUMBER,
    category_name       NVARCHAR2(100) NOT NULL,
    parent_id           NUMBER,
    description         NVARCHAR2(500),
    image_url           VARCHAR2(500),
    display_order       NUMBER DEFAULT 0,
    is_active           NUMBER(1) DEFAULT 1,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name),
    CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES categories(category_id),
    CONSTRAINT ck_cat_is_active CHECK (is_active IN (0, 1))
);

CREATE TABLE authors (
    author_id           NUMBER,
    author_name         NVARCHAR2(150) NOT NULL,
    biography           NCLOB,
    birth_date          DATE,
    nationality         NVARCHAR2(50),
    created_at          DATE DEFAULT SYSDATE,
    CONSTRAINT pk_authors PRIMARY KEY (author_id)
);

CREATE TABLE publishers (
    publisher_id        NUMBER,
    publisher_name      NVARCHAR2(200) NOT NULL,
    address             NVARCHAR2(500),
    phone               VARCHAR2(15),
    email               VARCHAR2(150),
    website             VARCHAR2(200),
    CONSTRAINT pk_publishers PRIMARY KEY (publisher_id),
    CONSTRAINT uq_publisher_name UNIQUE (publisher_name),
    CONSTRAINT uq_publisher_email UNIQUE (email)
);

CREATE TABLE books (
    book_id             NUMBER,
    isbn                VARCHAR2(20),
    title               NVARCHAR2(300) NOT NULL,
    description         NCLOB,
    category_id         NUMBER NOT NULL,
    publisher_id        NUMBER,
    price               NUMBER(12,2) NOT NULL,
    stock_quantity      NUMBER DEFAULT 0,
    weight_gram         NUMBER,
    dimensions          VARCHAR2(50),
    page_count          NUMBER,
    publication_year    NUMBER(4),
    language            VARCHAR2(20) DEFAULT 'vi',
    cover_type          VARCHAR2(20),
    is_featured         NUMBER(1) DEFAULT 0,
    is_new_arrival      NUMBER(1) DEFAULT 0,
    view_count          NUMBER DEFAULT 0,
    sold_count          NUMBER DEFAULT 0,
    is_active           NUMBER(1) DEFAULT 1,
    created_by          NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    updated_by          NUMBER,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_isbn UNIQUE (isbn),
    CONSTRAINT fk_book_cat FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT fk_book_pub FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id),
    CONSTRAINT fk_book_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_book_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_book_price CHECK (price >= 0),
    CONSTRAINT ck_book_pub_year CHECK (publication_year BETWEEN 1900 AND 2100),
    CONSTRAINT ck_book_active CHECK (is_active IN (0, 1))
);

CREATE TABLE book_images (
    image_id            NUMBER,
    book_id             NUMBER NOT NULL,
    image_url           VARCHAR2(500) NOT NULL,
    is_main             NUMBER(1) DEFAULT 0,
    sort_order          NUMBER DEFAULT 0,
    created_at          DATE DEFAULT SYSDATE,
    CONSTRAINT pk_book_images PRIMARY KEY (image_id),
    CONSTRAINT fk_img_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT ck_img_is_main CHECK (is_main IN (0, 1))
);

CREATE TABLE book_authors (
    ba_id               NUMBER,
    book_id             NUMBER NOT NULL,
    author_id           NUMBER NOT NULL,
    role                VARCHAR2(20) DEFAULT 'AUTHOR' NOT NULL,
    author_order        NUMBER DEFAULT 1,
    created_at          DATE DEFAULT SYSDATE,
    CONSTRAINT pk_book_authors PRIMARY KEY (ba_id),
    CONSTRAINT uq_book_author UNIQUE (book_id, author_id, role),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id),
    CONSTRAINT ck_ba_role CHECK (role IN ('AUTHOR', 'TRANSLATOR', 'EDITOR', 'ILLUSTRATOR')),
    CONSTRAINT ck_ba_order CHECK (author_order > 0)
);

CREATE TABLE customers (
    customer_id         NUMBER,
    full_name           NVARCHAR2(100) NOT NULL,
    email               VARCHAR2(150) NOT NULL,
    phone               VARCHAR2(15),
    address             NVARCHAR2(500),
    province            NVARCHAR2(50),
    district            NVARCHAR2(50),
    date_of_birth       DATE,
    gender              VARCHAR2(10),
    avatar_url          VARCHAR2(500),
    preferred_branch_id NUMBER, 
    created_by          NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    updated_by          NUMBER,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT fk_cust_pref_branch FOREIGN KEY (preferred_branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_cust_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_cust_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_cust_gender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'))
);

CREATE TABLE shipping_methods (
    method_id           NUMBER,
    method_name         NVARCHAR2(100) NOT NULL,
    method_code         VARCHAR2(30) NOT NULL,
    carrier             NVARCHAR2(50) NOT NULL,
    base_fee            NUMBER(10,2) DEFAULT 0,
    weight_fee_per_kg   NUMBER(10,2),
    free_threshold      NUMBER(12,2),
    estimated_days_min  NUMBER,
    estimated_days_max  NUMBER,
    is_active           NUMBER(1) DEFAULT 1,
    display_order       NUMBER DEFAULT 0,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_shipping_methods PRIMARY KEY (method_id),
    CONSTRAINT uq_ship_method_code UNIQUE (method_code),
    CONSTRAINT ck_ship_fee CHECK (base_fee >= 0),
    CONSTRAINT ck_ship_active CHECK (is_active IN (0, 1))
);

CREATE TABLE orders (
    order_id            NUMBER,
    order_code          VARCHAR2(30) NOT NULL,
    customer_id         NUMBER NOT NULL,
    branch_id           NUMBER NOT NULL,
    status_code         VARCHAR2(20) NOT NULL,
    shipping_method_id  NUMBER,
    coupon_id           NUMBER,
    total_amount        NUMBER(12,2) DEFAULT 0 NOT NULL,
    discount_amount     NUMBER(12,2) DEFAULT 0,
    shipping_fee        NUMBER(10,2) DEFAULT 0,
    final_amount        NUMBER(12,2) DEFAULT 0,
    order_date          DATE DEFAULT SYSDATE,
    ship_address        NVARCHAR2(500) NOT NULL,
    ship_province       NVARCHAR2(50),
    ship_district       NVARCHAR2(50),
    ship_ward           NVARCHAR2(50),
    ship_phone          VARCHAR2(15),
    tracking_number     VARCHAR2(50),
    shipped_at          DATE,
    delivered_at        DATE,
    cancelled_at        DATE,
    customer_note       NVARCHAR2(1000),
    admin_note          NVARCHAR2(1000),
    created_by          NUMBER,
    updated_at          DATE,
    updated_by          NUMBER,
    cancelled_by        NUMBER,
    cancellation_reason NVARCHAR2(500),
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT uq_order_code UNIQUE (order_code),
    CONSTRAINT fk_order_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_order_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_order_status FOREIGN KEY (status_code) REFERENCES order_statuses(status_code),
    CONSTRAINT fk_order_ship FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(method_id),
    CONSTRAINT fk_order_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_order_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_order_cancelled_by FOREIGN KEY (cancelled_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_order_amount CHECK (total_amount >= 0),
    CONSTRAINT ck_order_discount CHECK (discount_amount >= 0),
    CONSTRAINT ck_order_ship_fee CHECK (shipping_fee >= 0)
);

CREATE TABLE order_details (
    detail_id           NUMBER,
    order_id            NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity            NUMBER NOT NULL,
    unit_price          NUMBER(12,2) NOT NULL,
    subtotal            NUMBER(12,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
    CONSTRAINT pk_order_details PRIMARY KEY (detail_id),
    CONSTRAINT fk_od_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_od_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT uq_od_order_book UNIQUE (order_id, book_id),
    CONSTRAINT ck_od_qty CHECK (quantity > 0),
    CONSTRAINT ck_od_unit_price CHECK (unit_price >= 0)
);

CREATE TABLE order_status_history (
    history_id          NUMBER,
    order_id            NUMBER NOT NULL,
    old_status          VARCHAR2(20),
    new_status          VARCHAR2(20) NOT NULL,
    changed_by          NUMBER NOT NULL,
    changed_at          DATE DEFAULT SYSDATE,
    changed_from_ip     VARCHAR2(50),
    reason              NVARCHAR2(500),
    CONSTRAINT pk_osh PRIMARY KEY (history_id),
    CONSTRAINT fk_osh_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_ochanged_by FOREIGN KEY (changed_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_osh_new_status CHECK (new_status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED', 'RETURNED'))
);

CREATE TABLE carts (
    cart_id             NUMBER,
    customer_id         NUMBER NOT NULL,
    branch_id           NUMBER NOT NULL,
    session_id          VARCHAR2(100),
    status              VARCHAR2(20) DEFAULT 'ACTIVE',
    converted_to_order_id NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_carts PRIMARY KEY (cart_id),
    CONSTRAINT fk_cart_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_cart_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_cart_converted FOREIGN KEY (converted_to_order_id) REFERENCES orders(order_id),
    CONSTRAINT ck_cart_status CHECK (status IN ('ACTIVE', 'CONVERTED', 'ABANDONED'))
);

CREATE TABLE cart_items (
    cart_item_id        NUMBER,
    cart_id             NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity            NUMBER NOT NULL,
    unit_price          NUMBER(12,2) NOT NULL,
    added_at            DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_cart_items PRIMARY KEY (cart_item_id),
    CONSTRAINT fk_ci_cart FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    CONSTRAINT fk_ci_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT uq_ci_cart_book UNIQUE (cart_id, book_id),
    CONSTRAINT ck_ci_qty CHECK (quantity > 0),
    CONSTRAINT ck_ci_price CHECK (unit_price >= 0)
);

CREATE TABLE branch_inventory (
    inventory_id        NUMBER,
    branch_id           NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity_available  NUMBER DEFAULT 0 NOT NULL,
    quantity_reserved   NUMBER DEFAULT 0 NOT NULL,
    quantity_transit_in NUMBER DEFAULT 0 NOT NULL,
    low_stock_threshold NUMBER DEFAULT 10,
    reorder_point       NUMBER DEFAULT 20,
    warehouse_zone      VARCHAR2(20),
    shelf_code          VARCHAR2(20),
    bin_code            VARCHAR2(20),
    last_stock_in_at    DATE,
    last_stock_out_at   DATE,
    last_counted_at     DATE,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    updated_by          NUMBER,
    CONSTRAINT pk_branch_inventory PRIMARY KEY (inventory_id),
    CONSTRAINT uq_binv_branch_book UNIQUE (branch_id, book_id),
    CONSTRAINT fk_binv_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_binv_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_binv_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_binv_qty_avail CHECK (quantity_available >= 0),
    CONSTRAINT ck_binv_qty_res CHECK (quantity_reserved >= 0),
    CONSTRAINT ck_binv_qty_transit CHECK (quantity_transit_in >= 0),
    CONSTRAINT ck_binv_logic CHECK (quantity_available >= quantity_reserved)
);

CREATE TABLE inventory_transfers (
    transfer_id         NUMBER,
    transfer_code       VARCHAR2(30) NOT NULL,
    from_branch_id      NUMBER NOT NULL,
    to_branch_id        NUMBER NOT NULL,
    transfer_type       VARCHAR2(20) DEFAULT 'TRANSFER',
    status              VARCHAR2(20) DEFAULT 'PENDING',
    requested_by        NUMBER NOT NULL,
    approved_by         NUMBER,
    shipped_by          NUMBER,
    received_by         NUMBER,
    total_items         NUMBER DEFAULT 0,
    total_quantity      NUMBER DEFAULT 0,
    request_date        DATE DEFAULT SYSDATE,
    approved_date       DATE,
    shipped_date        DATE,
    received_date       DATE,
    shipping_fee        NUMBER(10,2) DEFAULT 0,
    tracking_code       VARCHAR2(50),
    notes               NVARCHAR2(1000),
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_inv_transfers PRIMARY KEY (transfer_id),
    CONSTRAINT uq_transfer_code UNIQUE (transfer_code),
    CONSTRAINT fk_xfer_from FOREIGN KEY (from_branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_xfer_to FOREIGN KEY (to_branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_xfer_req_by FOREIGN KEY (requested_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_xfer_app_by FOREIGN KEY (approved_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_xfer_ship_by FOREIGN KEY (shipped_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_xfer_rec_by FOREIGN KEY (received_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_xfer_type CHECK (transfer_type IN ('TRANSFER', 'RETURN', 'ADJUST')),
    CONSTRAINT ck_xfer_status CHECK (status IN ('PENDING', 'APPROVED', 'SHIPPING', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_xfer_diff_branch CHECK (from_branch_id != to_branch_id)
);

CREATE TABLE transfer_details (
    detail_id           NUMBER,
    transfer_id         NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity_requested  NUMBER NOT NULL,
    quantity_shipped    NUMBER DEFAULT 0,
    quantity_received   NUMBER DEFAULT 0,
    unit_cost           NUMBER(12,2),
    notes               NVARCHAR2(500),
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_transfer_details PRIMARY KEY (detail_id),
    CONSTRAINT fk_td_transfer FOREIGN KEY (transfer_id) REFERENCES inventory_transfers(transfer_id),
    CONSTRAINT fk_td_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT ck_td_qty_req CHECK (quantity_requested > 0),
    CONSTRAINT ck_td_qty_ship CHECK (quantity_shipped >= 0),
    CONSTRAINT ck_td_qty_rec CHECK (quantity_received >= 0),
    CONSTRAINT ck_td_qty_logic CHECK (quantity_received <= quantity_shipped)
);

CREATE TABLE inventory_transactions (
    txn_id              NUMBER,
    branch_id           NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    txn_type            VARCHAR2(20) NOT NULL,
    reference_id        NUMBER,
    reference_type      VARCHAR2(20),
    reference_detail    VARCHAR2(50),
    quantity            NUMBER NOT NULL,
    unit_cost           NUMBER(12,2),
    total_cost          NUMBER(12,2),
    notes               NVARCHAR2(500),
    created_by          NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    CONSTRAINT pk_inv_txn PRIMARY KEY (txn_id),
    CONSTRAINT fk_it_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_it_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_it_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_it_type CHECK (txn_type IN ('IN', 'OUT', 'ADJUST', 'TRANSFER_IN', 'TRANSFER_OUT', 'RETURN')),
    CONSTRAINT ck_it_ref_type CHECK (reference_type IN ('ORDER', 'TRANSFER', 'ADJUSTMENT', 'INITIAL', 'RETURN'))
);

CREATE TABLE coupons (
    coupon_id           NUMBER,
    coupon_code         VARCHAR2(20) NOT NULL,
    coupon_name         NVARCHAR2(100) NOT NULL,
    description         NVARCHAR2(500),
    discount_type       VARCHAR2(10) NOT NULL,
    discount_value      NUMBER(12,2) NOT NULL,
    min_order_amount    NUMBER(12,2) DEFAULT 0,
    max_discount_amount NUMBER(12,2),
    usage_limit         NUMBER,
    usage_count         NUMBER DEFAULT 0,
    per_customer_limit  NUMBER DEFAULT 1,
    applicable_branches VARCHAR2(500),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    is_active           NUMBER(1) DEFAULT 1,
    created_by          NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    updated_by          NUMBER,
    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupon_code UNIQUE (coupon_code),
    CONSTRAINT fk_coupon_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_coupon_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_coupon_discount_type CHECK (discount_type IN ('PERCENT', 'FIXED')),
    CONSTRAINT ck_coupon_value CHECK (discount_value > 0),
    CONSTRAINT ck_coupon_dates CHECK (end_date >= start_date),
    CONSTRAINT ck_coupon_active CHECK (is_active IN (0, 1))
);

ALTER TABLE orders ADD CONSTRAINT fk_order_coupon 
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id);

CREATE TABLE payment_transactions (
    transaction_id      NUMBER,
    order_id            NUMBER NOT NULL,
    branch_id           NUMBER,
    payment_method      VARCHAR2(30) NOT NULL,
    amount              NUMBER(12,2) NOT NULL,
    currency            VARCHAR2(3) DEFAULT 'VND',
    status              VARCHAR2(20) DEFAULT 'PENDING',
    transaction_code    VARCHAR2(100),
    gateway_name        VARCHAR2(50),
    gateway_request     CLOB,
    gateway_response    CLOB,
    error_message       NVARCHAR2(500),
    paid_at             DATE,
    refunded_at         DATE,
    refund_amount       NUMBER(12,2) DEFAULT 0,
    created_by          NUMBER,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    updated_by          NUMBER,
    CONSTRAINT pk_payment_txn PRIMARY KEY (transaction_id),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_pay_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT fk_pay_created_by FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT fk_pay_updated_by FOREIGN KEY (updated_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_pay_method CHECK (payment_method IN ('COD', 'CREDIT_CARD', 'BANK_TRANSFER', 'MOMO', 'VNPAY', 'ZALOPAY', 'PAYPAL', 'CASH')),
    CONSTRAINT ck_pay_status CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED')),
    CONSTRAINT ck_pay_amount CHECK (amount > 0),
    CONSTRAINT ck_pay_refund CHECK (refund_amount >= 0 AND refund_amount <= amount)
);

CREATE TABLE reviews (
    review_id           NUMBER,
    customer_id         NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    order_id            NUMBER NOT NULL,
    rating              NUMBER(1) NOT NULL,
    comment_text        NVARCHAR2(2000),
    is_approved         NUMBER(1) DEFAULT 0,
    approved_by         NUMBER,
    approved_at         DATE,
    helpful_count       NUMBER DEFAULT 0,
    created_at          DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT fk_rev_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_rev_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT fk_rev_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_rev_approved_by FOREIGN KEY (approved_by) REFERENCES staff(staff_id),
    CONSTRAINT ck_rev_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_rev_order_book UNIQUE (order_id, book_id)
);

CREATE TABLE wishlists (
    wishlist_id         NUMBER,
    customer_id         NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    added_at            DATE DEFAULT SYSDATE,
    note                NVARCHAR2(500),
    is_notified         NUMBER(1) DEFAULT 0,
    notification_sent_at DATE,
    CONSTRAINT pk_wishlists PRIMARY KEY (wishlist_id),
    CONSTRAINT fk_wish_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_wish_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT uq_wish_cust_book UNIQUE (customer_id, book_id),
    CONSTRAINT ck_wish_notified CHECK (is_notified IN (0, 1))
);

CREATE OR REPLACE TRIGGER trg_branches_bi 
BEFORE INSERT ON branches 
FOR EACH ROW 
BEGIN 
    IF :NEW.branch_id IS NULL THEN 
        SELECT seq_branches.NEXTVAL INTO :NEW.branch_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_users_bi 
BEFORE INSERT ON users 
FOR EACH ROW 
BEGIN 
    IF :NEW.user_id IS NULL THEN 
        SELECT seq_users.NEXTVAL INTO :NEW.user_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_staff_bi 
BEFORE INSERT ON staff 
FOR EACH ROW 
BEGIN 
    IF :NEW.staff_id IS NULL THEN 
        SELECT seq_staff.NEXTVAL INTO :NEW.staff_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_categories_bi 
BEFORE INSERT ON categories 
FOR EACH ROW 
BEGIN 
    IF :NEW.category_id IS NULL THEN 
        SELECT seq_categories.NEXTVAL INTO :NEW.category_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_authors_bi 
BEFORE INSERT ON authors 
FOR EACH ROW 
BEGIN 
    IF :NEW.author_id IS NULL THEN 
        SELECT seq_authors.NEXTVAL INTO :NEW.author_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_publishers_bi 
BEFORE INSERT ON publishers 
FOR EACH ROW 
BEGIN 
    IF :NEW.publisher_id IS NULL THEN 
        SELECT seq_publishers.NEXTVAL INTO :NEW.publisher_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_books_bi 
BEFORE INSERT ON books 
FOR EACH ROW 
BEGIN 
    IF :NEW.book_id IS NULL THEN 
        SELECT seq_books.NEXTVAL INTO :NEW.book_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_book_images_bi 
BEFORE INSERT ON book_images 
FOR EACH ROW 
BEGIN 
    IF :NEW.image_id IS NULL THEN 
        SELECT seq_book_images.NEXTVAL INTO :NEW.image_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_book_authors_bi 
BEFORE INSERT ON book_authors 
FOR EACH ROW 
BEGIN 
    IF :NEW.ba_id IS NULL THEN 
        SELECT seq_book_authors.NEXTVAL INTO :NEW.ba_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_customers_bi 
BEFORE INSERT ON customers 
FOR EACH ROW 
BEGIN 
    IF :NEW.customer_id IS NULL THEN 
        SELECT seq_customers.NEXTVAL INTO :NEW.customer_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_ship_methods_bi 
BEFORE INSERT ON shipping_methods 
FOR EACH ROW 
BEGIN 
    IF :NEW.method_id IS NULL THEN 
        SELECT seq_shipping_methods.NEXTVAL INTO :NEW.method_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_carts_bi 
BEFORE INSERT ON carts 
FOR EACH ROW 
BEGIN 
    IF :NEW.cart_id IS NULL THEN 
        SELECT seq_carts.NEXTVAL INTO :NEW.cart_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_cart_items_bi 
BEFORE INSERT ON cart_items 
FOR EACH ROW 
BEGIN 
    IF :NEW.cart_item_id IS NULL THEN 
        SELECT seq_cart_items.NEXTVAL INTO :NEW.cart_item_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_orders_bi 
BEFORE INSERT ON orders 
FOR EACH ROW 
BEGIN 
    IF :NEW.order_id IS NULL THEN 
        SELECT seq_orders.NEXTVAL INTO :NEW.order_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_order_details_bi 
BEFORE INSERT ON order_details 
FOR EACH ROW 
BEGIN 
    IF :NEW.detail_id IS NULL THEN 
        SELECT seq_order_details.NEXTVAL INTO :NEW.detail_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_osh_bi 
BEFORE INSERT ON order_status_history 
FOR EACH ROW 
BEGIN 
    IF :NEW.history_id IS NULL THEN 
        SELECT seq_order_status_his.NEXTVAL INTO :NEW.history_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_branch_inv_bi 
BEFORE INSERT ON branch_inventory 
FOR EACH ROW 
BEGIN 
    IF :NEW.inventory_id IS NULL THEN 
        SELECT seq_branch_inventory.NEXTVAL INTO :NEW.inventory_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_inv_transfers_bi 
BEFORE INSERT ON inventory_transfers 
FOR EACH ROW 
BEGIN 
    IF :NEW.transfer_id IS NULL THEN 
        SELECT seq_inventory_transfers.NEXTVAL INTO :NEW.transfer_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_transfer_details_bi 
BEFORE INSERT ON transfer_details 
FOR EACH ROW 
BEGIN 
    IF :NEW.detail_id IS NULL THEN 
        SELECT seq_transfer_details.NEXTVAL INTO :NEW.detail_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_inv_txn_bi 
BEFORE INSERT ON inventory_transactions 
FOR EACH ROW 
BEGIN 
    IF :NEW.txn_id IS NULL THEN 
        SELECT seq_inventory_txn.NEXTVAL INTO :NEW.txn_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_payment_txn_bi 
BEFORE INSERT ON payment_transactions 
FOR EACH ROW 
BEGIN 
    IF :NEW.transaction_id IS NULL THEN 
        SELECT seq_payment_txn.NEXTVAL INTO :NEW.transaction_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_coupons_bi 
BEFORE INSERT ON coupons 
FOR EACH ROW 
BEGIN 
    IF :NEW.coupon_id IS NULL THEN 
        SELECT seq_coupons.NEXTVAL INTO :NEW.coupon_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_reviews_bi 
BEFORE INSERT ON reviews 
FOR EACH ROW 
BEGIN 
    IF :NEW.review_id IS NULL THEN 
        SELECT seq_reviews.NEXTVAL INTO :NEW.review_id FROM DUAL; 
    END IF; 
END;
/

CREATE OR REPLACE TRIGGER trg_wishlists_bi 
BEFORE INSERT ON wishlists 
FOR EACH ROW 
BEGIN 
    IF :NEW.wishlist_id IS NULL THEN 
        SELECT seq_wishlists.NEXTVAL INTO :NEW.wishlist_id FROM DUAL; 
    END IF; 
END;
/

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, phone, is_main_branch, status)
VALUES ('HQ001', N'Trụ sở chính DigiBook', 'STORE', N'123 Nguyễn Văn A, Quận 1', N'TP. Hồ Chí Minh', '02812345678', 1, 'ACTIVE');

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('PENDING', 'Pending', N'Chờ xác nhận', 1, '#FFA500', 0, '["CONFIRMED","CANCELLED"]', 0);

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('CONFIRMED', 'Confirmed', N'Đã xác nhận', 2, '#1E90FF', 0, '["SHIPPING","CANCELLED"]', 1);

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('SHIPPING', 'Shipping', N'Đang giao hàng', 3, '#9370DB', 0, '["DELIVERED","RETURNED"]', 1);

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('DELIVERED', 'Delivered', N'Đã giao hàng', 4, '#32CD32', 1, '["RETURNED"]', 1);

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('CANCELLED', 'Cancelled', N'Đã hủy', 5, '#DC143C', 1, '[]', 0);

INSERT INTO order_statuses (status_code, status_name, status_name_vi, display_order, color_code, is_terminal, allowed_next_status, require_payment) 
VALUES ('RETURNED', 'Returned', N'Đã trả hàng', 6, '#808080', 1, '[]', 1);

INSERT INTO users (username, email, password_hash, full_name, role, is_active)
VALUES ('admin', 'admin@digibook.com', 'HASH_VALUE_HERE', N

SET DEFINE ON;

DELETE FROM wishlists;
DELETE FROM reviews;
DELETE FROM payment_transactions;
DELETE FROM coupons;
DELETE FROM inventory_transactions;
DELETE FROM transfer_details;
DELETE FROM inventory_transfers;
DELETE FROM branch_inventory;
DELETE FROM order_status_history;
DELETE FROM order_details;
DELETE FROM orders;
DELETE FROM cart_items;
DELETE FROM carts;
DELETE FROM shipping_methods;
DELETE FROM customers;
DELETE FROM book_authors;
DELETE FROM books;
DELETE FROM publishers;
DELETE FROM categories;
DELETE FROM authors;
DELETE FROM staff;

DELETE FROM users WHERE username != 'admin';
DELETE FROM branches WHERE branch_code != 'HQ001';

COMMIT;

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('HN002', N'Chi nhánh Hà Nội', 'STORE', N'Số 45 Tràng Tiền, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', '02438234567', 'hanoi@digibook.com', 'ACTIVE', 0, TO_DATE('2023-03-15', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('DN003', N'Chi nhánh Đà Nẵng', 'STORE', N'168 Nguyễn Văn Linh, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', '0236367890', 'danang@digibook.com', 'ACTIVE', 0, TO_DATE('2023-06-20', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('CT004', N'Chi nhánh Cần Thơ', 'STORE', N'12 Nguyễn Trãi, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', '0292387654', 'cantho@digibook.com', 'ACTIVE', 0, TO_DATE('2023-09-10', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, status, is_main_branch, opening_date) 
VALUES ('KHO_HCM', N'Kho trung chuyển TP.HCM', 'WAREHOUSE', N'KCN Tân Bình, Quận Tân Phú', N'TP. Hồ Chí Minh', N'Quận Tân Phú', '0283765432', 'ACTIVE', 0, TO_DATE('2023-01-01', 'YYYY-MM-DD'));

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('manager_hn', 'manager.hn@digibook.com', 'HASH_MGR_HN', N'Nguyễn Văn Dũng', 'MANAGER', '0912345678', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('staff_sale_01', 'sale01@digibook.com', 'HASH_SALE01', N'Trần Thị Bán Hàng', 'STAFF', '0923456789', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('staff_kho', 'kho@digibook.com', 'HASH_KHO', N'Lê Văn Kho', 'STAFF', '0934567890', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('support_01', 'support@digibook.com', 'HASH_SP', N'Phạm Thị Hỗ Trợ', 'SUPPORT', '0945678901', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('manager_dn', 'manager.dn@digibook.com', 'HASH_MGR_DN', N'Hoàng Văn Đà Nẵng', 'MANAGER', '0909123456', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('admin_cslt', 'admin.cslt@digibook.com', 'HASH_CSLT', N'Admin Cơ Sở Lưu Trữ', 'ADMIN', '0908234567', 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'admin'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV001', N'Quản lý hệ thống', 'ADMIN', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 25000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'manager_hn'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'NV002', N'Quản lý chi nhánh HN', 'MANAGEMENT', TO_DATE('2023-03-15', 'YYYY-MM-DD'), 20000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'staff_sale_01'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV003', N'Nhân viên bán hàng', 'SALES', TO_DATE('2023-02-01', 'YYYY-MM-DD'), 8000000, 'ACTIVE', 0, 0);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'staff_kho'), (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), 'NV004', N'Thủ kho', 'WAREHOUSE', TO_DATE('2023-01-15', 'YYYY-MM-DD'), 9000000, 'ACTIVE', 0, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'support_01'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV005', N'Nhân viên CSKH', 'SUPPORT', TO_DATE('2023-04-01', 'YYYY-MM-DD'), 7500000, 'ACTIVE', 0, 0);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'manager_dn'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'NV006', N'Quản lý chi nhánh ĐN', 'MANAGEMENT', TO_DATE('2023-06-20', 'YYYY-MM-DD'), 19000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'admin_cslt'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'NV007', N'Quản lý chi nhánh CT', 'MANAGEMENT', TO_DATE('2023-09-10', 'YYYY-MM-DD'), 18500000, 'ACTIVE', 1, 1);

COMMIT;

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Văn học', NULL, N'Sách văn học trong và ngoài nước', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Kinh tế', NULL, N'Sách kinh tế, quản trị, marketing', 2, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Kỹ năng sống', NULL, N'Sách kỹ năng mềm, phát triển bản thân', 3, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Khoa học - Kỹ thuật', NULL, N'Sách khoa học, công nghệ, lập trình', 4, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Thiếu nhi', NULL, N'Sách cho trẻ em và thanh thiếu niên', 5, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Lịch sử - Địa lý', NULL, N'Sách lịch sử, địa danh thế giới', 6, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Tiểu thuyết', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Tiểu thuyết các loại', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Truyện ngắn', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Tập truyện ngắn', 2, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Thơ ca', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Thơ và tuyển tập thơ', 3, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Quản trị - Lãnh đạo', (SELECT category_id FROM categories WHERE category_name = N'Kinh tế'), N'Sách về quản trị doanh nghiệp', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Marketing - Bán hàng', (SELECT category_id FROM categories WHERE category_name = N'Kinh tế'), N'Marketing và kỹ năng bán hàng', 2, 1);

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nguyễn Nhật Ánh', N'Nhà văn nổi tiếng với các tác phẩm thiếu nhi và tuổi mới lớn', TO_DATE('1955-05-07', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Tô Hoài', N'Nhà văn, nhà báo với tác phẩm Dế Mèn phiêu lưu ký', TO_DATE('1920-09-27', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Paulo Coelho', N'Nhà văn Brazil nổi tiếng với Nhà giả kim', TO_DATE('1947-08-24', 'YYYY-MM-DD'), N'Brazil');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'J.K. Rowling', N'Tác giả bộ truyện Harry Potter', TO_DATE('1965-07-31', 'YYYY-MM-DD'), N'Anh');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Dale Carnegie', N'Tác giả sách kỹ năng giao tiếp nổi tiếng', TO_DATE('1888-11-24', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Robert Kiyosaki', N'Tác giả Dạy con làm giàu', TO_DATE('1947-04-08', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Stephen Hawking', N'Nhà vật lý lý thuyết nổi tiếng', TO_DATE('1942-01-08', 'YYYY-MM-DD'), N'Anh');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Yuval Noah Harari', N'Sử gia Israel, tác giả Sapiens', TO_DATE('1976-02-24', 'YYYY-MM-DD'), N'Israel');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nguyễn Du', N'Đại thi hào dân tộc', TO_DATE('1765-01-03', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nam Cao', N'Nhà văn hiện thực phê phán', TO_DATE('1915-10-29', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Fujiko F. Fujio', N'Tác giả bộ truyện Doraemon', TO_DATE('1933-12-01', 'YYYY-MM-DD'), N'Nhật Bản');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Daniel Kahneman', N'Nhà tâm lý học đoạt giải Nobel', TO_DATE('1934-03-05', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Eckhart Tolle', N'Tác giả sách tâm linh nổi tiếng', TO_DATE('1948-02-16', 'YYYY-MM-DD'), N'Đức');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Malcolm Gladwell', N'Nhà báo và tác giả sách best-seller', TO_DATE('1963-09-03', 'YYYY-MM-DD'), N'Canada');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Vũ Trọng Phụng', N'Nhà văn hiện thực phê phán', TO_DATE('1912-10-20', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Trẻ', N'161B Lý Chính Thắng, Q.3, TP.HCM', '02839316289', 'info@nxbtre.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Kim Đồng', N'55 Quang Trung, Hà Nội', '02439434730', 'info@nxbkimdong.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Giáo dục Việt Nam', N'81 Trần Hưng Đạo, Hà Nội', '02438220801', 'nxbgd@moet.edu.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Nhã Nam', N'59 Đỗ Quang, Hà Nội', '02435146876', 'contact@nhanam.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Alpha Books', N'176 Thái Hà, Hà Nội', '02463297200', 'info@alphabooks.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'First News', N'11H Nguyễn Thị Minh Khai, Q.1, TP.HCM', '02838227979', 'info@firstnews.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Văn học', N'18 Nguyễn Trường Tộ, Hà Nội', '02437161518', 'nxbvanhoc@yahoo.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Bloomsbury', N'50 Bedford Square, London', '+442074315600', 'info@bloomsbury.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'HarperCollins', N'195 Broadway, New York', '+12122077000', 'info@harpercollins.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Penguin Random House', N'1745 Broadway, New York', '+12127829000', 'info@penguinrandomhouse.com');

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026700', N'Nhà Giả Kim', N'Câu chuyện về Santiago và hành trình tìm kiếm kho báu', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 89000, 300, '20x14x2', 228, 2020, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042088592', N'Harry Potter và Hòn đá Phù thủy', N'Tập 1 series Harry Potter', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Bloomsbury'), 185000, 450, '21x15x3', 366, 2019, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026670', N'Đắc Nhân Tâm', N'Nghệ thuật thu phục lòng người', (SELECT category_id FROM categories WHERE category_name = N'Marketing - Bán hàng'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'First News'), 95000, 350, '20x14x2.5', 320, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041038796', N'Dạy Con Làm Giàu - Tập 1', N'Những bài học tài chính cho trẻ', (SELECT category_id FROM categories WHERE category_name = N'Quản trị - Lãnh đạo'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'First News'), 108000, 400, '21x15x2', 320, 2022, 'vi', 'PAPERBACK', 1, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026694', N'Tôi Thấy Hoa Vàng Trên Cỏ Xanh', N'Truyện dài về tuổi thơ', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 120000, 380, '20x14x2.5', 300, 2020, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041063804', N'Đất Rừng Phương Nam', N'Tiểu thuyết về Nam Bộ', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 145000, 500, '21x15x3', 450, 2021, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042086055', N'Doraemon - Tập 1', N'Truyện tranh Nhật Bản', (SELECT category_id FROM categories WHERE category_name = N'Thiếu nhi'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Kim Đồng'), 25000, 150, '18x13x1', 192, 2023, 'vi', 'PAPERBACK', 0, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026717', N'Think and Grow Rich', N'Nghĩ giàu làm giàu', (SELECT category_id FROM categories WHERE category_name = N'Quản trị - Lãnh đạo'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Alpha Books'), 115000, 420, '21x15x2', 350, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041038802', N'Sapiens: Lược Sử Loài Người', N'Sử học về sự tiến hóa của con người', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 175000, 550, '24x17x3', 560, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026724', N'Tâm Lý Học Đám Đông', N'Nghiên cứu về tâm lý quần chúng', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 85000, 320, '20x14x2', 280, 2019, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041045022', N'Vũ Trọng Phụng - Tuyển tập', N'Các tác phẩm hay của Vũ Trọng Phụng', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 165000, 480, '21x15x2.8', 420, 2022, 'vi', 'HARDCOVER', 0, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041050019', N'Lược Sử Tương Lai', N'Về những thách thức của nhân loại', (SELECT category_id FROM categories WHERE category_name = N'Khoa học - Kỹ thuật'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 195000, 600, '24x17x3.5', 520, 2023, 'vi', 'PAPERBACK', 1, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026731', N'Ngồi Khóc Trên Cây', N'Truyện dài về tình bạn và tuổi học trò', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 95000, 340, '20x14x2', 280, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042088608', N'Harry Potter và Phòng Chứa Bí Mật', N'Tập 2 Harry Potter', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Bloomsbury'), 195000, 480, '21x15x3.2', 400, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026748', N'Mắt Biếc', N'Truyện tình yêu tuổi học trò', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 105000, 360, '20x14x2.2', 320, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026700'), 'https://digibook.com/images/nha-gia-kim-1.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026700'), 'https://digibook.com/images/nha-gia-kim-2.jpg', 0, 1);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088592'), 'https://digibook.com/images/hp-1.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088592'), 'https://digibook.com/images/hp-1-back.jpg', 0, 1);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026670'), 'https://digibook.com/images/dac-nhan-tam.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038796'), 'https://digibook.com/images/day-con-lam-giau.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026694'), 'https://digibook.com/images/toi-thay-hoa-vang.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041063804'), 'https://digibook.com/images/dat-rung-phuong-nam.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), 'https://digibook.com/images/doraemon-1.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026717'), 'https://digibook.com/images/think-grow-rich.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), 'https://digibook.com/images/sapiens.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), 'https://digibook.com/images/sapiens-2.jpg', 0, 1);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026724'), 'https://digibook.com/images/tam-ly-dam-dong.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041045022'), 'https://digibook.com/images/vu-trong-phung.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041050019'), 'https://digibook.com/images/luoc-su-tuong-lai.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026731'), 'https://digibook.com/images/ngoi-khoc-tren-cay.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088608'), 'https://digibook.com/images/hp-2.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026748'), 'https://digibook.com/images/mat-biec.jpg', 1, 0);

INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026700'), (SELECT author_id FROM authors WHERE author_name = N'Paulo Coelho'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088592'), (SELECT author_id FROM authors WHERE author_name = N'J.K. Rowling'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026670'), (SELECT author_id FROM authors WHERE author_name = N'Dale Carnegie'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038796'), (SELECT author_id FROM authors WHERE author_name = N'Robert Kiyosaki'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026694'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041063804'), (SELECT author_id FROM authors WHERE author_name = N'Tô Hoài'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT author_id FROM authors WHERE author_name = N'Fujiko F. Fujio'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT author_id FROM authors WHERE author_name = N'Fujiko F. Fujio'), 'ILLUSTRATOR', 2);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026717'), (SELECT author_id FROM authors WHERE author_name = N'Dale Carnegie'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'TRANSLATOR', 2);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026724'), (SELECT author_id FROM authors WHERE author_name = N'Paulo Coelho'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041045022'), (SELECT author_id FROM authors WHERE author_name = N'Vũ Trọng Phụng'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041050019'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026731'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088608'), (SELECT author_id FROM authors WHERE author_name = N'J.K. Rowling'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026748'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);

COMMIT;

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Trần Văn Khách Hàng', 'tran.van.khach@gmail.com', '0909123456', N'123 Nguyễn Văn Cừ, Q.5', N'TP. Hồ Chí Minh', N'Quận 5', TO_DATE('1990-05-15', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Nguyễn Thị Mua Sách', 'nguyen.thi.mua@yahoo.com', '0918234567', N'45 Tràng Tiền, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', TO_DATE('1995-08-20', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'HN002'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Lê Văn Đọc Giả', 'le.van.doc@gmail.com', '0927345678', N'78 Nguyễn Văn Linh, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', TO_DATE('1988-12-10', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'DN003'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Phạm Thị Học Sinh', 'pham.thi.hs@gmail.com', '0936456789', N'12/4 Đường 3/2, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', TO_DATE('2002-03-25', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'CT004'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Hoàng Văn Giáo Sư', 'hoang.van.gs@edu.vn', '0945567890', N'56 Lý Tự Trọng, Q.1', N'TP. Hồ Chí Minh', N'Quận 1', TO_DATE('1975-11-08', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Vũ Thị Sinh Viên', 'vu.thi.sv@student.edu.vn', '0956678901', N'KTX ĐHQG, Thủ Đức', N'TP. Hồ Chí Minh', N'Thành phố Thủ Đức', TO_DATE('2000-09-12', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Đặng Văn Doanh Nhân', 'dang.van.dn@company.vn', '0967789012', N'Tòa nhà Bitexco, Q.1', N'TP. Hồ Chí Minh', N'Quận 1', TO_DATE('1980-07-30', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Bùi Thị Nội Trợ', 'bui.thi.nt@gmail.com', '0978890123', N'234 Lê Lợi, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', TO_DATE('1992-04-18', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'DN003'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Ngô Văn Công Chức', 'ngo.van.cc@gmail.com', '0989901234', N'89 Trần Phú, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', TO_DATE('1985-06-05', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HN002'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Lý Thị Giáo Viên', 'ly.thi.gv@school.edu.vn', '0990012345', N'101 Hùng Vương, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', TO_DATE('1983-10-22', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'CT004'));

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng tiêu chuẩn', 'GHN_STD', 'GHN', 25000, 5000, 300000, 3, 5, 1, 1);

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng nhanh', 'GHTK_FAST', 'GHTK', 35000, 8000, 500000, 1, 2, 1, 2);

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng hỏa tốc', 'NOW', 'AhaMove', 60000, 15000, NULL, 2, 4, 1, 3); 

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Nhận tại cửa hàng', 'PICKUP', 'STORE', 0, 0, 0, 0, 0, 1, 4);

INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 2);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'ACTIVE', SYSDATE - 1);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'ABANDONED', SYSDATE - 10);
INSERT INTO carts (customer_id, branch_id, status, converted_to_order_id, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'CONVERTED', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), SYSDATE - 5);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 3);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 1);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'bui.thi.nt@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'ACTIVE', SYSDATE - 4);

INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 2, 89000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1, 95000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 1, 175000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 1, 85000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com') AND status = 'ABANDONED'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 3, 120000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 5, 25000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026748'), 1, 105000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 2, 108000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), 1, 195000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'bui.thi.nt@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 1, 185000);

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD001', (SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'DELIVERED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 245000, 0, 25000, 270000, SYSDATE - 10, N'12/4 Đường 3/2', N'Cần Thơ', N'Ninh Kiều', '0936456789');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD002', (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'SHIPPING', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHTK_FAST'), 273000, 0, 35000, 308000, SYSDATE - 3, N'123 Nguyễn Văn Cừ', N'TP. Hồ Chí Minh', N'Quận 5', '0909123456');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD003', (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'PENDING', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 175000, 20000, 25000, 180000, SYSDATE - 1, N'45 Tràng Tiền', N'Hà Nội', N'Hoàn Kiếm', '0918234567');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone, cancelled_at, cancellation_reason) 
VALUES ('ORD004', (SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'CANCELLED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 89000, 0, 0, 0, SYSDATE - 5, N'78 Nguyễn Văn Linh', N'Đà Nẵng', N'Hải Châu', '0927345678', SYSDATE - 4, N'Khách đổi ý không mua nữa');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD005', (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'CONFIRMED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 450000, 50000, 0, 400000, SYSDATE - 2, N'56 Lý Tự Trọng', N'TP. Hồ Chí Minh', N'Quận 1', '0945567890');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD006', (SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'PENDING', (SELECT method_id FROM shipping_methods WHERE method_code = 'PICKUP'), 230000, 0, 0, 230000, SYSDATE, N'KTX ĐHQG', N'TP. Hồ Chí Minh', N'Thủ Đức', '0956678901');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD007', (SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'DELIVERED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHTK_FAST'), 520000, 0, 35000, 555000, SYSDATE - 15, N'Tòa nhà Bitexco', N'TP. Hồ Chí Minh', N'Quận 1', '0967789012');

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 5, 25000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 1, 95000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 1, 89000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1, 95000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 1, 120000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD003'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 1, 175000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 1, 89000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 1, 185000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 1, 108000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786041063804'), 1, 145000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD006'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 1, 85000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD006'), (SELECT book_id FROM books WHERE isbn = '9786042088608'), 1, 195000);

INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 2, 175000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), 1, 195000);

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), NULL, 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'), SYSDATE - 10, N'Tạo đơn hàng mới');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'PENDING', 'CONFIRMED', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'), SYSDATE - 9, N'Xác nhận thanh toán');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'CONFIRMED', 'SHIPPING', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), SYSDATE - 8, N'Giao cho đơn vị vận chuyển');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'SHIPPING', 'DELIVERED', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), SYSDATE - 6, N'Khách đã nhận hàng');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), NULL, 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV006'), SYSDATE - 5, N'Tạo đơn');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), 'PENDING', 'CANCELLED', (SELECT staff_id FROM staff WHERE staff_code = 'NV006'), SYSDATE - 4, N'Khách hủy đơn');

COMMIT;

INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 50, 2, 10, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 30, 1, 5, 'A', 'A02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 100, 0, 20, 'B', 'B01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 45, 1, 10, 'B', 'B02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 25, 0, 5, 'A', 'A03');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 200, 5, 30, 'C', 'C01');

INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 30, 0, 10, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 20, 1, 5, 'A', 'A02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 15, 0, 5, 'B', 'B01');

INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'DN003'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 8, 0, 5, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'DN003'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 5, 0, 3, 'A', 'A02');

INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 100, 0, 20, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 20, 0, 5, 'A', 'A02');

INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 500, 0, 50, 'KHO', 'K01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 300, 0, 30, 'KHO', 'K02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1000, 0, 100, 'KHO', 'K03');

INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC001', (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'TRANSFER', 'COMPLETED', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'), (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), 3, 150, SYSDATE - 30, N'Nhập hàng đầu tháng cho chi nhánh chính');

INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC002', (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'TRANSFER', 'SHIPPING', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'), (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), 2, 50, SYSDATE - 2, N'Bổ sung hàng cho chi nhánh Hà Nội');

INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC003', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'TRANSFER', 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), NULL, 1, 20, SYSDATE, N'Chuyển hàng dư từ HCM sang Đà Nẵng');

INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 50, 50, 50, 45000);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 30, 30, 30, 95000);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 70, 70, 70, 50000);

INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 20, 20, 0);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC002'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 30, 30, 0);

INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC003'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 20, 0, 0);

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'IN', 'INITIAL', 1000, 45000, N'Nhập kho đầu kỳ', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 'IN', 'INITIAL', 600, 95000, N'Nhập kho đầu kỳ', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 'OUT', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'ORDER', -5, 15000, N'Bán hàng đơn ORD001', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 'OUT', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'ORDER', -1, 60000, N'Bán hàng đơn ORD001', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'TRANSFER_OUT', (SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), 'TRANSFER', -50, N'Điều chuyển đến chi nhánh 1', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'TRANSFER_IN', (SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), 'TRANSFER', 50, N'Nhận từ kho trung chuyển', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'));

INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('WELCOME', N'Chào mừng thành viên mới', N'Giảm 10% cho đơn hàng đầu tiên', 'PERCENT', 10, 100000, 50000, 100, 1, SYSDATE - 30, SYSDATE + 365, 1, NULL, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('SALE50K', N'Giảm 50K', N'Giảm trực tiếp 50.000đ', 'FIXED', 50000, 200000, NULL, 50, 2, SYSDATE - 10, SYSDATE + 20, 1, '["1","2"]', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('SUMMER2024', N'Khuyến mãi hè', N'Giảm 20% cho sách thiếu nhi', 'PERCENT', 20, 150000, 100000, 200, 5, SYSDATE, TO_DATE('2026-08-31', 'YYYY-MM-DD'), 1, NULL, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, discount_type, discount_value, min_order_amount, start_date, end_date, is_active, usage_count, created_by) 
VALUES ('EXPIRED', N'Coupon hết hạn', 'PERCENT', 15, 100000, SYSDATE - 60, SYSDATE - 30, 0, 50, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'COD', 270000, 'VND', 'SUCCESS', 'COD001', SYSDATE - 6, (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'MOMO', 308000, 'VND', 'PENDING', 'MOMO20240327001', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'));

INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD003'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'BANK_TRANSFER', 180000, 'VND', 'SUCCESS', 'BANK20240326001', SYSDATE - 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV002'));

INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'CREDIT_CARD', 555000, 'VND', 'SUCCESS', 'VISA20240310001', SYSDATE - 15, (SELECT staff_id FROM staff WHERE staff_code = 'NV003'));

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 5, N'Sách hay, con tôi rất thích đọc Doraemon!', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 5, 3);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 4, N'Truyện hay nhưng giao hàng hơi chậm', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 5, 1);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT order_id FROM orders WHERE order_code = 'ORD007'), 5, N'Sapiens là cuốn sách tuyệt vời, nên đọc!', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 10, 10);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), (SELECT order_id FROM orders WHERE order_code = 'ORD007'), 5, N'Tương lai của nhân loại qua góc nhìn thú vị', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 10, 5);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), (SELECT order_id FROM orders WHERE order_code = 'ORD002'), 5, N'Nhà Giả Kim thay đổi cuộc đời tôi', 0);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT order_id FROM orders WHERE order_code = 'ORD003'), 4, N'Hay nhưng dài quá', 0);

INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), SYSDATE - 5, N'Muốn mua tập 2 Harry Potter');

INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), SYSDATE - 3, N'Để dành mua sau');

INSERT INTO wishlists (customer_id, book_id, added_at) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), SYSDATE - 10);

INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), SYSDATE - 2, N'Sách này hay quá nhưng chưa có tiền mua');

INSERT INTO wishlists (customer_id, book_id, added_at, is_notified) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT book_id FROM books WHERE isbn = '9786041026748'), SYSDATE - 20, 1);

INSERT INTO wishlists (customer_id, book_id, added_at) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), SYSDATE - 1);

COMMIT;

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_daily_branch_sales';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT IN (-12003, -942) THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_secure_profile';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_order_sales_report';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -942 THEN
            RAISE;
        END IF;
END;
/

CREATE OR REPLACE VIEW vw_order_sales_report AS
SELECT
    o.order_id,
    o.order_code,
    o.order_date,
    o.status_code,
    o.branch_id,
    br.branch_name,
    o.customer_id,
    c.full_name AS customer_name,
    c.email AS customer_email,
    o.coupon_id,
    cp.coupon_code,
    o.total_amount,
    o.discount_amount,
    o.shipping_fee,
    o.final_amount,
    od.detail_id,
    od.book_id,
    b.title AS book_title,
    b.isbn,
    cat.category_id,
    cat.category_name,
    pub.publisher_id,
    pub.publisher_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) AS line_subtotal,
    CASE
        WHEN o.total_amount > 0 THEN ROUND((od.quantity * od.unit_price) / o.total_amount * 100, 2)
        ELSE 0
    END AS line_weight_percent
FROM orders o
JOIN branches br
    ON br.branch_id = o.branch_id
JOIN customers c
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON od.order_id = o.order_id
JOIN books b
    ON b.book_id = od.book_id
LEFT JOIN categories cat
    ON cat.category_id = b.category_id
LEFT JOIN publishers pub
    ON pub.publisher_id = b.publisher_id
LEFT JOIN coupons cp
    ON cp.coupon_id = o.coupon_id;
/

CREATE OR REPLACE VIEW vw_customer_secure_profile AS
SELECT
    c.customer_id,
    c.full_name,
    CASE
        WHEN c.email IS NULL THEN NULL
        WHEN INSTR(c.email, '@') > 3 THEN SUBSTR(c.email, 1, 2) || '***' || SUBSTR(c.email, INSTR(c.email, '@'))
        ELSE '***' || SUBSTR(c.email, INSTR(c.email, '@'))
    END AS masked_email,
    CASE
        WHEN c.phone IS NULL THEN NULL
        WHEN LENGTH(c.phone) >= 7 THEN SUBSTR(c.phone, 1, 3) || '****' || SUBSTR(c.phone, -3)
        ELSE '***MASKED***'
    END AS masked_phone,
    CASE
        WHEN c.address IS NULL THEN NULL
        WHEN INSTR(c.address, ',') > 0 THEN N'***, ' || TRIM(SUBSTR(c.address, INSTR(c.address, ',') + 1))
        ELSE N'***MASKED ADDRESS***'
    END AS masked_address,
    c.province,
    c.district,
    c.created_at,
    c.updated_at,
    NVL(s.total_orders, 0) AS total_orders,
    NVL(s.total_spent, 0) AS total_spent,
    CASE
        WHEN NVL(s.total_spent, 0) >= 5000000 THEN 'VIP'
        WHEN NVL(s.total_spent, 0) >= 1500000 THEN 'LOYAL'
        ELSE 'STANDARD'
    END AS customer_segment
FROM customers c
LEFT JOIN (
    SELECT
        o.customer_id,
        COUNT(*) AS total_orders,
        SUM(o.final_amount) AS total_spent
    FROM orders o
    WHERE o.status_code <> 'CANCELLED'
    GROUP BY o.customer_id
) s
    ON s.customer_id = c.customer_id
WITH READ ONLY;
/

CREATE MATERIALIZED VIEW mv_daily_branch_sales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    TRUNC(o.order_date) AS sale_date,
    o.branch_id,
    br.branch_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.status_code = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN o.status_code = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(od.quantity) AS total_units_sold,
    SUM(od.quantity * od.unit_price) AS gross_merchandise_value,
    SUM(o.discount_amount) AS total_discount_amount,
    SUM(o.shipping_fee) AS total_shipping_fee,
    SUM(o.final_amount) AS total_final_amount
FROM orders o
JOIN branches br
    ON br.branch_id = o.branch_id
JOIN order_details od
    ON od.order_id = o.order_id
GROUP BY
    TRUNC(o.order_date),
    o.branch_id,
    br.branch_name;
/

CREATE OR REPLACE PROCEDURE sp_manage_book (
    p_action            IN VARCHAR2,
    p_book_id           IN OUT NUMBER,
    p_isbn              IN VARCHAR2,
    p_title             IN NVARCHAR2,
    p_description       IN NCLOB,
    p_category_id       IN NUMBER,
    p_publisher_id      IN NUMBER,
    p_price             IN NUMBER,
    p_stock_quantity    IN NUMBER,
    p_publication_year  IN NUMBER,
    p_page_count        IN NUMBER,
    p_language          IN VARCHAR2 DEFAULT 'vi',
    p_cover_type        IN VARCHAR2 DEFAULT 'PAPERBACK',
    p_updated_by        IN NUMBER DEFAULT NULL
)
AS
    v_action          VARCHAR2(10);
    v_count           NUMBER;
    v_dep_count       NUMBER;
BEGIN
    
    v_action := UPPER(TRIM(p_action));

    IF v_action NOT IN ('ADD', 'UPDATE', 'DELETE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Action không hợp lệ. Chỉ hỗ trợ ADD/UPDATE/DELETE.');
    END IF;

    IF v_action = 'ADD' THEN
        
        IF p_title IS NULL OR p_category_id IS NULL OR p_price IS NULL OR p_price < 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Thiếu dữ liệu bắt buộc hoặc giá không hợp lệ khi thêm sách.');
        END IF;

        IF p_stock_quantity IS NOT NULL AND p_stock_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'stock_quantity không được âm.');
        END IF;

        SELECT COUNT(*)
          INTO v_count
          FROM categories
         WHERE category_id = p_category_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Category không tồn tại.');
        END IF;

        IF p_publisher_id IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM publishers
             WHERE publisher_id = p_publisher_id;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20005, 'Publisher không tồn tại.');
            END IF;
        END IF;

        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM books
             WHERE isbn = p_isbn;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20006, 'ISBN đã tồn tại.');
            END IF;
        END IF;

        INSERT INTO books (
            book_id, isbn, title, description, category_id, publisher_id, price,
            stock_quantity, page_count, publication_year, language, cover_type,
            created_at, updated_at, updated_by
        ) VALUES (
            p_book_id, p_isbn, p_title, p_description, p_category_id, p_publisher_id, p_price,
            NVL(p_stock_quantity, 0), p_page_count, p_publication_year, NVL(p_language, 'vi'), p_cover_type,
            SYSDATE, SYSDATE, p_updated_by
        )
        RETURNING book_id INTO p_book_id;

    ELSIF v_action = 'UPDATE' THEN
        
        SELECT COUNT(*)
          INTO v_count
          FROM books
         WHERE book_id = p_book_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Không tìm thấy sách để cập nhật.');
        END IF;

        IF p_price IS NOT NULL AND p_price < 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Giá sách không được âm.');
        END IF;

        IF p_stock_quantity IS NOT NULL AND p_stock_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'stock_quantity không được âm.');
        END IF;

        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM books
             WHERE isbn = p_isbn
               AND book_id <> p_book_id;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20010, 'ISBN đã được dùng bởi sách khác.');
            END IF;
        END IF;

        UPDATE books
           SET isbn = COALESCE(p_isbn, isbn),
               title = COALESCE(p_title, title),
               description = COALESCE(p_description, description),
               category_id = COALESCE(p_category_id, category_id),
               publisher_id = COALESCE(p_publisher_id, publisher_id),
               price = COALESCE(p_price, price),
               stock_quantity = COALESCE(p_stock_quantity, stock_quantity),
               publication_year = COALESCE(p_publication_year, publication_year),
               page_count = COALESCE(p_page_count, page_count),
               language = COALESCE(p_language, language),
               cover_type = COALESCE(p_cover_type, cover_type),
               updated_at = SYSDATE,
               updated_by = p_updated_by
         WHERE book_id = p_book_id;

    ELSE
        
        SELECT COUNT(*)
          INTO v_dep_count
          FROM order_details
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Không thể xóa sách đã phát sinh đơn hàng.');
        END IF;

        SELECT COUNT(*)
          INTO v_dep_count
          FROM cart_items
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Không thể xóa sách đang nằm trong giỏ hàng.');
        END IF;

        DELETE FROM books
         WHERE book_id = p_book_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Không tìm thấy sách để xóa.');
        END IF;
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20014, 'Vi phạm ràng buộc duy nhất (ISBN hoặc khóa unique khác).');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'Lỗi sp_manage_book: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE sp_report_monthly_sales (
    p_from_date      IN DATE,
    p_to_date        IN DATE,
    p_branch_id      IN NUMBER DEFAULT NULL,
    p_result         OUT SYS_REFCURSOR
)
AS
BEGIN
    IF p_from_date IS NULL OR p_to_date IS NULL OR p_from_date > p_to_date THEN
        RAISE_APPLICATION_ERROR(-20101, 'Khoảng ngày báo cáo không hợp lệ.');
    END IF;

    OPEN p_result FOR
        SELECT TO_CHAR(TRUNC(o.order_date, 'MM'), 'YYYY-MM') AS month_key,
               COUNT(*) AS total_orders,
               SUM(CASE WHEN o.status_code = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
               SUM(CASE WHEN o.status_code = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
               SUM(o.total_amount) AS gross_amount,
               SUM(o.discount_amount) AS total_discount,
               SUM(o.shipping_fee) AS total_shipping_fee,
               SUM(o.final_amount) AS final_amount_sum,
               SUM(CASE WHEN o.status_code = 'DELIVERED' THEN o.final_amount ELSE 0 END) AS delivered_revenue
          FROM orders o
         WHERE o.order_date >= TRUNC(p_from_date)
           AND o.order_date < TRUNC(p_to_date) + 1
           AND (p_branch_id IS NULL OR o.branch_id = p_branch_id)
         GROUP BY TRUNC(o.order_date, 'MM')
         ORDER BY TRUNC(o.order_date, 'MM');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20102, 'Lỗi sp_report_monthly_sales: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE sp_print_low_stock_inventory (
    p_branch_id IN NUMBER DEFAULT NULL
)
AS
    CURSOR c_low_stock IS
        SELECT bi.branch_id,
               br.branch_name,
               bi.book_id,
               b.title,
               bi.quantity_available,
               bi.low_stock_threshold
          FROM branch_inventory bi
          JOIN branches br ON br.branch_id = bi.branch_id
          JOIN books b ON b.book_id = bi.book_id
         WHERE bi.quantity_available <= bi.low_stock_threshold
           AND (p_branch_id IS NULL OR bi.branch_id = p_branch_id)
         ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;

    v_row   c_low_stock%ROWTYPE;
    v_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DANH SACH SACH SAP HET HANG ===');
    IF p_branch_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Phạm vi: TOAN HE THONG');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Phạm vi: CHI NHANH ID = ' || p_branch_id);
    END IF;

    OPEN c_low_stock;
    LOOP
        FETCH c_low_stock INTO v_row;
        EXIT WHEN c_low_stock%NOTFOUND;

        v_total := v_total + 1;
        DBMS_OUTPUT.PUT_LINE(
            'Branch=' || v_row.branch_id ||
            ' | BranchName=' || v_row.branch_name ||
            ' | Book=' || v_row.book_id ||
            ' | Title=' || v_row.title ||
            ' | Avail=' || v_row.quantity_available ||
            ' | Threshold=' || v_row.low_stock_threshold
        );
    END LOOP;
    CLOSE c_low_stock;

    DBMS_OUTPUT.PUT_LINE('Tong so dong can canh bao: ' || v_total);
EXCEPTION
    WHEN OTHERS THEN
        IF c_low_stock%ISOPEN THEN
            CLOSE c_low_stock;
        END IF;
        RAISE_APPLICATION_ERROR(-20201, 'Lỗi sp_print_low_stock_inventory: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE sp_calculate_coupon_discount (
    p_coupon_code      IN VARCHAR2,
    p_order_amount     IN NUMBER,
    p_discount_amount  OUT NUMBER,
    p_message          OUT NVARCHAR2
)
AS
    v_discount_type       coupons.discount_type%TYPE;
    v_discount_value      coupons.discount_value%TYPE;
    v_start_date          coupons.start_date%TYPE;
    v_end_date            coupons.end_date%TYPE;
    v_usage_limit         coupons.usage_limit%TYPE;
    v_usage_count         coupons.usage_count%TYPE;
    v_min_order_amount    coupons.min_order_amount%TYPE;
    v_max_discount_amount coupons.max_discount_amount%TYPE;
    v_is_active           coupons.is_active%TYPE;
BEGIN
    p_discount_amount := 0;
    p_message := N'COUPON_INVALID';

    IF p_order_amount IS NULL OR p_order_amount <= 0 THEN
        p_message := N'ORDER_AMOUNT_INVALID';
        RETURN;
    END IF;

    SELECT discount_type,
           discount_value,
           start_date,
           end_date,
           usage_limit,
           usage_count,
           min_order_amount,
           max_discount_amount,
           is_active
      INTO v_discount_type,
           v_discount_value,
           v_start_date,
           v_end_date,
           v_usage_limit,
           v_usage_count,
           v_min_order_amount,
           v_max_discount_amount,
           v_is_active
      FROM coupons
     WHERE coupon_code = p_coupon_code;

    IF v_is_active <> 1 THEN
        p_message := N'COUPON_NOT_ACTIVE';
        RETURN;
    END IF;

    IF TRUNC(SYSDATE) < TRUNC(v_start_date) OR TRUNC(SYSDATE) > TRUNC(v_end_date) THEN
        p_message := N'COUPON_OUT_OF_DATE';
        RETURN;
    END IF;

    IF v_usage_limit IS NOT NULL AND v_usage_count >= v_usage_limit THEN
        p_message := N'COUPON_EXHAUSTED';
        RETURN;
    END IF;

    IF p_order_amount < NVL(v_min_order_amount, 0) THEN
        p_message := N'ORDER_NOT_ENOUGH_FOR_COUPON';
        RETURN;
    END IF;

    IF v_discount_type = 'PERCENT' THEN
        p_discount_amount := ROUND(p_order_amount * v_discount_value / 100, 2);
    ELSE
        p_discount_amount := v_discount_value;
    END IF;

    IF v_max_discount_amount IS NOT NULL THEN
        p_discount_amount := LEAST(p_discount_amount, v_max_discount_amount);
    END IF;

    p_discount_amount := LEAST(p_discount_amount, p_order_amount);
    p_message := N'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_discount_amount := 0;
        p_message := N'COUPON_NOT_FOUND';
    WHEN TOO_MANY_ROWS THEN
        p_discount_amount := 0;
        p_message := N'COUPON_CODE_DUPLICATED';
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20301, 'Lỗi sp_calculate_coupon_discount: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER trg_biu_orders_validation
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
BEGIN
    
    :NEW.total_amount := NVL(:NEW.total_amount, 0);
    :NEW.discount_amount := NVL(:NEW.discount_amount, 0);
    :NEW.shipping_fee := NVL(:NEW.shipping_fee, 0);
    :NEW.final_amount := NVL(:NEW.final_amount, 0);

    IF UPDATING THEN
        :NEW.updated_at := SYSDATE;
    END IF;

    IF :NEW.total_amount < 0 OR :NEW.discount_amount < 0 OR :NEW.shipping_fee < 0 OR :NEW.final_amount < 0 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Gia tri tien te trong ORDERS khong duoc am.');
    END IF;

    IF ROUND(:NEW.final_amount, 2) <> ROUND(:NEW.total_amount - :NEW.discount_amount + :NEW.shipping_fee, 2) THEN
        RAISE_APPLICATION_ERROR(-20502, 'final_amount phai = total_amount - discount_amount + shipping_fee.');
    END IF;

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

BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_orders_audit_log START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -955 THEN
            RAISE;
        END IF;
END;
/

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

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 220;

PROMPT ==========================================
PROMPT BUOC 7 - INDEXING VA TOI UU HOA
PROMPT ==========================================

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_orders_recent_date';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_binv_low_stock';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_orders_trunc_order_date';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX idx_books_category_bm';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> -1418 THEN
            RAISE;
        END IF;
END;
/

PROMPT ==========================================
PROMPT Q1 BEFORE - Recent orders dashboard
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_BEFORE' FOR
SELECT
    o.order_id,
    o.order_code,
    c.full_name,
    o.final_amount,
    o.status_code,
    o.order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id DESC
FETCH FIRST 5 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_BEFORE', 'BASIC +PREDICATE +NOTE'));

CREATE INDEX idx_orders_recent_date
    ON orders (order_date DESC, order_id DESC);

PROMPT ==========================================
PROMPT Q1 AFTER - Recent orders dashboard
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q1_AFTER' FOR
SELECT
    o.order_id,
    o.order_code,
    c.full_name,
    o.final_amount,
    o.status_code,
    o.order_date
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id DESC
FETCH FIRST 5 ROWS ONLY;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q1_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q2 BEFORE - Low stock inventory by branch
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_BEFORE' FOR
SELECT
    bi.branch_id,
    bi.book_id,
    bi.quantity_available,
    bi.low_stock_threshold
FROM branch_inventory bi
WHERE bi.quantity_available <= bi.low_stock_threshold
ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_BEFORE', 'BASIC +PREDICATE +NOTE'));

CREATE INDEX idx_binv_low_stock
    ON branch_inventory (branch_id, quantity_available, low_stock_threshold, book_id);

PROMPT ==========================================
PROMPT Q2 AFTER - Low stock inventory by branch
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q2_AFTER' FOR
SELECT
    bi.branch_id,
    bi.book_id,
    bi.quantity_available,
    bi.low_stock_threshold
FROM branch_inventory bi
WHERE bi.quantity_available <= bi.low_stock_threshold
ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q2_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q3 BEFORE - Daily sales by date
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_BEFORE' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.final_amount) AS total_revenue
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_BEFORE', 'BASIC +PREDICATE +NOTE'));

CREATE INDEX idx_orders_trunc_order_date
    ON orders (TRUNC(order_date));

PROMPT ==========================================
PROMPT Q3 AFTER - Daily sales by date
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q3_AFTER' FOR
SELECT
    TRUNC(o.order_date) AS sale_day,
    COUNT(*) AS total_orders,
    SUM(o.final_amount) AS total_revenue
FROM orders o
WHERE TRUNC(o.order_date) BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
GROUP BY TRUNC(o.order_date)
ORDER BY sale_day;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q3_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT Q4 BEFORE - Category analytics
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_BEFORE' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 7, 8)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q4_BEFORE', 'BASIC +PREDICATE +NOTE'));

CREATE BITMAP INDEX idx_books_category_bm
    ON books (category_id);

PROMPT ==========================================
PROMPT Q4 AFTER - Category analytics
PROMPT ==========================================

EXPLAIN PLAN SET STATEMENT_ID = 'B7_Q4_AFTER' FOR
SELECT
    b.category_id,
    COUNT(*) AS total_books,
    ROUND(AVG(b.price), 2) AS avg_price
FROM books b
WHERE b.category_id IN (4, 7, 8)
GROUP BY b.category_id
ORDER BY b.category_id;

SELECT PLAN_TABLE_OUTPUT
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'B7_Q4_AFTER', 'BASIC +PREDICATE +NOTE'));

PROMPT ==========================================
PROMPT KIEM TRA CAC INDEX VUA TAO
PROMPT ==========================================

SELECT
    index_name,
    index_type,
    table_name,
    status,
    visibility
FROM user_indexes
WHERE index_name IN (
    'IDX_ORDERS_RECENT_DATE',
    'IDX_BINV_LOW_STOCK',
    'IDX_ORDERS_TRUNC_ORDER_DATE',
    'IDX_BOOKS_CATEGORY_BM'
)
ORDER BY index_name;

SET SERVEROUTPUT ON;

DEFINE APP_SCHEMA = 'AUTO';

DECLARE
    v_owner  VARCHAR2(128) := UPPER('&&APP_SCHEMA');
    v_found  VARCHAR2(128);
    v_con_name VARCHAR2(128);
    v_pdb_name VARCHAR2(128);

    PROCEDURE exec_optional(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    PROCEDURE exec_required(p_sql IN VARCHAR2, p_step IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20800, p_step || ' that bai: ' || SQLERRM);
    END;

    PROCEDURE grant_object_priv(p_privs IN VARCHAR2, p_obj IN VARCHAR2, p_role IN VARCHAR2) IS
        v_cnt NUMBER;
        v_sql VARCHAR2(1000);
    BEGIN
        SELECT COUNT(*)
          INTO v_cnt
          FROM all_objects
         WHERE owner = v_owner
           AND object_name = UPPER(p_obj)
           AND object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW', 'PROCEDURE');

        IF v_cnt = 0 THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Khong tim thay object ' || v_owner || '.' || UPPER(p_obj) || ', bo qua.');
            RETURN;
        END IF;

        v_sql := 'GRANT ' || p_privs || ' ON ' || v_owner || '.' || UPPER(p_obj) || ' TO ' || UPPER(p_role);
        EXECUTE IMMEDIATE v_sql;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: Grant loi (' || p_obj || ' -> ' || p_role || '): ' || SQLERRM);
    END;

    PROCEDURE ensure_working_container IS
    BEGIN
        SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
          INTO v_con_name
          FROM dual;

        IF USER = 'SYS' AND v_con_name = 'CDB$ROOT' THEN
            BEGIN
                SELECT name
                  INTO v_pdb_name
                  FROM (
                        SELECT name
                          FROM v$pdbs
                         WHERE name <> 'PDB$SEED'
                           AND open_mode = 'READ WRITE'
                         ORDER BY con_id
                       )
                 WHERE ROWNUM = 1;

                EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_pdb_name);
                DBMS_OUTPUT.PUT_LINE('INFO: Dang chay bang SYS o CDB$ROOT, da chuyen sang PDB ' || v_pdb_name || '.');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20801,
                        'Dang o CDB$ROOT nhung khong co PDB nao dang READ WRITE. ' ||
                        'Hay ALTER SESSION SET CONTAINER vao PDB ung dung truoc khi chay script.'
                    );
            END;
        END IF;
    END;
BEGIN
    ensure_working_container;

    IF v_owner = 'AUTO' THEN
        BEGIN
            SELECT owner
              INTO v_found
              FROM (
                    SELECT owner, COUNT(*) AS score
                      FROM all_objects
                     WHERE object_name IN (
                           'BOOKS', 'ORDERS', 'CUSTOMERS',
                           'VW_ORDER_SALES_REPORT', 'SP_MANAGE_BOOK'
                       )
                     GROUP BY owner
                     ORDER BY score DESC
                   )
             WHERE ROWNUM = 1;
            v_owner := v_found;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_owner := USER;
        END;
    END IF;

    DBMS_OUTPUT.PUT_LINE('INFO: APP_SCHEMA = ' || v_owner);

    exec_optional('DROP USER DIGIBOOK_GUEST CASCADE');
    exec_optional('DROP USER DIGIBOOK_STAFF CASCADE');
    exec_optional('DROP USER DIGIBOOK_ADMIN CASCADE');
    exec_optional('DROP ROLE DIGIBOOK_GUEST');
    exec_optional('DROP ROLE DIGIBOOK_STAFF');
    exec_optional('DROP ROLE DIGIBOOK_ADMIN');
    exec_optional('DROP ROLE GUEST_ROLE');
    exec_optional('DROP ROLE STAFF_ROLE');
    exec_optional('DROP ROLE ADMIN_ROLE');

    exec_required('CREATE ROLE ADMIN_ROLE', 'CREATE ROLE ADMIN_ROLE');
    exec_required('CREATE ROLE STAFF_ROLE', 'CREATE ROLE STAFF_ROLE');
    exec_required('CREATE ROLE GUEST_ROLE', 'CREATE ROLE GUEST_ROLE');

    exec_required('GRANT CREATE SESSION TO ADMIN_ROLE', 'GRANT CREATE SESSION ADMIN_ROLE');
    exec_required('GRANT CREATE SESSION TO STAFF_ROLE', 'GRANT CREATE SESSION STAFF_ROLE');
    exec_required('GRANT CREATE SESSION TO GUEST_ROLE', 'GRANT CREATE SESSION GUEST_ROLE');

    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BRANCHES', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'USERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'STAFF', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BOOKS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'CUSTOMERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDERS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'ORDER_DETAILS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'BRANCH_INVENTORY', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'INVENTORY_TRANSACTIONS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'COUPONS', 'ADMIN_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE, DELETE', 'PAYMENT_TRANSACTIONS', 'ADMIN_ROLE');

    grant_object_priv('SELECT', 'BRANCHES', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'BOOKS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'CUSTOMERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDERS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'ORDER_DETAILS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'ORDER_STATUS_HISTORY', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'BRANCH_INVENTORY', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT', 'INVENTORY_TRANSACTIONS', 'STAFF_ROLE');
    grant_object_priv('SELECT, INSERT, UPDATE', 'PAYMENT_TRANSACTIONS', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'COUPONS', 'STAFF_ROLE');

    grant_object_priv('SELECT', 'BOOKS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'BOOK_IMAGES', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'CATEGORIES', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'AUTHORS', 'GUEST_ROLE');
    grant_object_priv('SELECT', 'PUBLISHERS', 'GUEST_ROLE');

    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'ADMIN_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_BRANCH_SALES', 'ADMIN_ROLE');

    grant_object_priv('SELECT', 'VW_ORDER_SALES_REPORT', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'STAFF_ROLE');
    grant_object_priv('SELECT', 'MV_DAILY_BRANCH_SALES', 'STAFF_ROLE');

    grant_object_priv('SELECT', 'VW_CUSTOMER_SECURE_PROFILE', 'GUEST_ROLE');

    grant_object_priv('EXECUTE', 'SP_MANAGE_BOOK', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_INVENTORY', 'ADMIN_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'ADMIN_ROLE');

    grant_object_priv('EXECUTE', 'SP_REPORT_MONTHLY_SALES', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_PRINT_LOW_STOCK_INVENTORY', 'STAFF_ROLE');
    grant_object_priv('EXECUTE', 'SP_CALCULATE_COUPON_DISCOUNT', 'STAFF_ROLE');

    exec_required('CREATE USER DIGIBOOK_ADMIN IDENTIFIED BY "DigiBook#Admin2026"', 'CREATE USER ADMIN');
    exec_required('CREATE USER DIGIBOOK_STAFF IDENTIFIED BY "DigiBook#Staff2026"', 'CREATE USER STAFF');
    exec_required('CREATE USER DIGIBOOK_GUEST IDENTIFIED BY "DigiBook#Guest2026"', 'CREATE USER GUEST');

    exec_required('GRANT ADMIN_ROLE TO DIGIBOOK_ADMIN', 'GRANT ADMIN_ROLE');
    exec_required('GRANT STAFF_ROLE TO DIGIBOOK_STAFF', 'GRANT STAFF_ROLE');
    exec_required('GRANT GUEST_ROLE TO DIGIBOOK_GUEST', 'GRANT GUEST_ROLE');

    exec_required('ALTER USER DIGIBOOK_ADMIN DEFAULT ROLE ALL', 'ALTER USER ADMIN DEFAULT ROLE');
    exec_required('ALTER USER DIGIBOOK_STAFF DEFAULT ROLE ALL', 'ALTER USER STAFF DEFAULT ROLE');
    exec_required('ALTER USER DIGIBOOK_GUEST DEFAULT ROLE ALL', 'ALTER USER GUEST DEFAULT ROLE');

    DBMS_OUTPUT.PUT_LINE('INFO: Hoan tat buoc 8.');
END;
/

SET SERVEROUTPUT ON;

ROLLBACK;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DECLARE
    
    v_branch_id       NUMBER := 1;
    v_quantity        NUMBER := 2;
    v_ship_fee        NUMBER := 25000;

    v_customer_id     customers.customer_id%TYPE;
    v_staff_id        staff.staff_id%TYPE;
    v_book_id         books.book_id%TYPE;
    v_unit_price      books.price%TYPE;
    v_order_id        orders.order_id%TYPE;
    v_order_code      orders.order_code%TYPE;
    v_avail_before    branch_inventory.quantity_available%TYPE;
    v_avail_after     branch_inventory.quantity_available%TYPE;

    e_insufficient_stock EXCEPTION;
    e_resource_busy      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_resource_busy, -54); 
BEGIN
    
    SELECT customer_id
      INTO v_customer_id
      FROM customers
     WHERE ROWNUM = 1;

    SELECT staff_id
      INTO v_staff_id
      FROM staff
     WHERE branch_id = v_branch_id
       AND ROWNUM = 1;

    SELECT bi.book_id,
           bi.quantity_available,
           b.price
      INTO v_book_id, v_avail_before, v_unit_price
      FROM branch_inventory bi
      JOIN books b
        ON b.book_id = bi.book_id
     WHERE bi.branch_id = v_branch_id
       AND bi.quantity_available >= v_quantity
       AND ROWNUM = 1
     FOR UPDATE WAIT 5;

    IF v_avail_before < v_quantity THEN
        RAISE e_insufficient_stock;
    END IF;

    v_order_code := 'DEMO_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

    INSERT INTO orders (
        order_code,
        customer_id,
        branch_id,
        status_code,
        shipping_method_id,
        total_amount,
        discount_amount,
        shipping_fee,
        final_amount,
        order_date,
        ship_address,
        ship_province,
        ship_district,
        ship_phone,
        created_by
    ) VALUES (
        v_order_code,
        v_customer_id,
        v_branch_id,
        'PENDING',
        1,
        0,
        0,
        v_ship_fee,
        v_ship_fee,
        SYSDATE,
        N'Demo transaction Oracle 19c',
        N'TP. Hồ Chí Minh',
        N'Quận 1',
        '0900000000',
        v_staff_id
    )
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_details (order_id, book_id, quantity, unit_price)
    VALUES (v_order_id, v_book_id, v_quantity, v_unit_price);

    UPDATE orders
       SET total_amount = (v_quantity * v_unit_price),
           final_amount = (v_quantity * v_unit_price) + shipping_fee - discount_amount,
           updated_at = SYSDATE,
           updated_by = v_staff_id
     WHERE order_id = v_order_id;

    UPDATE branch_inventory
       SET quantity_available = quantity_available - v_quantity,
           quantity_reserved = quantity_reserved + v_quantity,
           updated_at = SYSDATE,
           updated_by = v_staff_id
     WHERE branch_id = v_branch_id
       AND book_id = v_book_id;

    INSERT INTO inventory_transactions (
        branch_id,
        book_id,
        txn_type,
        reference_id,
        reference_type,
        quantity,
        unit_cost,
        total_cost,
        notes,
        created_by
    ) VALUES (
        v_branch_id,
        v_book_id,
        'OUT',
        v_order_id,
        'ORDER',
        -v_quantity,
        v_unit_price,
        (v_quantity * v_unit_price),
        N'Buoc 9 - Tru kho cho don demo',
        v_staff_id
    );

    INSERT INTO order_status_history (
        order_id,
        old_status,
        new_status,
        changed_by,
        changed_at,
        reason
    ) VALUES (
        v_order_id,
        NULL,
        'PENDING',
        v_staff_id,
        SYSDATE,
        N'Tao don demo transaction'
    );

    SELECT quantity_available
      INTO v_avail_after
      FROM branch_inventory
     WHERE branch_id = v_branch_id
       AND book_id = v_book_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('=== TRANSACTION THANH CONG ===');
    DBMS_OUTPUT.PUT_LINE('Order ID         : ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('Order Code       : ' || v_order_code);
    DBMS_OUTPUT.PUT_LINE('Branch ID        : ' || v_branch_id);
    DBMS_OUTPUT.PUT_LINE('Book ID          : ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('So luong mua     : ' || v_quantity);
    DBMS_OUTPUT.PUT_LINE('Ton truoc giao dich: ' || v_avail_before);
    DBMS_OUTPUT.PUT_LINE('Ton sau giao dich  : ' || v_avail_after);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Khong tim thay du lieu dau vao phu hop.');
    WHEN e_insufficient_stock THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ton kho khong du.');
    WHEN e_resource_busy THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Ban ghi dang bi khoa boi session khac (ORA-00054).');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK: Loi khac - ' || SQLERRM);
END;
/

