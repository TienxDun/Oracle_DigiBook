# WITH

Mệnh đề `WITH` trong Oracle dùng để tạo `Common Table Expression (CTE) `— tức là đặt tên cho một truy vấn con (subquery factoring).

## 1. Mục đích

- Đặt tên cho truy vấn con
- Làm câu lệnh rõ ràng, dễ đọc
- Tránh lặp lại subquery nhiều lần
- Hỗ trợ truy vấn phức tạp
## 2. Cú pháp cơ bản

```SQL
WITH cte_nameAS (
	SELECT ...
)
SELECT ...
FROM cte_name;
```

## 3. Ví dụ đơn giản trong SQL

```SQL
WITH high_salaryAS (
	SELECT employee_id, salary
	FROM employees
	WHERE salary>10000
)
SELECT*
FROM high_salary;
```

Ở đây:

- `high_salary` là một CTE
- Oracle coi nó như một inline view
## 4. Sử dụng WITH bên trong PL/SQL

Vì WITH là SQL, nên dùng trong:

- SELECT INTO
- Cursor
- INSERT
- UPDATE
- DELETE
```SQL
# Ví dụ trong PL/SQL block

SET SERVEROUTPUTON;

DECLARE
   v_count NUMBER;
BEGIN
WITH high_salaryAS (
	SELECT*
	FROM employees
	WHERE salary>10000
)

SELECT COUNT(*)
INTO v_count
FROM high_salary;

   DBMS_OUTPUT.PUT_LINE('Total: '|| v_count);
END;
/
```

## 5. WITH nhiều CTE

```SQL
WITH dept_avg AS (
	SELECT department_id, AVG(salary) avg_sal
	FROM employees
	GROUP BY department_id
),
high_dept AS (
	SELECT*
	FROM dept_avg
	WHERE avg_sal>8000
)

SELECT*
FROM high_dept;
```

Các CTE có thể tham chiếu lẫn nhau theo thứ tự khai báo.

## 6. WITH và ROWNUM (ví dụ top-N)

```SQL
WITH sorted_emp AS (
	SELECT*
	FROM employees
	ORDER BY salary DESC
)

SELECT*
FROM sorted_emp
WHERE ROWNUM <= 10;
```

## 7. WITH đệ quy (Recursive CTE)

Oracle hỗ trợ truy vấn phân cấp:

```SQL
WITH emp_tree (employee_id, manager_id, level_no) AS (
	SELECT employee_id, manager_id, 1
	FROM employees
	WHERE manager_id IS NULL
	
	UNION ALL
	
	SELECT e.employee_id, e.manager_id, t.level_no + 1
	FROM employees e
	JOIN emp_tree t
	ON e.manager_id= t.employee_id
)

SELECT*
FROM emp_tree;
```

Dùng cho:

- Cây tổ chức
- Danh mục phân cấp
- BOM structure
## 8. WITH vs Subquery thông thường

## 9. Bản chất thực thi

Oracle có thể:

- Inline view (merge vào query chính)
- Hoặc materialize tạm thời (tùy optimizer)
