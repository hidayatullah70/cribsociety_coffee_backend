const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const { generateId } = require('../utils/idGenerator');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const ROLES = require('../constants/roles');
const { recordAuditLog } = require('../utils/auditLogger');

async function getAllStaff() {
  const [rows] = await pool.query(
    'SELECT id, name, email, role, is_active AS isActive, created_at AS createdAt, updated_at AS updatedAt FROM users ORDER BY created_at ASC'
  );
  return rows.map(r => ({
    ...r,
    isActive: Boolean(r.isActive),
  }));
}

async function getStaffById(id) {
  const [rows] = await pool.query(
    'SELECT id, name, email, role, is_active AS isActive, created_at AS createdAt, updated_at AS updatedAt FROM users WHERE id = ?',
    [id]
  );
  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Staff with ID ${id} not found`);
  }
  const r = rows[0];
  return {
    ...r,
    isActive: Boolean(r.isActive),
  };
}

async function createStaff({ name, email, password, role = ROLES.STAFF }, user) {
  if (!name || !email || !password) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Name, email, and password are required');
  }

  const cleanEmail = email.toLowerCase().trim();

  // Check unique email
  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [cleanEmail]);
  if (existing.length > 0) {
    throw new ApiError(409, ERROR_CODES.CONFLICT, 'A user with this email address already exists');
  }

  const id = generateId('usr');
  const passwordHash = await bcrypt.hash(password, 10);
  const userRole = role === ROLES.OWNER ? ROLES.OWNER : ROLES.STAFF;

  await pool.query(
    `INSERT INTO users (id, name, email, password_hash, role, is_active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, TRUE, NOW(), NOW())`,
    [id, name.trim(), cleanEmail, passwordHash, userRole]
  );

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'CREATE_STAFF',
    entityType: 'users',
    entityId: id,
    metadata: { name, email: cleanEmail, role: userRole },
  });

  return getStaffById(id);
}

async function updateStaff(id, updateData, user) {
  await getStaffById(id);

  const { name, email, password, role, isActive } = updateData;

  const updates = [];
  const values = [];

  if (name !== undefined && name.trim()) {
    updates.push('name = ?');
    values.push(name.trim());
  }

  if (email !== undefined && email.trim()) {
    const cleanEmail = email.toLowerCase().trim();
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ? AND id != ?', [cleanEmail, id]);
    if (existing.length > 0) {
      throw new ApiError(409, ERROR_CODES.CONFLICT, 'Email is already in use by another user');
    }
    updates.push('email = ?');
    values.push(cleanEmail);
  }

  if (password !== undefined && password.length >= 6) {
    const passwordHash = await bcrypt.hash(password, 10);
    updates.push('password_hash = ?');
    values.push(passwordHash);
  }

  if (role !== undefined && (role === ROLES.OWNER || role === ROLES.STAFF)) {
    updates.push('role = ?');
    values.push(role);
  }

  if (isActive !== undefined) {
    updates.push('is_active = ?');
    values.push(Boolean(isActive));
  }

  if (updates.length === 0) {
    return getStaffById(id);
  }

  values.push(id);
  await pool.query(`UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ?`, values);

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'UPDATE_STAFF',
    entityType: 'users',
    entityId: id,
    metadata: updateData,
  });

  return getStaffById(id);
}

module.exports = {
  getAllStaff,
  getStaffById,
  createStaff,
  updateStaff,
};
