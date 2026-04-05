-- ==========================================================
-- FILE: 3_insert_data.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Nhập dữ liệu mẫu (DML) - Tối thiểu 100 bản ghi có ý nghĩa
-- TỔNG SỐ BẢN GHI: ~250+ records
-- ==========================================================

-- ==========================================================
-- PHẦN 0: DỌN DẸP DỮ LIỆU CŨ (Để hỗ trợ chạy lại script nhiều lần)
-- ==========================================================
SET DEFINE ON;

-- 0.1. Xóa dữ liệu các bảng theo thứ tự ngược lại (bảng con trước, bảng cha sau)
DELETE FROM wishlists;
DELETE FROM reviews;
DELETE FROM payment_transactions;
DELETE FROM coupons;
DELETE FROM inventory_transactions;
DELETE FROM transfer_details;
DELETE FROM inventory_transfers;
DELETE FROM branch_inventory;
DELETE FROM order_status_history;
DELETE FROM order_details;
DELETE FROM orders;
DELETE FROM cart_items;
DELETE FROM carts;
DELETE FROM shipping_methods;
DELETE FROM customers;
DELETE FROM book_authors;
DELETE FROM books;
DELETE FROM publishers;
DELETE FROM categories;
DELETE FROM authors;
DELETE FROM staff;

-- Giữ lại user 'admin' và chi nhánh 'HQ001' đã tạo ở file 2
DELETE FROM users WHERE username != 'admin';
DELETE FROM branches WHERE branch_code != 'HQ001';

COMMIT;

-- ==========================================================
-- PHẦN 1: DỮ LIỆU CỦA DŨNG (Hệ thống & Chi nhánh)
-- ==========================================================

