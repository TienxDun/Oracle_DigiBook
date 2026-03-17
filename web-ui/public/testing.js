const statusText = document.getElementById('statusText');
const statusDot = document.getElementById('statusDot');
const runtimeInfo = document.getElementById('runtimeInfo');

const manageBookForm = document.getElementById('manageBookForm');
const monthlySalesForm = document.getElementById('monthlySalesForm');
const lowStockForm = document.getElementById('lowStockForm');
const couponForm = document.getElementById('couponForm');
const triggerValidationForm = document.getElementById('triggerValidationForm');
const triggerRecalcForm = document.getElementById('triggerRecalcForm');
const triggerAuditForm = document.getElementById('triggerAuditForm');

const manageBookResult = document.getElementById('manageBookResult');
const monthlySalesResult = document.getElementById('monthlySalesResult');
const lowStockResult = document.getElementById('lowStockResult');
const couponResult = document.getElementById('couponResult');
const triggerValidationResult = document.getElementById('triggerValidationResult');
const triggerRecalcResult = document.getElementById('triggerRecalcResult');
const triggerAuditResult = document.getElementById('triggerAuditResult');

const manageBookBadge = document.getElementById('manageBookBadge');
const monthlySalesBadge = document.getElementById('monthlySalesBadge');
const lowStockBadge = document.getElementById('lowStockBadge');
const couponBadge = document.getElementById('couponBadge');
const triggerValidationBadge = document.getElementById('triggerValidationBadge');
const triggerRecalcBadge = document.getElementById('triggerRecalcBadge');
const triggerAuditBadge = document.getElementById('triggerAuditBadge');

const monthlySalesTable = document.getElementById('monthlySalesTable');
const lowStockTable = document.getElementById('lowStockTable');
const couponTable = document.getElementById('couponTable');
const triggerRecalcTable = document.getElementById('triggerRecalcTable');
const triggerAuditTable = document.getElementById('triggerAuditTable');
const reloadCouponsButton = document.getElementById('reloadCouponsButton');
const reloadAuditButton = document.getElementById('reloadAuditButton');

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

function validateManageBookPayload(payload) {
  if (payload.action === 'DELETE') {
    return payload.bookId == null ? 'DELETE yêu cầu Book ID.' : null;
  }

  if (payload.action === 'UPDATE' && payload.bookId == null) {
    return 'UPDATE yêu cầu Book ID.';
  }

  if (!payload.title || !String(payload.title).trim()) {
    return 'Title là bắt buộc cho ADD/UPDATE.';
  }

  if (payload.price == null || payload.price <= 0) {
    return 'Price phải lớn hơn 0 cho ADD/UPDATE.';
  }

  if (payload.stockQuantity != null && payload.stockQuantity < 0) {
    return 'Stock quantity không được âm.';
  }

  if (payload.categoryId == null) {
    return 'Category ID là bắt buộc cho ADD/UPDATE.';
  }

  if (payload.publisherId == null) {
    return 'Publisher ID là bắt buộc cho ADD/UPDATE.';
  }

  return null;
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

function setTestBadge(badgeEl, ok) {
  if (!badgeEl) return;
  badgeEl.classList.remove('pass', 'fail');
  if (ok === true) {
    badgeEl.classList.add('pass');
    badgeEl.textContent = 'PASS';
  } else if (ok === false) {
    badgeEl.classList.add('fail');
    badgeEl.textContent = 'FAIL';
  }
}

function renderJson(target, payload) {
  target.textContent = JSON.stringify(payload, null, 2);
  target.classList.remove('pass', 'fail');
  if (payload != null && typeof payload === 'object') {
    if (payload.ok === true) target.classList.add('pass');
    else if (payload.ok === false) target.classList.add('fail');
  }
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

function renderTriggerSteps(container, steps) {
  if (!steps || !steps.length) {
    container.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có bước kiểm tra.</div>';
    return;
  }

  const rows = steps.map((step) => ({
    STEP: step.step,
    EXPECTED_TOTAL: step.expectedTotal,
    ACTUAL_TOTAL: step.actualTotal,
    MATCH: step.expectedTotal === step.actualTotal ? 'PASS' : 'FAIL',
    SHIPPING_FEE: step.shippingFee,
    DISCOUNT_AMOUNT: step.discountAmount
  }));

  renderTable(container, rows);
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
  try {
    const runtime = await fetchJson('/api/runtime');
    renderRuntime(runtime);
  } catch (error) {
    runtimeInfo.innerHTML = `<div class="empty-state">Lỗi tải runtime: ${error.message}</div>`;
  }
}

async function loadCoupons() {
  try {
    const data = await fetchJson('/api/table/coupons?limit=100');
    renderTable(couponTable, data.rows);
  } catch (error) {
    couponTable.innerHTML = `<div class="empty-state" style="padding: 16px;">Không thể tải coupons: ${error.message}</div>`;
  }
}

async function loadAuditLog() {
  if (!triggerAuditTable) {
    return;
  }

  try {
    const data = await fetchJson('/api/testing/triggers/audit-log?limit=20');
    renderTable(triggerAuditTable, data.rows);
  } catch (error) {
    triggerAuditTable.innerHTML = `<div class="empty-state" style="padding: 16px;">Không thể tải audit log: ${error.message}</div>`;
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

  const validationError = validateManageBookPayload(payload);
  if (validationError) {
    renderJson(manageBookResult, { ok: false, action: payload.action, message: validationError });
    return;
  }

  manageBookResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/procedures/manage-book', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderJson(manageBookResult, result);
    setTestBadge(manageBookBadge, result.ok);

    if (result.bookId) {
      manageBookForm.elements.bookId.value = result.bookId;
    }
  } catch (error) {
    renderJson(manageBookResult, { ok: false, message: error.message });
    setTestBadge(manageBookBadge, false);
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
    setTestBadge(monthlySalesBadge, result.ok);
  } catch (error) {
    monthlySalesTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    renderJson(monthlySalesResult, { ok: false, message: error.message });
    setTestBadge(monthlySalesBadge, false);
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
    setTestBadge(lowStockBadge, result.ok);
  } catch (error) {
    lowStockTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    renderJson(lowStockResult, { ok: false, message: error.message });
    setTestBadge(lowStockBadge, false);
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
    setTestBadge(couponBadge, result.ok);
  } catch (error) {
    renderJson(couponResult, { ok: false, message: error.message });
    setTestBadge(couponBadge, false);
  }
});

triggerValidationForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(triggerValidationForm);
  const payload = {
    scenario: data.get('scenario'),
    orderId: parseNumber(data.get('orderId')),
    customerId: parseNumber(data.get('customerId')),
    shippingAddress: data.get('shippingAddress') || null
  };

  triggerValidationResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/triggers/validation', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderJson(triggerValidationResult, result);
    setTestBadge(triggerValidationBadge, result.ok);
  } catch (error) {
    renderJson(triggerValidationResult, { ok: false, message: error.message });
    setTestBadge(triggerValidationBadge, false);
  }
});

triggerRecalcForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  const data = new FormData(triggerRecalcForm);
  const payload = {
    customerId: parseNumber(data.get('customerId')),
    bookId: parseNumber(data.get('bookId')),
    shippingFee: parseNumber(data.get('shippingFee')),
    discountAmount: parseNumber(data.get('discountAmount')),
    insertQuantity: parseNumber(data.get('insertQuantity')),
    insertUnitPrice: parseNumber(data.get('insertUnitPrice')),
    updateQuantity: parseNumber(data.get('updateQuantity')),
    updateUnitPrice: parseNumber(data.get('updateUnitPrice')),
    shippingAddress: data.get('shippingAddress') || null
  };

  triggerRecalcResult.textContent = 'Đang chạy...';

  try {
    const result = await fetchJson('/api/testing/triggers/recalculate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    renderTriggerSteps(triggerRecalcTable, result.steps);
    renderJson(triggerRecalcResult, {
      ok: result.ok,
      orderId: result.orderId,
      detailId: result.detailId,
      evaluatedSteps: result.steps.length
    });
    setTestBadge(triggerRecalcBadge, result.ok);
  } catch (error) {
    triggerRecalcTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
    renderJson(triggerRecalcResult, { ok: false, message: error.message });
    setTestBadge(triggerRecalcBadge, false);
  }
});

if (triggerAuditForm && triggerAuditResult && triggerAuditTable) {
  triggerAuditForm.addEventListener('submit', async (event) => {
    event.preventDefault();

    const data = new FormData(triggerAuditForm);
    const payload = {
      customerId: parseNumber(data.get('customerId')),
      shippingFee: parseNumber(data.get('shippingFee')),
      discountAmount: parseNumber(data.get('discountAmount')),
      shippingAddress: data.get('shippingAddress') || null
    };

    triggerAuditResult.textContent = 'Đang chạy...';

    try {
      const result = await fetchJson('/api/testing/triggers/audit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      renderTable(triggerAuditTable, result.rows);
      renderJson(triggerAuditResult, {
        ok: result.ok,
        orderId: result.orderId,
        count: result.count,
        actions: result.rows.map((row) => row.ACTION_TYPE)
      });
      setTestBadge(triggerAuditBadge, result.ok);
    } catch (error) {
      triggerAuditTable.innerHTML = '<div class="empty-state" style="padding: 16px;">Không có dữ liệu.</div>';
      renderJson(triggerAuditResult, { ok: false, message: error.message });
      setTestBadge(triggerAuditBadge, false);
    }
  });
}

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

if (reloadAuditButton) {
  reloadAuditButton.addEventListener('click', async () => {
    reloadAuditButton.disabled = true;
    reloadAuditButton.textContent = 'Đang tải...';

    try {
      await loadAuditLog();
    } finally {
      reloadAuditButton.disabled = false;
      reloadAuditButton.textContent = 'Tải lại audit log';
    }
  });
}

(async function bootstrap() {
  try {
    const now = new Date();
    monthlySalesForm.elements.fromDate.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    monthlySalesForm.elements.toDate.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-31`;
  } catch (error) {
    // Ignore date prefill issue.
  }

    try {
      await Promise.all([loadHealth(), loadRuntime(), loadCoupons(), loadAuditLog()]);
    } catch (error) {
      console.error('Bootstrap error:', error);
    }
})();
