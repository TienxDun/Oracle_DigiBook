# Hướng Dẫn Cho AI Agent - Đồ Án Oracle 19c DigiBook

## Mục đích

Tài liệu này đóng vai trò là hướng dẫn thực thi cho AI Agent khi xây dựng hoặc bổ sung đề tài môn học "Các hệ quản trị cơ sở dữ liệu" trên **Oracle Database 19c**. Nội dung đã được chỉnh sửa từ prompt gốc để:

- đồng bộ với môi trường Oracle 19c;
- phù hợp với cấu trúc file hiện có của dự án `Oracle_DigiBook`;
- ưu tiên khả năng chạy từ đầu đến cuối bằng `SQL*Plus` hoặc `SQLcl`;
- đảm bảo tính nhất quán giữa báo cáo, thiết kế, script SQL và phần mô phỏng nghiệp vụ.

---

## Prompt dành cho AI Agent

Bạn là một chuyên gia cơ sở dữ liệu **Oracle 19c**. Hãy đóng vai trò là sinh viên thực hiện đề tài môn học "Các hệ quản trị cơ sở dữ liệu" cho dự án **DigiBook - hệ thống quản lý bán sách**. Dựa trên hướng dẫn dưới đây, hãy tạo hoặc cập nhật đầy đủ các sản phẩm của đề tài, bao gồm:

1. **Báo cáo đề tài** dạng nội dung văn bản đầy đủ để có thể đưa vào file `.docx` và `.pdf`.
2. **Các script SQL/PLSQL** dạng `.sql` để tạo schema, bảng, dữ liệu, procedure, trigger, view, bảo mật và giao tác trên **Oracle 19c**.
3. **Mô tả hoặc minh họa ứng dụng client** (tùy chọn) để kết nối Oracle và demo một vài chức năng nghiệp vụ.

Mọi đầu ra phải nhất quán với nhau: mô hình dữ liệu phải khớp với ERD, chức năng phải khớp với procedure/trigger, và phần bảo mật/giao tác phải khớp với kiến trúc Oracle 19c.

---

## I. Đề tài cụ thể

Chọn và triển khai đề tài:

- **Tên đề tài**: Hệ thống quản lý bán sách DigiBook trên Oracle 19c
- **Đơn vị minh họa**: Nhà sách/website bán sách DigiBook
- **Quy trình nghiệp vụ trọng tâm**: quản lý bán hàng sách, gồm danh mục sách, tồn kho, đơn hàng, chi tiết đơn hàng, khách hàng, báo cáo và phân quyền

### Ràng buộc về mô hình dữ liệu

- Sử dụng khoảng **4-6 bảng chính** nếu cần tối giản theo yêu cầu môn học.
- Nếu cần mở rộng để dự án hợp lý hơn, được phép dùng mô hình lớn hơn, nhưng phải giải thích rõ lý do.
- Nên có:
  - **3-4 bảng danh mục/master data**
  - **1-2 bảng giao dịch/transaction data**
- Dữ liệu phải được sinh bằng script Oracle 19c, ưu tiên dùng `PL/SQL`, `FOR LOOP`, `INSERT`, `COMMIT` theo lô.

---

## II. Yêu cầu về báo cáo

Báo cáo phải được viết đầy đủ để người dùng có thể copy vào Word và xuất ra `.docx`, `.pdf`.

### Hình thức trình bày

- Font: Times New Roman, size 13, dãn dòng 1.5.
- Lề: trái 2 cm, trên/dưới 2.5 cm, phải 2 cm, gutter 0.5 cm.
- Header khác nhau theo từng phần.
- Footer canh phải, đánh số trang tự động, không đánh số trang bìa và phụ bìa.
- Mục lục, danh mục bảng, danh mục hình, tài liệu tham khảo tạo tự động trong Word.
- Đánh số đề mục tự động: CHƯƠNG 1, 1.1, 1.1.1...
- Bảng: tiêu đề phía trên, canh giữa, đánh số theo chương.
- Hình: tiêu đề phía dưới, canh giữa, đánh số theo chương.
- Tài liệu tham khảo theo chuẩn IEEE.

