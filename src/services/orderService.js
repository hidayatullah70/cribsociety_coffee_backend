const { pool } = require('../config/db');
const { generateId, generateOrderNumber } = require('../utils/idGenerator');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const { ORDER_STATUS, isValidStatusTransition } = require('../constants/orderStatus');
const { PAYMENT_STATUS } = require('../constants/paymentStatus');
const { recordAuditLog } = require('../utils/auditLogger');

async function createOrder(orderPayload, user) {
  const { items, discount } = orderPayload;

  if (!items || !Array.isArray(items) || items.length === 0) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Order must contain at least one item');
  }

  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    let calculatedSubtotal = 0;
    const processedItems = [];

    // Process and validate each line item
    for (const item of items) {
      const { productId, quantity = 1, variantId = null, addonIds = [] } = item;

      if (!productId) {
        throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Product ID is required for each item');
      }

      const qty = parseInt(quantity, 10);
      if (isNaN(qty) || qty <= 0) {
        throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Item quantity must be a positive integer');
      }

      // Check product in DB
      const [prodRows] = await connection.query(
        `SELECT p.id, p.name, p.price, p.available, p.is_archived, COALESCE(i.quantity, 0) AS stock
         FROM products p
         LEFT JOIN inventory i ON p.id = i.product_id
         WHERE p.id = ? FOR UPDATE`,
        [productId]
      );

      if (prodRows.length === 0 || prodRows[0].is_archived) {
        throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Product with ID ${productId} not found`);
      }

      const product = prodRows[0];

      if (!product.available) {
        throw new ApiError(400, ERROR_CODES.BAD_REQUEST, `Product "${product.name}" is currently unavailable for order`);
      }

      let unitPrice = Number(product.price);
      let variantNameSnapshot = null;

      // Handle variant price delta
      if (variantId) {
        const [varRows] = await connection.query(
          'SELECT id, name, price_delta FROM product_variants WHERE id = ? AND product_id = ? AND is_active = TRUE',
          [variantId, productId]
        );

        if (varRows.length > 0) {
          variantNameSnapshot = varRows[0].name;
          unitPrice += Number(varRows[0].price_delta);
        }
      }

      // Handle addons
      const addonSnapshots = [];
      if (Array.isArray(addonIds) && addonIds.length > 0) {
        const [addonRows] = await connection.query(
          'SELECT id, name, price FROM addons WHERE id IN (?) AND is_active = TRUE',
          [addonIds]
        );

        for (const addon of addonRows) {
          unitPrice += Number(addon.price);
          addonSnapshots.push(addon.name);
        }
      }

      const lineTotal = unitPrice * qty;
      calculatedSubtotal += lineTotal;

      processedItems.push({
        id: generateId('item'),
        productId: product.id,
        productNameSnapshot: product.name,
        unitPrice,
        quantity: qty,
        lineTotal,
        variantNameSnapshot,
        addonSnapshot: addonSnapshots.length > 0 ? addonSnapshots : null,
      });
    }

    // Process discount
    let discountTotal = 0;
    let discountRecord = null;

    if (discount && typeof discount === 'object') {
      const { type, value, label } = discount;
      const numValue = Number(value) || 0;

      if (numValue > 0) {
        if (type === 'percentage') {
          discountTotal = (calculatedSubtotal * numValue) / 100;
        } else {
          discountTotal = numValue;
        }

        // Cap discount to subtotal so total cannot become negative
        if (discountTotal > calculatedSubtotal) {
          discountTotal = calculatedSubtotal;
        }

        discountRecord = {
          id: generateId('disc'),
          type: type === 'percentage' ? 'percentage' : 'fixed',
          value: numValue,
          amountApplied: discountTotal,
          label: label || 'Discount',
        };
      }
    }

    const finalTotal = Math.max(0, calculatedSubtotal - discountTotal);
    const orderId = generateId('ord');
    const orderNumber = generateOrderNumber();
    const creatorUserId = user ? user.id : 'usr_staff_01';

    // 1. Insert Order
    await connection.query(
      `INSERT INTO orders 
       (id, order_number, status, payment_status, subtotal, discount_total, total, created_by, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        orderId,
        orderNumber,
        ORDER_STATUS.PENDING,
        PAYMENT_STATUS.UNPAID,
        calculatedSubtotal,
        discountTotal,
        finalTotal,
        creatorUserId,
      ]
    );

    // 2. Insert Order Items
    for (const item of processedItems) {
      await connection.query(
        `INSERT INTO order_items 
         (id, order_id, product_id, product_name_snapshot, unit_price, quantity, line_total, variant_name_snapshot, addon_snapshot, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          item.id,
          orderId,
          item.productId,
          item.productNameSnapshot,
          item.unitPrice,
          item.quantity,
          item.lineTotal,
          item.variantNameSnapshot,
          item.addonSnapshot ? JSON.stringify(item.addonSnapshot) : null,
        ]
      );
    }

    // 3. Insert Discount if applied
    if (discountRecord) {
      await connection.query(
        `INSERT INTO discounts (id, order_id, type, value, amount_applied, label, created_at)
         VALUES (?, ?, ?, ?, ?, ?, NOW())`,
        [
          discountRecord.id,
          orderId,
          discountRecord.type,
          discountRecord.value,
          discountRecord.amountApplied,
          discountRecord.label,
        ]
      );
    }

    // 4. Record Audit Log
    await recordAuditLog(connection, {
      actorUserId: creatorUserId,
      action: 'CREATE_ORDER',
      entityType: 'orders',
      entityId: orderId,
      metadata: { orderNumber, total: finalTotal, itemsCount: processedItems.length },
    });

    await connection.commit();
    connection.release();

    return getOrderById(orderId);
  } catch (err) {
    await connection.rollback();
    connection.release();
    throw err;
  }
}

async function getOrders({ status, from, to, page = 1, limit = 20, orderNumber }) {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  let whereClauses = ['1=1'];
  const values = [];

  if (status) {
    whereClauses.push('o.status = ?');
    values.push(status);
  }

  if (orderNumber) {
    whereClauses.push('o.order_number LIKE ?');
    values.push(`%${orderNumber}%`);
  }

  if (from) {
    whereClauses.push('o.created_at >= ?');
    values.push(new Date(from));
  }

  if (to) {
    whereClauses.push('o.created_at <= ?');
    values.push(new Date(to));
  }

  const whereSql = whereClauses.join(' AND ');

  // Get total count
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS totalCount FROM orders o WHERE ${whereSql}`,
    values
  );
  const totalCount = countRows[0].totalCount;

  // Get orders list
  const [orders] = await pool.query(
    `SELECT 
       o.id, 
       o.order_number AS orderNumber, 
       o.status, 
       o.payment_status AS paymentStatus, 
       o.subtotal, 
       o.discount_total AS discountTotal, 
       o.total, 
       o.created_by AS createdBy,
       u.name AS createdByName,
       o.created_at AS createdAt, 
       o.updated_at AS updatedAt
     FROM orders o
     JOIN users u ON o.created_by = u.id
     WHERE ${whereSql}
     ORDER BY o.created_at DESC
     LIMIT ? OFFSET ?`,
    [...values, limitNum, offset]
  );

  if (orders.length === 0) {
    return {
      orders: [],
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalCount,
        totalPages: Math.ceil(totalCount / limitNum),
      },
    };
  }

  const orderIds = orders.map(o => o.id);

  // Fetch items for these orders
  const [items] = await pool.query(
    `SELECT 
       id, 
       order_id AS orderId, 
       product_id AS productId, 
       product_name_snapshot AS productName, 
       unit_price AS unitPrice, 
       quantity, 
       line_total AS lineTotal, 
       variant_name_snapshot AS variantName, 
       addon_snapshot AS addonSnapshot,
       created_at AS createdAt
     FROM order_items
     WHERE order_id IN (?)`,
    [orderIds]
  );

  // Fetch payments for these orders
  const [payments] = await pool.query(
    `SELECT id, order_id AS orderId, method, amount, status, external_reference AS externalReference, paid_at AS paidAt
     FROM payments
     WHERE order_id IN (?)`,
    [orderIds]
  );

  const itemsByOrder = {};
  items.forEach(it => {
    if (!itemsByOrder[it.orderId]) itemsByOrder[it.orderId] = [];
    itemsByOrder[it.orderId].push({
      id: it.id,
      productId: it.productId,
      name: it.productName,
      unitPrice: Number(it.unitPrice),
      quantity: it.quantity,
      lineTotal: Number(it.lineTotal),
      variantName: it.variantName,
      addons: typeof it.addonSnapshot === 'string' ? JSON.parse(it.addonSnapshot) : it.addonSnapshot,
    });
  });

  const paymentsByOrder = {};
  payments.forEach(p => {
    if (!paymentsByOrder[p.orderId]) paymentsByOrder[p.orderId] = [];
    paymentsByOrder[p.orderId].push({
      id: p.id,
      method: p.method,
      amount: Number(p.amount),
      status: p.status,
      externalReference: p.externalReference,
      paidAt: p.paidAt,
    });
  });

  const formattedOrders = orders.map(o => ({
    id: o.id,
    orderNumber: o.orderNumber,
    status: o.status,
    paymentStatus: o.paymentStatus,
    subtotal: Number(o.subtotal),
    discountTotal: Number(o.discountTotal),
    total: Number(o.total),
    createdBy: {
      id: o.createdBy,
      name: o.createdByName,
    },
    items: itemsByOrder[o.id] || [],
    payments: paymentsByOrder[o.id] || [],
    createdAt: o.createdAt,
    updatedAt: o.updatedAt,
  }));

  return {
    orders: formattedOrders,
    pagination: {
      page: pageNum,
      limit: limitNum,
      totalCount,
      totalPages: Math.ceil(totalCount / limitNum),
    },
  };
}

