# Parameter

**Parameter** được hiểu là cơ chế cho phép người dùng nhập giá trị khi thực thi câu lệnh SQL, thông qua ký hiệu `&`. Đây là cơ chế **substitution variable** — Oracle sẽ thay thế giá trị vào câu lệnh trước khi phân tích cú pháp và thực thi.

‣

## 1. Bản chất kỹ thuật

- Ký hiệu: `&variable_name`
- Khi chạy câu lệnh, hệ thống yêu cầu nhập giá trị
- Giá trị được thay thế trực tiếp vào câu SQL
- Sau đó Oracle mới parse và execute
## 2. Một số ví dụ

```SQL
# cơ bản
SELECT employee_id, last_name, salary
FROM hr.employees
WHERE employee_id = &emp_id;


# truyền nhiều tham số

SELECT employee_id, last_name, &column_name
FROM employees
WHERE &condition
ORDER BY &order_column;

# tham số là chuỗi
SELECT *
FROM employees
WHERE last_name = '&name';
```

## 3. Một số lưu ý

- `&var` → hỏi mỗi lần xuất hiện
- `&&var` → hỏi một lần, lưu lại cho các lần sau
```SQL
SELECT *
FROM employees
WHERE department_id = &&dept_id;

SELECT *
FROM departments
WHERE department_id = &&dept_id;
```

Khai báo mặc định bằng DEFINE

```SQL
DEFINE dept_id = 10;

SELECT *
FROM employees
WHERE department_id = &dept_id;
```

