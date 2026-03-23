/**
 * DigiBook UI Components and Helpers
 */

const UI = (function() {
  'use strict';

  function formatVND(value) {
    return Number(value || 0).toLocaleString('vi-VN') + 'đ';
  }

  function formatDate(value, withTime = false) {
    if (!value) return '—';
    const d = new Date(value);
    if (isNaN(d.getTime())) return String(value);
    
    const options = { day: '2-digit', month: '2-digit', year: 'numeric' };
    if (withTime) {
      options.hour = '2-digit';
      options.minute = '2-digit';
    }
    return d.toLocaleDateString('vi-VN', options);
  }

  function statusBadge(status) {
    const map = {
      'PENDING': 'badge-pending',
      'CONFIRMED': 'badge-confirmed',
      'SHIPPING': 'badge-shipping',
      'DELIVERED': 'badge-delivered',
      'CANCELLED': 'badge-cancelled',
      'ACTIVE': 'badge-active',
      'INACTIVE': 'badge-inactive',
      'BANNED': 'badge-banned',
      'PAID': 'badge-paid',
      'FAILED': 'badge-failed',
      'REFUNDED': 'badge-refunded'
    };
    return `<span class="badge ${map[status] || 'badge-pending'}">${status || '—'}</span>`;
  }

  function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3200);
  }

  function showLoading(container) {
    container.innerHTML = '<div class="loading-spinner"><div class="spinner"></div></div>';
  }

  function refreshIcons() {
    if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  function showEmpty(container, icon = 'package-open', text = 'Không có dữ liệu', sub = '') {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon"><i data-lucide="${icon}"></i></div>
        <div class="empty-state-text">${text}</div>
        ${sub ? `<div class="empty-state-sub">${sub}</div>` : ''}
      </div>
    `;
    refreshIcons();
  }

  return {
    formatVND,
    formatDate,
    statusBadge,
    showToast,
    showLoading,
    showEmpty,
    refreshIcons
  };
})();

// Attach to window
window.DigiBookUI = UI;
