/**
 * DigiBook API Client
 */

const API = (function() {
  'use strict';

  async function request(url, options = {}) {
    const defaultHeaders = { 'Content-Type': 'application/json' };
    
    try {
      const res = await fetch(url, {
        ...options,
        headers: {
          ...defaultHeaders,
          ...options.headers
        }
      });

      const data = await res.json();
      
      if (!res.ok) {
        throw new Error(data.message || `API Error: ${res.status}`);
      }
      
      return data;
    } catch (err) {
      console.error(`API Request Failed [${url}]:`, err);
      // Re-throw so callers can handle or show UI feedback
      throw err;
    }
  }

  return {
    get: (url, options) => request(url, { ...options, method: 'GET' }),
    post: (url, body, options) => request(url, { ...options, method: 'POST', body: JSON.stringify(body) }),
    put: (url, body, options) => request(url, { ...options, method: 'PUT', body: JSON.stringify(body) }),
    delete: (url, options) => request(url, { ...options, method: 'DELETE' }),
    
    // Specific helper for paginated table data
    getTable: (tableName, limit = 25) => request(`/api/table/${tableName}?limit=${limit}`)
  };
})();

// Export if in a module environment, otherwise attach to window
if (typeof module !== 'undefined' && module.exports) {
  module.exports = API;
} else {
  window.DigiBookAPI = API;
}
