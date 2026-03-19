    -- Lists all objects in the DIGIBOOK schema (Oracle 19c).
    -- Run this while connected as DIGIBOOK (or a DBA with access to USER_OBJECTS).

    SET PAGESIZE 200
    SET LINESIZE 200
    SET FEEDBACK ON

    COLUMN object_type FORMAT A24
    COLUMN object_name FORMAT A40
    COLUMN status FORMAT A10

    PROMPT === ALL OBJECTS (USER_OBJECTS) ===
    SELECT object_type,
        object_name,
        status
    FROM   user_objects
    ORDER  BY object_type, object_name;

    PROMPT === TABLES ===
    SELECT table_name
    FROM   user_tables
    ORDER  BY table_name;

    PROMPT === TRIGGERS ===
    SELECT trigger_name,
        status,
        triggering_event,
        table_name
    FROM   user_triggers
    ORDER  BY trigger_name;

    PROMPT === PROCEDURES ===
    SELECT object_name
    FROM   user_objects
    WHERE  object_type = 'PROCEDURE'
    ORDER  BY object_name;

    PROMPT === FUNCTIONS ===
    SELECT object_name
    FROM   user_objects
    WHERE  object_type = 'FUNCTION'
    ORDER  BY object_name;

    PROMPT === PACKAGES ===
    SELECT object_name
    FROM   user_objects
    WHERE  object_type = 'PACKAGE'
    ORDER  BY object_name;

    PROMPT === VIEWS ===
    SELECT object_name
    FROM   user_objects
    WHERE  object_type = 'VIEW'
    ORDER  BY object_name;

    PROMPT === SEQUENCES ===
    SELECT sequence_name
    FROM   user_sequences
    ORDER  BY sequence_name;

    PROMPT === SYNONYMS ===
    SELECT synonym_name
    FROM   user_synonyms
    ORDER  BY synonym_name;

    PROMPT === TYPES ===
    SELECT object_name
    FROM   user_objects
    WHERE  object_type = 'TYPE'
    ORDER  BY object_name;

    PROMPT === MATERIALIZED VIEWS ===
    SELECT mview_name
    FROM   user_mviews
    ORDER  BY mview_name;
