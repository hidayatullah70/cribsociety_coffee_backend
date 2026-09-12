const crypto = require('crypto');

/**
 * Generate a unique opaque ID with domain prefix
 * e.g. usr_a1b2c3d4, prod_e5f6g7h8, ord_9i0j1k2l
 */
function generateId(prefix = '') {
  const randomStr = crypto.randomBytes(8).toString('hex');
  const timestamp = Date.now().toString(36).slice(-4);
  const id = `${randomStr}${timestamp}`;
  return prefix ? `${prefix}_${id}` : id;
}

/**
 * Generate human-readable unique order number #CSC-XXXX
 */
function generateOrderNumber() {
  const num = Math.floor(1000 + Math.random() * 9000);
  return `#CSC-${num}`;
}

module.exports = {
  generateId,
  generateOrderNumber,
};
