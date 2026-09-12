const { pool } = require('../config/db');
const { generateId } = require('../utils/idGenerator');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const { PAYMENT_STATUS, PAYMENT_METHOD } = require('../constants/paymentStatus');
const { ORDER_STATUS } = require('../constants/orderStatus');
const { recordAuditLog } = require('../utils/auditLogger');
const { getOrderById } = require('./orderService');

async function processPayment(orderId, paymentData, user) {
  const { method, amount, externalReference = null } = paymentData;

  if (!method || !Object.values(PAYMENT_METHOD).includes(method)) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, `Invalid payment method: ${method}`);
  }

  const paymentAmount = Number(amount);
  if (isNaN(paymentAmount) || paymentAmount <= 0) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Payment amount must be a positive number');
  }

  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    // 1. Lock and retrieve order
    const [orders] = await connection.query(
      'SELECT id, order_number, status, payment_status, total FROM orders WHERE id = ? FOR UPDATE',
      [orderId]
    );

    if (orders.length === 0) {
      throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Order with ID ${orderId} not found`);
    }

    const order = orders[0];

    if (order.status === ORDER_STATUS.CANCELLED) {
      throw new ApiError(400, ERROR_CODES.BAD_REQUEST, 'Cannot process payment for a cancelled order');
    }

    // Idempotency: Prevent duplicate successful payment
    if (order.payment_status === PAYMENT_STATUS.PAID) {
      throw new ApiError(409, ERROR_CODES.CONFLICT, 'Order has already been paid');
    }

    if (paymentAmount < Number(order.total)) {
      throw new ApiError(
        400,
        ERROR_CODES.PAYMENT_REQUIRED,
        `Payment amount (${paymentAmount}) is less than order total (${order.total})`
      );
    }

    // 2. Fetch order items to decrement inventory
    const [orderItems] = await connection.query(
      'SELECT product_id, quantity, product_name_snapshot FROM order_items WHERE order_id = ?',
      [orderId]
    );

    // Verify and decrement stock for items
    for (const item of orderItems) {
      if (item.product_id) {
        const [invRows] = await connection.query(
          'SELECT quantity FROM inventory WHERE product_id = ? FOR UPDATE',
          [item.product_id]
        );

        if (invRows.length > 0) {
          const currentQty = invRows[0].quantity;
          const newQty = Math.max(0, currentQty - item.quantity);

          await connection.query(
            'UPDATE inventory SET quantity = ? WHERE product_id = ?',
            [newQty, item.product_id]
          );

          // Append inventory adjustment record
          const adjId = generateId('adj');
          await connection.query(
            `INSERT INTO inventory_adjustments 
             (id, product_id, actor_user_id, previous_quantity, adjustment_quantity, resulting_quantity, reason, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
            [
              adjId,
              item.product_id,
              user ? user.id : 'usr_staff_01',
              currentQty,
              -item.quantity,
              newQty,
              `POS Checkout order ${order.order_number}`,
            ]
          );

          // If stock hits 0, auto set product availability to false
          if (newQty === 0) {
            await connection.query('UPDATE products SET available = FALSE WHERE id = ?', [item.product_id]);
          }
        }
      }
    }

    // 3. Create payment record
    const paymentId = generateId('pay');
    const paidAt = new Date();

    await connection.query(
      `INSERT INTO payments 
       (id, order_id, method, amount, status, external_reference, paid_at, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        paymentId,
        orderId,
        method,
        paymentAmount,
        PAYMENT_STATUS.PAID,
        externalReference || `REF-${Date.now()}`,
        paidAt,
      ]
    );

    // 4. Update order payment_status and status
    await connection.query(
      `UPDATE orders 
       SET payment_status = ?, status = ? 
       WHERE id = ?`,
      [PAYMENT_STATUS.PAID, ORDER_STATUS.PREPARING, orderId]
    );

    // 5. Audit log
    await recordAuditLog(connection, {
      actorUserId: user ? user.id : null,
      action: 'PROCESS_PAYMENT',
      entityType: 'payments',
      entityId: paymentId,
      metadata: {
        orderId,
        orderNumber: order.order_number,
        method,
        amount: paymentAmount,
      },
    });

    await connection.commit();
    connection.release();

    return {
      paymentId,
      orderId,
      orderNumber: order.order_number,
      method,
      amount: paymentAmount,
      status: PAYMENT_STATUS.PAID,
      paidAt: paidAt.toISOString(),
    };
  } catch (err) {
    await connection.rollback();
    connection.release();
    throw err;
  }
}

module.exports = {
  processPayment,
};
