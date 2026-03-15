# Cấu trúc chương trình PL/SQL

PL/SQL (Procedural Language/SQL) là phần mở rộng của SQL, cho phép viết chương trình có cấu trúc ngay trong Oracle.

Một chương trình PL/SQL được tổ chức theo dạng **block.**

## 1. Cấu trúc tổng quát của một PL/SQL Block

```SQL
DECLARE
-- Phần khai báo
BEGIN
-- Phần thực thi
EXCEPTION
-- Phần xử lý ngoại lệ
END;
/
```

Một block có thể có:

- Phần khai báo (DECLARE) – tùy chọn
- Phần thực thi (BEGIN…END) – bắt buộc
- Phần ngoại lệ (EXCEPTION) – tùy chọn
## 2. Phần khai báo (DECLARE)

Dùng để khai báo:

- Biến
- Hằng số
- Cursor
- Exception
- Record
- Kiểu dữ liệu
Ví dụ:

```SQL
DECLARE
   v_name     VARCHAR2(50);
   v_salary   NUMBER(10,2);
   c_bonus    CONSTANT NUMBER :=1000;
```

Đặc điểm:

- Mỗi biến phải có kiểu dữ liệu
- Có thể gán giá trị ban đầu bằng `:=`
- Hằng số dùng từ khóa `CONSTANT`
## 3. Phần thực thi (BEGIN … END)

Đây là phần bắt buộc.

Chứa:

- Câu lệnh SQL
- Lệnh gán
- Cấu trúc điều khiển (IF, LOOP, CASE)
- Gọi procedure / function
Ví dụ:

```SQL
BEGIN
SELECT salary
INTO v_salary
FROM employees
WHERE employee_id=100;

   DBMS_OUTPUT.PUT_LINE('Salary: '|| v_salary);
END;
/
```

Lưu ý:

- `SELECT` trong PL/SQL phải dùng `INTO`
- Có thể kết hợp nhiều câu lệnh
## 4. Phần xử lý ngoại lệ (EXCEPTION)

Dùng để xử lý lỗi phát sinh trong quá trình thực thi.

Ví dụ:

```SQL
EXCEPTION
WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No employee found');
WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE('More than one row returned');
WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Unknown error');
```

Một số ngoại lệ phổ biến:

- `NO_DATA_FOUND`
- `TOO_MANY_ROWS`
- `ZERO_DIVIDE`
- `VALUE_ERROR`
## 5. Ví dụ

```SQL
SET SERVEROUTPUT ON;

DECLARE
   v_last_name employees.last_name%TYPE;
BEGIN
   SELECT last_name
   INTO v_last_name
   FROM employees
   WHERE employee_id = 100;

   DBMS_OUTPUT.PUT_LINE('Employee: ' || v_last_name);

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/
```

## 6. Đặc điểm quan trọng của PL/SQL Block

### 6.1. Có thể lồng block (Nested Block)

```SQL
BEGIN
  DECLARE
      v_test NUMBER :=10;
  BEGIN
      DBMS_OUTPUT.PUT_LINE(v_test);
	END;
END;
/
```

---

#### 6.2. Scope (Phạm vi biến)

- Biến khai báo trong block chỉ dùng được trong block đó
- Block trong có thể truy cập biến của block ngoài
#### 6.3. Thực thi trên Server

Khác với SQL thuần:

- SQL chỉ xử lý truy vấn
- PL/SQL chạy như một chương trình hoàn chỉnh trên server
## 7. Mô hình thực thi

Ứng dụng → Gửi block PL/SQL → Oracle Server xử lý toàn bộ → Trả kết quả

Điều này giúp:

- Giảm round-trip giữa client và server
- Tăng hiệu năng
- Gom nhiều thao tác vào một transaction
## 8. Phân loại PL/SQL Block

1. Anonymous Block
1. Named Block