-- 1.1. Chi nhánh bổ sung (Đã có HQ001 trong file 2)
INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('HN002', N'Chi nhánh Hà Nội', 'STORE', N'Số 45 Tràng Tiền, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', '02438234567', 'hanoi@digibook.com', 'ACTIVE', 0, TO_DATE('2023-03-15', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('DN003', N'Chi nhánh Đà Nẵng', 'STORE', N'168 Nguyễn Văn Linh, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', '0236367890', 'danang@digibook.com', 'ACTIVE', 0, TO_DATE('2023-06-20', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, email, status, is_main_branch, opening_date) 
VALUES ('CT004', N'Chi nhánh Cần Thơ', 'STORE', N'12 Nguyễn Trãi, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', '0292387654', 'cantho@digibook.com', 'ACTIVE', 0, TO_DATE('2023-09-10', 'YYYY-MM-DD'));

INSERT INTO branches (branch_code, branch_name, branch_type, address, province, district, phone, status, is_main_branch, opening_date) 
VALUES ('KHO_HCM', N'Kho trung chuyển TP.HCM', 'WAREHOUSE', N'KCN Tân Bình, Quận Tân Phú', N'TP. Hồ Chí Minh', N'Quận Tân Phú', '0283765432', 'ACTIVE', 0, TO_DATE('2023-01-01', 'YYYY-MM-DD'));

-- 1.2. Người dùng bổ sung (Đã có admin)
INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('manager_hn', 'manager.hn@digibook.com', 'HASH_MGR_HN', N'Nguyễn Văn Dũng', 'MANAGER', '0912345678', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('staff_sale_01', 'sale01@digibook.com', 'HASH_SALE01', N'Trần Thị Bán Hàng', 'STAFF', '0923456789', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('staff_kho', 'kho@digibook.com', 'HASH_KHO', N'Lê Văn Kho', 'STAFF', '0934567890', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('support_01', 'support@digibook.com', 'HASH_SP', N'Phạm Thị Hỗ Trợ', 'SUPPORT', '0945678901', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('manager_dn', 'manager.dn@digibook.com', 'HASH_MGR_DN', N'Hoàng Văn Đà Nẵng', 'MANAGER', '0909123456', 1);

INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active) 
VALUES ('admin_cslt', 'admin.cslt@digibook.com', 'HASH_CSLT', N'Admin Cơ Sở Lưu Trữ', 'ADMIN', '0908234567', 1);

-- 1.3. Nhân viên (Staff)
INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'admin'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV001', N'Quản lý hệ thống', 'ADMIN', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 25000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'manager_hn'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'NV002', N'Quản lý chi nhánh HN', 'MANAGEMENT', TO_DATE('2023-03-15', 'YYYY-MM-DD'), 20000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'staff_sale_01'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV003', N'Nhân viên bán hàng', 'SALES', TO_DATE('2023-02-01', 'YYYY-MM-DD'), 8000000, 'ACTIVE', 0, 0);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'staff_kho'), (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), 'NV004', N'Thủ kho', 'WAREHOUSE', TO_DATE('2023-01-15', 'YYYY-MM-DD'), 9000000, 'ACTIVE', 0, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'support_01'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'NV005', N'Nhân viên CSKH', 'SUPPORT', TO_DATE('2023-04-01', 'YYYY-MM-DD'), 7500000, 'ACTIVE', 0, 0);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'manager_dn'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'NV006', N'Quản lý chi nhánh ĐN', 'MANAGEMENT', TO_DATE('2023-06-20', 'YYYY-MM-DD'), 19000000, 'ACTIVE', 1, 1);

INSERT INTO staff (user_id, branch_id, staff_code, job_title, department, hire_date, base_salary, status, can_approve_order, can_manage_stock) 
VALUES ((SELECT user_id FROM users WHERE username = 'admin_cslt'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'NV007', N'Quản lý chi nhánh CT', 'MANAGEMENT', TO_DATE('2023-09-10', 'YYYY-MM-DD'), 18500000, 'ACTIVE', 1, 1);

COMMIT;

-- ==========================================================
-- PHẦN 2: DỮ LIỆU CỦA NAM (Danh mục sản phẩm)
-- ==========================================================

-- 2.1. Danh mục sách (Categories) - Cấu trúc cây
INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Văn học', NULL, N'Sách văn học trong và ngoài nước', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Kinh tế', NULL, N'Sách kinh tế, quản trị, marketing', 2, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Kỹ năng sống', NULL, N'Sách kỹ năng mềm, phát triển bản thân', 3, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Khoa học - Kỹ thuật', NULL, N'Sách khoa học, công nghệ, lập trình', 4, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Thiếu nhi', NULL, N'Sách cho trẻ em và thanh thiếu niên', 5, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Lịch sử - Địa lý', NULL, N'Sách lịch sử, địa danh thế giới', 6, 1);

-- Sub-categories cho Văn học
INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Tiểu thuyết', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Tiểu thuyết các loại', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Truyện ngắn', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Tập truyện ngắn', 2, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Thơ ca', (SELECT category_id FROM categories WHERE category_name = N'Văn học'), N'Thơ và tuyển tập thơ', 3, 1);

-- Sub-categories cho Kinh tế
INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Quản trị - Lãnh đạo', (SELECT category_id FROM categories WHERE category_name = N'Kinh tế'), N'Sách về quản trị doanh nghiệp', 1, 1);

INSERT INTO categories (category_name, parent_id, description, display_order, is_active) 
VALUES (N'Marketing - Bán hàng', (SELECT category_id FROM categories WHERE category_name = N'Kinh tế'), N'Marketing và kỹ năng bán hàng', 2, 1);

-- 2.2. Tác giả (Authors)
INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nguyễn Nhật Ánh', N'Nhà văn nổi tiếng với các tác phẩm thiếu nhi và tuổi mới lớn', TO_DATE('1955-05-07', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Tô Hoài', N'Nhà văn, nhà báo với tác phẩm Dế Mèn phiêu lưu ký', TO_DATE('1920-09-27', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Paulo Coelho', N'Nhà văn Brazil nổi tiếng với Nhà giả kim', TO_DATE('1947-08-24', 'YYYY-MM-DD'), N'Brazil');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'J.K. Rowling', N'Tác giả bộ truyện Harry Potter', TO_DATE('1965-07-31', 'YYYY-MM-DD'), N'Anh');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Dale Carnegie', N'Tác giả sách kỹ năng giao tiếp nổi tiếng', TO_DATE('1888-11-24', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Robert Kiyosaki', N'Tác giả Dạy con làm giàu', TO_DATE('1947-04-08', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Stephen Hawking', N'Nhà vật lý lý thuyết nổi tiếng', TO_DATE('1942-01-08', 'YYYY-MM-DD'), N'Anh');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Yuval Noah Harari', N'Sử gia Israel, tác giả Sapiens', TO_DATE('1976-02-24', 'YYYY-MM-DD'), N'Israel');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nguyễn Du', N'Đại thi hào dân tộc', TO_DATE('1765-01-03', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Nam Cao', N'Nhà văn hiện thực phê phán', TO_DATE('1915-10-29', 'YYYY-MM-DD'), N'Việt Nam');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Fujiko F. Fujio', N'Tác giả bộ truyện Doraemon', TO_DATE('1933-12-01', 'YYYY-MM-DD'), N'Nhật Bản');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Daniel Kahneman', N'Nhà tâm lý học đoạt giải Nobel', TO_DATE('1934-03-05', 'YYYY-MM-DD'), N'Mỹ');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Eckhart Tolle', N'Tác giả sách tâm linh nổi tiếng', TO_DATE('1948-02-16', 'YYYY-MM-DD'), N'Đức');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Malcolm Gladwell', N'Nhà báo và tác giả sách best-seller', TO_DATE('1963-09-03', 'YYYY-MM-DD'), N'Canada');

INSERT INTO authors (author_name, biography, birth_date, nationality) 
VALUES (N'Vũ Trọng Phụng', N'Nhà văn hiện thực phê phán', TO_DATE('1912-10-20', 'YYYY-MM-DD'), N'Việt Nam');

-- 2.3. Nhà xuất bản (Publishers)
INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Trẻ', N'161B Lý Chính Thắng, Q.3, TP.HCM', '02839316289', 'info@nxbtre.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Kim Đồng', N'55 Quang Trung, Hà Nội', '02439434730', 'info@nxbkimdong.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Giáo dục Việt Nam', N'81 Trần Hưng Đạo, Hà Nội', '02438220801', 'nxbgd@moet.edu.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Nhã Nam', N'59 Đỗ Quang, Hà Nội', '02435146876', 'contact@nhanam.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Alpha Books', N'176 Thái Hà, Hà Nội', '02463297200', 'info@alphabooks.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'First News', N'11H Nguyễn Thị Minh Khai, Q.1, TP.HCM', '02838227979', 'info@firstnews.com.vn');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'NXB Văn học', N'18 Nguyễn Trường Tộ, Hà Nội', '02437161518', 'nxbvanhoc@yahoo.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Bloomsbury', N'50 Bedford Square, London', '+442074315600', 'info@bloomsbury.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'HarperCollins', N'195 Broadway, New York', '+12122077000', 'info@harpercollins.com');

INSERT INTO publishers (publisher_name, address, phone, email) 
VALUES (N'Penguin Random House', N'1745 Broadway, New York', '+12127829000', 'info@penguinrandomhouse.com');

-- 2.4. Sách (Books)
INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026700', N'Nhà Giả Kim', N'Câu chuyện về Santiago và hành trình tìm kiếm kho báu', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 89000, 300, '20x14x2', 228, 2020, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042088592', N'Harry Potter và Hòn đá Phù thủy', N'Tập 1 series Harry Potter', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Bloomsbury'), 185000, 450, '21x15x3', 366, 2019, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026670', N'Đắc Nhân Tâm', N'Nghệ thuật thu phục lòng người', (SELECT category_id FROM categories WHERE category_name = N'Marketing - Bán hàng'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'First News'), 95000, 350, '20x14x2.5', 320, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041038796', N'Dạy Con Làm Giàu - Tập 1', N'Những bài học tài chính cho trẻ', (SELECT category_id FROM categories WHERE category_name = N'Quản trị - Lãnh đạo'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'First News'), 108000, 400, '21x15x2', 320, 2022, 'vi', 'PAPERBACK', 1, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026694', N'Tôi Thấy Hoa Vàng Trên Cỏ Xanh', N'Truyện dài về tuổi thơ', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 120000, 380, '20x14x2.5', 300, 2020, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041063804', N'Đất Rừng Phương Nam', N'Tiểu thuyết về Nam Bộ', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 145000, 500, '21x15x3', 450, 2021, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042086055', N'Doraemon - Tập 1', N'Truyện tranh Nhật Bản', (SELECT category_id FROM categories WHERE category_name = N'Thiếu nhi'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Kim Đồng'), 25000, 150, '18x13x1', 192, 2023, 'vi', 'PAPERBACK', 0, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026717', N'Think and Grow Rich', N'Nghĩ giàu làm giàu', (SELECT category_id FROM categories WHERE category_name = N'Quản trị - Lãnh đạo'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Alpha Books'), 115000, 420, '21x15x2', 350, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041038802', N'Sapiens: Lược Sử Loài Người', N'Sử học về sự tiến hóa của con người', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 175000, 550, '24x17x3', 560, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026724', N'Tâm Lý Học Đám Đông', N'Nghiên cứu về tâm lý quần chúng', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 85000, 320, '20x14x2', 280, 2019, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041045022', N'Vũ Trọng Phụng - Tuyển tập', N'Các tác phẩm hay của Vũ Trọng Phụng', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Văn học'), 165000, 480, '21x15x2.8', 420, 2022, 'vi', 'HARDCOVER', 0, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041050019', N'Lược Sử Tương Lai', N'Về những thách thức của nhân loại', (SELECT category_id FROM categories WHERE category_name = N'Khoa học - Kỹ thuật'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Nhã Nam'), 195000, 600, '24x17x3.5', 520, 2023, 'vi', 'PAPERBACK', 1, 1, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026731', N'Ngồi Khóc Trên Cây', N'Truyện dài về tình bạn và tuổi học trò', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 95000, 340, '20x14x2', 280, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786042088608', N'Harry Potter và Phòng Chứa Bí Mật', N'Tập 2 Harry Potter', (SELECT category_id FROM categories WHERE category_name = N'Lịch sử - Địa lý'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'Bloomsbury'), 195000, 480, '21x15x3.2', 400, 2020, 'vi', 'PAPERBACK', 0, 0, 1);

INSERT INTO books (isbn, title, description, category_id, publisher_id, price, weight_gram, dimensions, page_count, publication_year, language, cover_type, is_featured, is_new_arrival, is_active) 
VALUES ('9786041026748', N'Mắt Biếc', N'Truyện tình yêu tuổi học trò', (SELECT category_id FROM categories WHERE category_name = N'Tiểu thuyết'), (SELECT publisher_id FROM publishers WHERE publisher_name = N'NXB Trẻ'), 105000, 360, '20x14x2.2', 320, 2021, 'vi', 'PAPERBACK', 1, 0, 1);

-- 2.5. Hình ảnh sách (Book Images)
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026700'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8935235236271.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088592'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8934974179672.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026670'), 'https://cdn1.fahasa.com/media/catalog/product/9/7/9786043949247.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038796'), 'https://cdn1.fahasa.com/media/catalog/product/i/m/image_66848.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026694'), 'https://cdn1.fahasa.com/media/catalog/product/n/n/nna-hvtcx.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041063804'), 'https://cdn1.fahasa.com/media/catalog/product/d/a/dat-rung-phuong-nam-bia.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), 'https://cdn1.fahasa.com/media/catalog/product/d/o/doraemon-do-vui_tap1_doraemon-xuat-hien_tb-2023.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026717'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8935086825754.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8935270703554.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026724'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8935270703561.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041045022'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8936046617570.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041050019'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8935235239135.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026731'), 'https://cdn1.fahasa.com/media/catalog/product/i/m/image_244718_1_6181.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088608'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8934974100232.jpg', 1, 0);
INSERT INTO book_images (book_id, image_url, is_main, sort_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026748'), 'https://cdn1.fahasa.com/media/catalog/product/8/9/8934974178637.jpg', 1, 0);

-- 2.6. Quan hệ sách - tác giả (Book Authors) - Xử lý nhiều tác giả/đóng góp viên
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026700'), (SELECT author_id FROM authors WHERE author_name = N'Paulo Coelho'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088592'), (SELECT author_id FROM authors WHERE author_name = N'J.K. Rowling'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026670'), (SELECT author_id FROM authors WHERE author_name = N'Dale Carnegie'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038796'), (SELECT author_id FROM authors WHERE author_name = N'Robert Kiyosaki'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026694'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041063804'), (SELECT author_id FROM authors WHERE author_name = N'Tô Hoài'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT author_id FROM authors WHERE author_name = N'Fujiko F. Fujio'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT author_id FROM authors WHERE author_name = N'Fujiko F. Fujio'), 'ILLUSTRATOR', 2);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026717'), (SELECT author_id FROM authors WHERE author_name = N'Dale Carnegie'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'TRANSLATOR', 2);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026724'), (SELECT author_id FROM authors WHERE author_name = N'Paulo Coelho'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041045022'), (SELECT author_id FROM authors WHERE author_name = N'Vũ Trọng Phụng'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041050019'), (SELECT author_id FROM authors WHERE author_name = N'Yuval Noah Harari'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026731'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786042088608'), (SELECT author_id FROM authors WHERE author_name = N'J.K. Rowling'), 'AUTHOR', 1);
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES ((SELECT book_id FROM books WHERE isbn = '9786041026748'), (SELECT author_id FROM authors WHERE author_name = N'Nguyễn Nhật Ánh'), 'AUTHOR', 1);

COMMIT;

-- ==========================================================
-- PHẦN 3: DỮ LIỆU CỦA HIẾU (Khách hàng & Bán hàng)
-- ==========================================================

-- 3.1. Khách hàng (Customers)
INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Trần Văn Khách Hàng', 'tran.van.khach@gmail.com', '0909123456', N'123 Nguyễn Văn Cừ, Q.5', N'TP. Hồ Chí Minh', N'Quận 5', TO_DATE('1990-05-15', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Nguyễn Thị Mua Sách', 'nguyen.thi.mua@yahoo.com', '0918234567', N'45 Tràng Tiền, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', TO_DATE('1995-08-20', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'HN002'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Lê Văn Đọc Giả', 'le.van.doc@gmail.com', '0927345678', N'78 Nguyễn Văn Linh, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', TO_DATE('1988-12-10', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'DN003'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Phạm Thị Học Sinh', 'pham.thi.hs@gmail.com', '0936456789', N'12/4 Đường 3/2, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', TO_DATE('2002-03-25', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'CT004'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Hoàng Văn Giáo Sư', 'hoang.van.gs@edu.vn', '0945567890', N'56 Lý Tự Trọng, Q.1', N'TP. Hồ Chí Minh', N'Quận 1', TO_DATE('1975-11-08', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Vũ Thị Sinh Viên', 'vu.thi.sv@student.edu.vn', '0956678901', N'KTX ĐHQG, Thủ Đức', N'TP. Hồ Chí Minh', N'Thành phố Thủ Đức', TO_DATE('2000-09-12', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Đặng Văn Doanh Nhân', 'dang.van.dn@company.vn', '0967789012', N'Tòa nhà Bitexco, Q.1', N'TP. Hồ Chí Minh', N'Quận 1', TO_DATE('1980-07-30', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Bùi Thị Nội Trợ', 'bui.thi.nt@gmail.com', '0978890123', N'234 Lê Lợi, Hải Châu', N'Đà Nẵng', N'Quận Hải Châu', TO_DATE('1992-04-18', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'DN003'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Ngô Văn Công Chức', 'ngo.van.cc@gmail.com', '0989901234', N'89 Trần Phú, Hoàn Kiếm', N'Hà Nội', N'Quận Hoàn Kiếm', TO_DATE('1985-06-05', 'YYYY-MM-DD'), 'MALE', (SELECT branch_id FROM branches WHERE branch_code = 'HN002'));

INSERT INTO customers (full_name, email, phone, address, province, district, date_of_birth, gender, preferred_branch_id) 
VALUES (N'Lý Thị Giáo Viên', 'ly.thi.gv@school.edu.vn', '0990012345', N'101 Hùng Vương, Ninh Kiều', N'Cần Thơ', N'Quận Ninh Kiều', TO_DATE('1983-10-22', 'YYYY-MM-DD'), 'FEMALE', (SELECT branch_id FROM branches WHERE branch_code = 'CT004'));

-- 3.2. Phương thức vận chuyển (Shipping Methods)
INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng tiêu chuẩn', 'GHN_STD', 'GHN', 25000, 5000, 300000, 3, 5, 1, 1);

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng nhanh', 'GHTK_FAST', 'GHTK', 35000, 8000, 500000, 1, 2, 1, 2);

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Giao hàng hỏa tốc', 'NOW', 'AhaMove', 60000, 15000, NULL, 2, 4, 1, 3); -- Theo giờ, tính theo giờ làm việc

INSERT INTO shipping_methods (method_name, method_code, carrier, base_fee, weight_fee_per_kg, free_threshold, estimated_days_min, estimated_days_max, is_active, display_order) 
VALUES (N'Nhận tại cửa hàng', 'PICKUP', 'STORE', 0, 0, 0, 0, 0, 1, 4);

-- 3.3. Giỏ hàng (Carts)
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 2);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'ACTIVE', SYSDATE - 1);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'ABANDONED', SYSDATE - 10);
INSERT INTO carts (customer_id, branch_id, status, converted_to_order_id, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'CONVERTED', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), SYSDATE - 5);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 3);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'ACTIVE', SYSDATE - 1);
INSERT INTO carts (customer_id, branch_id, status, created_at) VALUES ((SELECT customer_id FROM customers WHERE email = 'bui.thi.nt@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'ACTIVE', SYSDATE - 4);

-- 3.4. Chi tiết giỏ hàng (Cart Items)
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 2, 89000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1, 95000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 1, 175000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 1, 85000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com') AND status = 'ABANDONED'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 3, 120000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 5, 25000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041026748'), 1, 105000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 2, 108000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), 1, 195000);
INSERT INTO cart_items (cart_id, book_id, quantity, unit_price) VALUES ((SELECT cart_id FROM carts WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'bui.thi.nt@gmail.com') AND status = 'ACTIVE'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 1, 185000);

