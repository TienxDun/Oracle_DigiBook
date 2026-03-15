# Data Dictionary

## 1. Khái niệm

**Data Dictionary **là tập hợp các bảng và view hệ thống do Oracle tự động quản lý, dùng để lưu **metadata** của database. Bao gồm:

- Thông tin về tables, columns, constraints
- User, roles, privileges
- Index, view, sequence
- Trigger, procedure, function
- Tablespace, segment, object status
- Thông tin audit, dependency, statistics
Quan trọng:

- Data Dictionary được tạo khi database được tạo
- Chỉ Oracle được phép cập nhật trực tiếp
- Người dùng chỉ được SELECT
Nó chính là "database về database".

## 2. Phân loại Data Dictionary Views

Oracle chia thành 3 nhóm chính:

### 2.1. USER_*

Thông tin các object thuộc **schema hiện tại**

Ví dụ:

- USER_TABLES
- USER_TAB_COLUMNS
- USER_CONSTRAINTS
### 2.2. ALL_*

Thông tin các object mà user có quyền truy cập

Ví dụ:

- ALL_TABLES
- ALL_TAB_COLUMNS
- ALL_OBJECTS
### 2.3. DBA_*

Thông tin toàn bộ database (cần quyền DBA)

Ví dụ:

- DBA_TABLES
- DBA_USERS
- DBA_OBJECTS
## 3. Một số truy vấn cơ bản

```SQL
# Xem tất cả bảng trong schema hiện tại

SELECT table_name
FROM user_tables;


# Xem cấu trúc cột của một bảng

SELECT column_name,
       data_type,
       data_length,
       nullable
FROM user_tab_columns
WHERE table_name='PRODUCT';


# Xem constraint của bảng

SELECT constraint_name,
       constraint_type,
       status
FROM user_constraints
WHERE table_name='PRODUCT';
```

Constraint_type:

- P = Primary key
- R = Foreign key
- U = Unique
- C = Check
```SQL
# Xem index của bảng

SELECT index_name,
       uniqueness
FROM user_indexes
WHERE table_name='PRODUCT';

# Xem tất cả object trong schema

SELECT object_name,
       object_type,
       status
FROM user_objects
ORDERBY object_type;


# Xem thông tin user (cần quyền phù hợp)
SELECT username,
       account_status,
       created
FROM dba_users;
```

