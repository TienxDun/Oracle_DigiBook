/* ========== DigiBook Store — Main SPA Router & Pages ========== */

const appEl = document.getElementById('app');
let currentPath = '';

// ========== SPA Router ==========
function navigate(path) {
  history.pushState(null, '', '/store' + (path === '/' ? '' : path));
  route();
}

window.addEventListener('popstate', route);

function route() {
  const fullPath = window.location.pathname.replace('/store', '') || '/';
  currentPath = fullPath;

  const r = fullPath;
  if (r === '/' || r === '') renderHomePage();
  else if (r.startsWith('/category/')) renderCategoryPage(r.split('/')[2]);
  else if (r === '/category') renderCategoryPage(null);
  else if (r.startsWith('/book/')) renderBookDetailPage(r.split('/')[2]);
  else if (r.startsWith('/search')) renderSearchPage();
  else if (r === '/cart') renderCartPage();
  else if (r === '/checkout') renderCheckoutPage();
  else if (r === '/auth') renderAuthPage();
  else if (r === '/account') renderAccountPage();
  else if (r.startsWith('/order-success/')) renderOrderSuccessPage(r.split('/')[2]);
  else renderHomePage();

  window.scrollTo(0, 0);
}

// ========== HOME PAGE ==========
async function renderHomePage() {
  appEl.innerHTML = renderHeader() + `
    <div class="hero-banner"><div class="hero-content">
      <div class="hero-text">
        <h1>Khám phá thế giới tri thức</h1>
        <p>Hàng ngàn đầu sách chất lượng từ văn học, công nghệ đến kinh tế. Giao hàng nhanh, nhiều ưu đãi hấp dẫn.</p>
        <button class="btn-primary" style="width:auto;padding:14px 32px;border-radius:50px;font-size:1rem" onclick="navigate('/category')">Khám phá ngay →</button>
      </div>
      <div class="hero-coupons"><div class="coupon-carousel" id="couponCarousel">${renderLoading()}</div></div>
    </div></div>
    <div class="category-bar"><div class="category-bar-inner" id="catBar">${renderLoading()}</div></div>
    <div class="container">
      <div class="section">
        <div class="section-header"><h2 class="section-title">Sách nổi bật</h2><a class="section-link" href="#" onclick="navigate('/category');return false">Xem tất cả →</a></div>
        <div id="featuredBooks">${renderBookGridSkeleton(4)}</div>
      </div>
      <div class="section">
        <div class="section-header"><h2 class="section-title">Sách mới nhất</h2><a class="section-link" href="#" onclick="navigate('/category');return false">Xem tất cả →</a></div>
        <div id="newBooks">${renderBookGridSkeleton(4)}</div>
      </div>
    </div>
    <div class="stats-bar"><div class="stats-bar-inner" id="statsBar">${renderLoading()}</div></div>
  ` + renderFooter();

  attachHeaderSearch();

  const [coupons, categories, featured, newBooks] = await Promise.all([
    api('/active-coupons').catch(() => ({ rows: [] })),
    api('/categories').catch(() => ({ rows: [] })),
    api('/featured-books').catch(() => ({ rows: [] })),
    api('/new-books').catch(() => ({ rows: [] }))
  ]);

  // Coupons
  const cc = document.getElementById('couponCarousel');
  if (cc) {
    cc.innerHTML = coupons.rows.length > 0 ? coupons.rows.map(c => `
      <div class="coupon-card">
        <div class="coupon-value">${c.DISCOUNT_TYPE === 'PERCENT' ? c.DISCOUNT_VALUE + '%' : formatPrice(c.DISCOUNT_VALUE)}</div>
        <div class="coupon-name">${c.COUPON_NAME}</div>
        <div class="coupon-code">${c.COUPON_CODE}</div>
      </div>
    `).join('') : '<div class="coupon-card"><div class="coupon-name">Chưa có ưu đãi</div></div>';
  }

  // Categories
  const cb = document.getElementById('catBar');
  if (cb) {
    const cats = categories.rows.filter(c => c.PARENT_ID != null);
    cb.innerHTML = `<button class="cat-chip active" onclick="navigate('/category')">Tất cả</button>` +
      cats.map(c => `<button class="cat-chip" onclick="navigate('/category/${c.CATEGORY_ID}')">${c.CATEGORY_NAME}</button>`).join('');
  }

  // Books
  const fb = document.getElementById('featuredBooks');
  if (fb) fb.innerHTML = `<div class="book-grid">${featured.rows.map(renderBookCard).join('')}</div>`;

  const nb = document.getElementById('newBooks');
  if (nb) nb.innerHTML = `<div class="book-grid">${newBooks.rows.map(renderBookCard).join('')}</div>`;

  // Stats
  const sb = document.getElementById('statsBar');
  if (sb) {
    try {
      const summary = await fetch('/api/summary').then(r => r.json());
      sb.innerHTML = `
        <div><div class="stat-item-value">${summary.cards.totalBooks}+</div><div class="stat-item-label">Đầu sách</div></div>
        <div><div class="stat-item-value">${summary.cards.totalCustomers}</div><div class="stat-item-label">Khách hàng</div></div>
        <div><div class="stat-item-value">${summary.cards.totalOrders}</div><div class="stat-item-label">Đơn hàng</div></div>
        <div><div class="stat-item-value">${summary.cards.avgRating}</div><div class="stat-item-label">Đánh giá TB</div></div>
      `;
    } catch (e) { sb.innerHTML = ''; }
  }
}

