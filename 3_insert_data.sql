-- ==========================================================
-- FILE: 3_insert_data.sql
-- Mục tiêu: Nạp dữ liệu mẫu (>= 100 bản ghi) cho DigiBook
-- Hệ quản trị: Oracle 19c
-- Ghi chú: Dữ liệu được chia theo 4 phần công việc Dũng/Nam/Hiếu/Phát
-- ==========================================================

SET DEFINE OFF;

-- ==========================================================
-- PHẦN 1 - DŨNG: CUSTOMERS, CATEGORIES, CARTS, CART_ITEMS
-- ==========================================================

-- 1) CUSTOMERS (16 bản ghi)
INSERT INTO customers (customer_id, full_name, email, password_hash, phone, address, created_at, updated_at, status)
VALUES (1, 'Nguyễn Minh An', 'an.nguyen@digibook.vn', 'HASH_AN_001', '0901000001', '12 Nguyễn Trãi, Hà Nội', DATE '2026-01-05', DATE '2026-03-01', 'ACTIVE');
INSERT INTO customers VALUES (2, 'Trần Quốc Bảo', 'bao.tran@digibook.vn', 'HASH_BAO_002', '0901000002', '24 Lê Lợi, Đà Nẵng', DATE '2026-01-06', DATE '2026-03-02', 'ACTIVE');
INSERT INTO customers VALUES (3, 'Lê Thúy Chi', 'chi.le@digibook.vn', 'HASH_CHI_003', '0901000003', '31 Võ Thị Sáu, HCM', DATE '2026-01-08', DATE '2026-03-02', 'ACTIVE');
INSERT INTO customers VALUES (4, 'Phạm Hoàng Duy', 'duy.pham@digibook.vn', 'HASH_DUY_004', '0901000004', '17 Hai Bà Trưng, Huế', DATE '2026-01-10', DATE '2026-03-03', 'ACTIVE');
INSERT INTO customers VALUES (5, 'Đoàn Gia Huy', 'huy.doan@digibook.vn', 'HASH_HUY_005', '0901000005', '44 Trần Hưng Đạo, Hải Phòng', DATE '2026-01-11', DATE '2026-03-03', 'ACTIVE');
INSERT INTO customers VALUES (6, 'Vũ Ngọc Khang', 'khang.vu@digibook.vn', 'HASH_KHANG_006', '0901000006', '88 CMT8, Cần Thơ', DATE '2026-01-12', DATE '2026-03-04', 'ACTIVE');
INSERT INTO customers VALUES (7, 'Hoàng Lan Anh', 'lananh.hoang@digibook.vn', 'HASH_LANANH_007', '0901000007', '9 Lý Thường Kiệt, Nha Trang', DATE '2026-01-14', DATE '2026-03-05', 'ACTIVE');
INSERT INTO customers VALUES (8, 'Bùi Tuấn Kiệt', 'kiet.bui@digibook.vn', 'HASH_KIET_008', '0901000008', '56 Nguyễn Văn Cừ, Vinh', DATE '2026-01-15', DATE '2026-03-05', 'ACTIVE');
INSERT INTO customers VALUES (9, 'Mai Bảo Ngọc', 'ngoc.mai@digibook.vn', 'HASH_NGOC_009', '0901000009', '72 Trường Chinh, Quy Nhơn', DATE '2026-01-17', DATE '2026-03-06', 'ACTIVE');
INSERT INTO customers VALUES (10, 'Đặng Quang Nhật', 'nhat.dang@digibook.vn', 'HASH_NHAT_010', '0901000010', '15 Bà Triệu, Hà Nội', DATE '2026-01-19', DATE '2026-03-06', 'ACTIVE');
INSERT INTO customers VALUES (11, 'Trương Gia Phúc', 'phuc.truong@digibook.vn', 'HASH_PHUC_011', '0901000011', '38 Lê Duẩn, Đà Nẵng', DATE '2026-01-20', DATE '2026-03-07', 'ACTIVE');
INSERT INTO customers VALUES (12, 'Ngô Minh Quân', 'quan.ngo@digibook.vn', 'HASH_QUAN_012', '0901000012', '66 Điện Biên Phủ, HCM', DATE '2026-01-21', DATE '2026-03-07', 'ACTIVE');
INSERT INTO customers VALUES (13, 'Phan Thư Trang', 'trang.phan@digibook.vn', 'HASH_TRANG_013', '0901000013', '90 Quang Trưng, Đà Lạt', DATE '2026-01-22', DATE '2026-03-08', 'ACTIVE');
INSERT INTO customers VALUES (14, 'Lâm Đức Trí', 'tri.lam@digibook.vn', 'HASH_TRI_014', '0901000014', '101 Hùng Vương, Huế', DATE '2026-01-24', DATE '2026-03-08', 'INACTIVE');
INSERT INTO customers VALUES (15, 'Cao Nhật Vy', 'vy.cao@digibook.vn', 'HASH_VY_015', '0901000015', '5 Trần Phú, Hội An', DATE '2026-01-25', DATE '2026-03-09', 'ACTIVE');
INSERT INTO customers VALUES (16, 'Lý Thanh Sơn', 'son.ly@digibook.vn', 'HASH_SON_016', '0901000016', '22 Nguyễn Huệ, Biên Hòa', DATE '2026-01-26', DATE '2026-03-10', 'BANNED');

