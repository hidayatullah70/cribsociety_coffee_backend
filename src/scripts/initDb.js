const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const config = require('../config/env');

async function initDatabase() {
  console.log('[DB Init] Starting database schema & seed initialization...');

  let connection;
  try {
    if (config.DB.URL) {
      console.log(`[DB Init] Connecting via DATABASE_URL...`);
      connection = await mysql.createConnection({
        uri: config.DB.URL,
        multipleStatements: true,
        connectTimeout: 15000,
        ssl: config.DB.URL.includes('proxy.rlwy.net') ? { rejectUnauthorized: false } : undefined,
      });
    } else {
      console.log(`[DB Init] Connecting to MySQL at ${config.DB.HOST}:${config.DB.PORT} with user "${config.DB.USER}"...`);
      try {
        connection = await mysql.createConnection({
          host: config.DB.HOST,
          port: config.DB.PORT,
          user: config.DB.USER,
          password: config.DB.PASSWORD,
          database: config.DB.NAME,
          multipleStatements: true,
          connectTimeout: 15000,
          ssl: config.DB.HOST.includes('proxy.rlwy.net') ? { rejectUnauthorized: false } : undefined,
        });
      } catch (err) {
        connection = await mysql.createConnection({
          host: config.DB.HOST,
          port: config.DB.PORT,
          user: config.DB.USER,
          password: config.DB.PASSWORD,
          multipleStatements: true,
          connectTimeout: 15000,
        });
      }
    }

    const sqlFilePath = path.resolve(__dirname, '../../database/database.sql');
    if (!fs.existsSync(sqlFilePath)) {
      throw new Error(`database.sql file not found at ${sqlFilePath}`);
    }

    let sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

    const targetDb = config.DB.NAME || 'railway';
    if (targetDb !== 'railway') {
      sqlContent = sqlContent.replace(/`railway`/g, `\`${targetDb}\``);
    }

    console.log(`[DB Init] Executing schema and seeds for database "${targetDb}"...`);
    
    // Execute SQL script
    await connection.query(sqlContent);

    console.log(`✅ [DB Init] Database "${targetDb}" schema and seeds initialized successfully!`);
    return { success: true, database: targetDb };
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
