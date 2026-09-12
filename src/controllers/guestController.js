const menuService = require('../services/menuService');
const orderService = require('../services/orderService');
const { sendSuccess } = require('../utils/response');

async function getPublicMenu(req, res, next) {
  try {
    const { categoryId } = req.query;
    const categories = await menuService.getCategories(false);
    const products = await menuService.getProducts({
      categoryId,
      available: true,
      includeArchived: false,
    });

    return sendSuccess(res, { categories, products }, 200);
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

async function trackOrder(req, res, next) {
  try {
    const { orderNumber } = req.params;
    const order = await orderService.getOrderByOrderNumber(orderNumber);
    // Sanitize sensitive user info for guest view
    return sendSuccess(res, {
      order: {
        orderNumber: order.orderNumber,
        status: order.status,
        paymentStatus: order.paymentStatus,
        subtotal: order.subtotal,
        discountTotal: order.discountTotal,
        total: order.total,
        items: order.items.map(it => ({
          name: it.name,
          variantName: it.variantName,
          addons: it.addons,
          quantity: it.quantity,
        })),
        createdAt: order.createdAt,
      },
    }, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getPublicMenu,
  getLiveQueue,
  trackOrder,
};
