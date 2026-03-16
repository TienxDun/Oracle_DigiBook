-- ==========================================================
-- FILE: 2_create_tables.sql
-- Mục tiêu: Tạo lược đồ bảng + ràng buộc + sequence + trigger
-- Hệ quản trị: Oracle 19c
-- ==========================================================

-- ==========================================================
-- 1) TẠO BẢNG (DDL)
-- ==========================================================

CREATE TABLE customers (
    customer_id      NUMBER,
    full_name        NVARCHAR2(100) NOT NULL,
    email            VARCHAR2(150) NOT NULL,
    password_hash    VARCHAR2(256) NOT NULL,
    phone            VARCHAR2(15),
    address          NVARCHAR2(500),
    created_at       DATE DEFAULT SYSDATE,
    updated_at       DATE,
    status           VARCHAR2(20) DEFAULT 'ACTIVE',
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT uq_customers_phone UNIQUE (phone),
    CONSTRAINT ck_customers_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED'))
);

CREATE TABLE categories (
    category_id      NUMBER,
    category_name    NVARCHAR2(100) NOT NULL,
    description      NVARCHAR2(500),
    parent_id        NUMBER,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_name UNIQUE (category_name),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
        REFERENCES categories(category_id)
);

CREATE TABLE carts (
    cart_id          NUMBER,
    customer_id      NUMBER NOT NULL,
    created_at       DATE DEFAULT SYSDATE,
    updated_at       DATE,
    status           VARCHAR2(20) DEFAULT 'ACTIVE',
    CONSTRAINT pk_carts PRIMARY KEY (cart_id),
    CONSTRAINT fk_carts_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT ck_carts_status CHECK (status IN ('ACTIVE', 'MERGED', 'ABANDONED'))
);

CREATE TABLE authors (
    author_id        NUMBER,
    author_name      NVARCHAR2(150) NOT NULL,
    biography        NCLOB,
    birth_date       DATE,
    nationality      NVARCHAR2(50),
    CONSTRAINT pk_authors PRIMARY KEY (author_id)
);

CREATE TABLE publishers (
    publisher_id     NUMBER,
    publisher_name   NVARCHAR2(200) NOT NULL,
    address          NVARCHAR2(500),
    phone            VARCHAR2(15),
    email            VARCHAR2(150),
    CONSTRAINT pk_publishers PRIMARY KEY (publisher_id),
    CONSTRAINT uq_publishers_name UNIQUE (publisher_name),
    CONSTRAINT uq_publishers_email UNIQUE (email)
);

CREATE TABLE coupons (
    coupon_id            NUMBER,
    coupon_code          VARCHAR2(50) NOT NULL,
    coupon_name          NVARCHAR2(150) NOT NULL,
    discount_type        VARCHAR2(10) NOT NULL,
    discount_value       NUMBER(10,2) NOT NULL,
    start_at             DATE NOT NULL,
    end_at               DATE NOT NULL,
    max_uses             NUMBER,
    used_count           NUMBER DEFAULT 0 NOT NULL,
    per_customer_limit   NUMBER DEFAULT 1 NOT NULL,
    min_order_amount     NUMBER(12,2) DEFAULT 0 NOT NULL,
    max_discount_amount  NUMBER(10,2),
    is_active            NUMBER(1) DEFAULT 1,
    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
    CONSTRAINT uq_coupons_code UNIQUE (coupon_code),
    CONSTRAINT ck_cp_discount_type CHECK (discount_type IN ('PERCENT', 'FIXED')),
    CONSTRAINT ck_cp_discount_value CHECK (
        (discount_type = 'PERCENT' AND discount_value > 0 AND discount_value <= 100)
        OR
        (discount_type = 'FIXED' AND discount_value > 0)
    ),
    CONSTRAINT ck_cp_end_after_start CHECK (end_at >= start_at),
    CONSTRAINT ck_cp_max_uses CHECK (max_uses IS NULL OR max_uses > 0),
    CONSTRAINT ck_cp_used_count CHECK (used_count >= 0),
    CONSTRAINT ck_cp_per_cus_limit CHECK (per_customer_limit > 0),
    CONSTRAINT ck_cp_min_order_amt CHECK (min_order_amount >= 0),
    CONSTRAINT ck_cp_max_discount CHECK (max_discount_amount IS NULL OR max_discount_amount > 0),
    CONSTRAINT ck_cp_is_active CHECK (is_active IN (0, 1))
);

