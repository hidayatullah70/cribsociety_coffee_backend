const { pool } = require('../config/db');
const { generateId } = require('../utils/idGenerator');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const { recordAuditLog } = require('../utils/auditLogger');

async function getInventory() {
  const [rows] = await pool.query(`
    SELECT 
      p.id AS productId,
      p.name AS productName,
      c.name AS categoryName,
      p.price,
      p.available,
      p.low_stock_threshold AS lowStockThreshold,
      COALESCE(i.quantity, 0) AS quantity,
      CASE 
        WHEN COALESCE(i.quantity, 0) <= COALESCE(p.low_stock_threshold, 5) THEN TRUE 
        ELSE FALSE 
      END AS isLowStock,
      i.updated_at AS lastUpdated
    FROM products p
    JOIN categories c ON p.category_id = c.id
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE p.is_archived = FALSE
    ORDER BY isLowStock DESC, c.sort_order ASC, p.name ASC
  `);

  return rows.map(r => ({
    productId: r.productId,
    productName: r.productName,
    categoryName: r.categoryName,
    price: Number(r.price),
    available: Boolean(r.available),
    lowStockThreshold: r.lowStockThreshold !== null ? Number(r.lowStockThreshold) : 5,
    quantity: Number(r.quantity),
    isLowStock: Boolean(r.isLowStock),
    lastUpdated: r.lastUpdated,
  }));
}

async function getProductInventory(productId) {
  const [rows] = await pool.query(
    `SELECT 
       p.id AS productId,
       p.name AS productName,
       c.name AS categoryName,
       p.price,
       p.available,
       p.low_stock_threshold AS lowStockThreshold,
       COALESCE(i.quantity, 0) AS quantity,
       CASE 
         WHEN COALESCE(i.quantity, 0) <= COALESCE(p.low_stock_threshold, 5) THEN TRUE 
         ELSE FALSE 
       END AS isLowStock,
       i.updated_at AS lastUpdated
     FROM products p
     JOIN categories c ON p.category_id = c.id
     LEFT JOIN inventory i ON p.id = i.product_id
     WHERE p.id = ?`,
    [productId]
  );

  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Product inventory with ID ${productId} not found`);
  }

  const r = rows[0];
  return {
    productId: r.productId,
    productName: r.productName,
    categoryName: r.categoryName,
    price: Number(r.price),
    available: Boolean(r.available),
    lowStockThreshold: r.lowStockThreshold !== null ? Number(r.lowStockThreshold) : 5,
    quantity: Number(r.quantity),
    isLowStock: Boolean(r.isLowStock),
    lastUpdated: r.lastUpdated,
  };
}

async function adjustInventory(productId, { quantity, adjustmentQuantity, available, reason }, user) {
  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const [invRows] = await connection.query(
      `SELECT p.id, p.name, p.available, COALESCE(i.quantity, 0) AS currentStock
       FROM products p
       LEFT JOIN inventory i ON p.id = i.product_id
       WHERE p.id = ? FOR UPDATE`,
      [productId]
    );

    if (invRows.length === 0) {
      throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Product with ID ${productId} not found`);
    }

    const currentStock = Number(invRows[0].currentStock);
    let targetStock;
    let adjQty;

    if (quantity !== undefined) {
      targetStock = parseInt(quantity, 10);
      if (isNaN(targetStock) || targetStock < 0) {
        throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Stock quantity cannot be negative');
      }
      adjQty = targetStock - currentStock;
    } else if (adjustmentQuantity !== undefined) {
      adjQty = parseInt(adjustmentQuantity, 10);
      if (isNaN(adjQty)) {
        throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Invalid adjustment quantity');
      }
      targetStock = currentStock + adjQty;
      if (targetStock < 0) {
        throw new ApiError(400, ERROR_CODES.INSUFFICIENT_STOCK, 'Stock quantity cannot become negative');
      }
    } else {
      targetStock = currentStock;
      adjQty = 0;
    }

    // 1. Update inventory
    await connection.query(
      `INSERT INTO inventory (product_id, quantity, updated_at)
       VALUES (?, ?, NOW())
       ON DUPLICATE KEY UPDATE quantity = ?, updated_at = NOW()`,
      [productId, targetStock, targetStock]
    );

    // 2. Update product availability if requested or auto-adjust
    if (available !== undefined) {
      await connection.query('UPDATE products SET available = ? WHERE id = ?', [Boolean(available), productId]);
    } else if (targetStock === 0) {
      await connection.query('UPDATE products SET available = FALSE WHERE id = ?', [productId]);
    } else if (targetStock > 0 && !invRows[0].available) {
      await connection.query('UPDATE products SET available = TRUE WHERE id = ?', [productId]);
    }

    // 3. Record append-only adjustment history
    if (adjQty !== 0) {
      const adjId = generateId('adj');
      await connection.query(
        `INSERT INTO inventory_adjustments 
         (id, product_id, actor_user_id, previous_quantity, adjustment_quantity, resulting_quantity, reason, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          adjId,
          productId,
          user ? user.id : 'usr_owner_01',
          currentStock,
          adjQty,
          targetStock,
          reason || 'Manual inventory adjustment',
        ]
      );
    }

    // 4. Audit log
    await recordAuditLog(connection, {
      actorUserId: user ? user.id : null,
      action: 'ADJUST_INVENTORY',
      entityType: 'inventory',
      entityId: productId,
      metadata: {
        productName: invRows[0].name,
        previousQuantity: currentStock,
        adjustmentQuantity: adjQty,
        resultingQuantity: targetStock,
        reason,
      },
    });

    await connection.commit();
    connection.release();

    return getProductInventory(productId);
  } catch (err) {
    await connection.rollback();
    connection.release();
    throw err;
  }
}

async function getAdjustmentHistory({ productId, page = 1, limit = 20 }) {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  let whereClause = '1=1';
  const values = [];

  if (productId) {
    whereClause += ' AND a.product_id = ?';
    values.push(productId);
  }

  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS total FROM inventory_adjustments a WHERE ${whereClause}`,
    values
  );
  const totalCount = countRows[0].total;

  const [rows] = await pool.query(
    `SELECT 
       a.id,
       a.product_id AS productId,
       p.name AS productName,
       a.actor_user_id AS actorUserId,
       u.name AS actorName,
       a.previous_quantity AS previousQuantity,
       a.adjustment_quantity AS adjustmentQuantity,
       a.resulting_quantity AS resultingQuantity,
       a.reason,
       a.created_at AS createdAt
     FROM inventory_adjustments a
     JOIN products p ON a.product_id = p.id
     JOIN users u ON a.actor_user_id = u.id
     WHERE ${whereClause}
     ORDER BY a.created_at DESC
     LIMIT ? OFFSET ?`,
    [...values, limitNum, offset]
  );

  return {
    adjustments: rows.map(r => ({
      id: r.id,
      productId: r.productId,
      productName: r.productName,
      actor: { id: r.actorUserId, name: r.actorName },
      previousQuantity: Number(r.previousQuantity),
      adjustmentQuantity: Number(r.adjustmentQuantity),
      resultingQuantity: Number(r.resultingQuantity),
      reason: r.reason,
      createdAt: r.createdAt,
    })),
    pagination: {
      page: pageNum,
      limit: limitNum,
      totalCount,
      totalPages: Math.ceil(totalCount / limitNum),
    },
  };
}

module.exports = {
  getInventory,
  getProductInventory,
  adjustInventory,
  getAdjustmentHistory,
};
