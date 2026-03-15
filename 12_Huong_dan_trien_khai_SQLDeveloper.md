# Hướng dẫn triển khai DigiBook lên Oracle bằng SQL Developer

## 1. Mục tiêu

Tài liệu này hướng dẫn triển khai toàn bộ các file SQL của đồ án DigiBook bằng `sqldeveloper.exe` với tài khoản đã kết nối thành công:

- Username: `DIGIBOOK`
- Password: `Digibook123`

Đồng thời, với mỗi file SQL sẽ có các câu lệnh SQL để kiểm tra lại kết quả sau khi chạy.

## 2. Thứ tự chạy khuyến nghị

Chạy các file theo đúng thứ tự sau:

1. `2_create_tables.sql`
2. `3_insert_data.sql`
3. `4_procedures.sql`
4. `5_triggers.sql`
5. `6_views.sql`
6. `7_indexes_and_tuning.sql`
7. `8_security_roles.sql`
8. `9_transaction_demo.sql`

## 3. Cách chạy bằng SQL Developer

### 3.1. Mở kết nối

1. Mở `sqldeveloper.exe`.
2. Trong phần `Connections`, chọn connection đã kết nối thành công bằng user `DIGIBOOK`.
3. Nếu chưa lưu connection, tạo mới với:
   - Username: `DIGIBOOK`
   - Password: `Digibook123`
   - Chọn đúng `Hostname`, `Port`, `Service name` hoặc `SID` theo máy Oracle của bạn.
4. Nhấn `Test`, sau đó `Connect`.

### 3.2. Cách chạy từng file

1. Vào `File -> Open` và mở file SQL cần chạy.
2. Đảm bảo tab SQL đang dùng đúng connection `DIGIBOOK`.
3. Nhấn `Run Script` hoặc phím `F5`.
4. Chờ đến khi phần `Script Output` báo hoàn tất.

Lưu ý:

- Nên dùng `F5` thay vì `Ctrl+Enter` vì các file có nhiều lệnh PL/SQL, `PROMPT`, `BEGIN ... END;`, `/`.
- Sau khi chạy xong từng file, thực hiện ngay phần `Kiểm tra kết quả` bên dưới.

### 3.3. Cách chạy nhanh bằng menu tự động

Đã bổ sung file menu để chạy nhanh các script theo số:

- `run_menu.sql`: Hiển thị menu và cho phép chọn file cần chạy.
- `run_all.sql`: Chạy tự động từ bước `2` đến bước `7`, sau đó dừng để chạy bước `8` bằng tài khoản `SYS`.

Cách dùng:

1. Mở `run_menu.sql` trong SQL Developer.
2. Đảm bảo đang dùng đúng connection `DIGIBOOK`.
3. Nhấn `F5` (`Run Script`).
4. Nhập lựa chọn từ `0` đến `9` khi được hỏi.

Ý nghĩa lựa chọn:

- `0`: Chạy reset schema (`0_reset_schema.sql`).
- `1` đến `8`: Chạy từng file chức năng tương ứng.
- `9`: Chạy nhanh bước `2` đến bước `7` theo đúng thứ tự.

### 3.4. Bắt buộc chạy riêng bước 8 bằng SYS

Để đúng kế hoạch và tránh lỗi quyền, bước bảo mật phải chạy riêng:

1. Chạy `run_menu.sql` và chọn `9` để hoàn tất bước `2 -> 7`.
2. Ngắt connection hiện tại, đăng nhập bằng `SYS AS SYSDBA` (hoặc user có quyền DBA tương đương).
3. Chạy `8_security_roles.sql` bằng `F5`.
4. Kết nối lại user `DIGIBOOK`, chạy tiếp `9_transaction_demo.sql` (chọn `8` trong menu).

Lưu ý: Đây là luồng đúng theo kế hoạch triển khai: `2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 (SYS) -> 9`.

## 4. Kiểm tra nhanh trước khi triển khai

Chạy các câu lệnh sau bằng connection `DIGIBOOK`:

```sql
SELECT USER FROM dual;

SELECT table_name
FROM user_tables
ORDER BY table_name;

SELECT privilege
FROM user_sys_privs
WHERE privilege IN ('CREATE MATERIALIZED VIEW', 'CREATE USER', 'CREATE ROLE')
ORDER BY privilege;
```

