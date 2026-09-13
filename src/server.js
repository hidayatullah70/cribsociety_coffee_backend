const app = require('./app');
const config = require('./config/env');
const { testConnection, pool } = require('./config/db');
const initDatabase = require('./scripts/initDb');

// Asynchronous DB initialization worker with retry logic
async function bootstrapDatabase(maxRetries = 10, delayMs = 3000) {
  let attempt = 0;
  while (attempt < maxRetries) {
    attempt++;
    console.log(`[Database Bootstrap] Connecting to database (Attempt ${attempt}/${maxRetries})...`);
    
    const isConnected = await testConnection();
    if (isConnected) {
      try {
        const [tables] = await pool.query("SHOW TABLES LIKE 'users'");
        if (tables.length === 0) {
          console.log('[Database Bootstrap] Tables not found. Auto-running schema & seed initialization...');
          await initDatabase();
        } else {
          console.log('[Database Bootstrap] ✅ Database schema verified and active.');
        }
        return true;
      } catch (err) {
        console.warn('[Database Bootstrap] Schema verification notice:', err.message);
      }
      return true;
    }

    if (attempt < maxRetries) {
      console.log(`[Database Bootstrap] Retrying in ${delayMs / 1000}s...`);
      await new Promise(res => setTimeout(res, delayMs));
    }
  }

  console.warn('[Database Bootstrap] ⚠️ Database could not be reached after maximum retries. The server will keep running and retry on incoming requests.');
  return false;
}

function startServer() {
  console.log('====================================================');
  console.log('  Crib Society Coffee — REST API Backend Server');
  console.log('====================================================');

  // 1. Start HTTP Server immediately on 0.0.0.0 to satisfy Railway port health checks
  const server = app.listen(config.PORT, '0.0.0.0', () => {
    console.log(`[Server] ✅ Server running in ${config.NODE_ENV} mode`);
    console.log(`[Server] 🚀 Listening on 0.0.0.0:${config.PORT}`);
    console.log(`[Server] 🌐 API Base: ${config.API_PREFIX}`);
    console.log(`[Server] 🩺 Healthcheck: ${config.API_PREFIX}/health`);

    // 2. Run Database connection & auto-migration asynchronously in background
    bootstrapDatabase().catch(err => {
      console.error('[Database Bootstrap] Unhandled bootstrap error:', err.message);
    });
  });

  // Graceful shutdown handling
  const shutdown = (signal) => {
    console.log(`\n[Server] Received ${signal}. Gracefully shutting down...`);
    server.close(() => {
      console.log('[Server] HTTP server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

startServer();
