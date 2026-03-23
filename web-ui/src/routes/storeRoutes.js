const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');
const { query, withConnection } = require('../db');
const { success, error } = require('../utils/responseUtils');

router.get('/categories', async (req, res) => {
  try {
    const rows = await query(`
      SELECT category_id, category_name, description, parent_id
      FROM categories
      ORDER BY category_id
    `);
    success(res, { rows });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/featured-books', async (req, res) => {
  try {
    const rows = await query(`
      SELECT b.book_id, b.title, b.price, b.stock_quantity,
             bi.image_url,
             NVL(r.avg_rating, 0) AS avg_rating,
             NVL(r.review_count, 0) AS review_count,
             a.author_name
      FROM books b
      LEFT JOIN book_images bi ON bi.book_id = b.book_id AND bi.is_primary = 1
      LEFT JOIN (
        SELECT book_id, ROUND(AVG(rating), 1) AS avg_rating, COUNT(*) AS review_count
        FROM reviews GROUP BY book_id
      ) r ON r.book_id = b.book_id
      LEFT JOIN (
        SELECT ba.book_id, au.author_name
        FROM book_authors ba
        JOIN authors au ON au.author_id = ba.author_id
        WHERE ba.role = 'AUTHOR' AND (ba.author_order = 1 OR ba.author_order IS NULL)
        AND ROWNUM > 0
      ) a ON a.book_id = b.book_id
      WHERE b.stock_quantity > 0
      ORDER BY avg_rating DESC NULLS LAST, b.created_at DESC
      FETCH FIRST 8 ROWS ONLY
    `);
    success(res, { rows });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/new-books', async (req, res) => {
  try {
    const rows = await query(`
      SELECT b.book_id, b.title, b.price, b.stock_quantity,
             bi.image_url,
             NVL(r.avg_rating, 0) AS avg_rating,
             NVL(r.review_count, 0) AS review_count,
             a.author_name
      FROM books b
      LEFT JOIN book_images bi ON bi.book_id = b.book_id AND bi.is_primary = 1
      LEFT JOIN (
        SELECT book_id, ROUND(AVG(rating), 1) AS avg_rating, COUNT(*) AS review_count
        FROM reviews GROUP BY book_id
      ) r ON r.book_id = b.book_id
      LEFT JOIN (
        SELECT ba.book_id, au.author_name
        FROM book_authors ba
        JOIN authors au ON au.author_id = ba.author_id
        WHERE ba.role = 'AUTHOR' AND (ba.author_order = 1 OR ba.author_order IS NULL)
        AND ROWNUM > 0
      ) a ON a.book_id = b.book_id
      ORDER BY b.created_at DESC, b.book_id DESC
      FETCH FIRST 8 ROWS ONLY
    `);
    success(res, { rows });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/active-coupons', async (req, res) => {
  try {
    const rows = await query(`
      SELECT coupon_id, coupon_code, coupon_name, discount_type,
             discount_value, end_at, min_order_amount, max_discount_amount
      FROM coupons
      WHERE is_active = 1 AND SYSDATE BETWEEN start_at AND end_at
        AND (max_uses IS NULL OR used_count < max_uses)
      ORDER BY end_at ASC
    `);
    success(res, { rows });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/books', async (req, res) => {
  const categoryId = req.query.category ? Number(req.query.category) : null;
  const sort = String(req.query.sort || 'newest');
  const page = Math.max(Number(req.query.page || 1), 1);
  const limit = Math.min(Math.max(Number(req.query.limit || 12), 1), 48);
  const offset = (page - 1) * limit;
  const minPrice = req.query.min_price ? Number(req.query.min_price) : null;
  const maxPrice = req.query.max_price ? Number(req.query.max_price) : null;
  const publisherId = req.query.publisher ? Number(req.query.publisher) : null;
  const minRating = req.query.min_rating ? Number(req.query.min_rating) : null;

  let orderClause;
  switch (sort) {
    case 'price_asc': orderClause = 'b.price ASC'; break;
    case 'price_desc': orderClause = 'b.price DESC'; break;
    case 'rating': orderClause = 'avg_rating DESC NULLS LAST'; break;
    case 'name_asc': orderClause = 'b.title ASC'; break;
    default: orderClause = 'b.created_at DESC, b.book_id DESC';
  }

  let whereExtra = '';
  const binds = { limit, offset };

  if (categoryId) {
    whereExtra += ' AND (b.category_id = :categoryId OR b.category_id IN (SELECT category_id FROM categories WHERE parent_id = :categoryId))';
    binds.categoryId = categoryId;
  }
  if (minPrice) { whereExtra += ' AND b.price >= :minPrice'; binds.minPrice = minPrice; }
  if (maxPrice) { whereExtra += ' AND b.price <= :maxPrice'; binds.maxPrice = maxPrice; }
  if (publisherId) { whereExtra += ' AND b.publisher_id = :publisherId'; binds.publisherId = publisherId; }

  let havingClause = '';
  if (minRating) {
    havingClause = ' HAVING NVL(ROUND(AVG(rv.rating), 1), 0) >= :minRating';
    binds.minRating = minRating;
  }

  try {
    const countBinds = {};
    let countWhere = '';
    if (categoryId) {
      countWhere += ' AND (b.category_id = :categoryId OR b.category_id IN (SELECT category_id FROM categories WHERE parent_id = :categoryId))';
      countBinds.categoryId = categoryId;
    }
    if (minPrice) { countWhere += ' AND b.price >= :minPrice'; countBinds.minPrice = minPrice; }
    if (maxPrice) { countWhere += ' AND b.price <= :maxPrice'; countBinds.maxPrice = maxPrice; }
    if (publisherId) { countWhere += ' AND b.publisher_id = :publisherId'; countBinds.publisherId = publisherId; }

    const [countResult] = await query(`SELECT COUNT(*) AS total FROM books b WHERE 1=1 ${countWhere}`, countBinds);

    const rows = await query(
      `SELECT * FROM (
        SELECT b.book_id, b.title, b.price, b.stock_quantity,
               bi.image_url,
               NVL(ROUND(AVG(rv.rating), 1), 0) AS avg_rating,
               COUNT(rv.review_id) AS review_count,
               MIN(CASE WHEN ba.role = 'AUTHOR' THEN au.author_name END) AS author_name,
               c.category_name, p.publisher_name
        FROM books b
        LEFT JOIN book_images bi ON bi.book_id = b.book_id AND bi.is_primary = 1
        LEFT JOIN reviews rv ON rv.book_id = b.book_id
        LEFT JOIN book_authors ba ON ba.book_id = b.book_id AND ba.role = 'AUTHOR'
        LEFT JOIN authors au ON au.author_id = ba.author_id
        LEFT JOIN categories c ON c.category_id = b.category_id
        LEFT JOIN publishers p ON p.publisher_id = b.publisher_id
        WHERE 1=1 ${whereExtra}
        GROUP BY b.book_id, b.title, b.price, b.stock_quantity, bi.image_url,
                 b.created_at, c.category_name, p.publisher_name
        ${havingClause}
        ORDER BY ${orderClause}
      )
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY`,
      binds
    );

    success(res, {
      rows,
      total: countResult ? countResult.TOTAL : 0,
      page,
      limit,
      totalPages: Math.ceil((countResult ? countResult.TOTAL : 0) / limit)
    });
  } catch (err) {
    error(res, err.message);
  }
});

router.get('/book/:id', async (req, res) => {
  const bookId = Number(req.params.id);
  try {
    const [book] = await query(`
      SELECT b.book_id, b.title, b.isbn, b.price, b.stock_quantity,
             b.description, b.publication_year, b.page_count,
             b.category_id, b.publisher_id, b.created_at,
             c.category_name, p.publisher_name
      FROM books b
      LEFT JOIN categories c ON c.category_id = b.category_id
      LEFT JOIN publishers p ON p.publisher_id = b.publisher_id
      WHERE b.book_id = :bookId
    `, { bookId });

    if (!book) return error(res, 'Sách không tồn tại.', 404);

    const [images, authors, reviews] = await Promise.all([
      query(`SELECT image_id, image_url, is_primary, sort_order FROM book_images WHERE book_id = :bookId ORDER BY is_primary DESC, sort_order ASC`, { bookId }),
      query(`SELECT a.author_id, a.author_name, a.biography, a.nationality, ba.role, ba.author_order FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id WHERE ba.book_id = :bookId ORDER BY ba.author_order NULLS LAST`, { bookId }),
      query(`SELECT r.review_id, r.rating, r.review_comment, r.review_date, c.full_name AS reviewer_name FROM reviews r JOIN orders o ON o.order_id = r.order_id JOIN customers c ON c.customer_id = o.customer_id WHERE r.book_id = :bookId ORDER BY r.review_date DESC FETCH FIRST 20 ROWS ONLY`, { bookId })
    ]);

    const avgRating = reviews.length > 0 ? (reviews.reduce((s, r) => s + r.RATING, 0) / reviews.length).toFixed(1) : 0;

    success(res, { ...book, images, authors, reviews, avgRating: Number(avgRating), reviewCount: reviews.length });
  } catch (err) {
    error(res, err.message);
  }
});

// ... I'll add the rest of the store APIs like search and cart here ...

router.get('/cart', async (req, res) => {
  const customerId = Number(req.query.customer_id);
  if (!customerId) return error(res, 'customer_id bắt buộc.', 400);

  try {
    const items = await query(`
      SELECT ci.cart_item_id, ci.quantity, ci.unit_price,
             b.book_id, b.title, b.price AS current_price, b.stock_quantity,
             bi.image_url
      FROM carts c
      JOIN cart_items ci ON ci.cart_id = c.cart_id
      JOIN books b ON b.book_id = ci.book_id
      LEFT JOIN book_images bi ON bi.book_id = b.book_id AND bi.is_primary = 1
      WHERE c.customer_id = :customerId AND c.status = 'ACTIVE'
      ORDER BY ci.created_at DESC
    `, { customerId });

    const subtotal = items.reduce((s, i) => s + (i.UNIT_PRICE * i.QUANTITY), 0);
    success(res, { items, subtotal, itemCount: items.length });
  } catch (err) {
    error(res, err.message);
  }
});

router.post('/cart/items', async (req, res) => {
  const { customerId, bookId, quantity } = req.body;
  if (!customerId || !bookId || !quantity) return error(res, 'customerId, bookId, quantity bắt buộc.', 400);

  try {
    const result = await withConnection(async (connection) => {
      // Check stock
      const bookResult = await connection.execute('SELECT price, stock_quantity FROM books WHERE book_id = :bookId', { bookId: Number(bookId) }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      const book = bookResult.rows[0];
      if (!book) throw new Error('Sách không tồn tại.');
      if (book.STOCK_QUANTITY < Number(quantity)) throw new Error('Không đủ hàng trong kho.');

      // Find/create cart
      let cartResult = await connection.execute(`SELECT cart_id FROM carts WHERE customer_id = :customerId AND status = 'ACTIVE'`, { customerId: Number(customerId) }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      let cartId;
      if (cartResult.rows.length === 0) {
        const createCart = await connection.execute(`INSERT INTO carts (cart_id, customer_id, created_at, status) VALUES (NULL, :customerId, SYSDATE, 'ACTIVE') RETURNING cart_id INTO :cartId`, { customerId: Number(customerId), cartId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } }, { autoCommit: false });
        cartId = createCart.outBinds.cartId[0];
      } else {
        cartId = cartResult.rows[0].CART_ID;
      }

      // Check if item exists in cart
      const existResult = await connection.execute('SELECT cart_item_id, quantity FROM cart_items WHERE cart_id = :cartId AND book_id = :bookId', { cartId, bookId: Number(bookId) }, { outFormat: oracledb.OUT_FORMAT_OBJECT });

      if (existResult.rows.length > 0) {
        const newQty = existResult.rows[0].QUANTITY + Number(quantity);
        await connection.execute(`UPDATE cart_items SET quantity = :qty, unit_price = :price, updated_at = SYSDATE WHERE cart_item_id = :itemId`, { qty: newQty, price: book.PRICE, itemId: existResult.rows[0].CART_ITEM_ID }, { autoCommit: false });
      } else {
        await connection.execute(`INSERT INTO cart_items (cart_item_id, cart_id, book_id, quantity, unit_price, created_at) VALUES (NULL, :cartId, :bookId, :qty, :price, SYSDATE)`, { cartId, bookId: Number(bookId), qty: Number(quantity), price: book.PRICE }, { autoCommit: false });
      }
      return { ok: true, message: 'Đã thêm vào giỏ hàng.' };
    });
    success(res, result);
  } catch (err) {
    error(res, err.message);
  }
});

module.exports = router;