Ý nghĩa:

- `USER` phải trả về `DIGIBOOK`.
- Nếu chưa có `CREATE MATERIALIZED VIEW` thì bước 6 có thể lỗi.
- Nếu chưa có `CREATE USER` hoặc `CREATE ROLE` thì bước 8 sẽ lỗi.

## 5. Triển khai từng phần nhỏ trong từng file

## Cách chạy theo từng phần nhỏ trong SQL Developer

Khi bạn không muốn chạy cả file một lần, hãy làm như sau:

1. Mở file SQL.
2. Bôi đen đúng block muốn chạy.
3. Nhấn `F5` để chạy riêng block đó dưới dạng script.
4. Chạy câu lệnh kiểm tra ngay sau block đó.
5. Chỉ sang block tiếp theo khi block hiện tại đã đúng.

Quy tắc quan trọng:

- Với các block `CREATE OR REPLACE PROCEDURE` hoặc `CREATE OR REPLACE TRIGGER`, phải bôi đen luôn cả dấu `/` ở dòng cuối.
- Với block `BEGIN ... END;`, cũng cần chạy kèm dấu `/` nếu script có dùng.
- Không chạy block phía sau nếu block phụ thuộc phía trước chưa thành công.

---

## Bước 2. Chạy `2_create_tables.sql` theo từng phần nhỏ

### Phần 2.0. Dọn dẹp đối tượng cũ

Chạy toàn bộ phần `DROP TRIGGER`, `DROP SEQUENCE`, `DROP TABLE` ở đầu file.

Kiểm tra:

```sql
SELECT table_name
FROM user_tables
WHERE table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY table_name;
```

Kỳ vọng: có thể ra rỗng hoặc chỉ còn một phần nếu trước đó có lỗi drop, không sao cả.

### Phần 2.1. Tạo các bảng cha độc lập

Chạy lần lượt các block tạo bảng sau:

1. `CUSTOMERS`
2. `CATEGORIES`
3. `AUTHORS`
4. `PUBLISHERS`

Kiểm tra ngay sau khi chạy xong nhóm này:

```sql
SELECT table_name
FROM user_tables
WHERE table_name IN ('CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS')
ORDER BY table_name;
```

### Phần 2.2. Tạo các bảng phụ thuộc sách

Chạy lần lượt:

1. `BOOKS`
2. `BOOK_AUTHORS`

Kiểm tra:

```sql
SELECT table_name
FROM user_tables
WHERE table_name IN ('BOOKS', 'BOOK_AUTHORS')
ORDER BY table_name;

SELECT constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('BOOKS', 'BOOK_AUTHORS')
ORDER BY table_name, constraint_name;
```

### Phần 2.3. Tạo các bảng đơn hàng và đánh giá

Chạy lần lượt:

1. `ORDERS`
2. `ORDER_DETAILS`
3. `REVIEWS`

Kiểm tra:

```sql
SELECT table_name
FROM user_tables
WHERE table_name IN ('ORDERS', 'ORDER_DETAILS', 'REVIEWS')
ORDER BY table_name;

SELECT constraint_name, table_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('ORDERS', 'ORDER_DETAILS', 'REVIEWS')
ORDER BY table_name, constraint_name;
```

### Phần 2.4. Tạo toàn bộ sequence

Chạy cả cụm `CREATE SEQUENCE`.

Kiểm tra:

```sql
SELECT sequence_name
FROM user_sequences
WHERE sequence_name IN (
    'SEQ_CUSTOMERS', 'SEQ_CATEGORIES', 'SEQ_AUTHORS', 'SEQ_PUBLISHERS',
    'SEQ_BOOKS', 'SEQ_ORDERS', 'SEQ_ORDER_DETAILS', 'SEQ_REVIEWS'
)
ORDER BY sequence_name;
```

### Phần 2.5. Tạo từng trigger auto-increment

Chạy lần lượt từng trigger:

1. `TRG_CUSTOMERS_AUTO_ID`
2. `TRG_CATEGORIES_AUTO_ID`
3. `TRG_AUTHORS_AUTO_ID`
4. `TRG_PUBLISHERS_AUTO_ID`
5. `TRG_BOOKS_AUTO_ID`
6. `TRG_ORDERS_AUTO_ID`
7. `TRG_ORDER_DETAILS_AUTO_ID`
8. `TRG_REVIEWS_AUTO_ID`

