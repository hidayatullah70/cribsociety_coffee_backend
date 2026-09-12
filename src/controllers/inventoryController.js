const inventoryService = require('../services/inventoryService');
const { sendSuccess } = require('../utils/response');

async function getInventory(req, res, next) {
  try {
    const inventory = await inventoryService.getInventory();
    return sendSuccess(res, { inventory }, 200);
  } catch (error) {
    next(error);
  }
}

async function getProductInventory(req, res, next) {
  try {
    const { productId } = req.params;
    const inventory = await inventoryService.getProductInventory(productId);
    return sendSuccess(res, { inventory }, 200);
  } catch (error) {
    next(error);
  }
}

async function adjustInventory(req, res, next) {
  try {
    const { productId } = req.params;
    const inventory = await inventoryService.adjustInventory(productId, req.body, req.user);
    return sendSuccess(res, { inventory }, 200);
  } catch (error) {
    next(error);
  }
}

async function getAdjustmentHistory(req, res, next) {
  try {
    const { productId, page, limit } = req.query;
    const result = await inventoryService.getAdjustmentHistory({ productId, page, limit });
    return sendSuccess(res, result, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getInventory,
  getProductInventory,
  adjustInventory,
  getAdjustmentHistory,
};
