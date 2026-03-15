/*
================================================================================
  📦 BƯỚC 2: TẠO LƯỢC ĐỒ & RÀNG BUỘC (DDL) — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 2_create_tables.sql
  Mục đích: Tạo toàn bộ Tables, Constraints, Sequences và Auto-increment Triggers
================================================================================
  ⚠️ THỨ TỰ THỰC THI: Chạy từ trên xuống dưới.
     Các bảng cha (không phụ thuộc FK) được tạo trước, bảng con tạo sau.
================================================================================
*/

-- ============================================================================
-- 🗑️ PHẦN 0: XÓA CÁC ĐỐI TƯỢNG CŨ (NẾU TỒN TẠI) — ĐỂ CHẠY LẠI AN TOÀN
-- ============================================================================
-- Ghi chú: Xóa theo thứ tự ngược lại (bảng con trước, bảng cha sau)
-- để tránh lỗi vi phạm ràng buộc Foreign Key.

-- Xóa Triggers trước
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_reviews_auto_id';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_order_details_auto_id';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_orders_auto_id';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_books_auto_id';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_publishers_auto_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_authors_auto_id';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_categories_auto_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_customers_auto_id';       EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Xóa Sequences
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_reviews';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_order_details';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_orders';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_books';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_publishers';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_authors';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_categories';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_customers';      EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Xóa Tables (bảng con trước, bảng cha sau)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE REVIEWS CASCADE CONSTRAINTS';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ORDER_DETAILS CASCADE CONSTRAINTS';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ORDERS CASCADE CONSTRAINTS';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE BOOK_AUTHORS CASCADE CONSTRAINTS';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE BOOKS CASCADE CONSTRAINTS';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PUBLISHERS CASCADE CONSTRAINTS';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AUTHORS CASCADE CONSTRAINTS';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CATEGORIES CASCADE CONSTRAINTS';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CUSTOMERS CASCADE CONSTRAINTS';      EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ✅ Đã dọn dẹp các đối tượng cũ thành công!
PROMPT ================================================

-- ============================================================================
-- 📋 PHẦN 1: TẠO CÁC BẢNG (CREATE TABLES)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1.1. Bảng CUSTOMERS — Khách hàng
-- Phụ trách: DŨNG
-- Mô tả   : Lưu thông tin khách hàng đăng ký trên hệ thống DigiBook
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE CUSTOMERS (
    customer_id     NUMBER                          -- Mã khách hàng (PK, auto-increment)
        CONSTRAINT pk_customers PRIMARY KEY,
    full_name       NVARCHAR2(100)  NOT NULL,       -- Họ và tên (bắt buộc)
    email           VARCHAR2(150)   NOT NULL,       -- Email đăng nhập (bắt buộc, duy nhất)
    password_hash   VARCHAR2(256)   NOT NULL,       -- Mật khẩu đã mã hóa (bắt buộc)
    phone           VARCHAR2(15),                   -- Số điện thoại (duy nhất, không bắt buộc)
    address         NVARCHAR2(500),                 -- Địa chỉ giao hàng
    created_at      DATE            DEFAULT SYSDATE,-- Ngày tạo tài khoản
    status          VARCHAR2(20)    DEFAULT 'ACTIVE',-- Trạng thái tài khoản

    -- Ràng buộc UNIQUE
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT uq_customers_phone UNIQUE (phone),

    -- Ràng buộc CHECK: Trạng thái chỉ nhận 3 giá trị hợp lệ
    CONSTRAINT chk_customers_status
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED')),

    -- Ràng buộc CHECK: Email phải có định dạng cơ bản (chứa @)
    CONSTRAINT chk_customers_email_format
        CHECK (email LIKE '%_@_%.__%')
);

COMMENT ON TABLE CUSTOMERS IS 'Bảng khách hàng - Lưu thông tin người dùng đăng ký trên DigiBook';
COMMENT ON COLUMN CUSTOMERS.customer_id IS 'Mã khách hàng - Khóa chính, tự động tăng';
COMMENT ON COLUMN CUSTOMERS.full_name IS 'Họ và tên đầy đủ của khách hàng';
COMMENT ON COLUMN CUSTOMERS.email IS 'Email đăng nhập - Duy nhất trong hệ thống';
COMMENT ON COLUMN CUSTOMERS.password_hash IS 'Mật khẩu đã được mã hóa (hash)';
COMMENT ON COLUMN CUSTOMERS.phone IS 'Số điện thoại liên hệ';
COMMENT ON COLUMN CUSTOMERS.address IS 'Địa chỉ giao hàng mặc định';
COMMENT ON COLUMN CUSTOMERS.created_at IS 'Ngày tạo tài khoản';
COMMENT ON COLUMN CUSTOMERS.status IS 'Trạng thái tài khoản: ACTIVE/INACTIVE/BANNED';