-- 3.5. Đơn hàng (Orders)
INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD001', (SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'DELIVERED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 245000, 0, 25000, 270000, SYSDATE - 10, N'12/4 Đường 3/2', N'Cần Thơ', N'Ninh Kiều', '0936456789');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD002', (SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'SHIPPING', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHTK_FAST'), 273000, 0, 35000, 308000, SYSDATE - 3, N'123 Nguyễn Văn Cừ', N'TP. Hồ Chí Minh', N'Quận 5', '0909123456');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD003', (SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'PENDING', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 175000, 20000, 25000, 180000, SYSDATE - 1, N'45 Tràng Tiền', N'Hà Nội', N'Hoàn Kiếm', '0918234567');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone, cancelled_at, cancellation_reason) 
VALUES ('ORD004', (SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'CANCELLED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 89000, 0, 0, 0, SYSDATE - 5, N'78 Nguyễn Văn Linh', N'Đà Nẵng', N'Hải Châu', '0927345678', SYSDATE - 4, N'Khách đổi ý không mua nữa');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD005', (SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'CONFIRMED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHN_STD'), 450000, 50000, 0, 400000, SYSDATE - 2, N'56 Lý Tự Trọng', N'TP. Hồ Chí Minh', N'Quận 1', '0945567890');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD006', (SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'PENDING', (SELECT method_id FROM shipping_methods WHERE method_code = 'PICKUP'), 230000, 0, 0, 230000, SYSDATE, N'KTX ĐHQG', N'TP. Hồ Chí Minh', N'Thủ Đức', '0956678901');

INSERT INTO orders (order_code, customer_id, branch_id, status_code, shipping_method_id, total_amount, discount_amount, shipping_fee, final_amount, order_date, ship_address, ship_province, ship_district, ship_phone) 
VALUES ('ORD007', (SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'DELIVERED', (SELECT method_id FROM shipping_methods WHERE method_code = 'GHTK_FAST'), 520000, 0, 35000, 555000, SYSDATE - 15, N'Tòa nhà Bitexco', N'TP. Hồ Chí Minh', N'Quận 1', '0967789012');

-- 3.6. Chi tiết đơn hàng (Order Details)
-- ORD001
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 5, 25000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 1, 95000);

-- ORD002
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 1, 89000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1, 95000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 1, 120000);