// ========== CATEGORY / BROWSE PAGE ==========
let browseState = { page: 1, sort: 'newest', category: null };

async function renderCategoryPage(catId) {
  browseState.category = catId;
  browseState.page = 1;

  appEl.innerHTML = renderHeader() + `
    <div class="container">
      <div class="breadcrumb"><a href="#" onclick="navigate('/');return false">Trang chủ</a> <span>›</span> Danh mục</div>
      <div class="browse-layout">
        <aside class="filter-sidebar" id="filterSidebar">${renderLoading()}</aside>
        <div>
          <div class="browse-toolbar">
            <span class="result-count" id="resultCount">Đang tải...</span>
            <select id="sortSelect" onchange="browseState.sort=this.value;browseState.page=1;loadBooks()">
              <option value="newest">Mới nhất</option>
              <option value="price_asc">Giá tăng dần</option>
              <option value="price_desc">Giá giảm dần</option>
              <option value="rating">Đánh giá cao</option>
              <option value="name_asc">Tên A-Z</option>
            </select>
          </div>
          <div id="bookList">${renderBookGridSkeleton(8)}</div>
          <div id="pagArea"></div>
        </div>
      </div>
    </div>
  ` + renderFooter();

  attachHeaderSearch();

  // Load sidebar
  const [cats, pubs] = await Promise.all([
    api('/categories').catch(() => ({ rows: [] })),
    api('/publishers').catch(() => ({ rows: [] }))
  ]);

  const fs = document.getElementById('filterSidebar');
  if (fs) {
    const subCats = cats.rows.filter(c => c.PARENT_ID != null);
    fs.innerHTML = `
      <div class="filter-section"><h4>Danh mục</h4>
        <label class="filter-option"><input type="radio" name="cat" value="" ${!catId ? 'checked' : ''} onchange="browseState.category=null;browseState.page=1;loadBooks()"> Tất cả</label>
        ${subCats.map(c => `<label class="filter-option"><input type="radio" name="cat" value="${c.CATEGORY_ID}" ${String(catId) === String(c.CATEGORY_ID) ? 'checked' : ''} onchange="browseState.category=${c.CATEGORY_ID};browseState.page=1;loadBooks()"> ${c.CATEGORY_NAME}</label>`).join('')}
      </div>
      <div class="filter-section"><h4>Nhà xuất bản</h4>
        ${pubs.rows.map(p => `<label class="filter-option"><input type="checkbox" value="${p.PUBLISHER_ID}" onchange="loadBooks()"> ${p.PUBLISHER_NAME}</label>`).join('')}
      </div>
    `;
  }

  loadBooks();
}

async function loadBooks() {
  const bl = document.getElementById('bookList');
  if (bl) bl.innerHTML = renderBookGridSkeleton(8);

  let url = `/books?page=${browseState.page}&sort=${browseState.sort}&limit=12`;
  if (browseState.category) url += `&category=${browseState.category}`;

  try {
    const data = await api(url);
    const bl = document.getElementById('bookList');
    const rc = document.getElementById('resultCount');
    const pa = document.getElementById('pagArea');

    if (bl) {
      bl.innerHTML = data.rows.length > 0
        ? `<div class="book-grid">${data.rows.map(renderBookCard).join('')}</div>`
        : `<div class="empty-state"><h3>Không tìm thấy sách</h3><p>Thử thay đổi bộ lọc hoặc danh mục khác.</p></div>`;
    }
    if (rc) rc.textContent = `Hiển thị ${data.rows.length} / ${data.total} sách`;
    if (pa) pa.innerHTML = renderPagination(data.page, data.totalPages, 'goPage');
  } catch (e) {
    if (bl) bl.innerHTML = `<div class="empty-state"><h3>Lỗi tải dữ liệu</h3><p>${e.message}</p></div>`;
  }
}

function goPage(p) {
  browseState.page = p;
  loadBooks();
  window.scrollTo(0, 200);
}

