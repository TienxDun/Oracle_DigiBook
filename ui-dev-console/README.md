# Oracle 19c Dev Console - DigiBook

Ứng dụng độc lập (Standalone) phát triển bằng Next.js hỗ trợ kiểm thử trực quan các đối tượng trong cơ sở dữ liệu Oracle 19c:
- Thủ tục lưu trữ (Procedures)
- Trình kích hoạt (Triggers)
- Khung nhìn / Khung nhìn thực thể hóa (Views / Materialized Views)
- Ma trận phân quyền bảo mật (Security Role Matrix)

Ứng dụng này được thiết kế tách biệt hoàn toàn với giao diện của người dùng cuối (End-user UI) và chỉ phục vụ cho môi trường **Local/Development**.

---

## 1) Cài đặt (Setup)

1. Sao chép file `.env.example` thành `.env.local`
2. Thiết lập các giá trị cấu hình tương ứng:
   - `ORACLE_CONNECTION_STRING` (Chuỗi kết nối Oracle)
   - `SESSION_SECRET` (Bí mật phiên làm việc - chỉ dùng cho local)
   - `SESSION_TTL_MINUTES` (Thời gian hết hạn phiên làm việc)
3. Cài đặt các thư viện phụ thuộc:

```bash
npm install
```

---

## 2) Khởi chạy (Run)

Sử dụng lệnh sau để chạy ứng dụng ở chế độ phát triển:

```bash
npm run dev
```

Truy cập tại địa chỉ: `http://localhost:3100`

---

## 3) Đăng nhập (Login)

Sử dụng các tài khoản Oracle được tạo từ script `sql/8_security_roles.sql`. Ví dụ:
- `DIGIBOOK_ADMIN` (Quản trị viên)
- `DIGIBOOK_STAFF` (Nhân viên)
- `DIGIBOOK_GUEST` (Khách)

---

## 4) Các Module Kiểm thử Hiện có

- **Trình thực thi View**: Chạy và xem kết quả của các View/Materialized View.
- **Trình thực thi Procedure**: Gọi và truyền tham số cho các Stored Procedure.
- **Giả lập Kịch bản Trigger**: Chạy các tình huống để kiểm tra Trigger (có hỗ trợ Rollback).
- **Xem ma trận bảo mật**: Kiểm tra quyền truy cập của từng Role.

---

## 5) Lưu ý về An toàn & Bảo mật

- **Allowlists**: API chỉ cho phép thao tác trên các đối tượng CSDL nằm trong danh sách trắng (Allowlist) đã định nghĩa trước.
- **Cơ chế Rollback**: Các kịch bản kiểm thử Trigger sử dụng `SAVEPOINT` + `ROLLBACK` để tránh thay đổi dữ liệu vĩnh viễn trong CSDL khi đang kiểm tra.
- **Môi trường**: Ứng dụng này **không** dành cho việc triển khai thực tế trên môi trường Production.
