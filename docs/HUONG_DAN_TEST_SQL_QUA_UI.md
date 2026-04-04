# Hướng dẫn Kiểm thử SQL qua Giao diện DigiBook (Oracle 19c)

## 1) Trang Cài đặt (Settings) dùng để làm gì? Có cần thiết không?

- **Mục đích hiện tại**:
  - Quản lý thông tin người dùng đăng nhập (form thông tin hồ sơ/bảo mật).
  - Hiển thị thông tin chi nhánh hiện tại mà người dùng đang làm việc.
- **Liên quan đến các mã SQL trong thư mục `sql`**:
  - Đây không phải là trang cốt lõi để kiểm thử các Procedure, Trigger, View, Index.
- **Kết luận**:
  - **Cần thiết** ở góc độ quản trị hệ thống (Giao diện hồ sơ/thiết lập).
  - **Không bắt buộc** nếu mục tiêu duy nhất của bạn là kiểm thử các đối tượng SQL (Procedure, Trigger, View, Index).

---

## 2) Phạm vi đã có giao diện (UI) để kiểm thử

### 2.1 Thủ tục lưu trữ (Procedures)

- **Đã có UI/API để kiểm thử**:
  - `sp_report_monthly_sales` (Báo cáo doanh thu tháng).
  - **UI**: Truy cập `/reports`.
  - **API**: Call `/api/reports/monthly-sales`.
- **Chưa có UI/API kiểm thử trực tiếp**:
  - `sp_manage_book` (Quản lý sách qua Procedure).
  - `sp_print_low_stock_inventory` (In danh sách tồn kho thấp).
  - `sp_calculate_coupon_discount` (Tính toán giảm giá mã Coupon).

### 2.2 Trình kích hoạt (Triggers)

- **Có thể kiểm thử qua giao diện hiện tại**:
  - `trg_aiud_branch_inventory_sync_book_stock`:
    - Kiểm thử thông qua chức năng **Nhập kho (Stock-in)** và **Điều chuyển (Transfer)** (cập nhật bảng `branch_inventory`).
  - `trg_aiud_orders_audit`:
    - Kiểm thử thông qua thao tác **Thay đổi trạng thái đơn hàng**.
- **Kiểm thử một phần / Khó kiểm thử đầy đủ**:
  - `trg_biu_orders_validation`:
    - Hiện tại giao diện chưa có form chỉnh sửa đầy đủ các trường tài chính và mốc thời gian (`total_amount`, `discount_amount`, `shipping_fee`, `final_amount`, `shipped_at`, `delivered_at`, `cancelled_at`).

### 2.3 Khung nhìn (Views)

- **Đã có UI/API để kiểm thử**:
  - `vw_customer_secure_profile` (Hồ sơ bảo mật khách hàng):
    - **UI**: Truy cập `/customers`.
    - **API**: Call `/api/customers`.
  - `vw_order_sales_report` (Báo cáo chi tiết bán hàng):
    - **UI**: Truy cập `/reports`.
    - **API**: Call `/api/reports/sales-overview`.
  - `mv_daily_branch_sales` (Materialized View - Doanh thu chi nhánh theo ngày):
    - **UI**: Truy cập `/reports`.
    - **API**: Call `/api/reports/daily-branch-sales`.

### 2.4 Chỉ mục (Indexes)

- Hiện tại chưa có giao diện kiểm thử trực tiếp mã lệnh `EXPLAIN PLAN` và so sánh hiệu năng trước/sau khi tạo Index.
- **Khuyến nghị**: Nên kiểm thử bằng công cụ SQLcl hoặc Oracle SQL Developer theo file `7_indexes_and_tuning.sql`.

---

## 3) Danh sách giao diện (UI) còn thiếu để kiểm thử đầy đủ SQL

1. **Phòng thí nghiệm Procedure Sách (Book Procedure Lab)**:
   - **Mục tiêu**: Gọi `sp_manage_book` để Thêm/Sửa/Xóa thay vì dùng lệnh DML (Insert/Update/Delete) trực tiếp.
   - **Yêu cầu**: Form nhập đầy đủ tham số của Procedure, hiển thị mã lỗi Oracle và thông báo từ `RAISE_APPLICATION_ERROR`.

2. **Bảng điều khiển Tồn kho thấp (Low Stock Console)**:
   - **Mục tiêu**: Kiểm thử `sp_print_low_stock_inventory`.
   - **Yêu cầu**: Nhập `branch_id`, hiển thị các dòng cảnh báo tồn kho thấp được trả về từ Procedure.

3. **Giao diện Giả lập Coupon (Coupon Simulation UI)**:
   - **Mục tiêu**: Kiểm thử trực tiếp `sp_calculate_coupon_discount`.
   - **Yêu cầu**: Nhập mã Coupon + Giá trị đơn hàng -> Trả về số tiền giảm và thông báo trạng thái (Hợp lệ, Hết hạn, Hết lượt dùng...).

