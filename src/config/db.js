const mysql = require('mysql2/promise');
const config = require('./env');

function createDatabasePool() {
  // If a full connection URL is provided (Railway DATABASE_URL / MYSQL_URL)
  if (config.DB.URL) {
    console.log('[Database] Initializing MySQL pool using connection URL...');
    return mysql.createPool({
      uri: config.DB.URL,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      decimalNumbers: true,
      timezone: 'Z',
      connectTimeout: 15000,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10000,
      ssl: config.DB.URL.includes('proxy.rlwy.net') ? { rejectUnauthorized: false } : undefined,
    });
  }

  // Otherwise initialize using individual parameters
  console.log(`[Database] Initializing MySQL pool using [${config.DB.HOST}:${config.DB.PORT}/${config.DB.NAME}]...`);
  return mysql.createPool({
    host: config.DB.HOST,
    port: config.DB.PORT,
    user: config.DB.USER,
    password: config.DB.PASSWORD,
    database: config.DB.NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    decimalNumbers: true,
    timezone: 'Z',
    connectTimeout: 15000,
    enableKeepAlive: true,
    keepAliveInitialDelay: 10000,
    ssl: config.DB.HOST.includes('proxy.rlwy.net') ? { rejectUnauthorized: false } : undefined,
  });
}

const pool = createDatabasePool();
let dbConnected = false;

// Helper to test database connection with logging
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    dbConnected = true;
    console.log(`[Database] ✅ Connected & pinged successfully [${config.DB.HOST}:${config.DB.PORT}/${config.DB.NAME}]`);
    return true;
  } catch (error) {
    console.error(`[Database] ⚠️ Connection test failed: ${error.message}`);
    dbConnected = false;
    return false;
  }
}

function isDatabaseReady() {
  return dbConnected;
}

module.exports = {
  pool,
  testConnection,
  isDatabaseReady,
};
