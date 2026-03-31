# Hướng dẫn Kiểm tra Giao diện (UI Testing Guide) - DigiBook

Tài liệu này hướng dẫn cách đăng nhập và kiểm tra các chức năng cơ bản trên giao diện UI sau khi đã thiết lập Database thành công.

## 1. Yêu cầu Tiền quyết
*   Oracle Database 19c đã chạy.
*   Đã thực hiện xong các bước khởi tạo trong:
    *   [0_setup_database.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/0_setup_database.sql)
    *   [2_create_tables.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/2_create_tables.sql)
    *   [3_insert_data.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/3_insert_data.sql)
*   Server Next.js đang chạy (`npm run dev` trong thư mục `ui/`).

## 2. Thông tin Đăng nhập (Dựa trên dữ liệu mẫu)

Truy cập: [http://localhost:3000/login](http://localhost:3000/login)

| Vai trò | Tên đăng nhập (Username) | Mật khẩu (Password) | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin` | `HASH_VALUE_HERE` | Quyền cao nhất hệ thống |
| **Quản lý (Manager)** | `manager_hn` | `HASH_MGR_HN` | Quản lý chi nhánh Hà Nội |
| **Nhân viên bán hàng** | `staff_sale_01` | `HASH_SALE01` | Phụ trách đơn hàng |
| **Thủ kho** | `staff_kho` | `HASH_KHO` | Phụ trách nhập xuất, điều chuyển |

---

## 3. Các bước Kiểm tra (Test Cases)

### Kịch bản 1: Đăng nhập & Dashboard
1. Truy cập trang `/login`.
2. Đăng nhập bằng tài khoản `manager_hn` / `HASH_MGR_HN`.
3. Kiểm tra xem có hiển thị thông báo "Đăng nhập thành công" không.
4. Kiểm tra trang **Dashboard** có hiển thị các con số thống kê (Doanh thu, Đơn hàng, Tổng sách) không.

### Kịch bản 2: Quản lý Danh mục Sách (Catalog)
1. Chọn menu **Sách / Sản phẩm**.
2. Kiểm tra danh sách sách (ISBN: `9786041026700` - Nhà Giả Kim) có xuất hiện không.
3. Thử tìm kiếm theo tên sách hoặc lọc theo danh mục (Văn học, Kinh tế...).

### Kịch bản 3: Quản lý Kho hàng (Inventory)
1. Chọn menu **Kho hàng / Tồn kho**.
2. Kiểm tra số lượng tồn kho của sách `Nhà Giả Kim` tại chi nhánh hiện tại.
3. Kiểm tra thông tin kệ hàng, khu vực kho (Zone A, B...).

### Kịch bản 4: Quản lý Đơn hàng (Orders)
1. Chọn menu **Đơn hàng**.
2. Tìm đơn hàng mã `ORD001`.
3. Click vào đơn hàng để xem chi tiết khách hàng và lịch sử trạng thái (Pending -> Confirmed -> Shipping -> Delivered).

---

## 4. Xử lý sự cố thường gặp
*   **Lỗi kết nối máy chủ**: Kiểm tra lại file `ui/.env.local` xem `DB_CONNECTION_STRING` đã đúng chưa.
*   **Lỗi đăng nhập thất bại**: Kiểm tra xem bạn đã chạy `COMMIT;` sau khi insert dữ liệu trong SQL chưa.
*   **Lỗi giao diện**: Nếu thấy lỗi đỏ liên quan đến thuộc tính "katalonextensionid", hãy refresh trang (đã được fix trong `layout.tsx`).
