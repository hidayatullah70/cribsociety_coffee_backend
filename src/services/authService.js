const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const { signToken } = require('../utils/jwt');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const config = require('../config/env');
const { recordAuditLog } = require('../utils/auditLogger');

async function login({ email, password }) {
  if (!email || !password) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Email and password are required');
  }

  const [rows] = await pool.query(
    'SELECT id, name, email, password_hash, role, is_active FROM users WHERE email = ?',
    [email.toLowerCase().trim()]
  );

  if (rows.length === 0) {
    throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Invalid email or password');
  }

  const user = rows[0];

  if (!user.is_active) {
    throw new ApiError(403, ERROR_CODES.FORBIDDEN, 'Your account is currently disabled');
  }

  const isPasswordValid = await bcrypt.compare(password, user.password_hash);
  if (!isPasswordValid) {
    throw new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Invalid email or password');
  }

  const tokenPayload = {
    id: user.id,
    role: user.role,
    email: user.email,
  };

  const token = signToken(tokenPayload);

  // Calculate expiration date
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  await recordAuditLog(null, {
    actorUserId: user.id,
    action: 'USER_LOGIN',
    entityType: 'users',
    entityId: user.id,
    metadata: { email: user.email, role: user.role },
  });

  return {
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
    session: {
      token,
      expiresAt,
    },
  };
}

async function getMe(userId) {
  const [rows] = await pool.query(
    'SELECT id, name, email, role, is_active, created_at, updated_at FROM users WHERE id = ?',
    [userId]
  );

  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, 'User not found');
  }

  return rows[0];
}

module.exports = {
  login,
  getMe,
};
