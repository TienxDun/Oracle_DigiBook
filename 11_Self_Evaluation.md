# 11_SELF_EVALUATION - KIỂM TRA TÍNH NHẤT QUÁN (ORACLE DIGIBOOK)

## 1. Phạm vi rà soát

Đã rà soát các đầu ra chính từ Bước 1 đến Bước 10:

- 1_Database_Design.md
- 2_create_tables.sql
- 3_insert_data.sql
- 4_procedures.sql
- 5_triggers.sql
- 6_views.sql
- 7_indexes_and_tuning.sql
- 8_security_roles.sql
- 9_transaction_demo.sql
- 10_Final_Report.md

## 2. Kết quả đối soát tính nhất quán

### 2.1. Thiết kế ERD và DDL (Bước 1 vs Bước 2)

- Số lượng thực thể cốt lõi khớp nhau (15 bảng): CUSTOMERS, CATEGORIES, CARTS, CART_ITEMS, AUTHORS, PUBLISHERS, COUPONS, BOOKS, BOOK_IMAGES, BOOK_AUTHORS, ORDERS, ORDER_DETAILS, ORDER_STATUS_HISTORY, REVIEWS, INVENTORY_TRANSACTIONS.
- Tên bảng, tên cột chính và quan hệ FK trong ERD khớp với script tạo bảng.
- Các ràng buộc quan trọng được phản ánh đúng:
  - UNIQUE: email customer, coupon_code, isbn, (order_id, book_id) trong ORDER_DETAILS/REVIEWS.
  - CHECK: status, payment_status, rating, quantity, price, stock, discount logic.
  - FK kép REVIEWS(order_id, book_id) -> ORDER_DETAILS(order_id, book_id) đúng với thiết kế.
- Có sequence + trigger sinh PK cho các bảng PK NUMBER, phù hợp yêu cầu Oracle 19c.

### 2.2. DML và ràng buộc (Bước 3 vs Bước 2)

- Dữ liệu mẫu đã insert vào đúng các bảng được tạo.
- Tổng số bản ghi mẫu > 100, đáp ứng yêu cầu bài toán.
- Khóa ngoại và ràng buộc hình thức nhìn chung được tôn trọng (dữ liệu tham chiếu tồn tại, giá trị rating/status nằm trong miền hợp lệ).
- Có đồng bộ sequence sau khi insert tay, hạn chế xung đột PK ở các lần insert tiếp theo.

### 2.3. Stored procedures/Triggers/Views trên đúng lược đồ (Bước 4-6)

- Procedures thao tác trên các bảng tồn tại và đúng nghiệp vụ:
  - sp_manage_book: BOOKS + bảng phụ thuộc liên quan.
  - sp_report_monthly_sales: ORDERS.
  - sp_print_low_stock_books: BOOKS/CATEGORIES/PUBLISHERS.
  - sp_calculate_coupon_discount: COUPONS.
- Triggers đúng đối tượng:
  - Validation trên ORDERS.
  - Compound trigger recalc tổng tiền từ ORDER_DETAILS -> ORDERS.
  - Audit log tác động trên ORDERS.
- Views/materialized view JOIN đúng các bảng đã tạo, phục vụ báo cáo và bảo mật dữ liệu.

### 2.4. Index và truy vấn thực tế (Bước 7)

- Các index đặt trên cột phù hợp với truy vấn mô phỏng:
  - Đơn gần nhất: ORDERS(order_date, order_id).
  - Low stock: BOOKS(stock_quantity, book_id).
  - Báo cáo theo ngày: function-based index TRUNC(order_date).
  - Lọc danh mục: bitmap index BOOKS(category_id).
- Có đối chiếu EXPLAIN PLAN before/after, đúng hướng tối ưu đề bài.

### 2.5. Phân quyền và bảo mật (Bước 8)

- Đã tạo 3 role (ADMIN_ROLE, STAFF_ROLE, GUEST_ROLE) và 3 user tương ứng.
- Quyền trên TABLE/VIEW/PROCEDURE được phân tách theo vai trò.
- Có xử lý bối cảnh PDB và auto-detect schema (APP_SCHEMA=AUTO), phù hợp vận hành Oracle 19c.

### 2.6. Transaction và concurrency (Bước 9)

- Có khối BEGIN...EXCEPTION...COMMIT/ROLLBACK đầy đủ.
- Có khai báo isolation level (SERIALIZABLE) và khóa dòng FOR UPDATE WAIT 5 để giảm race condition.
- Có cập nhật đồng bộ ORDERS, ORDER_DETAILS, BOOKS, INVENTORY_TRANSACTIONS, ORDER_STATUS_HISTORY trong cùng transaction.

### 2.7. Báo cáo tổng hợp (Bước 10)

- Nội dung tổng hợp phù hợp chuỗi script và thứ tự chạy.
- Bảng phân công và tiến độ khớp với nhóm công việc đã trình bày từ các bước trước.

## 3. Điểm chưa nhất quán phát hiện

### [Mức độ: Trung bình] Tổng tiền mẫu trong ORDERS chưa đồng bộ tuyệt đối với ORDER_DETAILS

- Trong 3_insert_data.sql, giá trị ORDERS.total_amount được nhập sẵn trước khi có trigger recalc (trigger tạo ở Bước 5).
- Một số đơn có thể không khớp công thức:
  total_amount = SUM(order_details.quantity * order_details.unit_price) + shipping_fee - discount_amount.
- Hệ quả:
  - Báo cáo doanh thu có thể sai số nhẹ nếu dùng trực tiếp total_amount.
  - View/report so sánh theo dòng chi tiết và tổng đơn có thể lệch.

## 4. Đề xuất khắc phục

Thực hiện 1 lần đồng bộ lại tổng tiền sau khi nạp dữ liệu mẫu (hoặc sau khi tạo trigger):

```sql
UPDATE orders o
SET o.total_amount = (
    SELECT GREATEST(
        NVL(SUM(od.quantity * od.unit_price), 0)
        + NVL(o.shipping_fee, 0)
        - NVL(o.discount_amount, 0),
        0
    )
    FROM order_details od
    WHERE od.order_id = o.order_id
);

COMMIT;
```

Khuyến nghị bổ sung script nhỏ sau Bước 3 hoặc sau Bước 5 (ví dụ: 3.1_reconcile_order_totals.sql) để đảm bảo dữ liệu mẫu luôn nhất quán.

## 5. Kết luận self-evaluation

- Đánh giá tổng thể: Hệ thống đạt mức đồng bộ tốt giữa thiết kế, DDL, PL/SQL, views, indexes, security và transaction theo đúng hướng Oracle 19c.
- Có 1 điểm cần chốt lại để đạt tính nhất quán nghiệp vụ cao hơn: đồng bộ total_amount của đơn hàng với chi tiết đơn hàng.
- Sau khi áp dụng đề xuất mục 4, bộ tài liệu và script có thể xem là đồng bộ và nhất quán cho nộp đồ án.
