const app = require('./app');
const config = require('./config/env');
const { testConnection, pool } = require('./config/db');
const initDatabase = require('./scripts/initDb');

async function startServer() {
  console.log('====================================================');
  console.log('  Crib Society Coffee — REST API Backend Server');
  console.log('====================================================');

  const isDbConnected = await testConnection();
  if (!isDbConnected) {
    console.warn('[Warning] MySQL connection could not be established immediately. Verify your DB environment variables (DATABASE_URL / MYSQLHOST).');
  } else {
    // Auto-initialize tables and seeds if not already created
    try {
      const [tables] = await pool.query("SHOW TABLES LIKE 'users'");
      if (tables.length === 0) {
        console.log('[Server] Database tables not found. Automatically running schema & seeds initialization...');
        await initDatabase();
      } else {
        console.log('[Server] Database schema is verified and ready.');
      }
    } catch (err) {
      console.warn('[Server] Auto-schema check notice:', err.message);
    }
  }

  const server = app.listen(config.PORT, () => {
    console.log(`[Server] Running in ${config.NODE_ENV} mode`);
    console.log(`[Server] Listening on http://localhost:${config.PORT}`);
    console.log(`[Server] API Base: http://localhost:${config.PORT}${config.API_PREFIX}`);
    console.log(`[Server] Healthcheck: http://localhost:${config.PORT}${config.API_PREFIX}/health`);
  });

  // Graceful shutdown handling
  const shutdown = () => {
    console.log('\n[Server] Gracefully shutting down...');
    server.close(() => {
      console.log('[Server] HTTP server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

startServer();