4. **Khu vực Kiểm chứng Đơn hàng (Orders Validation Lab)**:
   - **Mục tiêu**: Kiểm thử ràng buộc của `trg_biu_orders_validation`.
   - **Yêu cầu**: Form cho phép nhập các bộ dữ liệu không hợp lệ (ví dụ: ngày giao trước ngày đặt) để xác nhận Trigger chặn thành công.

5. **Trình xem Nhật ký Kiểm toán (Audit Log Viewer)**:
   - **Mục tiêu**: Đối chiếu kết quả của Trigger `trg_aiud_orders_audit`.
   - **Yêu cầu**: Trang hiển thị bảng `orders_audit_log`, hỗ trợ lọc theo mã đơn hàng và loại hành động.

---

## 4) Hướng dẫn kiểm thử thực tế trên giao diện

### 4.1 Kiểm thử Procedure `sp_report_monthly_sales`
- **Các bước trên UI**:
  1. Mở trang `/reports`.
  2. Chọn khoảng ngày (Từ ngày - Đến ngày).
  3. Bấm **Áp dụng**.
  4. Quan sát bảng **Kết quả SP: sp_report_monthly_sales**.
- **Đối chiếu SQL (Oracle 19c)**:
  ```sql
  VARIABLE rc REFCURSOR;
  EXEC sp_report_monthly_sales(DATE '2026-01-01', DATE '2026-12-31', NULL, :rc);
  PRINT rc;
  ```

### 4.2 Kiểm thử View `vw_customer_secure_profile`
- **Các bước trên UI**:
  1. Mở trang `/customers`.
  2. Tìm kiếm theo Tên, Email (đã ẩn) hoặc Số điện thoại (đã ẩn).
  3. Kiểm tra phân loại khách hàng (STANDARD, LOYAL, VIP).
- **Đối chiếu SQL**:
  ```sql
  SELECT * FROM vw_customer_secure_profile FETCH FIRST 20 ROWS ONLY;
  ```
- **Kỳ vọng**: Dữ liệu cá nhân nhạy cảm đã được che (masking) đúng quy trình trong SQL.

### 4.3 Kiểm thử View `vw_order_sales_report`
- **Các bước trên UI**:
  1. Mở trang `/reports`.
  2. Kiểm tra bảng dữ liệu **Chi tiết bán hàng (View)**.
- **Kỳ vọng**: Các cột Tên chi nhánh, Tên sách, Số lượng phải khớp với dữ liệu gốc.

### 4.4 Kiểm thử Materialized View `mv_daily_branch_sales`
- **Các bước trên UI**:
  1. Mở trang `/reports`.
  2. Kiểm tra bảng **Doanh thu hằng ngày (Materialized View)**.
- **Lưu ý**: Nếu dữ liệu mới chưa hiển thị, cần refresh thủ công trong Database:
  ```sql
  EXEC DBMS_MVIEW.REFRESH('MV_DAILY_BRANCH_SALES', 'C');
  ```

### 4.5 Kiểm thử Trigger đồng bộ tồn kho
- **Các bước trên UI**:
  1. Truy cập `/inventory` và thực hiện **Nhập hàng (Stock-in)** cho một cuốn sách.
  2. Kiểm tra tổng số lượng tồn kho (Total Stock) của cuốn sách đó tại trang Catalog.
- **Kỳ vọng**: Trigger tự động tính toán lại tổng tồn kho toàn bộ hệ thống ngay khi có biến động tại chi nhánh.

### 4.6 Kiểm thử Trigger Nhật ký Đơn hàng (Audit)
- **Các bước trên UI**:
  1. Vào `/orders`, thay đổi trạng thái một đơn hàng bất kỳ.
- **Đối chiếu SQL**:
  ```sql
  SELECT * FROM orders_audit_log WHERE order_id = :your_order_id;
  ```

---

## 5) Ghi chú quan trọng cho Đồ án

1. **Sử dụng Procedure**: Hiện tại các thao tác CRUD cơ bản đang dùng lệnh SQL trực tiếp. Để chứng minh khả năng áp dụng Stored Procedure trong thực tế, nên ưu tiên xây dựng thêm giao diện "Procedure Lab".
2. **Test Indexes**: Phải thực hiện báo cáo hiệu năng bằng SQL Developer để có con số cụ thể về thời gian phản hồi (Response time) và chi phí thực thi (Execution cost) trước/sau khi đánh Index.
3. **Phân quyền**: Các Trigger về bảo mật dữ liệu sẽ phát huy tác dụng tốt nhất khi kiểm thử với các tài khoản Manager/Staff khác nhau.