Kiểm tra:

```sql
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name IN (
    'TRG_CUSTOMERS_AUTO_ID', 'TRG_CATEGORIES_AUTO_ID', 'TRG_AUTHORS_AUTO_ID',
    'TRG_PUBLISHERS_AUTO_ID', 'TRG_BOOKS_AUTO_ID', 'TRG_ORDERS_AUTO_ID',
    'TRG_ORDER_DETAILS_AUTO_ID', 'TRG_REVIEWS_AUTO_ID'
)
ORDER BY trigger_name;
```

### Phần 2.6. Kiểm tra tổng thể bước 2

```sql
SELECT table_name
FROM user_tables
WHERE table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY table_name;

SELECT trigger_name, status
FROM user_triggers
WHERE trigger_name LIKE 'TRG_%_AUTO_ID'
ORDER BY trigger_name;
```

---

## Bước 3. Chạy `3_insert_data.sql` theo từng phần nhỏ

### Phần 3.0. Thiết lập trước khi insert

Chạy:

```sql
SET DEFINE OFF;
```

### Phần 3.1. Insert dữ liệu `CATEGORIES` và `CUSTOMERS`

Chạy toàn bộ block của Dũng.

Kiểm tra:

```sql
SELECT COUNT(*) AS total_categories FROM CATEGORIES;
SELECT COUNT(*) AS total_customers FROM CUSTOMERS;

SELECT customer_id, full_name, email, status
FROM CUSTOMERS
ORDER BY customer_id;
```

### Phần 3.2. Insert dữ liệu `AUTHORS` và `PUBLISHERS`

Chạy toàn bộ block của Nam.

Kiểm tra:

```sql
SELECT COUNT(*) AS total_authors FROM AUTHORS;
SELECT COUNT(*) AS total_publishers FROM PUBLISHERS;

SELECT author_id, author_name, nationality
FROM AUTHORS
ORDER BY author_id;
```

### Phần 3.3. Insert dữ liệu `BOOKS` và `BOOK_AUTHORS`

Chạy toàn bộ block của Hiếu.

Kiểm tra:

```sql
SELECT COUNT(*) AS total_books FROM BOOKS;
SELECT COUNT(*) AS total_book_authors FROM BOOK_AUTHORS;

SELECT book_id, title, category_id, publisher_id
FROM BOOKS
ORDER BY book_id;

SELECT book_id, author_id
FROM BOOK_AUTHORS
ORDER BY book_id, author_id;
```

### Phần 3.4. Insert dữ liệu `ORDERS`, `ORDER_DETAILS`, `REVIEWS`

Chạy toàn bộ block của Phát.

Kiểm tra:

```sql
SELECT COUNT(*) AS total_orders FROM ORDERS;
SELECT COUNT(*) AS total_order_details FROM ORDER_DETAILS;
SELECT COUNT(*) AS total_reviews FROM REVIEWS;

SELECT order_id, customer_id, total_amount, status
FROM ORDERS
ORDER BY order_id;
```

### Phần 3.5. Chạy `COMMIT` và kiểm tra tổng thể

Chạy `COMMIT;` ở cuối file.

Kiểm tra:

```sql
SELECT 'CATEGORIES' AS table_name, COUNT(*) AS total_rows FROM CATEGORIES
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL
SELECT 'AUTHORS', COUNT(*) FROM AUTHORS
UNION ALL
SELECT 'PUBLISHERS', COUNT(*) FROM PUBLISHERS
UNION ALL
SELECT 'BOOKS', COUNT(*) FROM BOOKS
UNION ALL
SELECT 'BOOK_AUTHORS', COUNT(*) FROM BOOK_AUTHORS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_DETAILS', COUNT(*) FROM ORDER_DETAILS
UNION ALL
SELECT 'REVIEWS', COUNT(*) FROM REVIEWS;
```

---

## Bước 4. Chạy `4_procedures.sql` theo từng phần nhỏ

Trước khi test procedure:

```sql
SET SERVEROUTPUT ON;
```

### Phần 4.0. Dọn procedure cũ

Chạy cụm `DROP PROCEDURE` ở đầu file.

