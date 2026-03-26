-- ==========================================================
-- FILE: 1_run_all_main.sql
-- Muc tieu: Chay all-in-one toan bo cac file SQL chinh cua du an DigiBook
-- Co che: Tu dong chuyen session giua APP schema va SYSDBA theo tung buoc
-- He quan tri: Oracle 19c
-- Cach chay: SQLPLUS/SQLCL => @1_run_all_main.sql
-- Luu y:
--   1. Script da gan san thong tin ket noi de khong can nhap tay.
--   2. Script se xoa va tao lai user/schema DIGIBOOK truoc khi trien khai.
--   3. Buoc 8 van duoc chay bang SYSDBA thong qua CONNECT.
-- ==========================================================

SET SERVEROUTPUT ON;
SET DEFINE ON;

PROMPT ==========================================
PROMPT SU DUNG THONG TIN KET NOI MAC DINH
PROMPT ==========================================
DEFINE APP_USER = 'Digibook'
DEFINE APP_PASSWORD = 'Digibook123'
DEFINE APP_CONNECT = 'localhost:1521/orclpdb'
DEFINE ROOT_PATH = 'C:/Users/leuti/Desktop/GitHub/Oracle_DigiBook'

DEFINE SYS_USER = 'sys'
DEFINE SYS_PASSWORD = 'sys'
DEFINE SYS_CONNECT = 'localhost:1521/orclpdb'

PROMPT APP_USER=&APP_USER
PROMPT APP_CONNECT=&APP_CONNECT
PROMPT ROOT_PATH=&ROOT_PATH
PROMPT SYS_USER=&SYS_USER
PROMPT SYS_CONNECT=&SYS_CONNECT

PROMPT ==========================================
PROMPT KHOI TAO LAI SCHEMA DIGIBOOK BANG SYSDBA
PROMPT ==========================================
CONNECT &SYS_USER/"&SYS_PASSWORD"@&SYS_CONNECT AS SYSDBA

COLUMN session_user FORMAT A30
COLUMN current_schema FORMAT A30
COLUMN current_container FORMAT A20
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;

