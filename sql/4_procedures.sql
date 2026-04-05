-- ==========================================================
-- FILE: 4_procedures.sql
-- MÔN: Cơ sở dữ liệu Oracle 19c - Đồ án DigiBook
-- NHÓM: Dũng, Nam, Hiếu, Phát
-- MỤC TIÊU: Xây dựng 4 Stored Procedures cho nghiệp vụ chính
-- ==========================================================

-- ==========================================================
-- SP 1 (Dũng)
-- Quản lý BOOKS theo hành động ADD/UPDATE/DELETE
-- Có kiểm tra nghiệp vụ và xử lý EXCEPTION rõ ràng
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_manage_book (
    p_action            IN VARCHAR2,
    p_book_id           IN OUT NUMBER,
    p_isbn              IN VARCHAR2,
    p_title             IN NVARCHAR2,
    p_description       IN NCLOB,
    p_category_id       IN NUMBER,
    p_publisher_id      IN NUMBER,
    p_price             IN NUMBER,
    p_stock_quantity    IN NUMBER,
    p_publication_year  IN NUMBER,
    p_page_count        IN NUMBER,
    p_language          IN VARCHAR2 DEFAULT 'vi',
    p_cover_type        IN VARCHAR2 DEFAULT 'PAPERBACK',
    p_updated_by        IN NUMBER DEFAULT NULL
)
AS
    v_action          VARCHAR2(10);
    v_count           NUMBER;
    v_dep_count       NUMBER;
