const menuService = require('../services/menuService');
const { sendSuccess } = require('../utils/response');

async function getCategories(req, res, next) {
  try {
    const includeInactive = req.query.all === 'true';
    const categories = await menuService.getCategories(includeInactive);
    return sendSuccess(res, { categories }, 200);
  } catch (error) {
    next(error);
  }
}

async function createCategory(req, res, next) {
  try {
    const { name, sortOrder } = req.body;
    const category = await menuService.createCategory({ name, sortOrder }, req.user);
    return sendSuccess(res, { category }, 201);
  } catch (error) {
    next(error);
  }
}

async function updateCategory(req, res, next) {
  try {
    const { id } = req.params;
    const category = await menuService.updateCategory(id, req.body, req.user);
    return sendSuccess(res, { category }, 200);
  } catch (error) {
    next(error);
  }
}

async function getAddons(req, res, next) {
  try {
    const includeInactive = req.query.all === 'true';
    const addons = await menuService.getAddons(includeInactive);
    return sendSuccess(res, { addons }, 200);
  } catch (error) {
    next(error);
  }
}

async function createAddon(req, res, next) {
  try {
    const addon = await menuService.createAddon(req.body, req.user);
    return sendSuccess(res, { addon }, 201);
  } catch (error) {
    next(error);
  }
}

async function getProducts(req, res, next) {
  try {
    const { categoryId, available, includeArchived } = req.query;
    const products = await menuService.getProducts({
      categoryId,
      available,
      includeArchived: includeArchived === 'true',
    });
    return sendSuccess(res, { products }, 200);
  } catch (error) {
    next(error);
  }
}

async function getProductById(req, res, next) {
  try {
    const { id } = req.params;
    const product = await menuService.getProductById(id);
    return sendSuccess(res, { product }, 200);
  } catch (error) {
    next(error);
  }
}

async function createProduct(req, res, next) {
  try {
    const product = await menuService.createProduct(req.body, req.user);
    return sendSuccess(res, { product }, 201);
  } catch (error) {
    next(error);
  }
}

async function updateProduct(req, res, next) {
  try {
    const { id } = req.params;
    const product = await menuService.updateProduct(id, req.body, req.user);
    return sendSuccess(res, { product }, 200);
  } catch (error) {
    next(error);
  }
}

async function archiveProduct(req, res, next) {
  try {
    const { id } = req.params;
    const result = await menuService.archiveProduct(id, req.user);
    return sendSuccess(res, result, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getCategories,
  createCategory,
  updateCategory,
  getAddons,
  createAddon,
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  archiveProduct,
};
