const ERROR_CODES = require('../constants/errorCodes');

class ApiError extends Error {
  constructor(statusCode, code, message, details = {}) {
    super(message);
    this.statusCode = statusCode;
    this.code = code || ERROR_CODES.INTERNAL_SERVER_ERROR;
    this.details = details;
  }
}

/**
 * Send standard success JSON response
 */
function sendSuccess(res, data, statusCode = 200, meta = null) {
  if (meta) {
    return res.status(statusCode).json({ data, meta });
  }
  return res.status(statusCode).json(data);
}

/**
 * Send standard error JSON envelope matching API-SPEC.md
 */
function sendError(res, statusCode, code, message, details = {}) {
  return res.status(statusCode).json({
    error: {
      code,
      message,
      details,
    },
  });
}

module.exports = {
  ApiError,
  sendSuccess,
  sendError,
};
