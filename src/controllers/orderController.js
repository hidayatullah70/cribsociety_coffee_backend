const orderService = require('../services/orderService');
const { sendSuccess } = require('../utils/response');

async function createOrder(req, res, next) {
  try {
    const order = await orderService.createOrder(req.body, req.user);
    return sendSuccess(res, { order }, 201);
  } catch (error) {
    next(error);
  }
}

async function getOrders(req, res, next) {
  try {
    const { status, from, to, page, limit, orderNumber } = req.query;
    const result = await orderService.getOrders({
      status,
      from,
      to,
      page,
      limit,
      orderNumber,
    });
    return sendSuccess(res, result, 200);
  } catch (error) {
    next(error);
  }
}

async function getOrderById(req, res, next) {
  try {
    const { id } = req.params;
    const order = await orderService.getOrderById(id);
    return sendSuccess(res, { order }, 200);
  } catch (error) {
    next(error);
  }
}

async function updateOrderStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const order = await orderService.updateOrderStatus(id, status, req.user);
    return sendSuccess(res, { order }, 200);
  } catch (error) {
    next(error);
  }
}

async function trackOrder(req, res, next) {
  try {
    const { orderNumber } = req.params;
    const order = await orderService.getOrderByOrderNumber(orderNumber);
    return sendSuccess(res, { order }, 200);
  } catch (error) {
    next(error);
  }
}

async function getLiveQueue(req, res, next) {
  try {
    const queue = await orderService.getLiveQueue();
    return sendSuccess(res, { queue }, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createOrder,
  getOrders,
  getOrderById,
  updateOrderStatus,
  trackOrder,
  getLiveQueue,
};