// ========== BOOK DETAIL PAGE ==========
async function renderBookDetailPage(bookId) {
  appEl.innerHTML = renderHeader() + `<div class="container"><div class="book-detail" id="bookDetail">${renderLoading()}</div></div>` + renderFooter();
  attachHeaderSearch();

  try {
    const book = await api(`/book/${bookId}`);
    const related = await api(`/book/${bookId}/related`).catch(() => ({ rows: [] }));

    const stockClass = book.STOCK_QUANTITY <= 0 ? 'out-stock' : book.STOCK_QUANTITY <= 10 ? 'low-stock' : 'in-stock';
    const stockIcon = book.STOCK_QUANTITY <= 0 ? '❌' : book.STOCK_QUANTITY <= 10 ? '⚠️' : '✅';
    const stockText = book.STOCK_QUANTITY <= 0 ? 'Hết hàng' : `Còn ${book.STOCK_QUANTITY} sản phẩm`;

    const mainImg = book.images.find(i => i.IS_PRIMARY === 1) || book.images[0];

    document.getElementById('bookDetail').innerHTML = `
      <div class="breadcrumb">
        <a href="#" onclick="navigate('/');return false">Trang chủ</a> <span>›</span>
        <a href="#" onclick="navigate('/category/${book.CATEGORY_ID}');return false">${book.CATEGORY_NAME || 'Danh mục'}</a> <span>›</span>
        ${book.TITLE}
      </div>
      <div class="detail-top">
        <div class="detail-gallery">
          <div class="detail-main-img" id="mainImgWrap">
            ${mainImg ? `<img src="${mainImg.IMAGE_URL}" alt="${book.TITLE}" id="mainImg" onerror="this.style.display='none'" />` : '<span class="book-placeholder" style="font-size:5rem">Sách</span>'}
          </div>
          ${book.images.length > 1 ? `<div class="detail-thumbs">${book.images.map((im, i) => `
            <div class="detail-thumb ${i === 0 ? 'active' : ''}" onclick="document.getElementById('mainImg').src='${im.IMAGE_URL}'; document.querySelectorAll('.detail-thumb').forEach(t=>t.classList.remove('active')); this.classList.add('active')">
              <img src="${im.IMAGE_URL}" alt="thumb" onerror="this.parentElement.style.display='none'" />
            </div>
          `).join('')}</div>` : ''}
        </div>
        <div class="detail-info">
          <h1>${book.TITLE}</h1>
          <div class="detail-authors">
            ${book.authors.map(a => `<span class="author-tag">${a.AUTHOR_NAME} <span class="role">${a.ROLE === 'AUTHOR' ? 'Tác giả' : a.ROLE === 'TRANSLATOR' ? 'Dịch giả' : 'Biên tập'}</span></span>`).join('')}
          </div>
          <div class="detail-meta">
            <span>${book.PUBLISHER_NAME || 'N/A'}</span>
            <span>${book.CATEGORY_NAME || 'N/A'}</span>
            ${book.PUBLICATION_YEAR ? `<span>Năm: ${book.PUBLICATION_YEAR}</span>` : ''}
            ${book.PAGE_COUNT ? `<span>${book.PAGE_COUNT} trang</span>` : ''}
            ${book.ISBN ? `<span>ISBN: ${book.ISBN}</span>` : ''}
          </div>
          <div class="detail-rating">
            <span class="stars">${renderStars(book.avgRating)}</span>
            <strong>${book.avgRating.toFixed(1)}</strong>/5
            <span class="count">(${book.reviewCount} đánh giá)</span>
          </div>
          <div class="detail-price">${formatPrice(book.PRICE)}</div>
          <div class="detail-stock ${stockClass}">${stockIcon} ${stockText}</div>
          ${book.STOCK_QUANTITY > 0 ? `
          <div class="detail-actions">
            <div class="qty-control">
              <button onclick="let v=document.getElementById('detailQty');v.value=Math.max(1,Number(v.value)-1)">−</button>
              <input type="number" id="detailQty" value="1" min="1" max="${book.STOCK_QUANTITY}" />
              <button onclick="let v=document.getElementById('detailQty');v.value=Math.min(${book.STOCK_QUANTITY},Number(v.value)+1)">+</button>
            </div>
            <button class="btn-add-cart" style="opacity:1;transform:none" onclick="addToCart(${book.BOOK_ID}, Number(document.getElementById('detailQty').value))">Thêm vào giỏ hàng</button>
          </div>` : ''}
        </div>
      </div>

      <div class="detail-tabs">
        <div class="tab-headers">
          <button class="tab-header active" onclick="switchTab(this, 'tabDesc')">Mô tả</button>
          <button class="tab-header" onclick="switchTab(this, 'tabInfo')">Thông tin</button>
          <button class="tab-header" onclick="switchTab(this, 'tabReview')">Đánh giá (${book.reviewCount})</button>
        </div>
        <div class="tab-content active" id="tabDesc">
          <div class="tab-description">${book.DESCRIPTION || 'Chưa có mô tả cho sản phẩm này.'}</div>
        </div>
        <div class="tab-content" id="tabInfo">
          <table class="info-table">
            <tr><td>ISBN</td><td>${book.ISBN || 'N/A'}</td></tr>
            <tr><td>Năm xuất bản</td><td>${book.PUBLICATION_YEAR || 'N/A'}</td></tr>
            <tr><td>Số trang</td><td>${book.PAGE_COUNT || 'N/A'}</td></tr>
            <tr><td>Nhà xuất bản</td><td>${book.PUBLISHER_NAME || 'N/A'}</td></tr>
            <tr><td>Danh mục</td><td>${book.CATEGORY_NAME || 'N/A'}</td></tr>
            ${book.authors.map(a => `<tr><td>${a.ROLE === 'AUTHOR' ? 'Tác giả' : a.ROLE === 'TRANSLATOR' ? 'Dịch giả' : 'Biên tập'}</td><td>${a.AUTHOR_NAME}</td></tr>`).join('')}
          </table>
        </div>
        <div class="tab-content" id="tabReview">
          ${book.reviewCount > 0 ? `
            <div class="review-summary">
              <div class="review-big-score">${book.avgRating.toFixed(1)}</div>
              <div><div style="color:var(--star);font-size:1.2rem">${renderStars(book.avgRating)}</div><div style="color:var(--text-muted);font-size:0.85rem">${book.reviewCount} đánh giá</div></div>
            </div>
            ${book.reviews.map(r => `
              <div class="review-item">
                <div class="review-header">
                  <div><span class="review-stars">${renderStars(r.RATING)}</span> <span class="review-name">${r.REVIEWER_NAME}</span></div>
                  <span class="review-date">${formatDate(r.REVIEW_DATE)}</span>
                </div>
                <div class="review-comment">${r.REVIEW_COMMENT || ''}</div>
              </div>
            `).join('')}
          ` : '<div class="empty-state"><h3>Chưa có đánh giá</h3><p>Hãy là người đầu tiên đánh giá sản phẩm này.</p></div>'}
        </div>
      </div>

      ${related.rows.length > 0 ? `
        <div class="section">
          <div class="section-header"><h2 class="section-title">Sách liên quan</h2></div>
          <div class="book-grid">${related.rows.map(renderBookCard).join('')}</div>
        </div>
      ` : ''}
    `;
  } catch (e) {
    document.getElementById('bookDetail').innerHTML = `<div class="empty-state"><h3>Không tìm thấy sách</h3><p>${e.message}</p></div>`;
  }
}

