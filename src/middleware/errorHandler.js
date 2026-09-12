const { sendError, ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const config = require('../config/env');

function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  // Handle known ApiError
  if (err instanceof ApiError) {
    return sendError(res, err.statusCode, err.code, err.message, err.details);
  }

  // Handle JSON parse error
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return sendError(res, 400, ERROR_CODES.BAD_REQUEST, 'Invalid JSON body format');
  }

  // Handle MySQL errors
  if (err.code === 'ER_DUP_ENTRY') {
    return sendError(res, 409, ERROR_CODES.CONFLICT, 'Duplicate entry: A record with this unique value already exists');
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2' || err.code === 'ER_ROW_IS_REFERENCED_2') {
    return sendError(res, 400, ERROR_CODES.BAD_REQUEST, 'Foreign key constraint violated');
  }

  // Generic internal server error
  console.error('[Unhandled Error]', err);

  const message = config.NODE_ENV === 'production' 
    ? 'An unexpected error occurred on the server' 
    : err.message;

  const details = config.NODE_ENV === 'development' ? { stack: err.stack } : {};

  return sendError(res, 500, ERROR_CODES.INTERNAL_SERVER_ERROR, message, details);
}

module.exports = errorHandler;
