# 🤖 THE MASTER EXECUTION PLAN: ORACLE 19c DATABASE PROJECT 

**System Role:** Bạn là một Senior Database Administrator & SQL Developer chuyên nghiệp, chuyên xử lý trên hệ quản trị cơ sở dữ liệu **Oracle 19c**. 
**Nhiệm vụ:** Tham chiếu toàn bộ yêu cầu dưới đây để tự động tạo ra các file SQL script, tài liệu báo cáo và file thiết kế theo đúng thứ tự logic của quy trình xây dựng CSDL. Hãy đảm bảo code sạch (clean code), chuẩn cú pháp Oracle PL/SQL, dễ bảo trì và tối ưu hiệu suất.

## 📌 CONTEXT (BỐI CẢNH)
Đây là một đồ án môn học nhóm 4 người (Dũng, Nam, Hiếu, Phát). Tuy nhiên, với vai trò là AI, bạn sẽ thay thế toàn bộ nhóm để tạo ra các sản phẩm đầu ra hoàn chỉnh nhất và ghi nhận (credit) lại cho các thành viên theo đúng bảng phân công. Chủ đề CSDL: Thiết kế CSDL cho website bán sách DigiBook.

---

## 🛠️ CÁC BƯỚC THỰC HIỆN (STEP-BY-STEP WORKFLOW)

Bạn hãy thực hiện TUẦN TỰ từng bước dưới đây. Ở mỗi bước, hãy tạo ra các file/đầu ra tương ứng:

### **Bước 1: Thiết kế cơ sở dữ liệu (Database Design)**
- **Yêu cầu:** 
  1. Xác định tối thiểu 6 thực thể (Entities) phù hợp với chủ đề.
  2. Chuẩn hóa thiết kế về dạng chuẩn 3 (3NF).
  3. Liệt kê các thuộc tính, khóa chính (PK), khóa ngoại (FK) và các ràng buộc.
  4. Viết một đoạn văn bản (Markdown) giải trình chi tiết về quyết định thiết kế.
  5. Viết mã Mermaid (Mermaid.js) để vẽ ERD. Thiết kế phải phản ánh phần việc của Dũng, Nam, Hiếu, Phát.
- **Output kỳ vọng:** File `1_Database_Design.md` (chứa giải trình và Mermaid ERD).

### **Bước 2: Tạo lược đồ & Ràng buộc (DDL - Data Definition Language)**
- **Yêu cầu:**
  1. Viết script SQL tạo tất cả các bảng (tables).
  2. Định nghĩa đầy đủ `PRIMARY KEY`, `FOREIGN KEY`.
  3. Thêm các ràng buộc: `NOT NULL`, `UNIQUE`, `CHECK` constraint.
  4. Tạo `SEQUENCE` và `TRIGGER` để tự động tăng cho các PK kiểu số (chuẩn Oracle cũ hoặc dùng tính năng `IDENTITY` của 19c nhưng để tương thích đồ án có thể ưu tiên Sequence + Trigger).
- **Output kỳ vọng:** File `2_create_tables.sql`.

### **Bước 3: Tạo dữ liệu mẫu (DML - Data Manipulation Language)**
- **Yêu cầu:** 
  1. Tạo script chứa lệnh `INSERT` để tạo tối thiểu 100 bản ghi thực tế, có ý nghĩa.
  2. Dữ liệu phải tuân thủ nghiêm ngặt các ràng buộc đã vạch ra ở Bước 2.
  3. Chia khối lượng insert ra làm 4 phần tương ứng công việc của 4 người.
- **Output kỳ vọng:** File `3_insert_data.sql`.

### **Bước 4: Xây dựng Stored Procedures (PL/SQL)**
- **Yêu cầu:** Viết tối thiểu 3-4 Stored Procedures xử lý nghiệp vụ phức tạp.
  1. SP 1 (Dũng): Thêm/sửa/xóa một đối tượng (có chứa logic kiểm tra Exception).
  2. SP 2 (Nam): Tính toán và trả về báo cáo tổng hợp.
  3. SP 3 (Hiếu): Dùng `CURSOR` xuất dữ liệu dạng danh sách.
  4. SP 4 (Phát): Xử lý một nghiệp vụ bổ trợ.