function switchTab(btn, tabId) {
  document.querySelectorAll('.tab-header').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById(tabId).classList.add('active');
}

// ========== SEARCH PAGE ==========
async function renderSearchPage() {
  const params = new URLSearchParams(window.location.search);
  const q = params.get('q') || '';

  appEl.innerHTML = renderHeader() + `
    <div class="container">
      <div class="breadcrumb"><a href="#" onclick="navigate('/');return false">Trang chủ</a> <span>›</span> Tìm kiếm: "${q}"</div>
      <div class="section">
        <div class="section-header"><h2 class="section-title">Kết quả tìm kiếm</h2></div>
        <div id="searchResultsPage">${renderBookGridSkeleton(8)}</div>
      </div>
    </div>
  ` + renderFooter();

  attachHeaderSearch();
  document.getElementById('headerSearchInput').value = q;

  if (q) {
    try {
      const data = await api(`/search?q=${encodeURIComponent(q)}`);
      document.getElementById('searchResultsPage').innerHTML = data.rows.length > 0
        ? `<p style="margin-bottom:16px;color:var(--text-muted)">Tìm thấy ${data.rows.length} kết quả</p><div class="book-grid">${data.rows.map(renderBookCard).join('')}</div>`
        : `<div class="empty-state"><h3>Không tìm thấy kết quả</h3><p>Thử tìm kiếm với từ khóa khác.</p></div>`;
    } catch (e) {
      document.getElementById('searchResultsPage').innerHTML = `<div class="empty-state"><h3>Lỗi</h3><p>${e.message}</p></div>`;
    }
  }
}

// ========== CART PAGE ==========
async function renderCartPage() {
  const user = getUser();
  if (!user) { navigate('/auth'); return; }

  appEl.innerHTML = renderHeader() + `
    <div class="container cart-page">
      <div class="breadcrumb"><a href="#" onclick="navigate('/');return false">Trang chủ</a> <span>›</span> Giỏ hàng</div>
      <h2 style="font-family:var(--font-heading);margin-bottom:24px">Giỏ hàng của bạn</h2>
      <div id="cartContent">${renderLoading()}</div>
    </div>
  ` + renderFooter();

  attachHeaderSearch();
  await loadCart();
}

