# Exception

```SQL
Exception Handling
│
├── Predefined
│   ├── NO_DATA_FOUND
│   ├── TOO_MANY_ROWS
│   ├── ZERO_DIVIDE
│   └── VALUE_ERROR
│
├── User-defined
│   ├── DECLARE e_name EXCEPTION
│   └── RAISE
│
└── RAISE_APPLICATION_ERROR
```

## 1. Khái niệm

`Exception` là cơ chế xử lý lỗi trong PL/SQL.

Khi một lỗi xảy ra trong phần `BEGIN`, luồng thực thi:

1. Dừng ngay tại vị trí lỗi
1. Chuyển xuống phần `EXCEPTION`
1. Tìm handler phù hợp
1. Thực thi handler
1. Kết thúc block
Nếu không có handler phù hợp → lỗi được propagate ra ngoài.

## 2. Cấu trúc chuẩn

```SQL
BEGIN
-- statements
EXCEPTION
WHEN exception_name THEN
-- xử lý lỗi
END;
/
```

## 3. Phân loại Exception

### 3.1. Predefined Exceptions (Oracle định nghĩa sẵn)

Oracle đã khai báo sẵn trong package STANDARD.

Một số quan trọng:

### 3.2. Ví dụ

```SQL
--  1. NO_DATA_FOUND

SET SERVEROUTPUT ON;

DECLARE
    v_name employees.last_name%TYPE;
    
BEGIN
    SELECT last_name
    INTO v_name
    FROM employees
    WHERE employee_id=-1;

    DBMS_OUTPUT.PUT_LINE(v_name);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/


-- 2. TOO_MANY_ROWS

DECLARE
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary
    INTO v_salary
    FROM employees
    WHERE department_id=60;

    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('More than one employee found');
END;
/


-- ZERO_DIVIDE

DECLARE
   v_result NUMBER;
BEGIN
   v_result :=100/0;

    EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot divide by zero');
END;
/

```

## 4. User-Defined Exceptions

Khi logic nghiệp vụ cần tự tạo lỗi.

### 4.1. Khai báo exception

```SQL
DECLARE
   e_low_salary EXCEPTION;
```

### 4.2. Raise exception

```SQL
RAISE e_low_salary;
```

### 4.3. Ví dụ HR: kiểm tra lương tối thiểu

```SQL
DECLARE
   v_salary employees.salary%TYPE;
   e_low_salary EXCEPTION;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id=104;

    IF v_salary<8000 THEN
        RAISE e_low_salary;
    END IF;

    EXCEPTION
    WHEN e_low_salary THEN
        DBMS_OUTPUT.PUT_LINE('Salary too low');
END;
/
```

## 5. RAISE_APPLICATION_ERROR

Dùng để trả lỗi có mã số cụ thể. Cú pháp:

```SQL
RAISE_APPLICATION_ERROR(error_number, message);
```

- error_number: từ -20000 đến -20999
- message: nội dung lỗi
Ví dụ HR: không cho giảm lương dưới mức tối thiểu

```SQL
DECLARE
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id=104;

    IF v_salary<10000 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary below minimum threshold');
    END IF;
END;
/
```

## 6. WHEN OTHERS

Bắt tất cả lỗi chưa được xử lý.

```SQL
EXCEPTION
WHEN OTHERSTHEN
      DBMS_OUTPUT.PUT_LINE('Unexpected error');
```

⚠ Lưu ý quan trọng:

- WHEN OTHERS nên đặt cuối cùng
- Có thể dùng SQLCODE, SQLERRM để lấy thông tin lỗi
Ví dụ ghi log lỗi

```SQL
EXCEPTION
WHEN OTHERSTHEN
      DBMS_OUTPUT.PUT_LINE('Error code: '|| SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error message: '|| SQLERRM);
```

## 7. Propagation (Lan truyền lỗi)

Nếu không bắt lỗi:

- Lỗi sẽ propagate ra block ngoài
- Nếu không ai bắt → hiển thị lỗi Oracle
Ví dụ nested block:

```SQL
DECLARE
    v_result NUMBER;
BEGIN
    BEGIN
        v_result :=10/0;
    END;
    EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Handled in outer block');
END;
/
```

