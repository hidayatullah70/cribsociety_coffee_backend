const mysql = require('mysql2/promise');
const config = require('./env');

const poolConfig = config.DB.URL
  ? {
      uri: config.DB.URL,
      waitForConnections: true,
      connectionLimit: 15,
      queueLimit: 0,
      decimalNumbers: true,
      timezone: 'Z',
    }
  : {
      host: config.DB.HOST,
      port: config.DB.PORT,
      user: config.DB.USER,
      password: config.DB.PASSWORD,
      database: config.DB.NAME,
      waitForConnections: true,
      connectionLimit: 15,
      queueLimit: 0,
      decimalNumbers: true,
      timezone: 'Z',
    };

const pool = mysql.createPool(poolConfig);

// Helper to test database connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[Database] Connected successfully to MySQL database: ${config.DB.NAME}`);
    connection.release();
    return true;
  } catch (error) {
    console.error('[Database] Connection failed:', error.message);
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};