async function getOrderById(id) {
  const [orders] = await pool.query(
    `SELECT 
       o.id, 
       o.order_number AS orderNumber, 
       o.status, 
       o.payment_status AS paymentStatus, 
       o.subtotal, 
       o.discount_total AS discountTotal, 
       o.total, 
       o.created_by AS createdBy,
       u.name AS createdByName,
       o.created_at AS createdAt, 
       o.updated_at AS updatedAt
     FROM orders o
     JOIN users u ON o.created_by = u.id
     WHERE o.id = ?`,
    [id]
  );

  if (orders.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Order with ID ${id} not found`);
  }

  const order = orders[0];

  const [items] = await pool.query(
    `SELECT 
       id, 
       product_id AS productId, 
       product_name_snapshot AS productName, 
       unit_price AS unitPrice, 
       quantity, 
       line_total AS lineTotal, 
       variant_name_snapshot AS variantName, 
       addon_snapshot AS addonSnapshot,
       created_at AS createdAt
     FROM order_items
     WHERE order_id = ?`,
    [id]
  );

  const [payments] = await pool.query(
    `SELECT id, method, amount, status, external_reference AS externalReference, paid_at AS paidAt, created_at AS createdAt
     FROM payments
     WHERE order_id = ?`,
    [id]
  );

  const [discounts] = await pool.query(
    `SELECT id, type, value, amount_applied AS amountApplied, label, created_at AS createdAt
     FROM discounts
     WHERE order_id = ?`,
    [id]
  );

  return {
    id: order.id,
    orderNumber: order.orderNumber,
    status: order.status,
    paymentStatus: order.paymentStatus,
    subtotal: Number(order.subtotal),
    discountTotal: Number(order.discountTotal),
    total: Number(order.total),
    createdBy: {
      id: order.createdBy,
      name: order.createdByName,
    },
    items: items.map(it => ({
      id: it.id,
      productId: it.productId,
      name: it.productName,
      unitPrice: Number(it.unitPrice),
      quantity: it.quantity,
      lineTotal: Number(it.lineTotal),
      variantName: it.variantName,
      addons: typeof it.addonSnapshot === 'string' ? JSON.parse(it.addonSnapshot) : it.addonSnapshot,
    })),
    payments: payments.map(p => ({
      id: p.id,
      method: p.method,
      amount: Number(p.amount),
      status: p.status,
      externalReference: p.externalReference,
      paidAt: p.paidAt,
    })),
    discount: discounts.length > 0 ? {
      id: discounts[0].id,
      type: discounts[0].type,
      value: Number(discounts[0].value),
      amountApplied: Number(discounts[0].amountApplied),
      label: discounts[0].label,
    } : null,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt,
  };
}

async function getOrderByOrderNumber(orderNumber) {
  const [rows] = await pool.query('SELECT id FROM orders WHERE order_number = ?', [orderNumber.trim()]);
  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Order with number ${orderNumber} not found`);
  }
  return getOrderById(rows[0].id);
}

