# Function

### 1.  Khái niệm

**Function** là một chương trình PL/SQL:

- Được lưu trữ trong database
- Có thể nhận tham số
- **Bắt buộc phải trả về đúng một giá trị**
- Có thể được sử dụng trong biểu thức SQL
Điểm khác biệt quan trọng so với Procedure:

> Function trả về giá trị bằng `RETURN`.

## 2. Cú pháp tổng quát

```SQL
CREATE OR REPLACE FUNCTION function_name
   (parameter_list)
RETURN return_datatype
AS
-- khai báo
BEGIN
-- xử lý
RETURN value;
EXCEPTION
-- xử lý lỗi
END function_name;
/
```

## 3. Ví dụ cơ bản

Ví dụ 1: Lấy lương nhân viên

```SQL
CREATE OR REPLACE FUNCTION get_salary
   (p_emp_id IN NUMBER)
RETURN NUMBER
AS
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary
    INTO v_salary
    FROM employees
    WHERE employee_id= p_emp_id;

    RETURN v_salary;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END;
/
```

Gọi trong PL/SQL

```SQL
DECLARE
    v_salary employees.salary%TYPE;
BEGIN
    v_salary := GET_SALARY(104);
    DBMS_OUTPUT.PUT_LINE('The salary of employee 104 is: ' || v_salary);
END;
```

## 4. Function dùng trong SQL

> 💡 

```SQL
SELECT employee_id,
       get_salary(employee_id) AS salary_value
FROM employees
WHERE department_id=60;
```

Oracle sẽ gọi function cho từng dòng.

⚠ Lưu ý: Function phải tuân thủ quy tắc SQL (không commit/rollback).

## 5. So sánh Function và Procedure

## 6. Function có nhiều RETURN

```SQL
CREATE OR REPLACE FUNCTION is_high_salary
   (p_salary IN NUMBER)
RETURN VARCHAR2
AS
BEGIN
    IF p_salary > 10000 THEN
        RETURN 'YES';
    END IF;
    RETURN 'NO';
END;
/
```

Quan trọng: Mọi nhánh phải có RETURN, nếu không sẽ lỗi: *Function returned without value*.

## 7. Function với Exception

```SQL
CREATE OR REPLACE FUNCTION get_employee_name
   (p_emp_id IN NUMBER)
RETURN VARCHAR2
AS
   v_name employees.last_name%TYPE;
BEGIN
    SELECT last_name INTO v_name
    FROM employees
    WHERE employee_id= p_emp_id;

    RETURN v_name;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RETURN'Unknown';
END;
/
```

## 8. Hạn chế khi dùng Function trong SQL

Function dùng trong SQL:

- Không được COMMIT / ROLLBACK
- Không được DML nếu không có AUTONOMOUS TRANSACTION
- Phải đảm bảo deterministic behavior (nếu dùng trong index/function-based index)
## 9. Deterministic Function

Cho phép Oracle tối ưu hóa:

```Plain Text
CREATE OR REPLACE FUNCTION salary_grade
   (p_salary IN NUMBER)
RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
    IF p_salary>=10000 THEN
    RETURN'High';
    ELSE
        RETURN'Low';
    END IF;
END;
/
```

Oracle có thể cache kết quả.

## 10. Function vs Inline SQL

Ví dụ không cần function:

```SQL
SELECT first_name,
    CASE
    WHEN salary>10000 THEN 'High'
    ELSE 'Low'
    END AS grade
FROM employees;
```

→ Nhanh hơn so với gọi function cho từng dòng.

## 11. Data Dictionary kiểm tra Function

```SQL
SELECT object_name, status
FROM user_objects
WHERE object_type='FUNCTION';
```

Xem source:

```SQL
SELECT text
FROM user_source
WHERE name ='GET_SALARY'
ORDER BY line;
```

## 12. Best Practice

