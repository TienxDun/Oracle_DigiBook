# BÁO CÁO ĐỀ TÀI: HỆ THỐNG QUẢN LÝ BÁN SÁCH DIGIBOOK TRÊN ORACLE 19c

> Tài liệu này được viết theo dạng **Markdown** để có thể copy sang Word và định dạng lại theo yêu cầu (Times New Roman 13, dãn dòng 1.5, lề…).  
> Phần “Runbook chạy script” và checklist kỹ thuật được đưa vào **Phụ lục**.

---

## TRANG BÌA (mẫu điền)

- **Trường/Khoa**: ............................................................
- **Môn học**: Các hệ quản trị cơ sở dữ liệu
- **Đề tài**: Hệ thống quản lý bán sách DigiBook trên Oracle 19c
- **Nhóm thực hiện**: Dũng – Nam – Hiếu – Phát
- **Giảng viên hướng dẫn**: ...................................................
- **Lớp**: ............................................................
- **Năm học**: 2025–2026

---

## TRANG PHỤ BÌA (mẫu điền)

- **Tóm tắt**: Đề tài xây dựng cơ sở dữ liệu cho hệ thống bán sách DigiBook trên Oracle 19c, gồm thiết kế ERD/3NF, triển khai DDL/DML, thủ tục PL/SQL, trigger nghiệp vụ/audit, view & materialized view, tối ưu chỉ mục, phân quyền RBAC, và mô phỏng giao tác & đồng thời.
- **Từ khóa**: Oracle 19c, PL/SQL, trigger, view, materialized view, RBAC, transaction, concurrency, indexing.

---

## MỤC LỤC (gợi ý)

1. Lời mở đầu  
2. Chương 1: Khảo sát hiện trạng và xác định yêu cầu  
3. Chương 2: Cơ sở lý thuyết (liên hệ đề tài)  
4. Chương 3: Phân tích hệ thống  
5. Chương 4: Thiết kế và cài đặt hệ thống  
6. Kết luận  
7. Tài liệu tham khảo  
8. Phụ lục  

---

## LỜI MỞ ĐẦU

### Mục tiêu đề tài

Đề tài “DigiBook” nhằm xây dựng một cơ sở dữ liệu phục vụ nghiệp vụ bán sách trực tuyến: quản lý danh mục – sách – khách hàng – giỏ hàng – đơn hàng – chi tiết đơn – trạng thái đơn – khuyến mãi – kho – đánh giá, đồng thời có khả năng báo cáo và phân quyền vận hành.

### Ý nghĩa thực tiễn

Trong bối cảnh thương mại điện tử phát triển, dữ liệu đơn hàng, kho, khách hàng và báo cáo doanh thu là tài sản quan trọng. Một thiết kế CSDL tốt giúp:

- đảm bảo **toàn vẹn dữ liệu** (khóa, ràng buộc, kiểm tra nghiệp vụ),
- hỗ trợ **vận hành** (phân quyền theo vai trò),
- và tạo nền tảng **mở rộng** (tối ưu truy vấn, vật hóa dữ liệu tổng hợp, xử lý giao tác).

### Đối tượng sử dụng

- Người quản trị hệ thống/DBA (quản lý schema, quyền, tối ưu).
- Nhân viên vận hành (cập nhật sách, theo dõi đơn).
- Bộ phận hỗ trợ (tra cứu thông tin đã che dữ liệu nhạy cảm).

---

## CHƯƠNG 1: KHẢO SÁT HIỆN TRẠNG VÀ XÁC ĐỊNH YÊU CẦU

### 1.1. Khảo sát hiện trạng

Mô hình minh họa DigiBook giả lập như một website bán sách:

- **Dữ liệu sản phẩm**: danh mục, sách, ảnh sách, tác giả, nhà xuất bản.
- **Dữ liệu giao dịch**: khách hàng, giỏ hàng, đơn hàng, chi tiết đơn, lịch sử trạng thái.
- **Dữ liệu vận hành**: giao dịch kho (nhập/xuất), đánh giá (chỉ sau khi mua), khuyến mãi (coupon).

Hạn chế thường gặp khi quản lý thủ công hoặc thiết kế kém:

- Trùng lặp dữ liệu (không chuẩn hóa).
- Sai lệch tổng tiền – chi tiết đơn.
- Khó truy vết lịch sử và tranh chấp (không có audit).
- Phân quyền lỏng lẻo (ai cũng thấy dữ liệu nhạy cảm).

### 1.2. Nội dung cần giải quyết

