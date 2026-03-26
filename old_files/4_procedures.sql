-- ==========================================================
-- FILE: 4_procedures.sql
-- Mục tiêu: Xây dựng Stored Procedures cho nghiệp vụ DigiBook
-- Hệ quản trị: Oracle 19c
-- ==========================================================

-- ==========================================================
-- SP 1 [Dung]
-- Quản lý BOOKS (ADD/UPDATE/DELETE) có kiểm tra nghiệp vụ và EXCEPTION.
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_manage_book (
    p_action            IN VARCHAR2,
    p_book_id           IN OUT NUMBER,
    p_title             IN NVARCHAR2,
    p_isbn              IN VARCHAR2,
    p_price             IN NUMBER,
    p_stock_quantity    IN NUMBER,
    p_description       IN NCLOB,
    p_publication_year  IN NUMBER,
    p_page_count        IN NUMBER,
    p_category_id       IN NUMBER,
    p_publisher_id      IN NUMBER
)
AS
    v_book_count       NUMBER;
    v_dep_count        NUMBER;
    v_action           VARCHAR2(10);
BEGIN
    -- Chuẩn hóa action để tránh sai khác hoa thường/hoa.
    v_action := UPPER(TRIM(p_action));

    IF v_action NOT IN ('ADD', 'UPDATE', 'DELETE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Action không hợp lệ. Chỉ hỗ trợ ADD/UPDATE/DELETE.');
    END IF;

    IF v_action = 'ADD' THEN
        -- Kiểm tra thông tin bắt buộc trước khi thêm mới.
        IF p_title IS NULL OR p_price IS NULL OR p_price <= 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Dữ liệu thêm mới không hợp lệ (title/price).');
        END IF;

        IF p_stock_quantity IS NOT NULL AND p_stock_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Stock quantity không được âm.');
        END IF;

        -- Kiểm tra khóa ngoại category.
        SELECT COUNT(*)
          INTO v_book_count
          FROM categories
         WHERE category_id = p_category_id;

        IF v_book_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Category không tồn tại.');
        END IF;

        -- Kiểm tra khóa ngoại publisher.
        SELECT COUNT(*)
          INTO v_book_count
          FROM publishers
         WHERE publisher_id = p_publisher_id;

        IF v_book_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Publisher không tồn tại.');
        END IF;

        -- Kiểm tra ISBN trùng nếu có truyền vào.
        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_book_count
              FROM books
             WHERE isbn = p_isbn;

            IF v_book_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20006, 'ISBN đã tồn tại.');
            END IF;
        END IF;

        INSERT INTO books (
            book_id,
            title,
            isbn,
            price,
            stock_quantity,
            description,
            publication_year,
            page_count,
            category_id,
            publisher_id,
            created_at,
            updated_at
        ) VALUES (
            p_book_id,
            p_title,
            p_isbn,
            p_price,
            NVL(p_stock_quantity, 0),
            p_description,
            p_publication_year,
            p_page_count,
            p_category_id,
            p_publisher_id,
            SYSDATE,
            SYSDATE
        )
        RETURNING book_id INTO p_book_id;

    ELSIF v_action = 'UPDATE' THEN
        -- Kiểm tra tồn tại sách trước khi cập nhật.
        SELECT COUNT(*)
          INTO v_book_count
          FROM books
         WHERE book_id = p_book_id;

        IF v_book_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Không tìm thấy book để cập nhật.');
        END IF;

        -- Nếu ISBN có thay đổi thì kiểm tra trùng ISBN với bản ghi khác.
        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_book_count
              FROM books
             WHERE isbn = p_isbn
               AND book_id <> p_book_id;

            IF v_book_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20008, 'ISBN đã được sử dụng bởi sách khác.');
            END IF;
        END IF;

        UPDATE books
           SET title = p_title,
               isbn = p_isbn,
               price = p_price,
               stock_quantity = p_stock_quantity,
               description = p_description,
               publication_year = p_publication_year,
               page_count = p_page_count,
               category_id = p_category_id,
               publisher_id = p_publisher_id,
               updated_at = SYSDATE
         WHERE book_id = p_book_id;

    ELSE
        -- Kiểm tra ràng buộc nghiệp vụ trước khi xóa sách.
        SELECT COUNT(*)
          INTO v_dep_count
          FROM order_details
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Không thể xóa sách đã phát sinh đơn hàng.');
        END IF;

        SELECT COUNT(*)
          INTO v_dep_count
          FROM cart_items
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Không thể xóa sách đang tồn tại trong giỏ hàng.');
        END IF;

        DELETE FROM book_authors WHERE book_id = p_book_id;
        DELETE FROM book_images WHERE book_id = p_book_id;
        DELETE FROM inventory_transactions WHERE book_id = p_book_id;
        DELETE FROM books WHERE book_id = p_book_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Không tìm thấy book để xóa.');
        END IF;
    END IF;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20012, 'Vi phạm unique constraint khi xử lý book.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Lỗi sp_manage_book: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 2 [Nam]
