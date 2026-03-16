# Oracle DigiBook

Oracle DigiBook là dự án mẫu quản lý nhà sách trên Oracle Database, kèm web UI để xem dashboard, tìm kiếm sách và duyệt dữ liệu bảng mà không cần viết SQL thủ công mỗi lần.

## Mục tiêu dự án

- Thiết kế schema Oracle cho nghiệp vụ nhà sách (sách, đơn hàng, giỏ hàng, kho, đánh giá...).
- Cung cấp bộ script SQL để dựng dữ liệu nhanh cho demo/học tập.
- Cung cấp web UI Node.js + Express + vanilla JS để tra cứu dữ liệu trực quan.

## Cấu trúc thư mục

- `1_Database_Design.md`: mô tả thiết kế dữ liệu.
- `2_create_tables.sql`: tạo bảng và ràng buộc.
- `3_insert_data.sql`: nạp dữ liệu mẫu.
- `0_drop_digibook.sql`: dọn schema (nếu cần reset).
- `0.1_list_digibook_objects.sql`: liệt kê object trong schema.
- `web-ui/`: ứng dụng web (backend API + frontend tĩnh).

## Kiến trúc tổng quan

- Database: Oracle 19c (hoặc tương thích Oracle).
- Backend: Express tại `web-ui/src/server.js`.
- Data access: `query()` tập trung tại `web-ui/src/db.js` (node-oracledb thin mode).
- Frontend: static files trong `web-ui/public`.
- Bảo mật truy cập bảng: chỉ các bảng trong `allowedTables` được expose qua API.

## Tính năng chính

- Dashboard tổng quan: số sách, tồn kho, khách hàng, đơn hàng, doanh thu đã giao, điểm đánh giá.
- Danh sách bảng hỗ trợ với số dòng và xem dữ liệu theo giới hạn.
- Tìm kiếm sách theo tiêu đề.
- Theo dõi runtime app qua endpoint `/api/runtime`.
- Tự động tăng cổng nếu `PORT` bị chiếm (ví dụ 3000 -> 3001...).

## Yêu cầu môi trường

- Node.js 20+.
- Oracle DB đang chạy và có schema DigiBook.
- User Oracle có quyền truy vấn các bảng DigiBook.

## Khởi tạo database

Chạy script theo đúng thứ tự:

1. `2_create_tables.sql`
2. `3_insert_data.sql`

Nếu cần reset dữ liệu trước khi tạo lại:

1. `0_drop_digibook.sql`
2. `2_create_tables.sql`
3. `3_insert_data.sql`

## Chạy web UI

Lưu ý quan trọng: chạy lệnh Node.js trong thư mục `web-ui`, không chạy ở thư mục root.

1. Vào thư mục ứng dụng:

   ```bash
   cd web-ui
   ```

2. Tạo file cấu hình môi trường từ mẫu:

   ```bash
   copy .env.example .env
   ```

3. Cập nhật `.env` với thông tin Oracle:

   ```env
   PORT=3000
   ORACLE_USER=digibook
   ORACLE_PASSWORD=your_password
   ORACLE_CONNECTION_STRING=localhost:1521/orclpdb
   ```

4. Cài dependency và chạy app:

   ```bash
   npm install
   npm start
   ```

5. Chế độ dev (watch):

   ```bash
   npm run dev
   ```

Sau khi start, xem terminal để biết URL thực tế (trường hợp đổi cổng).

## API chính

- `GET /api/health`: kiểm tra kết nối Oracle.
- `GET /api/runtime`: thông tin runtime (port thực tế, pid, hostname, startedAt).
- `GET /api/summary`: dữ liệu dashboard + đơn hàng gần đây.
- `GET /api/tables`: danh sách bảng được hỗ trợ và tổng số dòng.
- `GET /api/table/:tableName?limit=25`: dữ liệu theo bảng (`limit` clamp từ 1..100).
- `GET /api/search/books?q=...`: tìm kiếm sách theo tên.

## Bảng được hỗ trợ qua UI/API

- `categories`
- `carts`
- `cart_items`
- `books`
- `book_images`
- `book_authors`
- `customers`
- `authors`
- `publishers`
- `coupons`
- `orders`
- `order_details`
- `order_status_history`
- `reviews`
- `inventory_transactions`

## Troubleshooting nhanh

- `npm start` báo lỗi ở root: đảm bảo đã `cd web-ui` trước khi chạy.
- UI báo lỗi kết nối DB: kiểm tra `.env` và thử `GET /api/health`.
- Không truy cập được cổng 3000: app có thể đã tự chuyển sang cổng kế tiếp, xem log startup hoặc `GET /api/runtime`.
- Thiếu dữ liệu bảng: xác nhận đã chạy đủ `2_create_tables.sql` và `3_insert_data.sql`.

## Ghi chú

- Mục tiêu của dự án là demo/learning flow end-to-end (DB -> API -> UI).
- Nếu mở rộng API, nên giữ pattern hiện tại: route mỏng, truy vấn tập trung qua `query()`.