PROMPT ✅ Tạo bảng CUSTOMERS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.2. Bảng CATEGORIES — Danh mục sách
-- Phụ trách: DŨNG
-- Mô tả   : Lưu các danh mục/thể loại sách (Văn học, Kinh tế, Kỹ năng...)
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE CATEGORIES (
    category_id     NUMBER                          -- Mã danh mục (PK, auto-increment)
        CONSTRAINT pk_categories PRIMARY KEY,
    category_name   NVARCHAR2(100)  NOT NULL,       -- Tên danh mục (bắt buộc, duy nhất)
    description     NVARCHAR2(500),                 -- Mô tả danh mục

    -- Ràng buộc UNIQUE: Mỗi tên danh mục phải duy nhất
    CONSTRAINT uq_categories_name UNIQUE (category_name)
);

COMMENT ON TABLE CATEGORIES IS 'Bảng danh mục - Phân loại thể loại sách';
COMMENT ON COLUMN CATEGORIES.category_id IS 'Mã danh mục - Khóa chính, tự động tăng';
COMMENT ON COLUMN CATEGORIES.category_name IS 'Tên danh mục sách - Duy nhất';
COMMENT ON COLUMN CATEGORIES.description IS 'Mô tả chi tiết về danh mục';

PROMPT ✅ Tạo bảng CATEGORIES thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.3. Bảng AUTHORS — Tác giả
-- Phụ trách: NAM
-- Mô tả   : Lưu thông tin tác giả viết sách
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE AUTHORS (
    author_id       NUMBER                          -- Mã tác giả (PK, auto-increment)
        CONSTRAINT pk_authors PRIMARY KEY,
    author_name     NVARCHAR2(150)  NOT NULL,       -- Tên tác giả (bắt buộc)
    biography       NCLOB,                          -- Tiểu sử (text dài)
    birth_date      DATE,                           -- Ngày sinh
    nationality     NVARCHAR2(50),                  -- Quốc tịch

    -- Ràng buộc CHECK: Ngày sinh phải trước ngày hiện tại
    CONSTRAINT chk_authors_birth_date
        CHECK (birth_date IS NULL OR birth_date < SYSDATE)
);

COMMENT ON TABLE AUTHORS IS 'Bảng tác giả - Lưu thông tin người viết sách';
COMMENT ON COLUMN AUTHORS.author_id IS 'Mã tác giả - Khóa chính, tự động tăng';
COMMENT ON COLUMN AUTHORS.author_name IS 'Tên đầy đủ của tác giả';
COMMENT ON COLUMN AUTHORS.biography IS 'Tiểu sử chi tiết của tác giả';
COMMENT ON COLUMN AUTHORS.birth_date IS 'Ngày sinh của tác giả';
COMMENT ON COLUMN AUTHORS.nationality IS 'Quốc tịch của tác giả';

PROMPT ✅ Tạo bảng AUTHORS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.4. Bảng PUBLISHERS — Nhà xuất bản
-- Phụ trách: NAM
-- Mô tả   : Lưu thông tin các nhà xuất bản
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE PUBLISHERS (
    publisher_id    NUMBER                          -- Mã NXB (PK, auto-increment)
        CONSTRAINT pk_publishers PRIMARY KEY,
    publisher_name  NVARCHAR2(200)  NOT NULL,       -- Tên NXB (bắt buộc, duy nhất)
    address         NVARCHAR2(500),                 -- Địa chỉ NXB
    phone           VARCHAR2(15),                   -- Số điện thoại
    email           VARCHAR2(150),                  -- Email liên hệ

    -- Ràng buộc UNIQUE
    CONSTRAINT uq_publishers_name  UNIQUE (publisher_name),
    CONSTRAINT uq_publishers_email UNIQUE (email),

    -- Ràng buộc CHECK: Email NXB phải có định dạng hợp lệ (nếu có)
    CONSTRAINT chk_publishers_email_format
        CHECK (email IS NULL OR email LIKE '%_@_%.__%')
);