-- ORD003
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD003'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 1, 175000);

-- ORD004 (Cancelled)
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 1, 89000);

-- ORD005
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 1, 185000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 1, 108000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD005'), (SELECT book_id FROM books WHERE isbn = '9786041063804'), 1, 145000);

-- ORD006
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD006'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 1, 85000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD006'), (SELECT book_id FROM books WHERE isbn = '9786042088608'), 1, 195000);

-- ORD007
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 2, 175000);
INSERT INTO order_details (order_id, book_id, quantity, unit_price) VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), 1, 195000);

-- 3.7. Lịch sử trạng thái đơn hàng (Order Status History)
INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), NULL, 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'), SYSDATE - 10, N'Tạo đơn hàng mới');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'PENDING', 'CONFIRMED', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'), SYSDATE - 9, N'Xác nhận thanh toán');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'CONFIRMED', 'SHIPPING', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), SYSDATE - 8, N'Giao cho đơn vị vận chuyển');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'SHIPPING', 'DELIVERED', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), SYSDATE - 6, N'Khách đã nhận hàng');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), NULL, 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV006'), SYSDATE - 5, N'Tạo đơn');

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, changed_at, reason) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD004'), 'PENDING', 'CANCELLED', (SELECT staff_id FROM staff WHERE staff_code = 'NV006'), SYSDATE - 4, N'Khách hủy đơn');

