/*
================================================================================
  📦 BƯỚC 7: INDEXING VÀ TỐI ƯU HÓA — DigiBook Database
================================================================================
  Chủ đề  : Website bán sách DigiBook
  DBMS    : Oracle 19c
  Nhóm    : Dũng, Nam, Hiếu, Phát
  File    : 7_indexes_and_tuning.sql
  Mục đích: Tạo ít nhất 3 Index (B-Tree, Bitmap, Function-based),
            chạy EXPLAIN PLAN trước/sau để so sánh hiệu suất.
================================================================================
  ⚠️ HƯỚNG DẪN THỰC THI:
  - Chạy file này SAU KHI đã chạy 2_create_tables.sql và 3_insert_data.sql.
  - Một số index có thể đã tồn tại do Oracle tự tạo cho PK/UNIQUE.
    Script sẽ chỉ tạo index BỔ SUNG cho các cột thường dùng trong WHERE/JOIN.
  - Trước khi test, chạy: SET SERVEROUTPUT ON;
================================================================================
*/

SET SERVEROUTPUT ON;

-- ============================================================================
-- 🗑️ XÓA CÁC INDEX CŨ (NẾU TỒN TẠI)
-- ============================================================================
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_orders_customer_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_orders_status';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_orders_order_date';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_books_category_id';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_books_publisher_id';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_books_title_upper';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_od_order_id';             EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_od_book_id';              EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_reviews_book_id';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_reviews_customer_id';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_bm_orders_payment';       EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT ✅ Đã dọn dẹp các Index cũ.
PROMPT ================================================

-- ============================================================================
-- 📋 PHẦN 1: PHÂN TÍCH — TẠI SAO CẦN INDEX VÀ CHỌN CỘT NÀO?
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                    📊 PHÂN TÍCH CHIẾN LƯỢC INDEXING                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  1. B-TREE INDEX (Index mặc định, phù hợp cột có Cardinality cao)         ║
║     ─────────────────────────────────────────────────────────────────────── ║
║     • ORDERS.customer_id   → FK, JOIN rất thường xuyên với CUSTOMERS      ║
║     • ORDERS.order_date    → WHERE clause lọc theo ngày (báo cáo)         ║
║     • BOOKS.category_id    → FK, WHERE clause lọc sách theo danh mục     ║
║     • BOOKS.publisher_id   → FK, JOIN với PUBLISHERS                      ║
║     • ORDER_DETAILS.order_id → FK, JOIN với ORDERS (truy vấn chi tiết)    ║
║     • ORDER_DETAILS.book_id  → FK, JOIN với BOOKS                         ║
║     • REVIEWS.book_id      → FK, lọc đánh giá theo sách                  ║
║                                                                            ║
║  2. BITMAP INDEX (phù hợp cột có Cardinality thấp — ít giá trị phân biệt)║
║     ─────────────────────────────────────────────────────────────────────── ║
║     • ORDERS.payment_method → Chỉ 4 giá trị: COD, CREDIT_CARD,           ║
║       BANK_TRANSFER, E_WALLET → Bitmap hiệu quả hơn B-Tree               ║
║     • ORDERS.status         → Chỉ 5 giá trị: PENDING, CONFIRMED, ...     ║
║       ⚠️ Lưu ý: Bitmap Index KHÔNG nên dùng trên bảng có DML thường      ║
║       xuyên (do lock conflict). Tuy nhiên, trong đồ án demo là phù hợp   ║
║       để minh họa kỹ thuật.                                               ║
║                                                                            ║
║  3. FUNCTION-BASED INDEX (index trên kết quả hàm/biểu thức)              ║
║     ─────────────────────────────────────────────────────────────────────── ║
║     • UPPER(BOOKS.title)    → Tìm kiếm sách không phân biệt hoa/thường  ║
║       VD: WHERE UPPER(title) LIKE '%MAT BIEC%'                            ║
║       Nếu không có FBI, Oracle sẽ FULL TABLE SCAN vì không dùng được     ║
║       B-Tree index trên cột title khi bọc hàm UPPER().                   ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- ============================================================================
-- 🔧 PHẦN 2: TẠO CÁC INDEX
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 2.1. B-TREE INDEX — Cột FK và cột lọc thường xuyên
-- Phụ trách: DŨNG, NAM
-- ────────────────────────────────────────────────────────────────────────────