async function loadCart() {
  const user = getUser();
  if (!user) return;

  try {
    const data = await api(`/cart?customer_id=${user.CUSTOMER_ID}`);
    setCartCount(data.items.length);
    const cc = document.getElementById('cartContent');
    if (!cc) return;

    if (data.items.length === 0) {
      cc.innerHTML = `<div class="empty-state"><h3>Giỏ hàng trống</h3><p>Hãy thêm sách yêu thích vào giỏ hàng.</p><br><button class="btn-outline" onclick="navigate('/category')">Mua sắm ngay →</button></div>`;
      return;
    }

    const shipping = 30000;
    cc.innerHTML = `
      <div class="cart-layout">
        <div class="cart-items">
          ${data.items.map(i => `
            <div class="cart-item">
              <div class="cart-item-img">${i.IMAGE_URL ? `<img src="${i.IMAGE_URL}" alt="${i.TITLE}" onerror="this.style.display='none'" />` : ''}</div>
              <div class="cart-item-info">
                <div class="cart-item-title" onclick="navigate('/book/${i.BOOK_ID}')">${i.TITLE}</div>
                <div class="cart-item-price">${formatPrice(i.UNIT_PRICE)}</div>
                <div class="cart-item-actions">
                  <div class="qty-control">
                    <button onclick="updateCartItem(${i.CART_ITEM_ID}, ${i.QUANTITY - 1})">−</button>
                    <input type="number" value="${i.QUANTITY}" readonly />
                    <button onclick="updateCartItem(${i.CART_ITEM_ID}, ${i.QUANTITY + 1})">+</button>
                  </div>
                  <span style="font-weight:600;color:var(--primary)">${formatPrice(i.UNIT_PRICE * i.QUANTITY)}</span>
                  <button class="cart-remove" onclick="removeCartItem(${i.CART_ITEM_ID})">Xóa</button>
                </div>
              </div>
            </div>
          `).join('')}
        </div>
        <div class="cart-summary">
          <h3>Tóm tắt đơn hàng</h3>
          <div class="summary-row"><span>Tạm tính (${data.itemCount} sản phẩm)</span><span>${formatPrice(data.subtotal)}</span></div>
          <div class="summary-row"><span>Phí vận chuyển</span><span>${formatPrice(shipping)}</span></div>
          <div class="coupon-form">
            <input type="text" placeholder="Mã giảm giá" id="couponInput" />
            <button onclick="applyCoupon()">Áp dụng</button>
          </div>
          <div id="couponResult"></div>
          <div class="summary-row total"><span>Tổng cộng</span><span id="cartTotal">${formatPrice(data.subtotal + shipping)}</span></div>
          <button class="btn-checkout" onclick="navigate('/checkout')">Tiến hành thanh toán →</button>
        </div>
      </div>
    `;
  } catch (e) {
    const cc = document.getElementById('cartContent');
    if (cc) cc.innerHTML = `<div class="empty-state"><h3>Lỗi</h3><p>${e.message}</p></div>`;
  }
}

async function updateCartItem(itemId, qty) {
  if (qty < 1) { removeCartItem(itemId); return; }
  try {
    await api(`/cart/items/${itemId}`, { method: 'PUT', body: { quantity: qty } });
    await loadCart();
  } catch (e) { showToast(e.message, 'error'); }
}

async function removeCartItem(itemId) {
  try {
    await api(`/cart/items/${itemId}`, { method: 'DELETE' });
    showToast('Đã xóa sản phẩm khỏi giỏ');
    await loadCart();
  } catch (e) { showToast(e.message, 'error'); }
}

async function applyCoupon() {
  const code = document.getElementById('couponInput').value.trim();
  if (!code) return;
  const user = getUser();
  try {
    const cart = await api(`/cart?customer_id=${user.CUSTOMER_ID}`);
    const result = await api('/cart/apply-coupon', { method: 'POST', body: { couponCode: code, orderAmount: cart.subtotal } });
    const cr = document.getElementById('couponResult');
    if (result.ok) {
      cr.innerHTML = `<div style="color:var(--success);font-size:0.85rem">Giảm ${formatPrice(result.discountAmount)}</div>`;
      document.getElementById('cartTotal').textContent = formatPrice(cart.subtotal + 30000 - result.discountAmount);
      localStorage.setItem('digibook_coupon', JSON.stringify({ code, discount: result.discountAmount }));
    } else {
      cr.innerHTML = `<div style="color:var(--danger);font-size:0.85rem">${result.messageCode}</div>`;
    }
  } catch (e) { showToast(e.message, 'error'); }
}

