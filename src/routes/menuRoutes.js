const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { requireOwner } = require('../middleware/roleGuard');

// Categories
router.get('/categories', optionalAuth, menuController.getCategories);
router.post('/categories', authenticate, requireOwner, menuController.createCategory);
router.patch('/categories/:id', authenticate, requireOwner, menuController.updateCategory);

// Addons
router.get('/addons', optionalAuth, menuController.getAddons);
router.post('/addons', authenticate, requireOwner, menuController.createAddon);

// Products
router.get('/products', optionalAuth, menuController.getProducts);
router.get('/products/:id', optionalAuth, menuController.getProductById);
router.post('/products', authenticate, requireOwner, menuController.createProduct);
router.patch('/products/:id', authenticate, requireOwner, menuController.updateProduct);
router.delete('/products/:id', authenticate, requireOwner, menuController.archiveProduct);

module.exports = router;