COMMIT;

-- ==========================================================
-- PHẦN 4: DỮ LIỆU CỦA PHÁT (Kho vận & Nghiệp vụ khác)
-- ==========================================================

-- 4.1. Tồn kho chi nhánh (Branch Inventory)
-- Chi nhánh 1 (HQ)
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 50, 2, 10, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 30, 1, 5, 'A', 'A02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 100, 0, 20, 'B', 'B01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), 45, 1, 10, 'B', 'B02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 25, 0, 5, 'A', 'A03');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 200, 5, 30, 'C', 'C01');

-- Chi nhánh 2 (Hà Nội)
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 30, 0, 10, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 20, 1, 5, 'A', 'A02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HN002'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), 15, 0, 5, 'B', 'B01');

-- Chi nhánh 3 (Đà Nẵng) - ít hàng hơn
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'DN003'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 8, 0, 5, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'DN003'), (SELECT book_id FROM books WHERE isbn = '9786041026694'), 5, 0, 3, 'A', 'A02');

-- Chi nhánh 4 (Cần Thơ)
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 100, 0, 20, 'A', 'A01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 20, 0, 5, 'A', 'A02');

-- Kho trung chuyển (5) - Chứa nhiều hàng nhất
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 500, 0, 50, 'KHO', 'K01');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 300, 0, 30, 'KHO', 'K02');
INSERT INTO branch_inventory (branch_id, book_id, quantity_available, quantity_reserved, low_stock_threshold, warehouse_zone, shelf_code) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 1000, 0, 100, 'KHO', 'K03');

