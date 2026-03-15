# 📊 BÁO CÁO TỔNG HỢP — DỰ ÁN CƠ SỞ DỮ LIỆU DigiBook

> **Đồ án môn học:** Thiết kế và Xây dựng Cơ sở dữ liệu  
> **Chủ đề:** Website bán sách trực tuyến DigiBook  
> **Hệ quản trị CSDL:** Oracle 19c  
> **Nhóm thực hiện:** Dũng, Nam, Hiếu, Phát  
> **Ngày hoàn thành:** 15/03/2026

---

## 📋 MỤC LỤC

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Cấu trúc thư mục dự án](#2-cấu-trúc-thư-mục-dự-án)
3. [Hướng dẫn triển khai (Deployment Guide)](#3-hướng-dẫn-triển-khai)
4. [Tóm tắt từng bước thực hiện](#4-tóm-tắt-từng-bước-thực-hiện)
5. [Phân tích kết quả](#5-phân-tích-kết-quả)
6. [Bảng phân công công việc](#6-bảng-phân-công-công-việc)
7. [Kết luận](#7-kết-luận)

---

## 1. Tổng quan dự án

### 1.1. Mô tả hệ thống

**DigiBook** là một nền tảng thương mại điện tử chuyên bán sách trực tuyến. Hệ thống hỗ trợ các chức năng chính:

| STT | Chức năng | Mô tả |
|-----|-----------|-------|
| 1 | Quản lý sách | Thêm, sửa, xóa, phân loại sách theo danh mục |
| 2 | Quản lý khách hàng | Đăng ký, đăng nhập, quản lý thông tin cá nhân |
| 3 | Đặt hàng | Tạo đơn hàng, thêm sách vào giỏ, thanh toán |
| 4 | Quản lý kho | Theo dõi số lượng tồn kho |
| 5 | Đánh giá sách | Khách hàng đánh giá & bình luận sách |
| 6 | Quản lý tác giả | Thông tin tác giả, liên kết tác giả — sách |
| 7 | Quản lý NXB | Thông tin nhà xuất bản, liên kết NXB — sách |

### 1.2. Thống kê tổng quan

| Chỉ số | Giá trị |
|--------|---------|
| Tổng số bảng dữ liệu | **10** (9 bảng chính + 1 bảng AUDIT_LOG) |
| Tổng số Sequences | **9** |
| Tổng số Triggers | **12** (8 auto-ID + 1 validation + 3 nghiệp vụ) |
| Tổng số Stored Procedures | **4** |
| Tổng số Views | **2** (Standard Views) |
| Tổng số Materialized Views | **1** |
| Tổng số Index | **11** (8 B-Tree + 2 Bitmap + 1 FBI) |
| Tổng số Roles | **3** |
| Tổng số Users | **3** |
| Tổng bản ghi dữ liệu mẫu | **111** |
| Chuẩn hóa | **3NF** |

---

## 2. Cấu trúc thư mục dự án

```
DigiBook_Database/
├── ai_execution_plan.md         ← Kế hoạch thực thi tổng thể
├── 1_Database_Design.md         ← Bước 1: Thiết kế CSDL + ERD (Mermaid)
├── 2_create_tables.sql          ← Bước 2: DDL — Tạo bảng, Sequences, Triggers (auto-ID + validation)
├── 3_insert_data.sql            ← Bước 3: DML — Dữ liệu mẫu (111 bản ghi)
├── 4_procedures.sql             ← Bước 4: 4 Stored Procedures PL/SQL
├── 5_triggers.sql               ← Bước 5: 3 Triggers nghiệp vụ + bảng AUDIT_LOG
├── 6_views.sql                  ← Bước 6: 2 Views + 1 Materialized View
├── 7_indexes_and_tuning.sql     ← Bước 7: 10 Indexes + EXPLAIN PLAN
├── 8_security_roles.sql         ← Bước 8: 3 Roles + 3 Users + DCL
├── 9_transaction_demo.sql       ← Bước 9: 4 Transaction demos
├── 10_Final_Report.md           ← Bước 10: Báo cáo tổng hợp (file này)
└── 11_Self_Evaluation.md        ← Bước 11: Tự đánh giá & kiểm tra nhất quán
```

---

## 3. Hướng dẫn triển khai

### 3.1. Yêu cầu hệ thống

- **Oracle Database 19c** (Enterprise/Standard Edition)
- **SQL*Plus** hoặc **SQL Developer** để thực thi script
- User có quyền **DBA** (cho Bước 8 — phân quyền)
- Quyền `CREATE MATERIALIZED VIEW` (cho Bước 6)

### 3.2. Thứ tự chạy các file SQL

> ⚠️ **QUAN TRỌNG:** Phải chạy theo đúng thứ tự dưới đây. Các file phụ thuộc lẫn nhau (bảng cha trước bảng con, dữ liệu trước stored procedure...).

| Thứ tự | File | Mô tả | Lưu ý |
|--------|------|-------|-------|
| 1 | `2_create_tables.sql` | Tạo 9 bảng, 8 sequences, 9 triggers (8 auto-ID + 1 validation) | Chạy dưới schema chính |
| 2 | `3_insert_data.sql` | Chèn 111 bản ghi dữ liệu mẫu | `SET DEFINE OFF` đã có trong file |
| 3 | `4_procedures.sql` | Tạo 4 Stored Procedures | `SET SERVEROUTPUT ON` để xem kết quả test |
| 4 | `5_triggers.sql` | Tạo bảng AUDIT_LOG + 3 triggers nghiệp vụ | File đã tự tạo bảng AUDIT_LOG |
| 5 | `6_views.sql` | Tạo 2 Views + 1 Materialized View | Cần quyền `CREATE MATERIALIZED VIEW` |
| 6 | `7_indexes_and_tuning.sql` | Tạo 10 Indexes + chạy EXPLAIN PLAN | Xem kết quả EXPLAIN PLAN trên console |
| 7 | `8_security_roles.sql` | Tạo Roles, Users và phân quyền | **Cần quyền SYSDBA/DBA** |
| 8 | `9_transaction_demo.sql` | Chạy 4 demos transaction | `SET SERVEROUTPUT ON` |

### 3.3. Cách chạy (SQL*Plus)

```sql
-- Kết nối vào Oracle với user có quyền
sqlplus DIGIBOOK/Digibook123@DIGIBOOK

-- Bật hiển thị output
SET SERVEROUTPUT ON;

-- Chạy từng file theo thứ tự
@2_create_tables.sql
@3_insert_data.sql
@4_procedures.sql
@5_triggers.sql
@6_views.sql
@7_indexes_and_tuning.sql

-- File này cần chạy dưới quyền SYSDBA
CONNECT sys/password AS SYSDBA;
@8_security_roles.sql

-- Quay lại user thường
CONNECT your_user/your_password@your_db;
@9_transaction_demo.sql
```

---

## 4. Tóm tắt từng bước thực hiện

### 4.1. Bước 1 — Thiết kế CSDL

**File:** `1_Database_Design.md`

Thiết kế **9 thực thể** (vượt mức tối thiểu 6), đạt chuẩn **3NF**:

| Thực thể | Phụ trách | Vai trò |
|----------|-----------|---------|
| CUSTOMERS | Dũng | Quản lý khách hàng |
| CATEGORIES | Dũng | Phân loại sách |
| AUTHORS | Nam | Quản lý tác giả |
| PUBLISHERS | Nam | Quản lý NXB |
| BOOKS | Hiếu | Sản phẩm chính |
| BOOK_AUTHORS | Hiếu | Bảng trung gian N:N (Sách ↔ Tác giả) |
| ORDERS | Phát | Đơn hàng |
| ORDER_DETAILS | Phát | Chi tiết đơn hàng (Virtual Column `subtotal`) |
| REVIEWS | Phát | Đánh giá sách |

**Tính năng nổi bật:**
- Sơ đồ ERD vẽ bằng Mermaid.js
- Quan hệ N:N giải quyết bằng bảng trung gian `BOOK_AUTHORS`
- Virtual Column `subtotal = quantity * unit_price`

---

### 4.2. Bước 2 — Tạo lược đồ & Ràng buộc (DDL)

**File:** `2_create_tables.sql`

| Thành phần | Số lượng |
|-----------|---------|
| Tables | 9 |
| Sequences | 8 |
| Triggers Auto-ID | 8 |
| Trigger Validation | 1 |
| PRIMARY KEY | 9 |
| FOREIGN KEY | 9 |
| UNIQUE constraints | 6 |
| CHECK constraints | 8+ |
| COMMENT ON | Tất cả bảng + cột |

**Tính năng nổi bật:**
- Script có phần dọn dẹp (DROP) an toàn ở đầu — có thể chạy lại nhiều lần
- Sequence + Trigger auto-increment (chuẩn Oracle truyền thống)
- Virtual Column trên `ORDER_DETAILS.subtotal`
- `ON DELETE CASCADE` / `ON DELETE SET NULL` cho FK

---

### 4.3. Bước 3 — Dữ liệu mẫu (DML)

**File:** `3_insert_data.sql`

| Bảng | Số bản ghi | Phụ trách |
|------|-----------|-----------|
| CATEGORIES | 8 | Dũng |
| CUSTOMERS | 10 | Dũng |
| AUTHORS | 12 | Nam |
| PUBLISHERS | 5 | Nam |
| BOOKS | 20 | Hiếu |
| BOOK_AUTHORS | 21 | Hiếu |
| ORDERS | 10 | Phát |
| ORDER_DETAILS | 15 | Phát |
| REVIEWS | 10 | Phát |
| **Tổng** | **111** | |

**Tính năng nổi bật:**
- Dữ liệu thực tế, có ý nghĩa (tên sách/tác giả/NXB Việt Nam thật)
- Tuân thủ nghiêm ngặt các ràng buộc CHECK, UNIQUE, FK
- Chia đều 4 phần cho 4 thành viên

---

### 4.4. Bước 4 — Stored Procedures (PL/SQL)

**File:** `4_procedures.sql`

| SP | Tên | Phụ trách | Chức năng |
|----|-----|-----------|-----------|
| SP1 | `sp_manage_book` | Dũng | CRUD sách (INSERT/UPDATE/DELETE) với Exception Handling |
| SP2 | `sp_revenue_report` | Nam | Báo cáo doanh thu tổng hợp (Top sách, top KH) |
| SP3 | `sp_list_books_by_cat` | Hiếu | Liệt kê sách theo danh mục bằng **Explicit CURSOR** |
| SP4 | `sp_place_order` | Phát | Xử lý đặt hàng đầy đủ (kiểm tra KH, kho, trừ kho, tạo đơn) |

**Kỹ thuật nổi bật:**
- Custom Exception + `RAISE_APPLICATION_ERROR`
- `RETURNING ... INTO` để lấy ID vừa tạo
- Explicit CURSOR lồng nhau (SP3)
- `SAVEPOINT` / `ROLLBACK TO` (SP4)
- `LISTAGG` gộp tên tác giả
- `FETCH FIRST N ROWS ONLY` (Oracle 12c+)

---

### 4.5. Bước 5 — Triggers nghiệp vụ

**File:** `5_triggers.sql`

| Trigger | Tên | Phụ trách | Bảng | Loại |
|---------|-----|-----------|------|------|
| T1 | `trg_validate_order` | Dũng | ORDERS | BEFORE INSERT/UPDATE |
| T2 | `trg_sync_order_total` | Nam | ORDER_DETAILS | **COMPOUND TRIGGER** |
| T3 | `trg_audit_books` | Hiếu | BOOKS | AFTER INSERT/UPDATE/DELETE |

**Kỹ thuật nổi bật:**
- **Tránh Mutating Table** hoàn toàn:
  - T1: Đọc bảng CUSTOMERS (khác bảng trigger)
  - T2: **Compound Trigger** — gom dữ liệu ở ROW level, xử lý ở STATEMENT level
  - T3: Ghi vào AUDIT_LOG (khác bảng trigger)
- Kiểm tra luồng trạng thái đơn hàng (1 chiều: PENDING → CONFIRMED → SHIPPING → DELIVERED)
- Tạo bảng phụ trợ `AUDIT_LOG` để lưu vết lịch sử

---

### 4.6. Bước 6 — Views

**File:** `6_views.sql`

| View | Tên | Phụ trách | Loại |
|------|-----|-----------|------|
| V1 | `vw_order_report` | Dũng | Standard View — JOIN 5 bảng |
| V2 | `vw_customer_safe` | Nam | Standard View — `WITH READ ONLY` |
| V3 | `mv_book_sales_summary` | Hiếu | **Materialized View** — `REFRESH COMPLETE ON DEMAND` |

**Kỹ thuật nổi bật:**
- V1: JOIN 5 bảng (ORDERS + CUSTOMERS + ORDER_DETAILS + BOOKS + CATEGORIES)
- V2: Data Masking (email: `an***@email.com`, SĐT: `090***4567`) + `WITH READ ONLY`
- V3: `BUILD IMMEDIATE` + `REFRESH COMPLETE ON DEMAND`, tổng hợp doanh số + đánh giá

---

### 4.7. Bước 7 — Indexing & Tối ưu hóa

**File:** `7_indexes_and_tuning.sql`

| Loại | Số lượng | Cột được index |
|------|---------|----------------|
| B-Tree | 8 | FK columns (customer_id, category_id, publisher_id, order_id, book_id) + order_date, customer_id (reviews) |
| Bitmap | 2 | status, payment_method (low cardinality) |
| Function-based | 1 | `UPPER(title)` — tìm kiếm case-insensitive |

**5 EXPLAIN PLAN demo:**
- Q1: Lọc đơn hàng theo customer_id
- Q2: Doanh thu DELIVERED 30 ngày (B-Tree + Bitmap kết hợp)
- Q3: Tìm sách `%keyword%` (FBI hạn chế do leading %)
- Q4: Tìm sách `prefix%` (FBI hiệu quả tối đa)
- Q5: Báo cáo sách bán chạy JOIN 3 bảng

---

### 4.8. Bước 8 — Phân quyền & Bảo mật (DCL)

**File:** `8_security_roles.sql`

| Role | User | Quyền chính |
|------|------|-------------|
| `DIGIBOOK_ADMIN` | `DB_ADMIN_USER` | ALL PRIVILEGES trên mọi đối tượng |
| `DIGIBOOK_STAFF` | `DB_STAFF_USER` | CRUD sách/danh mục, SELECT đơn hàng, View bảo mật KH |
| `DIGIBOOK_GUEST` | `DB_GUEST_USER` | SELECT sách/danh mục/tác giả/đánh giá (chỉ đọc) |

**Nguyên tắc:** Least Privilege — mỗi role chỉ có đúng quyền cần thiết.

---

### 4.9. Bước 9 — Transaction & Concurrency

**File:** `9_transaction_demo.sql`

| Demo | Mô tả | Isolation Level |
|------|-------|-----------------|
| D1 | Đặt hàng liên hoàn (6 bước) | READ COMMITTED |
| D2 | Chuyển danh mục sách | **SERIALIZABLE** |
| D3 | ROLLBACK toàn bộ (khách BANNED) | READ COMMITTED |
| D4 | Deadlock Retry Pattern | — |

**Kỹ thuật nổi bật:**
- `SET TRANSACTION ISOLATION LEVEL` (cả 2 mức Oracle hỗ trợ)
- `SAVEPOINT` / `ROLLBACK TO` / `COMMIT`
- `FOR UPDATE WAIT 5` — row-level lock với timeout
- `PRAGMA EXCEPTION_INIT(-60)` — bắt deadlock
- Retry Loop Pattern với backoff

---

## 5. Phân tích kết quả

### 5.1. Điểm mạnh

| # | Tiêu chí | Đánh giá |
|---|----------|----------|
| 1 | **Thiết kế 3NF** | ✅ Không dư thừa dữ liệu, không phụ thuộc bắc cầu |
| 2 | **Code sạch** | ✅ Comment đầy đủ tiếng Việt, header ghi rõ người phụ trách |
| 3 | **Exception Handling** | ✅ Tất cả SP và Transaction đều có khối EXCEPTION |
| 4 | **Tránh Mutating Table** | ✅ Sử dụng Compound Trigger (T2), đọc bảng khác (T1, T3) |
| 5 | **Bảo mật** | ✅ 3 mức phân quyền (Admin/Staff/Guest), View che giấu dữ liệu nhạy cảm |
| 6 | **Hiệu suất** | ✅ 11 Index phù hợp (B-Tree, Bitmap, FBI) + EXPLAIN PLAN |
| 7 | **Tính toàn vẹn** | ✅ Transaction ACID với SAVEPOINT/ROLLBACK, 2 Isolation Level |
| 8 | **Rerunnable** | ✅ Mọi script đều có phần DROP đầu file — chạy lại an toàn |

### 5.2. Khả năng mở rộng

- **Thêm bảng mới:** Dễ dàng thêm bảng (VD: PROMOTIONS, WISHLISTS) nhờ thiết kế modular.
- **Tích hợp ứng dụng:** Các SP đã sẵn sàng để gọi từ backend (Java, Python, Node.js).
- **Báo cáo nâng cao:** Materialized View `mv_book_sales_summary` có thể schedule refresh tự động.

---

## 6. Bảng phân công công việc

### 6.1. Phân công theo thành viên

#### 👤 DŨNG

| Bước | Công việc | File | Đối tượng |
|------|-----------|------|-----------|
| 1 | Thiết kế bảng | `1_Database_Design.md` | CUSTOMERS, CATEGORIES |
| 2 | Tạo bảng + Constraints | `2_create_tables.sql` | CUSTOMERS, CATEGORIES + Seq/Trg |
| 3 | Chèn dữ liệu | `3_insert_data.sql` | 8 Categories + 10 Customers |
| 4 | Stored Procedure | `4_procedures.sql` | `sp_manage_book` (CRUD sách) |
| 5 | Trigger | `5_triggers.sql` | `trg_validate_order` (Validation) |
| 6 | View | `6_views.sql` | `vw_order_report` (JOIN 5 bảng) |

#### 👤 NAM

| Bước | Công việc | File | Đối tượng |
|------|-----------|------|-----------|
| 1 | Thiết kế bảng | `1_Database_Design.md` | AUTHORS, PUBLISHERS |
| 2 | Tạo bảng + Constraints | `2_create_tables.sql` | AUTHORS, PUBLISHERS + Seq/Trg |
| 3 | Chèn dữ liệu | `3_insert_data.sql` | 12 Authors + 5 Publishers |
| 4 | Stored Procedure | `4_procedures.sql` | `sp_revenue_report` (Báo cáo doanh thu) |
| 5 | Trigger | `5_triggers.sql` | `trg_sync_order_total` (Compound Trigger) |
| 6 | View | `6_views.sql` | `vw_customer_safe` (Data Masking + READ ONLY) |

#### 👤 HIẾU

| Bước | Công việc | File | Đối tượng |
|------|-----------|------|-----------|
| 1 | Thiết kế bảng | `1_Database_Design.md` | BOOKS, BOOK_AUTHORS |
| 2 | Tạo bảng + Constraints | `2_create_tables.sql` | BOOKS, BOOK_AUTHORS + Seq/Trg |
| 3 | Chèn dữ liệu | `3_insert_data.sql` | 20 Books + 21 Book_Authors |
| 4 | Stored Procedure | `4_procedures.sql` | `sp_list_books_by_cat` (CURSOR) |
| 5 | Trigger | `5_triggers.sql` | `trg_audit_books` (Audit Log) |
| 6 | View | `6_views.sql` | `mv_book_sales_summary` (Materialized View) |

#### 👤 PHÁT

| Bước | Công việc | File | Đối tượng |
|------|-----------|------|-----------|
| 1 | Thiết kế bảng | `1_Database_Design.md` | ORDERS, ORDER_DETAILS, REVIEWS |
| 2 | Tạo bảng + Constraints | `2_create_tables.sql` | ORDERS, ORDER_DETAILS, REVIEWS + Seq/Trg |
| 3 | Chèn dữ liệu | `3_insert_data.sql` | 10 Orders + 15 OD + 10 Reviews |
| 4 | Stored Procedure | `4_procedures.sql` | `sp_place_order` (Xử lý đặt hàng) |
| 7 | Indexing | `7_indexes_and_tuning.sql` | FBI `UPPER(title)` |
| 8 | Phân quyền | `8_security_roles.sql` | DIGIBOOK_GUEST |

### 6.2. Phân công theo file (công việc chung)

| File | Người thực hiện chính |
|------|----------------------|
| `7_indexes_and_tuning.sql` | Dũng, Nam (B-Tree) + Hiếu (Bitmap) + Phát (FBI) |
| `8_security_roles.sql` | Dũng (Admin) + Nam, Hiếu (Staff) + Phát (Guest) |
| `9_transaction_demo.sql` | Dũng, Nam (Demo 1) + Hiếu, Phát (Demo 2, 3, 4) |
| `10_Final_Report.md` | Cả nhóm |

---

## 7. Kết luận

Dự án CSDL DigiBook đã được thiết kế và triển khai hoàn chỉnh trên **Oracle 19c**, bao gồm đầy đủ các thành phần từ thiết kế logic (ERD, 3NF) đến triển khai vật lý (DDL, DML, PL/SQL, DCL) và tối ưu hóa (Indexing, EXPLAIN PLAN).

### Thành quả đạt được:

- ✅ **9 bảng dữ liệu** đạt chuẩn 3NF với đầy đủ ràng buộc
- ✅ **111 bản ghi** dữ liệu mẫu thực tế
- ✅ **4 Stored Procedures** xử lý nghiệp vụ phức tạp
- ✅ **3 Triggers nghiệp vụ** (bao gồm Compound Trigger tránh Mutating Table)
- ✅ **3 Views** (bao gồm Materialized View)
- ✅ **11 Indexes** (B-Tree, Bitmap, Function-based) với EXPLAIN PLAN
- ✅ **3 Roles + 3 Users** phân quyền theo nguyên tắc Least Privilege
- ✅ **4 Transaction demos** minh họa ACID, Isolation Level, Deadlock Handling
- ✅ Code sạch, comment đầy đủ tiếng Việt, dễ bảo trì

Mọi file SQL đều có cơ chế dọn dẹp (DROP) ở đầu, cho phép **chạy lại nhiều lần** mà không bị lỗi.

---

*Báo cáo được hoàn thành ngày 15/03/2026 bởi nhóm Dũng, Nam, Hiếu, Phát.*
