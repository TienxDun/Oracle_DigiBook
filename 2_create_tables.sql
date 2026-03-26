-- ==========================================================
-- FILE: 2_create_tables.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Tạo schema đa chi nhánh (Multi-Branch) cho hệ thống bán sách
-- ORACLE VERSION: 19c
-- ==========================================================

-- ==========================================================
-- A. SEQUENCES - Auto-increment cho tất cả bảng (Quản lý chung)
-- ==========================================================

CREATE SEQUENCE seq_branches START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_staff START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_categories START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_authors START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_publishers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_books START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_book_images START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_book_authors START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; -- Bảng trung gian
CREATE SEQUENCE seq_customers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_shipping_methods START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_details START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_status_his START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; -- Audit log
CREATE SEQUENCE seq_carts START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_cart_items START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_branch_inventory START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_inventory_transfers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_transfer_details START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE; -- Chi tiết điều chuyển
CREATE SEQUENCE seq_inventory_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_payment_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_coupons START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_reviews START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_wishlists START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ==========================================================
-- B. PHẦN VIỆC CỦA DŨNG: HỆ THỐNG & CHI NHÁNH (System & Branch)
-- ==========================================================

-- 1. Bảng Chi nhánh (Multi-branch core)
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
    manager_id          NUMBER, -- FK đến staff (sẽ thêm sau)
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

-- 2. Trạng thái đơn hàng (Lookup table)
CREATE TABLE order_statuses (
    status_code         VARCHAR2(20),
    status_name         NVARCHAR2(50) NOT NULL,
    status_name_vi      NVARCHAR2(50) NOT NULL,
    description         NVARCHAR2(200),
    display_order       NUMBER NOT NULL,
    color_code          VARCHAR2(7) DEFAULT '#000000',
    is_terminal         NUMBER(1) DEFAULT 0,
    allowed_next_status VARCHAR2(200), -- JSON array
    require_payment     NUMBER(1) DEFAULT 0,
    is_active           NUMBER(1) DEFAULT 1,
    CONSTRAINT pk_order_statuses PRIMARY KEY (status_code),
    CONSTRAINT ck_osts_is_terminal CHECK (is_terminal IN (0, 1)),
    CONSTRAINT ck_osts_require_payment CHECK (require_payment IN (0, 1)),
    CONSTRAINT ck_osts_is_active CHECK (is_active IN (0, 1))
);

-- 3. Người dùng hệ thống (Authentication)
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

-- 4. Nhân viên (Liên kết User với Chi nhánh)
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

-- Thêm FK cho branches.manager_id (sau khi đã tạo bảng staff)
ALTER TABLE branches ADD CONSTRAINT fk_branch_manager 
    FOREIGN KEY (manager_id) REFERENCES staff(staff_id);

-- Thêm FK self-referencing cho users
ALTER TABLE users ADD CONSTRAINT fk_users_created_by 
    FOREIGN KEY (created_by) REFERENCES users(user_id);
ALTER TABLE users ADD CONSTRAINT fk_users_updated_by 
    FOREIGN KEY (updated_by) REFERENCES users(user_id);

-- ==========================================================
-- C. PHẦN VIỆC CỦA NAM: DANH MỤC SẢN PHẨM (Catalog)
-- ==========================================================

-- 5. Danh mục sách (Cấu trúc cây)
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

-- 6. Tác giả
CREATE TABLE authors (
    author_id           NUMBER,
    author_name         NVARCHAR2(150) NOT NULL,
    biography           NCLOB,
    birth_date          DATE,
    nationality         NVARCHAR2(50),
    created_at          DATE DEFAULT SYSDATE,
    CONSTRAINT pk_authors PRIMARY KEY (author_id)
);

-- 7. Nhà xuất bản
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

