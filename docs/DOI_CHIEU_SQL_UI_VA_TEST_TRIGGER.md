# Đối chiếu SQL với UI và Bảng Kiểm Thử (Test Cases)

Tài liệu này dùng để đối chiếu các đối tượng Database (SQL) với các thành phần tương ứng trên giao diện (UI) và các kịch bản kiểm thử (Test Cases) cho Trigger.

## 1. Đối chiếu SQL -> API -> UI

Bảng dưới đây liệt kê các thành phần đã được kết nối từ Database lên giao diện ứng dụng.

| STT | Thành phần (Procedure/View/Trigger) | SQL Object (File & Name) | API Endpoint (Backend Route) | Màn hình UI (Frontend) |
|:---:|:---|:---|:---|:---|
| 1 | **Báo cáo doanh thu tháng** | `sql/4_procedures.sql`<br>`sp_report_monthly_sales` | `/api/reports/monthly-sales` | `Báo cáo / Thống kê` |
| 2 | **Tổng quan bán hàng (View)** | `sql/6_views.sql`<br>`vw_order_sales_report` | `/api/reports/sales-overview` | `Báo cáo / Thống kê` |
| 3 | **Doanh thu chi nhánh (M-View)** | `sql/6_views.sql`<br>`mv_daily_branch_sales` | `/api/reports/daily-branch-sales` | `Báo cáo / Thống kê` |
| 4 | **Hồ sơ khách hàng bảo mật** | `sql/6_views.sql`<br>`vw_customer_secure_profile` | `/api/customers` | `Quản lý Khách hàng` |
| 5 | **Cảnh báo tồn kho thấp** | `sql/4_procedures.sql`<br>`sp_print_low_stock_inventory` | `/api/inventory/low-stock` | `Kho hàng (Drawer)` |
| 6 | **Tính toán giảm giá Coupon** | `sql/4_procedures.sql`<br>`sp_calculate_coupon_discount` | `/api/coupons/test` | `Quản lý Coupon` |
| 7 | **Quản lý Sách (CRUD)** | `sql/4_procedures.sql`<br>`sp_manage_book` | `/api/catalog` & `/[id]` | `Danh mục Sách` |
| 8 | **Audit Log đơn hàng** | `sql/5_triggers.sql`<br>`trg_aiud_orders_audit` | `/api/audit-logs` | `Nhật ký hệ thống` |
| 9 | **Đồng bộ tồn kho tổng** | `sql/5_triggers.sql`<br>`trg_aiud_branch_inventory...` | `/api/inventory/stock-in`<br>`/api/inventory/transfer` | `Quản lý Kho / Chuyển kho` |

---

## 2. Các thành phần chưa tích hợp UI chính

Dưới đây là các phần hiện tại chủ yếu được kiểm tra qua `ui-dev-console` hoặc Script SQL.

| STT | Thành phần | SQL Object | Trạng thái / Ghi chú |
|:---:|:---|:---|:---|
| 1 | **Demo Giao dịch (Transaction)** | `sql/9_transaction_demo.sql` | Demo qua `ui-dev-console` (Rubric) |
| 2 | **Trigger Validate đơn hàng** | `trg_biu_orders_validation` | Kích hoạt tự động khi cập nhật đơn hàng |
| 3 | **Trigger ID tự tăng** | Nhóm `trg_*_bi` | Tự động chạy khi Insert dữ liệu |

---

## 3. Kịch bản kiểm thử (Test Cases) cho Trigger

### A. Kiểm thử Validation (Trigger `trg_biu_orders_validation`)

| Mã TC | Tình huống kiểm thử | Các bước thực hiện | Kết quả kỳ vọng |
|:---|:---|:---|:---|
| **TC-OV-01** | Giá trị `total_amount` âm | Cập nhật `total_amount = -1` | Lỗi `ORA-20501` (Không được âm) |
| **TC-OV-02** | Sai công thức `final_amount` | Set `final_amount` không khớp công thức | Lỗi `ORA-20502` (Sai logic tính toán) |
| **TC-OV-03** | Thiếu ngày gửi (`shipped_at`) | Có `delivered_at` nhưng `shipped_at = NULL` | Lỗi `ORA-20503` (Trình tự thời gian sai) |
| **TC-OV-04** | Sai trạng thái hủy | Có `cancelled_at` nhưng status không phải hủy | Lỗi `ORA-20504` (Mâu thuẫn trạng thái) |
| **TC-OV-05** | Tự động gán ngày hủy | Status = `CANCELLED`, bỏ trống `cancelled_at` | Hệ thống tự điền ngày hiện tại |

### B. Kiểm thử Nhật ký (Trigger `trg_aiud_orders_audit`)

| Mã TC | Hành động | Các bước thực hiện | Kết quả kỳ vọng |
|:---|:---|:---|:---|
| **TC-OA-01** | Tạo đơn hàng (INSERT) | Insert 1 đơn hàng mới | `orders_audit_log` thêm dòng mới (INSERT) |
| **TC-OA-02** | Cập nhật đơn (UPDATE) | Thay đổi trạng thái/ghi chú đơn hàng | Thêm dòng mới (UPDATE), lưu giá cũ/mới |
| **TC-OA-03** | Xóa đơn (DELETE) | Xóa 1 bản ghi trong bảng `orders` | Thêm dòng mới (DELETE), lưu lại ID đã xóa |
| **TC-OA-04** | Rollback giao dịch | Update đơn hàng rồi thực hiện `Rollback` | Không có log nào được lưu lại |

### C. Kiểm thử Đồng bộ Tồn kho (`trg_aiud_branch_inventory_sync...`)

| Mã TC | Hành động | Các bước thực hiện | Kết quả kỳ vọng |
|:---|:---|:---|:---|
| **TC-BI-01** | Thêm tồn kho chi nhánh | Insert dòng mới vào `branch_inventory` | `books.stock_quantity` tăng tự động |
| **TC-BI-02** | Cập nhật số lượng | Thay đổi `quantity_available` ở chi nhánh | Tổng kho tại bảng `books` cập nhật theo |
| **TC-BI-03** | Xóa bản ghi tồn kho | Delete dòng tồn kho của sách X | Tổng kho giảm tương ứng |
| **TC-BI-04** | Cập nhật hàng loạt | Cập nhật nhiều chi nhánh cùng lúc | Không lỗi Mutating Table, tổng kho đúng |

---

## 4. Ghi chú chung cho buổi vấn đáp

- **Mẹo nhỏ:** Khi giảng viên hỏi về Trigger, hãy chỉ vào bảng **Test Cases** để giải thích các ràng buộc nghiệp vụ (Business Rules) mà bạn đã cài đặt trực tiếp trong Database.
- **Dữ liệu thực tế:** Bạn nên mở bảng `orders_audit_log` để chứng minh Trigger thực sự ghi nhận lại mọi thay đổi do người dùng thực hiện trên UI.
