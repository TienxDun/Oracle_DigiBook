/*
================================================================================
  📦 BƯỚC 3: TẠO DỮ LIỆU MẪU (DML) — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 3_insert_data.sql
  Mục đích: Chèn tối thiểu 100 bản ghi mẫu cho 9 bảng, chia đều cho 4 người.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Bật SET DEFINE OFF để tránh lỗi khi chèn dấu '&'.
  - Các Trigger Auto-Increment sẽ tự động gán ID từ Sequence theo thứ tự chèn.
  - Chạy Script theo thứ tự từ trên xuống dưới (Bảng cha -> Bảng con).
================================================================================
*/

SET DEFINE OFF;

/* ============================================================================
   👤 PHẦN 1: DŨNG (Phụ trách: CATEGORIES, CUSTOMERS)
============================================================================ */

PROMPT Đang chèn dữ liệu bảng CATEGORIES (Dũng)...
-- [1-8] 8 Danh mục sách
INSERT INTO CATEGORIES (category_name, description) VALUES ('Tiểu thuyết', 'Các tác phẩm văn học hư cấu, tiểu thuyết trong và ngoài nước');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Kỹ năng sống', 'Sách phát triển bản thân, kỹ năng giao tiếp, quản lý thời gian');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Kinh tế - Kinh doanh', 'Sách về khởi nghiệp, quản trị, đầu tư, tài chính');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Lịch sử - Tôn giáo', 'Sách tìm hiểu về lịch sử nhân loại, sự kiện và tôn giáo');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Thiếu nhi', 'Truyện tranh, cổ tích, sách khám phá cho trẻ em');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Khoa học - Viễn tưởng', 'Kiến thức khoa học, vũ trụ, sinh học và tiểu thuyết viễn tưởng');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Ngoại ngữ', 'Giáo trình, tài liệu học tiếng Anh, Nhật, Hàn, Trung');
INSERT INTO CATEGORIES (category_name, description) VALUES ('Tâm lý học', 'Sách phân tích tâm lý con người, hành vi và nhận thức');

PROMPT Đang chèn dữ liệu bảng CUSTOMERS (Dũng)...
-- [1-10] 10 Khách hàng (Sử dụng dummy hash cho password)
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Nguyễn Văn An', 'an.nguyen@email.com', 'hashedpwd123', '0901234567', 'Quận 1, TP.HCM', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Trần Thị Bình', 'binh.tran@email.com', 'hashedpwd123', '0912345678', 'Ba Đình, Hà Nội', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Lê Hoàng Cường', 'cuong.le@email.com', 'hashedpwd123', '0923456789', 'Hải Châu, Đà Nẵng', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Phạm Quỳnh Dung', 'dung.pham@email.com', 'hashedpwd123', '0934567890', 'Ninh Kiều, Cần Thơ', 'INACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Hoàng Thanh Em', 'em.hoang@email.com', 'hashedpwd123', '0945678901', 'Quận 3, TP.HCM', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Vũ Tuấn Phong', 'phong.vu@email.com', 'hashedpwd123', '0956789012', 'Cầu Giấy, Hà Nội', 'BANNED');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Đặng Thùy Giang', 'giang.dang@email.com', 'hashedpwd123', '0967890123', 'Gò Vấp, TP.HCM', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Bùi Xuân Hải', 'hai.bui@email.com', 'hashedpwd123', '0978901234', 'Liên Chiểu, Đà Nẵng', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Ngô Quang Huy', 'huy.ngo@email.com', 'hashedpwd123', '0989012345', 'Thanh Xuân, Hà Nội', 'ACTIVE');
INSERT INTO CUSTOMERS (full_name, email, password_hash, phone, address, status) VALUES ('Đỗ Thị Yến', 'yen.do@email.com', 'hashedpwd123', '0990123456', 'Quận 10, TP.HCM', 'ACTIVE');

/* ============================================================================
   👤 PHẦN 2: NAM (Phụ trách: AUTHORS, PUBLISHERS)
============================================================================ */

