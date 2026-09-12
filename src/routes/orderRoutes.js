const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { requireStaffOrOwner } = require('../middleware/roleGuard');

// Live queue status (Public or authenticated)
router.get('/queue', orderController.getLiveQueue);

// Track order by #CSC-xxxx
router.get('/track/:orderNumber', orderController.trackOrder);

// Order CRUD / Management (POS & Staff)
router.post('/', authenticate, requireStaffOrOwner, orderController.createOrder);
router.get('/', authenticate, requireStaffOrOwner, orderController.getOrders);
router.get('/:id', authenticate, requireStaffOrOwner, orderController.getOrderById);
router.patch('/:id/status', authenticate, requireStaffOrOwner, orderController.updateOrderStatus);

module.exports = router;