-- 2) CATEGORIES (10 bản ghi)
INSERT INTO categories (category_id, category_name, description, parent_id) VALUES (1, 'Sách', 'Danh mục gốc', NULL);
INSERT INTO categories VALUES (2, 'Văn học', 'Tiểu thuyết, truyện ngắn', 1);
INSERT INTO categories VALUES (3, 'Kinh tế', 'Quản trị, đầu tư, marketing', 1);
INSERT INTO categories VALUES (4, 'Công nghệ', 'Lập trình, dữ liệu, AI', 1);
INSERT INTO categories VALUES (5, 'Tâm lý - Kỹ năng', 'Phát triển bản thân', 1);
INSERT INTO categories VALUES (6, 'Thiếu nhi', 'Sách cho tre em', 1);
INSERT INTO categories VALUES (7, 'Tiểu thuyết Việt', 'Văn học Việt Nam', 2);
INSERT INTO categories VALUES (8, 'Tiểu thuyết Nước ngoài', 'Văn học dich', 2);
INSERT INTO categories VALUES (9, 'Data Science', 'Phân tích dữ liệu', 4);
INSERT INTO categories VALUES (10, 'Oracle Database', 'Quản trị CSDL Oracle', 4);

-- 3) CARTS (16 bản ghi)
INSERT INTO carts (cart_id, customer_id, created_at, updated_at, status) VALUES (1, 1, DATE '2026-03-01', DATE '2026-03-02', 'ACTIVE');
INSERT INTO carts VALUES (2, 2, DATE '2026-03-01', DATE '2026-03-02', 'ACTIVE');
INSERT INTO carts VALUES (3, 3, DATE '2026-03-01', DATE '2026-03-02', 'ACTIVE');
INSERT INTO carts VALUES (4, 4, DATE '2026-03-01', DATE '2026-03-03', 'ABANDONED');
INSERT INTO carts VALUES (5, 5, DATE '2026-03-02', DATE '2026-03-03', 'ACTIVE');
INSERT INTO carts VALUES (6, 6, DATE '2026-03-02', DATE '2026-03-03', 'ACTIVE');
INSERT INTO carts VALUES (7, 7, DATE '2026-03-02', DATE '2026-03-04', 'MERGED');
INSERT INTO carts VALUES (8, 8, DATE '2026-03-02', DATE '2026-03-04', 'ACTIVE');
INSERT INTO carts VALUES (9, 9, DATE '2026-03-03', DATE '2026-03-04', 'ACTIVE');
INSERT INTO carts VALUES (10, 10, DATE '2026-03-03', DATE '2026-03-05', 'ACTIVE');
INSERT INTO carts VALUES (11, 11, DATE '2026-03-03', DATE '2026-03-05', 'ACTIVE');
INSERT INTO carts VALUES (12, 12, DATE '2026-03-04', DATE '2026-03-05', 'ACTIVE');
INSERT INTO carts VALUES (13, 13, DATE '2026-03-04', DATE '2026-03-06', 'ACTIVE');
INSERT INTO carts VALUES (14, 14, DATE '2026-03-04', DATE '2026-03-06', 'ABANDONED');
INSERT INTO carts VALUES (15, 15, DATE '2026-03-05', DATE '2026-03-06', 'ACTIVE');
INSERT INTO carts VALUES (16, 16, DATE '2026-03-05', DATE '2026-03-07', 'ABANDONED');

-- ==========================================================
-- PHẦN 2 - NAM: AUTHORS, PUBLISHERS, COUPONS
-- ==========================================================

-- 4) AUTHORS (12 bản ghi)
INSERT INTO authors (author_id, author_name, biography, birth_date, nationality) VALUES (1, 'Nguyễn Nhật Ánh', 'Tác giả văn học Việt Nam', DATE '1955-05-07', 'Việt Nam');
INSERT INTO authors VALUES (2, 'Tony Buổi Sáng', 'Tác giả sách kỹ năng', DATE '1978-11-10', 'Việt Nam');
INSERT INTO authors VALUES (3, 'Lê Minh Tuấn', 'Tác giả công nghệ', DATE '1985-03-15', 'Việt Nam');
INSERT INTO authors VALUES (4, 'Robert Martin', 'Tác giả về clean code', DATE '1952-12-05', 'USA');
INSERT INTO authors VALUES (5, 'Andrew Hunt', 'Tác giả practical programming', DATE '1964-09-12', 'USA');
INSERT INTO authors VALUES (6, 'Thomas Cormen', 'Tác giả giải thuật', DATE '1956-01-01', 'USA');
INSERT INTO authors VALUES (7, 'Cal Newport', 'Tác giả kỹ năng học tập', DATE '1982-06-23', 'USA');
INSERT INTO authors VALUES (8, 'Morgan Housel', 'Tác giả về tài chính', DATE '1984-08-01', 'USA');
INSERT INTO authors VALUES (9, 'Daniel Kahneman', 'Nobel kinh tế', DATE '1934-03-05', 'Israel');
INSERT INTO authors VALUES (10, 'Phan Văn Trường', 'Tác giả kinh doanh', DATE '1946-05-04', 'Việt Nam');
INSERT INTO authors VALUES (11, 'Nguyễn Thị Thu Hà', 'Dịch giả sách công nghệ', DATE '1990-09-09', 'Việt Nam');
INSERT INTO authors VALUES (12, 'Trần Đức Hải', 'Biên tập viên', DATE '1988-02-20', 'Việt Nam');

