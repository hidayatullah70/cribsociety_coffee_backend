const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT || '5000', 10),
  API_PREFIX: process.env.API_PREFIX || '/api/v1',
  DB: {
    HOST: process.env.DB_HOST || process.env.MYSQLHOST || 'localhost',
    PORT: parseInt(process.env.DB_PORT || process.env.MYSQLPORT || '3306', 10),
    USER: process.env.DB_USER || process.env.MYSQLUSER || 'root',
    PASSWORD: process.env.DB_PASSWORD !== undefined ? process.env.DB_PASSWORD : (process.env.MYSQLPASSWORD !== undefined ? process.env.MYSQLPASSWORD : ''),
    NAME: process.env.DB_NAME || process.env.MYSQLDATABASE || 'railway',
    URL: process.env.DATABASE_URL || process.env.MYSQL_URL || null,
  },
  JWT: {
    SECRET: process.env.JWT_SECRET || 'cribsociety_super_secret_jwt_key_2026_production_ready',
    EXPIRES_IN: process.env.JWT_EXPIRES_IN || '1d',
  },
  CORS_ORIGIN: process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',').map(item => item.trim())
    : ['http://localhost:5173', 'http://localhost:3000', 'http://127.0.0.1:5173'],
};