### Phần 4.1. Tạo `SP_MANAGE_BOOK`

Chạy riêng block tạo `sp_manage_book`.

Kiểm tra:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
  AND object_name = 'SP_MANAGE_BOOK';

SELECT name, line, position, text
FROM user_errors
WHERE type = 'PROCEDURE'
  AND name = 'SP_MANAGE_BOOK'
ORDER BY sequence;
```

Test nhanh:

```sql
BEGIN
    sp_manage_book(
        p_action => 'UPDATE',
        p_book_id => 1,
        p_price => 111000
    );
END;
/

SELECT book_id, title, price
FROM BOOKS
WHERE book_id = 1;
```

### Phần 4.2. Tạo `SP_REVENUE_REPORT`

Chạy riêng block tạo `sp_revenue_report`.

Kiểm tra:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
  AND object_name = 'SP_REVENUE_REPORT';
```

Test nhanh:

```sql
BEGIN
    sp_revenue_report(SYSDATE - 30, SYSDATE);
END;
/
```

### Phần 4.3. Tạo `SP_LIST_BOOKS_BY_CAT`

Chạy riêng block tạo `sp_list_books_by_cat`.

Kiểm tra:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
  AND object_name = 'SP_LIST_BOOKS_BY_CAT';
```

Test nhanh:

```sql
BEGIN
    sp_list_books_by_cat(1);
END;
/
```

### Phần 4.4. Tạo `SP_PLACE_ORDER`

Chạy riêng block tạo `sp_place_order`.

Kiểm tra:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
  AND object_name = 'SP_PLACE_ORDER';
```

Test nhanh:

```sql
BEGIN
    sp_place_order(
        p_customer_id => 1,
        p_book_id => 1,
        p_quantity => 1,
        p_ship_address => N'Quận 1, TP.HCM',
        p_payment_method => 'COD'
    );
END;
/
```

### Phần 4.5. Kiểm tra tổng thể bước 4

```sql
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PROCEDURE'
  AND object_name IN (
      'SP_MANAGE_BOOK',
      'SP_REVENUE_REPORT',
      'SP_LIST_BOOKS_BY_CAT',
      'SP_PLACE_ORDER'
  )
ORDER BY object_name;

SELECT name, type, line, position, text
FROM user_errors
WHERE type = 'PROCEDURE'
ORDER BY name, sequence;
```

---

## Bước 5. Chạy `5_triggers.sql` theo từng phần nhỏ

Trước khi test trigger:

```sql
SET SERVEROUTPUT ON;
```

### Phần 5.0. Dọn trigger và bảng hỗ trợ cũ

Chạy cụm `DROP TRIGGER`, `DROP TABLE AUDIT_LOG`, `DROP SEQUENCE SEQ_AUDIT_LOG`.

### Phần 5.1. Tạo `AUDIT_LOG`, `SEQ_AUDIT_LOG`, `TRG_AUDIT_LOG_AUTO_ID`

Chạy các block tạo bảng log, sequence và auto-id trigger cho bảng log.

Kiểm tra:

```sql
SELECT table_name
FROM user_tables
WHERE table_name = 'AUDIT_LOG';

SELECT sequence_name
FROM user_sequences
WHERE sequence_name = 'SEQ_AUDIT_LOG';

SELECT trigger_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_AUDIT_LOG_AUTO_ID';
```

### Phần 5.2. Tạo `TRG_VALIDATE_ORDER`

Chạy riêng block của trigger này.

Kiểm tra:

```sql
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_VALIDATE_ORDER';
```

Test nhanh:

```sql
INSERT INTO ORDERS (customer_id, total_amount, status, shipping_address, payment_method)
VALUES (1, 100000, 'PENDING', N'Quận 1, TP.HCM', 'COD');

ROLLBACK;
```

### Phần 5.3. Tạo `TRG_SYNC_ORDER_TOTAL`

Chạy riêng block compound trigger này.

Kiểm tra:

```sql
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_SYNC_ORDER_TOTAL';
```

Test nhanh:

```sql
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price)
VALUES (1, 2, 1, 85000);

COMMIT;

SELECT order_id, total_amount
FROM ORDERS
WHERE order_id = 1;
```

### Phần 5.4. Tạo `TRG_AUDIT_BOOKS`