BEGIN
    -- Chuẩn hóa action để tránh sai khác chữ hoa/thường.
    v_action := UPPER(TRIM(p_action));

    IF v_action NOT IN ('ADD', 'UPDATE', 'DELETE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Action không hợp lệ. Chỉ hỗ trợ ADD/UPDATE/DELETE.');
    END IF;

    IF v_action = 'ADD' THEN
        -- Validate dữ liệu đầu vào tối thiểu cho thêm mới.
        IF p_title IS NULL OR p_category_id IS NULL OR p_price IS NULL OR p_price < 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Thiếu dữ liệu bắt buộc hoặc giá không hợp lệ khi thêm sách.');
        END IF;

        IF p_stock_quantity IS NOT NULL AND p_stock_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'stock_quantity không được âm.');
        END IF;

        -- Kiểm tra FK category.
        SELECT COUNT(*)
          INTO v_count
          FROM categories
         WHERE category_id = p_category_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Category không tồn tại.');
        END IF;

        -- Kiểm tra FK publisher (nếu có truyền).
        IF p_publisher_id IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM publishers
             WHERE publisher_id = p_publisher_id;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20005, 'Publisher không tồn tại.');
            END IF;
        END IF;

        -- Kiểm tra trùng ISBN (nếu có truyền).
        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM books
             WHERE isbn = p_isbn;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20006, 'ISBN đã tồn tại.');
            END IF;
        END IF;

        INSERT INTO books (
            book_id, isbn, title, description, category_id, publisher_id, price,
            stock_quantity, page_count, publication_year, language, cover_type,
            created_at, updated_at, updated_by
        ) VALUES (
            p_book_id, p_isbn, p_title, p_description, p_category_id, p_publisher_id, p_price,
            NVL(p_stock_quantity, 0), p_page_count, p_publication_year, NVL(p_language, 'vi'), p_cover_type,
            SYSDATE, SYSDATE, p_updated_by
        )
        RETURNING book_id INTO p_book_id;

    ELSIF v_action = 'UPDATE' THEN
        -- Kiểm tra sách tồn tại.
        SELECT COUNT(*)
          INTO v_count
          FROM books
         WHERE book_id = p_book_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Không tìm thấy sách để cập nhật.');
        END IF;

        IF p_price IS NOT NULL AND p_price < 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Giá sách không được âm.');
        END IF;

        IF p_stock_quantity IS NOT NULL AND p_stock_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'stock_quantity không được âm.');
        END IF;

        -- Nếu ISBN có truyền thì kiểm tra không trùng với sách khác.
        IF p_isbn IS NOT NULL THEN
            SELECT COUNT(*)
              INTO v_count
              FROM books
             WHERE isbn = p_isbn
               AND book_id <> p_book_id;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20010, 'ISBN đã được dùng bởi sách khác.');
            END IF;
        END IF;

        UPDATE books
           SET isbn = COALESCE(p_isbn, isbn),
               title = COALESCE(p_title, title),
               description = COALESCE(p_description, description),
               category_id = COALESCE(p_category_id, category_id),
               publisher_id = COALESCE(p_publisher_id, publisher_id),
               price = COALESCE(p_price, price),
               stock_quantity = COALESCE(p_stock_quantity, stock_quantity),
               publication_year = COALESCE(p_publication_year, publication_year),
               page_count = COALESCE(p_page_count, page_count),
               language = COALESCE(p_language, language),
               cover_type = COALESCE(p_cover_type, cover_type),
               updated_at = SYSDATE,
               updated_by = p_updated_by
         WHERE book_id = p_book_id;

    ELSE
        -- Trước khi xóa, kiểm tra phụ thuộc nghiệp vụ quan trọng.
        SELECT COUNT(*)
          INTO v_dep_count
          FROM order_details
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Không thể xóa sách đã phát sinh đơn hàng.');
        END IF;

        SELECT COUNT(*)
          INTO v_dep_count
          FROM cart_items
         WHERE book_id = p_book_id;

        IF v_dep_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Không thể xóa sách đang nằm trong giỏ hàng.');
        END IF;

        DELETE FROM books
         WHERE book_id = p_book_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Không tìm thấy sách để xóa.');
        END IF;
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20014, 'Vi phạm ràng buộc duy nhất (ISBN hoặc khóa unique khác).');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20015, 'Lỗi sp_manage_book: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 2 (Nam)
-- Báo cáo tổng hợp doanh thu theo tháng (dùng SYS_REFCURSOR)
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_report_monthly_sales (
    p_from_date      IN DATE,
    p_to_date        IN DATE,
    p_branch_id      IN NUMBER DEFAULT NULL,
    p_result         OUT SYS_REFCURSOR
)
AS
BEGIN
    IF p_from_date IS NULL OR p_to_date IS NULL OR p_from_date > p_to_date THEN
        RAISE_APPLICATION_ERROR(-20101, 'Khoảng ngày báo cáo không hợp lệ.');
    END IF;

    OPEN p_result FOR
        SELECT TO_CHAR(TRUNC(o.order_date, 'MM'), 'YYYY-MM') AS month_key,
               COUNT(*) AS total_orders,
               SUM(CASE WHEN o.status_code = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
               SUM(CASE WHEN o.status_code = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
               SUM(o.total_amount) AS gross_amount,
               SUM(o.discount_amount) AS total_discount,
               SUM(o.shipping_fee) AS total_shipping_fee,
               SUM(o.final_amount) AS final_amount_sum,
               SUM(CASE WHEN o.status_code = 'DELIVERED' THEN o.final_amount ELSE 0 END) AS delivered_revenue
          FROM orders o
         WHERE o.order_date >= TRUNC(p_from_date)
           AND o.order_date < TRUNC(p_to_date) + 1
           AND (p_branch_id IS NULL OR o.branch_id = p_branch_id)
         GROUP BY TRUNC(o.order_date, 'MM')
         ORDER BY TRUNC(o.order_date, 'MM');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20102, 'Lỗi sp_report_monthly_sales: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 3 (Hiếu)
-- Dùng CURSOR để in danh sách tồn kho thấp theo chi nhánh
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_print_low_stock_inventory (
    p_branch_id IN NUMBER DEFAULT NULL,
    p_result    OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_result FOR
        SELECT bi.branch_id AS branch_id,
               br.branch_name AS branch_name,
               bi.book_id AS book_id,
               b.title AS title,
               bi.quantity_available AS quantity_available,
               bi.low_stock_threshold AS low_stock_threshold
          FROM branch_inventory bi
          JOIN branches br ON br.branch_id = bi.branch_id
          JOIN books b ON b.book_id = bi.book_id
         WHERE bi.quantity_available <= bi.low_stock_threshold
           AND (p_branch_id IS NULL OR bi.branch_id = p_branch_id)
         ORDER BY bi.branch_id, bi.quantity_available, bi.book_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20201, 'Lỗi sp_print_low_stock_inventory: ' || SQLERRM);
END;
/

-- ==========================================================
-- SP 4 (Phát)
-- Nghiệp vụ bổ trợ: kiểm tra và tính giảm giá coupon cho đơn hàng
-- ==========================================================
CREATE OR REPLACE PROCEDURE sp_calculate_coupon_discount (
    p_coupon_code      IN VARCHAR2,
    p_order_amount     IN NUMBER,
    p_discount_amount  OUT NUMBER,
    p_message          OUT NVARCHAR2
)
AS
    v_discount_type       coupons.discount_type%TYPE;
    v_discount_value      coupons.discount_value%TYPE;
    v_start_date          coupons.start_date%TYPE;
    v_end_date            coupons.end_date%TYPE;
    v_usage_limit         coupons.usage_limit%TYPE;
    v_usage_count         coupons.usage_count%TYPE;
    v_min_order_amount    coupons.min_order_amount%TYPE;
    v_max_discount_amount coupons.max_discount_amount%TYPE;
    v_is_active           coupons.is_active%TYPE;
BEGIN
    p_discount_amount := 0;
    p_message := N'COUPON_INVALID';

    -- Validate tổng tiền đơn hàng trước khi kiểm tra coupon.
    IF p_order_amount IS NULL OR p_order_amount <= 0 THEN
        p_message := N'ORDER_AMOUNT_INVALID';
        RETURN;
    END IF;

    -- Truy vấn coupon theo mã.
    SELECT discount_type,
           discount_value,
           start_date,
           end_date,
           usage_limit,
           usage_count,
           min_order_amount,
           max_discount_amount,
           is_active
      INTO v_discount_type,
           v_discount_value,
           v_start_date,
           v_end_date,
           v_usage_limit,
           v_usage_count,
           v_min_order_amount,
           v_max_discount_amount,
           v_is_active
      FROM coupons
     WHERE coupon_code = p_coupon_code;

    -- Kiểm tra điều kiện hiệu lực coupon.
    IF v_is_active <> 1 THEN
        p_message := N'COUPON_NOT_ACTIVE';
        RETURN;
    END IF;

    IF TRUNC(SYSDATE) < TRUNC(v_start_date) OR TRUNC(SYSDATE) > TRUNC(v_end_date) THEN
        p_message := N'COUPON_OUT_OF_DATE';
        RETURN;
    END IF;

    IF v_usage_limit IS NOT NULL AND v_usage_count >= v_usage_limit THEN
        p_message := N'COUPON_EXHAUSTED';
        RETURN;
    END IF;

    IF p_order_amount < NVL(v_min_order_amount, 0) THEN
        p_message := N'ORDER_NOT_ENOUGH_FOR_COUPON';
        RETURN;
    END IF;

    -- Tính giảm theo loại PERCENT/FIXED.
    IF v_discount_type = 'PERCENT' THEN
        p_discount_amount := ROUND(p_order_amount * v_discount_value / 100, 2);
    ELSE
        p_discount_amount := v_discount_value;
    END IF;

    -- Giới hạn giảm tối đa (nếu có).
    IF v_max_discount_amount IS NOT NULL THEN
        p_discount_amount := LEAST(p_discount_amount, v_max_discount_amount);
    END IF;

    -- Không cho giảm lớn hơn tổng tiền đơn.
    p_discount_amount := LEAST(p_discount_amount, p_order_amount);
    p_message := N'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_discount_amount := 0;
        p_message := N'COUPON_NOT_FOUND';
    WHEN TOO_MANY_ROWS THEN
        p_discount_amount := 0;
        p_message := N'COUPON_CODE_DUPLICATED';
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20301, 'Lỗi sp_calculate_coupon_discount: ' || SQLERRM);
END;
/

-- ==========================================================
-- KẾT THÚC FILE 4_procedures.sql
-- ==========================================================
