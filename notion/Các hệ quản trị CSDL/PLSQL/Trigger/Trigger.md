# Trigger

```SQL
Trigger
│
├── BEFORE / AFTER
├── Statement-level
├── Row-level (:NEW / :OLD)
├── INSTEAD OF
└── Compound Trigger
```

## 1. Khái niệm

**Trigger** là một khối PL/SQL:

- Được gắn với một bảng hoặc view
- Tự động thực thi khi xảy ra sự kiện DML
- Không cần gọi thủ công
Trigger dùng để:

- Kiểm soát toàn vẹn dữ liệu
- Audit thay đổi
- Tự động hóa nghiệp vụ
- Bảo vệ dữ liệu
## 2. Phân loại Trigger

### 2.1. Theo thời điểm

### 2.2. Theo phạm vi

Row-level phải dùng:

```SQL
FOR EACH ROW
```

## 3. Cú pháp tổng quát

```SQL
CREATE OR REPLACE TRIGGER trigger_name
BEFORE|AFTER
INSERT|UPDATE|DELETE
ON table_name
[FOR EACH ROW]
BEGIN
-- code
END;
/
```

## 4. Pseudorecord :NEW và :OLD

Chỉ dùng trong row-level trigger.

Ví dụ:

- INSERT → chỉ có :NEW
- DELETE → chỉ có :OLD
- UPDATE → có cả hai
## 5. Ví dụ

### 5.1. Kiểm soát không cho giảm lương

```SQL
CREATE OR REPLACE TRIGGER prevent_salary_decrease
BEFORE UPDATE OF salary
ON employees
FOR EACH ROW
BEGIN
    IF :NEW.salary < :OLD.salary THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Salary cannot be decreased'
        );
    END IF;
END;
/
```

Nếu cố:

```SQL
UPDATE employees
SET salary = 1000
WHERE employee_id = 100;
```

→ Bị chặn.

### 5.2. Audit thay đổi lương

Tạo bảng log

```SQL
CREATE TABLE salary_audit (
   emp_id NUMBER,
   old_salary NUMBER,
   new_salary NUMBER,
   changed_at DATE
);
```

Tạo trigger

```SQL
CREATE OR REPLACE TRIGGER log_salary_change
AFTER UPDATE OF salary
ON employees
FOR EACH ROW
BEGIN
INSERT INTO salary_audit
VALUES (
      :OLD.employee_id,
      :OLD.salary,
      :NEW.salary,
      SYSDATE
   );
END;
/
```

```SQL
-- Update
UPDATE employees
SET salary = 10000
WHERE employee_id = 104;

-- Check audit
SELECT *
FROM SALARY_AUDIT;
```

### 5.3. Statement-level trigger

```SQL
CREATE OR REPLACE TRIGGER log_bulk_update
AFTER UPDATE ON employees
BEGIN
   DBMS_OUTPUT.PUT_LINE('Employees table updated');
END;
/
```

Chạy 1 lần cho cả câu lệnh.

### 5.4. INSTEAD OF Trigger (trên View)

Tạo view

```SQL
CREATE OR REPLACE VIEW emp_view AS
SELECT employee_id, first_name, salary
FROM employees;
```

Trigger

```SQL
CREATE OR REPLACE TRIGGER emp_view_insert
INSTEAD OF INSERT ON emp_view
FOR EACH ROW
BEGIN
INSERT INTO employees
   (employee_id, first_name, salary)
VALUES
   (:NEW.employee_id, :NEW.first_name, :NEW.salary);
END;
/
```

## 6. Trigger và Mutating Table Error

Lỗi phổ biến:

```Plain Text
ORA-04091: table is mutating
```

Xảy ra khi:

- Row-level trigger
- Truy vấn lại chính bảng đang bị update
Ví dụ sai:

```SQL
SELECT COUNT(*)
FROM employees;
```

Trong trigger employees.

## 7️⃣ Compound Trigger (Oracle 11g+)

Giải quyết mutating table.

```SQL
CREATE OR REPLACE TRIGGER emp_compound
FOR UPDATE ON employees
COMPOUND TRIGGER

BEFORE STATEMENT IS
BEGIN
    NULL;
END BEFORE STATEMENT;

BEFORE EACH ROW IS
    BEGIN
        NULL;
END BEFORE EACH ROW;

AFTER STATEMENT IS
    BEGIN
        NULL;
END AFTER STATEMENT;

END;
/
```

## 8. Data Dictionary kiểm tra Trigger

```SQL
SELECT trigger_name, status
FROM user_triggers;
```

Xem source:

```SQL
SELECT text
FROM user_source
WHERE type='TRIGGER'
AND name='PREVENT_SALARY_DECREASE'
ORDER BY line;
```

## 9. So sánh Trigger vs Procedure

