const { pool } = require('../config/db');
const { ORDER_STATUS } = require('../constants/orderStatus');
const { PAYMENT_STATUS } = require('../constants/paymentStatus');

async function getSummary({ from, to }) {
  let whereClauses = ['o.payment_status = ?', 'o.status != ?'];
  const values = [PAYMENT_STATUS.PAID, ORDER_STATUS.CANCELLED];

  if (from) {
    whereClauses.push('o.created_at >= ?');
    values.push(new Date(from));
  }

  if (to) {
    whereClauses.push('o.created_at <= ?');
    values.push(new Date(to));
  }

  const whereSql = whereClauses.join(' AND ');

  // 1. Calculate revenue, order count
  const [salesMetrics] = await pool.query(
    `SELECT 
       COALESCE(SUM(o.total), 0) AS revenue,
       COUNT(o.id) AS ordersCount
     FROM orders o
     WHERE ${whereSql}`,
    values
  );

  const revenue = Number(salesMetrics[0].revenue);
  const orders = Number(salesMetrics[0].ordersCount);
  const averageOrderValue = orders > 0 ? Math.round((revenue / orders) * 100) / 100 : 0;

  // 2. Count low stock products
  const [stockMetrics] = await pool.query(`
    SELECT COUNT(*) AS lowStockCount
    FROM products p
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE p.is_archived = FALSE
      AND COALESCE(i.quantity, 0) <= COALESCE(p.low_stock_threshold, 5)
  `);

  const lowStockCount = Number(stockMetrics[0].lowStockCount);

  // 3. Top selling items
  const [topItems] = await pool.query(
    `SELECT 
       oi.product_name_snapshot AS name,
       SUM(oi.quantity) AS totalQuantitySold,
       SUM(oi.line_total) AS totalRevenue
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.id
     WHERE ${whereSql}
     GROUP BY oi.product_name_snapshot
     ORDER BY totalQuantitySold DESC
     LIMIT 5`,
    values
  );

  // 4. Payment methods breakdown
  const [paymentBreakdown] = await pool.query(
    `SELECT 
       p.method,
       COUNT(p.id) AS transactionCount,
       COALESCE(SUM(p.amount), 0) AS totalAmount
     FROM payments p
     JOIN orders o ON p.order_id = o.id
     WHERE p.status = 'paid' AND ${whereSql}
     GROUP BY p.method`,
    values
  );

  return {
    revenue,
    orders,
    averageOrderValue,
    lowStockCount,
    topSellingProducts: topItems.map(item => ({
      name: item.name,
      totalQuantitySold: Number(item.totalQuantitySold),
      totalRevenue: Number(item.totalRevenue),
    })),
    paymentBreakdown: paymentBreakdown.map(pb => ({
      method: pb.method,
      transactionCount: Number(pb.transactionCount),
      totalAmount: Number(pb.totalAmount),
    })),
  };
}

module.exports = {
  getSummary,
};
