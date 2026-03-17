const statusText = document.getElementById('statusText');
const statusDot = document.getElementById('statusDot');
const runtimeInfo = document.getElementById('runtimeInfo');

const manageBookForm = document.getElementById('manageBookForm');
const monthlySalesForm = document.getElementById('monthlySalesForm');
const lowStockForm = document.getElementById('lowStockForm');
const couponForm = document.getElementById('couponForm');

const manageBookResult = document.getElementById('manageBookResult');
const monthlySalesResult = document.getElementById('monthlySalesResult');
const lowStockResult = document.getElementById('lowStockResult');
const couponResult = document.getElementById('couponResult');

const monthlySalesTable = document.getElementById('monthlySalesTable');
const lowStockTable = document.getElementById('lowStockTable');
const couponTable = document.getElementById('couponTable');
const reloadCouponsButton = document.getElementById('reloadCouponsButton');

function formatNumber(value) {
  if (value == null) {
    return '-';
  }

  return new Intl.NumberFormat('vi-VN').format(value);
}

function setStatus(ok, text) {
  statusText.textContent = text;
  statusDot.classList.remove('ok', 'error');
  statusDot.classList.add(ok ? 'ok' : 'error');
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, options);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Request failed');
  }

  return data;
}

function parseNumber(value) {
  if (value === '' || value == null) {
    return null;
  }

  const number = Number(value);
  return Number.isNaN(number) ? null : number;
}

function renderRuntime(data) {
  const startedAt = data.startedAt ? new Date(data.startedAt).toLocaleString('vi-VN') : '-';
  const baseUrl = data.baseUrl
    ? `<a href="${data.baseUrl}" target="_blank" rel="noreferrer">${data.baseUrl}</a>`
    : '-';

  runtimeInfo.innerHTML = [
    ['Cổng', data.actualPort ?? '-'],
    ['Địa chỉ', baseUrl],
    ['Khởi động', startedAt]
  ]
    .map(
      ([label, value]) =>
        `<div class="runtime-item"><span>${label}:</span><strong>${value}</strong></div>`
    )
    .join('');
}

function renderJson(target, payload) {
  target.textContent = JSON.stringify(payload, null, 2);
}

function renderTable(container, rows) {
  if (!rows || !rows.length) {
    container.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    return;
  }

  const columns = Object.keys(rows[0]);
  const thead = `<thead><tr>${columns.map((column) => `<th>${column}</th>`).join('')}</tr></thead>`;
  const tbody = `<tbody>${rows
    .map((row) => `<tr>${columns.map((column) => `<td>${row[column] == null ? '-' : String(row[column])}</td>`).join('')}</tr>`)
    .join('')}</tbody>`;

  container.innerHTML = `<table>${thead}${tbody}</table>`;
}

async function loadHealth() {
  try {
    await fetchJson('/api/health');
    setStatus(true, 'Đã kết nối');
  } catch (error) {
    setStatus(false, 'Lỗi kết nối');
  }
}

async function loadRuntime() {
  const runtime = await fetchJson('/api/runtime');
  renderRuntime(runtime);
}

async function loadCoupons() {
  try {
    const data = await fetchJson('/api/table/coupons?limit=100');
    renderTable(couponTable, data.rows);
  } catch (error) {
    couponTable.innerHTML = `<div class="empty-state" style="padding: 16px;">Không thể tải coupons: ${error.message}</div>`;
  }
}

manageBookForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(manageBookForm);
  const payload = {
    action: data.get('action'),
    bookId: parseNumber(data.get('bookId')),
    title: data.get('title') || null,
    isbn: data.get('isbn') || null,
    price: parseNumber(data.get('price')),
    stockQuantity: parseNumber(data.get('stockQuantity')),
    description: data.get('description') || null,
    publicationYear: parseNumber(data.get('publicationYear')),
    pageCount: parseNumber(data.get('pageCount')),
    categoryId: parseNumber(data.get('categoryId')),
    publisherId: parseNumber(data.get('publisherId'))
  };

  manageBookResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/procedures/manage-book', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderJson(manageBookResult, result);

    if (result.bookId) {
      manageBookForm.elements.bookId.value = result.bookId;
    }
  } catch (error) {
    renderJson(manageBookResult, { ok: false, message: error.message });
  }
});

monthlySalesForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(monthlySalesForm);
  const payload = {
    fromDate: data.get('fromDate'),
    toDate: data.get('toDate')
  };

  monthlySalesResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/procedures/monthly-sales', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderTable(monthlySalesTable, result.rows);
    renderJson(monthlySalesResult, { ok: result.ok, count: result.count });
  } catch (error) {
    monthlySalesTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    renderJson(monthlySalesResult, { ok: false, message: error.message });
  }
});

lowStockForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(lowStockForm);
  const payload = {
    threshold: parseNumber(data.get('threshold'))
  };

  lowStockResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/procedures/low-stock', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderTable(lowStockTable, result.rows);
    renderJson(lowStockResult, {
      ok: result.ok,
      count: result.count,
      message: result.message
    });
  } catch (error) {
    lowStockTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    renderJson(lowStockResult, { ok: false, message: error.message });
  }
});

couponForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(couponForm);
  const payload = {
    couponCode: data.get('couponCode'),
    orderAmount: parseNumber(data.get('orderAmount'))
  };

  couponResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/procedures/coupon-discount', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderJson(couponResult, {
      ok: result.ok,
      couponCode: result.couponCode,
      orderAmount: formatNumber(result.orderAmount),
      discountAmount: formatNumber(result.discountAmount),
      messageCode: result.messageCode
    });
  } catch (error) {
    renderJson(couponResult, { ok: false, message: error.message });
  }
});

reloadCouponsButton.addEventListener('click', async () => {
  reloadCouponsButton.disabled = true;
  reloadCouponsButton.textContent = 'Đang tải...';

  try {
    await loadCoupons();
  } finally {
    reloadCouponsButton.disabled = false;
    reloadCouponsButton.textContent = 'Tải lại coupons';
  }
});

(async function bootstrap() {
  try {
    const now = new Date();
    monthlySalesForm.elements.fromDate.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    monthlySalesForm.elements.toDate.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-31`;
  } catch (error) {
    // Ignore date prefill issue.
  }

  await Promise.all([loadHealth(), loadRuntime(), loadCoupons()]);
})();
