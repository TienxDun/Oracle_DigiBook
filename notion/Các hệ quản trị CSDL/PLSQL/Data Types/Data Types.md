# Data Types

## 1. Khái niệm

**Data Type** xác định:

- Kiểu dữ liệu có thể lưu
- Kích thước bộ nhớ
- Phạm vi giá trị hợp lệ
- Cách Oracle xử lý và tối ưu lưu trữ
Chọn đúng data type ảnh hưởng trực tiếp đến:

- Storage
- Index efficiency
- Performance
- Data integrity
## 2. Nhóm Data Types quan trọng

### 2.1. Character Data Types

#### 2.1.1. VARCHAR2(size)

- Lưu chuỗi biến độ dài
- Tối đa 4000 bytes (SQL)
- Phổ biến nhất
```SQL
product_name VARCHAR2(200)
```

#### 2.1.2. CHAR(size)

- Chuỗi cố định độ dài
- Nếu thiếu sẽ pad khoảng trắng
```SQL
gender CHAR(1)
```

#### 2.1.3. NVARCHAR2(size)

- Dùng cho Unicode
- Quan trọng khi lưu tiếng Việt có dấu
### 2.2. Numeric Data Types

#### 2.2.1. NUMBER(p, s)

- p = precision (tổng số chữ số)
- s = scale (số chữ số sau dấu thập phân)
Ví dụ:

```SQL
price NUMBER(10,2)
```

→ Tối đa 10 chữ số, 2 chữ số thập phân

→ Lưu tối đa: 99999999.99

#### 2.2.2. NUMBER (không khai báo p,s)

Cho phép giá trị rất lớn, nhưng không kiểm soát được tính chặt chẽ.

### 2.3. Date & Time

#### 2.3.1. DATE

Lưu:

- Ngày
- Giờ
- Phút
- Giây
```SQL
order_date DATE
```

Ví dụ insert:

```SQL
INSERTINTO sales_order(order_date)
VALUES (SYSDATE);
```

#### 2.3.2. TIMESTAMP

Chính xác hơn DATE (lưu fractional seconds)

```SQL
created_at TIMESTAMP
```

### 2.4. Large Objects (LOB)

#### 2.4.1. CLOB

Lưu văn bản lớn (>4000 bytes)

#### 2.4.2. BLOB

Lưu dữ liệu nhị phân (ảnh, file)