CREATE TABLE books (
    book_id            NUMBER,
    title              NVARCHAR2(300) NOT NULL,
    isbn               VARCHAR2(20),
    price              NUMBER(10,2) NOT NULL,
    stock_quantity     NUMBER DEFAULT 0,
    description        NCLOB,
    publication_year   NUMBER(4),
    page_count         NUMBER,
    cover_image_url    VARCHAR2(500),
    category_id        NUMBER,
    publisher_id       NUMBER,
    created_at         DATE DEFAULT SYSDATE,
    updated_at         DATE,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_isbn UNIQUE (isbn),
    CONSTRAINT fk_books_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id),
    CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id)
        REFERENCES publishers(publisher_id),
    CONSTRAINT ck_books_price CHECK (price > 0),
    CONSTRAINT ck_books_stock CHECK (stock_quantity >= 0),
    CONSTRAINT ck_books_pub_year CHECK (publication_year BETWEEN 1900 AND 2100),
    CONSTRAINT ck_books_page_count CHECK (page_count > 0)
);

CREATE TABLE book_images (
    image_id          NUMBER,
    book_id           NUMBER NOT NULL,
    image_url         VARCHAR2(500) NOT NULL,
    is_primary        NUMBER(1) DEFAULT 0,
    sort_order        NUMBER DEFAULT 0,
    created_at        DATE DEFAULT SYSDATE,
    CONSTRAINT pk_book_images PRIMARY KEY (image_id),
    CONSTRAINT fk_bimg_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT ck_bimg_is_primary CHECK (is_primary IN (0, 1))
);

CREATE TABLE book_authors (
    book_id           NUMBER,
    author_id         NUMBER,
    role              VARCHAR2(20) DEFAULT 'AUTHOR' NOT NULL,
    author_order      NUMBER,
    CONSTRAINT pk_book_authors PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id)
        REFERENCES authors(author_id),
    CONSTRAINT ck_ba_role CHECK (role IN ('AUTHOR', 'TRANSLATOR', 'EDITOR')),
    CONSTRAINT ck_ba_author_order CHECK (author_order IS NULL OR author_order > 0)
);

CREATE TABLE orders (
    order_id           NUMBER,
    customer_id        NUMBER NOT NULL,
    coupon_id          NUMBER,
    order_date         DATE DEFAULT SYSDATE,
    total_amount       NUMBER(12,2) DEFAULT 0,
    status             VARCHAR2(20) DEFAULT 'PENDING',
    shipping_address   NVARCHAR2(500) NOT NULL,
    payment_method     VARCHAR2(30),
    payment_status     VARCHAR2(20) DEFAULT 'PENDING',
    shipping_fee       NUMBER(10,2) DEFAULT 0,
    discount_amount    NUMBER(10,2) DEFAULT 0,
    updated_at         DATE,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id)
        REFERENCES coupons(coupon_id),
    CONSTRAINT ck_orders_total_amount CHECK (total_amount >= 0),
    CONSTRAINT ck_orders_status CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT ck_orders_payment_mth CHECK (payment_method IN ('COD', 'CREDIT_CARD', 'BANK_TRANSFER', 'E_WALLET')),
    CONSTRAINT ck_orders_payment_stt CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    CONSTRAINT ck_orders_ship_fee CHECK (shipping_fee >= 0),
    CONSTRAINT ck_orders_discount CHECK (discount_amount >= 0)
);