// ========== CHECKOUT PAGE ==========
async function renderCheckoutPage() {
  const user = getUser();
  if (!user) { navigate('/auth'); return; }

  appEl.innerHTML = renderHeader() + `
    <div class="container checkout-page">
      <div class="stepper">
        <div class="step done"><span class="step-dot">✓</span> Giỏ hàng</div>
        <div class="step-line"></div>
        <div class="step active"><span class="step-dot">2</span> Thông tin</div>
        <div class="step-line"></div>
        <div class="step"><span class="step-dot">3</span> Hoàn tất</div>
      </div>
      <div class="cart-layout">
        <div>
          <h3 style="font-family:var(--font-heading);margin-bottom:20px">Thông tin giao hàng</h3>
          <div class="form-group"><label>Họ tên</label><input id="coName" value="${user.FULL_NAME || ''}" /></div>
          <div class="form-group"><label>Email</label><input id="coEmail" value="${user.EMAIL || ''}" readonly style="background:var(--surface-alt)" /></div>
          <div class="form-group"><label>Số điện thoại</label><input id="coPhone" value="${user.PHONE || ''}" /></div>
          <div class="form-group"><label>Địa chỉ giao hàng</label><textarea id="coAddress" rows="3">${user.ADDRESS || ''}</textarea></div>
          <div class="form-group"><label>Phương thức thanh toán</label>
            <select id="coPayment">
              <option value="COD">Thanh toán khi nhận hàng (COD)</option>
              <option value="BANK_TRANSFER">Chuyển khoản ngân hàng</option>
              <option value="E_WALLET">Ví điện tử</option>
              <option value="CREDIT_CARD">Thẻ tín dụng</option>
            </select>
          </div>
        </div>
        <div class="cart-summary" id="checkoutSummary">${renderLoading()}</div>
      </div>
    </div>
  ` + renderFooter();

  attachHeaderSearch();

  // Load cart summary
  try {
    const cart = await api(`/cart?customer_id=${user.CUSTOMER_ID}`);
    const coupon = JSON.parse(localStorage.getItem('digibook_coupon') || 'null');
    const discount = coupon ? coupon.discount : 0;
    const total = cart.subtotal + 30000 - discount;

    document.getElementById('checkoutSummary').innerHTML = `
      <h3>Đơn hàng (${cart.itemCount} sản phẩm)</h3>
      ${cart.items.map(i => `<div class="summary-row"><span>${i.TITLE} ×${i.QUANTITY}</span><span>${formatPrice(i.UNIT_PRICE * i.QUANTITY)}</span></div>`).join('')}
      <hr style="border:none;border-top:1px solid var(--border-light);margin:12px 0">
      <div class="summary-row"><span>Tạm tính</span><span>${formatPrice(cart.subtotal)}</span></div>
      <div class="summary-row"><span>Phí ship</span><span>${formatPrice(30000)}</span></div>
      ${discount > 0 ? `<div class="summary-row" style="color:var(--success)"><span>Giảm giá (${coupon.code})</span><span>-${formatPrice(discount)}</span></div>` : ''}
      <div class="summary-row total"><span>Tổng cộng</span><span>${formatPrice(total)}</span></div>
      <button class="btn-checkout" onclick="placeOrder()">Đặt hàng</button>
      <button class="btn-outline" style="width:100%;margin-top:8px" onclick="navigate('/cart')">Quay lại giỏ</button>
    `;
  } catch (e) {
    document.getElementById('checkoutSummary').innerHTML = `<p style="color:var(--danger)">${e.message}</p>`;
  }
}

async function placeOrder() {
  const user = getUser();
  const address = document.getElementById('coAddress').value.trim();
  const payment = document.getElementById('coPayment').value;
  const coupon = JSON.parse(localStorage.getItem('digibook_coupon') || 'null');

  if (!address || address.length < 10) { showToast('Vui lòng nhập địa chỉ giao hàng (ít nhất 10 ký tự)', 'error'); return; }

  try {
    const result = await api('/orders', {
      method: 'POST',
      body: { customerId: user.CUSTOMER_ID, shippingAddress: address, paymentMethod: payment, couponCode: coupon?.code || null }
    });

    if (result.ok) {
      localStorage.removeItem('digibook_coupon');
      setCartCount(0);
      navigate(`/order-success/${result.orderId}`);
    }
  } catch (e) { showToast(e.message, 'error'); }
}

// ========== ORDER SUCCESS ==========
function renderOrderSuccessPage(orderId) {
  appEl.innerHTML = renderHeader() + `
    <div class="container success-page">
      <div class="success-icon">✓</div>
      <h2>Đặt hàng thành công!</h2>
      <p>Mã đơn hàng: <strong>#${orderId}</strong>. Cảm ơn bạn đã mua sắm tại DigiBook!</p>
      <div style="display:flex;gap:12px;justify-content:center">
        <button class="btn-outline" onclick="navigate('/account')">Xem đơn hàng</button>
        <button class="btn-primary" style="width:auto;padding:12px 28px" onclick="navigate('/')">Về trang chủ</button>
      </div>
    </div>
  ` + renderFooter();
  attachHeaderSearch();
}

// ========== AUTH PAGE ==========
function renderAuthPage() {
  if (getUser()) { navigate('/account'); return; }

  appEl.innerHTML = renderHeader() + `
    <div class="auth-page">
      <div class="auth-card">
        <h2>Chào mừng đến DigiBook</h2>
        <p class="subtitle">Đăng nhập hoặc tạo tài khoản để mua sách</p>
        <div class="auth-tabs">
          <button class="auth-tab active" onclick="switchAuthTab('login')">Đăng nhập</button>
          <button class="auth-tab" onclick="switchAuthTab('register')">Đăng ký</button>
        </div>
        <div id="authLogin">
          <div class="form-group"><label>Email</label><input type="email" id="loginEmail" placeholder="email@example.com" /></div>
          <div class="form-group"><label>Mật khẩu</label><input type="password" id="loginPassword" placeholder="Nhập mật khẩu" /></div>
          <button class="btn-primary" onclick="handleLogin()">Đăng nhập →</button>
        </div>
        <div id="authRegister" style="display:none">
          <div class="form-group"><label>Họ tên</label><input id="regName" placeholder="Nguyễn Văn A" /></div>
          <div class="form-group"><label>Email</label><input type="email" id="regEmail" placeholder="email@example.com" /></div>
          <div class="form-group"><label>Mật khẩu</label><input type="password" id="regPassword" placeholder="Ít nhất 6 ký tự" /></div>
          <div class="form-group"><label>Số điện thoại</label><input id="regPhone" placeholder="0901234567" /></div>
          <div class="form-group"><label>Địa chỉ</label><input id="regAddress" placeholder="Số nhà, đường, quận, TP" /></div>
          <button class="btn-primary" onclick="handleRegister()">Tạo tài khoản →</button>
        </div>
        <div id="authError" style="color:var(--danger);font-size:0.85rem;margin-top:12px;text-align:center"></div>
      </div>
    </div>
  ` + renderFooter();
  attachHeaderSearch();
}

