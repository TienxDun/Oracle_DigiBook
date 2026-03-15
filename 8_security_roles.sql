/*
================================================================================
  📦 BƯỚC 8: PHÂN QUYỀN & BẢO MẬT (DCL) — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 8_security_roles.sql
  Mục đích: Tạo Roles, Users và phân quyền truy cập (DCL - Data Control Language).
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Cần chạy dưới quyền SYSDBA hoặc user có quyền quản trị (DBA).
  - Script này bao gồm việc tạo Role, User và cấp quyền (GRANT).
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 🗑️ PHẦN 0: XÓA CÁC ĐỐI TƯỢNG CŨ (NẾU TỒN TẠI)
-- ============================================================================
BEGIN
    -- Xóa Users
    FOR r IN (SELECT username FROM dba_users WHERE username IN ('DB_ADMIN_USER', 'DB_STAFF_USER', 'DB_GUEST_USER')) LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || r.username || ' CASCADE';
    END LOOP;
    
    -- Xóa Roles
    FOR r IN (SELECT role FROM dba_roles WHERE role IN ('DIGIBOOK_ADMIN', 'DIGIBOOK_STAFF', 'DIGIBOOK_GUEST')) LOOP
        EXECUTE IMMEDIATE 'DROP ROLE ' || r.role;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

PROMPT ✅ Đã dọn dẹp các Role và User cũ thành công!
PROMPT ================================================

-- ============================================================================
-- 🛡️ PHẦN 1: TẠO ROLES (NHÓM QUYỀN)
-- ============================================================================

-- 1. Role Quản trị viên (Toàn quyền)
CREATE ROLE DIGIBOOK_ADMIN;
PROMPT ✅ Đã tạo Role: DIGIBOOK_ADMIN

-- 2. Role Nhân viên (Quản lý sách, xem đơn hàng, xem báo cáo)
CREATE ROLE DIGIBOOK_STAFF;
PROMPT ✅ Đã tạo Role: DIGIBOOK_STAFF

-- 3. Role Khách (Chỉ xem thông tin sách và đánh giá)
CREATE ROLE DIGIBOOK_GUEST;
PROMPT ✅ Đã tạo Role: DIGIBOOK_GUEST

-- ============================================================================
-- 🔑 PHẦN 2: PHÂN QUYỀN CHI TIẾT CHO CÁC ROLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1. Phân quyền cho DIGIBOOK_ADMIN (DŨNG phụ trách)
-- ----------------------------------------------------------------------------
-- Admin có toàn quyền trên các bảng dữ liệu
GRANT ALL PRIVILEGES ON CUSTOMERS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON CATEGORIES TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON AUTHORS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON PUBLISHERS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON BOOKS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON BOOK_AUTHORS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON ORDERS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON ORDER_DETAILS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON REVIEWS TO DIGIBOOK_ADMIN;
GRANT ALL PRIVILEGES ON AUDIT_LOG TO DIGIBOOK_ADMIN;

-- Admin có quyền thực thi tất cả procedure
GRANT EXECUTE ON sp_manage_book TO DIGIBOOK_ADMIN;
GRANT EXECUTE ON sp_revenue_report TO DIGIBOOK_ADMIN;
GRANT EXECUTE ON sp_list_books_by_cat TO DIGIBOOK_ADMIN;
GRANT EXECUTE ON sp_place_order TO DIGIBOOK_ADMIN;

-- Admin có quyền trên các View
GRANT SELECT ON vw_order_report TO DIGIBOOK_ADMIN;
GRANT SELECT ON vw_customer_safe TO DIGIBOOK_ADMIN;
GRANT SELECT ON mv_book_sales_summary TO DIGIBOOK_ADMIN;

PROMPT ✅ Đã phân quyền cho Role: DIGIBOOK_ADMIN

-- ----------------------------------------------------------------------------
-- 2.2. Phân quyền cho DIGIBOOK_STAFF (NAM & HIẾU phụ trách)
-- ----------------------------------------------------------------------------
-- Nhân viên có thể xem khách hàng (nhưng chỉ qua view che giấu dữ liệu)
GRANT SELECT ON vw_customer_safe TO DIGIBOOK_STAFF;

-- Nhân viên quản lý kho sách và danh mục
GRANT SELECT, INSERT, UPDATE, DELETE ON BOOKS TO DIGIBOOK_STAFF;
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIES TO DIGIBOOK_STAFF;
GRANT SELECT, INSERT, UPDATE, DELETE ON AUTHORS TO DIGIBOOK_STAFF;
GRANT SELECT, INSERT, UPDATE, DELETE ON PUBLISHERS TO DIGIBOOK_STAFF;
GRANT SELECT, INSERT, UPDATE, DELETE ON BOOK_AUTHORS TO DIGIBOOK_STAFF;

-- Nhân viên chỉ có quyền xem đơn hàng và chi tiết
GRANT SELECT ON ORDERS TO DIGIBOOK_STAFF;
GRANT SELECT ON ORDER_DETAILS TO DIGIBOOK_STAFF;
GRANT SELECT ON vw_order_report TO DIGIBOOK_STAFF;

-- Nhân viên thực thi các procedure quản lý
GRANT EXECUTE ON sp_manage_book TO DIGIBOOK_STAFF;
GRANT EXECUTE ON sp_list_books_by_cat TO DIGIBOOK_STAFF;
GRANT SELECT ON mv_book_sales_summary TO DIGIBOOK_STAFF;

PROMPT ✅ Đã phân quyền cho Role: DIGIBOOK_STAFF

-- ----------------------------------------------------------------------------
-- 2.3. Phân quyền cho DIGIBOOK_GUEST (PHÁT phụ trách)
-- ----------------------------------------------------------------------------
-- Khách chỉ có quyền xem thông tin cơ bản
GRANT SELECT ON BOOKS TO DIGIBOOK_GUEST;
GRANT SELECT ON CATEGORIES TO DIGIBOOK_GUEST;
GRANT SELECT ON AUTHORS TO DIGIBOOK_GUEST;
GRANT SELECT ON REVIEWS TO DIGIBOOK_GUEST;
GRANT SELECT ON mv_book_sales_summary TO DIGIBOOK_GUEST;

-- Khách có thể thực thi procedure liệt kê sách
GRANT EXECUTE ON sp_list_books_by_cat TO DIGIBOOK_GUEST;

PROMPT ✅ Đã phân quyền cho Role: DIGIBOOK_GUEST

-- ============================================================================
-- 👤 PHẦN 3: TẠO NGƯỜI DÙNG (USERS) VÀ GÁN ROLES
-- ============================================================================

-- 1. Create Admin User
CREATE USER DB_ADMIN_USER IDENTIFIED BY Admin123#;
GRANT CONNECT, RESOURCE TO DB_ADMIN_USER;
GRANT DIGIBOOK_ADMIN TO DB_ADMIN_USER;
PROMPT ✅ Đã tạo User: DB_ADMIN_USER (Role: DIGIBOOK_ADMIN)

-- 2. Create Staff User
CREATE USER DB_STAFF_USER IDENTIFIED BY Staff123#;
GRANT CONNECT, RESOURCE TO DB_STAFF_USER;
GRANT DIGIBOOK_STAFF TO DB_STAFF_USER;
PROMPT ✅ Đã tạo User: DB_STAFF_USER (Role: DIGIBOOK_STAFF)

-- 3. Create Guest User
CREATE USER DB_GUEST_USER IDENTIFIED BY Guest123#;
GRANT CONNECT TO DB_GUEST_USER;
GRANT DIGIBOOK_GUEST TO DB_GUEST_USER;
PROMPT ✅ Đã tạo User: DB_GUEST_USER (Role: DIGIBOOK_GUEST)

-- ============================================================================
-- 📊 PHẦN 4: KIỂM TRA PHÂN QUYỀN
-- ============================================================================

PROMPT
PROMPT ================================================================
PROMPT 📋 KIỂM TRA HỆ THỐNG PHÂN QUYỀN
PROMPT ================================================================

PROMPT 1. Danh sách Roles đã tạo:
SELECT role FROM dba_roles WHERE role LIKE 'DIGIBOOK%';

PROMPT 2. Danh sách quyền của Role DIGIBOOK_STAFF trên các bảng:
SELECT table_name, privilege FROM role_tab_privs WHERE role = 'DIGIBOOK_STAFF';

PROMPT 3. Danh sách Users đã gán Role:
SELECT grantee, granted_role FROM dba_role_privs 
WHERE granted_role LIKE 'DIGIBOOK%' 
ORDER BY grantee;

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 8 HOÀN TẤT — PHÂN QUYỀN & BẢO MẬT THÀNH CÔNG!
PROMPT ================================================================
PROMPT    🛡️ 3 Roles created: ADMIN, STAFF, GUEST
PROMPT    🔑 Detailed Object Privileges granted
PROMPT    👤 3 Users created and mapped to Roles
PROMPT ================================================================