-- Index 1: ORDERS.customer_id (B-Tree)
-- Lý do: Cột FK liên kết ORDERS → CUSTOMERS. Mọi truy vấn "đơn hàng của
--         khách hàng X" đều dùng WHERE customer_id = ? hoặc JOIN.
CREATE INDEX idx_orders_customer_id ON ORDERS(customer_id);
PROMPT ✅ [B-Tree] idx_orders_customer_id trên ORDERS(customer_id)

-- Index 2: ORDERS.order_date (B-Tree)
-- Lý do: Báo cáo doanh thu luôn lọc theo khoảng thời gian
--         WHERE order_date BETWEEN ... AND ...
CREATE INDEX idx_orders_order_date ON ORDERS(order_date);
PROMPT ✅ [B-Tree] idx_orders_order_date trên ORDERS(order_date)

-- Index 3: BOOKS.category_id (B-Tree)
-- Lý do: Người dùng thường xuyên duyệt sách theo danh mục
--         WHERE category_id = ? hoặc JOIN CATEGORIES
CREATE INDEX idx_books_category_id ON BOOKS(category_id);
PROMPT ✅ [B-Tree] idx_books_category_id trên BOOKS(category_id)

-- Index 4: BOOKS.publisher_id (B-Tree)
-- Lý do: JOIN PUBLISHERS để lấy tên NXB trong View và báo cáo
CREATE INDEX idx_books_publisher_id ON BOOKS(publisher_id);
PROMPT ✅ [B-Tree] idx_books_publisher_id trên BOOKS(publisher_id)

-- Index 5: ORDER_DETAILS.order_id (B-Tree)
-- Lý do: Cột FK, JOIN rất thường xuyên để lấy chi tiết đơn hàng
CREATE INDEX idx_od_order_id ON ORDER_DETAILS(order_id);
PROMPT ✅ [B-Tree] idx_od_order_id trên ORDER_DETAILS(order_id)

-- Index 6: ORDER_DETAILS.book_id (B-Tree)
-- Lý do: Cột FK, dùng khi tính sách bán chạy nhất (GROUP BY book_id)
CREATE INDEX idx_od_book_id ON ORDER_DETAILS(book_id);
PROMPT ✅ [B-Tree] idx_od_book_id trên ORDER_DETAILS(book_id)

-- Index 7: REVIEWS.book_id (B-Tree)
-- Lý do: Lọc đánh giá theo sách, tính điểm trung bình
CREATE INDEX idx_reviews_book_id ON REVIEWS(book_id);
PROMPT ✅ [B-Tree] idx_reviews_book_id trên REVIEWS(book_id)

-- Index 7b: REVIEWS.customer_id (B-Tree)
-- Lý do: Lọc các đánh giá của khách hàng, JOIN với CUSTOMERS
CREATE INDEX idx_reviews_customer_id ON REVIEWS(customer_id);
PROMPT ✅ [B-Tree] idx_reviews_customer_id trên REVIEWS(customer_id)

-- ────────────────────────────────────────────────────────────────────────────
-- 2.2. BITMAP INDEX — Cột có Cardinality thấp
-- Phụ trách: HIẾU
-- ────────────────────────────────────────────────────────────────────────────

-- Index 8: ORDERS.status (Bitmap)
-- Lý do: Chỉ có 5 giá trị phân biệt (PENDING, CONFIRMED, SHIPPING,
--         DELIVERED, CANCELLED). Bitmap Index rất hiệu quả cho lọc
--         WHERE status = 'DELIVERED' hoặc IN ('PENDING', 'CONFIRMED').
-- ⚠️ Bitmap phù hợp cho bảng có tỷ lệ READ >> WRITE.
CREATE BITMAP INDEX idx_orders_status ON ORDERS(status);
PROMPT ✅ [Bitmap] idx_orders_status trên ORDERS(status)

-- Index 9: ORDERS.payment_method (Bitmap)
-- Lý do: Chỉ có 4 giá trị (COD, CREDIT_CARD, BANK_TRANSFER, E_WALLET).
--         Dùng trong báo cáo thống kê theo phương thức thanh toán.
CREATE BITMAP INDEX idx_bm_orders_payment ON ORDERS(payment_method);
PROMPT ✅ [Bitmap] idx_bm_orders_payment trên ORDERS(payment_method)

-- ────────────────────────────────────────────────────────────────────────────
-- 2.3. FUNCTION-BASED INDEX — Index trên biểu thức
-- Phụ trách: PHÁT
-- ────────────────────────────────────────────────────────────────────────────