function switchAuthTab(tab) {
  document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
  if (tab === 'login') {
    document.querySelectorAll('.auth-tab')[0].classList.add('active');
    document.getElementById('authLogin').style.display = 'block';
    document.getElementById('authRegister').style.display = 'none';
  } else {
    document.querySelectorAll('.auth-tab')[1].classList.add('active');
    document.getElementById('authLogin').style.display = 'none';
    document.getElementById('authRegister').style.display = 'block';
  }
  document.getElementById('authError').textContent = '';
}

async function handleLogin() {
  const email = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  if (!email || !password) { document.getElementById('authError').textContent = 'Vui lòng nhập đầy đủ thông tin.'; return; }

  try {
    const data = await api('/auth/login', { method: 'POST', body: { email, password } });
    setUser(data.customer);
    showToast(`Xin chào, ${data.customer.FULL_NAME}!`);
    // Load cart count
    try {
      const cart = await api(`/cart?customer_id=${data.customer.CUSTOMER_ID}`);
      setCartCount(cart.items.length);
    } catch {}
    navigate('/');
  } catch (e) {
    document.getElementById('authError').textContent = e.message;
  }
}

async function handleRegister() {
  const fullName = document.getElementById('regName').value.trim();
  const email = document.getElementById('regEmail').value.trim();
  const password = document.getElementById('regPassword').value;
  const phone = document.getElementById('regPhone').value.trim();
  const address = document.getElementById('regAddress').value.trim();

  if (!fullName || !email || !password) { document.getElementById('authError').textContent = 'Vui lòng nhập họ tên, email và mật khẩu.'; return; }

  try {
    await api('/auth/register', { method: 'POST', body: { fullName, email, password, phone, address } });
    showToast('Đăng ký thành công! Đang đăng nhập...');
    const loginData = await api('/auth/login', { method: 'POST', body: { email, password } });
    setUser(loginData.customer);
    navigate('/');
  } catch (e) {
    document.getElementById('authError').textContent = e.message;
  }
}

// ========== ACCOUNT PAGE ==========
let accountTab = 'profile';

async function renderAccountPage() {
  const user = getUser();
  if (!user) { navigate('/auth'); return; }

  appEl.innerHTML = renderHeader() + `
    <div class="container account-page">
      <div class="breadcrumb"><a href="#" onclick="navigate('/');return false">Trang chủ</a> <span>›</span> Tài khoản</div>
      <div class="account-layout">
        <nav class="account-sidebar">
          <button class="account-nav-item ${accountTab === 'profile' ? 'active' : ''}" onclick="accountTab='profile';loadAccountTab()">Hồ sơ</button>
          <button class="account-nav-item ${accountTab === 'orders' ? 'active' : ''}" onclick="accountTab='orders';loadAccountTab()">Đơn hàng</button>
          <button class="account-nav-item ${accountTab === 'reviews' ? 'active' : ''}" onclick="accountTab='reviews';loadAccountTab()">Đánh giá</button>
        </nav>
        <div class="account-content" id="accountContent">${renderLoading()}</div>
      </div>
    </div>
  ` + renderFooter();

  attachHeaderSearch();
  loadAccountTab();
}

