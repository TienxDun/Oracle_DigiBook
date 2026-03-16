const state = {
  currentTable: 'books',
  tables: [],
  summary: null,
  tableFilter: ''
};

const statusText = document.getElementById('statusText');
const statusDot = document.getElementById('statusDot');
const statsContainer = document.getElementById('stats');
const recentOrdersContainer = document.getElementById('recentOrders');
const tableTabs = document.getElementById('tableTabs');
const tableTabSearch = document.getElementById('tableTabSearch');
const tableTabCount = document.getElementById('tableTabCount');
const tableContainer = document.getElementById('tableContainer');
const tableMeta = document.getElementById('tableMeta');
const limitSelect = document.getElementById('limitSelect');
const reloadButton = document.getElementById('reloadButton');
const searchForm = document.getElementById('searchForm');
const searchInput = document.getElementById('searchInput');
const searchResults = document.getElementById('searchResults');
const statTemplate = document.getElementById('statTemplate');
const runtimeInfo = document.getElementById('runtimeInfo');

function formatNumber(value) {
  if (value == null) {
    return '-';
  }

  return new Intl.NumberFormat('vi-VN').format(value);
}

function formatCurrency(value) {
  if (value == null) {
    return '-';
  }

  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0
  }).format(value);
}

function formatCompactCurrency(value) {
  if (value == null) {
    return '-';
  }

  if (value >= 1000000) {
    return `${new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 2 }).format(value / 1000000)} triệu`;
  }

  if (value >= 1000) {
    return `${new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(value / 1000)} nghìn`;
  }

  return formatCurrency(value);
}

function formatValue(value, columnName = '') {
  if (value == null) {
    return '-';
  }

  if (typeof value === 'number') {
    if (String(columnName).toUpperCase().endsWith('_YEAR')) {
      return String(value);
    }

    return formatNumber(value);
  }

  const isoDate = /^\d{4}-\d{2}-\d{2}T/;
  if (typeof value === 'string' && isoDate.test(value)) {
    return new Date(value).toLocaleString('vi-VN');
  }

  return String(value);
}

function setStatus(ok, text) {
  statusText.textContent = text;
  statusDot.classList.remove('ok', 'error');
  statusDot.classList.add(ok ? 'ok' : 'error');
}

async function fetchJson(url) {
  const response = await fetch(url);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Request failed');
  }

  return data;
}

async function loadHealth() {
  try {
    await fetchJson('/api/health');
    setStatus(true, 'Đã kết nối');
  } catch (error) {
    setStatus(false, 'Lỗi kết nối');
    tableMeta.textContent = error.message;
  }
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

function renderStats(summary) {
  statsContainer.innerHTML = '';

  const items = [
    { label: 'Tổng sách', value: formatNumber(summary.totalBooks) },
    { label: 'Tồn kho', value: formatNumber(summary.totalStock) },
    { label: 'Khách hàng', value: formatNumber(summary.totalCustomers) },
    { label: 'Đơn hàng', value: formatNumber(summary.totalOrders) },
    {
      label: 'Doanh thu đã giao',
      note: 'Tổng doanh thu từ các đơn đã hoàn tất',
      value: formatCurrency(summary.deliveredRevenue),
      featured: true
    },
    {
      label: 'Điểm đánh giá trung bình',
      note: `${formatNumber(summary.totalReviews)} lượt đánh giá hợp lệ`,
      value: formatNumber(summary.avgRating),
      featured: true
    }
  ];

  items.forEach((item) => {
    const node = statTemplate.content.cloneNode(true);
    const card = node.querySelector('.stat-card');
    const label = node.querySelector('.stat-label');
    const note = node.querySelector('.stat-note');
    const value = node.querySelector('.stat-value');

    label.textContent = item.label;
    value.textContent = item.value;

    if (item.note) {
      note.textContent = item.note;
    } else {
      note.remove();
    }

    if (item.featured) {
      card.classList.add('stat-card-feature');
    }

    statsContainer.appendChild(node);
  });
}

function renderTable(columns, rows) {
  if (!columns.length) {
    tableContainer.innerHTML = '<div class="empty-state" style="padding:16px;">Không có dữ liệu.</div>';
    return;
  }

  const thead = `<thead><tr>${columns.map((column) => `<th>${column}</th>`).join('')}</tr></thead>`;
  const tbody = `<tbody>${rows
    .map(
      (row) =>
        `<tr>${columns
          .map((column) => `<td>${formatValue(row[column], column)}</td>`)
          .join('')}</tr>`
    )
    .join('')}</tbody>`;

  tableContainer.innerHTML = `<table>${thead}${tbody}</table>`;
}

function renderRecentOrders(rows) {
  renderIntoContainer(recentOrdersContainer, rows);
}

function renderIntoContainer(container, rows) {
  if (!rows.length) {
    container.innerHTML = '<div class="empty-state" style="padding:16px;">Không có dữ liệu.</div>';
    return;
  }

  const columns = Object.keys(rows[0]);
  const thead = `<thead><tr>${columns.map((column) => `<th>${column}</th>`).join('')}</tr></thead>`;
  const tbody = `<tbody>${rows
    .map(
      (row) =>
        `<tr>${columns
          .map((column) => {
            const raw = row[column];
            const content = column.toLowerCase().includes('status')
              ? `<span class="badge">${formatValue(raw, column)}</span>`
              : formatValue(raw, column);
            return `<td>${content}</td>`;
          })
          .join('')}</tr>`
    )
    .join('')}</tbody>`;

  container.innerHTML = `<table>${thead}${tbody}</table>`;
}

function renderTabs() {
  tableTabs.innerHTML = '';

  const filter = state.tableFilter.trim().toLowerCase();
  const visibleTables = state.tables.filter((table) => {
    if (!filter) {
      return true;
    }

    const byLabel = String(table.label || '').toLowerCase().includes(filter);
    const byKey = String(table.key || '').toLowerCase().includes(filter);
    return byLabel || byKey;
  });

  tableTabCount.textContent = `${formatNumber(visibleTables.length)}/${formatNumber(state.tables.length)} bảng`;

  if (!visibleTables.length) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.style.padding = '8px 10px';
    empty.textContent = 'Không có bảng phù hợp bộ lọc.';
    tableTabs.appendChild(empty);
    return;
  }

  visibleTables.forEach((table) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `tab${table.key === state.currentTable ? ' active' : ''}`;
    button.setAttribute('role', 'tab');
    button.setAttribute('aria-selected', table.key === state.currentTable ? 'true' : 'false');
    const label = document.createElement('span');
    label.className = 'tab-label';
    label.textContent = table.label;
    const badge = document.createElement('span');
    badge.className = 'tab-badge';
    badge.textContent = formatNumber(table.totalRows);
    button.append(label, badge);
    button.addEventListener('click', async () => {
      state.currentTable = table.key;
      renderTabs();
      await loadTable();
    });
    tableTabs.appendChild(button);
  });

  const activeTab = tableTabs.querySelector('.tab.active');
  if (activeTab) {
    activeTab.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' });
  }
}