-- 8. Sách (Books)
CREATE TABLE books (
    book_id             NUMBER,
    isbn                VARCHAR2(20),
    title               NVARCHAR2(300) NOT NULL,
    description         NCLOB,
    category_id         NUMBER NOT NULL,
    publisher_id        NUMBER,
    price               NUMBER(12,2) NOT NULL,
    stock_quantity      NUMBER DEFAULT 0, -- Tổng tồn kho toàn hệ thống (denormalized)
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

-- 9. Hình ảnh sách
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

-- 10. Quan hệ nhiều-nhiều: Sách - Tác giả (Fix lỗi thiết kế 1-n)
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

-- ==========================================================
-- D. PHẦN VIỆC CỦA HIẾU: KHÁCH HÀNG & BÁN HÀNG (Sales)
-- ==========================================================

-- 11. Khách hàng
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
    preferred_branch_id NUMBER, -- Chi nhánh ưa thích
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

-- 12. Phương thức vận chuyển
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

-- 13. Giỏ hàng (Carts)
CREATE TABLE carts (
    cart_id             NUMBER,
    customer_id         NUMBER NOT NULL,
    branch_id           NUMBER NOT NULL, -- Giỏ hàng thuộc chi nhánh nào
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

-- 14. Chi tiết giỏ hàng (Cart Items)
CREATE TABLE cart_items (
    cart_item_id        NUMBER,
    cart_id             NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity            NUMBER NOT NULL,
    unit_price          NUMBER(12,2) NOT NULL, -- Giá tại thời điểm thêm vào
    added_at            DATE DEFAULT SYSDATE,
    updated_at          DATE,
    CONSTRAINT pk_cart_items PRIMARY KEY (cart_item_id),
    CONSTRAINT fk_ci_cart FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    CONSTRAINT fk_ci_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT uq_ci_cart_book UNIQUE (cart_id, book_id),
    CONSTRAINT ck_ci_qty CHECK (quantity > 0),
    CONSTRAINT ck_ci_price CHECK (unit_price >= 0)
);

-- 15. Đơn hàng (Orders)
CREATE TABLE orders (
    order_id            NUMBER,
    order_code          VARCHAR2(30) NOT NULL,
    customer_id         NUMBER NOT NULL,
    branch_id           NUMBER NOT NULL, -- Đơn hàng thuộc chi nhánh nào
    status_code         VARCHAR2(20) NOT NULL,
    shipping_method_id  NUMBER,
    coupon_id           NUMBER, -- Sẽ thêm FK sau khi tạo bảng coupons
    total_amount        NUMBER(12,2) DEFAULT 0 NOT NULL,
    discount_amount     NUMBER(12,2) DEFAULT 0,
    shipping_fee        NUMBER(10,2) DEFAULT 0,
    final_amount        NUMBER(12,2) DEFAULT 0, -- total - discount + ship
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

-- 16. Chi tiết đơn hàng
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

-- 17. Lịch sử trạng thái đơn hàng (Audit)
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

-- ==========================================================
-- E. PHẦN VIỆC CỦA PHÁT: KHO VẬN & NGHIỆP VỤ KHÁC (Inventory & Others)
-- ==========================================================

-- 18. Tồn kho theo chi nhánh (Branch Inventory - Core of Multi-branch)
CREATE TABLE branch_inventory (
    inventory_id        NUMBER,
    branch_id           NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    quantity_available  NUMBER DEFAULT 0 NOT NULL, -- Có thể bán
    quantity_reserved   NUMBER DEFAULT 0 NOT NULL, -- Đã giữ cho đơn hàng
    quantity_transit_in NUMBER DEFAULT 0 NOT NULL, -- Đang về
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
    -- Constraint quan trọng: Available phải >= Reserved
    CONSTRAINT ck_binv_logic CHECK (quantity_available >= quantity_reserved)
);

-- 19. Phiếu điều chuyển kho (Inventory Transfers)
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

-- 20. Chi tiết điều chuyển (Transfer Details)
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

-- 21. Giao dịch kho (Inventory Transactions - Log mọi thay đổi kho)
CREATE TABLE inventory_transactions (
    txn_id              NUMBER,
    branch_id           NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    txn_type            VARCHAR2(20) NOT NULL, -- IN, OUT, ADJUST, TRANSFER_IN, TRANSFER_OUT
    reference_id        NUMBER,
    reference_type      VARCHAR2(20), -- ORDER, TRANSFER, ADJUSTMENT, INITIAL
    reference_detail    VARCHAR2(50),
    quantity            NUMBER NOT NULL, -- Dương: nhập, Âm: xuất
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

-- 22. Mã giảm giá (Coupons)
CREATE TABLE coupons (
    coupon_id           NUMBER,
    coupon_code         VARCHAR2(20) NOT NULL,
    coupon_name         NVARCHAR2(100) NOT NULL,
    description         NVARCHAR2(500),
    discount_type       VARCHAR2(10) NOT NULL, -- PERCENT, FIXED
    discount_value      NUMBER(12,2) NOT NULL,
    min_order_amount    NUMBER(12,2) DEFAULT 0,
    max_discount_amount NUMBER(12,2),
    usage_limit         NUMBER,
    usage_count         NUMBER DEFAULT 0,
    per_customer_limit  NUMBER DEFAULT 1,
    applicable_branches VARCHAR2(500), -- JSON array, NULL = all branches
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

-- Thêm FK cho orders.coupon_id (sau khi tạo bảng coupons)
ALTER TABLE orders ADD CONSTRAINT fk_order_coupon 
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id);

-- 23. Thanh toán (Payment Transactions)
CREATE TABLE payment_transactions (
    transaction_id      NUMBER,
    order_id            NUMBER NOT NULL,
    branch_id           NUMBER, -- Chi nhánh thu tiền
    payment_method      VARCHAR2(30) NOT NULL,
    amount              NUMBER(12,2) NOT NULL,
    currency            VARCHAR2(3) DEFAULT 'VND',
    status              VARCHAR2(20) DEFAULT 'PENDING',
    transaction_code    VARCHAR2(100), -- Mã giao dịch từ cổng thanh toán
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

-- 24. Đánh giá sản phẩm (Reviews)
CREATE TABLE reviews (
    review_id           NUMBER,
    customer_id         NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    order_id            NUMBER NOT NULL, -- Đảm bảo chỉ review sách đã mua
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
    CONSTRAINT uq_rev_order_book UNIQUE (order_id, book_id) -- Mỗi đơn chỉ review 1 lần/1 sách
);

-- 25. Danh sách yêu thích (Wishlists)
CREATE TABLE wishlists (
    wishlist_id         NUMBER,
    customer_id         NUMBER NOT NULL,
    book_id             NUMBER NOT NULL,
    added_at            DATE DEFAULT SYSDATE,
    note                NVARCHAR2(500),
    is_notified         NUMBER(1) DEFAULT 0, -- Đã thông báo khi có hàng?
    notification_sent_at DATE,
    CONSTRAINT pk_wishlists PRIMARY KEY (wishlist_id),
    CONSTRAINT fk_wish_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_wish_book FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT uq_wish_cust_book UNIQUE (customer_id, book_id),
    CONSTRAINT ck_wish_notified CHECK (is_notified IN (0, 1))
);

-- ==========================================================
-- F. TRIGGERS CHO AUTO-INCREMENT (Tự động tăng PK)
-- ==========================================================

-- 26. Trigger cho BRANCHES (Dũng)
CREATE OR REPLACE TRIGGER trg_branches_bi 
BEFORE INSERT ON branches 
FOR EACH ROW 
BEGIN 
    IF :NEW.branch_id IS NULL THEN 
        SELECT seq_branches.NEXTVAL INTO :NEW.branch_id FROM DUAL; 
    END IF; 
END;
/

-- 27. Trigger cho USERS (Dũng)
CREATE OR REPLACE TRIGGER trg_users_bi 
BEFORE INSERT ON users 
FOR EACH ROW 
BEGIN 
    IF :NEW.user_id IS NULL THEN 
        SELECT seq_users.NEXTVAL INTO :NEW.user_id FROM DUAL; 
    END IF; 
END;
/

-- 28. Trigger cho STAFF (Dũng)
CREATE OR REPLACE TRIGGER trg_staff_bi 
BEFORE INSERT ON staff 
FOR EACH ROW 
BEGIN 
    IF :NEW.staff_id IS NULL THEN 
        SELECT seq_staff.NEXTVAL INTO :NEW.staff_id FROM DUAL; 
    END IF; 
END;
/

-- 29. Trigger cho CATEGORIES (Nam)
CREATE OR REPLACE TRIGGER trg_categories_bi 
BEFORE INSERT ON categories 
FOR EACH ROW 
BEGIN 
    IF :NEW.category_id IS NULL THEN 
        SELECT seq_categories.NEXTVAL INTO :NEW.category_id FROM DUAL; 
    END IF; 
END;
/

-- 30. Trigger cho AUTHORS (Nam)
CREATE OR REPLACE TRIGGER trg_authors_bi 
BEFORE INSERT ON authors 
FOR EACH ROW 
BEGIN 
    IF :NEW.author_id IS NULL THEN 
        SELECT seq_authors.NEXTVAL INTO :NEW.author_id FROM DUAL; 
    END IF; 
END;
/

-- 31. Trigger cho PUBLISHERS (Nam)
CREATE OR REPLACE TRIGGER trg_publishers_bi 
BEFORE INSERT ON publishers 
FOR EACH ROW 
BEGIN 
    IF :NEW.publisher_id IS NULL THEN 
        SELECT seq_publishers.NEXTVAL INTO :NEW.publisher_id FROM DUAL; 
    END IF; 
END;
/

-- 32. Trigger cho BOOKS (Nam)
CREATE OR REPLACE TRIGGER trg_books_bi 
BEFORE INSERT ON books 
FOR EACH ROW 
BEGIN 
    IF :NEW.book_id IS NULL THEN 
        SELECT seq_books.NEXTVAL INTO :NEW.book_id FROM DUAL; 
    END IF; 
END;
/

-- 33. Trigger cho BOOK_IMAGES (Nam)
CREATE OR REPLACE TRIGGER trg_book_images_bi 
BEFORE INSERT ON book_images 
FOR EACH ROW 
BEGIN 
    IF :NEW.image_id IS NULL THEN 
        SELECT seq_book_images.NEXTVAL INTO :NEW.image_id FROM DUAL; 
    END IF; 
END;
/

-- 34. Trigger cho BOOK_AUTHORS (Nam)
CREATE OR REPLACE TRIGGER trg_book_authors_bi 
BEFORE INSERT ON book_authors 
FOR EACH ROW 
BEGIN 
    IF :NEW.ba_id IS NULL THEN 
        SELECT seq_book_authors.NEXTVAL INTO :NEW.ba_id FROM DUAL; 
    END IF; 
END;
/

-- 35. Trigger cho CUSTOMERS (Hiếu)
CREATE OR REPLACE TRIGGER trg_customers_bi 
BEFORE INSERT ON customers 
FOR EACH ROW 
BEGIN 
    IF :NEW.customer_id IS NULL THEN 
        SELECT seq_customers.NEXTVAL INTO :NEW.customer_id FROM DUAL; 
    END IF; 
END;
/

-- 36. Trigger cho SHIPPING_METHODS (Hiếu)
CREATE OR REPLACE TRIGGER trg_ship_methods_bi 
BEFORE INSERT ON shipping_methods 
FOR EACH ROW 
BEGIN 
    IF :NEW.method_id IS NULL THEN 
        SELECT seq_shipping_methods.NEXTVAL INTO :NEW.method_id FROM DUAL; 
    END IF; 
END;
/

-- 37. Trigger cho CARTS (Hiếu)
CREATE OR REPLACE TRIGGER trg_carts_bi 
BEFORE INSERT ON carts 
FOR EACH ROW 
BEGIN 
    IF :NEW.cart_id IS NULL THEN 
        SELECT seq_carts.NEXTVAL INTO :NEW.cart_id FROM DUAL; 
    END IF; 
END;
/

-- 38. Trigger cho CART_ITEMS (Hiếu)
CREATE OR REPLACE TRIGGER trg_cart_items_bi 
BEFORE INSERT ON cart_items 
FOR EACH ROW 
BEGIN 
    IF :NEW.cart_item_id IS NULL THEN 
        SELECT seq_cart_items.NEXTVAL INTO :NEW.cart_item_id FROM DUAL; 
    END IF; 
END;
/

-- 39. Trigger cho ORDERS (Hiếu)
CREATE OR REPLACE TRIGGER trg_orders_bi 
BEFORE INSERT ON orders 
FOR EACH ROW 
BEGIN 
    IF :NEW.order_id IS NULL THEN 
        SELECT seq_orders.NEXTVAL INTO :NEW.order_id FROM DUAL; 
    END IF; 
END;
/

-- 40. Trigger cho ORDER_DETAILS (Hiếu)
CREATE OR REPLACE TRIGGER trg_order_details_bi 
BEFORE INSERT ON order_details 
FOR EACH ROW 
BEGIN 
    IF :NEW.detail_id IS NULL THEN 
        SELECT seq_order_details.NEXTVAL INTO :NEW.detail_id FROM DUAL; 
    END IF; 
END;
/

-- 41. Trigger cho ORDER_STATUS_HISTORY (Hiếu)
CREATE OR REPLACE TRIGGER trg_osh_bi 
BEFORE INSERT ON order_status_history 
FOR EACH ROW 
BEGIN 
    IF :NEW.history_id IS NULL THEN 
        SELECT seq_order_status_his.NEXTVAL INTO :NEW.history_id FROM DUAL; 
    END IF; 
END;
/

-- 42. Trigger cho BRANCH_INVENTORY (Phát)
CREATE OR REPLACE TRIGGER trg_branch_inv_bi 
BEFORE INSERT ON branch_inventory 
FOR EACH ROW 
BEGIN 
    IF :NEW.inventory_id IS NULL THEN 
        SELECT seq_branch_inventory.NEXTVAL INTO :NEW.inventory_id FROM DUAL; 
    END IF; 
END;
/

-- 43. Trigger cho INVENTORY_TRANSFERS (Phát)
CREATE OR REPLACE TRIGGER trg_inv_transfers_bi 
BEFORE INSERT ON inventory_transfers 
FOR EACH ROW 
BEGIN 
    IF :NEW.transfer_id IS NULL THEN 
        SELECT seq_inventory_transfers.NEXTVAL INTO :NEW.transfer_id FROM DUAL; 
    END IF; 
END;
/

-- 44. Trigger cho TRANSFER_DETAILS (Phát)
CREATE OR REPLACE TRIGGER trg_transfer_details_bi 
BEFORE INSERT ON transfer_details 
FOR EACH ROW 
BEGIN 
    IF :NEW.detail_id IS NULL THEN 
        SELECT seq_transfer_details.NEXTVAL INTO :NEW.detail_id FROM DUAL; 
    END IF; 
END;
/

-- 45. Trigger cho INVENTORY_TRANSACTIONS (Phát)
CREATE OR REPLACE TRIGGER trg_inv_txn_bi 
BEFORE INSERT ON inventory_transactions 
FOR EACH ROW 
BEGIN 
    IF :NEW.txn_id IS NULL THEN 
        SELECT seq_inventory_txn.NEXTVAL INTO :NEW.txn_id FROM DUAL; 
    END IF; 
END;
/

-- 46. Trigger cho PAYMENT_TRANSACTIONS (Phát)
CREATE OR REPLACE TRIGGER trg_payment_txn_bi 
BEFORE INSERT ON payment_transactions 
FOR EACH ROW 
BEGIN 
    IF :NEW.transaction_id IS NULL THEN 
        SELECT seq_payment_txn.NEXTVAL INTO :NEW.transaction_id FROM DUAL; 
    END IF; 
END;
/

-- 47. Trigger cho COUPONS (Phát)
CREATE OR REPLACE TRIGGER trg_coupons_bi 
BEFORE INSERT ON coupons 
FOR EACH ROW 
BEGIN 
    IF :NEW.coupon_id IS NULL THEN 
        SELECT seq_coupons.NEXTVAL INTO :NEW.coupon_id FROM DUAL; 
    END IF; 
END;
/

-- 48. Trigger cho REVIEWS (Phát)
CREATE OR REPLACE TRIGGER trg_reviews_bi 
BEFORE INSERT ON reviews 
FOR EACH ROW 
BEGIN 
    IF :NEW.review_id IS NULL THEN 
        SELECT seq_reviews.NEXTVAL INTO :NEW.review_id FROM DUAL; 
    END IF; 
END;
/

-- 49. Trigger cho WISHLISTS (Phát)
CREATE OR REPLACE TRIGGER trg_wishlists_bi 
BEFORE INSERT ON wishlists 
FOR EACH ROW 
BEGIN 
    IF :NEW.wishlist_id IS NULL THEN 
        SELECT seq_wishlists.NEXTVAL INTO :NEW.wishlist_id FROM DUAL; 
    END IF; 
END;
/

-- ==========================================================
-- G. DỮ LIỆU MẶC ĐỊNH (Seeding)
-- ==========================================================

-- Chi nhánh trụ sở chính
INSERT INTO branches (branch_code, branch_name, branch_type, address, province, phone, is_main_branch, status)
VALUES ('HQ001', N'Trụ sở chính DigiBook', 'STORE', N'123 Nguyễn Văn A, Quận 1', N'TP. Hồ Chí Minh', '02812345678', 1, 'ACTIVE');

-- Trạng thái đơn hàng
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

-- Tài khoản Admin mặc định (password cần hash sau)
INSERT INTO users (username, email, password_hash, full_name, role, is_active)
VALUES ('admin', 'admin@digibook.com', 'HASH_VALUE_HERE', N'Quản trị viên', 'ADMIN', 1);

COMMIT;

-- ==========================================================
-- KẾT THÚC FILE 2_create_tables.sql
-- Tổng cộng: 25 bảng + 49 triggers + 26 sequences
-- ==========================================================