Chạy riêng block của trigger này.

Kiểm tra:

```sql
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_AUDIT_BOOKS';
```

Test nhanh:

```sql
UPDATE BOOKS
SET price = price + 1000
WHERE book_id = 1;

COMMIT;

SELECT log_id, table_name, operation, record_id, column_changed
FROM AUDIT_LOG
ORDER BY log_id DESC;
```

### Phần 5.5. Kiểm tra tổng thể bước 5

```sql
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name IN (
    'TRG_AUDIT_LOG_AUTO_ID',
    'TRG_VALIDATE_ORDER',
    'TRG_SYNC_ORDER_TOTAL',
    'TRG_AUDIT_BOOKS'
)
ORDER BY trigger_name;

SELECT name, type, line, position, text
FROM user_errors
WHERE type = 'TRIGGER'
ORDER BY name, sequence;
```

---

## Bước 6. Chạy `6_views.sql` theo từng phần nhỏ

### Phần 6.0. Kiểm tra quyền materialized view

```sql
SELECT privilege
FROM user_sys_privs
WHERE privilege = 'CREATE MATERIALIZED VIEW';
```

Nếu không có kết quả thì chưa chạy phần materialized view.

### Phần 6.1. Dọn view cũ

Chạy block `DROP MATERIALIZED VIEW` và `DROP VIEW`.

### Phần 6.2. Tạo `VW_ORDER_REPORT`

Chạy riêng block tạo view này.

Kiểm tra:

```sql
SELECT view_name
FROM user_views
WHERE view_name = 'VW_ORDER_REPORT';

SELECT *
FROM VW_ORDER_REPORT
WHERE ROWNUM <= 10;
```

### Phần 6.3. Tạo `VW_CUSTOMER_SAFE`

Chạy riêng block tạo view này.

Kiểm tra:

```sql
SELECT view_name
FROM user_views
WHERE view_name = 'VW_CUSTOMER_SAFE';

SELECT *
FROM VW_CUSTOMER_SAFE
WHERE ROWNUM <= 10;
```

### Phần 6.4. Tạo `MV_BOOK_SALES_SUMMARY`

Chỉ chạy phần này khi đã có quyền `CREATE MATERIALIZED VIEW`.

Kiểm tra:

```sql
SELECT mview_name, staleness, compile_state
FROM user_mviews
WHERE mview_name = 'MV_BOOK_SALES_SUMMARY';

SELECT book_id, ten_sach, tong_sl_ban, tong_doanh_thu
FROM MV_BOOK_SALES_SUMMARY
ORDER BY book_id;
```

### Phần 6.5. Kiểm tra tổng thể bước 6

```sql
SELECT view_name
FROM user_views
WHERE view_name IN ('VW_ORDER_REPORT', 'VW_CUSTOMER_SAFE')
ORDER BY view_name;

SELECT mview_name
FROM user_mviews
WHERE mview_name = 'MV_BOOK_SALES_SUMMARY';
```

---

## Bước 7. Chạy `7_indexes_and_tuning.sql` theo từng phần nhỏ

### Phần 7.0. Dọn index cũ

Chạy cụm `DROP INDEX` ở đầu file.

### Phần 7.1. Tạo nhóm B-Tree index

Chạy các index sau:

1. `IDX_ORDERS_CUSTOMER_ID`
2. `IDX_ORDERS_ORDER_DATE`
3. `IDX_BOOKS_CATEGORY_ID`
4. `IDX_BOOKS_PUBLISHER_ID`
5. `IDX_OD_ORDER_ID`
6. `IDX_OD_BOOK_ID`
7. `IDX_REVIEWS_BOOK_ID`
8. `IDX_REVIEWS_CUSTOMER_ID`

Kiểm tra:

```sql
SELECT index_name, table_name, index_type, status
FROM user_indexes
WHERE index_name IN (
    'IDX_ORDERS_CUSTOMER_ID',
    'IDX_ORDERS_ORDER_DATE',
    'IDX_BOOKS_CATEGORY_ID',
    'IDX_BOOKS_PUBLISHER_ID',
    'IDX_OD_ORDER_ID',
    'IDX_OD_BOOK_ID',
    'IDX_REVIEWS_BOOK_ID',
    'IDX_REVIEWS_CUSTOMER_ID'
)
ORDER BY index_name;
```