- **Phạm vi hệ thống**: triển khai CSDL Oracle 19c cho nghiệp vụ bán sách end-to-end; có runbook chạy script từ đầu.
- **Chứng từ/báo cáo**:
  - báo cáo doanh thu theo tháng,
  - báo cáo bán hàng theo dòng đơn,
  - tổng hợp doanh thu theo ngày & danh mục (dashboard).
- **Yêu cầu kỹ thuật**:
  - Toàn vẹn: PK/FK/UNIQUE/CHECK + trigger kiểm tra nghiệp vụ.
  - Bảo mật: role/user, phân quyền SELECT/DML/EXECUTE theo vai trò.
  - Hiệu năng: index theo use-case + explain plan.
  - Giao tác & đồng thời: minh họa COMMIT/ROLLBACK, mức cô lập, khóa dòng.

### 1.3. Lý do chọn Oracle 19c

Oracle 19c là phiên bản LTS phổ biến trong doanh nghiệp, hỗ trợ mạnh:

- PL/SQL cho nghiệp vụ tại tầng DB.
- Read consistency và locking phù hợp xử lý đồng thời.
- View/materialized view cho reporting.
- Quản trị user/role/profile theo tiêu chuẩn enterprise.

---

## CHƯƠNG 2: CƠ SỞ LÝ THUYẾT (LIÊN HỆ ĐỀ TÀI)

### 2.1. Kiến trúc Oracle 19c (Instance/Database/PDB)

Hệ thống có thể được triển khai trong môi trường Oracle 19c dạng CDB/PDB. Khi tạo user/schema ứng dụng, cần đảm bảo **kết nối đúng PDB** (ví dụ `orclpdb`) hoặc `ALTER SESSION SET CONTAINER = ORCLPDB` để tạo local user.

### 2.2. Quản trị User, Role, Profile trong Oracle 19c

Phân quyền theo RBAC giúp giảm rủi ro lộ dữ liệu và thao tác sai. Trong đề tài:

- tạo `ADMIN_ROLE`, `STAFF_ROLE`, `GUEST_ROLE`,
- tạo user tương ứng và cấp quyền theo bảng/view/procedure.

### 2.3. Ngôn ngữ PL/SQL

PL/SQL được dùng để:

- viết procedure nghiệp vụ (CRUD có kiểm tra, báo cáo ref cursor, cursor in DBMS_OUTPUT),
- viết trigger nghiệp vụ (validation, audit, compound trigger tránh mutating table),
- xử lý exception và đảm bảo transaction đúng.

### 2.4. Sao lưu và phục hồi (khái quát)

Trong bối cảnh đồ án, nội dung backup/restore được trình bày ở mức khái quát (RMAN, archived redo log). Khi triển khai thực tế cần xây dựng quy trình sao lưu định kỳ và kiểm thử restore.

### 2.5. Quản lý giao tác

Giao tác đảm bảo tính nhất quán khi thao tác nhiều bảng (đơn hàng – chi tiết – kho – lịch sử). Đề tài minh họa:

- `COMMIT`, `ROLLBACK`,
- đặt isolation level (SERIALIZABLE),
- khóa dòng `FOR UPDATE WAIT` khi trừ kho.

### 2.6. Xử lý đồng thời và read consistency trong Oracle

Oracle áp dụng **read consistency**; dirty read không xảy ra như một isolation riêng biệt. Đồng thời vẫn cần xử lý lost update/lock contention bằng chiến lược khóa hợp lý (khóa dòng sách khi trừ kho).

---

## CHƯƠNG 3: PHÂN TÍCH HỆ THỐNG

### 3.1. Phân tích chức năng (mô tả BFD mức khái quát)

- Quản lý danh mục & sách (thêm/sửa/xóa, ảnh, tác giả, NXB).
- Quản lý khách hàng và giỏ hàng.
- Lập đơn hàng, theo dõi trạng thái, lịch sử trạng thái.
- Quản lý kho theo giao dịch (IN/OUT/ADJUST).
- Báo cáo doanh thu và thống kê bán hàng.
- Phân quyền theo vai trò vận hành.

### 3.2. Phân tích dữ liệu (tổng quan ERD)

CSDL gồm **15 bảng nghiệp vụ lõi** và thêm bảng vận hành audit:

- Lõi: `CUSTOMERS`, `CATEGORIES`, `CARTS`, `CART_ITEMS`, `AUTHORS`, `PUBLISHERS`, `COUPONS`, `BOOKS`, `BOOK_IMAGES`, `BOOK_AUTHORS`, `ORDERS`, `ORDER_DETAILS`, `ORDER_STATUS_HISTORY`, `REVIEWS`, `INVENTORY_TRANSACTIONS`.
- Vận hành: `ORDERS_AUDIT_LOG` (tạo bởi trigger audit).

ERD chi tiết và giải trình chuẩn hóa 3NF được trình bày trong `1_Database_Design.md`.

