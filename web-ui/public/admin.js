/* ========== DigiBook Admin — Refactored Frontend Logic ========== */
(function (api, ui) {
  'use strict';

  // ========== STATE ==========
  const pageTitles = {
    dashboard: 'Dashboard',
    books: 'Quản lý Sách',
    orders: 'Quản lý Đơn hàng',
    customers: 'Quản lý Khách hàng',
    coupons: 'Mã giảm giá',
    tables: 'Xem bảng dữ liệu'
  };

  let currentPage = 'dashboard';
  let tableList = [];
  let selectedTable = null;

  // ========== NAVIGATION ==========
  function navigateTo(page) {
    if (!pageTitles[page]) return;
    currentPage = page;

    // Update sidebar UI
    document.querySelectorAll('.sidebar-link').forEach(link => {
      link.classList.toggle('active', link.dataset.page === page);
    });

    // Update sections visibility
    document.querySelectorAll('.page-section').forEach(section => {
      section.classList.toggle('active', section.id === `page-${page}`);
    });

    // Update header title
    const titleEl = document.getElementById('pageTitle');
    if (titleEl) titleEl.textContent = pageTitles[page];

    // Update URL hash
    window.location.hash = page;

    // Load page data
    loadPageData(page);

    // Initial icon refresh for static elements
    ui.refreshIcons();
  }

  function loadPageData(page) {
    switch (page) {
      case 'dashboard': loadDashboard(); break;
      case 'books': loadBooks(); break;
      case 'orders': loadOrders(); break;
      case 'customers': loadCustomers(); break;
      case 'coupons': loadCoupons(); break;
      case 'tables': loadTableList(); break;
    }
  }

  // ========== DASHBOARD ==========
  async function loadDashboard() {
    try {
      const data = await api.get('/api/summary');
      const cards = data.cards;

      const statCards = document.getElementById('statCards');
      if (statCards) {
        statCards.innerHTML = `
          <div class="stat-card blue">
            <div class="stat-card-header">
              <span class="stat-card-label">Tổng sách</span>
              <div class="stat-card-icon"><i data-lucide="book-open-check"></i></div>
            </div>
            <div class="stat-card-main">
              <div class="stat-card-value">${Number(cards.totalBooks).toLocaleString()}</div>
              <div class="stat-card-footer">
                <span class="stat-card-trend ${cards.newBooks > 0 ? 'up' : ''}">
                  <i data-lucide="${cards.newBooks > 0 ? 'trending-up' : 'minus'}" style="width:12px;height:12px"></i> 
                  ${cards.newBooks > 0 ? '+' : ''}${cards.newBooks}
                </span>
                <span class="stat-card-sub">mới trong tháng</span>
              </div>
            </div>
          </div>
          <div class="stat-card green">
            <div class="stat-card-header">
              <span class="stat-card-label">Đơn hàng</span>
              <div class="stat-card-icon"><i data-lucide="shopping-bag"></i></div>
            </div>
            <div class="stat-card-main">
              <div class="stat-card-value">${Number(cards.totalOrders).toLocaleString()}</div>
              <div class="stat-card-footer">
                <span class="stat-card-trend ${cards.newOrders > 0 ? 'up' : ''}">
                  <i data-lucide="${cards.newOrders > 0 ? 'trending-up' : 'minus'}" style="width:12px;height:12px"></i>
                  ${cards.newOrders > 0 ? '+' : ''}${cards.newOrders}
                </span>
                <span class="stat-card-sub">tháng này</span>
              </div>
            </div>
          </div>
          <div class="stat-card amber">
            <div class="stat-card-header">
              <span class="stat-card-label">Doanh thu</span>
              <div class="stat-card-icon"><i data-lucide="banknote"></i></div>
            </div>
            <div class="stat-card-main">
              <div class="stat-card-value">${ui.formatVND(cards.deliveredRevenue)}</div>
              <div class="stat-card-footer">
                <span class="stat-card-trend ${cards.newRevenue > 0 ? 'up' : ''}">
                  <i data-lucide="${cards.newRevenue > 0 ? 'trending-up' : 'minus'}" style="width:12px;height:12px"></i>
                  +${ui.formatVND(cards.newRevenue)}
                </span>
                <span class="stat-card-sub">doanh số mới</span>
              </div>
            </div>
          </div>
          <div class="stat-card purple">
            <div class="stat-card-header">
              <span class="stat-card-label">Khách hàng</span>
              <div class="stat-card-icon"><i data-lucide="users-round"></i></div>
            </div>
            <div class="stat-card-main">
              <div class="stat-card-value">${Number(cards.totalCustomers).toLocaleString()}</div>
              <div class="stat-card-footer">
                <span class="stat-card-trend ${cards.newCustomers > 0 ? 'up' : ''}">
                  <i data-lucide="${cards.newCustomers > 0 ? 'user-plus' : 'minus'}" style="width:12px;height:12px"></i>
                  +${cards.newCustomers}
                </span>
                <span class="stat-card-sub">đăng ký mới</span>
              </div>
            </div>
          </div>
          <div class="stat-card red">
            <div class="stat-card-header">
              <span class="stat-card-label">Đánh giá</span>
              <div class="stat-card-icon"><i data-lucide="star"></i></div>
            </div>
            <div class="stat-card-main">
              <div class="stat-card-value">${cards.totalReviews}</div>
              <div class="stat-card-footer">
                <span class="stat-card-trend up">
                  <i data-lucide="star" style="width:12px;height:12px"></i>
                  ${cards.avgRating}/5
                </span>
                <span class="stat-card-sub">trung bình</span>
              </div>
            </div>
          </div>
        `;
        ui.refreshIcons();
      }

      const tbody = document.getElementById('recentOrdersBody');
      if (tbody) {
        if (data.recentOrders && data.recentOrders.length > 0) {
          tbody.innerHTML = data.recentOrders.map(o => `
            <tr>
              <td class="table-cell-primary">#${o.ORDER_ID}</td>
              <td>${o.FULL_NAME || '—'}</td>
              <td class="fw-600">${ui.formatVND(o.TOTAL_AMOUNT)}</td>
              <td>${ui.statusBadge(o.STATUS)}</td>
              <td class="text-muted">${ui.formatDate(o.ORDER_DATE)}</td>
            </tr>
          `).join('');
        } else {
          tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Chưa có đơn hàng</td></tr>';
        }
      }
    } catch (err) {
      ui.showToast('Không thể tải dữ liệu dashboard', 'error');
    }
  }

  // ========== BOOKS ==========
  async function loadBooks() {
    const tbody = document.getElementById('booksTableBody');
    const container = tbody?.closest('.admin-card-body') || document.querySelector('#page-books .admin-card-body');
    if (!container) return;
    
    const limit = document.getElementById('bookLimitSelect')?.value || 25;
    ui.showLoading(container);

    try {
      const data = await api.getTable('books', limit);
      if (!data.rows || data.rows.length === 0) {
        ui.showEmpty(container, 'book-copy', 'Chưa có sách');
        return;
      }

      const html = `
        <div class="admin-table-wrap">
          <table class="admin-table">
            <thead>
              <tr>
                <th>ID</th><th>Tên sách</th><th>ISBN</th><th>Giá</th><th>Tồn kho</th><th>Danh mục</th><th>NXB</th><th>Hành động</th>
              </tr>
            </thead>
            <tbody id="booksTableBody">${data.rows.map(b => `
              <tr>
                <td class="table-cell-mono">${b.BOOK_ID}</td>
                <td class="table-cell-primary table-cell-truncate" title="${(b.TITLE || '').replace(/"/g, '&quot;')}">${b.TITLE || '—'}</td>
                <td class="table-cell-mono">${b.ISBN || '—'}</td>
                <td class="fw-600">${ui.formatVND(b.PRICE)}</td>
                <td>${Number(b.STOCK_QUANTITY || 0) <= 5 ? `<span class="badge badge-cancelled">${b.STOCK_QUANTITY}</span>` : b.STOCK_QUANTITY}</td>
                <td class="text-muted">${b.CATEGORY_ID || '—'}</td>
                <td class="text-muted">${b.PUBLISHER_ID || '—'}</td>
                <td>
                  <div class="flex gap-8">
                    <button class="btn btn-outline btn-sm btn-edit-book" data-id="${b.BOOK_ID}" data-title="${(b.TITLE || '').replace(/"/g, '&quot;')}" data-isbn="${b.ISBN || ''}" data-price="${b.PRICE}" data-stock="${b.STOCK_QUANTITY || 0}" data-year="${b.PUBLICATION_YEAR || ''}" data-pages="${b.PAGE_COUNT || ''}" data-cat="${b.CATEGORY_ID || ''}" data-pub="${b.PUBLISHER_ID || ''}" data-desc="${(b.DESCRIPTION || '').replace(/"/g, '&quot;')}"><i data-lucide="pencil" style="width: 14px; height: 14px;"></i></button>
                    <button class="btn btn-outline btn-sm btn-delete-book" data-id="${b.BOOK_ID}" data-title="${(b.TITLE || '').replace(/"/g, '&quot;')}"><i data-lucide="trash-2" style="width: 14px; height: 14px;"></i></button>
                  </div>
                </td>
              </tr>
            `).join('')}</tbody>
          </table>
        </div>
      `;
      container.innerHTML = html;
      ui.refreshIcons();
      bindBookActions();
    } catch (err) {
      ui.showEmpty(container, 'alert-circle', 'Lỗi tải danh sách sách');
    }
  }

  function bindBookActions() {
    document.querySelectorAll('.btn-edit-book').forEach(btn => {
      btn.onclick = () => openBookModal('edit', btn.dataset);
    });
    document.querySelectorAll('.btn-delete-book').forEach(btn => {
      btn.onclick = () => deleteBook(btn.dataset.id, btn.dataset.title);
    });
  }

  function openBookModal(mode, data = {}) {
    const modal = document.getElementById('bookModal');
    const title = document.getElementById('bookModalTitle');
    const form = document.getElementById('bookForm');
    if (!modal || !form) return;

    if (mode === 'edit') {
      title.textContent = 'Chỉnh sửa sách';
      document.getElementById('bookFormId').value = data.id || '';
      document.getElementById('bookFormTitle').value = data.title || '';
      document.getElementById('bookFormIsbn').value = data.isbn || '';
      document.getElementById('bookFormPrice').value = data.price || '';
      document.getElementById('bookFormStock').value = data.stock || '';
      document.getElementById('bookFormYear').value = data.year || '';
      document.getElementById('bookFormPages').value = data.pages || '';
      document.getElementById('bookFormCategory').value = data.cat || '';
      document.getElementById('bookFormPublisher').value = data.pub || '';
      document.getElementById('bookFormDesc').value = data.desc || '';
    } else {
      title.textContent = 'Thêm sách mới';
      form.reset();
      document.getElementById('bookFormId').value = '';
    }

    modal.classList.add('active');
  }

  async function saveBook() {
    const bookId = document.getElementById('bookFormId').value;
    const action = bookId ? 'UPDATE' : 'ADD';

    const body = {
      action,
      bookId: bookId ? Number(bookId) : null,
      title: document.getElementById('bookFormTitle').value.trim(),
      isbn: document.getElementById('bookFormIsbn').value.trim() || null,
      price: Number(document.getElementById('bookFormPrice').value) || null,
      stockQuantity: Number(document.getElementById('bookFormStock').value) || 0,
      publicationYear: Number(document.getElementById('bookFormYear').value) || null,
      pageCount: Number(document.getElementById('bookFormPages').value) || null,
      categoryId: Number(document.getElementById('bookFormCategory').value) || null,
      publisherId: Number(document.getElementById('bookFormPublisher').value) || null,
      description: document.getElementById('bookFormDesc').value.trim() || null
    };

    if (!body.title) return ui.showToast('Tên sách không được để trống', 'error');

    try {
      await api.post('/api/testing/procedures/manage-book', body);
      ui.showToast(action === 'ADD' ? 'Thêm sách thành công!' : 'Cập nhật sách thành công!', 'success');
      document.getElementById('bookModal').classList.remove('active');
      loadBooks();
    } catch (err) { /* Toast already handled by api client if generic, but api.js I wrote doesn't toast, it just throws */
       ui.showToast(err.message, 'error');
    }
  }

  async function deleteBook(bookId, title) {
    if (!confirm(`Xóa sách "${title}" (ID: ${bookId})?`)) return;
    try {
      await api.post('/api/testing/procedures/manage-book', { action: 'DELETE', bookId: Number(bookId) });
      ui.showToast('Đã xóa sách thành công!', 'success');
      loadBooks();
    } catch (err) {
      ui.showToast(err.message, 'error');
    }
  }

  // ========== ORDERS ==========
  async function loadOrders() {
    const container = document.querySelector('#page-orders .admin-card-body');
    if (!container) return;
    
    const limit = document.getElementById('orderLimitSelect')?.value || 25;
    ui.showLoading(container);

    try {
      const data = await api.getTable('orders', limit);
      if (!data.rows || data.rows.length === 0) {
        ui.showEmpty(container, 'shopping-cart', 'Chưa có đơn hàng');
        return;
      }

      const html = `
        <div class="admin-table-wrap">
          <table class="admin-table">
            <thead>
              <tr><th>Mã đơn</th><th>KH ID</th><th>Tổng tiền</th><th>Trạng thái</th><th>Thanh toán</th><th>PT thanh toán</th><th>Ngày đặt</th><th>Hành động</th></tr>
            </thead>
            <tbody>${data.rows.map(o => `
              <tr>
                <td class="table-cell-primary">#${o.ORDER_ID}</td>
                <td class="table-cell-mono">${o.CUSTOMER_ID}</td>
                <td class="fw-600">${ui.formatVND(o.TOTAL_AMOUNT)}</td>
                <td>${ui.statusBadge(o.STATUS)}</td>
                <td>${ui.statusBadge(o.PAYMENT_STATUS)}</td>
                <td class="text-muted">${o.PAYMENT_METHOD || '—'}</td>
                <td class="text-muted">${ui.formatDate(o.ORDER_DATE)}</td>
                <td>
                  <div class="flex gap-8">
                    <button class="btn btn-outline btn-sm btn-view-order" data-id="${o.ORDER_ID}"><i data-lucide="eye" style="width: 14px; height: 14px;"></i></button>
                    <button class="btn btn-outline btn-sm btn-update-order" data-id="${o.ORDER_ID}" data-status="${o.STATUS}" data-payment="${o.PAYMENT_STATUS}"><i data-lucide="pencil" style="width: 14px; height: 14px;"></i></button>
                  </div>
                </td>
              </tr>
            `).join('')}</tbody>
          </table>
        </div>
      `;
      container.innerHTML = html;
      ui.refreshIcons();
      bindOrderActions();
    } catch (err) {
      ui.showEmpty(container, 'alert-circle', 'Lỗi tải đơn hàng');
    }
  }

  function bindOrderActions() {
    document.querySelectorAll('.btn-view-order').forEach(btn => {
      btn.onclick = () => viewOrderDetail(btn.dataset.id);
    });
    document.querySelectorAll('.btn-update-order').forEach(btn => {
      btn.onclick = () => openOrderStatusModal(btn.dataset);
    });
  }

  async function viewOrderDetail(orderId) {
    const modal = document.getElementById('orderDetailModal');
    const body = document.getElementById('orderDetailBody');
    if (!modal || !body) return;
    
    document.getElementById('orderDetailTitle').textContent = `Chi tiết đơn hàng #${orderId}`;
    ui.showLoading(body);
    modal.classList.add('active');

    try {
       // Fetch everything needed
       const [orderData, detailData, historyData] = await Promise.all([
         api.getTable('orders', 100),
         api.getTable('order_details', 100),
         api.getTable('order_status_history', 100)
       ]);

       const order = orderData.rows.find(o => o.ORDER_ID === Number(orderId));
       if (!order) {
         body.innerHTML = '<div class="empty-state"><div class="empty-state-text">Không tìm thấy đơn hàng</div></div>';
         return;
       }

       const details = detailData.rows.filter(d => d.ORDER_ID === Number(orderId));
       const history = historyData.rows.filter(h => h.ORDER_ID === Number(orderId));

       body.innerHTML = `
         <div class="order-detail-grid">
           <div class="order-detail-item"><span class="order-detail-label">Mã đơn</span><span class="order-detail-value">#${order.ORDER_ID}</span></div>
           <div class="order-detail-item"><span class="order-detail-label">Khách hàng ID</span><span class="order-detail-value">${order.CUSTOMER_ID}</span></div>
           <div class="order-detail-item"><span class="order-detail-label">Trạng thái</span><span class="order-detail-value">${ui.statusBadge(order.STATUS)}</span></div>
           <div class="order-detail-item"><span class="order-detail-label">Thanh toán</span><span class="order-detail-value">${ui.statusBadge(order.PAYMENT_STATUS)} ${order.PAYMENT_METHOD || ''}</span></div>
           <div class="order-detail-item"><span class="order-detail-label">Tổng tiền</span><span class="order-detail-value fw-600 text-primary">${ui.formatVND(order.TOTAL_AMOUNT)}</span></div>
           <div class="order-detail-item"><span class="order-detail-label">Ngày đặt</span><span class="order-detail-value">${ui.formatDate(order.ORDER_DATE, true)}</span></div>
           <div class="order-detail-item" style="grid-column: span 2;"><span class="order-detail-label">Địa chỉ</span><span class="order-detail-value">${order.SHIPPING_ADDRESS || '—'}</span></div>
         </div>

         ${details.length > 0 ? `
           <h4 style="margin: 16px 0 8px; font-size: 0.9rem; color: var(--admin-text-secondary);">Chi tiết sản phẩm</h4>
           <table class="admin-table">
             <thead><tr><th>Sách ID</th><th>Số lượng</th><th>Đơn giá</th><th>Thành tiền</th></tr></thead>
             <tbody>${details.map(d => `<tr><td class="table-cell-mono">${d.BOOK_ID}</td><td>${d.QUANTITY}</td><td>${ui.formatVND(d.UNIT_PRICE)}</td><td class="fw-600">${ui.formatVND(d.SUBTOTAL)}</td></tr>`).join('')}</tbody>
           </table>
         ` : ''}

         ${history.length > 0 ? `
           <h4 style="margin: 16px 0 8px; font-size: 0.9rem; color: var(--admin-text-secondary);">Lịch sử trạng thái</h4>
           <div class="order-timeline">
             ${history.map(h => `<div class="timeline-item"><div class="timeline-status">${h.OLD_STATUS || 'N/A'} → ${h.NEW_STATUS}</div><div class="timeline-meta">${ui.formatDate(h.CHANGED_AT, true)} • ${h.CHANGED_SOURCE}${h.NOTE ? ` — ${h.NOTE}` : ''}</div></div>`).join('')}
           </div>
         ` : ''}
       `;
    } catch (err) {
      body.innerHTML = '<div class="empty-state"><div class="empty-state-text">Lỗi khi tải chi tiết đơn hàng</div></div>';
    }
  }

  function openOrderStatusModal(data) {
    const modal = document.getElementById('orderStatusModal');
    if (!modal) return;
    document.getElementById('orderStatusId').value = data.id;
    document.getElementById('orderStatusSelect').value = data.status || 'PENDING';
    document.getElementById('orderPaymentStatusSelect').value = data.payment || 'PENDING';
    document.getElementById('orderStatusNote').value = '';
    modal.classList.add('active');
  }

  async function saveOrderStatus() {
    const orderId = document.getElementById('orderStatusId').value;
    const body = {
      status: document.getElementById('orderStatusSelect').value,
      paymentStatus: document.getElementById('orderPaymentStatusSelect').value,
      note: document.getElementById('orderStatusNote').value.trim()
    };

    try {
      await api.put(`/api/admin/orders/${orderId}/status`, body);
      ui.showToast('Cập nhật trạng thái thành công!', 'success');
      document.getElementById('orderStatusModal').classList.remove('active');
      loadOrders();
    } catch (err) {
      ui.showToast(err.message, 'error');
    }
  }

  // ========== CUSTOMERS & COUPONS & TABLES (Similar patterns) ==========
  async function loadCustomers() {
     const container = document.querySelector('#page-customers .admin-card-body');
     const limit = document.getElementById('customerLimitSelect')?.value || 25;
     ui.showLoading(container);
     try {
       const data = await api.getTable('customers', limit);
       container.innerHTML = `<div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>ID</th><th>Họ tên</th><th>Email</th><th>Điện thoại</th><th>Trạng thái</th><th>Ngày tạo</th></tr></thead><tbody>${data.rows.map(c => `<tr><td class="table-cell-mono">${c.CUSTOMER_ID}</td><td class="table-cell-primary">${c.FULL_NAME || '—'}</td><td>${c.EMAIL || '—'}</td><td class="text-muted">${c.PHONE || '—'}</td><td>${ui.statusBadge(c.STATUS)}</td><td class="text-muted">${ui.formatDate(c.CREATED_AT)}</td></tr>`).join('')}</tbody></table></div>`;
       ui.refreshIcons();
     } catch (err) { ui.showEmpty(container, 'alert-circle', 'Lỗi tải khách hàng'); }
  }

  async function loadCoupons() {
     const container = document.querySelector('#page-coupons .admin-card-body');
     const limit = document.getElementById('couponLimitSelect')?.value || 25;
     ui.showLoading(container);
     try {
       const data = await api.getTable('coupons', limit);
       container.innerHTML = `<div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>ID</th><th>Mã code</th><th>Tên</th><th>Loại</th><th>Giá trị</th><th>Đã dùng</th><th>Ngày hết hạn</th><th>Trạng thái</th></tr></thead><tbody>${data.rows.map(c => {
         const isValid = new Date(c.END_AT) >= new Date();
         return `<tr><td class="table-cell-mono">${c.COUPON_ID}</td><td class="table-cell-mono">${c.COUPON_CODE}</td><td>${c.COUPON_NAME || '—'}</td><td><span class="badge ${c.DISCOUNT_TYPE === 'PERCENT' ? 'badge-confirmed' : 'badge-shipping'}">${c.DISCOUNT_TYPE}</span></td><td>${c.DISCOUNT_TYPE === 'PERCENT' ? c.DISCOUNT_VALUE + '%' : ui.formatVND(c.DISCOUNT_VALUE)}</td><td>${c.USED_COUNT || 0}${c.MAX_USES ? ` / ${c.MAX_USES}` : ''}</td><td>${ui.formatDate(c.END_AT)}</td><td>${c.IS_ACTIVE ? (isValid ? ui.statusBadge('ACTIVE') : '<span class="badge badge-cancelled">Hết hạn</span>') : ui.statusBadge('INACTIVE')}</td></tr>`;
       }).join('')}</tbody></table></div>`;
       ui.refreshIcons();
     } catch (err) { ui.showEmpty(container, 'alert-circle', 'Lỗi tải mã giảm giá'); }
  }

  async function loadTableList() {
    const tabList = document.getElementById('tableTabList');
    if (tableList.length === 0) {
      ui.showLoading(tabList);
      try { tableList = await api.get('/api/tables'); } catch (err) { 
        tabList.innerHTML = '<div class="text-muted p-12">Lỗi tải danh sách bảng</div>'; 
        return; 
      }
    }
    renderTableTabs(tableList);
  }

  function renderTableTabs(tables) {
    const tabList = document.getElementById('tableTabList');
    tabList.innerHTML = tables.map(t => `<button class="table-tab-item ${selectedTable === t.key ? 'active' : ''}" data-table="${t.key}"><span>${t.label}</span><span class="row-count">${t.totalRows}</span></button>`).join('');
    tabList.querySelectorAll('.table-tab-item').forEach(btn => {
      btn.onclick = () => { 
        selectedTable = btn.dataset.table; 
        renderTableTabs(tables); 
        loadTableData(selectedTable); 
      };
    });
  }

  async function loadTableData(tableName) {
    const container = document.getElementById('tableViewContainer');
    const limit = document.getElementById('tableLimitSelect')?.value || 25;
    const info = tableList.find(t => t.key === tableName);
    
    document.getElementById('tableViewTitle').textContent = info?.label || tableName;
    document.getElementById('tableViewSubtitle').textContent = `Bảng: ${tableName}`;
    ui.showLoading(container);

    try {
      const data = await api.getTable(tableName, limit);
      if (!data.rows || data.rows.length === 0) {
        ui.showEmpty(container, '📭', 'Bảng trống');
        return;
      }

      const cols = data.columns || Object.keys(data.rows[0]);
       container.innerHTML = `<table class="admin-table"><thead><tr>${cols.map(c => `<th>${c}</th>`).join('')}</tr></thead><tbody>${data.rows.map(row => `<tr>${cols.map(c => {
        let val = row[c];
        if (val === null || val === undefined) val = '—';
        else if (typeof val === 'string' && /^\d{4}-\d{2}-\d{2}/.test(val)) val = ui.formatDate(val, true);
        const strVal = String(val);
        return `<td class="${strVal.length > 30 ? 'table-cell-truncate' : ''}" title="${strVal.replace(/"/g, '&quot;')}">${strVal}</td>`;
      }).join('')}</tr>`).join('')}</tbody></table>`;
       ui.refreshIcons();
       document.getElementById('tableViewSubtitle').textContent = `Bảng: ${tableName} — Hiển thị ${data.rows.length} / ${data.totalRows} dòng`;
    } catch (err) { ui.showEmpty(container, 'alert-circle', `Lỗi tải bảng ${tableName}`); }
  }

  // ========== UTILS & EVENTS ==========
  function setupGlobalSearch() {
    const input = document.getElementById('globalSearch');
    let searchTimeout = null;
    input?.addEventListener('input', () => {
      clearTimeout(searchTimeout);
      const term = input.value.trim();
      if (!term) return;
      searchTimeout = setTimeout(async () => {
        try {
          const data = await api.get(`/api/search/books?q=${encodeURIComponent(term)}`);
          if (data.rows?.length > 0) {
            navigateTo('books');
            ui.showToast(`Tìm thấy ${data.rows.length} kết quả cho "${term}"`, 'info');
          } else {
             ui.showToast(`Không tìm thấy sách nào cho "${term}"`, 'info');
          }
        } catch (err) {}
      }, 500);
    });
  }

  async function checkDbStatus() {
    const dot = document.getElementById('dbStatusDot');
    const text = document.getElementById('dbStatusText');
    if (!dot || !text) return;
    try {
      await api.get('/api/health');
      dot.style.background = 'var(--admin-secondary)';
      text.textContent = 'Oracle kết nối OK';
    } catch (err) {
      dot.style.background = 'var(--admin-danger)';
      text.textContent = 'Mất kết nối';
    }
  }

  function bindEvents() {
    // Nav
    document.querySelectorAll('.sidebar-link').forEach(link => {
      link.onclick = () => navigateTo(link.dataset.page);
    });

    // Modals generic close
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
       overlay.onclick = (e) => { if (e.target === overlay) overlay.classList.remove('active'); };
       overlay.querySelector('.modal-close')?.addEventListener('click', () => overlay.classList.remove('active'));
    });

    // Forms
    document.getElementById('btnAddBook')?.addEventListener('click', () => openBookModal('add'));
    document.getElementById('bookModalCancel')?.addEventListener('click', () => document.getElementById('bookModal').classList.remove('active'));
    document.getElementById('bookModalSave')?.addEventListener('click', saveBook);
    document.getElementById('orderStatusCancel')?.addEventListener('click', () => document.getElementById('orderStatusModal').classList.remove('active'));
    document.getElementById('orderStatusSave')?.addEventListener('click', saveOrderStatus);

    // Reloads & Limits
    const mappings = [
      { btn: 'btnReloadBooks', select: 'bookLimitSelect', fn: loadBooks },
      { btn: 'btnReloadOrders', select: 'orderLimitSelect', fn: loadOrders },
      { btn: 'btnReloadCustomers', select: 'customerLimitSelect', fn: loadCustomers },
      { btn: 'btnReloadCoupons', select: 'couponLimitSelect', fn: loadCoupons },
      { btn: 'btnReloadTable', select: 'tableLimitSelect', fn: () => selectedTable && loadTableData(selectedTable) }
    ];

    mappings.forEach(m => {
      document.getElementById(m.btn)?.addEventListener('click', m.fn);
      document.getElementById(m.select)?.addEventListener('change', m.fn);
    });

    // Table Filter
    document.getElementById('tableFilterInput')?.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase();
      renderTableTabs(tableList.filter(t => t.key.toLowerCase().includes(term) || t.label.toLowerCase().includes(term)));
    });

    setupGlobalSearch();
    window.onhashchange = () => {
      const hash = window.location.hash.replace('#', '');
      if (hash && pageTitles[hash]) navigateTo(hash);
    };
  }

  function init() {
    bindEvents();
    checkDbStatus();
    setInterval(checkDbStatus, 30000);
    const hash = window.location.hash.replace('#', '');
    navigateTo(pageTitles[hash] ? hash : 'dashboard');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

})(window.DigiBookAPI, window.DigiBookUI);
