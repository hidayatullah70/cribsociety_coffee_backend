const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/auth');
const { requireStaffOrOwner } = require('../middleware/roleGuard');

// Process payment for order
router.post('/:id/payment', authenticate, requireStaffOrOwner, paymentController.processPayment);
router.post('/order/:id', authenticate, requireStaffOrOwner, paymentController.processPayment);

module.exports = router;