-- 4.2. Phiếu điều chuyển kho (Inventory Transfers)
INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC001', (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'TRANSFER', 'COMPLETED', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'), (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), 3, 150, SYSDATE - 30, N'Nhập hàng đầu tháng cho chi nhánh chính');

INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC002', (SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'TRANSFER', 'SHIPPING', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'), (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), 2, 50, SYSDATE - 2, N'Bổ sung hàng cho chi nhánh Hà Nội');

INSERT INTO inventory_transfers (transfer_code, from_branch_id, to_branch_id, transfer_type, status, requested_by, approved_by, total_items, total_quantity, request_date, notes) 
VALUES ('DC003', (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT branch_id FROM branches WHERE branch_code = 'DN003'), 'TRANSFER', 'PENDING', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'), NULL, 1, 20, SYSDATE, N'Chuyển hàng dư từ HCM sang Đà Nẵng');

-- 4.3. Chi tiết điều chuyển (Transfer Details)
-- DC001 (Completed)
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 50, 50, 50, 45000);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 30, 30, 30, 95000);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received, unit_cost) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), (SELECT book_id FROM books WHERE isbn = '9786041026670'), 70, 70, 70, 50000);

-- DC002 (Shipping)
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC002'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 20, 20, 0);
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC002'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), 30, 30, 0);