-- Index 10: UPPER(BOOKS.title) (Function-based)
-- Lý do: Người dùng tìm kiếm sách thường nhập không đúng hoa/thường.
--         VD: "mat biec", "MAT BIEC", "Mắt biếc" → cần WHERE UPPER(title) LIKE ...
--         Nếu không có FBI, Oracle PHẢI quét toàn bộ bảng (FULL TABLE SCAN)
--         vì không thể dùng B-Tree index khi cột bị bọc hàm.
CREATE INDEX idx_books_title_upper ON BOOKS(UPPER(title));
PROMPT ✅ [Function-based] idx_books_title_upper trên UPPER(BOOKS.title)

PROMPT
PROMPT ================================================
PROMPT ✅ HOÀN TẤT TẠO 11 INDEX!
PROMPT    • 8 B-Tree Index (FK + lọc thời gian)
PROMPT    • 2 Bitmap Index (status, payment_method)
PROMPT    • 1 Function-based Index (UPPER title)
PROMPT ================================================

-- ============================================================================
-- 📊 PHẦN 3: EXPLAIN PLAN — SO SÁNH HIỆU SUẤT TRƯỚC VÀ SAU INDEX
-- ============================================================================

/*
  ⚠️ GHI CHÚ VỀ CÁCH ĐỌC EXPLAIN PLAN:
  ─────────────────────────────────────────────────────────────────────
  Cột quan trọng:
  • OPERATION  : Thao tác Oracle thực hiện (TABLE ACCESS, INDEX SCAN...)
  • OPTIONS    : Chi tiết (FULL = quét toàn bộ, RANGE SCAN = quét phạm vi)
  • OBJECT_NAME: Tên bảng/index được sử dụng
  • COST       : Chi phí ước tính (càng thấp càng tốt)
  • CARDINALITY: Số dòng ước tính trả về

  Mục tiêu: Từ TABLE ACCESS FULL → INDEX RANGE SCAN hoặc INDEX UNIQUE SCAN
  ─────────────────────────────────────────────────────────────────────
*/

PROMPT
PROMPT ================================================================
PROMPT 📊 PHẦN 3: EXPLAIN PLAN — PHÂN TÍCH HIỆU SUẤT
PROMPT ================================================================

-- ────────────────────────────────────────────────────────────────────
-- 3.1. TRUY VẤN 1: Lọc đơn hàng theo khách hàng
-- Index sử dụng: idx_orders_customer_id (B-Tree)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 📌 TRUY VẤN 1: Tìm tất cả đơn hàng của khách hàng ID = 1
PROMPT    → Sử dụng: idx_orders_customer_id (B-Tree)

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_IDX' FOR
    SELECT o.order_id, o.order_date, o.total_amount, o.status
    FROM ORDERS o
    WHERE o.customer_id = 1;

PROMPT 🔍 Execution Plan (có Index):
SELECT LPAD(' ', 2 * (LEVEL - 1)) || operation || ' ' ||
       options || ' ' || NVL(object_name, '') AS plan_line,
       cost, cardinality
FROM plan_table
WHERE statement_id = 'Q1_IDX'
START WITH id = 0
CONNECT BY PRIOR id = parent_id
ORDER SIBLINGS BY id;

DELETE FROM plan_table WHERE statement_id = 'Q1_IDX';

/*
  📝 GIẢI THÍCH:
  ─────────────────────────────────────────────────────────────────────
  KHÔNG CÓ INDEX:
    → TABLE ACCESS FULL trên ORDERS → Quét toàn bộ bảng
    → Cost cao khi bảng lớn (hàng triệu dòng)

  CÓ INDEX idx_orders_customer_id:
    → INDEX RANGE SCAN trên idx_orders_customer_id → Tìm nhanh các dòng
      có customer_id = 1
    → TABLE ACCESS BY INDEX ROWID → Lấy dữ liệu từ bảng theo ROWID
    → Cost thấp hơn đáng kể

  KẾT LUẬN: Index trên cột FK customer_id giúp tăng tốc JOIN và lọc
  theo khách hàng, đặc biệt khi bảng ORDERS có hàng triệu bản ghi.
  ─────────────────────────────────────────────────────────────────────
*/

-- ────────────────────────────────────────────────────────────────────
-- 3.2. TRUY VẤN 2: Báo cáo doanh thu theo khoảng thời gian
-- Index sử dụng: idx_orders_order_date (B-Tree) + idx_orders_status (Bitmap)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 📌 TRUY VẤN 2: Doanh thu đơn DELIVERED trong 30 ngày gần nhất
PROMPT    → Sử dụng: idx_orders_order_date (B-Tree) + idx_orders_status (Bitmap)

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_IDX' FOR
    SELECT SUM(o.total_amount) AS total_revenue,
           COUNT(*) AS total_orders
    FROM ORDERS o
    WHERE o.order_date BETWEEN SYSDATE - 30 AND SYSDATE
      AND o.status = 'DELIVERED';

