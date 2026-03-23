/**
 * Standard API response utilities
 */

const success = (res, data, status = 200) => {
  return res.status(status).json(data);
};

const error = (res, message, status = 500) => {
  return res.status(status).json({
    ok: false,
    message: message || 'An unexpected error occurred'
  });
};

const formatOracleError = (err) => {
  if (err && err.message) {
    // Basic cleaning of Oracle error messages
    return err.message.replace(/^ORA-\d+: /, '');
  }
  return 'Oracle request failed';
};

module.exports = {
  success,
  error,
  formatOracleError
};