-- DC003 (Pending)
INSERT INTO transfer_details (transfer_id, book_id, quantity_requested, quantity_shipped, quantity_received) 
VALUES ((SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC003'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 20, 0, 0);

-- 4.4. Giao dịch kho (Inventory Transactions)
-- Nhập hàng ban đầu
INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'IN', 'INITIAL', 1000, 45000, N'Nhập kho đầu kỳ', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), 'IN', 'INITIAL', 600, 95000, N'Nhập kho đầu kỳ', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

-- Xuất bán (từ chi nhánh 4 - Cần Thơ cho đơn ORD001)
INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), 'OUT', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'ORDER', -5, 15000, N'Bán hàng đơn ORD001', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, unit_cost, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'CT004'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), 'OUT', (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 'ORDER', -1, 60000, N'Bán hàng đơn ORD001', (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

-- Điều chuyển (Transfer)
INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'KHO_HCM'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'TRANSFER_OUT', (SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), 'TRANSFER', -50, N'Điều chuyển đến chi nhánh 1', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'));

INSERT INTO inventory_transactions (branch_id, book_id, txn_type, reference_id, reference_type, quantity, notes, created_by) 
VALUES ((SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), 'TRANSFER_IN', (SELECT transfer_id FROM inventory_transfers WHERE transfer_code = 'DC001'), 'TRANSFER', 50, N'Nhận từ kho trung chuyển', (SELECT staff_id FROM staff WHERE staff_code = 'NV004'));

-- 4.5. Mã giảm giá (Coupons)
INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('WELCOME', N'Chào mừng thành viên mới', N'Giảm 10% cho đơn hàng đầu tiên', 'PERCENT', 10, 100000, 50000, 100, 1, SYSDATE - 30, SYSDATE + 365, 1, NULL, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('SALE50K', N'Giảm 50K', N'Giảm trực tiếp 50.000đ', 'FIXED', 50000, 200000, NULL, 50, 2, SYSDATE - 10, SYSDATE + 20, 1, '["1","2"]', (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, per_customer_limit, start_date, end_date, is_active, applicable_branches, created_by) 
VALUES ('SUMMER2024', N'Khuyến mãi hè', N'Giảm 20% cho sách thiếu nhi', 'PERCENT', 20, 150000, 100000, 200, 5, SYSDATE, TO_DATE('2026-08-31', 'YYYY-MM-DD'), 1, NULL, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

INSERT INTO coupons (coupon_code, coupon_name, discount_type, discount_value, min_order_amount, start_date, end_date, is_active, usage_count, created_by) 
VALUES ('EXPIRED', N'Coupon hết hạn', 'PERCENT', 15, 100000, SYSDATE - 60, SYSDATE - 30, 0, 50, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'));

-- 4.6. Thanh toán (Payment Transactions)
-- Thanh toán cho ORD001 (Success)
INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD001'), (SELECT branch_id FROM branches WHERE branch_code = 'CT004'), 'COD', 270000, 'VND', 'SUCCESS', 'COD001', SYSDATE - 6, (SELECT staff_id FROM staff WHERE staff_code = 'NV007'));

-- Thanh toán cho ORD002 (Pending)
INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD002'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'MOMO', 308000, 'VND', 'PENDING', 'MOMO20240327001', (SELECT staff_id FROM staff WHERE staff_code = 'NV003'));

-- Thanh toán cho ORD003 (Success - dùng Coupon)
INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD003'), (SELECT branch_id FROM branches WHERE branch_code = 'HN002'), 'BANK_TRANSFER', 180000, 'VND', 'SUCCESS', 'BANK20240326001', SYSDATE - 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV002'));

-- Thanh toán cho ORD007 (Credit Card)
INSERT INTO payment_transactions (order_id, branch_id, payment_method, amount, currency, status, transaction_code, paid_at, created_by) 
VALUES ((SELECT order_id FROM orders WHERE order_code = 'ORD007'), (SELECT branch_id FROM branches WHERE branch_code = 'HQ001'), 'CREDIT_CARD', 555000, 'VND', 'SUCCESS', 'VISA20240310001', SYSDATE - 15, (SELECT staff_id FROM staff WHERE staff_code = 'NV003'));

-- 4.7. Đánh giá sản phẩm (Reviews)
INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786042086055'), (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 5, N'Sách hay, con tôi rất thích đọc Doraemon!', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 5, 3);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'pham.thi.hs@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041026731'), (SELECT order_id FROM orders WHERE order_code = 'ORD001'), 4, N'Truyện hay nhưng giao hàng hơi chậm', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 5, 1);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT order_id FROM orders WHERE order_code = 'ORD007'), 5, N'Sapiens là cuốn sách tuyệt vời, nên đọc!', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 10, 10);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved, approved_by, approved_at, helpful_count) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'dang.van.dn@company.vn'), (SELECT book_id FROM books WHERE isbn = '9786041050019'), (SELECT order_id FROM orders WHERE order_code = 'ORD007'), 5, N'Tương lai của nhân loại qua góc nhìn thú vị', 1, (SELECT staff_id FROM staff WHERE staff_code = 'NV001'), SYSDATE - 10, 5);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), (SELECT order_id FROM orders WHERE order_code = 'ORD002'), 5, N'Nhà Giả Kim thay đổi cuộc đời tôi', 0);

INSERT INTO reviews (customer_id, book_id, order_id, rating, comment_text, is_approved) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), (SELECT order_id FROM orders WHERE order_code = 'ORD003'), 4, N'Hay nhưng dài quá', 0);

-- 4.8. Wishlists (Danh sách yêu thích)
INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786042088592'), SYSDATE - 5, N'Muốn mua tập 2 Harry Potter');

INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'tran.van.khach@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041038796'), SYSDATE - 3, N'Để dành mua sau');

