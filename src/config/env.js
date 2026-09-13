const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

// Detect any MySQL URL from Railway / cloud providers
const rawDbUrl = process.env.DATABASE_URL 
  || process.env.MYSQL_URL 
  || process.env.MYSQL_PRIVATE_URL 
  || process.env.MYSQL_PUBLIC_URL 
  || null;

let parsedFromUrl = {};
if (rawDbUrl) {
  try {
    const parsed = new URL(rawDbUrl);
    parsedFromUrl = {
      host: parsed.hostname,
      port: parseInt(parsed.port || '3306', 10),
      user: decodeURIComponent(parsed.username || 'root'),
      password: decodeURIComponent(parsed.password || ''),
      database: parsed.pathname ? parsed.pathname.replace(/^\//, '') : 'railway',
    };
  } catch (e) {
    // If URL parsing fails, ignore and use fallbacks
  }
}

const host = process.env.DB_HOST 
  || process.env.MYSQLHOST 
  || process.env.MYSQL_HOST 
  || parsedFromUrl.host 
  || 'localhost';

const port = parseInt(
  process.env.DB_PORT 
  || process.env.MYSQLPORT 
  || process.env.MYSQL_PORT 
  || parsedFromUrl.port 
  || '3306',
  10
);

const user = process.env.DB_USER 
  || process.env.MYSQLUSER 
  || process.env.MYSQL_USER 
  || parsedFromUrl.user 
  || 'root';

const password = process.env.DB_PASSWORD !== undefined 
  ? process.env.DB_PASSWORD 
  : (process.env.MYSQLPASSWORD !== undefined 
      ? process.env.MYSQLPASSWORD 
      : (process.env.MYSQL_PASSWORD !== undefined 
          ? process.env.MYSQL_PASSWORD 
          : (process.env.MYSQL_ROOT_PASSWORD !== undefined 
              ? process.env.MYSQL_ROOT_PASSWORD 
              : (parsedFromUrl.password !== undefined ? parsedFromUrl.password : ''))));

const database = process.env.DB_NAME 
  || process.env.MYSQLDATABASE 
  || process.env.MYSQL_DATABASE 
  || parsedFromUrl.database 
  || 'railway';

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT || '5000', 10),
  API_PREFIX: process.env.API_PREFIX || '/api/v1',
  DB: {
    HOST: host,
    PORT: port,
    USER: user,
    PASSWORD: password,
    NAME: database,
    URL: rawDbUrl,
  },
  JWT: {
    SECRET: process.env.JWT_SECRET || 'cribsociety_super_secret_jwt_key_2026_production_ready',
    EXPIRES_IN: process.env.JWT_EXPIRES_IN || '1d',
  },
  CORS_ORIGIN: process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',').map(item => item.trim())
    : ['http://localhost:5173', 'http://localhost:3000', 'http://127.0.0.1:5173'],
};