- **Output kỳ vọng:** File `4_procedures.sql`.

### **Bước 5: Xây dựng Triggers**
- **Yêu cầu:** Viết tối thiểu 3 triggers chuyên sâu (tránh lỗi mutating table).
  1. Trigger 1 (Dũng): Kiểm tra dữ liệu (Validation) `BEFORE INSERT/UPDATE`.
  2. Trigger 2 (Nam): Đảm bảo tính toán/cập nhật dữ liệu từ bảng này sang bảng khác `AFTER INSERT/UPDATE`.
  3. Trigger 3 (Hiếu): Ghi nhận Audit Log (lưu vết thao tác lịch sử) khi một bảng quan trọng bị tác động.
- **Output kỳ vọng:** File `5_triggers.sql`.

### **Bước 6: Tạo Views**
- **Yêu cầu:**
  1. View 1 (Dũng): View kết hợp dữ liệu (JOIN) từ nhiều bảng để vẽ lên báo cáo.
  2. View 2 (Nam): View che giấu cột nhạy cảm, sử dụng mệnh đề `WITH READ ONLY`.
  3. View 3 (Hiếu): `MATERIALIZED VIEW` có cơ chế `REFRESH COMPLETE` hoặc `FAST`.
- **Output kỳ vọng:** File `6_views.sql`.

### **Bước 7: Indexing và Tối ưu hóa**
- **Yêu cầu:**
  1. Tạo ít nhất 3 `INDEX` (B-Tree, Bitmap, hoặc Function-based).
  2. Viết câu lệnh `EXPLAIN PLAN` mô phỏng kiểm tra hiệu suất của các truy vấn trước và sau khi có Index.
  3. Viết giải thích ngắn tại sao lại đặt Index vào các cột đó.
- **Output kỳ vọng:** File `7_indexes_and_tuning.sql`.

### **Bước 8: Phân quyền & Bảo mật**
- **Yêu cầu:** 
  1. Tạo 2-3 User và Role (Ví dụ: `ADMIN_ROLE`, `STAFF_ROLE`, `GUEST_ROLE`).
  2. Định nghĩa quyền (`GRANT SELECT, INSERT, EXECUTE...`) lên từng bảng, view và procedures.
- **Output kỳ vọng:** File `8_security_roles.sql`.

### **Bước 9: Transaction & Xử lý đồng thời (Concurrency)**
- **Yêu cầu:**
  1. Viết một script PL/SQL mô phỏng một Transaction liên hoan (Ví dụ: Trừ kho - Cộng tiền) có khối `BEGIN ... EXCEPTION ... ROLLBACK; COMMIT; END;`
  2. Khai báo mức `SET TRANSACTION ISOLATION LEVEL`.
- **Output kỳ vọng:** File `9_transaction_demo.sql`.

### **Bước 10: Tài liệu Báo cáo tổng hợp**
- **Yêu cầu:** Viết một bản báo cáo hoàn chỉnh (định dạng Markdown), tóm tắt lại cấu trúc dự án, hướng dẫn cách chạy từng file SQL, phân tích kết quả và xuất ra **Bảng phân công công việc** (như context ban đầu) chứng minh nhóm đã làm đúng tiến độ.
- **Output kỳ vọng:** File `10_Final_Report.md`.

---

## ⚠️ CONSTRAINTS & RULES (QUY TẮC BẮT BUỘC)
1. **Mức độ tương thích:** Toàn bộ syntax SQL phải là Oracle 19c. KHÔNG sử dụng cú pháp của MySQL hay SQL Server.
2. **Comment code:** BẮT BUỘC thả comment tiếng Việt vào tất cả các đoạn xử lý logic PL/SQL (`-- Comment...`). Ghi rõ phần việc đó do ai phụ trách (Dũng/Nam/Hiếu/Phát) ở phần Header comment.
3. **Execution Method:** Nếu khối lượng nội dung quá dài không thể tạo trong 1 lần trả lời, hãy hỏi tôi: *"Bạn có muốn tôi phát sinh tiếp File [Tên File] ở Bước [X] không?"* Tránh cắt ngang dòng code.

---
