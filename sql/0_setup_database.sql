-- ==========================================================
-- FILE: 0_setup_database.sql
-- MỤC TIÊU: Thiết lập PDB và User vĩnh viễn cho dự án DigiBook
-- ORACLE VERSION: 19c (PDB Mode)
-- ==========================================================

-- 1. Chuyển đổi Session sang PDB (Mặc định là ORCLPDB)
-- Lệnh này đảm bảo mọi thao tác sau đó tác động lên PDB chứ không phải Root Container.
ALTER SESSION SET CONTAINER = ORCLPDB;

-- 2. Xóa User cũ (Chỉ dùng khi muốn cài đặt lại từ đầu)
-- DROP USER DIGIBOOK CASCADE;

-- 3. Tạo User DIGIBOOK
-- DEFAULT TABLESPACE USERS: Dữ liệu (Bảng, Index) sẽ được lưu vĩnh viễn trên file .dbf của hệ thống.
-- TEMPORARY TABLESPACE TEMP: Chỉ dùng cho các tác vụ sắp xếp (Sort/Join) tạm thời.
CREATE USER DIGIBOOK IDENTIFIED BY "Digibook@123"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;

-- 4. Cấp quyền kết nối và truy cập tài nguyên
GRANT CONNECT, RESOURCE TO DIGIBOOK;

-- 5. Cấp quyền lưu trữ vĩnh viễn (Persistent Storage)
-- Đảm bảo dữ liệu được ghi xuống đĩa cứng và không bị giới hạn dung lượng.
ALTER USER DIGIBOOK QUOTA UNLIMITED ON USERS;
GRANT UNLIMITED TABLESPACE TO DIGIBOOK;

-- 6. Cấp các quyền nghiệp vụ bổ sung để tạo Objects
GRANT CREATE VIEW TO DIGIBOOK;
GRANT CREATE SEQUENCE TO DIGIBOOK;
GRANT CREATE TRIGGER TO DIGIBOOK;
GRANT CREATE PROCEDURE TO DIGIBOOK;
GRANT CREATE MATERIALIZED VIEW TO DIGIBOOK;

-- 7. Thông báo hoàn tất
PROMPT ===================================================
PROMPT HE THONG DA SAN SANG!
PROMPT PDB: ORCLPDB
PROMPT USER: DIGIBOOK / PASS: Digibook@123
PROMPT LUU TRU: PERMANENT (TABLESPACE USERS)
PROMPT ===================================================
