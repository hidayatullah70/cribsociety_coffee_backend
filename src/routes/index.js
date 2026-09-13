const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const menuRoutes = require('./menuRoutes');
const orderRoutes = require('./orderRoutes');
const paymentRoutes = require('./paymentRoutes');
const inventoryRoutes = require('./inventoryRoutes');
const dashboardRoutes = require('./dashboardRoutes');
const staffRoutes = require('./staffRoutes');
const guestRoutes = require('./guestRoutes');

const { isDatabaseReady, testConnection } = require('../config/db');

const initDatabase = require('../scripts/initDb');

// API Healthcheck
router.get('/health', async (req, res) => {
  let isReady = isDatabaseReady();
  if (!isReady) {
    isReady = await testConnection();
  }

  res.status(200).json({
    status: 'UP',
    name: 'Crib Society Coffee API',
    version: '1.0.0',
    database: isReady ? 'connected' : 'connecting',
    timestamp: new Date().toISOString(),
  });
});

// Direct Web Database Initializer & Seeder
router.get('/init-db', async (req, res, next) => {
  try {
    const result = await initDatabase();
    res.status(200).json({
      success: true,
      message: 'Database schema & seeds created successfully!',
      result,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      code: error.code || 'DB_INIT_ERROR',
    });
  }
});

// Mount modules
router.use('/auth', authRoutes);
router.use('/menu', menuRoutes);
router.use('/orders', orderRoutes);
router.use('/orders', paymentRoutes);
router.use('/payments', paymentRoutes);
router.use('/inventory', inventoryRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/staff', staffRoutes);
router.use('/guest', guestRoutes);

module.exports = router;