CREATE TABLE order_details (
    order_detail_id   NUMBER,
    order_id          NUMBER NOT NULL,
    book_id           NUMBER NOT NULL,
    quantity          NUMBER NOT NULL,
    unit_price        NUMBER(10,2) NOT NULL,
    subtotal          NUMBER(12,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
    CONSTRAINT pk_order_details PRIMARY KEY (order_detail_id),
    CONSTRAINT fk_od_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    CONSTRAINT fk_od_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT uq_od_order_book UNIQUE (order_id, book_id),
    CONSTRAINT ck_od_quantity CHECK (quantity > 0),
    CONSTRAINT ck_od_unit_price CHECK (unit_price > 0)
);

CREATE TABLE order_status_history (
    status_history_id   NUMBER,
    order_id            NUMBER NOT NULL,
    old_status          VARCHAR2(20),
    new_status          VARCHAR2(20) NOT NULL,
    changed_at          DATE DEFAULT SYSDATE,
    changed_by          NUMBER,
    changed_source      VARCHAR2(20) DEFAULT 'SYSTEM' NOT NULL,
    note                NVARCHAR2(500),
    CONSTRAINT pk_order_status_his PRIMARY KEY (status_history_id),
    CONSTRAINT fk_osh_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    CONSTRAINT fk_osh_changed_by FOREIGN KEY (changed_by)
        REFERENCES customers(customer_id),
    CONSTRAINT ck_osh_new_status CHECK (new_status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT ck_osh_source CHECK (changed_source IN ('SYSTEM', 'ADMIN', 'CUSTOMER'))
);

CREATE TABLE reviews (
    review_id         NUMBER,
    order_id          NUMBER NOT NULL,
    book_id           NUMBER NOT NULL,
    rating            NUMBER(1) NOT NULL,
    review_comment    NCLOB,
    review_date       DATE DEFAULT SYSDATE,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    CONSTRAINT fk_reviews_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT fk_reviews_od FOREIGN KEY (order_id, book_id)
        REFERENCES order_details(order_id, book_id),
    CONSTRAINT uq_reviews_order_book UNIQUE (order_id, book_id),
    CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE cart_items (
    cart_item_id      NUMBER,
    cart_id           NUMBER NOT NULL,
    book_id           NUMBER NOT NULL,
    quantity          NUMBER NOT NULL,
    unit_price        NUMBER(10,2) NOT NULL,
    created_at        DATE DEFAULT SYSDATE,
    updated_at        DATE,
    CONSTRAINT pk_cart_items PRIMARY KEY (cart_item_id),
    CONSTRAINT fk_ci_cart FOREIGN KEY (cart_id)
        REFERENCES carts(cart_id),
    CONSTRAINT fk_ci_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT uq_ci_cart_book UNIQUE (cart_id, book_id),
    CONSTRAINT ck_ci_quantity CHECK (quantity > 0),
    CONSTRAINT ck_ci_unit_price CHECK (unit_price > 0)
);

CREATE TABLE inventory_transactions (
    txn_id            NUMBER,
    book_id           NUMBER NOT NULL,
    txn_type          VARCHAR2(20) NOT NULL,
    reference_id      NUMBER,
    reference_type    VARCHAR2(20),
    quantity          NUMBER NOT NULL,
    created_at        DATE DEFAULT SYSDATE,
    note              NVARCHAR2(500),
    CONSTRAINT pk_inventory_txn PRIMARY KEY (txn_id),
    CONSTRAINT fk_it_book FOREIGN KEY (book_id)
        REFERENCES books(book_id),
    CONSTRAINT fk_it_order_ref FOREIGN KEY (reference_id)
        REFERENCES orders(order_id),
    CONSTRAINT ck_it_type CHECK (txn_type IN ('IN', 'OUT', 'ADJUST')),
    CONSTRAINT ck_it_ref_type CHECK (reference_type IN ('ORDER', 'MANUAL', 'RETURN')),
    CONSTRAINT ck_it_quantity CHECK (quantity > 0),
    CONSTRAINT ck_it_out_requires_ref CHECK (
        txn_type <> 'OUT' OR (reference_id IS NOT NULL AND reference_type = 'ORDER')
    )
);

-- Ràng buộc: Mỗi sách chỉ có tối đa 1 ảnh chính (is_primary = 1)
CREATE UNIQUE INDEX uq_bimg_primary_one
    ON book_images (CASE WHEN is_primary = 1 THEN book_id END);


-- ==========================================================
-- 2) SEQUENCE CHO CÁC BẢNG CÓ PK KIỂU NUMBER
-- ==========================================================

CREATE SEQUENCE seq_customers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_categories START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_carts START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_cart_items START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_authors START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_publishers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_coupons START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_books START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_book_images START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_details START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_order_status_his START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_reviews START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_inventory_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- ==========================================================
-- 3) TRIGGER TỰ ĐỘNG GÁN PK TỪ SEQUENCE
-- ==========================================================

-- ==========================================================
-- [Dũng] Trigger cấp mã cho CUSTOMERS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_customers
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    -- Tự động sinh customer_id nếu chưa truyền từ ứng dụng
    IF :NEW.customer_id IS NULL THEN
        :NEW.customer_id := seq_customers.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Dũng] Trigger cấp mã cho CATEGORIES
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_categories
BEFORE INSERT ON categories
FOR EACH ROW
BEGIN
    -- Tự động sinh category_id nếu giá trị đầu vào là NULL
    IF :NEW.category_id IS NULL THEN
        :NEW.category_id := seq_categories.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Dũng] Trigger cấp mã cho CARTS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_carts
