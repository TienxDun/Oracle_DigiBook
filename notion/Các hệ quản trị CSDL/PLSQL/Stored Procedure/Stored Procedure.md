# Stored Procedure

## 1. Khái niệm

`Stored Procedure` là một chương trình PL/SQL được:

- Lưu trữ trong database
- Biên dịch sẵn
- Có thể được gọi lại nhiều lần
- Chạy trực tiếp trên Oracle Server
Nó giúp:

- Tái sử dụng logic
- Giảm round-trip giữa client và server
- Bảo mật logic nghiệp vụ
- Kiểm soát transaction
## 2. Cú pháp tổng quát

```SQL
CREATEOR REPLACE PROCEDURE procedure_name
   (parameter_list)
AS
-- khai báo
BEGIN
-- xử lý
EXCEPTION
-- xử lý lỗi
END procedure_name;
/
```

## 3. Procedure không có tham số

```SQL
-- Ví dụ HR: tăng 5% lương phòng 60

CREATE OR REPLACE PROCEDURE raise_salary_dept60
AS
BEGIN
	UPDATE employees
	SET salary= salary*1.05
	WHERE department_id=60;

	COMMIT;
END;
/
```

Gọi procedure

```SQL
BEGIN
   raise_salary_dept60;
END;
/
```

Hoặc:

```SQL
EXEC raise_salary_dept60;
```

## 4. Procedure có tham số

### 4.1. Tham số IN

```SQL
CREATE OR REPLACE PROCEDURE raise_salary_dept
   (p_dept_id IN NUMBER)
AS
BEGIN
    UPDATE employees
    SET salary = salary*1.1
    WHERE department_id = p_dept_id;

    COMMIT;
END;
/
```

Gọi:

```SQL
EXEC raise_salary_dept(90);
```

### 4.2. Tham số OUT

Trả kết quả ra ngoài.

```SQL
CREATE OR REPLACE PROCEDURE get_salary
   (p_emp_id IN NUMBER,
    p_salary OUT NUMBER)
AS
BEGIN
    SELECT salary
    INTO p_salary
    FROM employees
    WHERE employee_id= p_emp_id;
END;
/
```

Gọi:

```SQL
DECLARE
    v_salary NUMBER;
BEGIN
    get_salary(200, v_salary);
    DBMS_OUTPUT.PUT_LINE(v_salary);
END;
/
```

### 4.3. Tham số IN OUT

```SQL
CREATE OR REPLACE PROCEDURE increase_value
   (p_value IN OUT NUMBER)
AS
BEGIN
   p_value := p_value+100;
END;
/


-- Exec

DECLARE
   v_value NUMBER := 150;
BEGIN
    increase_value(v_value);
    DBMS_OUTPUT.PUT_LINE('The increased value is: ' || v_value);
END;
/
```

## 5. Ví dụ

HR: tăng lương nhưng không cho vượt 20000

```SQL
CREATE OR REPLACE PROCEDURE safe_raise
   (p_emp_id IN NUMBER,
    p_percent IN NUMBER)
AS
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id= p_emp_id;

    v_salary := v_salary* (1+ p_percent/100);

    IF v_salary > 20000 THEN
        RAISE_APPLICATION_ERROR(-20001,'Salary exceeds limit');
    END IF;

    UPDATE employees
    SET salary= v_salary
    WHERE employee_id= p_emp_id;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
```

## 6. Data Dictionary liên quan

Sau khi tạo procedure, có thể kiểm tra:

```SQL
SELECT object_name, status
FROM user_objects
WHERE object_type='PROCEDURE';
```

Xem source code:

```SQL
SELECT text
FROM user_source
WHERE name='RAISE_SALARY_DEPT60'
ORDERBY line;
```

## 7. Cơ chế hoạt động nội bộ

Khi gọi procedure:

1. Oracle kiểm tra quyền EXECUTE
1. Load compiled code
1. Tạo execution context
1. Thực thi trên server
Ưu điểm:

- Giảm network traffic
- Giữ logic tập trung
- Tăng hiệu năng
## 8. Quyền truy cập

```SQL
GRANT EXECUTEON safe_raise TO hr_user;
```

## 9. Ưu điểm của Stored Procedure

## 10. So sánh Procedure vs Anonymous Block

