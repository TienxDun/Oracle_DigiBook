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

SET DEFINE OFF;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- ============================================================================
-- ✅ PHẦN TIỀN KIỂM TRA MÔI TRƯỜNG THỰC THI
-- ============================================================================
-- Bắt buộc chạy trong PDB (không chạy ở CDB$ROOT), và tự động trỏ CURRENT_SCHEMA
-- về schema đang chứa các object DigiBook để lệnh GRANT không bị ORA-00942.
DECLARE
  v_con_name   VARCHAR2(128);
  v_target_pdb VARCHAR2(128);
  v_owner      VARCHAR2(128);
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'CON_NAME') INTO v_con_name FROM dual;

  IF v_con_name = 'CDB$ROOT' THEN
    BEGIN
      SELECT name
        INTO v_target_pdb
        FROM (
              SELECT name
                FROM v$pdbs
               WHERE open_mode = 'READ WRITE'
               ORDER BY CASE WHEN UPPER(name) = 'XEPDB1' THEN 0 ELSE 1 END, name
             )
       WHERE ROWNUM = 1;

      EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_target_pdb);
      SELECT SYS_CONTEXT('USERENV', 'CON_NAME') INTO v_con_name FROM dual;
      DBMS_OUTPUT.PUT_LINE('ℹ️ Dang chay o CDB$ROOT -> da tu dong chuyen sang PDB: ' || v_con_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
          -20081,
          'Dang o CDB$ROOT va khong co PDB nao mo READ WRITE. Hay mo PDB (vd: XEPDB1) hoac CONNECT truc tiep vao service PDB roi chay lai.'
        );
    END;
  END IF;

  SELECT owner
    INTO v_owner
    FROM (
      SELECT owner
        FROM dba_tables
       WHERE table_name = 'CUSTOMERS'
         AND owner NOT IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS')
       ORDER BY CASE WHEN owner = 'DIGIBOOK' THEN 0 ELSE 1 END, owner
       )
   WHERE ROWNUM = 1;

  EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = ' || v_owner;
  DBMS_OUTPUT.PUT_LINE('✅ Current container: ' || v_con_name);
  DBMS_OUTPUT.PUT_LINE('✅ Current schema for object grants: ' || v_owner);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(
      -20082,
      'Khong tim thay bang CUSTOMERS trong PDB hien tai. Hay chay 2_create_tables.sql truoc, sau do chay lai file nay.'
    );
END;
/

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

DECLARE
  v_count NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('1. Danh sách Roles đã tạo:');
  v_count := 0;
  FOR r IN (
    SELECT role
    FROM dba_roles
    WHERE role LIKE 'DIGIBOOK%'
    ORDER BY role
  ) LOOP
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('   - ' || r.role);
  END LOOP;
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('   (không có dữ liệu)');
  END IF;

  DBMS_OUTPUT.PUT_LINE('2. Danh sách quyền của Role DIGIBOOK_STAFF trên các bảng:');
  v_count := 0;
  FOR r IN (
    SELECT table_name, privilege
    FROM role_tab_privs
    WHERE role = 'DIGIBOOK_STAFF'
    ORDER BY table_name, privilege
  ) LOOP
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('   - ' || RPAD(r.table_name, 20) || ' : ' || r.privilege);
  END LOOP;
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('   (không có dữ liệu)');
  END IF;

  DBMS_OUTPUT.PUT_LINE('3. Danh sách Users đã gán Role:');
  v_count := 0;
  FOR r IN (
    SELECT grantee, granted_role
    FROM dba_role_privs
    WHERE granted_role LIKE 'DIGIBOOK%'
    ORDER BY grantee, granted_role
  ) LOOP
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE('   - ' || RPAD(r.grantee, 20) || ' -> ' || r.granted_role);
  END LOOP;
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('   (không có dữ liệu)');
  END IF;
END;
/

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 8 HOÀN TẤT — PHÂN QUYỀN & BẢO MẬT THÀNH CÔNG!
PROMPT ================================================================
PROMPT    🛡️ 3 Roles created: ADMIN, STAFF, GUEST
PROMPT    🔑 Detailed Object Privileges granted
PROMPT    👤 3 Users created and mapped to Roles
PROMPT ================================================================
