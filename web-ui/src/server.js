const express = require('express');
const os = require('os');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const { closePool, initPool, query } = require('./db');

const app = express();
const port = Number(process.env.PORT || 3000);
const maxPortAttempts = 20;
const startedAt = new Date().toISOString();
const runtimeState = {
  preferredPort: port,
  actualPort: null,
  hostname: os.hostname(),
  pid: process.pid,
  nodeVersion: process.version,
  startedAt
};

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
        cover_image_url,
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
  }
};

app.use(express.json());
app.use(express.static(path.resolve(__dirname, '..', 'public')));

app.get('/api/health', async (req, res) => {
  try {
    await query('SELECT 1 AS ok FROM dual');
    res.json({ ok: true, database: 'connected' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

app.get('/api/summary', async (req, res) => {
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

    res.json({
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
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/tables', async (req, res) => {
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

    res.json(tables);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/table/:tableName', async (req, res) => {
  const table = allowedTables[req.params.tableName];
  const requestedLimit = Number(req.query.limit || 25);
  const limit = Math.min(Math.max(requestedLimit, 1), 100);

  if (!table) {
    return res.status(404).json({ message: 'Bảng không được hỗ trợ.' });
  }

  try {
    const [countResult, rows] = await Promise.all([
      query(table.countQuery),
      query(table.query, { limit })
    ]);

    const totalRows = Number((countResult[0] && countResult[0].TOTAL_ROWS) || 0);
    const columns = rows.length > 0 ? Object.keys(rows[0]) : [];

    res.json({
      table: req.params.tableName,
      label: table.label,
      totalRows,
      columns,
      rows
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/search/books', async (req, res) => {
  const term = String(req.query.q || '').trim();

  if (!term) {
    return res.json({ rows: [] });
  }

  try {
    const rows = await query(
      `
        SELECT
          b.book_id,
          b.title,
          b.price,
          c.category_name,
          p.publisher_name,
          b.stock_quantity
        FROM books b
        LEFT JOIN categories c ON c.category_id = b.category_id
        LEFT JOIN publishers p ON p.publisher_id = b.publisher_id
        WHERE UPPER(b.title) LIKE '%' || UPPER(:term) || '%'
        ORDER BY b.title
        FETCH FIRST 20 ROWS ONLY
      `,
      { term }
    );

    res.json({ rows });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/runtime', (req, res) => {
  const actualPort = runtimeState.actualPort;

  res.json({
    appName: 'DigiBook Oracle Web UI',
    preferredPort: runtimeState.preferredPort,
    actualPort,
    hostname: runtimeState.hostname,
    pid: runtimeState.pid,
    nodeVersion: runtimeState.nodeVersion,
    startedAt: runtimeState.startedAt,
    baseUrl: actualPort ? `http://localhost:${actualPort}` : null
  });
});

app.get('*', (req, res) => {
  res.sendFile(path.resolve(__dirname, '..', 'public', 'index.html'));
});

function listenOnAvailablePort(preferredPort, attempt = 0) {
  const candidatePort = preferredPort + attempt;

  return new Promise((resolve, reject) => {
    const server = app.listen(candidatePort);

    server.once('listening', () => {
      resolve({ server, actualPort: candidatePort });
    });

    server.once('error', (error) => {
      if (error.code === 'EADDRINUSE' && attempt < maxPortAttempts) {
        console.warn(`Cổng ${candidatePort} đang được sử dụng. Thử cổng ${candidatePort + 1}...`);
        listenOnAvailablePort(preferredPort, attempt + 1).then(resolve).catch(reject);
        return;
      }

      reject(error);
    });
  });
}

async function start() {
  try {
    await initPool();
    const { server, actualPort } = await listenOnAvailablePort(port);
    runtimeState.actualPort = actualPort;

    console.log(`DigiBook UI running at http://localhost:${actualPort}`);

    server.on('error', async (error) => {
      await closePool();
      console.error('Cannot start server:', error.message);
      process.exit(1);
    });
  } catch (error) {
    await closePool();
    console.error('Cannot start server:', error.message);
    process.exit(1);
  }
}

process.on('SIGINT', async () => {
  await closePool();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await closePool();
  process.exit(0);
});

start();