PROMPT 🔍 Execution Plan (có Index):
SELECT LPAD(' ', 2 * (LEVEL - 1)) || operation || ' ' ||
       options || ' ' || NVL(object_name, '') AS plan_line,
       cost, cardinality
FROM plan_table
WHERE statement_id = 'Q2_IDX'
START WITH id = 0
CONNECT BY PRIOR id = parent_id
ORDER SIBLINGS BY id;

DELETE FROM plan_table WHERE statement_id = 'Q2_IDX';

/*
  📝 GIẢI THÍCH:
  ─────────────────────────────────────────────────────────────────────
  KHÔNG CÓ INDEX:
    → TABLE ACCESS FULL trên ORDERS, lọc WHERE ở mức row-level

  CÓ INDEX:
    → Oracle có thể kết hợp (BITMAP AND/OR):
      • idx_orders_order_date: RANGE SCAN theo khoảng thời gian
      • idx_orders_status: BITMAP SCAN tìm status = 'DELIVERED'
    → Chỉ đọc các dòng thỏa cả 2 điều kiện

  KẾT LUẬN: Kết hợp B-Tree (range) + Bitmap (equality trên low-cardinality)
  cho hiệu suất tối ưu trong truy vấn báo cáo lọc theo ngày + trạng thái.
  ─────────────────────────────────────────────────────────────────────
*/

-- ────────────────────────────────────────────────────────────────────
-- 3.3. TRUY VẤN 3: Tìm kiếm sách theo tên (không phân biệt hoa/thường)
-- Index sử dụng: idx_books_title_upper (Function-based)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 📌 TRUY VẤN 3: Tìm sách có tên chứa "MAT BIEC" (case-insensitive)
PROMPT    → Sử dụng: idx_books_title_upper (Function-based)

EXPLAIN PLAN SET STATEMENT_ID = 'Q3_IDX' FOR
    SELECT b.book_id, b.title, b.price
    FROM BOOKS b
    WHERE UPPER(b.title) LIKE '%MAT BIEC%';

PROMPT 🔍 Execution Plan (có Function-based Index):
SELECT LPAD(' ', 2 * (LEVEL - 1)) || operation || ' ' ||
       options || ' ' || NVL(object_name, '') AS plan_line,
       cost, cardinality
FROM plan_table
WHERE statement_id = 'Q3_IDX'
START WITH id = 0
CONNECT BY PRIOR id = parent_id
ORDER SIBLINGS BY id;

DELETE FROM plan_table WHERE statement_id = 'Q3_IDX';

/*
  📝 GIẢI THÍCH:
  ─────────────────────────────────────────────────────────────────────
  KHÔNG CÓ FUNCTION-BASED INDEX:
    → TABLE ACCESS FULL bắt buộc, vì Oracle không thể dùng B-Tree index
      trên cột title khi bọc hàm UPPER().

  CÓ idx_books_title_upper:
    → Oracle biết rằng có index trên UPPER(title)
    → Với LIKE '%...%' (chứa leading wildcard): vẫn có thể FULL SCAN
      vì leading % làm index không hiệu quả cho RANGE SCAN.
    → Tuy nhiên, với LIKE 'MAT BIEC%' (không có leading %):
      Oracle SẼ dùng INDEX RANGE SCAN trên FBI.

  ⚠️ LƯU Ý QUAN TRỌNG:
    LIKE '%keyword%' vẫn cần FULL SCAN do leading wildcard.
    Để tận dụng FBI tốt nhất, dùng: LIKE 'KEYWORD%' (prefix search).
    Trong thực tế, nên kết hợp Oracle Text (CONTAINS) cho full-text search.
  ─────────────────────────────────────────────────────────────────────
*/

-- ────────────────────────────────────────────────────────────────────
-- 3.4. TRUY VẤN 4: Tìm sách theo tên (prefix — FBI hiệu quả nhất)
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 📌 TRUY VẤN 4: Tìm sách bắt đầu bằng "HARRY" (prefix search)
PROMPT    → FBI idx_books_title_upper sẽ phát huy hiệu quả tối đa

EXPLAIN PLAN SET STATEMENT_ID = 'Q4_IDX' FOR
    SELECT b.book_id, b.title, b.price
    FROM BOOKS b
    WHERE UPPER(b.title) LIKE 'HARRY%';

