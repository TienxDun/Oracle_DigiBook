/* ========== DigiBook Store — Reusable Components ========== */

const API = '/api/store';

// ========== Utilities ==========
function formatPrice(num) {
  return Number(num || 0).toLocaleString('vi-VN') + '₫';
}

function formatDate(d) {
  if (!d) return '';
  const date = new Date(d);
  return date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

function renderStars(rating, max = 5) {
  const full = Math.floor(rating);
  const half = rating % 1 >= 0.5 ? 1 : 0;
  return '★'.repeat(full) + (half ? '½' : '') + '☆'.repeat(max - full - half);
}

async function api(path, options = {}) {
  const res = await fetch(API + path, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
    body: options.body ? JSON.stringify(options.body) : undefined
  });
  const data = await res.json();
  if (!res.ok && !data.ok) throw new Error(data.message || 'Lỗi hệ thống');
  return data;
}

function getUser() {
  try { return JSON.parse(localStorage.getItem('digibook_user')); } catch { return null; }
}

function setUser(user) {
  localStorage.setItem('digibook_user', JSON.stringify(user));
}

function clearUser() {
  localStorage.removeItem('digibook_user');
}

function getCartCount() {
  return Number(localStorage.getItem('digibook_cart_count') || 0);
}

function setCartCount(n) {
  localStorage.setItem('digibook_cart_count', String(n));
  document.querySelectorAll('.cart-count-val').forEach(el => {
    el.textContent = n;
    el.parentElement.style.display = n > 0 ? 'flex' : 'none';
  });
}

// ========== Toast ==========
function showToast(msg, type = 'success') {
  let container = document.querySelector('.toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = msg;
  container.appendChild(toast);
  setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 300); }, 3000);
}

// ========== Header ==========
function renderHeader() {
  const user = getUser();
  const count = getCartCount();
  return `
    <header class="site-header">
      <div class="header-inner">
        <div class="logo" onclick="navigate('/')">DigiBook</div>
        <form class="header-search" id="headerSearchForm">
          <input type="text" placeholder="Tìm sách, tác giả, ISBN..." id="headerSearchInput" />
          <button type="submit">Tìm</button>
        </form>
        <nav class="header-nav">
          <a class="nav-link" href="#" onclick="navigate('/category'); return false;">Danh mục</a>
          <a class="nav-link cart-link" href="#" onclick="navigate('/cart'); return false;">
            Giỏ hàng
            <span class="cart-badge" style="display:${count > 0 ? 'flex' : 'none'}">
              <span class="cart-count-val">${count}</span>
            </span>
          </a>
          ${user
            ? `<a class="nav-link" href="#" onclick="navigate('/account'); return false;">${user.FULL_NAME.split(' ').pop()}</a>
               <button class="nav-btn" onclick="handleLogout()" style="background:rgba(255,255,255,0.1);color:#fff;border:1px solid rgba(255,255,255,0.3)">Đăng xuất</button>`
            : `<button class="nav-btn" onclick="navigate('/auth')">Đăng nhập</button>`
          }
        </nav>
      </div>
    </header>`;
}

// ========== Footer ==========
function renderFooter() {
  return `
    <footer class="site-footer">
      <div class="footer-inner">
        <div class="footer-brand">
          <div class="logo">DigiBook</div>
          <p>Nền tảng bán sách trực tuyến hàng đầu Việt Nam. Hàng ngàn đầu sách chất lượng với giá tốt nhất.</p>
        </div>
        <div class="footer-col">
          <h4>Danh mục</h4>
          <a href="#" onclick="navigate('/category/2'); return false;">Văn học</a>
          <a href="#" onclick="navigate('/category/3'); return false;">Kinh tế</a>
          <a href="#" onclick="navigate('/category/4'); return false;">Công nghệ</a>
          <a href="#" onclick="navigate('/category/5'); return false;">Tâm lý</a>
        </div>
        <div class="footer-col">
          <h4>Hỗ trợ</h4>
          <a href="#">Chính sách đổi trả</a>
          <a href="#">Hướng dẫn mua hàng</a>
          <a href="#">Liên hệ</a>
        </div>
        <div class="footer-col">
          <h4>Liên hệ</h4>
          <a href="#">support@digibook.vn</a>
          <a href="#">1900-BOOK</a>
          <a href="#">TP. Hồ Chí Minh</a>
        </div>
      </div>
      <div class="footer-bottom">
        <p>© 2026 DigiBook — Nhóm 4: Dũng, Nam, Hiếu, Phát | Oracle 19c</p>
      </div>
    </footer>`;
}

