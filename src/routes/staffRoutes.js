const express = require('express');
const router = express.Router();
const staffController = require('../controllers/staffController');
const { authenticate } = require('../middleware/auth');
const { requireOwner } = require('../middleware/roleGuard');

// Staff management is Owner-only
router.get('/', authenticate, requireOwner, staffController.getAllStaff);
router.post('/', authenticate, requireOwner, staffController.createStaff);
router.get('/:id', authenticate, requireOwner, staffController.getStaffById);
router.patch('/:id', authenticate, requireOwner, staffController.updateStaff);

module.exports = router;