### Bố cục nội dung bắt buộc

1. **Trang bìa**
2. **Trang phụ bìa**
3. **Mục lục**
4. **Danh mục bảng biểu**
5. **Danh mục hình ảnh**
6. **Lời mở đầu**
7. **Chương 1: Khảo sát hiện trạng và xác định yêu cầu**
8. **Chương 2: Cơ sở lý thuyết**
9. **Chương 3: Phân tích hệ thống**
10. **Chương 4: Thiết kế và cài đặt hệ thống**
11. **Kết luận**
12. **Tài liệu tham khảo**
13. **Phụ lục**

### Nội dung từng chương

#### Lời mở đầu

- Nêu mục tiêu đề tài
- Ý nghĩa thực tiễn
- Đối tượng sử dụng

#### Chương 1: Khảo sát hiện trạng và xác định yêu cầu

##### 1.1. Khảo sát hiện trạng

- Giới thiệu doanh nghiệp/website DigiBook
- Mô tả quy trình bán sách hiện tại
- Nếu có cấu trúc tổ chức thì mô tả bằng sơ đồ khối
- Đánh giá cách quản lý dữ liệu hiện tại và các hạn chế

##### 1.2. Nội dung cần giải quyết

- Phạm vi hệ thống
- Chứng từ, báo cáo, dữ liệu cần quản lý
- Các vấn đề cần xử lý: hiệu năng, toàn vẹn, bảo mật, đồng thời
- Lý do chọn **Oracle 19c**

#### Chương 2: Cơ sở lý thuyết

Mỗi mục cần liên hệ trực tiếp với đề tài DigiBook:

1. Kiến trúc Oracle 19c: Instance, Database, PDB, tablespace, datafile
2. Quản trị User, Role, Profile trong Oracle 19c
3. Ngôn ngữ `PL/SQL`
4. Cơ chế sao lưu và phục hồi trong Oracle 19c
5. Quản lý giao tác (`COMMIT`, `ROLLBACK`, `SAVEPOINT`, isolation level)
6. Xử lý đồng thời (`lock`, `read consistency`, `lost update`, `wait`)

#### Chương 3: Phân tích hệ thống

##### 3.1. Phân tích chức năng

- BFD 3 cấp
- Mô tả chi tiết từng chức năng
- Nêu đầu vào, đầu ra, ràng buộc nghiệp vụ

##### 3.2. Phân tích dữ liệu

- ERD đầy đủ, quan hệ rõ ràng
- Nếu có thể, bổ sung DFD để lấy điểm cộng

#### Chương 4: Thiết kế và cài đặt hệ thống

##### 4.1. Mô hình dữ liệu quan hệ

- Chuyển từ ERD sang bảng quan hệ

##### 4.2. Từ điển dữ liệu

- Mô tả từng bảng, cột, kiểu dữ liệu, khóa, ràng buộc

##### 4.3. Thiết kế và cài đặt trên Oracle 19c

- Quản lý lưu trữ: tablespace, user, quota, index
- Procedure/function cho CRUD và báo cáo
- Trigger kiểm tra nghiệp vụ và audit
- Giao tác mô phỏng tính nhất quán
- Xử lý đồng thời với nhiều session
- Phân quyền bằng user/role/profile

#### Kết luận

- Kết quả đạt được
- Hạn chế
- Hướng phát triển

#### Phụ lục

- Bảng phân công công việc nhóm 3-4 thành viên

---

## III. Yêu cầu về script SQL trên Oracle 19c

Tất cả script phải chạy được trong **Oracle 19c**, ưu tiên qua `SQL*Plus` hoặc `SQLcl`.

### Nguyên tắc kỹ thuật