async function loadSummary() {
  const data = await fetchJson('/api/summary');
  state.summary = data;
  renderStats(data.cards);
  renderRecentOrders(data.recentOrders);
}

async function loadRuntime() {
  const data = await fetchJson('/api/runtime');
  renderRuntime(data);
}

async function loadTables() {
  state.tables = await fetchJson('/api/tables');
  renderTabs();
}

async function loadTable() {
  try {
    const limit = Number(limitSelect.value || 25);
    const data = await fetchJson(`/api/table/${state.currentTable}?limit=${limit}`);

    const tableInfo = state.tables.find((table) => table.key === state.currentTable);
    if (tableInfo) {
      tableInfo.totalRows = data.totalRows;
      renderTabs();
    }

    tableMeta.textContent = `${data.label} • Tổng ${formatNumber(data.totalRows)} dòng • Đang hiển thị ${formatNumber(data.rows.length)} dòng`;
    renderTable(data.columns, data.rows);
  } catch (error) {
    tableMeta.textContent = `Không thể tải bảng: ${error.message}`;
    tableContainer.innerHTML = '<div class="empty-state" style="padding:16px;">Không thể tải dữ liệu bảng hiện tại.</div>';
  }
}

async function searchBooks(term) {
  const data = await fetchJson(`/api/search/books?q=${encodeURIComponent(term)}`);

  if (!data.rows.length) {
    searchResults.className = 'result-list empty-state';
    searchResults.textContent = 'Không tìm thấy sách phù hợp.';
    return;
  }

  searchResults.className = 'result-list';
  searchResults.innerHTML = data.rows
    .map(
      (row) => `
        <article class="result-item">
          <div class="result-title">${row.TITLE}</div>
          <div class="result-meta">Mã sách: ${row.BOOK_ID} • Giá: ${formatCurrency(row.PRICE)} • Tồn: ${formatNumber(row.STOCK_QUANTITY)}</div>
          <div class="result-meta">Danh mục: ${row.CATEGORY_NAME || '-'} • NXB: ${row.PUBLISHER_NAME || '-'}</div>
        </article>
      `
    )
    .join('');
}

reloadButton.addEventListener('click', loadTable);
limitSelect.addEventListener('change', loadTable);

tableTabSearch.addEventListener('input', () => {
  state.tableFilter = tableTabSearch.value;
  renderTabs();
});

searchForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const term = searchInput.value.trim();

  if (!term) {
    searchResults.className = 'result-list empty-state';
    searchResults.textContent = 'Nhập tên sách để tìm kiếm.';
    return;
  }

  await searchBooks(term);
});

async function init() {
  await loadHealth();
  await loadRuntime();
  await loadSummary();
  await loadTables();
  await loadTable();
}

init().catch((error) => {
  setStatus(false, 'Khởi động thất bại');
  tableMeta.textContent = error.message;
});