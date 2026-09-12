const { verifyToken } = require('../utils/jwt');
const { pool } = require('../config/db');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Authentication token required');
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Session token has expired, please log in again');
      }
      throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Invalid authentication token');
    }

    // Retrieve user from DB to verify user is active
    const [rows] = await pool.query(
      'SELECT id, name, email, role, is_active FROM users WHERE id = ?',
      [decoded.id]
    );

    if (rows.length === 0) {
      throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'User no longer exists');
    }

    const user = rows[0];
    if (!user.is_active) {
      throw new ApiError(403, ERROR_CODES.FORBIDDEN, 'User account is inactive');
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
}

// Optional authentication (attaches user if token present, does not fail if absent)
async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = verifyToken(token);
        const [rows] = await pool.query(
          'SELECT id, name, email, role, is_active FROM users WHERE id = ?',
          [decoded.id]
        );
        if (rows.length > 0 && rows[0].is_active) {
          req.user = rows[0];
        }
      } catch (e) {
        // Ignore invalid token in optional auth
      }
    }
    next();
  } catch (error) {
    next(error);
  }
}

module.exports = {
  authenticate,
  optionalAuth,
};