// ========== Book Card ==========
function renderBookCard(book) {
  const stockClass = book.STOCK_QUANTITY <= 0 ? 'out' : book.STOCK_QUANTITY <= 10 ? 'low' : '';
  const stockText = book.STOCK_QUANTITY <= 0 ? 'Hết hàng' : book.STOCK_QUANTITY <= 10 ? `Còn ${book.STOCK_QUANTITY}` : '';
  return `
    <div class="book-card" onclick="navigate('/book/${book.BOOK_ID}')">
      <div class="book-card-img">
        ${book.IMAGE_URL
          ? `<img src="${book.IMAGE_URL}" alt="${book.TITLE}" onerror="this.style.display='none';this.nextElementSibling.style.display='block'" /><span class="book-placeholder" style="display:none">Sách</span>`
          : `<span class="book-placeholder">Sách</span>`}
        ${stockText ? `<span class="stock-badge ${stockClass}">${stockText}</span>` : ''}
      </div>
      <div class="book-card-body">
        <div class="book-card-title">${book.TITLE}</div>
        <div class="book-card-author">${book.AUTHOR_NAME || 'Chưa rõ tác giả'}</div>
        <div class="book-card-meta">
          <span class="book-card-price">${formatPrice(book.PRICE)}</span>
          <span class="book-card-rating">
            ★ ${Number(book.AVG_RATING || 0).toFixed(1)}
            <span>(${book.REVIEW_COUNT || 0})</span>
          </span>
        </div>
        ${book.STOCK_QUANTITY > 0 ? `<button class="add-cart-btn" onclick="event.stopPropagation(); addToCart(${book.BOOK_ID})">Thêm vào giỏ</button>` : ''}
      </div>
    </div>`;
}

// ========== Pagination ==========
function renderPagination(page, totalPages, onPageChange) {
  if (totalPages <= 1) return '';
  let html = '<div class="pagination">';
  html += `<button class="page-btn" ${page <= 1 ? 'disabled' : ''} onclick="${onPageChange}(${page - 1})">◀</button>`;
  for (let i = 1; i <= totalPages; i++) {
    if (totalPages > 7 && i > 3 && i < totalPages - 2 && Math.abs(i - page) > 1) {
      if (i === 4 || i === totalPages - 3) html += '<span style="padding:0 6px;color:var(--text-muted)">...</span>';
      continue;
    }
    html += `<button class="page-btn ${i === page ? 'active' : ''}" onclick="${onPageChange}(${i})">${i}</button>`;
  }
  html += `<button class="page-btn" ${page >= totalPages ? 'disabled' : ''} onclick="${onPageChange}(${page + 1})">▶</button>`;
  html += '</div>';
  return html;
}

// ========== Loading ==========
function renderLoading() {
  return '<div class="loading-spinner"><div class="spinner"></div></div>';
}

function renderBookGridSkeleton(count = 8) {
  return '<div class="book-grid">' +
    Array(count).fill(`
      <div class="book-card">
        <div class="book-card-img skeleton" style="height:200px"></div>
        <div class="book-card-body">
          <div class="skeleton" style="height:18px;margin-bottom:8px"></div>
          <div class="skeleton" style="height:14px;width:60%;margin-bottom:10px"></div>
          <div class="skeleton" style="height:20px;width:40%"></div>
        </div>
      </div>
    `).join('') + '</div>';
}

// ========== Add to Cart ==========
async function addToCart(bookId, qty = 1) {
  const user = getUser();
  if (!user) { showToast('Vui lòng đăng nhập để thêm vào giỏ hàng', 'error'); navigate('/auth'); return; }
  try {
    await api('/cart/items', { method: 'POST', body: { customerId: user.CUSTOMER_ID, bookId, quantity: qty } });
    setCartCount(getCartCount() + qty);
    showToast('Đã thêm vào giỏ hàng!');
  } catch (e) {
    showToast(e.message, 'error');
  }
}

function handleLogout() {
  clearUser();
  setCartCount(0);
  navigate('/');
  showToast('Đã đăng xuất thành công');
}