---

## CHƯƠNG 4: THIẾT KẾ VÀ CÀI ĐẶT HỆ THỐNG

### 4.1. Mô hình dữ liệu quan hệ

Thiết kế quan hệ dựa trên ERD và chuẩn hóa 3NF:

- Quan hệ 1:N: khách hàng–đơn hàng, đơn hàng–chi tiết, sách–ảnh, sách–giao dịch kho, …
- Quan hệ N:N: sách–tác giả thông qua bảng nối `BOOK_AUTHORS`.
- Ràng buộc nghiệp vụ bắt buộc:
  - `REVIEWS(order_id, book_id)` tham chiếu `ORDER_DETAILS(order_id, book_id)` để đảm bảo “chỉ mua mới được review”.
  - `BOOK_IMAGES`: mỗi sách chỉ có tối đa 1 ảnh chính (`is_primary=1`) bằng unique function-based index.

### 4.2. Từ điển dữ liệu (tóm tắt)

Phần mô tả chi tiết cột/PK/FK/CHECK/UNIQUE theo từng bảng đã được trình bày ở `1_Database_Design.md` (mục 3). Tại đây tóm tắt các nhóm dữ liệu:

- Nhóm khách hàng & giỏ: `CUSTOMERS`, `CARTS`, `CART_ITEMS`
- Nhóm danh mục & sản phẩm: `CATEGORIES`, `BOOKS`, `BOOK_IMAGES`, `AUTHORS`, `PUBLISHERS`, `BOOK_AUTHORS`
- Nhóm giao dịch: `ORDERS`, `ORDER_DETAILS`, `ORDER_STATUS_HISTORY`, `COUPONS`, `REVIEWS`
- Nhóm kho: `INVENTORY_TRANSACTIONS`

### 4.3. Thiết kế và cài đặt trên Oracle 19c (script)

Các script triển khai theo thứ tự:

- DDL tạo bảng/ràng buộc/sequence/trigger PK: `2_create_tables.sql`
- DML dữ liệu mẫu (>= 100): `3_insert_data.sql`
- Stored procedures: `4_procedures.sql`
- Triggers nghiệp vụ & audit: `5_triggers.sql`
- Views & materialized view: `6_views.sql`
- Indexing + EXPLAIN PLAN: `7_indexes_and_tuning.sql`
- Security roles/users: `8_security_roles.sql`
- Transaction & concurrency demo: `9_transaction_demo.sql`

Ngoài ra có script tổng chạy all-in-one: `1_run_all_main.sql`.

### 4.4. Procedure/Function nghiệp vụ (tóm tắt)

- `sp_manage_book`: quản lý sách (ADD/UPDATE/DELETE), kiểm tra khóa ngoại và ràng buộc nghiệp vụ.
- `sp_report_monthly_sales`: báo cáo doanh thu theo tháng qua `SYS_REFCURSOR`.
- `sp_print_low_stock_books`: cursor in danh sách sách sắp hết hàng.
- `sp_calculate_coupon_discount`: tính giảm giá theo coupon và điều kiện hiệu lực.

### 4.5. Trigger nghiệp vụ (tóm tắt)

- Validation `BEFORE INSERT/UPDATE` trên `ORDERS`.
- Compound trigger trên `ORDER_DETAILS` để tính lại `ORDERS.total_amount` (tránh mutating table).
- Audit trigger ghi log thao tác trên `ORDERS` vào `ORDERS_AUDIT_LOG`.

### 4.6. View / Materialized View (tóm tắt)

- `vw_order_sales_report`: view JOIN nhiều bảng phục vụ báo cáo bán hàng chi tiết.
- `vw_customer_secure_profile`: view che dữ liệu nhạy cảm, `WITH READ ONLY`.
- `mv_daily_category_sales`: materialized view tổng hợp theo ngày & danh mục, refresh on demand.

### 4.7. Indexing và tuning (tóm tắt)

Các index được tạo theo use-case và kèm explain plan before/after:

- `IDX_ORDERS_RECENT_DATE` (B-Tree): hỗ trợ dashboard “đơn gần nhất”.
- `IDX_BOOKS_LOW_STOCK` (B-Tree): lọc tồn kho thấp.
- `IDX_ORDERS_TRUNC_ORDER_DATE` (function-based): báo cáo theo ngày với `TRUNC(order_date)`.
- `IDX_BOOKS_CATEGORY_BM` (bitmap): lọc/nhóm theo danh mục có cardinality thấp.

### 4.8. Phân quyền và bảo mật (RBAC)

Áp dụng RBAC theo vai trò:

