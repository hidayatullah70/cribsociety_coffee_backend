const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { authenticate } = require('../middleware/auth');
const { requireStaffOrOwner } = require('../middleware/roleGuard');

router.get('/summary', authenticate, requireStaffOrOwner, dashboardController.getSummary);

module.exports = router;
