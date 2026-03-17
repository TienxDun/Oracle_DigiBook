# 10_FINAL_REPORT - ORACLE DIGIBOOK (ORACLE 19c)

## 1. Thông tin chung

- Đề tài: Thiết kế cơ sở dữ liệu website bán sách DigiBook.
- Hệ quản trị: Oracle Database 19c.
- Mô hình triển khai: Oracle DB + Web UI (Node.js/Express + Vanilla JS).
- Nhóm thực hiện: Dũng, Nam, Hiếu, Phát (AI tổng hợp và đồng bộ đầu ra).
- Mục tiêu báo cáo: Tổng kết toàn bộ kết quả từ Bước 1 đến Bước 9, hướng dẫn chạy file SQL, đối soát tiến độ và phân công công việc.

---

## 2. Tóm tắt cấu trúc dự án

### 2.1. Nhóm file SQL theo chức năng

- `0_drop_digibook.sql`: dọn dẹp schema để reset môi trường.
- `0.1_list_digibook_objects.sql`: liệt kê object trong schema.
- `2_create_tables.sql`: tạo bảng, PK/FK, CHECK/UNIQUE, sequence, trigger sinh PK.
- `3_insert_data.sql`: nạp dữ liệu mẫu.
- `4_procedures.sql`: stored procedures nghiệp vụ.
- `5_triggers.sql`: trigger validation, recalc tổng tiền, audit log.
- `6_views.sql`: views báo cáo + view bảo mật + materialized view.
- `7_indexes_and_tuning.sql`: tạo index và explain plan trước/sau.
- `8_security_roles.sql`: role/user và cấp quyền theo RBAC.
- `9_transaction_demo.sql`: transaction demo có isolation level + rollback/commit.

### 2.2. Nhóm file test và giải thích

- `4.1_procedures_test.sql`, `5.1_triggers_test.sql`, `6.1_views_test.sql`, `7.1_indexes_and_tuning_test.sql`, `8.1_security_roles_test.sql`.
- `4.2_procedures_explain.md`, `5.2_triggers_explain.md`, `6.2_views_explain.md`, `7.2_indexes_and_tuning_explain.md`, `8.2_security_roles_explain.md`.

### 2.3. Nhóm ứng dụng web

- Thư mục `web-ui/` gồm API backend (`src/server.js`, `src/db.js`) và frontend (`public/`).
- Chức năng chính: dashboard, tìm kiếm sách, xem bảng dữ liệu, endpoint health/runtime.

---

## 3. Hướng dẫn chuẩn bị môi trường

### 3.1. Database

- Sử dụng Oracle 19c (ưu tiên PDB: `ORCLPDB` hoặc `ORCLPDB1`).
- Tạo schema ứng dụng (ví dụ `DIGIBOOK`) và cấp quyền tạo object cần thiết.

### 3.2. Chạy script SQL

Có thể chạy bằng SQL Developer hoặc SQL*Plus/SQLcl.

Ví dụ SQL*Plus:

```sql
CONNECT DIGIBOOK/<password>@localhost:1521/orclpdb
@2_create_tables.sql
@3_insert_data.sql
```

---

## 4. Runbook chạy từng file SQL

Bảng sau mô tả thứ tự chạy khuyến nghị, mục tiêu và kết quả mong đợi.

| Thứ tự | File | Mục đích | Kết quả mong đợi |
| --- | --- | --- | --- |
| 0 (tùy chọn) | `0_drop_digibook.sql` | Xóa toàn bộ object hiện có để reset | Schema sạch, sẵn sàng tạo lại |
| 0.1 (tùy chọn) | `0.1_list_digibook_objects.sql` | Kiểm tra object hiện tại | Danh sách object theo từng loại |
| 1 | `2_create_tables.sql` | Tạo schema đầy đủ | 15 bảng + constraints + sequence + trigger PK |
| 2 | `3_insert_data.sql` | Nạp dữ liệu mẫu nghiệp vụ | Dữ liệu mẫu đầy đủ, đạt yêu cầu > 100 bản ghi |
| 3 | `4_procedures.sql` | Tạo stored procedures | 4 procedure tạo thành công |
| 3.1 (kiểm thử) | `4.1_procedures_test.sql` | Test procedure | Có testcase thành công và testcase fail kỳ vọng |
| 4 | `5_triggers.sql` | Tạo trigger nghiệp vụ | 3 trigger chính + đối tượng hỗ trợ audit |
| 4.1 (kiểm thử) | `5.1_triggers_test.sql` | Test trigger | Trigger validation/recalc/audit hoạt động đúng |
| 5 | `6_views.sql` | Tạo view và materialized view | 2 view + 1 materialized view tạo thành công |
| 5.1 (kiểm thử) | `6.1_views_test.sql` | Test view | JOIN view, secure view, mview trả dữ liệu đúng |
| 6 | `7_indexes_and_tuning.sql` | Tạo index + explain plan | 4 index theo thiết kế và plan before/after |
| 6.1 (kiểm thử) | `7.1_indexes_and_tuning_test.sql` | Test index | Kiểm tra tồn tại, loại index, cột, plan sử dụng index |
| 7 | `8_security_roles.sql` | Tạo role/user và cấp quyền | 3 role + 3 user + grant theo vai trò |
| 7.1 (kiểm thử) | `8.1_security_roles_test.sql` | Test phân quyền | Xác nhận role/user/privilege đã cấp |
| 8 | `9_transaction_demo.sql` | Demo transaction và concurrency | Tạo đơn, trừ kho, ghi inventory, commit/rollback đúng logic |