COMMENT ON TABLE PUBLISHERS IS 'Bảng nhà xuất bản - Lưu thông tin NXB';
COMMENT ON COLUMN PUBLISHERS.publisher_id IS 'Mã NXB - Khóa chính, tự động tăng';
COMMENT ON COLUMN PUBLISHERS.publisher_name IS 'Tên nhà xuất bản - Duy nhất';
COMMENT ON COLUMN PUBLISHERS.address IS 'Địa chỉ trụ sở NXB';
COMMENT ON COLUMN PUBLISHERS.phone IS 'Số điện thoại liên hệ NXB';
COMMENT ON COLUMN PUBLISHERS.email IS 'Email liên hệ NXB - Duy nhất';

PROMPT ✅ Tạo bảng PUBLISHERS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.5. Bảng BOOKS — Sách (Sản phẩm chính)
-- Phụ trách: HIẾU
-- Mô tả   : Lưu toàn bộ thông tin sách bán trên DigiBook
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE BOOKS (
    book_id             NUMBER                          -- Mã sách (PK, auto-increment)
        CONSTRAINT pk_books PRIMARY KEY,
    title               NVARCHAR2(300)  NOT NULL,       -- Tên sách (bắt buộc)
    isbn                VARCHAR2(20),                   -- Mã ISBN (duy nhất)
    price               NUMBER(10,2)    NOT NULL,       -- Giá bán VNĐ (bắt buộc, > 0)
    stock_quantity      NUMBER          DEFAULT 0,      -- Số lượng tồn kho (>= 0)
    description         NCLOB,                          -- Mô tả chi tiết sách
    publication_year    NUMBER(4),                       -- Năm xuất bản
    page_count          NUMBER,                         -- Số trang
    cover_image_url     VARCHAR2(500),                  -- Link ảnh bìa
    category_id         NUMBER,                         -- FK: Mã danh mục
    publisher_id        NUMBER,                         -- FK: Mã NXB
    created_at          DATE            DEFAULT SYSDATE,-- Ngày thêm vào hệ thống

    -- Ràng buộc UNIQUE: Mỗi ISBN phải duy nhất
    CONSTRAINT uq_books_isbn UNIQUE (isbn),

    -- Ràng buộc CHECK: Giá sách phải lớn hơn 0
    CONSTRAINT chk_books_price
        CHECK (price > 0),

    -- Ràng buộc CHECK: Số lượng tồn kho không âm
    CONSTRAINT chk_books_stock
        CHECK (stock_quantity >= 0),

    -- Ràng buộc CHECK: Năm xuất bản hợp lệ (1900 - 2100)
    CONSTRAINT chk_books_pub_year
        CHECK (publication_year IS NULL OR (publication_year >= 1900 AND publication_year <= 2100)),

    -- Ràng buộc CHECK: Số trang phải lớn hơn 0 (nếu có)
    CONSTRAINT chk_books_page_count
        CHECK (page_count IS NULL OR page_count > 0),

    -- Khóa ngoại: Liên kết đến bảng CATEGORIES
    CONSTRAINT fk_books_category
        FOREIGN KEY (category_id) REFERENCES CATEGORIES(category_id)
        ON DELETE SET NULL,

    -- Khóa ngoại: Liên kết đến bảng PUBLISHERS
    CONSTRAINT fk_books_publisher
        FOREIGN KEY (publisher_id) REFERENCES PUBLISHERS(publisher_id)
        ON DELETE SET NULL
);

COMMENT ON TABLE BOOKS IS 'Bảng sách - Sản phẩm chính của DigiBook';
COMMENT ON COLUMN BOOKS.book_id IS 'Mã sách - Khóa chính, tự động tăng';
COMMENT ON COLUMN BOOKS.title IS 'Tiêu đề sách';
COMMENT ON COLUMN BOOKS.isbn IS 'Mã quốc tế ISBN - Duy nhất';
COMMENT ON COLUMN BOOKS.price IS 'Giá bán (VNĐ)';
COMMENT ON COLUMN BOOKS.stock_quantity IS 'Số lượng tồn kho hiện tại';
COMMENT ON COLUMN BOOKS.description IS 'Mô tả chi tiết nội dung sách';
COMMENT ON COLUMN BOOKS.publication_year IS 'Năm xuất bản';
COMMENT ON COLUMN BOOKS.page_count IS 'Tổng số trang';
COMMENT ON COLUMN BOOKS.cover_image_url IS 'Đường dẫn URL ảnh bìa sách';
COMMENT ON COLUMN BOOKS.category_id IS 'FK - Mã danh mục sách';
COMMENT ON COLUMN BOOKS.publisher_id IS 'FK - Mã nhà xuất bản';
COMMENT ON COLUMN BOOKS.created_at IS 'Ngày thêm sách vào hệ thống';