### Phần 7.2. Tạo nhóm Bitmap index

Chạy:

1. `IDX_ORDERS_STATUS`
2. `IDX_BM_ORDERS_PAYMENT`

Kiểm tra:

```sql
SELECT index_name, table_name, index_type, status
FROM user_indexes
WHERE index_name IN ('IDX_ORDERS_STATUS', 'IDX_BM_ORDERS_PAYMENT')
ORDER BY index_name;
```

### Phần 7.3. Tạo function-based index

Chạy:

1. `IDX_BOOKS_TITLE_UPPER`

Kiểm tra:

```sql
SELECT index_name, table_name, index_type, status
FROM user_indexes
WHERE index_name = 'IDX_BOOKS_TITLE_UPPER';

SELECT index_name, column_expression
FROM user_ind_expressions
WHERE index_name = 'IDX_BOOKS_TITLE_UPPER';
```

### Phần 7.4. Chạy explain plan kiểm tra

```sql
EXPLAIN PLAN FOR
SELECT order_id, order_date, total_amount
FROM ORDERS
WHERE customer_id = 1;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);
```

---

## Bước 8. Chạy `8_security_roles.sql` theo từng phần nhỏ

### Phần 8.0. Kiểm tra trên user `DIGIBOOK`

```sql
SELECT privilege
FROM user_sys_privs
WHERE privilege IN ('CREATE USER', 'CREATE ROLE')
ORDER BY privilege;
```

Nếu không có kết quả thì dừng, chuyển sang connection `SYS AS SYSDBA` hoặc user DBA.

### Phần 8.1. Dọn role và user cũ bằng connection DBA

Chạy block đầu tiên dùng `DBA_USERS` và `DBA_ROLES`.

### Phần 8.2. Tạo 3 role

Chạy:

1. `CREATE ROLE DIGIBOOK_ADMIN`
2. `CREATE ROLE DIGIBOOK_STAFF`
3. `CREATE ROLE DIGIBOOK_GUEST`

Kiểm tra:

```sql
SELECT role
FROM dba_roles
WHERE role IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST')
ORDER BY role;
```

### Phần 8.3. Cấp quyền cho từng role

Chạy theo 3 block:

1. Block quyền cho `DIGIBOOK_ADMIN`
2. Block quyền cho `DIGIBOOK_STAFF`
3. Block quyền cho `DIGIBOOK_GUEST`

Kiểm tra:

```sql
SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE grantee IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST')
ORDER BY grantee, table_name, privilege;
```

### Phần 8.4. Tạo user và gán role

Chạy lần lượt:

1. `DB_ADMIN_USER`
2. `DB_STAFF_USER`
3. `DB_GUEST_USER`

Kiểm tra:

```sql
SELECT username
FROM dba_users
WHERE username IN ('DB_ADMIN_USER', 'DB_STAFF_USER', 'DB_GUEST_USER')
ORDER BY username;

SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN ('DB_ADMIN_USER', 'DB_STAFF_USER', 'DB_GUEST_USER')
ORDER BY grantee;
```

### Phần 8.5. Kiểm tra tổng thể bước 8

```sql
SELECT role
FROM dba_roles
WHERE role IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST')
ORDER BY role;

SELECT username
FROM dba_users
WHERE username IN ('DB_ADMIN_USER', 'DB_STAFF_USER', 'DB_GUEST_USER')
ORDER BY username;
```

---

## Bước 9. Chạy `9_transaction_demo.sql` theo từng phần nhỏ

Trước khi chạy:

```sql
SET SERVEROUTPUT ON;
```

### Phần 9.1. Chạy DEMO 1

Chạy riêng block `DEMO 1: Transaction liên hoàn — Đặt hàng đầy đủ`.

Kiểm tra:

```sql
SELECT order_id, customer_id, total_amount, status
FROM ORDERS
ORDER BY order_id DESC;

SELECT order_detail_id, order_id, book_id, quantity, unit_price
FROM ORDER_DETAILS
ORDER BY order_detail_id DESC;

SELECT book_id, title, stock_quantity
FROM BOOKS
WHERE book_id IN (3, 5)
ORDER BY book_id;
```

