const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');
const { authenticate } = require('../middleware/auth');
const { requireStaffOrOwner } = require('../middleware/roleGuard');

router.get('/', authenticate, requireStaffOrOwner, inventoryController.getInventory);
router.get('/adjustments', authenticate, requireStaffOrOwner, inventoryController.getAdjustmentHistory);
router.get('/:productId', authenticate, requireStaffOrOwner, inventoryController.getProductInventory);
router.patch('/:productId', authenticate, requireStaffOrOwner, inventoryController.adjustInventory);

module.exports = router;