PROMPT ✅ Tạo bảng BOOKS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.6. Bảng BOOK_AUTHORS — Liên kết Sách – Tác giả (Bảng trung gian N:N)
-- Phụ trách: HIẾU
-- Mô tả   : Giải quyết quan hệ nhiều-nhiều giữa BOOKS và AUTHORS
--            Một sách có thể có nhiều tác giả, một tác giả viết nhiều sách
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE BOOK_AUTHORS (
    book_id     NUMBER  NOT NULL,                   -- FK: Mã sách
    author_id   NUMBER  NOT NULL,                   -- FK: Mã tác giả

    -- Khóa chính tổng hợp (Composite Primary Key)
    CONSTRAINT pk_book_authors PRIMARY KEY (book_id, author_id),

    -- Khóa ngoại: Liên kết đến bảng BOOKS (xóa cascade khi sách bị xóa)
    CONSTRAINT fk_ba_book
        FOREIGN KEY (book_id) REFERENCES BOOKS(book_id)
        ON DELETE CASCADE,

    -- Khóa ngoại: Liên kết đến bảng AUTHORS (xóa cascade khi tác giả bị xóa)
    CONSTRAINT fk_ba_author
        FOREIGN KEY (author_id) REFERENCES AUTHORS(author_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE BOOK_AUTHORS IS 'Bảng trung gian - Liên kết Sách và Tác giả (quan hệ N:N)';
COMMENT ON COLUMN BOOK_AUTHORS.book_id IS 'FK - Mã sách (thành phần khóa chính)';
COMMENT ON COLUMN BOOK_AUTHORS.author_id IS 'FK - Mã tác giả (thành phần khóa chính)';

PROMPT ✅ Tạo bảng BOOK_AUTHORS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.7. Bảng ORDERS — Đơn hàng
-- Phụ trách: PHÁT
-- Mô tả   : Lưu thông tin đơn hàng của khách
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE ORDERS (
    order_id            NUMBER                          -- Mã đơn hàng (PK, auto-increment)
        CONSTRAINT pk_orders PRIMARY KEY,
    customer_id         NUMBER          NOT NULL,       -- FK: Mã khách hàng (bắt buộc)
    order_date          DATE            DEFAULT SYSDATE,-- Ngày đặt hàng
    total_amount        NUMBER(12,2)    DEFAULT 0,      -- Tổng tiền đơn hàng (>= 0)
    status              VARCHAR2(20)    DEFAULT 'PENDING',-- Trạng thái đơn hàng
    shipping_address    NVARCHAR2(500)  NOT NULL,       -- Địa chỉ giao hàng (bắt buộc)
    payment_method      VARCHAR2(30),                   -- Phương thức thanh toán

    -- Ràng buộc CHECK: Tổng tiền không âm
    CONSTRAINT chk_orders_total
        CHECK (total_amount >= 0),

    -- Ràng buộc CHECK: Trạng thái đơn hàng chỉ nhận 5 giá trị hợp lệ
    CONSTRAINT chk_orders_status
        CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED')),

    -- Ràng buộc CHECK: Phương thức thanh toán hợp lệ
    CONSTRAINT chk_orders_payment
        CHECK (payment_method IS NULL OR payment_method IN ('COD', 'CREDIT_CARD', 'BANK_TRANSFER', 'E_WALLET')),

    -- Khóa ngoại: Liên kết đến bảng CUSTOMERS
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE ORDERS IS 'Bảng đơn hàng - Lưu thông tin đặt hàng của khách';
COMMENT ON COLUMN ORDERS.order_id IS 'Mã đơn hàng - Khóa chính, tự động tăng';
COMMENT ON COLUMN ORDERS.customer_id IS 'FK - Mã khách hàng đặt đơn';
COMMENT ON COLUMN ORDERS.order_date IS 'Ngày giờ đặt hàng';
COMMENT ON COLUMN ORDERS.total_amount IS 'Tổng giá trị đơn hàng (VNĐ)';
COMMENT ON COLUMN ORDERS.status IS 'Trạng thái: PENDING/CONFIRMED/SHIPPING/DELIVERED/CANCELLED';
COMMENT ON COLUMN ORDERS.shipping_address IS 'Địa chỉ giao hàng cụ thể';
COMMENT ON COLUMN ORDERS.payment_method IS 'Phương thức: COD/CREDIT_CARD/BANK_TRANSFER/E_WALLET';

PROMPT ✅ Tạo bảng ORDERS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.8. Bảng ORDER_DETAILS — Chi tiết đơn hàng
-- Phụ trách: PHÁT
-- Mô tả   : Lưu từng dòng sản phẩm (sách) trong đơn hàng
--            Cột subtotal là VIRTUAL COLUMN tự động tính = quantity * unit_price
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE ORDER_DETAILS (
    order_detail_id NUMBER                          -- Mã chi tiết (PK, auto-increment)
        CONSTRAINT pk_order_details PRIMARY KEY,
    order_id        NUMBER          NOT NULL,       -- FK: Mã đơn hàng (bắt buộc)
    book_id         NUMBER          NOT NULL,       -- FK: Mã sách (bắt buộc)
    quantity        NUMBER          NOT NULL,       -- Số lượng mua (bắt buộc, > 0)
    unit_price      NUMBER(10,2)    NOT NULL,       -- Đơn giá tại thời điểm mua (bắt buộc, > 0)
    subtotal        NUMBER(12,2)                    -- Thành tiền (Virtual Column)
        GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,

    -- Ràng buộc CHECK: Số lượng mua phải > 0
    CONSTRAINT chk_od_quantity
        CHECK (quantity > 0),

    -- Ràng buộc CHECK: Đơn giá phải > 0
    CONSTRAINT chk_od_unit_price
        CHECK (unit_price > 0),

    -- Ràng buộc UNIQUE: Mỗi sách chỉ xuất hiện 1 lần trong 1 đơn hàng
    -- (Nếu mua thêm thì tăng quantity, không tạo dòng mới)
    CONSTRAINT uq_od_order_book UNIQUE (order_id, book_id),

    -- Khóa ngoại: Liên kết đến bảng ORDERS
    CONSTRAINT fk_od_order
        FOREIGN KEY (order_id) REFERENCES ORDERS(order_id)
        ON DELETE CASCADE,

    -- Khóa ngoại: Liên kết đến bảng BOOKS
    CONSTRAINT fk_od_book
        FOREIGN KEY (book_id) REFERENCES BOOKS(book_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE ORDER_DETAILS IS 'Bảng chi tiết đơn hàng - Từng dòng sản phẩm trong đơn';
COMMENT ON COLUMN ORDER_DETAILS.order_detail_id IS 'Mã chi tiết - Khóa chính, tự động tăng';
COMMENT ON COLUMN ORDER_DETAILS.order_id IS 'FK - Mã đơn hàng';
COMMENT ON COLUMN ORDER_DETAILS.book_id IS 'FK - Mã sách được mua';
COMMENT ON COLUMN ORDER_DETAILS.quantity IS 'Số lượng mua';
COMMENT ON COLUMN ORDER_DETAILS.unit_price IS 'Đơn giá tại thời điểm mua (snapshot giá)';
COMMENT ON COLUMN ORDER_DETAILS.subtotal IS 'Thành tiền = quantity × unit_price (Virtual Column)';

PROMPT ✅ Tạo bảng ORDER_DETAILS thành công!

-- ────────────────────────────────────────────────────────────────────────────
-- 1.9. Bảng REVIEWS — Đánh giá sách
-- Phụ trách: PHÁT
-- Mô tả   : Lưu đánh giá & bình luận của khách hàng cho sách
--            Mỗi khách chỉ được đánh giá 1 lần cho mỗi sách (UNIQUE)
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE REVIEWS (
    review_id       NUMBER                          -- Mã đánh giá (PK, auto-increment)
        CONSTRAINT pk_reviews PRIMARY KEY,
    customer_id     NUMBER          NOT NULL,       -- FK: Mã khách hàng (bắt buộc)
    book_id         NUMBER          NOT NULL,       -- FK: Mã sách (bắt buộc)
    rating          NUMBER(1)       NOT NULL,       -- Số sao 1-5 (bắt buộc)
    comment         NCLOB,                          -- Nội dung bình luận
    review_date     DATE            DEFAULT SYSDATE,-- Ngày đánh giá

    -- Ràng buộc CHECK: Rating từ 1 đến 5
    CONSTRAINT chk_reviews_rating
        CHECK (rating BETWEEN 1 AND 5),

    -- Ràng buộc UNIQUE: Mỗi khách chỉ đánh giá 1 lần / sách
    CONSTRAINT uq_reviews_customer_book
        UNIQUE (customer_id, book_id),

    -- Khóa ngoại: Liên kết đến bảng CUSTOMERS
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
        ON DELETE CASCADE,

    -- Khóa ngoại: Liên kết đến bảng BOOKS
    CONSTRAINT fk_reviews_book
        FOREIGN KEY (book_id) REFERENCES BOOKS(book_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE REVIEWS IS 'Bảng đánh giá - Bình luận & chấm điểm sách của khách hàng';
COMMENT ON COLUMN REVIEWS.review_id IS 'Mã đánh giá - Khóa chính, tự động tăng';
COMMENT ON COLUMN REVIEWS.customer_id IS 'FK - Mã khách hàng đánh giá';
COMMENT ON COLUMN REVIEWS.book_id IS 'FK - Mã sách được đánh giá';
COMMENT ON COLUMN REVIEWS.rating IS 'Số sao đánh giá (1 đến 5)';
COMMENT ON COLUMN REVIEWS.comment IS 'Nội dung bình luận chi tiết';
COMMENT ON COLUMN REVIEWS.review_date IS 'Ngày viết đánh giá';

PROMPT ✅ Tạo bảng REVIEWS thành công!

PROMPT ================================================
PROMPT ✅ HOÀN TẤT TẠO 9 BẢNG DỮ LIỆU!
PROMPT ================================================

-- ============================================================================
-- 🔢 PHẦN 2: TẠO SEQUENCES — Bộ đếm tự động tăng cho Primary Key
-- ============================================================================
-- Ghi chú: Mỗi bảng có PK kiểu NUMBER sẽ có 1 Sequence tương ứng.
-- Bảng BOOK_AUTHORS dùng Composite PK nên không cần Sequence.
-- Sequence bắt đầu từ 1, mỗi lần tăng 1, cache 20 để tối ưu hiệu suất.

-- Sequence cho CUSTOMERS (Phụ trách: Dũng)
CREATE SEQUENCE seq_customers
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho CATEGORIES (Phụ trách: Dũng)
CREATE SEQUENCE seq_categories
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho AUTHORS (Phụ trách: Nam)
CREATE SEQUENCE seq_authors
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho PUBLISHERS (Phụ trách: Nam)
CREATE SEQUENCE seq_publishers
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho BOOKS (Phụ trách: Hiếu)
CREATE SEQUENCE seq_books
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho ORDERS (Phụ trách: Phát)
CREATE SEQUENCE seq_orders
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho ORDER_DETAILS (Phụ trách: Phát)
CREATE SEQUENCE seq_order_details
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho REVIEWS (Phụ trách: Phát)
CREATE SEQUENCE seq_reviews
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

PROMPT ================================================
PROMPT ✅ HOÀN TẤT TẠO 8 SEQUENCES!
PROMPT ================================================

-- ============================================================================
-- ⚡ PHẦN 3: TẠO TRIGGERS AUTO-INCREMENT — Gán PK tự động trước khi INSERT
-- ============================================================================
-- Ghi chú: Sử dụng BEFORE INSERT trigger kết hợp Sequence
-- Đây là phương pháp chuẩn trên Oracle (trước 12c dùng IDENTITY).
-- Chọn Sequence + Trigger để tương thích đồ án và minh họa rõ cơ chế.
-- Mỗi trigger kiểm tra nếu PK chưa được gán thì mới lấy từ Sequence.

-- ────────────────────────────────────────────────────────────────────────────
-- 3.1. Trigger Auto-ID cho bảng CUSTOMERS
-- Phụ trách: DŨNG
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_customers_auto_id
    BEFORE INSERT ON CUSTOMERS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán customer_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.customer_id IS NULL THEN
        :NEW.customer_id := seq_customers.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.2. Trigger Auto-ID cho bảng CATEGORIES
-- Phụ trách: DŨNG
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_categories_auto_id
    BEFORE INSERT ON CATEGORIES
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán category_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.category_id IS NULL THEN
        :NEW.category_id := seq_categories.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.3. Trigger Auto-ID cho bảng AUTHORS
-- Phụ trách: NAM
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_authors_auto_id
    BEFORE INSERT ON AUTHORS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán author_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.author_id IS NULL THEN
        :NEW.author_id := seq_authors.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.4. Trigger Auto-ID cho bảng PUBLISHERS
-- Phụ trách: NAM
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_publishers_auto_id
    BEFORE INSERT ON PUBLISHERS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán publisher_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.publisher_id IS NULL THEN
        :NEW.publisher_id := seq_publishers.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.5. Trigger Auto-ID cho bảng BOOKS
-- Phụ trách: HIẾU
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_books_auto_id
    BEFORE INSERT ON BOOKS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán book_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.book_id IS NULL THEN
        :NEW.book_id := seq_books.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.6. Trigger Auto-ID cho bảng ORDERS
-- Phụ trách: PHÁT
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_orders_auto_id
    BEFORE INSERT ON ORDERS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán order_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.order_id IS NULL THEN
        :NEW.order_id := seq_orders.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.7. Trigger Auto-ID cho bảng ORDER_DETAILS
-- Phụ trách: PHÁT
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_order_details_auto_id
    BEFORE INSERT ON ORDER_DETAILS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán order_detail_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.order_detail_id IS NULL THEN
        :NEW.order_detail_id := seq_order_details.NEXTVAL;
    END IF;
END;
/

-- ────────────────────────────────────────────────────────────────────────────
-- 3.8. Trigger Auto-ID cho bảng REVIEWS
-- Phụ trách: PHÁT
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_reviews_auto_id
    BEFORE INSERT ON REVIEWS
    FOR EACH ROW
BEGIN
    -- Nếu chưa gán review_id thì tự động lấy giá trị tiếp theo từ Sequence
    IF :NEW.review_id IS NULL THEN
        :NEW.review_id := seq_reviews.NEXTVAL;
    END IF;
END;
/

PROMPT ================================================
PROMPT ✅ HOÀN TẤT TẠO 8 TRIGGERS AUTO-INCREMENT!
PROMPT ================================================

-- ============================================================================
-- 📊 PHẦN 4: KIỂM TRA — XÁC NHẬN TẤT CẢ ĐỐI TƯỢNG ĐÃ TẠO THÀNH CÔNG
-- ============================================================================

-- Liệt kê tất cả các bảng đã tạo
PROMPT
PROMPT 📋 DANH SÁCH CÁC BẢNG ĐÃ TẠO:
SELECT table_name, num_rows
FROM user_tables
WHERE table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY table_name;

-- Liệt kê tất cả các Sequences đã tạo
PROMPT
PROMPT 🔢 DANH SÁCH CÁC SEQUENCES ĐÃ TẠO:
SELECT sequence_name, min_value, max_value, increment_by, last_number
FROM user_sequences
WHERE sequence_name IN (
    'SEQ_CUSTOMERS', 'SEQ_CATEGORIES', 'SEQ_AUTHORS', 'SEQ_PUBLISHERS',
    'SEQ_BOOKS', 'SEQ_ORDERS', 'SEQ_ORDER_DETAILS', 'SEQ_REVIEWS'
)
ORDER BY sequence_name;

-- Liệt kê tất cả các Triggers đã tạo
PROMPT
PROMPT ⚡ DANH SÁCH CÁC TRIGGERS ĐÃ TẠO:
SELECT trigger_name, table_name, triggering_event, trigger_type, status
FROM user_triggers
WHERE trigger_name LIKE 'TRG_%_AUTO_ID'
ORDER BY trigger_name;

-- Liệt kê tất cả các Constraints
PROMPT
PROMPT 🔒 DANH SÁCH CÁC CONSTRAINTS:
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY table_name, constraint_type;

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 2 HOÀN TẤT — TẠO LƯỢC ĐỒ & RÀNG BUỘC THÀNH CÔNG!
PROMPT ================================================================
PROMPT    📦 9 Tables created
PROMPT    🔢 8 Sequences created  
PROMPT    ⚡ 8 Auto-increment Triggers created
PROMPT    🔒 Constraints: PK, FK, UNIQUE, CHECK, NOT NULL
PROMPT    📝 Comments on all tables and columns
PROMPT ================================================================