-- 5) PUBLISHERS (8 bản ghi)
INSERT INTO publishers (publisher_id, publisher_name, address, phone, email) VALUES (1, 'NXB Trẻ', '161B Lý Chính Thắng, HCM', '02839316289', 'contact@nxbtre.vn');
INSERT INTO publishers VALUES (2, 'NXB Kim Đồng', '55 Quang Trưng, Hà Nội', '02439434730', 'info@kimdong.vn');
INSERT INTO publishers VALUES (3, 'NXB Lao Động', '175 Giảng Võ, Hà Nội', '02438459670', 'office@nxbld.vn');
INSERT INTO publishers VALUES (4, 'Alpha Books', '176 Thái Hà, Hà Nội', '02435378899', 'support@alphabooks.vn');
INSERT INTO publishers VALUES (5, 'Thái Hà Books', '119C5 Tô Hiệu, Hà Nội', '02437545678', 'hello@thaihabooks.vn');
INSERT INTO publishers VALUES (6, 'OReilly Media VN', 'District 1, HCM', '02838226688', 'vn@oreillymedia.com');
INSERT INTO publishers VALUES (7, 'Wiley VN', 'District 3, HCM', '02839398811', 'vn@wiley.com');
INSERT INTO publishers VALUES (8, 'Pearson VN', 'Cầu Giấy, Hà Nội', '02437890011', 'vn@pearson.com');

-- 6) COUPONS (8 bản ghi)
INSERT INTO coupons (coupon_id, coupon_code, coupon_name, discount_type, discount_value, start_at, end_at, max_uses, used_count, per_customer_limit, min_order_amount, max_discount_amount, is_active)
VALUES (1, 'WELCOME10', 'Giảm 10 phần trăm cho khách mới', 'PERCENT', 10, DATE '2026-01-01', DATE '2026-12-31', 1000, 20, 1, 100000, 50000, 1);
INSERT INTO coupons VALUES (2, 'FREESHIP25', 'Giảm 25000 trên đơn từ 200k', 'FIXED', 25000, DATE '2026-01-01', DATE '2026-12-31', 500, 35, 2, 200000, NULL, 1);
INSERT INTO coupons VALUES (3, 'TECH15', 'Giảm 15 phần trăm sách công nghệ', 'PERCENT', 15, DATE '2026-02-01', DATE '2026-09-30', 300, 12, 1, 300000, 80000, 1);
INSERT INTO coupons VALUES (4, 'SPRING50K', 'Ưu đãi mùa xuân', 'FIXED', 50000, DATE '2026-03-01', DATE '2026-05-31', 200, 18, 1, 400000, NULL, 1);
INSERT INTO coupons VALUES (5, 'BIGSALE20', 'Giảm 20 phần trăm tối đa 120k', 'PERCENT', 20, DATE '2026-03-01', DATE '2026-04-30', 150, 22, 1, 500000, 120000, 1);
INSERT INTO coupons VALUES (6, 'LOYAL30K', 'Khách hàng thân thiết', 'FIXED', 30000, DATE '2026-01-15', DATE '2026-12-31', NULL, 40, 3, 250000, NULL, 1);
INSERT INTO coupons VALUES (7, 'OLDUSER5', 'Ưu đãi tái kích hoạt', 'PERCENT', 5, DATE '2026-01-01', DATE '2026-06-30', 400, 10, 1, 100000, 30000, 0);
INSERT INTO coupons VALUES (8, 'FLASH70K', 'Flash sale theo giờ', 'FIXED', 70000, DATE '2026-03-10', DATE '2026-03-31', 80, 15, 1, 600000, NULL, 1);

-- ==========================================================
-- PHẦN 3 - HIẾU: BOOKS, BOOK_IMAGES, BOOK_AUTHORS, INVENTORY_TRANSACTIONS
-- ==========================================================

