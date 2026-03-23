const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');
const { query, execute, withConnection, initPool } = require('../db');
const { success, error, formatOracleError } = require('../utils/responseUtils');

const allowedTables = {
  categories: {
    label: 'Danh mục',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM categories',
    query: `
      SELECT
        category_id,
        category_name,
        description,
        parent_id
      FROM categories
      ORDER BY category_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  carts: {
    label: 'Giỏ hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM carts',
    query: `
      SELECT
        cart_id,
        customer_id,
        created_at,
        updated_at,
        status
      FROM carts
      ORDER BY cart_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  cart_items: {
    label: 'Chi tiết giỏ hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM cart_items',
    query: `
      SELECT
        cart_item_id,
        cart_id,
        book_id,
        quantity,
        unit_price,
        created_at,
        updated_at
      FROM cart_items
      ORDER BY cart_item_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  books: {
    label: 'Sách',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM books',
    query: `
      SELECT
        book_id,
        title,
        isbn,
        price,
        stock_quantity,
        DBMS_LOB.SUBSTR(description, 200, 1) AS description,
        publication_year,
        page_count,
        category_id,
        publisher_id,
        created_at,
        updated_at
      FROM books
      ORDER BY book_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  book_images: {
    label: 'Ảnh sách',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM book_images',
    query: `
      SELECT
        image_id,
        book_id,
        image_url,
        is_primary,
        sort_order,
        created_at
      FROM book_images
      ORDER BY image_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  book_authors: {
    label: 'Tác giả theo sách',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM book_authors',
    query: `
      SELECT
        book_id,
        author_id,
        role,
        author_order
      FROM book_authors
      ORDER BY book_id, author_order NULLS LAST, author_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  customers: {
    label: 'Khách hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM customers',
    query: `
      SELECT
        customer_id,
        full_name,
        email,
        password_hash,
        phone,
        address,
        created_at,
        updated_at,
        status
      FROM customers
      ORDER BY customer_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  authors: {
    label: 'Tác giả',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM authors',
    query: `
      SELECT
        author_id,
        author_name,
        DBMS_LOB.SUBSTR(biography, 200, 1) AS biography,
        birth_date,
        nationality
      FROM authors
      ORDER BY author_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  publishers: {
    label: 'Nhà xuất bản',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM publishers',
    query: `
      SELECT
        publisher_id,
        publisher_name,
        address,
        phone,
        email
      FROM publishers
      ORDER BY publisher_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  coupons: {
    label: 'Mã giảm giá',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM coupons',
    query: `
      SELECT
        coupon_id,
        coupon_code,
        coupon_name,
        discount_type,
        discount_value,
        start_at,
        end_at,
        max_uses,
        used_count,
        per_customer_limit,
        min_order_amount,
        max_discount_amount,
        is_active
      FROM coupons
      ORDER BY coupon_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  orders: {
    label: 'Đơn hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM orders',
    query: `
      SELECT
        order_id,
        customer_id,
        coupon_id,
        order_date,
        total_amount,
        status,
        shipping_address,
        payment_method,
        payment_status,
        shipping_fee,
        discount_amount,
        updated_at
      FROM orders
      ORDER BY order_id DESC
      FETCH FIRST :limit ROWS ONLY
    `
  },
  order_details: {
    label: 'Chi tiết đơn hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM order_details',
    query: `
      SELECT
        order_detail_id,
        order_id,
        book_id,
        quantity,
        unit_price,
        subtotal
      FROM order_details
      ORDER BY order_detail_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  order_status_history: {
    label: 'Lịch sử trạng thái đơn',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM order_status_history',
    query: `
      SELECT
        status_history_id,
        order_id,
        old_status,
        new_status,
        changed_at,
        changed_by,
        changed_source,
        note
      FROM order_status_history
      ORDER BY status_history_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  reviews: {
    label: 'Đánh giá',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM reviews',
    query: `
      SELECT
        review_id,
        order_id,
        book_id,
        rating,
        DBMS_LOB.SUBSTR(review_comment, 200, 1) AS review_comment,
        review_date
      FROM reviews
      ORDER BY review_id DESC
      FETCH FIRST :limit ROWS ONLY
    `
  },
  inventory_transactions: {
    label: 'Giao dịch kho',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM inventory_transactions',
    query: `
      SELECT
        txn_id,
        book_id,
        txn_type,
        reference_id,
        reference_type,
        quantity,
        created_at,
        note
      FROM inventory_transactions
      ORDER BY txn_id DESC
      FETCH FIRST :limit ROWS ONLY
    `
  },
  orders_audit_log: {
    label: 'Audit log đơn hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM orders_audit_log',
    query: `
      SELECT
        audit_id,
        order_id,
        action_type,
        old_status,
        new_status,
        old_total_amount,
        new_total_amount,
        old_payment_status,
        new_payment_status,
        action_by,
        action_at,
        module_name,
        client_identifier,
        note
      FROM orders_audit_log
      ORDER BY audit_id DESC
      FETCH FIRST :limit ROWS ONLY
    `
  },
  vw_order_sales_report: {
    label: 'View báo cáo bán hàng',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM vw_order_sales_report',
    query: `
      SELECT
        order_id,
        order_date,
        customer_name,
        customer_email,
        order_status,
        payment_method,
        payment_status,
        book_title,
        category_name,
        publisher_name,
        quantity,
        unit_price,
        line_subtotal,
        shipping_fee,
        discount_amount,
        order_total_amount,
        line_weight_percent
      FROM vw_order_sales_report
      ORDER BY order_id DESC
      FETCH FIRST :limit ROWS ONLY
    `
  },
  vw_customer_secure_profile: {
    label: 'View khách hàng (đã mask)',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM vw_customer_secure_profile',
    query: `
      SELECT
        customer_id,
        full_name,
        masked_email,
        masked_phone,
        masked_address,
        status,
        total_orders,
        total_spent,
        customer_segment,
        created_at,
        updated_at
      FROM vw_customer_secure_profile
      ORDER BY customer_id
      FETCH FIRST :limit ROWS ONLY
    `
  },
  mv_daily_category_sales: {
    label: 'MV doanh thu theo ngày',
    countQuery: 'SELECT COUNT(*) AS total_rows FROM mv_daily_category_sales',
    query: `
      SELECT
        sale_date,
        category_id,
        category_name,
        total_orders,
        total_units_sold,
        gross_merchandise_value,
        avg_unit_price,
        latest_order_at
      FROM mv_daily_category_sales
      ORDER BY sale_date DESC, category_id
      FETCH FIRST :limit ROWS ONLY
    `
  }
};

// --- Helper Functions ---
function getOracleDate(value) {
  const trimmed = String(value || '').trim();
  if (!trimmed) return null;
  const parsed = new Date(trimmed);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

// --- Admin Endpoints ---

router.get('/summary', async (req, res) => {
  try {
    const [bookStats] = await query(`
      SELECT COUNT(*) AS total_books, NVL(SUM(stock_quantity), 0) AS total_stock
      FROM books
    `);

    const [customerStats] = await query(`
      SELECT COUNT(*) AS total_customers
      FROM customers
    `);

    const [orderStats] = await query(`
      SELECT COUNT(*) AS total_orders,
             NVL(SUM(CASE WHEN status = 'DELIVERED' THEN total_amount ELSE 0 END), 0) AS delivered_revenue
      FROM orders
    `);

    const [reviewStats] = await query(`
      SELECT COUNT(*) AS total_reviews,
             ROUND(NVL(AVG(rating), 0), 2) AS avg_rating
      FROM reviews
    `);

    const recentOrders = await query(`
      SELECT
        o.order_id,
        c.full_name,
        o.total_amount,
        o.status,
        o.order_date
      FROM orders o
      JOIN customers c ON c.customer_id = o.customer_id
      ORDER BY o.order_date DESC, o.order_id DESC
      FETCH FIRST 5 ROWS ONLY
    `);

    success(res, {
      cards: {
        totalBooks: bookStats.TOTAL_BOOKS,
        totalStock: bookStats.TOTAL_STOCK,
        totalCustomers: customerStats.TOTAL_CUSTOMERS,
        totalOrders: orderStats.TOTAL_ORDERS,
        deliveredRevenue: orderStats.DELIVERED_REVENUE,
        totalReviews: reviewStats.TOTAL_REVIEWS,
        avgRating: reviewStats.AVG_RATING
      },
      recentOrders
    });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/tables', async (req, res) => {
  try {
    const tables = await Promise.all(
      Object.entries(allowedTables).map(async ([key, value]) => {
        const [countResult] = await query(value.countQuery);
        return {
          key,
          label: value.label,
          totalRows: Number(countResult.TOTAL_ROWS || 0)
        };
      })
    );
    success(res, tables);
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/table/:tableName', async (req, res) => {
  const table = allowedTables[req.params.tableName];
  const requestedLimit = Number(req.query.limit || 25);
  const limit = Math.min(Math.max(requestedLimit, 1), 100);

  if (!table) {
    return error(res, 'Bảng không được hỗ trợ.', 404);
  }

  try {
    const [countResult, rows] = await Promise.all([
      query(table.countQuery),
      query(table.query, { limit })
    ]);

    const totalRows = Number((countResult[0] && countResult[0].TOTAL_ROWS) || 0);
    const columns = rows.length > 0 ? Object.keys(rows[0]) : [];

    success(res, {
      table: req.params.tableName,
      label: table.label,
      totalRows,
      columns,
      rows
    });
  } catch (err) {
    error(res, err.message);
  }
});

// --- Testing / Procedure Endpoints ---

router.post('/testing/procedures/manage-book', async (req, res) => {
  const action = String(req.body.action || '').trim().toUpperCase();
  if (!['ADD', 'UPDATE', 'DELETE'].includes(action)) {
    return error(res, 'Action không hợp lệ. Chỉ hỗ trợ ADD/UPDATE/DELETE.', 400);
  }

  try {
    const binds = {
      p_action: action,
      p_book_id: {
        dir: oracledb.BIND_INOUT,
        type: oracledb.NUMBER,
        val: req.body.bookId == null ? null : Number(req.body.bookId)
      },
      p_title: req.body.title ?? null,
      p_isbn: req.body.isbn ?? null,
      p_price: req.body.price == null ? null : Number(req.body.price),
      p_stock_quantity: req.body.stockQuantity == null ? null : Number(req.body.stockQuantity),
      p_description: req.body.description ?? null,
      p_publication_year: req.body.publicationYear == null ? null : Number(req.body.publicationYear),
      p_page_count: req.body.pageCount == null ? null : Number(req.body.pageCount),
      p_category_id: req.body.categoryId == null ? null : Number(req.body.categoryId),
      p_publisher_id: req.body.publisherId == null ? null : Number(req.body.publisherId)
    };

    const result = await execute(
      `
        BEGIN
          sp_manage_book(
            :p_action,
            :p_book_id,
            :p_title,
            :p_isbn,
            :p_price,
            :p_stock_quantity,
            :p_description,
            :p_publication_year,
            :p_page_count,
            :p_category_id,
            :p_publisher_id
          );
        END;
      `,
      binds,
      { autoCommit: true }
    );

    success(res, {
      ok: true,
      action,
      bookId: result.outBinds.p_book_id,
      message: `Procedure sp_manage_book(${action}) chạy thành công.`
    });
  } catch (err) {
    error(res, err.message, 400);
  }
});

// ... I'll add the rest of the testing procedures and triggers here ...
// For brevity, I'll move them all in this one call since I'm creating the NEW file.

router.post('/testing/procedures/monthly-sales', async (req, res) => {
  const fromDate = String(req.body.fromDate || '').trim();
  const toDate = String(req.body.toDate || '').trim();

  if (!fromDate || !toDate) {
    return error(res, 'Vui lòng nhập fromDate và toDate (YYYY-MM-DD).', 400);
  }

  const activePool = await initPool();
  const connection = await activePool.getConnection();

  try {
    const result = await connection.execute(
      `BEGIN sp_report_monthly_sales(:p_from_date, :p_to_date, :p_result); END;`,
      {
        p_from_date: new Date(fromDate),
        p_to_date: new Date(toDate),
        p_result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
      },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const resultSet = result.outBinds.p_result;
    const rows = await resultSet.getRows(1000);
    await resultSet.close();

    success(res, { ok: true, rows, count: rows.length });
  } catch (err) {
    error(res, err.message, 400);
  } finally {
    await connection.close();
  }
});

router.post('/testing/procedures/low-stock', async (req, res) => {
  const threshold = Number(req.body.threshold ?? 10);
  if (Number.isNaN(threshold) || threshold < 0) {
    return error(res, 'Ngưỡng tồn kho phải là số >= 0.', 400);
  }

  try {
    await execute(`BEGIN sp_print_low_stock_books(:p_threshold); END;`, { p_threshold: threshold }, { autoCommit: false });
    const rows = await query(
      `
        SELECT
          b.book_id,
          b.title,
          b.stock_quantity,
          c.category_name,
          p.publisher_name
        FROM books b
        LEFT JOIN categories c ON c.category_id = b.category_id
        LEFT JOIN publishers p ON p.publisher_id = b.publisher_id
        WHERE b.stock_quantity <= :threshold
        ORDER BY b.stock_quantity ASC, b.book_id ASC
      `,
      { threshold }
    );

    success(res, {
      ok: true,
      message: 'Procedure sp_print_low_stock_books chạy thành công.',
      rows,
      count: rows.length
    });
  } catch (err) {
    error(res, err.message, 400);
  }
});

router.post('/testing/procedures/coupon-discount', async (req, res) => {
  const couponCode = String(req.body.couponCode || '').trim();
  const orderAmount = Number(req.body.orderAmount);

  if (!couponCode) return error(res, 'Coupon code không được để trống.', 400);
  if (Number.isNaN(orderAmount) || orderAmount <= 0) return error(res, 'orderAmount phải là số > 0.', 400);

  try {
    const result = await execute(
      `
        BEGIN
          sp_calculate_coupon_discount(
            :p_coupon_code,
            :p_order_amount,
            :p_discount_amount,
            :p_message
          );
        END;
      `,
      {
        p_coupon_code: couponCode,
        p_order_amount: orderAmount,
        p_discount_amount: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        p_message: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 }
      }
    );

    success(res, {
      ok: true,
      couponCode,
      orderAmount,
      discountAmount: result.outBinds.p_discount_amount,
      messageCode: result.outBinds.p_message
    });
  } catch (err) {
    error(res, err.message, 400);
  }
});

router.post('/testing/triggers/validation', async (req, res) => {
  const scenario = String(req.body.scenario || '').trim();
  if (!['short-address', 'delivered-unpaid', 'missing-payment-method'].includes(scenario)) {
    return error(res, 'Scenario không hợp lệ.', 400);
  }

  try {
    const result = await withConnection(async (connection) => {
      if (scenario === 'short-address') {
        try {
          await connection.execute(
            `INSERT INTO orders (order_id, customer_id, total_amount, status, shipping_address, payment_status, shipping_fee)
             VALUES (NULL, :customer_id, 0, 'PENDING', :shipping_address, 'PENDING', 30000)`,
            {
              customer_id: Number(req.body.customerId || 1),
              shipping_address: req.body.shippingAddress || 'Qua ngan'
            }
          );
          await connection.rollback();
          return { ok: false, passed: false, scenario, message: 'Trigger không chặn dữ liệu như kỳ vọng.' };
        } catch (err) {
          await connection.rollback();
          return { ok: true, passed: true, scenario, message: formatOracleError(err) };
        }
      }

      try {
        await connection.execute(
          `UPDATE orders SET status = :status, payment_status = :payment_status, payment_method = :payment_method WHERE order_id = :order_id`,
          {
            status: scenario === 'delivered-unpaid' ? 'DELIVERED' : 'CONFIRMED',
            payment_status: req.body.paymentStatus || 'PENDING',
            payment_method: scenario === 'missing-payment-method' ? null : (req.body.paymentMethod || 'COD'),
            order_id: Number(req.body.orderId || 7)
          },
          { autoCommit: false }
        );
        await connection.rollback();
        return { ok: false, passed: false, scenario, message: 'Trigger không chặn cập nhật như kỳ vọng.' };
      } catch (err) {
        await connection.rollback();
        return { ok: true, passed: true, scenario, message: formatOracleError(err) };
      }
    });
    success(res, result);
  } catch (err) {
    error(res, formatOracleError(err), 400);
  }
});

// Update Order Status (Admin)
router.put('/orders/:orderId/status', async (req, res) => {
  const orderId = Number(req.params.orderId);
  const { status, paymentStatus, note } = req.body;

  try {
    await execute(
      `UPDATE orders SET status = :status, payment_status = :paymentStatus, updated_at = SYSDATE WHERE order_id = :orderId`,
      { status, paymentStatus, orderId },
      { autoCommit: true }
    );
    success(res, { ok: true, message: 'Cập nhật trạng thái thành công.' });
  } catch (err) {
    error(res, err.message, 400);
  }
});

module.exports = router;
