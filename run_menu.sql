SET VERIFY OFF
SET DEFINE ON

PROMPT =============================================
PROMPT MENU TRIỂN KHAI DIGIBOOK (ORACLE)
PROMPT =============================================
PROMPT [0] Reset schema                  -> 0_reset_schema.sql
PROMPT [1] Tao bang + sequence + trigger -> 2_create_tables.sql
PROMPT [2] Nap du lieu mau               -> 3_insert_data.sql
PROMPT [3] Tao stored procedures         -> 4_procedures.sql
PROMPT [4] Tao triggers nghiep vu        -> 5_triggers.sql
PROMPT [5] Tao views/materialized view   -> 6_views.sql
PROMPT [6] Tao index + tuning            -> 7_indexes_and_tuning.sql
PROMPT [7] Bao mat/phan quyen (SYS)      -> 8_security_roles.sql
PROMPT [8] Transaction demo              -> 9_transaction_demo.sql
PROMPT [9] Chay nhanh buoc 2 -> 7 (de xong schema chinh)
PROMPT ---------------------------------------------
PROMPT Luong khuyen nghi: 9 -> (dang nhap SYS chay 7) -> 8
PROMPT =============================================

ACCEPT menu_choice CHAR PROMPT 'Nhap lua chon (0-9): '

PROMPT
PROMPT Dang thuc thi lua chon: &&menu_choice
PROMPT

@@run_&&menu_choice..sql

PROMPT
PROMPT Hoan tat menu.
PROMPT
