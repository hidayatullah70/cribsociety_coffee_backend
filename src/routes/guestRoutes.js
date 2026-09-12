const express = require('express');
const router = express.Router();
const guestController = require('../controllers/guestController');

router.get('/menu', guestController.getPublicMenu);
router.get('/queue', guestController.getLiveQueue);
router.get('/track/:orderNumber', guestController.trackOrder);

module.exports = router;