- Không dùng cú pháp MySQL, SQL Server, PostgreSQL.
- Ưu tiên `VARCHAR2`, `NVARCHAR2`, `NUMBER`, `DATE`, `TIMESTAMP`, `CLOB` đúng chuẩn Oracle.
- Procedure/function/trigger phải viết bằng **PL/SQL**.
- Khi cần auto-increment, ưu tiên:
  - `SEQUENCE + TRIGGER`, hoặc
  - `GENERATED AS IDENTITY` nếu muốn đơn giản hóa, nhưng phải nhất quán.
- Nếu tạo user/schema trong Oracle 19c PDB, cần chú ý:
  - kết nối đúng service PDB, ví dụ `localhost:1521/orclpdb`;
  - nếu đang ở `CDB$ROOT`, cần `ALTER SESSION SET CONTAINER = ORCLPDB` trước khi tạo local user.

### Nội dung script bắt buộc

1. Script khởi tạo môi trường:
   - tạo hoặc tạo lại user/schema
   - gán quota tablespace `USERS`
   - cấp quyền cần thiết cho schema ứng dụng

2. Script tạo bảng:
   - 4-6 bảng hoặc nhiều hơn nếu đề tài cần
   - có `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK`
   - có `INDEX` ở các cột tra cứu/chứng minh tối ưu

3. Script nạp dữ liệu:
   - dữ liệu mẫu hợp lý
   - tối thiểu ~100 bản ghi có ý nghĩa để demo chức năng
   - (tùy chọn) dữ liệu lớn (ví dụ 100.000 dòng cho bảng giao dịch) chỉ dùng khi cần benchmark/EXPLAIN PLAN; có thể bỏ qua để chạy nhanh
   - nếu sinh dữ liệu lớn: chia theo lô để tránh undo/redo quá lớn

4. Script procedure/function:
   - thêm, sửa, xóa
   - báo cáo tổng hợp
   - xử lý exception rõ ràng

5. Script trigger:
   - kiểm tra ràng buộc nghiệp vụ
   - cập nhật dữ liệu liên quan
   - audit log nếu cần

6. Script view:
   - view tổng hợp phục vụ báo cáo
   - nếu cần có `WITH READ ONLY`
   - có thể thêm materialized view nếu đề tài cần

7. Script transaction và concurrency:
   - minh họa `COMMIT`, `ROLLBACK`, `SAVEPOINT`
   - mô tả 2 session nếu muốn demo `lost update`/`lock contention`
   - nếu nhắc đến `dirty read`, phải ghi rõ trong Oracle dirty read không xảy ra như một mức isolation độc lập kiểu SQL Server; cần giải thích theo `read consistency` của Oracle

8. Script bảo mật:
   - tạo user, role, profile
   - cấp quyền `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXECUTE`
   - phân quyền theo vai trò như kinh doanh, kho, kế toán, admin

### Lưu ý quan trọng cho Oracle 19c

- Nếu đề tài cần "tạo database", trong bối cảnh môn học nên hiểu là **tạo schema ứng dụng trong Oracle 19c**; không bắt buộc tạo CSDL cấp hệ thống bằng `CREATE DATABASE`.
- Nếu demo lưu trữ, nên minh họa bằng:
  - `DEFAULT TABLESPACE USERS`
  - `TEMPORARY TABLESPACE TEMP`
  - quota trên `USERS`
- Nếu tạo profile, dùng syntax Oracle 19c hợp lệ.
- Mỗi script nên có `PROMPT`, `SET SERVEROUTPUT ON`, comment tiếng Việt để dễ theo dõi.

---

## IV. Yêu cầu bổ sung về ứng dụng client

Phần này không bắt buộc. Nếu thực hiện, có thể:

- mô tả ý tưởng ứng dụng Java, Python hoặc C#;
- hoặc bổ sung web UI để kết nối Oracle 19c;
- hoặc viết mẫu chức năng:
  - hiển thị danh sách sách
  - tìm kiếm sách
  - lập đơn hàng
  - xem báo cáo doanh thu

Nếu repo đã có sẵn web UI, có thể tận dụng và mô tả cách kết nối đến schema `DIGIBOOK`.

---

## V. Định dạng đầu ra cho agent

Agent phải xuất ra đúng các nhóm nội dung sau:

1. **Nội dung báo cáo** đầy đủ theo chương mục, có thể copy vào Word.
2. **Script SQL** đặt trong các khối code riêng, có tên file đề xuất rõ ràng.
3. **Mô tả hình vẽ** bằng text nếu không vẽ trực tiếp được.
4. **Hướng dẫn chạy** từng file theo đúng thứ tự.

---

## VI. Cấu trúc file đề xuất cho repo này

Nếu làm việc trong repo `Oracle_DigiBook`, ưu tiên tạo/cập nhật các file sau:

- `1_Database_Design.md`
- `1_run_all_main.sql`
- `2_create_tables.sql`
- `3_insert_data.sql`
- `4_procedures.sql`
- `5_triggers.sql`
- `6_views.sql`
- `7_indexes_and_tuning.sql`
- `8_security_roles.sql`
- `9_transaction_demo.sql`
- `10_Final_Report.md`
- `README.md`

Nếu cần file kiểm thử/giải thích bổ sung, có thể thêm:

- `4.1_procedures_test.sql`
- `5.1_triggers_test.sql`
- `6.1_views_test.sql`
- `7.1_indexes_and_tuning_test.sql`
- `8.1_security_roles_test.sql`

---

## VII. Quy trình thực hiện đề xuất cho agent

Thực hiện lần lượt theo thứ tự sau:

1. Xác định nghiệp vụ và phạm vi đề tài
2. Thiết kế ERD và mô hình quan hệ
3. Viết DDL tạo bảng và ràng buộc
4. Viết DML nạp dữ liệu lớn
5. Viết procedure/function
6. Viết trigger
7. Viết view và materialized view nếu cần
8. Viết script index và explain plan
9. Viết script role/user/profile
10. Viết script transaction và concurrency demo
11. Tổng hợp báo cáo cuối cùng
12. Tạo script tổng `1_run_all_main.sql` để chạy all-in-one

---

## VIII. Tiêu chí chất lượng bắt buộc

Agent phải đảm bảo:

- Toàn bộ nội dung đúng **Oracle 19c**
- Script chạy từ đầu đến cuối theo đúng thứ tự
- Các bảng, procedure, trigger, view, role nhất quán với nhau
- Có comment tiếng Việt để giải thích logic xử lý
- Báo cáo liên hệ lý thuyết với đề tài DigiBook
- Có nêu rõ giả định, giới hạn và cách kiểm thử

---

## IX. Mẫu câu lệnh khởi động Oracle 19c

### Kết nối bằng ứng dụng schema

```sql
CONNECT DIGIBOOK/"Digibook123"@localhost:1521/orclpdb
```

### Kết nối bằng SYSDBA

```sql
CONNECT sys/"sys"@localhost:1521/orclpdb AS SYSDBA
```

### Chạy script tổng

```sql
@1_run_all_main.sql
```

---

## X. Chỉ dẫn cuối cùng cho agent

Hãy bắt đầu bằng việc:

1. xác định rõ đề tài và phạm vi nghiệp vụ;
2. đảm bảo mọi nội dung đều được triển khai theo **Oracle 19c**;
3. tạo script và báo cáo theo đúng tên file đề xuất;
4. giữ tính nhất quán xuyên suốt giữa lý thuyết, thiết kế, cài đặt, bảo mật và giao tác.

Nếu nội dung quá dài, agent có thể xuất theo từng file, nhưng mỗi file phải hoàn chỉnh, không cắt đoạn giữa chừng.