PROMPT [PRE-STEP] Dang xoa va tao lai user DIGIBOOK ...
DECLARE
    v_con_name VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CON_NAME');
    v_exists   NUMBER;

    PROCEDURE exec_optional(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK: ' || p_sql);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('INFO: Bo qua lenh "' || p_sql || '" -> ' || SQLERRM);
    END;

    PROCEDURE exec_required(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK: ' || p_sql);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20500, 'Khong the thuc thi: ' || p_sql || ' | Loi: ' || SQLERRM);
    END;

    PROCEDURE kill_user_sessions(p_username IN VARCHAR2) IS
    BEGIN
        FOR r IN (
            SELECT sid, serial#, inst_id
            FROM gv$session
            WHERE username = UPPER(p_username)
        ) LOOP
            BEGIN
                EXECUTE IMMEDIATE
                    'ALTER SYSTEM KILL SESSION ''' || r.sid || ',' || r.serial# || ',@' || r.inst_id || ''' IMMEDIATE';
                DBMS_OUTPUT.PUT_LINE(
                    'OK: Da kill session cua ' || UPPER(p_username) ||
                    ' (SID=' || r.sid || ', SERIAL#=' || r.serial# || ', INST_ID=' || r.inst_id || ')'
                );
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(
                        'WARN: Khong kill duoc session cua ' || UPPER(p_username) ||
                        ' (SID=' || r.sid || ', SERIAL#=' || r.serial# || ', INST_ID=' || r.inst_id || ') -> ' || SQLERRM
                    );
            END;
        END LOOP;
    END;
BEGIN
    -- Dam bao dang dung trong PDB de tao local user DIGIBOOK.
    IF v_con_name = 'CDB$ROOT' THEN
        BEGIN
            EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ORCLPDB';
            DBMS_OUTPUT.PUT_LINE('INFO: Da chuyen container sang ORCLPDB.');
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ORCLPDB1';
                    DBMS_OUTPUT.PUT_LINE('INFO: Da chuyen container sang ORCLPDB1.');
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(
                            -20501,
                            'Dang o CDB$ROOT va khong the chuyen sang ORCLPDB/ORCLPDB1. Hay kiem tra lai service SYS_CONNECT hoac ten PDB. Loi: ' || SQLERRM
                        );
                END;
        END;
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: Dang o container ' || v_con_name || '.');
    END IF;

    -- Dong cac session dang dung DIGIBOOK truoc khi drop user.
    kill_user_sessions('DIGIBOOK');

    -- Xoa schema cu de dam bao moi truong sach truoc khi deploy.
    SELECT COUNT(*)
      INTO v_exists
      FROM dba_users
     WHERE username = 'DIGIBOOK';

    IF v_exists > 0 THEN
        exec_required('DROP USER DIGIBOOK CASCADE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: User DIGIBOOK khong ton tai, bo qua DROP USER.');
    END IF;

    SELECT COUNT(*)
      INTO v_exists
      FROM dba_roles
     WHERE role = 'DIGIBOOK';

    IF v_exists > 0 THEN
        exec_required('DROP ROLE DIGIBOOK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: Role DIGIBOOK khong ton tai, bo qua DROP ROLE.');
    END IF;

    -- Tao lai user schema chinh cho du an.
    exec_required('CREATE USER DIGIBOOK IDENTIFIED BY "Digibook123"');
    exec_required('ALTER USER DIGIBOOK DEFAULT TABLESPACE USERS');
    exec_required('ALTER USER DIGIBOOK TEMPORARY TABLESPACE TEMP');
    exec_required('ALTER USER DIGIBOOK QUOTA UNLIMITED ON USERS');

    -- Cap cac quyen can thiet de chay day du cac buoc 2 -> 9.
    exec_required('GRANT CREATE SESSION TO DIGIBOOK');
    exec_required('GRANT CREATE TABLE TO DIGIBOOK');
    exec_required('GRANT CREATE VIEW TO DIGIBOOK');
    exec_required('GRANT CREATE SEQUENCE TO DIGIBOOK');
    exec_required('GRANT CREATE TRIGGER TO DIGIBOOK');
    exec_required('GRANT CREATE PROCEDURE TO DIGIBOOK');
    exec_required('GRANT CREATE TYPE TO DIGIBOOK');
    exec_required('GRANT CREATE MATERIALIZED VIEW TO DIGIBOOK');
END;
/

PROMPT ==========================================
PROMPT CHUYEN SANG APP SCHEMA DIGIBOOK
PROMPT ==========================================
CONNECT &APP_USER/"&APP_PASSWORD"@&APP_CONNECT

PROMPT ==========================================
PROMPT THONG TIN SESSION APP HIEN TAI
PROMPT ==========================================
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;

PROMPT ==========================================
PROMPT DIGIBOOK MASTER RUN - BAT DAU
PROMPT Session APP se chay Bước 2 -> 7 va Bước 9
PROMPT Session SYSDBA se chay rieng Bước 8
PROMPT ==========================================

-- Neu muon reset schema truoc khi tao lai, bo comment dong duoi day:
-- @&ROOT_PATH/0_drop_digibook.sql

PROMPT [1/8] Dang chay 2_create_tables.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/2_create_tables.sql

PROMPT [2/8] Dang chay 3_insert_data.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/3_insert_data.sql
SET DEFINE ON;

PROMPT [3/8] Dang chay 4_procedures.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/4_procedures.sql

PROMPT [4/8] Dang chay 5_triggers.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/5_triggers.sql

PROMPT [5/8] Dang chay 6_views.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/6_views.sql

PROMPT [6/8] Dang chay 7_indexes_and_tuning.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/7_indexes_and_tuning.sql

PROMPT Dang chuyen session sang SYSDBA de chay Bước 8 ...
SET DEFINE ON;
CONNECT &SYS_USER/"&SYS_PASSWORD"@&SYS_CONNECT AS SYSDBA

PROMPT ==========================================
PROMPT THONG TIN SESSION SYSDBA HIEN TAI
PROMPT ==========================================
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;

PROMPT [7/8] Dang chay 8_security_roles.sql ...
PROMPT Dang chay bang SYSDBA session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/8_security_roles.sql

PROMPT Dang quay lai APP schema de chay Bước 9 ...
SET DEFINE ON;
CONNECT &APP_USER/"&APP_PASSWORD"@&APP_CONNECT

PROMPT ==========================================
PROMPT THONG TIN SESSION APP SAU KHI QUAY LAI
PROMPT ==========================================
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;

PROMPT [8/8] Dang chay 9_transaction_demo.sql ...
PROMPT Dang chay bang APP session:
SELECT
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'CON_NAME') AS current_container
FROM dual;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
@&ROOT_PATH/9_transaction_demo.sql

PROMPT ==========================================
PROMPT DIGIBOOK MASTER RUN - HOAN TAT
PROMPT ==========================================