-- Trả về báo cáo tổng hợp doanh thu đơn hàng theo tháng.
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_report_monthly_sales (
    p_from_date    IN DATE,
    p_to_date      IN DATE,
    p_result       OUT SYS_REFCURSOR
)
AS
BEGIN
    -- Mở ref cursor để ứng dụng có thể fetch dữ liệu báo cáo.
    OPEN p_result FOR
        SELECT TO_CHAR(TRUNC(order_date, 'MM'), 'YYYY-MM') AS month_key,
               COUNT(*) AS total_orders,
               SUM(CASE WHEN status = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
               SUM(total_amount) AS gross_amount,
               SUM(CASE WHEN status = 'DELIVERED' THEN total_amount ELSE 0 END) AS delivered_revenue,
               SUM(discount_amount) AS total_discount,
               SUM(shipping_fee) AS total_shipping
          FROM orders
         WHERE order_date >= TRUNC(p_from_date)
           AND order_date < TRUNC(p_to_date) + 1
         GROUP BY TRUNC(order_date, 'MM')
         ORDER BY TRUNC(order_date, 'MM');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20021, 'Lỗi sp_report_monthly_sales: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 3 [Hieu]
-- Dùng CURSOR để xuất danh sách sách sắp hết hàng ra DBMS_OUTPUT.
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_print_low_stock_books (
    p_threshold IN NUMBER DEFAULT 10
)
AS
    CURSOR c_low_stock IS
        SELECT b.book_id,
               b.title,
               b.stock_quantity,
               c.category_name,
               p.publisher_name
          FROM books b
          LEFT JOIN categories c ON c.category_id = b.category_id
          LEFT JOIN publishers p ON p.publisher_id = b.publisher_id
         WHERE b.stock_quantity <= p_threshold
         ORDER BY b.stock_quantity ASC, b.book_id ASC;

    v_row c_low_stock%ROWTYPE;
    v_total NUMBER := 0;
BEGIN
    -- In tiêu đề để dễ theo dõi kết quả danh sách.
    DBMS_OUTPUT.PUT_LINE('=== LOW STOCK BOOKS (threshold=' || p_threshold || ') ===');

    OPEN c_low_stock;
    LOOP
        FETCH c_low_stock INTO v_row;
        EXIT WHEN c_low_stock%NOTFOUND;

        v_total := v_total + 1;

        -- In từng dòng dữ liệu sách theo định dạng đơn giản.
        DBMS_OUTPUT.PUT_LINE(
            'BookID=' || v_row.book_id ||
            ' | Title=' || v_row.title ||
            ' | Stock=' || v_row.stock_quantity ||
            ' | Category=' || NVL(v_row.category_name, 'N/A') ||
            ' | Publisher=' || NVL(v_row.publisher_name, 'N/A')
        );
    END LOOP;
    CLOSE c_low_stock;

    DBMS_OUTPUT.PUT_LINE('Total low-stock books: ' || v_total);
EXCEPTION
    WHEN OTHERS THEN
        IF c_low_stock%ISOPEN THEN
            CLOSE c_low_stock;
        END IF;
        RAISE_APPLICATION_ERROR(-20031, 'Lỗi sp_print_low_stock_books: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 4 [Phat]
-- Nghiệp vụ bổ trợ: tính giảm giá coupon cho đơn hàng.
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_calculate_coupon_discount (
    p_coupon_code      IN VARCHAR2,
    p_order_amount     IN NUMBER,
    p_discount_amount  OUT NUMBER,
    p_message          OUT NVARCHAR2
)
AS
    v_discount_type        coupons.discount_type%TYPE;
    v_discount_value       coupons.discount_value%TYPE;
    v_start_at             coupons.start_at%TYPE;
    v_end_at               coupons.end_at%TYPE;
    v_max_uses             coupons.max_uses%TYPE;
    v_used_count           coupons.used_count%TYPE;
    v_min_order_amount     coupons.min_order_amount%TYPE;
    v_max_discount_amount  coupons.max_discount_amount%TYPE;
    v_is_active            coupons.is_active%TYPE;
BEGIN
    p_discount_amount := 0;
    p_message := 'COUPON_INVALID';

    -- Kiểm tra đầu vào đơn hàng.
    IF p_order_amount IS NULL OR p_order_amount <= 0 THEN
        p_message := 'ORDER_AMOUNT_INVALID';
        RETURN;
    END IF;

    -- Lấy thông tin coupon theo code.
    SELECT discount_type,
           discount_value,
           start_at,
           end_at,
           max_uses,
           used_count,
           min_order_amount,
           max_discount_amount,
           is_active
      INTO v_discount_type,
           v_discount_value,
           v_start_at,
           v_end_at,
           v_max_uses,
           v_used_count,
           v_min_order_amount,
           v_max_discount_amount,
           v_is_active
      FROM coupons
     WHERE coupon_code = p_coupon_code;

    -- Kiểm tra coupon còn hiệu lực sử dụng.
    IF v_is_active <> 1 THEN
        p_message := 'COUPON_NOT_ACTIVE';
        RETURN;
    END IF;

    IF SYSDATE < v_start_at OR SYSDATE > v_end_at THEN
        p_message := 'COUPON_OUT_OF_DATE';
        RETURN;
    END IF;

    IF v_max_uses IS NOT NULL AND v_used_count >= v_max_uses THEN
        p_message := 'COUPON_EXHAUSTED';
        RETURN;
    END IF;

    IF p_order_amount < v_min_order_amount THEN
        p_message := 'ORDER_NOT_ENOUGH_FOR_COUPON';
        RETURN;
    END IF;

    -- Tính giá trị giảm theo loại PERCENT/FIXED.
    IF v_discount_type = 'PERCENT' THEN
        p_discount_amount := ROUND(p_order_amount * v_discount_value / 100, 2);
    ELSE
        p_discount_amount := v_discount_value;
    END IF;

    -- Áp trần giảm tối đa nếu coupon có max_discount_amount.
    IF v_max_discount_amount IS NOT NULL THEN
        p_discount_amount := LEAST(p_discount_amount, v_max_discount_amount);
    END IF;

    -- Không cho giảm vượt qua tổng tiền đơn.
    p_discount_amount := LEAST(p_discount_amount, p_order_amount);
    p_message := 'OK';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_discount_amount := 0;
        p_message := 'COUPON_NOT_FOUND';
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20041, 'Lỗi sp_calculate_coupon_discount: ' || SQLERRM);
END;
/

-- ==========================================================
-- KẾT THÚC FILE
-- ==========================================================
