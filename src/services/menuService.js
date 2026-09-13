const { pool } = require('../config/db');
const { generateId } = require('../utils/idGenerator');
const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const { recordAuditLog } = require('../utils/auditLogger');

// ------------------------------------------------------------------------------
// Categories
// ------------------------------------------------------------------------------
async function getCategories(includeInactive = false) {
  try {
    let query = 'SELECT id, name, sort_order, is_active, created_at, updated_at FROM categories';
    if (!includeInactive) {
      query += ' WHERE is_active = TRUE';
    }
    query += ' ORDER BY sort_order ASC, name ASC';

    const [categories] = await pool.query(query);
    return categories;
  } catch (err) {
    if (err.code === 'ER_NO_SUCH_TABLE') {
      console.log('[MenuService] Tables missing. Auto-initializing database schema & seeds...');
      const initDatabase = require('../scripts/initDb');
      await initDatabase();
      const [categories] = await pool.query('SELECT id, name, sort_order, is_active, created_at, updated_at FROM categories WHERE is_active = TRUE ORDER BY sort_order ASC, name ASC');
      return categories;
    }
    throw err;
  }
}

async function getCategoryById(id) {
  const [rows] = await pool.query(
    'SELECT id, name, sort_order, is_active, created_at, updated_at FROM categories WHERE id = ?',
    [id]
  );
  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Category with ID ${id} not found`);
  }
  return rows[0];
}

async function createCategory({ name, sortOrder = 0 }, user) {
  if (!name || !name.trim()) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Category name is required');
  }

  const id = generateId('cat');
  await pool.query(
    'INSERT INTO categories (id, name, sort_order, is_active) VALUES (?, ?, ?, TRUE)',
    [id, name.trim(), sortOrder || 0]
  );

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'CREATE_CATEGORY',
    entityType: 'categories',
    entityId: id,
    metadata: { name, sortOrder },
  });

  return getCategoryById(id);
}

async function updateCategory(id, { name, sortOrder, isActive }, user) {
  const category = await getCategoryById(id);

  const updates = [];
  const values = [];

  if (name !== undefined && name.trim()) {
    updates.push('name = ?');
    values.push(name.trim());
  }
  if (sortOrder !== undefined) {
    updates.push('sort_order = ?');
    values.push(Number(sortOrder));
  }
  if (isActive !== undefined) {
    updates.push('is_active = ?');
    values.push(Boolean(isActive));
  }

  if (updates.length === 0) {
    return category;
  }

  values.push(id);
  await pool.query(`UPDATE categories SET ${updates.join(', ')} WHERE id = ?`, values);

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'UPDATE_CATEGORY',
    entityType: 'categories',
    entityId: id,
    metadata: { name, sortOrder, isActive },
  });

  return getCategoryById(id);
}

// ------------------------------------------------------------------------------
// Addons
// ------------------------------------------------------------------------------
async function getAddons(includeInactive = false) {
  let query = 'SELECT id, name, price, is_active, created_at, updated_at FROM addons';
  if (!includeInactive) {
    query += ' WHERE is_active = TRUE';
  }
  query += ' ORDER BY name ASC';

  const [addons] = await pool.query(query);
  return addons.map(a => ({
    ...a,
    price: Number(a.price),
  }));
}

async function createAddon({ name, price }, user) {
  if (!name || price === undefined || price < 0) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Valid addon name and non-negative price are required');
  }

  const id = generateId('add');
  await pool.query(
    'INSERT INTO addons (id, name, price, is_active) VALUES (?, ?, ?, TRUE)',
    [id, name.trim(), price]
  );

  return {
    id,
    name: name.trim(),
    price: Number(price),
    isActive: true,
  };
}

// ------------------------------------------------------------------------------
// Products
// ------------------------------------------------------------------------------
async function getProducts({ categoryId, available, includeArchived = false }) {
  try {
    let query = `
      SELECT 
        p.id, 
        p.category_id AS categoryId, 
        c.name AS categoryName,
        p.name, 
        p.description, 
        p.price, 
        p.available, 
        p.low_stock_threshold AS lowStockThreshold, 
        p.is_archived AS isArchived,
        COALESCE(i.quantity, 0) AS stockQuantity,
        p.created_at AS createdAt, 
        p.updated_at AS updatedAt
      FROM products p
      JOIN categories c ON p.category_id = c.id
      LEFT JOIN inventory i ON p.id = i.product_id
      WHERE 1=1
    `;

    const values = [];

    if (!includeArchived) {
      query += ' AND p.is_archived = FALSE';
    }

    if (categoryId) {
      query += ' AND p.category_id = ?';
      values.push(categoryId);
    }

    if (available !== undefined && available !== null && available !== '') {
      const isAvail = available === 'true' || available === true || available === '1' || available === 1;
      query += ' AND p.available = ?';
      values.push(isAvail);
    }

    query += ' ORDER BY c.sort_order ASC, p.name ASC';

    const [products] = await pool.query(query, values);

    if (products.length === 0) {
      return [];
    }

    const productIds = products.map(p => p.id);

    // Fetch all variants for these products
    const [variants] = await pool.query(
      `SELECT id, product_id AS productId, name, price_delta AS priceDelta, is_active AS isActive 
       FROM product_variants 
       WHERE product_id IN (?) AND is_active = TRUE 
       ORDER BY price_delta ASC`,
      [productIds]
    );

    // Fetch all addons for these products
    const [productAddons] = await pool.query(
      `SELECT pa.product_id AS productId, a.id, a.name, a.price, a.is_active AS isActive
       FROM product_addons pa
       JOIN addons a ON pa.addon_id = a.id
       WHERE pa.product_id IN (?) AND a.is_active = TRUE
       ORDER BY a.name ASC`,
      [productIds]
    );

    const variantsByProduct = {};
    variants.forEach(v => {
      if (!variantsByProduct[v.productId]) variantsByProduct[v.productId] = [];
      variantsByProduct[v.productId].push({
        id: v.id,
        name: v.name,
        priceDelta: Number(v.priceDelta),
      });
    });

    const addonsByProduct = {};
    productAddons.forEach(a => {
      if (!addonsByProduct[a.productId]) addonsByProduct[a.productId] = [];
      addonsByProduct[a.productId].push({
        id: a.id,
        name: a.name,
        price: Number(a.price),
      });
    });

    return products.map(p => ({
      id: p.id,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      name: p.name,
      description: p.description,
      price: Number(p.price),
      available: Boolean(p.available),
      lowStockThreshold: p.lowStockThreshold !== null ? Number(p.lowStockThreshold) : null,
      stockQuantity: Number(p.stockQuantity),
      isArchived: Boolean(p.isArchived),
      variants: variantsByProduct[p.id] || [],
      addons: addonsByProduct[p.id] || [],
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  } catch (err) {
    if (err.code === 'ER_NO_SUCH_TABLE') {
      console.log('[MenuService] Tables missing in getProducts. Auto-initializing...');
      const initDatabase = require('../scripts/initDb');
      await initDatabase();
      return getProducts({ categoryId, available, includeArchived });
    }
    throw err;
  }
}

async function getProductById(id, includeArchived = true) {
  const query = `
    SELECT 
      p.id, 
      p.category_id AS categoryId, 
      c.name AS categoryName,
      p.name, 
      p.description, 
      p.price, 
      p.available, 
      p.low_stock_threshold AS lowStockThreshold, 
      p.is_archived AS isArchived,
      COALESCE(i.quantity, 0) AS stockQuantity,
      p.created_at AS createdAt, 
      p.updated_at AS updatedAt
    FROM products p
    JOIN categories c ON p.category_id = c.id
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE p.id = ? ${includeArchived ? '' : 'AND p.is_archived = FALSE'}
  `;

  const [rows] = await pool.query(query, [id]);

  if (rows.length === 0) {
    throw new ApiError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `Product with ID ${id} not found`);
  }

  const product = rows[0];

  // Fetch variants
  const [variants] = await pool.query(
    `SELECT id, name, price_delta AS priceDelta, is_active AS isActive 
     FROM product_variants 
     WHERE product_id = ? AND is_active = TRUE 
     ORDER BY price_delta ASC`,
    [id]
  );

  // Fetch addons
  const [addons] = await pool.query(
    `SELECT a.id, a.name, a.price, a.is_active AS isActive
     FROM product_addons pa
     JOIN addons a ON pa.addon_id = a.id
     WHERE pa.product_id = ? AND a.is_active = TRUE
     ORDER BY a.name ASC`,
    [id]
  );

  return {
    id: product.id,
    categoryId: product.categoryId,
    categoryName: product.categoryName,
    name: product.name,
    description: product.description,
    price: Number(product.price),
    available: Boolean(product.available),
    lowStockThreshold: product.lowStockThreshold !== null ? Number(product.lowStockThreshold) : null,
    stockQuantity: Number(product.stockQuantity),
    isArchived: Boolean(product.isArchived),
    variants: variants.map(v => ({ id: v.id, name: v.name, priceDelta: Number(v.priceDelta) })),
    addons: addons.map(a => ({ id: a.id, name: a.name, price: Number(a.price) })),
    createdAt: product.createdAt,
    updatedAt: product.updatedAt,
  };
}

async function createProduct(productData, user) {
  const {
    categoryId,
    name,
    description = null,
    price,
    available = true,
    lowStockThreshold = 5,
    initialStock = 0,
    variants = [],
    addonIds = [],
  } = productData;

  if (!categoryId || !name || price === undefined || price < 0) {
    throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Valid categoryId, name, and non-negative price are required');
  }

  // Verify category exists
  await getCategoryById(categoryId);

  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const productId = generateId('prod');

    // 1. Insert product
    await connection.query(
      `INSERT INTO products (id, category_id, name, description, price, available, low_stock_threshold, is_archived)
       VALUES (?, ?, ?, ?, ?, ?, ?, FALSE)`,
      [productId, categoryId, name.trim(), description, price, available, lowStockThreshold]
    );

    // 2. Insert initial inventory
    const safeStock = Math.max(0, parseInt(initialStock || 0, 10));
    await connection.query(
      'INSERT INTO inventory (product_id, quantity) VALUES (?, ?)',
      [productId, safeStock]
    );

    if (safeStock > 0) {
      const adjustmentId = generateId('adj');
      await connection.query(
        `INSERT INTO inventory_adjustments 
         (id, product_id, actor_user_id, previous_quantity, adjustment_quantity, resulting_quantity, reason)
         VALUES (?, ?, ?, 0, ?, ?, 'Initial product stock')`,
        [adjustmentId, productId, user ? user.id : 'usr_owner_01', safeStock, safeStock]
      );
    }

    // 3. Insert variants if provided
    if (Array.isArray(variants) && variants.length > 0) {
      for (const variant of variants) {
        if (variant.name) {
          const variantId = generateId('var');
          await connection.query(
            `INSERT INTO product_variants (id, product_id, name, price_delta, is_active)
             VALUES (?, ?, ?, ?, TRUE)`,
            [variantId, productId, variant.name.trim(), Number(variant.priceDelta || 0)]
          );
        }
      }
    }

    // 4. Insert addon associations if provided
    if (Array.isArray(addonIds) && addonIds.length > 0) {
      for (const addonId of addonIds) {
        await connection.query(
          'INSERT IGNORE INTO product_addons (product_id, addon_id) VALUES (?, ?)',
          [productId, addonId]
        );
      }
    }

    // 5. Audit log
    await recordAuditLog(connection, {
      actorUserId: user ? user.id : null,
      action: 'CREATE_PRODUCT',
      entityType: 'products',
      entityId: productId,
      metadata: { name, categoryId, price, initialStock },
    });

    await connection.commit();
    connection.release();

    return getProductById(productId);
  } catch (err) {
    await connection.rollback();
    connection.release();
    throw err;
  }
}

async function updateProduct(id, updateData, user) {
  await getProductById(id);

  const {
    categoryId,
    name,
    description,
    price,
    available,
    lowStockThreshold,
    variants,
    addonIds,
  } = updateData;

  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const updates = [];
    const values = [];

    if (categoryId !== undefined) {
      updates.push('category_id = ?');
      values.push(categoryId);
    }
    if (name !== undefined && name.trim()) {
      updates.push('name = ?');
      values.push(name.trim());
    }
    if (description !== undefined) {
      updates.push('description = ?');
      values.push(description);
    }
    if (price !== undefined) {
      if (price < 0) throw new ApiError(400, ERROR_CODES.VALIDATION_ERROR, 'Price must be non-negative');
      updates.push('price = ?');
      values.push(Number(price));
    }
    if (available !== undefined) {
      updates.push('available = ?');
      values.push(Boolean(available));
    }
    if (lowStockThreshold !== undefined) {
      updates.push('low_stock_threshold = ?');
      values.push(lowStockThreshold === null ? null : Math.max(0, parseInt(lowStockThreshold, 10)));
    }

    if (updates.length > 0) {
      values.push(id);
      await connection.query(`UPDATE products SET ${updates.join(', ')} WHERE id = ?`, values);
    }

    // Update variants if provided
    if (Array.isArray(variants)) {
      // Deactivate current variants
      await connection.query('UPDATE product_variants SET is_active = FALSE WHERE product_id = ?', [id]);
      for (const variant of variants) {
        if (variant.id) {
          await connection.query(
            `UPDATE product_variants SET name = ?, price_delta = ?, is_active = TRUE WHERE id = ? AND product_id = ?`,
            [variant.name, Number(variant.priceDelta || 0), variant.id, id]
          );
        } else if (variant.name) {
          const varId = generateId('var');
          await connection.query(
            `INSERT INTO product_variants (id, product_id, name, price_delta, is_active) VALUES (?, ?, ?, ?, TRUE)`,
            [varId, id, variant.name, Number(variant.priceDelta || 0)]
          );
        }
      }
    }

    // Update addons if provided
    if (Array.isArray(addonIds)) {
      await connection.query('DELETE FROM product_addons WHERE product_id = ?', [id]);
      for (const addonId of addonIds) {
        await connection.query(
          'INSERT IGNORE INTO product_addons (product_id, addon_id) VALUES (?, ?)',
          [id, addonId]
        );
      }
    }

    await recordAuditLog(connection, {
      actorUserId: user ? user.id : null,
      action: 'UPDATE_PRODUCT',
      entityType: 'products',
      entityId: id,
      metadata: updateData,
    });

    await connection.commit();
    connection.release();

    return getProductById(id);
  } catch (err) {
    await connection.rollback();
    connection.release();
    throw err;
  }
}

async function archiveProduct(id, user) {
  await getProductById(id);

  // Soft archive to protect transactional history
  await pool.query(
    'UPDATE products SET is_archived = TRUE, available = FALSE WHERE id = ?',
    [id]
  );

  await recordAuditLog(null, {
    actorUserId: user ? user.id : null,
    action: 'ARCHIVE_PRODUCT',
    entityType: 'products',
    entityId: id,
    metadata: { is_archived: true, available: false },
  });

  return { message: 'Product successfully archived', id };
}

module.exports = {
  getCategories,
  getCategoryById,
  createCategory,
  updateCategory,
  getAddons,
  createAddon,
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  archiveProduct,
};