-- 7) BOOKS (20 bản ghi)
INSERT INTO books (book_id, title, isbn, price, stock_quantity, description, publication_year, page_count, category_id, publisher_id, created_at, updated_at)
VALUES (1, 'Mắt Biếc', '9786042000011', 98000, 120, 'Tiểu thuyết Việt Nam noi tieng', 2019, 320, 7, 1, DATE '2026-01-10', DATE '2026-03-01');
INSERT INTO books VALUES (2, 'Cho Tôi Xin Một Vé Đi Tuổi Thơ', '9786042000012', 88000, 90, 'Tác phẩm dành cho mọi lứa tuổi', 2018, 280, 7, 1, DATE '2026-01-10', DATE '2026-03-01');
INSERT INTO books VALUES (3, 'Nhà Giả Kim', '9786042000013', 120000, 70, 'Tiểu thuyết truyền cảm hứng', 2017, 240, 8, 4, DATE '2026-01-11', DATE '2026-03-01');
INSERT INTO books VALUES (4, 'Đắc Nhân Tâm', '9786042000014', 110000, 80, 'Sách ky nang giao tiep', 2015, 300, 5, 3, DATE '2026-01-11', DATE '2026-03-01');
INSERT INTO books VALUES (5, 'Clean Code', '9786042000015', 350000, 60, 'Nguyên tắc viết code sạch', 2020, 464, 4, 6, DATE '2026-01-12', DATE '2026-03-02');
INSERT INTO books VALUES (6, 'The Pragmatic Programmer', '9786042000016', 420000, 55, 'Kinh nghiệm lập trình thực chiến', 2019, 352, 4, 7, DATE '2026-01-12', DATE '2026-03-02');
INSERT INTO books VALUES (7, 'Introduction to Algorithms', '9786042000017', 650000, 40, 'Sách giai thuat kinh dien', 2021, 1312, 4, 8, DATE '2026-01-13', DATE '2026-03-02');
INSERT INTO books VALUES (8, 'Deep Work', '9786042000018', 210000, 85, 'Tập trung sâu trong công việc', 2016, 304, 5, 4, DATE '2026-01-13', DATE '2026-03-02');
INSERT INTO books VALUES (9, 'Tâm Lý Học Tiền Bạc', '9786042000019', 190000, 100, 'Tâm lý tài chính cá nhân', 2022, 280, 3, 4, DATE '2026-01-14', DATE '2026-03-03');
INSERT INTO books VALUES (10, 'Think Fast and Slow', '9786042000020', 280000, 65, 'Tư duy nhanh và chậm', 2018, 512, 3, 7, DATE '2026-01-14', DATE '2026-03-03');
INSERT INTO books VALUES (11, 'Oracle Database 19c Handbook', '9786042000021', 520000, 30, 'Tài liệu Oracle 19c', 2023, 700, 10, 8, DATE '2026-01-15', DATE '2026-03-03');
INSERT INTO books VALUES (12, 'SQL Performance Explained', '9786042000022', 360000, 45, 'Tối ưu truy vấn SQL', 2020, 360, 10, 7, DATE '2026-01-15', DATE '2026-03-03');
INSERT INTO books VALUES (13, 'Python for Data Analysis', '9786042000023', 410000, 50, 'Phân tích dữ liệu bang Python', 2021, 480, 9, 7, DATE '2026-01-16', DATE '2026-03-04');
INSERT INTO books VALUES (14, 'Hands On Machine Learning', '9786042000024', 560000, 35, 'Machine learning thực hành', 2022, 720, 9, 8, DATE '2026-01-16', DATE '2026-03-04');
INSERT INTO books VALUES (15, 'Trẻ Em Học Lập Trình', '9786042000025', 150000, 95, 'Nhập môn lập trình cho trẻ em', 2021, 220, 6, 2, DATE '2026-01-17', DATE '2026-03-04');
INSERT INTO books VALUES (16, '100 Câu Đố Tư Duy', '9786042000026', 99000, 140, 'Sách tri tue cho thieu nhi', 2020, 180, 6, 2, DATE '2026-01-17', DATE '2026-03-04');
INSERT INTO books VALUES (17, 'Khởi Nghiệp Tinh Gọn', '9786042000027', 170000, 75, 'Khởi nghiệp và mô hình tinh gọn', 2019, 260, 3, 5, DATE '2026-01-18', DATE '2026-03-05');
INSERT INTO books VALUES (18, 'Quản Trị Tài Chính Cá Nhân', '9786042000028', 200000, 88, 'Quản lý tài chính cho gia đình', 2023, 320, 3, 5, DATE '2026-01-18', DATE '2026-03-05');
INSERT INTO books VALUES (19, 'Docker và Kubernetes Cơ Bản', '9786042000029', 330000, 58, 'Nền tảng devops hiện đại', 2022, 410, 4, 6, DATE '2026-01-19', DATE '2026-03-05');
INSERT INTO books VALUES (20, 'Microservices Pattern', '9786042000030', 470000, 42, 'Kiến trúc hệ thống phân tán', 2021, 500, 4, 7, DATE '2026-01-19', DATE '2026-03-05');

