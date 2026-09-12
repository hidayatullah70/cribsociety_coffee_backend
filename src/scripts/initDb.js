const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../config/env');

async function initDatabase() {
  console.log('[DB Init] Starting database initialization...');
  console.log(`[DB Init] Connecting to MySQL at ${config.DB.HOST}:${config.DB.PORT} with user "${config.DB.USER}"...`);

  let connection;
  try {
    // Connect with URI or parameters
    const connectionConfig = config.DB.URL
      ? { uri: config.DB.URL, multipleStatements: true }
      : {
          host: config.DB.HOST,
          port: config.DB.PORT,
          user: config.DB.USER,
          password: config.DB.PASSWORD,
          multipleStatements: true,
        };

    connection = await mysql.createConnection(connectionConfig);

    const sqlFilePath = path.resolve(__dirname, '../../database/database.sql');
    if (!fs.existsSync(sqlFilePath)) {
      throw new Error(`database.sql file not found at ${sqlFilePath}`);
    }

    let sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

    // If a custom DB name is used (e.g. Railway's default 'railway' or custom name)
    const targetDb = config.DB.NAME || 'railway';
    if (targetDb !== 'railway') {
      sqlContent = sqlContent.replace(/`railway`/g, `\`${targetDb}\``);
    }

    console.log(`[DB Init] Executing schema and seeds for database "${targetDb}"...`);
    await connection.query(sqlContent);

    console.log(`✅ [DB Init] Database "${targetDb}" schema and seeds initialized successfully!`);
  } catch (error) {
    console.error('❌ [DB Init] Failed to initialize database:', error.message);
    if (require.main === module) {
      process.exit(1);
    }
    throw error;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

if (require.main === module) {
  initDatabase();
}

module.exports = initDatabase;
