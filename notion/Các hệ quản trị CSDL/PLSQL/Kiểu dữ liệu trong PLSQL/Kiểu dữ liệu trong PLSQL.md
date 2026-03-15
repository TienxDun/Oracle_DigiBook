# Kiểu dữ liệu trong PL/SQL

```Plain Text
PL/SQL Data Types
│
├── Scalar
│   ├── NUMBER
│   ├── PLS_INTEGER
│   ├── VARCHAR2
│   ├── DATE
│   └── BOOLEAN
│
├── Anchored
│   ├── %TYPE
│   └── %ROWTYPE
│
├── Composite
│   ├── RECORD
│   ├── Associative Array
│   ├── Nested Table
│   └── VARRAY
│
└── Reference
    └── REF CURSOR
```

## 1. Scalar Data Types (Kiểu đơn trị)

### 1.1. Numeric Types

#### 1.1.1. NUMBER(p,s)

- Chính xác tuyệt đối (decimal arithmetic)
- Tối đa 38 chữ số
- Dùng cho tài chính
```SQL
v_salary NUMBER(10,2);
```

#### 1.1.2. PLS_INTEGER

- Số nguyên
- Tối ưu hiệu năng hơn NUMBER
- Thao tác bằng CPU native arithmetic
```SQL
v_count PLS_INTEGER;
```

👉 Khuyến nghị:

- Dùng `PLS_INTEGER` cho biến đếm, loop counter
- Dùng `NUMBER` khi cần độ chính xác thập phân
#### 1.1.3. BINARY_INTEGER (legacy)

Hiện nay nên dùng `PLS_INTEGER` thay thế.

### 1.2. Character Types

#### 1.2.1. VARCHAR2(n)

- Chuỗi biến độ dài
- Phổ biến nhất
```SQL
v_name VARCHAR2(100);
```

#### 1.2.2. CHAR(n)

- Độ dài cố định
- Tốn bộ nhớ hơn
#### 1.2.3. NCHAR / NVARCHAR2

- Unicode
- Quan trọng khi xử lý đa ngôn ngữ
### 1.3. Boolean (Chỉ tồn tại trong PL/SQL)

SQL không có BOOLEAN, nhưng PL/SQL có:

```SQL
v_flag BOOLEAN;
```

Giá trị:

- TRUE
- FALSE
- NULL
Không thể dùng trực tiếp trong SQL statement.

### 1.4. Date & Time

#### 1.4.1. DATE

- Lưu ngày + giờ
#### 1.4.2. TIMESTAMP

- Có fractional seconds
```SQL
v_created DATE := SYSDATE;
```

## 2. Anchored Data Types (%TYPE, %ROWTYPE)

### 2.1. %TYPE

Cho phép biến kế thừa kiểu dữ liệu của một cột.

```SQL
v_salary employees.salary%TYPE;
```

Lợi ích:

- Nếu schema thay đổi → không cần sửa code
- Tránh mismatch datatype
👉 Đây là best practice trong PL/SQL.

### 2.2. %ROWTYPE

Cho phép biến đại diện cho một dòng dữ liệu.

```SQL
v_emp employees%ROWTYPE;
```

Có thể truy cập:

```Plain Text
v_emp.salary
v_emp.last_name
```

Dùng khi SELECT nhiều cột.

## 3. Composite Types (Kiểu phức hợp)

### 3.1. RECORD

Giống struct trong C.

```SQL
TYPE emp_recordIS RECORD (
   id NUMBER,
   name VARCHAR2(50)
);

v_emp emp_record;
```

### 3.2. Collections

PL/SQL có 3 loại collection:

#### 3.2.1. Associative Array (Index-by Table)

```SQL
TYPE num_table IS TABLE OF NUMBER
INDEXBY PLS_INTEGER;
```

- Không cần khởi tạo trước
- Không lưu trong DB
- Dùng trong memory
#### 3.2.2. Nested Table

```SQL
TYPE num_list IS TABLE OF NUMBER;
```

- Có thể lưu xuống DB
- Phải khởi tạo
#### 3.2.3. VARRAY

```SQL
TYPE num_array IS VARRAY(10)OF NUMBER;
```

- Có giới hạn kích thước cố định
## 4. LOB Types

- BLOB
- CLOB
- NCLOB
Dùng cho dữ liệu lớn.

## 5. Cursor-related Types

`REF CURSOR` cho phép trả về result set động.

```SQL
TYPE ref_cursor_type IS REF CURSOR;
```

Dùng nhiều trong API.

## 6. Subtypes

PL/SQL cho phép tạo subtype:

```SQL
SUBTYPE small_int IS NUMBER(5);
```

Giúp tăng tính semantic clarity.

## 7. NULL & Default Initialization

- Biến mặc định = NULL
- Có thể gán giá trị ban đầu bằng `:=`
```SQL
v_count NUMBER := 0;
```

