# Cấu trúc điều khiển

```Bash
Control Structures
│
├── Conditional
│   ├── IF
│   └── CASE
│
├── Loop
│   ├── LOOP
│   ├── WHILE
│   ├── FOR
│   └── Cursor FOR
│
└── Jump
    ├── EXIT
    ├── CONTINUE
    └── GOTO
```

## 1. Cấu trúc điều kiện (Conditional Control)

### 1.1. IF – THEN

Cú pháp

```SQL
IF condition THEN
   statements;
END IF;
```

Ví dụ: kiểm tra lương

```SQL
SET SERVEROUTPUT ON;

DECLARE
   v_salary employees.salary%TYPE;
BEGIN
	SELECT salary
	INTO v_salary
	FROM employees
	WHERE employee_id=100;

	IF v_salary>10000 THEN
	      DBMS_OUTPUT.PUT_LINE('High salary');
	END IF;
END;
/
```

### 1.2. IF – THEN – ELSE

```SQL
IF condition THEN
   statements1;
ELSE
   statements2;
END IF;
```

Ví dụ: phân loại lương

```SQL
DECLARE
   v_salary employees.salary%TYPE;
BEGIN
	SELECT salary INTO v_salary
	FROM employees
	WHERE employee_id=101;

	IF v_salary>10000 THEN
	      DBMS_OUTPUT.PUT_LINE('High');
	ELSE
	      DBMS_OUTPUT.PUT_LINE('Normal');
	END IF;
END;
/
```

### 1.3. IF – THEN – ELSIF – ELSE

```SQL
DECLARE
    v_salary employees.salary%TYPE;
BEGIN
	SELECT salary INTO v_salary
	FROM employees
	WHERE employee_id=102;

	IF v_salary>=15000 THEN
        DBMS_OUTPUT.PUT_LINE('Executive');
    ELSIF v_salary>=8000 THEN
        DBMS_OUTPUT.PUT_LINE('Manager');
    ELSIF v_salary>=4000 THEN
        DBMS_OUTPUT.PUT_LINE('Staff');
	ELSE
        DBMS_OUTPUT.PUT_LINE('Entry');
    END IF;
END;
/
```

## 2. CASE Statement

### 2.1. Simple CASE

```SQL
DECLARE
    v_job employees.job_id%TYPE;
BEGIN
    SELECT job_id INTO v_job
    FROM employees
    WHERE employee_id=104;

    CASE v_job
    WHEN 'IT_PROG' THEN
        DBMS_OUTPUT.PUT_LINE('Programmer');
    WHEN 'AD_VP' THEN
        DBMS_OUTPUT.PUT_LINE('Vice President');
    ELSE
         DBMS_OUTPUT.PUT_LINE('Other job');
    END CASE;
END;
/
```

### 2.2. Searched CASE

```SQL
DECLARE
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id=104;

    CASE
    WHEN v_salary>15000 THEN
        DBMS_OUTPUT.PUT_LINE('Top tier');
    WHEN v_salary>8000 THEN
        DBMS_OUTPUT.PUT_LINE('Mid tier');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Lower tier');
    END CASE;
END;
/
```

## 3. Vòng lặp (Loops)

### 3.1. LOOP cơ bản

```SQL
DECLARE
   v_counter NUMBER :=1;
BEGIN
    LOOP
        DBMS_OUTPUT.PUT_LINE('Counter = '|| v_counter);
        v_counter := v_counter+1;
    EXIT WHEN v_counter>5;
    END LOOP;
END;
/
```

### 3.2. WHILE LOOP

```SQL
DECLARE
    v_counter NUMBER :=1;
BEGIN
    WHILE v_counter<=5 LOOP
        DBMS_OUTPUT.PUT_LINE('WHILE = '|| v_counter);
        v_counter := v_counter+1;
    END LOOP;
END;
/
```

### 3.3. FOR LOOP (Range)

```SQL
BEGIN
    FOR i IN 1..5 LOOP
        DBMS_OUTPUT.PUT_LINE('FOR i = '|| i);
    END LOOP;
END;
/
```

`Reverse`

```SQL
BEGIN
    FOR i IN REVERSE 1..5 LOOP
        DBMS_OUTPUT.PUT_LINE('FOR i = '|| i);
    END LOOP;
END;
/
```

## 4. Cursor FOR LOOP (Rất quan trọng)

> 💡 

Ví dụ: in danh sách nhân viên phòng 60

```SQL
BEGIN
FOR rec IN (
        SELECT first_name, salary
        FROM employees
        WHERE department_id=60
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.first_name||' - '|| rec.salary );
    END LOOP;
END;
/
```

## 5. LOOP với Cursor tường minh

```SQL
DECLARE
    CURSOR c_emp IS
        SELECT first_name, salary
        FROM employees
        WHERE department_id=90;

    v_emp c_emp%ROWTYPE;
BEGIN
    OPEN c_emp;
    
    LOOP
        FETCH c_emp INTO v_emp;
        EXIT WHEN c_emp%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(v_emp.first_name||' '|| v_emp.salary);
    END LOOP;

CLOSE c_emp;
END;
/
```

## 6. EXIT và EXIT WHEN

```SQL
DECLARE
    v_counter NUMBER :=1;
BEGIN
    LOOP
        IF v_counter=3 THEN
            EXIT;
        END IF;

        DBMS_OUTPUT.PUT_LINE(v_counter);
        v_counter := v_counter+1;
    END LOOP;
END;
/
```

## 7. CONTINUE

```SQL
BEGIN
    FOR i IN 1..5 LOOP
        IF i=3 THEN
            CONTINUE;
        END IF;

        DBMS_OUTPUT.PUT_LINE(i);
    END LOOP;
END;
/
```

## 7. GOTO (cấm thuật 🙀)

```SQL
DECLARE
   v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id=104;

    IF v_salary<10000 THEN
        GOTO low_salary;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Normal salary');
    GOTO end_label;

    <<low_salary>>
    DBMS_OUTPUT.PUT_LINE('Low salary');

    <<end_label>>
    NULL;
END;
/
```

## 9. Lồng nhiều cấu trúc

Ví dụ: tăng lương cho nhân viên lương thấp

```SQL
BEGIN
    FOR rec IN (
        SELECT employee_id, salary
        FROM employees
        WHERE department_id=60
   ) LOOP

        IF rec.salary<5000 THEN
            UPDATE employees
            SET salary= salary*1.1
            WHERE employee_id= rec.employee_id;
        END IF;

    END LOOP;

    COMMIT;
END;
/
```

## 10. So sánh nhanh

