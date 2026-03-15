# Package

```SQL
Package
│
├── Specification (public API)
│   ├── Procedure
│   ├── Function
│   ├── Variable
│   └── Type
│
└── Body (implementation)
    ├── Code
    ├── Private logic
    └── Initialization block
```

### 1. Khái niệm

**Package** là một cấu trúc dùng để:

- Nhóm nhiều procedure, function, biến, type, cursor
- Đóng gói (encapsulation) logic nghiệp vụ
- Tách phần giao diện (specification) và phần cài đặt (body)
Có thể hiểu: Package giống như một “module” hoặc “namespace” trong lập trình.

## 2. Cấu trúc của Package

Package gồm 2 phần:

1. Package Specification (Spec)
1. Package Body
## 3. Cú pháp tổng quát

Package Specification

```SQL
CREATE OR REPLACE PACKAGE package_name AS

-- public declarations
PROCEDURE proc_name;
FUNCTION func_nameRETURN NUMBER;

END package_name;
/
```

Package Body

```SQL
CREATE OR REPLACE PACKAGE BODY package_name AS

PROCEDURE proc_name AS
BEGIN
	NULL;
END;

FUNCTION func_name RETURN NUMBER AS
BEGIN
	RETURN 1;
END;

END package_name;
/
```

## 4. Ví dụ

🎯 Mục tiêu: Tạo package quản lý lương.

1. Tạo Package Specification

```SQL
CREATE OR REPLACE PACKAGE hr_salary_pkg AS

-- Biến public
   g_bonus_percent NUMBER :=10;

-- Function tính lương mới
FUNCTION calculate_raise
      (p_salary IN NUMBER)
RETURN NUMBER;

-- Procedure tăng lương
PROCEDURE raise_employee
      (p_emp_id IN NUMBER); 

END hr_salary_pkg;
/
```

2. Tạo Package Body

```SQL
CREATE OR REPLACE PACKAGE BODY hr_salary_pkg AS
    -- Function implementation
    FUNCTION calculate_raise
        (p_salary IN NUMBER)
    RETURN NUMBER
    AS
    BEGIN
        RETURN p_salary * (1+ g_bonus_percent/100);
    END calculate_raise;

    -- Procedure implementation
    PROCEDURE raise_employee
        (p_emp_id IN NUMBER)
    AS
        v_salary employees.salary%TYPE;
    BEGIN
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id= p_emp_id;

        v_salary := calculate_raise(v_salary);

        UPDATE employees
        SET salary= v_salary
        WHERE employee_id= p_emp_id;

        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Employee not found');
    END raise_employee;

END hr_salary_pkg;
/
```

## 5. Gọi Package

```SQL
BEGIN
   hr_salary_pkg.raise_employee(100);
END;
/
```

Hoặc dùng function trong SQL:

```SQL
SELECT first_name,
       hr_salary_pkg.calculate_raise(salary) AS new_salary
FROM employees;
```

## 6. Public vs Private trong Package

- Public: Khai báo trong specification → bên ngoài gọi được.
- Private: Chỉ khai báo trong body → bên ngoài không truy cập được.
### Ví dụ Private Function

```SQL
CREATE OR REPLACE PACKAGE BODY hr_salary_pkg AS

FUNCTION internal_round
      (p_valueIN NUMBER)
RETURN NUMBER
AS
	BEGIN
		RETURN ROUND(p_value,2);
	END;

END hr_salary_pkg;
/
```

Function này không thể gọi từ ngoài.

## 7. Biến toàn cục trong Package

Biến khai báo trong spec:

```SQL
g_bonus_percent NUMBER :=10;
```

Có thể thay đổi:

```SQL
BEGIN
   hr_salary_pkg.g_bonus_percent :=15;
END;
/
```

⚠ Lưu ý: giá trị chỉ tồn tại trong session.

## 8. Ưu điểm của Package

## 9. Package Initialization

Có thể có khối BEGIN ở cuối package body:

```SQL
BEGIN
   DBMS_OUTPUT.PUT_LINE('Package loaded');
END hr_salary_pkg;
/
```

Khối này chạy khi package được load lần đầu trong session.

## 10. So sánh Procedure đơn lẻ vs Package

## 11. Data Dictionary

Kiểm tra package:

```SQL
SELECT object_name, status
FROM user_objects
WHERE object_type='PACKAGE';
```

Xem source:

```SQL
SELECT text
FROM user_source
WHERE name='HR_SALARY_PKG'
ORDER BY line;
```