INSERT INTO wishlists (customer_id, book_id, added_at) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'nguyen.thi.mua@yahoo.com'), (SELECT book_id FROM books WHERE isbn = '9786041026700'), SYSDATE - 10);

INSERT INTO wishlists (customer_id, book_id, added_at, note) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'le.van.doc@gmail.com'), (SELECT book_id FROM books WHERE isbn = '9786041038802'), SYSDATE - 2, N'Sách này hay quá nhưng chưa có tiền mua');

INSERT INTO wishlists (customer_id, book_id, added_at, is_notified) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'hoang.van.gs@edu.vn'), (SELECT book_id FROM books WHERE isbn = '9786041026748'), SYSDATE - 20, 1);

INSERT INTO wishlists (customer_id, book_id, added_at) 
VALUES ((SELECT customer_id FROM customers WHERE email = 'vu.thi.sv@student.edu.vn'), (SELECT book_id FROM books WHERE isbn = '9786041026724'), SYSDATE - 1);

COMMIT;

-- ==========================================================
-- THỐNG KÊ DỮ LIỆU
-- ==========================================================
-- Tổng số bản ghi đã chèn:
-- Branches: 4 (+1 đã có = 5)
-- Users: 6 (+1 đã có = 7)
-- Staff: 7
-- Categories: 11
-- Authors: 15
-- Publishers: 10
-- Books: 15
-- Book Images: 17
-- Book Authors: 18
-- Customers: 10
-- Shipping Methods: 4
-- Carts: 8
-- Cart Items: 10
-- Orders: 7
-- Order Details: 16
-- Order Status History: 6
-- Branch Inventory: 17
-- Inventory Transfers: 3
-- Transfer Details: 6
-- Inventory Transactions: 8
-- Coupons: 4
-- Payment Transactions: 4
-- Reviews: 6
-- Wishlists: 6
-- ==========================================================
-- TỔNG CỘNG: ~250+ bản ghi
-- ==========================================================