### Phần 9.2. Chạy DEMO 2

Chạy riêng block `DEMO 2: Transaction Serializable — Chuyển danh mục sách`.

Kiểm tra:

```sql
SELECT book_id, title, category_id
FROM BOOKS
WHERE book_id = 9;
```

Kỳ vọng: script có chuyển rồi khôi phục, nên cuối cùng `category_id` quay lại giá trị cũ.

### Phần 9.3. Chạy DEMO 3

Chạy riêng block `DEMO 3: Transaction thất bại — ROLLBACK toàn bộ`.

Kiểm tra:

```sql
SELECT book_id, stock_quantity
FROM BOOKS
WHERE book_id = 1;
```

Kỳ vọng: tồn kho không bị giảm sau rollback.

### Phần 9.4. Chạy DEMO 4

Chạy riêng block `DEMO 4: Mô phỏng xử lý Deadlock`.

Kiểm tra:

```sql
SELECT book_id, title, price
FROM BOOKS
WHERE book_id = 2;
```

### Phần 9.5. Kiểm tra tổng thể bước 9

```sql
SELECT order_id, customer_id, order_date, total_amount, status
FROM ORDERS
ORDER BY order_id DESC;

SELECT order_detail_id, order_id, book_id, quantity, unit_price, subtotal
FROM ORDER_DETAILS
ORDER BY order_detail_id DESC;
```

## 6. Cách xử lý lỗi thường gặp

### Lỗi ở bước 6

Nguyên nhân thường gặp:

- Thiếu quyền `CREATE MATERIALIZED VIEW`.

Kiểm tra:

```sql
SELECT privilege
FROM user_sys_privs
WHERE privilege = 'CREATE MATERIALIZED VIEW';
```

### Lỗi ở bước 8

Nguyên nhân thường gặp:

- User `DIGIBOOK` không có quyền `CREATE USER`, `CREATE ROLE`.
- User `DIGIBOOK` không được phép truy cập `DBA_USERS`, `DBA_ROLES`, `DBA_ROLE_PRIVS`.

Giải pháp:

- Chạy riêng file `8_security_roles.sql` bằng connection `SYS AS SYSDBA` hoặc user DBA.

### Lỗi do chạy sai chế độ

Nguyên nhân:

- Chạy bằng `Ctrl+Enter` thay vì `F5`.

Giải pháp:

- Đóng tab output cũ.
- Mở lại file.
- Chạy lại bằng `Run Script (F5)`.

## 7. Trình tự thực tế đề xuất cho bạn

Với connection hiện tại `DIGIBOOK`, bạn nên làm như sau:

1. Chạy lần lượt bước 2 đến bước 7 bằng user `DIGIBOOK`.
2. Nếu bước 6 lỗi, nhờ DBA cấp `CREATE MATERIALIZED VIEW` cho `DIGIBOOK`, rồi chạy lại bước 6.
3. Chạy bước 8 bằng `SYS AS SYSDBA` hoặc user có quyền DBA.
4. Quay lại user `DIGIBOOK` để chạy bước 9.
5. Sau mỗi bước, chạy ngay nhóm lệnh kiểm tra tương ứng trong tài liệu này.

## 8. Kiểm tra tổng thể sau khi hoàn tất

Sau khi triển khai xong, có thể chạy bộ kiểm tra tổng hợp sau:

```sql
SELECT COUNT(*) AS total_tables
FROM user_tables;

SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
WHERE object_type IN ('TABLE', 'SEQUENCE', 'TRIGGER', 'PROCEDURE', 'VIEW', 'MATERIALIZED VIEW', 'INDEX')
GROUP BY object_type
ORDER BY object_type;

SELECT 'CUSTOMERS' AS table_name, COUNT(*) AS total_rows FROM CUSTOMERS
UNION ALL
SELECT 'BOOKS', COUNT(*) FROM BOOKS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_DETAILS', COUNT(*) FROM ORDER_DETAILS
UNION ALL
SELECT 'REVIEWS', COUNT(*) FROM REVIEWS;
```

Nếu cần nộp báo cáo, bạn có thể chụp màn hình:

- `Script Output` sau mỗi bước
- Kết quả `SELECT` kiểm tra
- Danh sách object trong `Connections -> Tables / Views / Procedures / Triggers / Indexes`