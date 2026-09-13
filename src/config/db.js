const mysql = require('mysql2/promise');
const config = require('./env');

const pool = mysql.createPool({
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
  connectTimeout: 10000,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
});

let dbConnected = false;

// Helper to test database connection with logging
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[Database] ✅ Connected successfully to MySQL [${config.DB.HOST}:${config.DB.PORT}/${config.DB.NAME}]`);
    connection.release();
    dbConnected = true;
    return true;
  } catch (error) {
    console.error(`[Database] ⚠️ Connection to MySQL [${config.DB.HOST}:${config.DB.PORT}/${config.DB.NAME}] failed: ${error.message}`);
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