async function updateOrderStatus(id, newStatus, user) {
  const order = await getOrderById(id);

  if (!Object.values(ORDER_STATUS).includes(newStatus)) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, `Invalid order status: ${newStatus}`);
  }

  if (order.status === ORDER_STATUS.COMPLETED || order.status === ORDER_STATUS.CANCELLED) {
    throw new ApiError(
      400,
      ERROR_CODES.INVALID_STATE_TRANSITION,
      `Order is already ${order.status} and cannot be modified`
    );
  }

  if (!isValidStatusTransition(order.status, newStatus)) {
    throw new ApiError(
      400,
      ERROR_CODES.INVALID_STATE_TRANSITION,
      `Cannot transition order status from '${order.status}' to '${newStatus}'`
    );
  }

  await pool.query('UPDATE orders SET status = ? WHERE id = ?', [newStatus, id]);

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'UPDATE_ORDER_STATUS',
    entityType: 'orders',
    entityId: id,
    metadata: { previousStatus: order.status, nextStatus: newStatus },
  });

  return getOrderById(id);
}

async function getLiveQueue() {
  const [orders] = await pool.query(
    `SELECT 
       id, 
       order_number AS orderNumber, 
       status, 
       created_at AS createdAt, 
       updated_at AS updatedAt
     FROM orders
     WHERE status IN (?, ?)
     ORDER BY updated_at ASC`,
    [ORDER_STATUS.PREPARING, ORDER_STATUS.READY]
  );

  return {
    preparing: orders.filter(o => o.status === ORDER_STATUS.PREPARING),
    ready: orders.filter(o => o.status === ORDER_STATUS.READY),
  };
}

module.exports = {
  createOrder,
  getOrders,
  getOrderById,
  getOrderByOrderNumber,
  updateOrderStatus,
  getLiveQueue,
};
