const express = require('express');
const cors = require('cors');
const config = require('./config/env');
const requestLogger = require('./middleware/requestLogger');
const errorHandler = require('./middleware/errorHandler');
const routes = require('./routes');
const { sendError } = require('./utils/response');
const ERROR_CODES = require('./constants/errorCodes');

const app = express();

// 1. Global Middleware
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps, curl, postman) or any origin in development
    if (!origin || config.NODE_ENV === 'development' || config.CORS_ORIGIN.includes(origin) || origin.includes('hoppscotch.io')) {
      return callback(null, true);
    }
    return callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// 2. Root ping
app.get('/', (req, res) => {
  res.json({
    name: 'Crib Society Coffee REST API',
    status: 'online',
    documentation: `${config.API_PREFIX}/health`,
  });
});

// 3. API Base Routes
app.use(config.API_PREFIX, routes);

// 4. 404 Fallback
app.use((req, res) => {
  sendError(
    res,
    404,
    ERROR_CODES.RESOURCE_NOT_FOUND,
    `Route ${req.method} ${req.originalUrl} not found`
  );
});

// 5. Global Error Handling
app.use(errorHandler);

module.exports = app;