-- 8) BOOK_IMAGES (28 bản ghi)
INSERT INTO book_images (image_id, book_id, image_url, is_primary, sort_order, created_at) VALUES (1, 1, 'https://img.digibook.vn/books/1/main.jpg', 1, 1, DATE '2026-01-10');
INSERT INTO book_images VALUES (2, 2, 'https://img.digibook.vn/books/2/main.jpg', 1, 1, DATE '2026-01-10');
INSERT INTO book_images VALUES (3, 3, 'https://img.digibook.vn/books/3/main.jpg', 1, 1, DATE '2026-01-11');
INSERT INTO book_images VALUES (4, 4, 'https://img.digibook.vn/books/4/main.jpg', 1, 1, DATE '2026-01-11');
INSERT INTO book_images VALUES (5, 5, 'https://img.digibook.vn/books/5/main.jpg', 1, 1, DATE '2026-01-12');
INSERT INTO book_images VALUES (6, 6, 'https://img.digibook.vn/books/6/main.jpg', 1, 1, DATE '2026-01-12');
INSERT INTO book_images VALUES (7, 7, 'https://img.digibook.vn/books/7/main.jpg', 1, 1, DATE '2026-01-13');
INSERT INTO book_images VALUES (8, 8, 'https://img.digibook.vn/books/8/main.jpg', 1, 1, DATE '2026-01-13');
INSERT INTO book_images VALUES (9, 9, 'https://img.digibook.vn/books/9/main.jpg', 1, 1, DATE '2026-01-14');
INSERT INTO book_images VALUES (10, 10, 'https://img.digibook.vn/books/10/main.jpg', 1, 1, DATE '2026-01-14');
INSERT INTO book_images VALUES (11, 11, 'https://img.digibook.vn/books/11/main.jpg', 1, 1, DATE '2026-01-15');
INSERT INTO book_images VALUES (12, 12, 'https://img.digibook.vn/books/12/main.jpg', 1, 1, DATE '2026-01-15');
INSERT INTO book_images VALUES (13, 13, 'https://img.digibook.vn/books/13/main.jpg', 1, 1, DATE '2026-01-16');
INSERT INTO book_images VALUES (14, 14, 'https://img.digibook.vn/books/14/main.jpg', 1, 1, DATE '2026-01-16');
INSERT INTO book_images VALUES (15, 15, 'https://img.digibook.vn/books/15/main.jpg', 1, 1, DATE '2026-01-17');
INSERT INTO book_images VALUES (16, 16, 'https://img.digibook.vn/books/16/main.jpg', 1, 1, DATE '2026-01-17');
INSERT INTO book_images VALUES (17, 17, 'https://img.digibook.vn/books/17/main.jpg', 1, 1, DATE '2026-01-18');
INSERT INTO book_images VALUES (18, 18, 'https://img.digibook.vn/books/18/main.jpg', 1, 1, DATE '2026-01-18');
INSERT INTO book_images VALUES (19, 19, 'https://img.digibook.vn/books/19/main.jpg', 1, 1, DATE '2026-01-19');
INSERT INTO book_images VALUES (20, 20, 'https://img.digibook.vn/books/20/main.jpg', 1, 1, DATE '2026-01-19');
INSERT INTO book_images VALUES (21, 5, 'https://img.digibook.vn/books/5/alt1.jpg', 0, 2, DATE '2026-01-12');
INSERT INTO book_images VALUES (22, 5, 'https://img.digibook.vn/books/5/alt2.jpg', 0, 3, DATE '2026-01-12');
INSERT INTO book_images VALUES (23, 7, 'https://img.digibook.vn/books/7/alt1.jpg', 0, 2, DATE '2026-01-13');
INSERT INTO book_images VALUES (24, 11, 'https://img.digibook.vn/books/11/alt1.jpg', 0, 2, DATE '2026-01-15');
INSERT INTO book_images VALUES (25, 13, 'https://img.digibook.vn/books/13/alt1.jpg', 0, 2, DATE '2026-01-16');
INSERT INTO book_images VALUES (26, 14, 'https://img.digibook.vn/books/14/alt1.jpg', 0, 2, DATE '2026-01-16');
INSERT INTO book_images VALUES (27, 19, 'https://img.digibook.vn/books/19/alt1.jpg', 0, 2, DATE '2026-01-19');
INSERT INTO book_images VALUES (28, 20, 'https://img.digibook.vn/books/20/alt1.jpg', 0, 2, DATE '2026-01-19');

