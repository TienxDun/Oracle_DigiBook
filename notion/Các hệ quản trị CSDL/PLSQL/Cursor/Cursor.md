# Cursor

## 1. Khái niệm

`Cursor` là một vùng nhớ logic do Oracle cấp phát để:

- Lưu trữ kết quả của một câu lệnh SQL
- Quản lý quá trình truy xuất từng dòng (row-by-row processing)
- Điều khiển việc FETCH dữ liệu từ result set
## 2. Lý do dùng

Trong SQL thuần:

```SQL
SELECT * FROM employees;
```

→ Kết quả trả về toàn bộ tập hợp.

Nhưng trong PL/SQL, khi muốn:

- Lặp từng dòng
- Kiểm tra từng giá trị
- Thực hiện xử lý điều kiện cho từng record
→ Phải dùng CURSOR.

## 3. Phân loại Cursor trong Oracle

### 3.1. Cursor ngầm định (Implicit Cursor)

Oracle tự tạo khi dùng:

- INSERT
- UPDATE
- DELETE
- SELECT INTO
Ví dụ:

```SQL
DECLARE
   v_salary employees.salary%TYPE;
BEGIN
	SELECT salary
	INTO v_salary
	FROM employees
	WHERE employee_id=100;
END;
/
```

Oracle tự động:

- OPEN
- FETCH
- CLOSE
Thuộc tính của implicit cursor

Ví dụ:

```SQL
BEGIN
	UPDATE employees
	SET salary= salary*1.1
	WHERE department_id=60;
	
  DBMS_OUTPUT.PUT_LINE('Rows updated: '||SQL%ROWCOUNT);
END;
/
```

### 3.2. Cursor tường minh (Explicit Cursor)

Do lập trình viên khai báo để xử lý nhiều dòng.

## 4. Quy trình hoạt động của Explicit Cursor

Gồm 4 bước:

1. DECLARE
1. OPEN
1. FETCH
1. CLOSE
### 4.1. Khai báo

```SQL
CURSOR cursor_name IS
SELECT ...
```

Ví dụ:

```SQL
DECLARE
CURSOR c_emp IS
SELECT employee_id, salary
FROM employees
WHERE department_id=60;
```

### 4.2. Mở cursor

```SQL
OPEN c_emp;
```

→ Oracle thực thi SELECT và tạo result set.

### 4.3. FETCH

```SQL
FETCH c_emp INTO variable;
```

→ Lấy từng dòng vào biến.

### 4.4. CLOSE

```SQL
CLOSE c_emp;
```

→ Giải phóng bộ nhớ.

## 5. Ví dụ

```SQL
SET SERVEROUTPUT ON;

DECLARE
   CURSOR c_emp IS
      SELECT first_name, salary
      FROM employees
      WHERE department_id = 60;

   v_emp c_emp%ROWTYPE;
BEGIN
   OPEN c_emp;

   LOOP
      FETCH c_emp INTO v_emp;
      EXIT WHEN c_emp%NOTFOUND;

      DBMS_OUTPUT.PUT_LINE(
         v_emp.first_name || ' - ' || v_emp.salary
      );
   END LOOP;

   CLOSE c_emp;
END;
/
```

## 6. Cursor FOR LOOP

> 💡 

```SQL
BEGIN
   FOR rec IN (
      SELECT first_name, salary
      FROM employees
      WHERE department_id = 60
   ) LOOP
      DBMS_OUTPUT.PUT_LINE(rec.first_name || ' ' || rec.salary);
   END LOOP;
END;
/
```

Ưu điểm:

- Ngắn gọn
- Ít lỗi
- Tự động quản lý vòng đời cursor
## 7. Cursor có tham số (Parameterized Cursor)

Cho phép truyền điều kiện linh hoạt.

```SQL
DECLARE
   CURSOR c_emp (p_dept NUMBER) IS
      SELECT first_name, salary
      FROM employees
      WHERE department_id = p_dept;

   v_emp c_emp%ROWTYPE;
BEGIN
   OPEN c_emp(60);

   LOOP
      FETCH c_emp INTO v_emp;
      EXIT WHEN c_emp%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_emp.first_name);
   END LOOP;

   CLOSE c_emp;
END;
/
```

## 8. Cursor và hiệu năng

Cursor phù hợp khi:

- Xử lý từng dòng
- Có logic phức tạp cho mỗi record
Không nên dùng cursor nếu có thể:

- Dùng một câu UPDATE hoặc MERGE là đủ
Ví dụ nên tránh:

```SQL
FOR rec IN (SELECT ...) LOOP
   UPDATE ...
END LOOP;
```

Nếu có thể thay bằng:

```SQL
UPDATE employees
SET salary = salary * 1.1
WHERE department_id = 60;
```

## 9. Bản chất bên trong

Cursor là cầu nối giữa:

- SQL Engine (set-based processing)
- PL/SQL Engine (procedural processing)
Oracle sử dụng:

- Private SQL Area
- Result set buffer
- Row-by-row fetch mechanism