- **Admin**: toàn quyền DML và xem report.
- **Staff**: quyền tác nghiệp (cập nhật sách/đơn theo phạm vi).
- **Guest**: chỉ được xem dữ liệu công khai (sách/danh mục/tác giả/NXB).

Script triển khai: `8_security_roles.sql` (có xử lý bối cảnh PDB và auto-detect schema).

### 4.9. Transaction & concurrency demo

Script `9_transaction_demo.sql` mô phỏng nghiệp vụ “tạo đơn – trừ kho – ghi giao dịch kho – cập nhật trạng thái – ghi lịch sử” trong một transaction:

- isolation: `SERIALIZABLE`,
- khóa dòng sách: `FOR UPDATE WAIT 5`,
- lỗi được xử lý bằng exception + rollback để đảm bảo toàn vẹn.

---

## KẾT LUẬN

### Kết quả đạt được

- Hoàn thiện thiết kế CSDL DigiBook theo hướng 3NF, đầy đủ thực thể và quan hệ.
- Triển khai end-to-end trên Oracle 19c: DDL/DML, procedure, trigger, view/mview, index, security, transaction demo.
- Có runbook chạy script và file test cho các nhóm chức năng.

### Hạn chế

- Dữ liệu mẫu có thể cần **đối soát lại `ORDERS.total_amount`** theo công thức từ `ORDER_DETAILS` sau khi tạo trigger recalc (đã nêu trong `11_Self_Evaluation.md`).
- Các sơ đồ BFD/DFD chi tiết (hình vẽ) chưa được đính kèm trực tiếp trong repo, hiện mới mô tả dạng văn bản.

### Hướng phát triển

- Bổ sung stored procedure tạo đơn hàng chuẩn production (khóa coupon `FOR UPDATE`, savepoint, xử lý retry).
- Hoàn thiện tài liệu sơ đồ BFD/DFD (bổ sung hình).
- Bổ sung cơ chế bảo mật ứng dụng (authn/authz) nếu public web-ui.

---

## TÀI LIỆU THAM KHẢO (IEEE – gợi ý)

[1] Oracle, “Oracle Database 19c Documentation,” Oracle Documentation.  
[2] Oracle, “PL/SQL Language Reference,” Oracle Documentation.  
[3] Oracle, “Database Concepts – Transactions and Concurrency,” Oracle Documentation.  
[4] Oracle, “Database Security Guide – Users, Roles, and Privileges,” Oracle Documentation.  

> Khi xuất bản Word/PDF, có thể bổ sung đường dẫn và ngày truy cập theo chuẩn IEEE của lớp.

---

## PHỤ LỤC

### Phụ lục A — Cấu trúc file & runbook chạy SQL

#### A.1. Nhóm file SQL theo chức năng

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
- `1_run_all_main.sql`: chạy all-in-one (kết nối SYSDBA tạo lại schema và chạy bước 2→9).

#### A.2. Thứ tự chạy khuyến nghị

| Thứ tự | File | Mục đích |
| --- | --- | --- |
| 0 (tùy chọn) | `0_drop_digibook.sql` | Reset môi trường |
| 1 | `2_create_tables.sql` | Tạo schema |
| 2 | `3_insert_data.sql` | Nạp dữ liệu mẫu |
| 3 | `4_procedures.sql` | Procedure |
| 4 | `5_triggers.sql` | Trigger |
| 5 | `6_views.sql` | View/MView |
| 6 | `7_indexes_and_tuning.sql` | Index + plan |
| 7 | `8_security_roles.sql` | RBAC |
| 8 | `9_transaction_demo.sql` | Transaction demo |

Ghi chú:

- Khi chạy `8_security_roles.sql`, nên dùng tài khoản có quyền tạo user/role và cấp quyền object.
- `9_transaction_demo.sql` đã có `ROLLBACK;` trước `SET TRANSACTION` để tránh lỗi `ORA-01453`.

### Phụ lục B — Bảng phân công công việc

| Thành viên | Hạng mục chính phụ trách | Đầu ra tiêu biểu |
| --- | --- | --- |
| Dũng | Thiết kế cốt lõi, validation, view báo cáo, index recent orders | `vw_order_sales_report`, `trg_biu_orders_validate`, `idx_orders_recent_date` |
| Nam | Báo cáo tổng hợp, đồng bộ tổng tiền, secure view, index low-stock | `sp_report_monthly_sales`, compound trigger recalc, `vw_customer_secure_profile` |
| Hiếu | Cursor, audit, materialized view, function/bitmap index | `sp_print_low_stock_books`, `mv_daily_category_sales` |
| Phát | Coupon discount, security roles, transaction demo | `sp_calculate_coupon_discount`, `8_security_roles.sql`, `9_transaction_demo.sql` |