PROMPT Đang chèn dữ liệu bảng AUTHORS (Nam)...
-- [1-12] 12 Tác giả
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Nguyễn Nhật Ánh', 'Nhà văn chuyên viết cho tuổi mới lớn.', TO_DATE('1955-05-07', 'YYYY-MM-DD'), 'Vietnam');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Dale Carnegie', 'Tác giả, nhà phát triển các lớp kỹ năng tự cải thiện.', TO_DATE('1888-11-24', 'YYYY-MM-DD'), 'USA');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Paulo Coelho', 'Tiểu thuyết gia người Brazil.', TO_DATE('1947-08-24', 'YYYY-MM-DD'), 'Brazil');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Yuval Noah Harari', 'Sử gia, giáo sư khoa Lịch sử tại ĐH Hê-brơ.', TO_DATE('1976-02-24', 'YYYY-MM-DD'), 'Israel');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Tô Hoài', 'Nhà văn Việt Nam, nổi tiếng với Dế Mèn phiêu lưu ký.', TO_DATE('1920-09-27', 'YYYY-MM-DD'), 'Vietnam');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('J.K. Rowling', 'Nhà văn Anh, tác giả loạt truyện Harry Potter.', TO_DATE('1965-07-31', 'YYYY-MM-DD'), 'UK');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('George Orwell', 'Nhà văn, nhà báo Anh.', TO_DATE('1903-06-25', 'YYYY-MM-DD'), 'UK');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Robert Kiyosaki', 'Doanh nhân, nhà đầu tư, tác giả.', TO_DATE('1947-04-08', 'YYYY-MM-DD'), 'USA');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Đặng Hoàng Giang', 'Tiến sĩ kinh tế phát triển, nhà hoạt động xã hội.', TO_DATE('1970-01-01', 'YYYY-MM-DD'), 'Vietnam');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Murakami Haruki', 'Tiểu thuyết gia người Nhật Bản.', TO_DATE('1949-01-12', 'YYYY-MM-DD'), 'Japan');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Trần Đăng Khoa', 'Nhà thơ, nhà báo, biên tập viên Tạp chí Văn nghệ Quân đội.', TO_DATE('1958-04-24', 'YYYY-MM-DD'), 'Vietnam');
INSERT INTO AUTHORS (author_name, biography, birth_date, nationality) VALUES ('Viktor Frankl', 'Bác sĩ tâm thần, người sống sót sau thảm họa Holocaust.', TO_DATE('1905-03-26', 'YYYY-MM-DD'), 'Austria');

PROMPT Đang chèn dữ liệu bảng PUBLISHERS (Nam)...
-- [1-5] 5 Nhà xuất bản
INSERT INTO PUBLISHERS (publisher_name, address, phone, email) VALUES ('NXB Trẻ', '161B Lý Chính Thắng, Quận 3, TP.HCM', '0283931628', 'info@nxbtre.com.vn');
INSERT INTO PUBLISHERS (publisher_name, address, phone, email) VALUES ('NXB Kim Đồng', '55 Quang Trung, Hai Bà Trưng, Hà Nội', '0243943473', 'info@nxbkimdong.com.vn');
INSERT INTO PUBLISHERS (publisher_name, address, phone, email) VALUES ('Nhã Nam', '59 Đỗ Quang, Cầu Giấy, Hà Nội', '0243514687', 'info@nhanam.vn');
INSERT INTO PUBLISHERS (publisher_name, address, phone, email) VALUES ('NXB Tổng hợp TP.HCM', '62 Nguyễn Thị Minh Khai, Quận 1, TP.HCM', '0283822534', 'nxtonghop@tphcm.gov.vn');
INSERT INTO PUBLISHERS (publisher_name, address, phone, email) VALUES ('First News - Trí Việt', '11H Nguyễn Thị Minh Khai, Quận 1, TP.HCM', '0283822797', 'triviet@firstnews.com.vn');

/* ============================================================================
   👤 PHẦN 3: HIẾU (Phụ trách: BOOKS, BOOK_AUTHORS)
============================================================================ */

