const { pool } = require('../config/db');
const { generateId } = require('./idGenerator');

/**
 * Record an audit log entry
 * @param {Object} connection - Optional MySQL connection (for transactions)
 * @param {Object} params - Log parameters
 */
async function recordAuditLog(connectionOrNull, { actorUserId, action, entityType, entityId, metadata }) {
  const db = connectionOrNull || pool;
  const id = generateId('aud');
  const metadataJson = metadata ? JSON.stringify(metadata) : null;

  try {
    await db.query(
      `INSERT INTO audit_logs (id, actor_user_id, action, entity_type, entity_id, metadata, created_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [id, actorUserId || null, action, entityType, entityId, metadataJson]
    );
  } catch (err) {
    // Audit logs should fail gracefully without crashing primary operations if non-fatal
    console.error('[AuditLogger] Failed to write audit log:', err.message);
  }
}

module.exports = {
  recordAuditLog,
};