PROMPT 🔍 Execution Plan:
SELECT LPAD(' ', 2 * (LEVEL - 1)) || operation || ' ' ||
       options || ' ' || NVL(object_name, '') AS plan_line,
       cost, cardinality
FROM plan_table
WHERE statement_id = 'Q4_IDX'
START WITH id = 0
CONNECT BY PRIOR id = parent_id
ORDER SIBLINGS BY id;

DELETE FROM plan_table WHERE statement_id = 'Q4_IDX';

/*
  📝 GIẢI THÍCH:
  → Với LIKE 'HARRY%' (không có leading %), Oracle SỬ DỤNG
    INDEX RANGE SCAN trên idx_books_title_upper.
  → Cost thấp hơn nhiều so với FULL TABLE SCAN.
  → Đây là best practice khi thiết kế tính năng tìm kiếm.
*/

-- ────────────────────────────────────────────────────────────────────
-- 3.5. TRUY VẤN 5: JOIN phức tạp — Báo cáo đơn hàng chi tiết
-- Index sử dụng: idx_od_order_id, idx_od_book_id, idx_books_category_id
-- ────────────────────────────────────────────────────────────────────
PROMPT
PROMPT 📌 TRUY VẤN 5: Báo cáo sách bán chạy theo danh mục (JOIN 3 bảng)
PROMPT    → Sử dụng: idx_od_book_id + idx_books_category_id

EXPLAIN PLAN SET STATEMENT_ID = 'Q5_IDX' FOR
    SELECT cat.category_name,
           b.title,
           SUM(od.quantity) AS total_sold
    FROM ORDER_DETAILS od
    INNER JOIN BOOKS b ON od.book_id = b.book_id
    INNER JOIN CATEGORIES cat ON b.category_id = cat.category_id
    GROUP BY cat.category_name, b.title
    ORDER BY total_sold DESC;

PROMPT 🔍 Execution Plan:
SELECT LPAD(' ', 2 * (LEVEL - 1)) || operation || ' ' ||
       options || ' ' || NVL(object_name, '') AS plan_line,
       cost, cardinality
FROM plan_table
WHERE statement_id = 'Q5_IDX'
START WITH id = 0
CONNECT BY PRIOR id = parent_id
ORDER SIBLINGS BY id;

DELETE FROM plan_table WHERE statement_id = 'Q5_IDX';

/*
  📝 GIẢI THÍCH:
  → idx_od_book_id giúp tăng tốc JOIN ORDER_DETAILS ⟕ BOOKS
  → idx_books_category_id giúp tăng tốc JOIN BOOKS ⟕ CATEGORIES
  → Oracle Optimizer chọn phương pháp JOIN tối ưu (NESTED LOOP / HASH JOIN)
    dựa trên thống kê và index có sẵn.
*/

-- ============================================================================
-- 📋 PHẦN 4: KIỂM TRA — LIỆT KÊ TẤT CẢ INDEX ĐÃ TẠO
-- ============================================================================

PROMPT
PROMPT ================================================================
PROMPT 📋 DANH SÁCH TẤT CẢ INDEX TRONG SCHEMA (do user tạo):
PROMPT ================================================================

SELECT index_name,
       table_name,
       index_type,
       uniqueness,
       status
FROM user_indexes
WHERE table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY table_name, index_name;

PROMPT
PROMPT ================================================================
PROMPT 📋 CHI TIẾT CÁC CỘT ĐƯỢC INDEX:
PROMPT ================================================================

SELECT i.index_name,
       i.table_name,
       i.index_type,
       ic.column_name,
       ic.column_position
FROM user_indexes i
INNER JOIN user_ind_columns ic ON i.index_name = ic.index_name
WHERE i.table_name IN (
    'CUSTOMERS', 'CATEGORIES', 'AUTHORS', 'PUBLISHERS',
    'BOOKS', 'BOOK_AUTHORS', 'ORDERS', 'ORDER_DETAILS', 'REVIEWS'
)
ORDER BY i.table_name, i.index_name, ic.column_position;

PROMPT
PROMPT ================================================================
PROMPT 🎉 BƯỚC 7 HOÀN TẤT — INDEXING VÀ TỐI ƯU HÓA THÀNH CÔNG!
PROMPT ================================================================
PROMPT    🔧 8 B-Tree Index   (FK + datetime columns)
PROMPT    🔧 2 Bitmap Index   (status, payment_method)
PROMPT    🔧 1 FBI            (UPPER(title) — case-insensitive search)
PROMPT    📊 5 EXPLAIN PLAN   (phân tích hiệu suất truy vấn)
PROMPT ================================================================