Ghi chú quan trọng:

- Khi chạy `8_security_roles.sql`, nên dùng tài khoản có quyền tạo user/role và cấp quyền object.
- `9_transaction_demo.sql` đã bổ sung `ROLLBACK;` trước `SET TRANSACTION` để tránh lỗi `ORA-01453` trong session còn transaction tồn đọng.

---

## 5. Phân tích kết quả theo từng bước

### 5.1. Bước 1 - Thiết kế CSDL

- Mô hình dữ liệu theo hướng 3NF, bao phủ nghiệp vụ bán sách online.
- Hệ thống xác định nhiều thực thể cốt lõi: khách hàng, sách, tác giả, đơn hàng, chi tiết đơn, kho, đánh giá, mã giảm giá.
- ERD và mô tả PK/FK/ràng buộc được trình bày trong tài liệu thiết kế.

### 5.2. Bước 2 - DDL

- Tạo đầy đủ bảng và ràng buộc Oracle 19c.
- Sử dụng sequence + trigger để tự động sinh PK cho các bảng số.
- Bộ ràng buộc CK/UNIQUE/FK giúp bảo vệ toàn vẹn dữ liệu tại tầng CSDL.

### 5.3. Bước 3 - DML

- Dữ liệu mẫu đã được nạp theo tình huống nghiệp vụ thực tế.
- Tổng số dữ liệu vượt ngưỡng yêu cầu tối thiểu 100 bản ghi.
- Dữ liệu khớp với ràng buộc khóa và business rules đã khai báo.

### 5.4. Bước 4 - Stored Procedures

Đã triển khai 4 procedure:

- `sp_manage_book`: thêm/sửa/xóa sách có kiểm tra exception và ràng buộc.
- `sp_report_monthly_sales`: báo cáo tổng hợp theo tháng qua `SYS_REFCURSOR`.
- `sp_print_low_stock_books`: sử dụng cursor để in danh sách sắp hết hàng.
- `sp_calculate_coupon_discount`: tính discount theo logic hiệu lực coupon.

Giá trị đạt được:

- Đồng bộ business rule tại DB layer.
- Có script test riêng cho happy path và expected fail.

### 5.5. Bước 5 - Triggers

Đã triển khai 3 trigger chuyên sâu:

- Validation `BEFORE INSERT/UPDATE` trên `orders`.
- Compound trigger đồng bộ `orders.total_amount` từ `order_details` (tránh mutating table).
- Audit trigger lưu vết thao tác trên `orders` vào `orders_audit_log`.

Giá trị đạt được:

- Dữ liệu được kiểm soát chặt ngay tại điểm ghi.
- Tăng khả năng truy vết và đối soát nghiệp vụ.

### 5.6. Bước 6 - Views

Đã triển khai:

- `vw_order_sales_report`: JOIN nhiều bảng để phục vụ báo cáo.
- `vw_customer_secure_profile`: masking dữ liệu nhạy cảm + `WITH READ ONLY`.
- `mv_daily_category_sales`: materialized view tổng hợp doanh thu theo ngày/danh mục.

Giá trị đạt được:

- Đơn giản hóa truy vấn báo cáo.
- Nâng cao bảo mật dữ liệu khách hàng.
- Cải thiện tốc độ truy vấn tổng hợp (qua mview).

### 5.7. Bước 7 - Indexing và Tuning

Đã tạo bộ index theo đúng use case:

- B-Tree cho truy vấn đơn gần nhất.
- B-Tree cho bài toán low-stock.
- Function-based index cho `TRUNC(order_date)`.
- Bitmap index cho truy vấn theo category.

Giá trị đạt được:

- Có đối chiếu plan trước/sau bằng `EXPLAIN PLAN` + `DBMS_XPLAN`.
- Có script test đánh giá tồn tại index, loại index, cột index và plan sử dụng index.

### 5.8. Bước 8 - Security Roles

