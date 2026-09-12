const PAYMENT_STATUS = {
  UNPAID: 'unpaid',
  PENDING: 'pending',
  PAID: 'paid',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
};

const PAYMENT_METHOD = {
  CASH: 'cash',
  QRIS: 'qris',
  CARD: 'card',
  OTHER: 'other',
};

module.exports = {
  PAYMENT_STATUS,
  PAYMENT_METHOD,
};