PROMPT Đang chèn dữ liệu bảng BOOKS (Hiếu)...
-- [1-20] 20 Cuốn sách
-- Category: 1 (Tiểu thuyết), 2 (Kỹ năng), 3 (Kinh tế), 4 (Lịch sử), 5 (Thiếu nhi)
-- Publisher: 1 (Trẻ), 2 (Kim Đồng), 3 (Nhã Nam), 4 (Tổng hợp), 5 (First News)
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Mắt Biếc', '9786041045612', 110000, 50, 2010, 292, 1, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Cho Tôi Xin Một Vé Đi Tuổi Thơ', '9786041162005', 85000, 100, 2008, 220, 1, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Đắc Nhân Tâm', '9786045874288', 76000, 200, 2016, 320, 2, 5);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Nhà Giả Kim', '9786041094030', 69000, 150, 2013, 228, 1, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Sapiens - Lược Sử Loài Người', '9786047732296', 159000, 80, 2017, 504, 4, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Homo Deus - Lược Sử Tương Lai', '9786047748440', 169000, 60, 2018, 516, 4, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Dế Mèn Phiêu Lưu Ký', '9786042106776', 45000, 300, 2015, 150, 5, 2);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Harry Potter Và Hòn Đá Phù Thủy', '9786041113229', 145000, 120, 2017, 368, 1, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('1984', '9786045543265', 98000, 70, 2020, 312, 1, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Trại Súc Vật', '9786046995649', 85000, 60, 2018, 180, 1, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Cha Giàu Cha Nghèo', '9786045862216', 110000, 250, 2015, 360, 3, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Thiện, Ác Và Smartphone', '9786045524318', 115000, 45, 2017, 320, 8, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Tìm Mình Trong Thế Giới Hậu Tuổi Thơ', '9786043003025', 135000, 90, 2020, 364, 8, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Rừng Na Uy', '9786041040334', 125000, 110, 2011, 520, 1, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Biên Niên Ký Chim Vặn Dây Cót', '9786041151665', 180000, 40, 2013, 768, 1, 3);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Tôi Thấy Hoa Vàng Trên Cỏ Xanh', '9786041131155', 92000, 130, 2018, 300, 1, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Harry Potter Và Phòng Chứa Bí Mật', '9786041113236', 155000, 115, 2017, 400, 1, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Dạy Con Làm Giàu Tập 2', '9786045862223', 105000, 150, 2016, 400, 3, 1);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Góc Sân Và Khoảng Trời', '9786042106783', 65000, 55, 2016, 200, 5, 2);
INSERT INTO BOOKS (title, isbn, price, stock_quantity, publication_year, page_count, category_id, publisher_id) VALUES ('Đi Tìm Lẽ Sống', '9786045862316', 82000, 140, 2015, 208, 2, 5);

PROMPT Đang chèn dữ liệu bảng BOOK_AUTHORS (Hiếu)...
-- [1-20] 20 Liên kết (N:N)
-- Authors: 1(NNA), 2(Dale), 3(Paulo), 4(Yuval), 5(To Hoai), 6(JK), 7(George), 8(Robert), 9(Dang Hoang Giang), 10(Murakami)
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (1, 1);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (2, 1);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (3, 2);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (4, 3);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (5, 4);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (6, 4);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (7, 5);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (8, 6);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (9, 7);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (10, 7);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (11, 8);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (12, 9);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (13, 9);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (14, 10);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (15, 10);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (16, 1);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (17, 6);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (18, 8);
-- Sách "Góc Sân Và Khoảng Trời" (19) — gán cho Trần Đăng Khoa (author_id=11)
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (19, 11);
-- Sách Đi Tìm Lẽ Sống (20) do Viktor Frankl (author_id=12) viết chính, thêm Dale Carnegie (ID=2) để demo quan hệ N:N
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (20, 12);
INSERT INTO BOOK_AUTHORS (book_id, author_id) VALUES (20, 2);

/* ============================================================================
   👤 PHẦN 4: PHÁT (Phụ trách: ORDERS, ORDER_DETAILS, REVIEWS)
============================================================================ */

