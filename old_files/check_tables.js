const { query, initPool, closePool } = require('../web-ui/src/db');

async function checkTables() {
  await initPool();
  const tablesToCheck = [
    'categories', 'carts', 'cart_items', 'books', 'book_images', 'book_authors',
    'customers', 'authors', 'publishers', 'coupons', 'orders', 'order_details',
    'order_status_history', 'reviews', 'inventory_transactions', 'orders_audit_log',
    'vw_order_sales_report', 'vw_customer_secure_profile', 'mv_daily_category_sales'
  ];

  console.log('Checking tables/views/MVs existence...');
  for (const t of tablesToCheck) {
    try {
      await query(`SELECT 1 FROM ${t} WHERE 1=0`);
      console.log(`[OK] ${t}`);
    } catch (err) {
      console.error(`[MISSING/ERROR] ${t}: ${err.message}`);
    }
  }
  await closePool();
}

checkTables();