-- 9) BOOK_AUTHORS (26 bản ghi)
INSERT INTO book_authors (book_id, author_id, role, author_order) VALUES (1, 1, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (2, 1, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (3, 11, 'TRANSLATOR', 1);
INSERT INTO book_authors VALUES (3, 12, 'EDITOR', 2);
INSERT INTO book_authors VALUES (4, 2, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (5, 4, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (5, 11, 'TRANSLATOR', 2);
INSERT INTO book_authors VALUES (6, 5, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (6, 11, 'TRANSLATOR', 2);
INSERT INTO book_authors VALUES (7, 6, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (8, 7, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (9, 8, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (10, 9, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (11, 3, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (11, 12, 'EDITOR', 2);
INSERT INTO book_authors VALUES (12, 3, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (13, 3, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (13, 11, 'TRANSLATOR', 2);
INSERT INTO book_authors VALUES (14, 3, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (14, 12, 'EDITOR', 2);
INSERT INTO book_authors VALUES (15, 10, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (16, 10, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (17, 10, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (18, 10, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (19, 4, 'AUTHOR', 1);
INSERT INTO book_authors VALUES (20, 5, 'AUTHOR', 1);

-- 10) INVENTORY_TRANSACTIONS (20 bản ghi)
INSERT INTO inventory_transactions (txn_id, book_id, txn_type, reference_id, reference_type, quantity, created_at, note)
VALUES (1, 1, 'IN', NULL, 'MANUAL', 120, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (2, 2, 'IN', NULL, 'MANUAL', 90, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (3, 3, 'IN', NULL, 'MANUAL', 70, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (4, 4, 'IN', NULL, 'MANUAL', 80, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (5, 5, 'IN', NULL, 'MANUAL', 60, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (6, 6, 'IN', NULL, 'MANUAL', 55, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (7, 7, 'IN', NULL, 'MANUAL', 40, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (8, 8, 'IN', NULL, 'MANUAL', 85, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (9, 9, 'IN', NULL, 'MANUAL', 100, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (10, 10, 'IN', NULL, 'MANUAL', 65, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (11, 11, 'IN', NULL, 'MANUAL', 30, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (12, 12, 'IN', NULL, 'MANUAL', 45, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (13, 13, 'IN', NULL, 'MANUAL', 50, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (14, 14, 'IN', NULL, 'MANUAL', 35, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (15, 15, 'IN', NULL, 'MANUAL', 95, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (16, 16, 'IN', NULL, 'MANUAL', 140, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (17, 17, 'IN', NULL, 'MANUAL', 75, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (18, 18, 'IN', NULL, 'MANUAL', 88, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (19, 19, 'IN', NULL, 'MANUAL', 58, DATE '2026-01-20', 'Nhập kho đầu kỳ');
INSERT INTO inventory_transactions VALUES (20, 20, 'IN', NULL, 'MANUAL', 42, DATE '2026-01-20', 'Nhập kho đầu kỳ');

-- 11) CART_ITEMS (24 bản ghi)
INSERT INTO cart_items (cart_item_id, cart_id, book_id, quantity, unit_price, created_at, updated_at)
VALUES (1, 1, 5, 1, 350000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (2, 1, 8, 1, 210000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (3, 2, 1, 2, 98000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (4, 2, 4, 1, 110000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (5, 3, 7, 1, 650000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (6, 3, 10, 1, 280000, DATE '2026-03-02', DATE '2026-03-02');
INSERT INTO cart_items VALUES (7, 4, 2, 1, 88000, DATE '2026-03-03', DATE '2026-03-03');
INSERT INTO cart_items VALUES (8, 5, 9, 1, 190000, DATE '2026-03-03', DATE '2026-03-03');
INSERT INTO cart_items VALUES (9, 5, 13, 1, 410000, DATE '2026-03-03', DATE '2026-03-03');
INSERT INTO cart_items VALUES (10, 6, 11, 1, 520000, DATE '2026-03-03', DATE '2026-03-03');
INSERT INTO cart_items VALUES (11, 6, 12, 1, 360000, DATE '2026-03-03', DATE '2026-03-03');
INSERT INTO cart_items VALUES (12, 7, 15, 2, 150000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (13, 7, 16, 1, 99000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (14, 8, 18, 1, 200000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (15, 8, 20, 1, 470000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (16, 9, 17, 1, 170000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (17, 9, 19, 1, 330000, DATE '2026-03-04', DATE '2026-03-04');
INSERT INTO cart_items VALUES (18, 10, 3, 1, 120000, DATE '2026-03-05', DATE '2026-03-05');
INSERT INTO cart_items VALUES (19, 10, 6, 1, 420000, DATE '2026-03-05', DATE '2026-03-05');
INSERT INTO cart_items VALUES (20, 11, 14, 1, 560000, DATE '2026-03-05', DATE '2026-03-05');
INSERT INTO cart_items VALUES (21, 12, 5, 1, 350000, DATE '2026-03-05', DATE '2026-03-05');
INSERT INTO cart_items VALUES (22, 13, 11, 1, 520000, DATE '2026-03-06', DATE '2026-03-06');
INSERT INTO cart_items VALUES (23, 14, 2, 1, 88000, DATE '2026-03-06', DATE '2026-03-06');
INSERT INTO cart_items VALUES (24, 15, 8, 1, 210000, DATE '2026-03-06', DATE '2026-03-06');

-- ==========================================================
-- PHẦN 4 - PHÁT: ORDERS, ORDER_DETAILS, ORDER_STATUS_HISTORY, REVIEWS
-- ==========================================================

-- 12) ORDERS (15 bản ghi)
INSERT INTO orders (order_id, customer_id, coupon_id, order_date, total_amount, status, shipping_address, payment_method, payment_status, shipping_fee, discount_amount, updated_at)
VALUES (1, 1, 1, DATE '2026-03-01', 658000, 'DELIVERED', '12 Nguyễn Trãi, Hà Nội', 'COD', 'PAID', 30000, 70000, DATE '2026-03-05');
INSERT INTO orders VALUES (2, 2, 2, DATE '2026-03-01', 271000, 'DELIVERED', '24 Lê Lợi, Đà Nẵng', 'E_WALLET', 'PAID', 25000, 25000, DATE '2026-03-05');
INSERT INTO orders VALUES (3, 3, NULL, DATE '2026-03-02', 940000, 'SHIPPING', '31 Võ Thị Sáu, HCM', 'BANK_TRANSFER', 'PAID', 30000, 0, DATE '2026-03-06');
INSERT INTO orders VALUES (4, 4, 3, DATE '2026-03-02', 646000, 'CONFIRMED', '17 Hai Bà Trưng, Huế', 'COD', 'PENDING', 30000, 114000, DATE '2026-03-06');
INSERT INTO orders VALUES (5, 5, NULL, DATE '2026-03-03', 409000, 'CANCELLED', '44 Trần Hưng Đạo, Hải Phòng', 'E_WALLET', 'FAILED', 30000, 0, DATE '2026-03-06');
INSERT INTO orders VALUES (6, 6, 4, DATE '2026-03-03', 830000, 'DELIVERED', '88 CMT8, Cần Thơ', 'BANK_TRANSFER', 'PAID', 30000, 50000, DATE '2026-03-07');
INSERT INTO orders VALUES (7, 7, NULL, DATE '2026-03-03', 279000, 'PENDING', '9 Lý Thường Kiệt, Nha Trang', 'COD', 'PENDING', 30000, 0, DATE '2026-03-07');
INSERT INTO orders VALUES (8, 8, 1, DATE '2026-03-04', 603000, 'SHIPPING', '56 Nguyễn Văn Cừ, Vinh', 'E_WALLET', 'PAID', 30000, 67000, DATE '2026-03-08');
INSERT INTO orders VALUES (9, 9, NULL, DATE '2026-03-04', 560000, 'CONFIRMED', '72 Trường Chinh, Quy Nhơn', 'COD', 'PAID', 30000, 0, DATE '2026-03-08');
INSERT INTO orders VALUES (10, 10, 5, DATE '2026-03-05', 640000, 'DELIVERED', '15 Bà Triệu, Hà Nội', 'BANK_TRANSFER', 'PAID', 30000, 120000, DATE '2026-03-09');
INSERT INTO orders VALUES (11, 11, NULL, DATE '2026-03-05', 900000, 'PENDING', '38 Lê Duẩn, Đà Nẵng', 'COD', 'PENDING', 30000, 0, DATE '2026-03-09');
INSERT INTO orders VALUES (12, 12, 6, DATE '2026-03-06', 548000, 'CONFIRMED', '66 Điện Biên Phủ, HCM', 'E_WALLET', 'PENDING', 30000, 30000, DATE '2026-03-10');
INSERT INTO orders VALUES (13, 13, NULL, DATE '2026-03-06', 920000, 'DELIVERED', '90 Quang Trưng, Đà Lạt', 'BANK_TRANSFER', 'PAID', 30000, 0, DATE '2026-03-10');
INSERT INTO orders VALUES (14, 14, 7, DATE '2026-03-07', 915000, 'SHIPPING', '101 Hùng Vương, Huế', 'COD', 'PAID', 30000, 15000, DATE '2026-03-10');
INSERT INTO orders VALUES (15, 15, 8, DATE '2026-03-07', 548000, 'PENDING', '5 Trần Phú, Hội An', 'E_WALLET', 'PENDING', 30000, 70000, DATE '2026-03-10');

-- 13) ORDER_DETAILS (30 bản ghi)
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (1, 1, 1, 2, 98000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (2, 1, 3, 4, 120000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (3, 2, 2, 1, 88000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (4, 2, 5, 1, 350000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (5, 3, 4, 2, 110000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (6, 3, 6, 1, 420000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (7, 4, 7, 1, 650000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (8, 4, 8, 1, 210000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (9, 5, 9, 2, 190000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (10, 5, 10, 1, 280000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (11, 6, 11, 1, 520000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (12, 6, 12, 1, 360000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (13, 7, 13, 1, 410000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (14, 7, 14, 1, 560000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (15, 8, 15, 2, 150000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (16, 8, 16, 3, 99000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (17, 9, 17, 1, 170000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (18, 9, 18, 2, 200000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (19, 10, 19, 1, 330000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (20, 10, 20, 1, 470000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (21, 11, 1, 3, 98000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (22, 11, 11, 1, 520000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (23, 12, 2, 1, 88000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (24, 12, 12, 1, 360000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (25, 13, 3, 2, 120000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (26, 13, 13, 1, 410000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (27, 14, 4, 1, 110000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (28, 14, 14, 1, 560000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (29, 15, 5, 1, 350000);
INSERT INTO order_details (order_detail_id, order_id, book_id, quantity, unit_price) VALUES (30, 15, 15, 1, 150000);

-- 14) ORDER_STATUS_HISTORY (28 bản ghi)
INSERT INTO order_status_history (status_history_id, order_id, old_status, new_status, changed_at, changed_by, changed_source, note)
VALUES (1, 1, NULL, 'PENDING', DATE '2026-03-01', 1, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (2, 1, 'PENDING', 'CONFIRMED', DATE '2026-03-02', NULL, 'SYSTEM', 'Đơn đã được xác nhận');
INSERT INTO order_status_history VALUES (3, 1, 'CONFIRMED', 'SHIPPING', DATE '2026-03-03', NULL, 'SYSTEM', 'Bắt đầu giao hàng');
INSERT INTO order_status_history VALUES (4, 1, 'SHIPPING', 'DELIVERED', DATE '2026-03-05', 1, 'CUSTOMER', 'Khách xác nhận nhận hàng');
INSERT INTO order_status_history VALUES (5, 2, NULL, 'PENDING', DATE '2026-03-01', 2, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (6, 2, 'PENDING', 'CONFIRMED', DATE '2026-03-02', NULL, 'SYSTEM', 'Hệ thống xác nhận');
INSERT INTO order_status_history VALUES (7, 2, 'CONFIRMED', 'DELIVERED', DATE '2026-03-05', 2, 'CUSTOMER', 'Đã giao thành công');
INSERT INTO order_status_history VALUES (8, 3, NULL, 'PENDING', DATE '2026-03-02', 3, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (9, 3, 'PENDING', 'CONFIRMED', DATE '2026-03-03', NULL, 'SYSTEM', 'Đơn đã được xử lý');
INSERT INTO order_status_history VALUES (10, 3, 'CONFIRMED', 'SHIPPING', DATE '2026-03-06', NULL, 'SYSTEM', 'Đơn đang giao');
INSERT INTO order_status_history VALUES (11, 4, NULL, 'PENDING', DATE '2026-03-02', 4, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (12, 4, 'PENDING', 'CONFIRMED', DATE '2026-03-06', NULL, 'SYSTEM', 'Xác nhận thành công');
INSERT INTO order_status_history VALUES (13, 5, NULL, 'PENDING', DATE '2026-03-03', 5, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (14, 5, 'PENDING', 'CANCELLED', DATE '2026-03-06', 5, 'CUSTOMER', 'Khách hủy đơn');
INSERT INTO order_status_history VALUES (15, 6, NULL, 'PENDING', DATE '2026-03-03', 6, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (16, 6, 'PENDING', 'CONFIRMED', DATE '2026-03-04', NULL, 'SYSTEM', 'Xác nhận đơn');
INSERT INTO order_status_history VALUES (17, 6, 'CONFIRMED', 'SHIPPING', DATE '2026-03-05', NULL, 'SYSTEM', 'Đơn đang giao');
INSERT INTO order_status_history VALUES (18, 6, 'SHIPPING', 'DELIVERED', DATE '2026-03-07', 6, 'CUSTOMER', 'Nhận hàng thành công');
INSERT INTO order_status_history VALUES (19, 7, NULL, 'PENDING', DATE '2026-03-03', 7, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (20, 8, NULL, 'PENDING', DATE '2026-03-04', 8, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (21, 8, 'PENDING', 'CONFIRMED', DATE '2026-03-05', NULL, 'SYSTEM', 'Xác nhận đơn');
INSERT INTO order_status_history VALUES (22, 8, 'CONFIRMED', 'SHIPPING', DATE '2026-03-08', NULL, 'SYSTEM', 'Đang giao');
INSERT INTO order_status_history VALUES (23, 9, NULL, 'PENDING', DATE '2026-03-04', 9, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (24, 9, 'PENDING', 'CONFIRMED', DATE '2026-03-08', NULL, 'SYSTEM', 'Xác nhận đơn');
INSERT INTO order_status_history VALUES (25, 10, NULL, 'PENDING', DATE '2026-03-05', 10, 'CUSTOMER', 'Tạo đơn hàng');
INSERT INTO order_status_history VALUES (26, 10, 'PENDING', 'CONFIRMED', DATE '2026-03-06', NULL, 'SYSTEM', 'Xác nhận đơn');
INSERT INTO order_status_history VALUES (27, 10, 'CONFIRMED', 'DELIVERED', DATE '2026-03-09', 10, 'CUSTOMER', 'Đã nhận hàng');
INSERT INTO order_status_history VALUES (28, 13, 'SHIPPING', 'DELIVERED', DATE '2026-03-10', 13, 'CUSTOMER', 'Nhận đơn thành công');

-- 15) REVIEWS (12 bản ghi, bắt buộc khớp (order_id, book_id) trong ORDER_DETAILS)
INSERT INTO reviews (review_id, order_id, book_id, rating, review_comment, review_date)
VALUES (1, 1, 1, 5, 'Nội dung xúc động, sách đẹp.', DATE '2026-03-06');
INSERT INTO reviews VALUES (2, 1, 3, 5, 'Bản dịch dễ đọc, truyện hay.', DATE '2026-03-06');
INSERT INTO reviews VALUES (3, 2, 2, 4, 'Phù hợp đối tượng học sinh.', DATE '2026-03-06');
INSERT INTO reviews VALUES (4, 2, 5, 5, 'Sách ky thuat rat gia tri.', DATE '2026-03-06');
INSERT INTO reviews VALUES (5, 3, 4, 4, 'Nội dung thực tế, dễ áp dụng.', DATE '2026-03-07');
INSERT INTO reviews VALUES (6, 3, 6, 5, 'Rất hữu ích cho lập trình viên.', DATE '2026-03-07');
INSERT INTO reviews VALUES (7, 4, 7, 5, 'Tài liệu giải thuật chuẩn.', DATE '2026-03-08');
INSERT INTO reviews VALUES (8, 4, 8, 4, 'Sách hay, hinh thuc dep.', DATE '2026-03-08');
INSERT INTO reviews VALUES (9, 6, 11, 5, 'Chi tiết và dễ tra cứu.', DATE '2026-03-09');
INSERT INTO reviews VALUES (10, 6, 12, 4, 'Nâng cao kỹ năng tối ưu SQL.', DATE '2026-03-09');
INSERT INTO reviews VALUES (11, 10, 19, 5, 'Nội dung devops rõ ràng.', DATE '2026-03-10');
INSERT INTO reviews VALUES (12, 10, 20, 4, 'Có nhiều ví dụ thực tế.', DATE '2026-03-10');

-- ==========================================================
-- [NAM] ĐỒNG BỘ LẠI SEQUENCE SAU KHI INSERT ID THỦ CÔNG
-- ==========================================================
-- Mục đích:
-- 1) Tránh xung đột PK khi lần insert tiếp theo không truyền ID
-- 2) Đưa NEXTVAL của sequence về >= MAX(id)+1 của từng bảng
DECLARE
    -- Procedure hỗ trợ căn chỉnh sequence tới giá trị đích
    PROCEDURE sync_sequence(p_seq_name IN VARCHAR2, p_target IN NUMBER) IS
        v_current NUMBER;
        v_delta   NUMBER;
    BEGIN
        -- Lấy NEXTVAL hiện tại để biết sequence đang ở đâu
        EXECUTE IMMEDIATE 'SELECT ' || p_seq_name || '.NEXTVAL FROM dual' INTO v_current;

        -- Tính độ lệch giữa target và current
        v_delta := p_target - v_current;

        -- Nếu sequence nhỏ hơn target thì tăng tạm thời và nhảy lên đúng mốc
        IF v_delta > 0 THEN
            EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY ' || TO_CHAR(v_delta);
            EXECUTE IMMEDIATE 'SELECT ' || p_seq_name || '.NEXTVAL FROM dual' INTO v_current;
            EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || p_seq_name || ' INCREMENT BY 1';
        END IF;
    END;
BEGIN
    sync_sequence('seq_customers', 17);
    sync_sequence('seq_categories', 11);
    sync_sequence('seq_carts', 17);
    sync_sequence('seq_cart_items', 25);
    sync_sequence('seq_authors', 13);
    sync_sequence('seq_publishers', 9);
    sync_sequence('seq_coupons', 9);
    sync_sequence('seq_books', 21);
    sync_sequence('seq_book_images', 29);
    sync_sequence('seq_inventory_txn', 21);
    sync_sequence('seq_orders', 16);
    sync_sequence('seq_order_details', 31);
    sync_sequence('seq_order_status_his', 29);
    sync_sequence('seq_reviews', 13);
END;
/

COMMIT;

-- ==========================================================
-- KẾT THÚC FILE
-- Tổng số bản ghi mẫu được nạp: 273
-- ==========================================================