Đã triển khai mô hình RBAC:

- Role: `ADMIN_ROLE`, `STAFF_ROLE`, `GUEST_ROLE`.
- User: `DIGIBOOK_ADMIN`, `DIGIBOOK_STAFF`, `DIGIBOOK_GUEST`.
- Cấp quyền theo nhóm đối tượng: bảng, view/mview, procedure.
- Có cơ chế auto-detect schema và xử lý bối cảnh PDB.

Giá trị đạt được:

- Tách quyền theo vai trò để giảm rủi ro cấp quyền tràn lan.
- Hỗ trợ vận hành và bảo mật tốt hơn trong môi trường Oracle 19c.

### 5.9. Bước 9 - Transaction và Concurrency

Script `9_transaction_demo.sql` mô phỏng transaction thực tế:

- Đặt isolation level (`SERIALIZABLE`).
- Khóa dòng sách (`FOR UPDATE WAIT 5`) để tránh race condition.
- Tạo đơn + thêm chi tiết + trừ kho + ghi inventory + cập nhật trạng thái + ghi lịch sử.
- Có `EXCEPTION` xử lý `NO_DATA_FOUND`, thiếu tồn, resource busy, lỗi tổng quát.
- `COMMIT` khi thành công, `ROLLBACK` khi thất bại.

Kết quả chạy thực tế ghi nhận:

- Đơn hàng tạo thành công.
- Tồn kho giảm đúng theo số lượng mua.
- Đã xử lý fix lỗi `ORA-01453` bằng cách reset transaction tồn đọng trước khi `SET TRANSACTION`.

---

## 6. Bảng phân công công việc và tiến độ

| Thành viên | Hạng mục chính phụ trách | Đầu ra tiêu biểu | Tiến độ |
| --- | --- | --- | --- |
| Dũng | Thiết kế cốt lõi, validation, view báo cáo, index recent orders | ERD/thực thể cốt lõi, trigger validate orders, `vw_order_sales_report`, `idx_orders_recent_date` | Hoàn thành |
| Nam | Báo cáo tổng hợp, đồng bộ tổng tiền, secure view, index low-stock, phân quyền vận hành | `sp_report_monthly_sales`, compound trigger recalc order, `vw_customer_secure_profile`, `idx_books_low_stock` | Hoàn thành |
| Hiếu | Xử lý cursor, audit, materialized view, function-based/bitmap index | `sp_print_low_stock_books`, trigger audit, `mv_daily_category_sales`, `idx_orders_trunc_order_date`, `idx_books_category_bm` | Hoàn thành |
| Phát | Nghiệp vụ bổ trợ, giao dịch đơn hàng, bảo mật role-user, transaction demo | `sp_calculate_coupon_discount`, `8_security_roles.sql`, `9_transaction_demo.sql` | Hoàn thành |

Nhận xét tiến độ:

- Các hạng mục chính đã được triển khai đầy đủ theo chuỗi từ thiết kế đến vận hành.
- Mỗi bước quan trọng đều có script test/giải thích kèm theo, phù hợp yêu cầu báo cáo đồ án.

---

## 7. Hướng dẫn chạy nhanh toàn bộ dự án

### 7.1. Chạy Database scripts (đề nghị)

```sql
-- (Tùy chọn) reset
@0_drop_digibook.sql

-- Khởi tạo dữ liệu
@2_create_tables.sql
@3_insert_data.sql

-- Nghiệp vụ nâng cao
@4_procedures.sql
@5_triggers.sql
@6_views.sql
@7_indexes_and_tuning.sql
@8_security_roles.sql
@9_transaction_demo.sql

-- Test
@4.1_procedures_test.sql
@5.1_triggers_test.sql
@6.1_views_test.sql
@7.1_indexes_and_tuning_test.sql
@8.1_security_roles_test.sql
```

### 7.2. Chạy Web UI

```bash
cd web-ui
copy .env.example .env
npm install
npm start
```

Nếu cổng `PORT` bận, ứng dụng tự động tăng cổng tiếp theo. Kiểm tra URL thực tế qua log startup hoặc endpoint `/api/runtime`.

---

## 8. Kết luận

DigiBook đã hoàn thành chuỗi triển khai CSDL Oracle 19c theo hướng end-to-end:

- Có mô hình dữ liệu và ràng buộc rõ ràng.
- Có dữ liệu mẫu để demo nghiệp vụ.
- Có tầng xử lý nghiệp vụ (procedure/trigger/view/index/security/transaction).
- Có script kiểm thử và tài liệu giải thích cho từng nhóm chức năng.
- Có thể mở rộng tiếp cho bước báo cáo nâng cao, monitoring và hardening bảo mật trong giai đoạn tiếp theo.
