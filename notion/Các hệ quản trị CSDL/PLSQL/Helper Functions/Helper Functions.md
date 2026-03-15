# Helper Functions

## 1. Hàm xử lý chuỗi (String Functions)

- `LOWER(expr)`
- `UPPER(expr)`
- `INITCAP(expr)`
- `CONCAT(expr1, expr2)`
- `SUBSTR(expr, start [, length])`
- `LENGTH(expr)`
- `INSTR(expr, search_string)`
- `LPAD(expr, length, pad_string)`
- `RPAD(expr, length, pad_string)`
- `REPLACE(expr, search, replace)`
- `TRIM([character FROM] expr)`
## 2.  Hàm số học (Numeric Functions)

- `ROUND(number [, decimal_places])`
- `TRUNC(number [, decimal_places])`
- `MOD(m, n)`
## 3. Hàm ngày giờ (Date Functions)

- `SYSDATE`
- `MONTHS_BETWEEN(date1, date2)`
- `ADD_MONTHS(date, n)`
- `NEXT_DAY(date, 'day')`
- `LAST_DAY(date)`
- `ROUND(date)`
- `TRUNC(date)`
## 4. Hàm chuyển đổi kiểu (Conversion Functions)

- `TO_NUMBER(expr)`
- `TO_DATE(expr, format_model)`
- `TO_CHAR(date, format_model)`
- `TO_CHAR(number, format_model)`
## 5. Hàm xử lý NULL

- `NVL(expr1, expr2)`
- `NVL2(expr1, expr2, expr3)`
- `NULLIF(expr1, expr2)`
- `COALESCE(expr1, expr2, …)`
## 6. Hàm đặc biệt

- `SQL%ROWCOUNT` (thuộc tính cursor ngầm định)
- `RAISE_APPLICATION_ERROR(error_number, message)`
