# Domain Decomposition

Hệ thống phải xử lý:

- Bán hàng offline + online
- Quản lý 2 cửa hàng
- Mỗi cửa hàng có kho riêng
- Đồng bộ tồn kho
- Hóa đơn điện tử
- VAT
- Báo cáo doanh thu
⇒ Chúng ta chia thành 6 module dữ liệu:

1. Master Data
1. Inventory
1. Sales
1. Invoice & Tax
1. Online Order Extension
1. Audit & Control
```Mermaid
erDiagram

%% =========================
%% 1. MASTER DATA
%% =========================

STORE {
    number store_id PK
    varchar store_name
    varchar address
    varchar phone
    varchar status
    date created_at
}

WAREHOUSE {
    number warehouse_id PK
    number store_id FK
    varchar warehouse_name
    varchar location_note
    varchar status
}

PRODUCT {
    number product_id PK
    varchar sku
    varchar product_name
    varchar category
    number purchase_price
    number selling_price
    number min_stock_level
    varchar status
    date created_at
}

CUSTOMER {
    number customer_id PK
    varchar customer_name
    varchar phone
    varchar email
    varchar customer_type
    date created_at
}

EMPLOYEE {
    number employee_id PK
    number store_id FK
    varchar full_name
    varchar role
    varchar status
    date hired_date
}

%% =========================
%% 2. INVENTORY
%% =========================

STOCK {
    number warehouse_id PK, FK
    number product_id PK, FK
    number quantity_on_hand
    date last_updated
}

INVENTORY_TRANSACTION {
    number txn_id PK
    number warehouse_id FK
    number product_id FK
    varchar txn_type
    number quantity_change
    varchar reference_type
    number reference_id
    number employee_id FK
    date created_at
}

%% =========================
%% 3. SALES (CORE)
%% =========================

SALES_ORDER {
    number order_id PK
    number store_id FK
    number customer_id FK
    date order_date
    varchar order_channel
    varchar order_status
    number total_amount
}

SALES_ORDER_DETAIL {
    number order_id PK, FK
    number product_id PK, FK
    number quantity
    number unit_price
    number line_total
}

%% =========================
%% 4. ONLINE EXTENSION
%% =========================

CART {
    number cart_id PK
    number customer_id FK
    date created_at
    varchar status
}

CART_ITEM {
    number cart_id PK, FK
    number product_id PK, FK
    number quantity
    number unit_price
}

PAYMENT {
    number payment_id PK
    number order_id FK
    number customer_id FK
    number amount
    varchar payment_method
    varchar payment_status
    date paid_at
}

SHIPMENT {
    number shipment_id PK
    number order_id FK
    varchar shipping_address
    varchar shipping_status
    date shipped_at
    date delivered_at
}

%% =========================
%% 5. INVOICE & TAX
%% =========================

INVOICE {
    number invoice_id PK
    number order_id FK
    varchar invoice_number
    date issue_date
    number vat_amount
    number total_with_vat
    varchar invoice_status
}

TAX_RATE {
    varchar tax_code PK
    number tax_percentage
    date effective_date
}

%% =========================
%% 6. AUDIT & CONTROL
%% =========================

ERROR_LOG {
    number error_id PK
    varchar module_name
    varchar error_message
    date created_at
}

%% =========================
%% RELATIONSHIPS
%% =========================

STORE ||--|| WAREHOUSE : has
STORE ||--o{ EMPLOYEE : employs
STORE ||--o{ SALES_ORDER : processes

WAREHOUSE ||--o{ STOCK : stores
WAREHOUSE ||--o{ INVENTORY_TRANSACTION : logs

PRODUCT ||--o{ STOCK : stocked_in
PRODUCT ||--o{ SALES_ORDER_DETAIL : appears_in
PRODUCT ||--o{ INVENTORY_TRANSACTION : affected_by
PRODUCT ||--o{ CART_ITEM : added_to

CUSTOMER ||--o{ SALES_ORDER : places
CUSTOMER ||--o{ CART : owns
CUSTOMER ||--o{ PAYMENT : makes

SALES_ORDER ||--o{ SALES_ORDER_DETAIL : contains
SALES_ORDER ||--|| INVOICE : generates
SALES_ORDER ||--o{ PAYMENT : paid_by
SALES_ORDER ||--o{ SHIPMENT : fulfilled_by

TAX_RATE ||--o{ INVOICE : applied_to

EMPLOYEE ||--o{ INVENTORY_TRANSACTION : performs
```

## 1. Quản lý tồn kho & tính toàn vẹn dữ liệu

### 1.1. Kiểm soát không âm tồn

**Nên để Oracle xử lý vì:**

- Liên quan tính toàn vẹn dữ liệu
- Có nhiều nguồn cập nhật (offline, online, API)
**Công nghệ nên dùng:**

- CHECK constraint
- Trigger (validation trước khi update)
- Stored Procedure bắt buộc cho xuất kho
- Transaction control
- Row-level locking
### 1.2. Kiểm soát đồng thời (Concurrency control)

**Mục tiêu:**

- Không bán vượt tồn
- Không ghi đè dữ liệu khi nhiều nhân viên thao tác
**Công nghệ nên dùng:**

- MVCC (cơ chế mặc định của Oracle)
- SELECT FOR UPDATE
- Transaction isolation
- Row-level locking
### 1.3. Audit & truy vết thay đổi tồn kho

**Mục tiêu:**

- Lưu lịch sử thay đổi tồn
- Phục vụ kiểm toán & pháp lý
**Công nghệ nên dùng:**

- AFTER trigger ghi log
- Bảng log chuyên biệt
- Oracle Flashback (nếu cần truy vết nâng cao)
- Unified Auditing (Enterprise)
## 2. Quản lý hóa đơn điện tử & thuế

### 2.1. Sinh số hóa đơn duy nhất

**Mục tiêu:**

- Không trùng số
- Đảm bảo thứ tự
**Công nghệ nên dùng:**

- Sequence
- Unique constraint
### 2.2. Khóa hóa đơn sau khi phát hành

**Mục tiêu:**

- Không cho sửa/xóa hóa đơn hợp lệ
**Công nghệ nên dùng:**

- Trigger kiểm soát trạng thái
- Constraint trạng thái
- Soft delete rule
### 2.3. Tính VAT & tổng tiền chuẩn hóa

**Mục tiêu:**

- Tính toán thống nhất giữa mọi kênh
**Công nghệ nên dùng:**

- Function
- Virtual column (nếu phù hợp)
- Stored Procedure xử lý hoàn tất đơn
### 2.4. Hoàn tất đơn hàng (atomic transaction)

**Mục tiêu:**

Một transaction phải bao gồm:

- Xuất kho
- Tính VAT
- Sinh hóa đơn
- Ghi doanh thu
**Công nghệ nên dùng:**

- Stored Procedure
- Transaction control (COMMIT / ROLLBACK)
- Exception handling trong PL/SQL
## 3. Đồng bộ kho & báo cáo

### 3.1. Đồng bộ tồn kho 2 cửa hàng (cùng DB)

**Công nghệ nên dùng:**

- Thiết kế schema theo kho
- Constraint unique (product + warehouse)
- View tổng tồn
- Index tối ưu truy vấn
Nếu nhiều DB:

- Database Link
- Materialized View
- GoldenGate (môi trường lớn)
### 3.2. Báo cáo doanh thu & thuế định kỳ

**Mục tiêu:**

- Tổng hợp theo ngày/tháng/quý
- Phục vụ kê khai
**Công nghệ nên dùng:**

- View tổng hợp
- Materialized View (pre-aggregation)