PROMPT Đang chèn dữ liệu bảng ORDERS (Phát)...
-- [1-10] 10 Đơn hàng
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (1, SYSDATE - 10, 269000, 'DELIVERED', 'Quận 1, TP.HCM', 'CREDIT_CARD');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (2, SYSDATE - 8, 145000, 'DELIVERED', 'Ba Đình, Hà Nội', 'COD');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (3, SYSDATE - 7, 289000, 'DELIVERED', 'Hải Châu, Đà Nẵng', 'BANK_TRANSFER');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (1, SYSDATE - 5, 125000, 'CONFIRMED', 'Quận 1, TP.HCM', 'E_WALLET');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (5, SYSDATE - 4, 328000, 'SHIPPING', 'Quận 3, TP.HCM', 'COD');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (7, SYSDATE - 3, 115000, 'DELIVERED', 'Gò Vấp, TP.HCM', 'COD');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (8, SYSDATE - 2, 220000, 'PENDING', 'Liên Chiểu, Đà Nẵng', 'BANK_TRANSFER');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (9, SYSDATE - 1, 155000, 'CANCELLED', 'Thanh Xuân, Hà Nội', 'COD');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (10, SYSDATE, 273000, 'PENDING', 'Quận 10, TP.HCM', 'E_WALLET');
INSERT INTO ORDERS (customer_id, order_date, total_amount, status, shipping_address, payment_method) VALUES (2, SYSDATE, 183000, 'PENDING', 'Ba Đình, Hà Nội', 'CREDIT_CARD');

PROMPT Đang chèn dữ liệu bảng ORDER_DETAILS (Phát)...
-- [1-15] 15 Chi tiết đơn hàng
-- Order 1: Book 1 (110k * 1) + Book 5 (159k * 1) = 269k
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (1, 1, 1, 110000);
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (1, 5, 1, 159000);
-- Order 2: Book 8 (145k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (2, 8, 1, 145000);
-- Order 3: Book 4 (69k * 1) + Book 11 (110k * 2) = 69k + 220k = 289k
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (3, 4, 1, 69000);
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (3, 11, 2, 110000);
-- Order 4: Book 14 (125k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (4, 14, 1, 125000);
-- Order 5: Book 5 (159k * 1) + Book 6 (169k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (5, 5, 1, 159000);
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (5, 6, 1, 169000);
-- Order 6: Book 12 (115k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (6, 12, 1, 115000);
-- Order 7: Book 1 (110k * 2)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (7, 1, 2, 110000);
-- Order 8: Book 9 (98k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (8, 9, 1, 98000);
-- Order 9: Book 17 (155k * 1)
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (9, 17, 1, 155000);
-- Order 10: Book 2 (85k * 1) + Book 9 (98k * 1) + Book 7 (45k * 2) = 85k + 98k + 90k = 273k
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (10, 2, 1, 85000);
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (10, 9, 1, 98000);
INSERT INTO ORDER_DETAILS (order_id, book_id, quantity, unit_price) VALUES (10, 7, 2, 45000);

PROMPT Đang chèn dữ liệu bảng REVIEWS (Phát)...
-- [1-10] 10 Đánh giá
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (1, 1, 5, 'Sách quá hay, Nguyễn Nhật Ánh muôn năm!', SYSDATE - 5);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (1, 5, 4, 'Sách cung cấp nhiều kiến thức lịch sử sâu sắc.', SYSDATE - 2);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (2, 8, 5, 'Truyện rất tuổi thơ, giao hàng nhanh.', SYSDATE - 3);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (3, 4, 5, 'Đọc xong nhà giả kim, tôi đã tìm ra sứ mệnh đời mình.', SYSDATE - 1);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (5, 5, 4, 'Đáng đọc, tuy nhiên hơi khó hiểu ở một số phần.', SYSDATE - 1);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (7, 12, 5, 'Tác giả viết rất thực tế về văn hóa mạng.', SYSDATE - 1);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (10, 2, 4, 'Truyện dễ thương, nhớ quá kỉ niệm tuổi nhóc tì.', SYSDATE);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (2, 9, 5, 'Tác phẩm kinh điển đáng suy ngẫm.', SYSDATE);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (8, 1, 5, 'Tôi đã khóc khi đọc chương cuối.', SYSDATE);
INSERT INTO REVIEWS (customer_id, book_id, rating, review_comment, review_date) VALUES (9, 17, 5, 'Ghiền Harry Potter từ xưa giờ.', SYSDATE);

PROMPT ================================================
PROMPT ✅ HOÀN TẤT CHÈN 111 BẢN GHI DỮ LIỆU MẪU!
PROMPT Đã chia đều công việc cho Dũng, Nam, Hiếu, Phát.
PROMPT ================================================

COMMIT;
PROMPT Đã COMMIT dữ liệu thành công!
