/*
================================================================================
  RESET TOAN BO OBJECT TRONG SCHEMA HIEN TAI
  Muc dich : Don dep schema de chay lai tu Buoc 2
  Cach chay: Mo file trong SQL Developer va nhan F5
  Luu y   : Script nay chi xoa object trong USER hien tai, KHONG xoa ca database.
================================================================================
*/

SET SERVEROUTPUT ON;

BEGIN
    FOR rec IN (
        SELECT object_name, object_type
        FROM user_objects
        WHERE object_type IN (
            'MATERIALIZED VIEW',
            'VIEW',
            'PROCEDURE',
            'FUNCTION',
            'PACKAGE',
            'TRIGGER',
            'SEQUENCE',
            'TABLE'
        )
        ORDER BY CASE object_type
            WHEN 'MATERIALIZED VIEW' THEN 1
            WHEN 'VIEW' THEN 2
            WHEN 'PROCEDURE' THEN 3
            WHEN 'FUNCTION' THEN 4
            WHEN 'PACKAGE' THEN 5
            WHEN 'TRIGGER' THEN 6
            WHEN 'SEQUENCE' THEN 7
            WHEN 'TABLE' THEN 8
            ELSE 99
        END,
        object_name
    ) LOOP
        BEGIN
            IF rec.object_type = 'TABLE' THEN
                EXECUTE IMMEDIATE 'DROP TABLE "' || rec.object_name || '" CASCADE CONSTRAINTS PURGE';
            ELSIF rec.object_type = 'VIEW' THEN
                EXECUTE IMMEDIATE 'DROP VIEW "' || rec.object_name || '"';
            ELSIF rec.object_type = 'MATERIALIZED VIEW' THEN
                EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW "' || rec.object_name || '"';
            ELSIF rec.object_type = 'PROCEDURE' THEN
                EXECUTE IMMEDIATE 'DROP PROCEDURE "' || rec.object_name || '"';
            ELSIF rec.object_type = 'FUNCTION' THEN
                EXECUTE IMMEDIATE 'DROP FUNCTION "' || rec.object_name || '"';
            ELSIF rec.object_type = 'PACKAGE' THEN
                EXECUTE IMMEDIATE 'DROP PACKAGE "' || rec.object_name || '"';
            ELSIF rec.object_type = 'TRIGGER' THEN
                EXECUTE IMMEDIATE 'DROP TRIGGER "' || rec.object_name || '"';
            ELSIF rec.object_type = 'SEQUENCE' THEN
                EXECUTE IMMEDIATE 'DROP SEQUENCE "' || rec.object_name || '"';
            END IF;

            DBMS_OUTPUT.PUT_LINE('DA XOA: ' || rec.object_type || ' - ' || rec.object_name);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('KHONG XOA DUOC: ' || rec.object_type || ' - ' || rec.object_name || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

PROMPT ================================================
PROMPT DA HOAN TAT DON DEP SCHEMA HIEN TAI
PROMPT Bay gio co the chay lai tu 2_create_tables.sql
PROMPT ================================================

SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
GROUP BY object_type
ORDER BY object_type;