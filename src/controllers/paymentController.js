const paymentService = require('../services/paymentService');
const { sendSuccess } = require('../utils/response');

async function processPayment(req, res, next) {
  try {
    const { id } = req.params; // orderId
    const result = await paymentService.processPayment(id, req.body, req.user);
    return sendSuccess(res, result, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  processPayment,
};