async function loadAccountTab() {
  const user = getUser();
  const ac = document.getElementById('accountContent');
  if (!ac) return;

  document.querySelectorAll('.account-nav-item').forEach(n => n.classList.remove('active'));
  document.querySelectorAll('.account-nav-item').forEach(n => { if (n.textContent.toLowerCase().includes(accountTab === 'profile' ? 'hồ sơ' : accountTab === 'orders' ? 'đơn hàng' : 'đánh giá')) n.classList.add('active'); });

  ac.innerHTML = renderLoading();

  if (accountTab === 'profile') {
    try {
      const p = await api(`/account/profile?customer_id=${user.CUSTOMER_ID}`);
      ac.innerHTML = `
        <h3 style="font-family:var(--font-heading);margin-bottom:20px">Thông tin cá nhân</h3>
        <div class="form-group"><label>Họ tên</label><input id="profName" value="${p.FULL_NAME || ''}" /></div>
        <div class="form-group"><label>Email</label><input value="${p.EMAIL || ''}" readonly style="background:var(--surface-alt)" /></div>
        <div class="form-group"><label>Số điện thoại</label><input id="profPhone" value="${p.PHONE || ''}" /></div>
        <div class="form-group"><label>Địa chỉ</label><input id="profAddress" value="${p.ADDRESS || ''}" /></div>
        <div class="form-group"><label>Trạng thái</label><span class="order-status ${p.STATUS}">${p.STATUS}</span></div>
        <div class="form-group"><label>Ngày tạo</label><span>${formatDate(p.CREATED_AT)}</span></div>
        <button class="btn-primary" style="width:auto;padding:10px 32px;margin-top:8px" onclick="updateProfile()">Cập nhật</button>
      `;
    } catch (e) { ac.innerHTML = `<p style="color:var(--danger)">${e.message}</p>`; }
  } else if (accountTab === 'orders') {
    try {
      const data = await api(`/account/orders?customer_id=${user.CUSTOMER_ID}`);
      if (data.orders.length === 0) {
        ac.innerHTML = `<div class="empty-state"><h3>Chưa có đơn hàng</h3><p>Hãy đặt hàng đầu tiên!</p></div>`;
        return;
      }
      ac.innerHTML = `<h3 style="font-family:var(--font-heading);margin-bottom:20px">Lịch sử đơn hàng</h3>` +
        data.orders.map(o => {
          const statusMap = { PENDING: 'Chờ xử lý', CONFIRMED: 'Đã xác nhận', SHIPPING: 'Đang giao', DELIVERED: 'Đã giao', CANCELLED: 'Đã hủy' };
          const steps = ['PENDING', 'CONFIRMED', 'SHIPPING', 'DELIVERED'];
          const currentIdx = steps.indexOf(o.STATUS);
          return `
            <div class="order-card">
              <div class="order-card-header">
                <span>Đơn #${o.ORDER_ID} — ${formatDate(o.ORDER_DATE)}</span>
                <span class="order-status ${o.STATUS}">${statusMap[o.STATUS] || o.STATUS}</span>
              </div>
              <div class="order-card-body">
                ${o.details.map(d => `<div class="summary-row"><span>${d.TITLE} ×${d.QUANTITY}</span><span>${formatPrice(d.SUBTOTAL)}</span></div>`).join('')}
                <div class="summary-row total"><span>Tổng</span><span>${formatPrice(o.TOTAL_AMOUNT)}</span></div>
                ${o.STATUS !== 'CANCELLED' ? `<div class="order-timeline">${steps.map((s, i) => `
                  <div class="timeline-step ${i < currentIdx ? 'done' : i === currentIdx ? 'current' : ''}">${statusMap[s]}</div>
                `).join('')}</div>` : ''}
              </div>
            </div>`;
        }).join('');
    } catch (e) { ac.innerHTML = `<p style="color:var(--danger)">${e.message}</p>`; }
  } else if (accountTab === 'reviews') {
    try {
      const data = await api(`/account/reviews?customer_id=${user.CUSTOMER_ID}`);
      if (data.rows.length === 0) {
        ac.innerHTML = `<div class="empty-state"><h3>Chưa có đánh giá</h3><p>Đánh giá sách sau khi nhận hàng nhé!</p></div>`;
        return;
      }
      ac.innerHTML = `<h3 style="font-family:var(--font-heading);margin-bottom:20px">Đánh giá của bạn</h3>` +
        data.rows.map(r => `
          <div class="review-item" style="display:flex;gap:16px;padding:16px 0">
            <div style="width:60px;height:75px;border-radius:6px;overflow:hidden;background:var(--surface-alt);flex-shrink:0">
              ${r.IMAGE_URL ? `<img src="${r.IMAGE_URL}" style="width:100%;height:100%;object-fit:cover" />` : ''}
            </div>
            <div>
              <div style="font-weight:500;cursor:pointer" onclick="navigate('/book/${r.BOOK_ID}')">${r.TITLE}</div>
              <div class="review-stars">${renderStars(r.RATING)}</div>
              <div class="review-comment">${r.REVIEW_COMMENT || ''}</div>
              <div class="review-date">${formatDate(r.REVIEW_DATE)}</div>
            </div>
          </div>
        `).join('');
    } catch (e) { ac.innerHTML = `<p style="color:var(--danger)">${e.message}</p>`; }
  }
}

async function updateProfile() {
  const user = getUser();
  try {
    await api('/account/profile', {
      method: 'PUT',
      body: {
        customerId: user.CUSTOMER_ID,
        fullName: document.getElementById('profName').value,
        phone: document.getElementById('profPhone').value,
        address: document.getElementById('profAddress').value
      }
    });
    // Update local user
    user.FULL_NAME = document.getElementById('profName').value;
    user.PHONE = document.getElementById('profPhone').value;
    user.ADDRESS = document.getElementById('profAddress').value;
    setUser(user);
    showToast('Cập nhật thành công!');
  } catch (e) { showToast(e.message, 'error'); }
}

// ========== Header Search Handler ==========
function attachHeaderSearch() {
  const form = document.getElementById('headerSearchForm');
  if (form) {
    form.onsubmit = (e) => {
      e.preventDefault();
      const q = document.getElementById('headerSearchInput').value.trim();
      if (q) {
        window.history.pushState(null, '', `/store/search?q=${encodeURIComponent(q)}`);
        renderSearchPage();
      }
    };
  }
}

// ========== Init ==========
route();