BEFORE INSERT ON carts
FOR EACH ROW
BEGIN
    -- Tự động sinh cart_id cho bản ghi giỏ hàng mới
    IF :NEW.cart_id IS NULL THEN
        :NEW.cart_id := seq_carts.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Dũng] Trigger cấp mã cho CART_ITEMS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_cart_items
BEFORE INSERT ON cart_items
FOR EACH ROW
BEGIN
    -- Tự động sinh cart_item_id để đảm bảo khóa chính duy nhất
    IF :NEW.cart_item_id IS NULL THEN
        :NEW.cart_item_id := seq_cart_items.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Nam] Trigger cấp mã cho AUTHORS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_authors
BEFORE INSERT ON authors
FOR EACH ROW
BEGIN
    -- Tự động sinh author_id cho thông tin tác giả mới
    IF :NEW.author_id IS NULL THEN
        :NEW.author_id := seq_authors.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Nam] Trigger cấp mã cho PUBLISHERS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_publishers
BEFORE INSERT ON publishers
FOR EACH ROW
BEGIN
    -- Tự động sinh publisher_id cho bản ghi nhà xuất bản
    IF :NEW.publisher_id IS NULL THEN
        :NEW.publisher_id := seq_publishers.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Nam] Trigger cấp mã cho COUPONS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_coupons
BEFORE INSERT ON coupons
FOR EACH ROW
BEGIN
    -- Tự động sinh coupon_id cho mã giảm giá mới
    IF :NEW.coupon_id IS NULL THEN
        :NEW.coupon_id := seq_coupons.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Hiếu] Trigger cấp mã cho BOOKS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_books
BEFORE INSERT ON books
FOR EACH ROW
BEGIN
    -- Tự động sinh book_id cho sách mới thêm vào hệ thống
    IF :NEW.book_id IS NULL THEN
        :NEW.book_id := seq_books.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Hiếu] Trigger cấp mã cho BOOK_IMAGES
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_book_images
BEFORE INSERT ON book_images
FOR EACH ROW
BEGIN
    -- Tự động sinh image_id cho ảnh sách mới
    IF :NEW.image_id IS NULL THEN
        :NEW.image_id := seq_book_images.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Hiếu] Trigger cấp mã cho INVENTORY_TRANSACTIONS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_inventory_txn
BEFORE INSERT ON inventory_transactions
FOR EACH ROW
BEGIN
    -- Tự động sinh txn_id cho giao dịch kho
    IF :NEW.txn_id IS NULL THEN
        :NEW.txn_id := seq_inventory_txn.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Phát] Trigger cấp mã cho ORDERS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_orders
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    -- Tự động sinh order_id cho đơn hàng mới
    IF :NEW.order_id IS NULL THEN
        :NEW.order_id := seq_orders.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Phát] Trigger cấp mã cho ORDER_DETAILS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_order_details
BEFORE INSERT ON order_details
FOR EACH ROW
BEGIN
    -- Tự động sinh order_detail_id cho dòng chi tiết đơn
    IF :NEW.order_detail_id IS NULL THEN
        :NEW.order_detail_id := seq_order_details.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Phát] Trigger cấp mã cho ORDER_STATUS_HISTORY
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_order_status_his
BEFORE INSERT ON order_status_history
FOR EACH ROW
BEGIN
    -- Tự động sinh status_history_id cho lịch sử trạng thái đơn
    IF :NEW.status_history_id IS NULL THEN
        :NEW.status_history_id := seq_order_status_his.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- [Phát] Trigger cấp mã cho REVIEWS
-- ==========================================================
CREATE OR REPLACE TRIGGER trg_bi_reviews
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    -- Tự động sinh review_id cho đánh giá mới
    IF :NEW.review_id IS NULL THEN
        :NEW.review_id := seq_reviews.NEXTVAL;
    END IF;
END;
/

-- ==========================================================
-- KẾT THÚC FILE
-- ==========================================================
