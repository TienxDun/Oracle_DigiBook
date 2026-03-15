# View

### 1. Khái niệm

`View` là một bảng ảo (virtual table):

- Được định nghĩa bởi một câu lệnh `SELECT`
- Không lưu dữ liệu vật lý (trừ materialized view)
- Khi truy vấn view → Oracle thực thi lại câu SELECT gốc
Hiểu đơn giản: View = Stored SELECT.

## 2. Mục đích sử dụng

View thường dùng để:

1. Đơn giản hóa truy vấn phức tạp
1. Ẩn cấu trúc bảng thật
1. Giới hạn dữ liệu truy cập
1. Bảo mật theo cột / dòng
1. Tái sử dụng logic
## 3. Cú pháp tạo View

```SQL
CREATEOR REPLACEVIEW view_name AS
SELECT ...
FROM ...
WHERE ...;
```

## 4. Ví dụ

### 4.1. View đơn giản

```SQL
CREATE OR REPLACE VIEW emp_basic_info AS
SELECT employee_id,
       first_name,
       last_name,
       salary
FROM employees;
```

Truy vấn:

```SQL
SELECT * FROM emp_basic_info;
```

### 4.2. View có điều kiện

```SQL
CREATE OR REPLACE VIEW high_salary_emp AS
SELECT employee_id,
       first_name,
       salary
FROM employees
WHERE salary > 10000;
```

### 4.3. View có JOIN

```SQL
CREATE OR REPLACE VIEW emp_with_dept AS
SELECT e.employee_id,
       e.first_name,
       d.department_name,
       e.salary
FROM employees e
JOIN departments d
ON e.department_id= d.department_id;
```

Truy vấn:

```SQL
SELECT * FROM emp_with_dept;
```

## 5. View có thể UPDATE không?

### 5.1. Updatable View

View có thể cập nhật nếu:

- Chỉ dựa trên 1 bảng
- Không có GROUP BY
- Không có DISTINCT
- Không có aggregate
- Không có JOIN phức tạp
Ví dụ:

```SQL
UPDATE emp_basic_info
SET salary= salary*1.1
WHERE employee_id=100;
```

→ Oracle sẽ update bảng employees.

### 5.2. Non-updatable View

Ví dụ có GROUP BY:

```SQL
CREATE OR REPLACE VIEW dept_avg_salary AS
SELECT department_id,
       AVG(salary) avg_salary
FROM employees
GROUP BY department_id;
```

Không thể:

```Plain Text
UPDATE dept_avg_salary ...
```

## 6. WITH CHECK OPTION

Ngăn người dùng insert/update vượt khỏi điều kiện view.

```SQL
CREATE OR REPLACE VIEW dept60_emp AS
SELECT*
FROM employees
WHERE department_id=60
WITH CHECKOPTION;
```

Nếu cố:

```Plain Text
UPDATE dept60_emp
SET department_id=90
WHERE employee_id=103;
```

→ Bị chặn.

## 7. WITH READ ONLY

```SQL
CREATE OR REPLACE VIEW emp_readonly AS
SELECT employee_id, first_name
FROM employees
WITH READ ONLY;
```

Không thể UPDATE/DELETE.

## 8. View và Bảo mật

Có thể:

```Plain Text
GRANT SELECTON emp_basic_info TO hr_user;
```

User chỉ thấy cột trong view, không thấy bảng gốc.

## 9. View vs Materialized View

## 10. View và Data Dictionary

Xem view:

```SQL
SELECT view_name
FROM user_views;
```

Xem nội dung:

```SQL
SELECT text
FROM user_views
WHERE view_name='EMP_BASIC_INFO';
```

## 11. View và Dependency

Nếu thay đổi bảng gốc → View có thể bị INVALID

Kiểm tra:

```SQL
SELECT object_name, status
FROM user_objects
WHERE object_type='VIEW';
```

## 12. INSTEAD OF Trigger trên View

Nếu view không updatable. Có thể dùng:

```SQL
INSTEAD OF INSERT/UPDATE/DELETE
```

để điều khiển thao tác.

## 13 Best Practices

✅ Dùng view để:

- Che giấu cấu trúc
- Tạo abstraction layer
- Phân quyền
❌ Không nên:

- Lồng quá nhiều view
- Tạo view phức tạp gây chậm
