# DigiBook Web UI

Web app này cho phép xem dữ liệu Oracle 19c của DigiBook qua giao diện web.

## 1. Chức năng

- Dashboard tổng quan: sách, tồn kho, khách hàng, đơn hàng, doanh thu, đánh giá.
- Xem dữ liệu theo bảng được hỗ trợ: `books`, `customers`, `orders`, `reviews`, `inventory_transactions`.
- Tìm kiếm sách theo tên.
- Kết nối Oracle bằng `node-oracledb` ở chế độ thin.
- Có endpoint `GET /api/runtime` để UI tự hiển thị cổng thực tế, PID và hostname của server.

## 2. Cài đặt

```bash
cd web-ui
copy .env.example .env
npm install
```

Cập nhật file `.env`:

```env
PORT=3000
ORACLE_USER=digibook
ORACLE_PASSWORD=your_password
ORACLE_CONNECTION_STRING=localhost:1521/orclpdb
```

## 3. Chạy ứng dụng

```bash
npm start
```

Nếu cổng trong `PORT` đang bận, ứng dụng sẽ tự động thử các cổng kế tiếp như `3001`, `3002`. URL thực tế sẽ được in ra ở terminal khi khởi động.

Mở trình duyệt tại:

```text
http://localhost:3000
```

## 4. Yêu cầu

- Oracle schema đã được tạo và nạp dữ liệu từ [2_create_tables.sql](..\2_create_tables.sql) và [3_insert_data.sql](..\3_insert_data.sql).
- Node.js 20+ được cài trên máy.
- Tài khoản Oracle có quyền `SELECT` trên các bảng DigiBook.

## 5. Ghi chú kỹ thuật

- Backend không cho chạy SQL tùy ý; chỉ expose các bảng cho phép để giảm rủi ro.
- Nếu Oracle chưa chạy, API `/api/health` sẽ báo lỗi và UI hiện trạng thái kết nối thất bại.
