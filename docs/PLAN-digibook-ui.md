# 🗺️ KẾ HOẠCH TRIỂN KHAI UI DIGIBOOK (SONG SONG ORACLE 19c)

**Mục tiêu:** Xây dựng hệ thống quản trị (Back-office) DigiBook có đầy đủ chức năng, kết nối trực tiếp và khai thác triệt để sức mạnh của Oracle 19c (Procedures, Views, Triggers).

---

## 🏗️ CẤU TRÚC TRIỂN KHAI THEO GIAI ĐOẠN

Kế hoạch này được thiết kế để chạy **SONG SONG** với các file SQL trong `ai_execution_plan.md`.

### **GIAI ĐOẠN 1: NỀN TẢNG & XÁC THỰC (Đồng bộ: File 2 & 8)**
*Trọng tâm: Kết nối DB và Phân quyền người dùng.*

1.  **Kết nối Oracle (Thin Mode):**
    *   Sử dụng `oracledb` v6+ (Thin mode) không cần cài Instant Client.
    *   Xây dựng Connection Pool tại `src/lib/db.ts`.
2.  **Xác thực người dùng (Authentication):**
    *   Xây dựng API `/api/auth/login` truy vấn bảng `USERS`.
    *   Xử lý logic so sánh mật khẩu (hiện tại là so sánh chuỗi đơn giản theo demo).
3.  **Phân quyền (RBAC):**
    *   Xử lý UI dựa trên `ROLE` (ADMIN, MANAGER, STAFF, SUPPORT).
    *   Xây dựng `BranchContext` để lưu trữ thông tin chi nhánh và người dùng hiện tại.

### **GIAI ĐOẠN 2: QUẢN LÝ DANH MỤC & SÁCH (Đồng bộ: File 2 & 3 - Phần Nam)**
*Trọng tâm: Hiển thị và quản lý sản phẩm.*

1.  **Quản lý Category:**
    *   UI hiển thị cấu trúc cây (Parent/Child) từ bảng `CATEGORIES`.
    *   Chức năng Thêm/Sửa/Xóa danh mục.
2.  **Quản lý Sách (Books):**
    *   Trang Catalog liệt kê sách với thông tin từ bảng `BOOKS`, `AUTHORS`, `PUBLISHERS`.
    *   Tích hợp upload/hiện ảnh từ bảng `BOOK_IMAGES`.
3.  **API Integration:**
    *   Xây dựng các API lấy danh sách sách có phân trang (Pagination) sử dụng `OFFSET/FETCH` của Oracle 19c.

### **GIAI ĐOẠN 3: KHO VẬN & ĐIỀU CHUYỂN (Đồng bộ: File 3 & 4 - Phần Phát)**
*Trọng tâm: Đa chi nhánh và tồn kho.*

1.  **Quản lý Tồn kho (Branch Inventory):**
    *   Theo dõi số lượng `quantity_available` và `quantity_reserved` tại từng chi nhánh.
    *   Cảnh báo tồn kho thấp (Low stock alerts) dựa trên `low_stock_threshold`.
2.  **Điều chuyển kho (Transfers):**
    *   Xây dựng quy trình tạo phiếu điều chuyển `DC001`, `DC002`.
    *   Xử lý trạng thái phiếu (Pending -> Shipping -> Completed).
3.  **API Triggers Test:**
    *   Kiểm tra xem khi điều chuyển, Trigger trong DB có tự động cập nhật số lượng ở 2 chi nhánh không.

### **GIAI ĐOẠN 4: BÁN HÀNG & KHÁCH HÀNG (Đồng bộ: File 3 - Phần Hiếu)**
*Trọng tâm: Quy trình đơn hàng.*

1.  **Quản lý đơn hàng (Orders):**
    *   Trang danh sách đơn hàng lấy từ bảng `ORDERS`.
    *   Trang chi tiết đơn hàng hiển thị `ORDER_DETAILS`.
2.  **Luồng trạng thái đơn hàng:**
    *   Cập nhật trạng thái đơn hàng (Confirm, Ship, Deliver, Cancel).
    *   Ghi log tự động vào bảng `ORDER_STATUS_HISTORY`.
3.  **Quản lý khách hàng (Customers):**
    *   Hiển thị thông tin khách hàng, lịch sử mua hàng và danh sách yêu thích (Wishlists).

### **GIAI ĐOẠN 5: BÁO CÁO & TỐI ƯU (Đồng bộ: File 4, 6, 7)**
*Trọng tâm: Khai thác SQL nâng cao lên UI.*

1.  **Dashboard Thống kê:**
    *   Sử dụng các **Database Views** (File 6) để vẽ biểu đồ doanh thu, hiệu suất chi nhánh.
    *   Gọi **Stored Procedures** (File 4) để tính toán báo cáo phức tạp phía server trước khi trả về UI.
2.  **Audit Logs UI:**
    *   Trang dành cho Admin xem lịch sử thao tác hệ thống (từ Triggers ghi log ở File 5).
3.  **Kiểm tra Performance:**
    *   Test tốc độ phản hồi của UI trước và sau khi đánh **Indexes** (File 7) trên các bảng lớn như `ORDERS` hoặc `BOOKS`.

---

## 📈 QUY TRÌNH PHÁT TRIỂN SONG SONG

| Tuần | Công việc Database (SQL) | Công việc Giao diện (UI) | Cách Test |
| :--- | :--- | :--- | :--- |
| **1** | File 2 & 8 (Tables, Roles) | Phase 1 (Nền tảng, Login) | Đăng nhập bằng user `admin` từ DB. |
| **2** | File 3 (Dữ liệu mẫu - Catalog) | Phase 2 (Catalog, Books) | Hiển thị sách từ bảng `BOOKS` lên UI. |
| **3** | File 3 & 4 (Inventory, SPs) | Phase 3 (Kho, Tồn kho) | Kiểm tra số lượng tồn kho theo chi nhánh. |
| **4** | File 3 & 5 (Orders, Triggers) | Phase 4 (Bán hàng, Đơn hàng) | Tạo đơn hàng và check Log tự động. |
| **5** | File 6 & 7 (Views, Indexes) | Phase 5 (Dashboard, Báo cáo) | Xem biểu đồ doanh thu từ View. |

---

## 📝 ĐẦU RA KỲ VỌNG (DELIVERABLES)
1.  **Hệ thống UI hoàn chỉnh:** Sử dụng Next.js, Tailwind CSS, Lucide Icons.
2.  **Backend API:** Viết bằng Next.js API Routes kết nối trực tiếp Oracle 19c.
3.  **Bộ tài liệu:** File `docs/PLAN-digibook-ui.md` này làm kim chỉ nam.

> [!IMPORTANT]
> Toàn bộ logic nghiệp vụ nặng (tính toán doanh thu, cập nhật tồn kho đa chi nhánh) phải được thực hiện ở tầng **Database (Stored Procs/Triggers)** để đảm bảo tính nhất quán dữ liệu, UI chỉ đóng vai trò hiển thị và gọi lệnh.
