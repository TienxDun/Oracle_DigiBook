# 📋 BƯỚC 11: TỰ ĐÁNH GIÁ VÀ KIỂM TRA TÍNH NHẤT QUÁN (Self-Evaluation)

> **Dự án:** DigiBook — Oracle 19c Database  
> **Nhóm:** Dũng, Nam, Hiếu, Phát  
> **Ngày đánh giá:** 2026-03-19  
> **Phạm vi:** Rà soát toàn bộ file từ Bước 1 đến Bước 10

---

## 📌 MỤC LỤC

1. [Tổng quan đánh giá](#1-tổng-quan-đánh-giá)
2. [Kiểm tra ERD vs DDL Script](#2-kiểm-tra-erd-vs-ddl-script)
3. [Kiểm tra Ràng buộc (Constraints)](#3-kiểm-tra-ràng-buộc-constraints)
4. [Kiểm tra Stored Procedures vs Schema](#4-kiểm-tra-stored-procedures-vs-schema)
5. [Kiểm tra Triggers vs Schema](#5-kiểm-tra-triggers-vs-schema)
6. [Kiểm tra Views vs Schema](#6-kiểm-tra-views-vs-schema)
7. [Kiểm tra Dữ liệu mẫu vs Ràng buộc](#7-kiểm-tra-dữ-liệu-mẫu-vs-ràng-buộc)
8. [Kiểm tra Index vs Truy vấn thực tế](#8-kiểm-tra-index-vs-truy-vấn-thực-tế)
9. [Kiểm tra Phân quyền vs Đối tượng](#9-kiểm-tra-phân-quyền-vs-đối-tượng)
10. [Kiểm tra Transaction Demo](#10-kiểm-tra-transaction-demo)
11. [Kiểm tra Báo cáo tổng hợp](#11-kiểm-tra-báo-cáo-tổng-hợp)
12. [Bảng tổng hợp phát hiện](#12-bảng-tổng-hợp-phát-hiện)
13. [Kết luận](#13-kết-luận)

---

## 1. Tổng quan đánh giá

### 1.1. Danh sách file được rà soát

| Bước | File | Kích thước | Trạng thái |
|------|------|-----------|------------|
| 1 | `1_Database_Design.md` | 53,886 bytes | ✅ Có |
| 2 | `2_create_tables.sql` | 19,525 bytes | ✅ Có |
| 3 | `3_insert_data.sql` | 37,439 bytes | ✅ Có |
| 4 | `4_procedures.sql` | 12,615 bytes | ✅ Có |
| 5 | `5_triggers.sql` | 7,582 bytes | ✅ Có |
| 6 | `6_views.sql` | 6,383 bytes | ✅ Có |
| 7 | `7_indexes_and_tuning.sql` | 9,549 bytes | ✅ Có |
| 8 | `8_security_roles.sql` | 11,817 bytes | ✅ Có |
| 9 | `9_transaction_demo.sql` | 6,181 bytes | ✅ Có |
| 10 | `10_Final_Report.md` | 11,763 bytes | ✅ Có |

**Kết luận sơ bộ:** Tất cả 10 file đầu ra kỳ vọng đều tồn tại và có nội dung đầy đủ.

### 1.2. Thống kê tổng quan

| Chỉ số | Giá trị |
|--------|---------|
| Bảng nghiệp vụ lõi | **15** |
| Bảng vận hành (audit) | **1** (`ORDERS_AUDIT_LOG`) |
| Sequences | **15** (14 bảng + 1 audit) |
| Trigger sinh PK | **14** |
| Trigger nghiệp vụ | **3** |
| Stored Procedures | **4** |
| Views thường | **2** |
| Materialized Views | **1** |
| Index tùy biến | **5** (gồm 1 unique function-based từ DDL) |
| Roles | **3** |
| Users | **3** |
| Tổng bản ghi mẫu | **273** |

---

## 2. Kiểm tra ERD vs DDL Script

### 2.1. So khớp danh sách bảng

| # | Bảng trong ERD (`1_Database_Design.md`) | Bảng trong DDL (`2_create_tables.sql`) | Kết quả |
|---|----------------------------------------|---------------------------------------|---------|
| 1 | `CUSTOMERS` | `customers` | ✅ Khớp |
| 2 | `CATEGORIES` | `categories` | ✅ Khớp |
| 3 | `CARTS` | `carts` | ✅ Khớp |
| 4 | `CART_ITEMS` | `cart_items` | ✅ Khớp |
| 5 | `AUTHORS` | `authors` | ✅ Khớp |
| 6 | `PUBLISHERS` | `publishers` | ✅ Khớp |
| 7 | `COUPONS` | `coupons` | ✅ Khớp |
| 8 | `BOOKS` | `books` | ✅ Khớp |
| 9 | `BOOK_IMAGES` | `book_images` | ✅ Khớp |
| 10 | `BOOK_AUTHORS` | `book_authors` | ✅ Khớp |
| 11 | `INVENTORY_TRANSACTIONS` | `inventory_transactions` | ✅ Khớp |
| 12 | `ORDERS` | `orders` | ✅ Khớp |
| 13 | `ORDER_DETAILS` | `order_details` | ✅ Khớp |
| 14 | `ORDER_STATUS_HISTORY` | `order_status_history` | ✅ Khớp |
| 15 | `REVIEWS` | `reviews` | ✅ Khớp |

**Kết luận:** 15/15 bảng trong ERD đều có mặt trong DDL script. ✅ **ĐỒNG BỘ**

### 2.2. So khớp cột (thuộc tính) — Chi tiết từng bảng

#### CUSTOMERS
| Cột trong ERD | Cột trong DDL | Kiểu dữ liệu khớp | Kết quả |
|---------------|---------------|---------------------|---------|
| `customer_id` NUMBER PK | `customer_id NUMBER` PK | ✅ | ✅ |
| `full_name` NVARCHAR2(100) NOT NULL | `full_name NVARCHAR2(100) NOT NULL` | ✅ | ✅ |
| `email` VARCHAR2(150) NOT NULL, UNIQUE | `email VARCHAR2(150) NOT NULL`, UNIQUE | ✅ | ✅ |
| `password_hash` VARCHAR2(256) NOT NULL | `password_hash VARCHAR2(256) NOT NULL` | ✅ | ✅ |
| `phone` VARCHAR2(15) UNIQUE | `phone VARCHAR2(15)` UNIQUE | ✅ | ✅ |
| `address` NVARCHAR2(500) | `address NVARCHAR2(500)` | ✅ | ✅ |
| `created_at` DATE DEFAULT SYSDATE | `created_at DATE DEFAULT SYSDATE` | ✅ | ✅ |
| `updated_at` DATE | `updated_at DATE` | ✅ | ✅ |
| `status` VARCHAR2(20) DEFAULT 'ACTIVE' CHECK | `status VARCHAR2(20) DEFAULT 'ACTIVE'` CHECK | ✅ | ✅ |

#### CATEGORIES
| Cột trong ERD | Cột trong DDL | Kết quả |
|---------------|---------------|---------|
| `category_id` NUMBER PK | `category_id NUMBER` PK | ✅ |
| `category_name` NVARCHAR2(100) NOT NULL, UNIQUE | `category_name NVARCHAR2(100) NOT NULL` UNIQUE | ✅ |
| `description` NVARCHAR2(500) | `description NVARCHAR2(500)` | ✅ |
| `parent_id` NUMBER FK → CATEGORIES | `parent_id NUMBER` FK → categories | ✅ |

#### BOOKS
| Cột trong ERD | Cột trong DDL | Kết quả |
|---------------|---------------|---------|
| `book_id` NUMBER PK | `book_id NUMBER` PK | ✅ |
| `title` NVARCHAR2(300) NOT NULL | `title NVARCHAR2(300) NOT NULL` | ✅ |
| `isbn` VARCHAR2(20) UNIQUE | `isbn VARCHAR2(20)` UNIQUE | ✅ |
| `price` NUMBER(10,2) NOT NULL CHECK > 0 | `price NUMBER(10,2) NOT NULL` CHECK > 0 | ✅ |
| `stock_quantity` NUMBER DEFAULT 0 CHECK >= 0 | `stock_quantity NUMBER DEFAULT 0` CHECK >= 0 | ✅ |
| `description` NCLOB | `description NCLOB` | ✅ |
| `publication_year` NUMBER(4) CHECK | `publication_year NUMBER(4)` CHECK | ✅ |
| `page_count` NUMBER CHECK > 0 | `page_count NUMBER` CHECK > 0 | ✅ |
| `category_id` NUMBER FK → CATEGORIES | `category_id NUMBER` FK → categories | ✅ |
| `publisher_id` NUMBER FK → PUBLISHERS | `publisher_id NUMBER` FK → publishers | ✅ |
| `created_at` DATE DEFAULT SYSDATE | `created_at DATE DEFAULT SYSDATE` | ✅ |
| `updated_at` DATE | `updated_at DATE` | ✅ |

#### ORDERS
| Cột trong ERD | Cột trong DDL | Kết quả |
|---------------|---------------|---------|
| `order_id` NUMBER PK | `order_id NUMBER` PK | ✅ |
| `customer_id` NUMBER FK NOT NULL | `customer_id NUMBER NOT NULL` FK | ✅ |
| `coupon_id` NUMBER FK (nullable) | `coupon_id NUMBER` FK | ✅ |
| `order_date` DATE DEFAULT SYSDATE | `order_date DATE DEFAULT SYSDATE` | ✅ |
| `total_amount` NUMBER(12,2) DEFAULT 0 CHECK >= 0 | `total_amount NUMBER(12,2) DEFAULT 0` CHECK >= 0 | ✅ |
| `status` VARCHAR2(20) DEFAULT 'PENDING' CHECK | `status VARCHAR2(20) DEFAULT 'PENDING'` CHECK | ✅ |
| `shipping_address` NVARCHAR2(500) NOT NULL | `shipping_address NVARCHAR2(500) NOT NULL` | ✅ |
| `payment_method` VARCHAR2(30) CHECK | `payment_method VARCHAR2(30)` CHECK | ✅ |
| `payment_status` VARCHAR2(20) DEFAULT 'PENDING' CHECK | `payment_status VARCHAR2(20) DEFAULT 'PENDING'` CHECK | ✅ |
| `shipping_fee` NUMBER(10,2) DEFAULT 0 CHECK >= 0 | `shipping_fee NUMBER(10,2) DEFAULT 0` CHECK >= 0 | ✅ |
| `discount_amount` NUMBER(10,2) DEFAULT 0 CHECK >= 0 | `discount_amount NUMBER(10,2) DEFAULT 0` CHECK >= 0 | ✅ |
| `updated_at` DATE | `updated_at DATE` | ✅ |

#### ORDER_DETAILS
| Cột trong ERD | Cột trong DDL | Kết quả |
|---------------|---------------|---------|
| `order_detail_id` NUMBER PK | `order_detail_id NUMBER` PK | ✅ |
| `order_id` NUMBER FK NOT NULL | `order_id NUMBER NOT NULL` FK | ✅ |
| `book_id` NUMBER FK NOT NULL | `book_id NUMBER NOT NULL` FK | ✅ |
| `quantity` NUMBER NOT NULL CHECK > 0 | `quantity NUMBER NOT NULL` CHECK > 0 | ✅ |
| `unit_price` NUMBER(10,2) NOT NULL CHECK > 0 | `unit_price NUMBER(10,2) NOT NULL` CHECK > 0 | ✅ |
| `subtotal` GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL | `subtotal NUMBER(12,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL` | ✅ |
| UNIQUE(order_id, book_id) | `uq_od_order_book UNIQUE (order_id, book_id)` | ✅ |

> **Ghi chú:** Các bảng còn lại (`CARTS`, `CART_ITEMS`, `AUTHORS`, `PUBLISHERS`, `COUPONS`, `BOOK_IMAGES`, `BOOK_AUTHORS`, `INVENTORY_TRANSACTIONS`, `ORDER_STATUS_HISTORY`, `REVIEWS`) đã được đối chiếu tương tự và **tất cả đều khớp** giữa ERD và DDL.

**Kết luận tổng:** ✅ **Tất cả cột, kiểu dữ liệu, PK, FK, CHECK constraint đều đồng bộ giữa `1_Database_Design.md` và `2_create_tables.sql`.**

---

## 3. Kiểm tra Ràng buộc (Constraints)

### 3.1. Primary Keys

| Bảng | PK trong ERD | PK trong DDL | Kết quả |
|------|-------------|-------------|---------|
| CUSTOMERS | `customer_id` | `pk_customers(customer_id)` | ✅ |
| CATEGORIES | `category_id` | `pk_categories(category_id)` | ✅ |
| CARTS | `cart_id` | `pk_carts(cart_id)` | ✅ |
| CART_ITEMS | `cart_item_id` | `pk_cart_items(cart_item_id)` | ✅ |
| AUTHORS | `author_id` | `pk_authors(author_id)` | ✅ |
| PUBLISHERS | `publisher_id` | `pk_publishers(publisher_id)` | ✅ |
| COUPONS | `coupon_id` | `pk_coupons(coupon_id)` | ✅ |
| BOOKS | `book_id` | `pk_books(book_id)` | ✅ |
| BOOK_IMAGES | `image_id` | `pk_book_images(image_id)` | ✅ |
| BOOK_AUTHORS | `(book_id, author_id)` composite | `pk_book_authors(book_id, author_id)` | ✅ |
| INVENTORY_TRANSACTIONS | `txn_id` | `pk_inventory_txn(txn_id)` | ✅ |
| ORDERS | `order_id` | `pk_orders(order_id)` | ✅ |
| ORDER_DETAILS | `order_detail_id` | `pk_order_details(order_detail_id)` | ✅ |
| ORDER_STATUS_HISTORY | `status_history_id` | `pk_order_status_his(status_history_id)` | ✅ |
| REVIEWS | `review_id` | `pk_reviews(review_id)` | ✅ |

### 3.2. Foreign Keys

| FK | ERD | DDL | Kết quả |
|----|-----|-----|---------|
| CATEGORIES.parent_id → CATEGORIES | ✅ | `fk_categories_parent` | ✅ |
| CARTS.customer_id → CUSTOMERS | ✅ | `fk_carts_customer` | ✅ |
| BOOKS.category_id → CATEGORIES | ✅ | `fk_books_category` | ✅ |
| BOOKS.publisher_id → PUBLISHERS | ✅ | `fk_books_publisher` | ✅ |
| BOOK_IMAGES.book_id → BOOKS | ✅ | `fk_bimg_book` | ✅ |
| BOOK_AUTHORS.book_id → BOOKS | ✅ | `fk_ba_book` | ✅ |
| BOOK_AUTHORS.author_id → AUTHORS | ✅ | `fk_ba_author` | ✅ |
| ORDERS.customer_id → CUSTOMERS | ✅ | `fk_orders_customer` | ✅ |
| ORDERS.coupon_id → COUPONS | ✅ | `fk_orders_coupon` | ✅ |
| ORDER_DETAILS.order_id → ORDERS | ✅ | `fk_od_order` | ✅ |
| ORDER_DETAILS.book_id → BOOKS | ✅ | `fk_od_book` | ✅ |
| ORDER_STATUS_HISTORY.order_id → ORDERS | ✅ | `fk_osh_order` | ✅ |
| ORDER_STATUS_HISTORY.changed_by → CUSTOMERS | ✅ | `fk_osh_changed_by` | ✅ |
| REVIEWS.order_id → ORDERS | ✅ | `fk_reviews_order` | ✅ |
| REVIEWS.book_id → BOOKS | ✅ | `fk_reviews_book` | ✅ |
| REVIEWS.(order_id, book_id) → ORDER_DETAILS | ✅ | `fk_reviews_od` | ✅ |
| CART_ITEMS.cart_id → CARTS | ✅ | `fk_ci_cart` | ✅ |
| CART_ITEMS.book_id → BOOKS | ✅ | `fk_ci_book` | ✅ |
| INVENTORY_TRANSACTIONS.book_id → BOOKS | ✅ | `fk_it_book` | ✅ |
| INVENTORY_TRANSACTIONS.reference_id → ORDERS | ✅ | `fk_it_order_ref` | ✅ |

**Tổng:** 20/20 FK trong ERD đều có mặt trong DDL. ✅ **ĐỒNG BỘ**

### 3.3. Sequences & Auto-Increment Triggers

| Bảng | Sequence | Trigger PK | Kết quả |
|------|----------|-----------|---------|
| CUSTOMERS | `seq_customers` | `trg_bi_customers` | ✅ |
| CATEGORIES | `seq_categories` | `trg_bi_categories` | ✅ |
| CARTS | `seq_carts` | `trg_bi_carts` | ✅ |
| CART_ITEMS | `seq_cart_items` | `trg_bi_cart_items` | ✅ |
| AUTHORS | `seq_authors` | `trg_bi_authors` | ✅ |
| PUBLISHERS | `seq_publishers` | `trg_bi_publishers` | ✅ |
| COUPONS | `seq_coupons` | `trg_bi_coupons` | ✅ |
| BOOKS | `seq_books` | `trg_bi_books` | ✅ |
| BOOK_IMAGES | `seq_book_images` | `trg_bi_book_images` | ✅ |
| ORDERS | `seq_orders` | `trg_bi_orders` | ✅ |
| ORDER_DETAILS | `seq_order_details` | `trg_bi_order_details` | ✅ |
| ORDER_STATUS_HISTORY | `seq_order_status_his` | `trg_bi_order_status_his` | ✅ |
| REVIEWS | `seq_reviews` | `trg_bi_reviews` | ✅ |
| INVENTORY_TRANSACTIONS | `seq_inventory_txn` | `trg_bi_inventory_txn` | ✅ |

> **Ghi chú:** Bảng `BOOK_AUTHORS` dùng PK composite (book_id, author_id) nên không cần sequence/trigger riêng. ✅ Đúng.

---

## 4. Kiểm tra Stored Procedures vs Schema

| SP | Bảng thao tác | Cột sử dụng | Tồn tại trong DDL? | Kết quả |
|----|--------------|-------------|--------------------|---------| 
| `sp_manage_book` (Dũng) | `books`, `categories`, `publishers`, `order_details`, `cart_items`, `book_authors`, `book_images`, `inventory_transactions` | book_id, title, isbn, price, stock_quantity, ... | ✅ Tất cả | ✅ |
| `sp_report_monthly_sales` (Nam) | `orders` | order_date, status, total_amount, discount_amount, shipping_fee | ✅ Tất cả | ✅ |
| `sp_print_low_stock_books` (Hiếu) | `books`, `categories`, `publishers` | book_id, title, stock_quantity, category_name, publisher_name | ✅ Tất cả | ✅ |
| `sp_calculate_coupon_discount` (Phát) | `coupons` | coupon_code, discount_type, discount_value, start_at, end_at, max_uses, used_count, min_order_amount, max_discount_amount, is_active | ✅ Tất cả | ✅ |

**Kết luận:** ✅ Tất cả 4 Stored Procedures thao tác trên đúng bảng và cột đã định nghĩa trong DDL.

---

## 5. Kiểm tra Triggers vs Schema

| Trigger | Bảng tác động | Loại | Cột sử dụng | Khớp DDL? | Kết quả |
|---------|--------------|------|-------------|-----------|---------|
| `trg_biu_orders_validate` (Dũng) | `orders` | BEFORE INSERT/UPDATE | updated_at, shipping_address, status, payment_method, payment_status, shipping_fee, discount_amount, total_amount | ✅ | ✅ |
| `trg_aiud_order_details_recalc_order` (Nam) | `order_details` → `orders` | COMPOUND TRIGGER | order_id, quantity, unit_price, shipping_fee, discount_amount, total_amount | ✅ | ✅ |
| `trg_aiud_orders_audit` (Hiếu) | `orders` → `orders_audit_log` | AFTER INSERT/UPDATE/DELETE | order_id, status, total_amount, payment_status | ✅ | ✅ |

**Kiểm tra bổ sung — Bảng `ORDERS_AUDIT_LOG`:**
- Được tạo trong `5_triggers.sql` (idempotent bằng `EXECUTE IMMEDIATE` + exception handling). ✅
- Có sequence riêng `seq_orders_audit_log`. ✅
- Được ghi nhận trong `1_Database_Design.md` (mục tóm tắt thiết kế: 16 bảng = 15 lõi + 1 audit). ✅

**Kết luận:** ✅ Tất cả 3 trigger nghiệp vụ thao tác trên đúng bảng và cột.

---

## 6. Kiểm tra Views vs Schema

| View | Bảng nguồn | Cột sử dụng | Khớp DDL? | Kết quả |
|------|-----------|-------------|-----------|---------|
| `vw_order_sales_report` (Dũng) | orders, customers, order_details, books, categories, publishers, coupons | order_id, order_date, customer_id, full_name, email, status, coupon_code, discount_type, book_id, title, category_id, category_name, publisher_id, publisher_name, quantity, unit_price, subtotal, shipping_fee, discount_amount, total_amount | ✅ | ✅ |
| `vw_customer_secure_profile` (Nam) | customers, orders | customer_id, full_name, email, phone, address, status, created_at, updated_at, total_amount | ✅ | ✅ |
| `mv_daily_category_sales` (Hiếu) | orders, order_details, books, categories | order_date, order_id, quantity, subtotal, unit_price, book_id, category_id, category_name, status | ✅ | ✅ |

**Kiểm tra bổ sung:**
- View 2 có mệnh đề `WITH READ ONLY` → ✅ Đúng yêu cầu đề bài.
- Materialized View dùng `REFRESH COMPLETE ON DEMAND` → ✅ Tương thích Oracle 19c.

**Kết luận:** ✅ Tất cả 3 view/mview sử dụng đúng bảng và cột trong schema.

---

## 7. Kiểm tra Dữ liệu mẫu vs Ràng buộc

### 7.1. Thống kê bản ghi

| Bảng | Số bản ghi | Yêu cầu | Kết quả |
|------|-----------|---------|---------|
| CUSTOMERS | 16 | — | ✅ |
| CATEGORIES | 10 | — | ✅ |
| CARTS | 16 | — | ✅ |
| CART_ITEMS | 24 | — | ✅ |
| AUTHORS | 12 | — | ✅ |
| PUBLISHERS | 8 | — | ✅ |
| COUPONS | 8 | — | ✅ |
| BOOKS | 20 | — | ✅ |
| BOOK_IMAGES | 28 | — | ✅ |
| BOOK_AUTHORS | 26 | — | ✅ |
| INVENTORY_TRANSACTIONS | 20 | — | ✅ |
| ORDERS | 15 | — | ✅ |
| ORDER_DETAILS | 30 | — | ✅ |
| ORDER_STATUS_HISTORY | 28 | — | ✅ |
| REVIEWS | 12 | — | ✅ |
| **TỔNG** | **273** | **≥ 100** | ✅ **Vượt** |

### 7.2. Kiểm tra tuân thủ ràng buộc

| Kiểm tra | Chi tiết | Kết quả |
|----------|----------|---------|
| FK BOOKS.category_id | Tất cả category_id (2–10) đều tồn tại trong CATEGORIES | ✅ |
| FK BOOKS.publisher_id | Tất cả publisher_id (1–8) đều tồn tại trong PUBLISHERS | ✅ |
| FK ORDERS.customer_id | Tất cả customer_id (1–15) đều tồn tại trong CUSTOMERS | ✅ |
| FK ORDERS.coupon_id | Coupon IDs (1–8) đều tồn tại; NULL cho đơn không dùng coupon | ✅ |
| FK ORDER_DETAILS.(order_id, book_id) | Tất cả cặp đều hợp lệ | ✅ |
| FK REVIEWS.(order_id, book_id) → ORDER_DETAILS | Tất cả 12 review đều tham chiếu tới cặp (order_id, book_id) có trong ORDER_DETAILS | ✅ |
| CHECK CUSTOMERS.status | Chỉ có 'ACTIVE', 'INACTIVE', 'BANNED' | ✅ |
| CHECK ORDERS.status | Chỉ có 'PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED', 'CANCELLED' | ✅ |
| CHECK COUPONS.discount_type | Chỉ có 'PERCENT', 'FIXED' | ✅ |
| CHECK BOOKS.price > 0 | Tất cả giá > 0 | ✅ |
| CHECK BOOKS.stock_quantity >= 0 | Tất cả >= 0 | ✅ |
| CHECK REVIEWS.rating BETWEEN 1 AND 5 | Tất cả rating từ 4–5 | ✅ |
| UNIQUE CART_ITEMS(cart_id, book_id) | Không có cặp trùng | ✅ |
| UNIQUE ORDER_DETAILS(order_id, book_id) | Không có cặp trùng | ✅ |
| UNIQUE REVIEWS(order_id, book_id) | Không có cặp trùng | ✅ |
| CHECK INVENTORY_TRANSACTIONS txn_type='OUT' requires reference | Tất cả 20 bản ghi là 'IN' với reference_type='MANUAL', không vi phạm | ✅ |
| Sequence sync sau insert | Block PL/SQL cuối file sync tất cả 14 sequence | ✅ |

### 7.3. Kiểm tra nghiệp vụ Reviews

| Review ID | order_id | book_id | Đơn hàng đã DELIVERED? | (order_id, book_id) tồn tại trong ORDER_DETAILS? | Kết quả |
|-----------|----------|---------|----------------------|--------------------------------------------------|---------|
| 1 | 1 | 1 | Đơn 1 = DELIVERED ✅ | OD row 1: (1,1) ✅ | ✅ |
| 2 | 1 | 3 | Đơn 1 = DELIVERED ✅ | OD row 2: (1,3) ✅ | ✅ |
| 3 | 2 | 2 | Đơn 2 = DELIVERED ✅ | OD row 3: (2,2) ✅ | ✅ |
| 4 | 2 | 5 | Đơn 2 = DELIVERED ✅ | OD row 4: (2,5) ✅ | ✅ |
| 5 | 3 | 4 | Đơn 3 = SHIPPING ⚠️ | OD row 5: (3,4) ✅ | ⚠️ Lưu ý |
| 6 | 3 | 6 | Đơn 3 = SHIPPING ⚠️ | OD row 6: (3,6) ✅ | ⚠️ Lưu ý |
| 7 | 4 | 7 | Đơn 4 = CONFIRMED ⚠️ | OD row 7: (4,7) ✅ | ⚠️ Lưu ý |
| 8 | 4 | 8 | Đơn 4 = CONFIRMED ⚠️ | OD row 8: (4,8) ✅ | ⚠️ Lưu ý |
| 9 | 6 | 11 | Đơn 6 = DELIVERED ✅ | OD row 11: (6,11) ✅ | ✅ |
| 10 | 6 | 12 | Đơn 6 = DELIVERED ✅ | OD row 12: (6,12) ✅ | ✅ |
| 11 | 10 | 19 | Đơn 10 = DELIVERED ✅ | OD row 19: (10,19) ✅ | ✅ |
| 12 | 10 | 20 | Đơn 10 = DELIVERED ✅ | OD row 20: (10,20) ✅ | ✅ |

> **⚠️ Phát hiện #1 — Severity: LOW (Nghiệp vụ, không phải lỗi kỹ thuật)**
> Reviews 5–8 tham chiếu đơn hàng chưa DELIVERED (đơn 3 = SHIPPING, đơn 4 = CONFIRMED). Về mặt **ràng buộc CSDL** thì FK vẫn hợp lệ (không có trigger/check nào chặn). Tuy nhiên **về nghiệp vụ**, thiết kế ban đầu nêu "Chỉ người đã mua mới được đánh giá" — thông thường đơn phải DELIVERED thì khách mới review. Điều này **không phải lỗi kỹ thuật** (CSDL chấp nhận) nhưng nên bổ sung trigger validation cho REVIEWS nếu muốn enforce nghiệp vụ chặt hơn.

**Kết luận:** ✅ Dữ liệu mẫu **tuân thủ tất cả ràng buộc CSDL**. Có 1 lưu ý nghiệp vụ nhỏ về review trên đơn chưa DELIVERED.

---

## 8. Kiểm tra Index vs Truy vấn thực tế

| Index | Loại | Bảng.Cột | Truy vấn thực tế phục vụ | Khớp DDL? | Kết quả |
|-------|------|---------|--------------------------|-----------|---------|
| `uq_bimg_primary_one` | Unique Function-based | `book_images(CASE WHEN is_primary=1 THEN book_id END)` | Ràng buộc 1 ảnh chính/sách | `2_create_tables.sql` | ✅ |
| `idx_orders_recent_date` | B-Tree DESC | `orders(order_date DESC, order_id DESC)` | Dashboard đơn mới nhất | `7_indexes_and_tuning.sql` | ✅ |
| `idx_books_low_stock` | B-Tree | `books(stock_quantity, book_id)` | SP `sp_print_low_stock_books` | `7_indexes_and_tuning.sql` | ✅ |
| `idx_orders_trunc_order_date` | Function-based | `orders(TRUNC(order_date))` | Báo cáo doanh thu theo ngày | `7_indexes_and_tuning.sql` | ✅ |
| `idx_books_category_bm` | Bitmap | `books(category_id)` | Báo cáo/filter theo danh mục | `7_indexes_and_tuning.sql` | ✅ |

**Kiểm tra bổ sung:**
- Index 1 (`uq_bimg_primary_one`): phản ánh đúng ràng buộc "mỗi sách tối đa 1 ảnh chính" trong thiết kế. ✅
- Index 2 (`idx_orders_recent_date`): Khớp với truy vấn Q1 trong EXPLAIN PLAN. ✅
- Index 3 (`idx_books_low_stock`): Khớp với cursor trong SP3. ✅  
- Index 4 (`idx_orders_trunc_order_date`): Khớp với truy vấn Q3 dùng `TRUNC(order_date)`. ✅
- Index 5 (`idx_books_category_bm`): Cardinality thấp (10 categories), bitmap phù hợp cho workload OLAP. ✅

**Kết luận:** ✅ **5/5 index đều phục vụ đúng truy vấn thực tế trong hệ thống.**

---

## 9. Kiểm tra Phân quyền vs Đối tượng

### 9.1. Các đối tượng được cấp quyền

| Đối tượng | ADMIN_ROLE | STAFF_ROLE | GUEST_ROLE | Tồn tại trong DDL? |
|-----------|-----------|-----------|-----------|---------------------|
| CUSTOMERS | SELECT,INSERT,UPDATE,DELETE | SELECT | — | ✅ |
| CATEGORIES | SELECT,INSERT,UPDATE,DELETE | SELECT | SELECT | ✅ |
| CARTS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | — | ✅ |
| CART_ITEMS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE,DELETE | — | ✅ |
| AUTHORS | SELECT,INSERT,UPDATE,DELETE | SELECT | SELECT | ✅ |
| PUBLISHERS | SELECT,INSERT,UPDATE,DELETE | SELECT | SELECT | ✅ |
| COUPONS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | — | ✅ |
| BOOKS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | SELECT | ✅ |
| BOOK_IMAGES | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | SELECT | ✅ |
| BOOK_AUTHORS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE,DELETE | — | ✅ |
| ORDERS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | — | ✅ |
| ORDER_DETAILS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | — | ✅ |
| ORDER_STATUS_HISTORY | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT | — | ✅ |
| REVIEWS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT,UPDATE | — | ✅ |
| INVENTORY_TRANSACTIONS | SELECT,INSERT,UPDATE,DELETE | SELECT,INSERT | — | ✅ |
| VW_ORDER_SALES_REPORT | SELECT | SELECT | — | ✅ |
| VW_CUSTOMER_SECURE_PROFILE | SELECT | SELECT | SELECT | ✅ |
| MV_DAILY_CATEGORY_SALES | SELECT | SELECT | — | ✅ |
| SP_MANAGE_BOOK | EXECUTE | EXECUTE | — | ✅ |
| SP_REPORT_MONTHLY_SALES | EXECUTE | EXECUTE | — | ✅ |
| SP_PRINT_LOW_STOCK_BOOKS | EXECUTE | EXECUTE | — | ✅ |
| SP_CALCULATE_COUPON_DISCOUNT | EXECUTE | EXECUTE | — | ✅ |

**Kiểm tra hợp lý:**
- GUEST chỉ SELECT trên bảng công khai (books, categories, authors, publishers, book_images) và view bảo mật → ✅ Hợp lý
- STAFF có quyền tác nghiệp (INSERT/UPDATE) nhưng bị hạn chế DELETE trên các bảng quan trọng → ✅ Hợp lý
- ADMIN có toàn quyền DML trên tất cả bảng → ✅ Hợp lý  
- `ORDERS_AUDIT_LOG` không có trong danh sách cấp quyền → ✅ Chấp nhận (bảng audit nội bộ, chỉ trigger ghi)

**Kết luận:** ✅ **Phân quyền đầy đủ, hợp lý và khớp với các đối tượng trong schema.**

---

## 10. Kiểm tra Transaction Demo

| Tiêu chí | Chi tiết | Kết quả |
|----------|----------|---------|
| SET TRANSACTION ISOLATION LEVEL | `SERIALIZABLE` — có khai báo rõ ràng | ✅ |
| FOR UPDATE locking | `FOR UPDATE WAIT 5` trên bảng BOOKS | ✅ |
| Bảng thao tác | CUSTOMERS, BOOKS, ORDERS, ORDER_DETAILS, INVENTORY_TRANSACTIONS, ORDER_STATUS_HISTORY | ✅ Tất cả tồn tại |
| COMMIT khi thành công | Có `COMMIT;` sau bước 10 | ✅ |
| ROLLBACK khi lỗi | 4 nhánh EXCEPTION đều có `ROLLBACK;` | ✅ |
| Xử lý lỗi ORA-01453 | Có `ROLLBACK;` trước `SET TRANSACTION` | ✅ |
| Kiểm tra tồn kho trước khi trừ | `IF v_stock_before < v_quantity THEN RAISE` | ✅ |
| Ghi inventory transaction | INSERT INTO inventory_transactions (OUT, ORDER) | ✅ |
| Ghi order_status_history | INSERT INTO order_status_history | ✅ |

**Kết luận:** ✅ **Transaction demo đầy đủ, xử lý đúng luồng nghiệp vụ và đồng nhất với schema.**

---

## 11. Kiểm tra Báo cáo tổng hợp

| Tiêu chí | Yêu cầu | Thực tế (`10_Final_Report.md`) | Kết quả |
|----------|---------|-------------------------------|---------|
| Tóm tắt cấu trúc dự án | Có | Mục 2: liệt kê đầy đủ file SQL, test, web-ui | ✅ |
| Hướng dẫn chạy file SQL | Có | Mục 4: Runbook chi tiết thứ tự + kết quả mong đợi | ✅ |
| Phân tích kết quả từng bước | Có | Mục 5: Phân tích Bước 1–9 | ✅ |
| Bảng phân công công việc | Có | Mục 6: 4 thành viên, đầu ra tiêu biểu | ✅ |
| Hướng dẫn chạy nhanh | Có | Mục 7: SQL + Web UI | ✅ |

**Kết luận:** ✅ **Báo cáo tổng hợp đầy đủ theo yêu cầu.**

---

## 12. Bảng tổng hợp phát hiện

| # | Mức độ | Hạng mục | Mô tả | Đề xuất sửa |
|---|--------|---------|-------|-------------|
| 1 | 🟢 **LOW** (Nghiệp vụ) | Dữ liệu mẫu — Reviews | 4 review (ID 5–8) tham chiếu đơn hàng chưa DELIVERED (SHIPPING/CONFIRMED). FK hợp lệ nhưng nghiệp vụ "chỉ review khi đã nhận hàng" chưa được enforce. | Bổ sung trigger `BEFORE INSERT ON REVIEWS` kiểm tra `ORDERS.status = 'DELIVERED'` trước khi cho insert. Hoặc chấp nhận cho beta nếu muốn cho phép review sớm. |
| 2 | ℹ️ **INFO** | Thiết kế — Technical Debt | Đã được document đầy đủ trong `1_Database_Design.md` mục 9 (13 items). Các vấn đề race condition, auth, backup đều đã có solution path. | Không cần sửa — chỉ cần follow roadmap đã vạch. |
| 3 | ℹ️ **INFO** | DDL — Trigger chống vòng lặp CATEGORIES | Đã document trong thiết kế (mục 4.15) nhưng chưa triển khai trigger chặn circular reference. | Chấp nhận cho beta. Triển khai khi thêm tính năng quản lý danh mục trong giao diện admin. |

---

## 13. Kết luận

### ✅ Kết quả đánh giá tổng thể: **ĐẠT — ĐỒNG BỘ VÀ NHẤT QUÁN**

Sau khi rà soát toàn bộ 10 file sản phẩm từ Bước 1 đến Bước 10, kết quả như sau:

| Hạng mục kiểm tra | Trạng thái |
|-------------------|------------|
| ERD vs DDL (tên bảng, cột, kiểu dữ liệu) | ✅ Khớp 100% |
| Primary Keys (15 bảng) | ✅ Khớp 100% |
| Foreign Keys (20 FK) | ✅ Khớp 100% |
| CHECK / UNIQUE constraints | ✅ Khớp 100% |
| Sequences + Trigger sinh PK (14 bảng) | ✅ Khớp 100% |
| Stored Procedures thao tác đúng bảng/cột | ✅ Khớp 100% |
| Triggers thao tác đúng bảng/cột | ✅ Khớp 100% |
| Views/MView sử dụng đúng bảng/cột | ✅ Khớp 100% |
| Dữ liệu mẫu tuân thủ ràng buộc CSDL | ✅ Khớp 100% |
| Index phục vụ truy vấn thực tế | ✅ Khớp 100% |
| Phân quyền khớp đối tượng trong schema | ✅ Khớp 100% |
| Transaction demo đúng luồng nghiệp vụ | ✅ Khớp 100% |
| Báo cáo tổng hợp đầy đủ nội dung | ✅ Khớp 100% |

**Tất cả các thành phần đều đồng bộ và nhất quán.** Không phát hiện lỗi kỹ thuật nào ảnh hưởng đến tính toàn vẹn dữ liệu. Chỉ có **1 lưu ý nghiệp vụ nhỏ** về review trên đơn chưa DELIVERED (không ảnh hưởng FK/constraint) và **2 ghi nhận thông tin** về technical debt đã document.

> **Xác nhận:** Dự án DigiBook đã hoàn thành đầy đủ 10 bước theo kế hoạch, tất cả sản phẩm đầu ra đồng bộ và sẵn sàng cho giai đoạn kiểm thử/nộp báo cáo.

---

*Báo cáo tự đánh giá được tạo tự động bởi AI Senior DBA, ngày 2026-03-19.*
