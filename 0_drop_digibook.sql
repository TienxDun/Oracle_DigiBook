-- Drops all objects in the DIGIBOOK schema (Oracle 19c).
-- Run this while connected as DIGIBOOK (or a DBA with appropriate privileges).

SET SERVEROUTPUT ON
SET FEEDBACK ON

DECLARE
  PROCEDURE exec_ddl(p_sql VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_sql);
    EXECUTE IMMEDIATE p_sql;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FAILED: ' || p_sql || ' => ' || SQLERRM);
  END;
BEGIN
  -- Drop materialized views first (dependencies)
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'MATERIALIZED VIEW'
  ) LOOP
    exec_ddl('DROP MATERIALIZED VIEW "' || r.object_name || '"');
  END LOOP;

  -- Drop views
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'VIEW'
  ) LOOP
    exec_ddl('DROP VIEW "' || r.object_name || '"');
  END LOOP;

  -- Drop synonyms
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'SYNONYM'
  ) LOOP
    exec_ddl('DROP SYNONYM "' || r.object_name || '"');
  END LOOP;

  -- Drop sequences
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'SEQUENCE'
  ) LOOP
    exec_ddl('DROP SEQUENCE "' || r.object_name || '"');
  END LOOP;

  -- Drop tables (including constraints)
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'TABLE'
  ) LOOP
    exec_ddl('DROP TABLE "' || r.object_name || '" CASCADE CONSTRAINTS PURGE');
  END LOOP;

  -- Drop types
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'TYPE'
  ) LOOP
    exec_ddl('DROP TYPE "' || r.object_name || '" FORCE');
  END LOOP;

  -- Drop packages
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'PACKAGE'
  ) LOOP
    exec_ddl('DROP PACKAGE "' || r.object_name || '"');
  END LOOP;

  -- Drop functions
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'FUNCTION'
  ) LOOP
    exec_ddl('DROP FUNCTION "' || r.object_name || '"');
  END LOOP;

  -- Drop procedures
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'PROCEDURE'
  ) LOOP
    exec_ddl('DROP PROCEDURE "' || r.object_name || '"');
  END LOOP;

  -- Drop triggers
  FOR r IN (
    SELECT object_name
    FROM user_objects
    WHERE object_type = 'TRIGGER'
  ) LOOP
    exec_ddl('DROP TRIGGER "' || r.object_name || '"');
  END LOOP;
END;
/

PROMPT Done. All objects in DIGIBOOK schema should be dropped.
