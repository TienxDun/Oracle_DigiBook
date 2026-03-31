# Hướng dẫn Kết nối Database Oracle cho DigiBook

Tài liệu này hướng dẫn cách thiết lập Database Oracle và cấu hình UI để kết nối thành công.

## 1. Thiết lập Database (Trong SQL*Plus hoặc SQL Developer)

Chạy các lệnh sau với quyền `SYSDBA`:

```sql
-- Chuyển sang Container PDB (Mặc định thường là ORCLPDB)
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Tạo User mới cho dự án
CREATE USER DIGIBOOK IDENTIFIED BY "Digibook@123";

-- Cấp các quyền cần thiết
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER, CREATE PROCEDURE TO DIGIBOOK;
ALTER USER DIGIBOOK QUOTA UNLIMITED ON USERS;
GRANT UNLIMITED TABLESPACE TO DIGIBOOK;
```

*Lưu ý: Bạn cũng có thể chạy file [0_setup_database.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/0_setup_database.sql) có sẵn trong thư mục gốc.*

## 2. Cấu hình UI (.env.local)

File `.env.local` trong thư mục `ui/` đã được cấu hình như sau:

```env
DB_USER=DIGIBOOK
DB_PASSWORD=Digibook@123
DB_CONNECTION_STRING=localhost:1521/ORCLPDB
```

*Nếu bạn sử dụng host khác hoặc port khác, hãy cập nhật lại `DB_CONNECTION_STRING`.*

## 3. Khởi tạo Tables và Dữ liệu

Sau khi tạo User thành công, đăng nhập bằng User `DIGIBOOK` và chạy các script theo thứ tự:
1. [2_create_tables.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/2_create_tables.sql)
2. [3_insert_data.sql](file:///c:/Users/leuti/Desktop/GitHub/Oracle_DigiBook/3_insert_data.sql)

## 4. Chạy ứng dụng

Trong thư mục `ui/`, thực hiện:
```bash
npm install
npm run dev
```
