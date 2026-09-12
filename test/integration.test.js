const http = require('http');
const app = require('../src/app');

let server;
let baseUrl;

function request(path, options = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const reqOptions = {
      method: options.method || 'GET',
      headers: options.headers || {},
    };

    const req = http.request(url, reqOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        let body;
        try {
          body = JSON.parse(data);
        } catch (e) {
          body = data;
        }
        resolve({ status: res.statusCode, headers: res.headers, body });
      });
    });

    req.on('error', reject);

    if (options.body) {
      req.setHeader('Content-Type', 'application/json');
      req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
    }

    req.end();
  });
}

async function runTests() {
  console.log('\n======================================================');
  console.log('  CRIB SOCIETY COFFEE — API INTEGRATION TEST SUITE');
  console.log('======================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${message}`);
      failed++;
    }
  }

  // Start test server on random free port
  server = http.createServer(app);
  await new Promise(resolve => server.listen(0, resolve));
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
  console.log(`[Test Runner] Test server listening on ${baseUrl}\n`);

  try {
    // 1. Healthcheck
    console.log('--- 1. Healthcheck & Ping ---');
    const healthRes = await request('/api/v1/health');
    assert(healthRes.status === 200 && healthRes.body.status === 'UP', 'GET /api/v1/health returns status UP');

    // 2. Authentication
    console.log('\n--- 2. Authentication ---');
    const invalidLogin = await request('/api/v1/auth/login', {
      method: 'POST',
      body: { email: 'owner@cribsociety.coffee', password: 'wrongpassword' },
    });
    assert(invalidLogin.status === 401 && invalidLogin.body.error.code === 'UNAUTHORIZED', 'Invalid credentials returns 401 UNAUTHORIZED envelope');

    const ownerLogin = await request('/api/v1/auth/login', {
      method: 'POST',
      body: { email: 'owner@cribsociety.coffee', password: 'password123' },
    });
    assert(ownerLogin.status === 200 && ownerLogin.body.user.role === 'owner', 'Owner login successful with role "owner"');
    const ownerToken = ownerLogin.body.session.token;

    const staffLogin = await request('/api/v1/auth/login', {
      method: 'POST',
      body: { email: 'sarah@cribsociety.coffee', password: 'password123' },
    });
    assert(staffLogin.status === 200 && staffLogin.body.user.role === 'staff', 'Staff login successful with role "staff"');
    const staffToken = staffLogin.body.session.token;

    const meRes = await request('/api/v1/auth/me', {
      headers: { Authorization: `Bearer ${staffToken}` },
    });
    assert(meRes.status === 200 && meRes.body.user.email === 'sarah@cribsociety.coffee', 'GET /api/v1/auth/me returns authenticated user profile');

    // 3. Menu & Categories
    console.log('\n--- 3. Menu & Catalog ---');
    const categoriesRes = await request('/api/v1/menu/categories');
    assert(categoriesRes.status === 200 && categoriesRes.body.categories.length >= 4, 'GET /api/v1/menu/categories returns seed categories');

    const productsRes = await request('/api/v1/menu/products');
    assert(productsRes.status === 200 && productsRes.body.products.length >= 10, 'GET /api/v1/menu/products returns product catalog');

    const singleProdRes = await request('/api/v1/menu/products/prod_crib_aren');
    assert(singleProdRes.status === 200 && singleProdRes.body.product.name === 'Crib Aren Latte', 'GET /api/v1/menu/products/:id returns product details with variants');
    assert(singleProdRes.body.product.variants.length > 0, 'Product has variants loaded');
    assert(singleProdRes.body.product.addons.length > 0, 'Product has addons loaded');

    // 4. POS Order Creation
    console.log('\n--- 4. POS Orders & Snapshots ---');
    const createOrderPayload = {
      items: [
        {
          productId: 'prod_crib_aren',
          quantity: 2,
          variantId: 'var_aren_large', // +6000
          addonIds: ['add_extra_espresso'], // +6000
        },
      ],
      discount: {
        type: 'fixed',
        value: 5000,
        label: 'Staff Promo',
      },
    };

    const orderRes = await request('/api/v1/orders', {
      method: 'POST',
      headers: { Authorization: `Bearer ${staffToken}` },
      body: createOrderPayload,
    });
    assert(orderRes.status === 201, 'POST /api/v1/orders creates order successfully');
    const createdOrder = orderRes.body.order;
    assert(createdOrder.orderNumber.startsWith('#CSC-'), `Generated valid order number: ${createdOrder.orderNumber}`);
    assert(createdOrder.subtotal === 80000, `Authoritative subtotal calculated correctly: 80000 (got ${createdOrder.subtotal})`);
    assert(createdOrder.discountTotal === 5000, `Discount applied correctly: 5000 (got ${createdOrder.discountTotal})`);
    assert(createdOrder.total === 75000, `Authoritative total calculated correctly: 75000 (got ${createdOrder.total})`);
    assert(createdOrder.items[0].name === 'Crib Aren Latte', 'Item snapshot name preserved');
    assert(createdOrder.items[0].variantName === 'Large (16oz)', 'Variant snapshot name preserved');

    // 5. Payments & Idempotency
    console.log('\n--- 5. Payments & Idempotency ---');
    const paymentPayload = {
      method: 'qris',
      amount: 75000,
      externalReference: 'QRIS-TEST-12345',
    };

    const paymentRes = await request(`/api/v1/orders/${createdOrder.id}/payment`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${staffToken}` },
      body: paymentPayload,
    });
    assert(paymentRes.status === 200 && paymentRes.body.status === 'paid', 'POST /orders/:id/payment processes payment successfully');

    // Duplicate payment idempotency check
    const dupPaymentRes = await request(`/api/v1/orders/${createdOrder.id}/payment`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${staffToken}` },
      body: paymentPayload,
    });
    assert(dupPaymentRes.status === 409 && dupPaymentRes.body.error.code === 'CONFLICT', 'Duplicate payment rejected with 409 CONFLICT');

    // 6. Guest Queue & Order Tracking
    console.log('\n--- 6. Guest Live Queue & Order Tracking ---');
    const queueRes = await request('/api/v1/guest/queue');
    assert(queueRes.status === 200 && Array.isArray(queueRes.body.queue.preparing), 'GET /api/v1/guest/queue returns live queue board');

    const trackRes = await request(`/api/v1/guest/track/${encodeURIComponent(createdOrder.orderNumber)}`);
    assert(trackRes.status === 200 && trackRes.body.order.orderNumber === createdOrder.orderNumber, 'GET /api/v1/guest/track/:orderNumber tracks order by number');

    // 7. Inventory Adjustments & History
    console.log('\n--- 7. Inventory & Stock Adjustments ---');
    const invRes = await request('/api/v1/inventory', {
      headers: { Authorization: `Bearer ${staffToken}` },
    });
    assert(invRes.status === 200 && Array.isArray(invRes.body.inventory), 'GET /api/v1/inventory lists product stock levels');

    const adjustRes = await request('/api/v1/inventory/prod_butterscotch', {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${ownerToken}` },
      body: { quantity: 28, reason: 'Manual audit stock count' },
    });
    assert(adjustRes.status === 200 && adjustRes.body.inventory.quantity === 28, 'PATCH /api/v1/inventory/:productId updates stock quantity');

    const historyRes = await request('/api/v1/inventory/adjustments?productId=prod_butterscotch', {
      headers: { Authorization: `Bearer ${staffToken}` },
    });
    assert(historyRes.status === 200 && historyRes.body.adjustments.length > 0, 'GET /api/v1/inventory/adjustments returns append-only audit trail');

    // 8. Dashboard KPIs
    console.log('\n--- 8. Dashboard KPI Summary ---');
    const dashRes = await request('/api/v1/dashboard/summary', {
      headers: { Authorization: `Bearer ${ownerToken}` },
    });
    assert(dashRes.status === 200 && dashRes.body.revenue > 0, `Dashboard returns qualifying revenue: Rp ${dashRes.body.revenue}`);
    assert(dashRes.body.orders > 0, `Dashboard returns qualifying order count: ${dashRes.body.orders}`);
    assert(typeof dashRes.body.averageOrderValue === 'number', `Dashboard returns valid Average Order Value: Rp ${dashRes.body.averageOrderValue}`);

    // 9. RBAC Security Controls
    console.log('\n--- 9. Role-Based Access Control (RBAC) ---');
    const staffBlockedStaffList = await request('/api/v1/staff', {
      headers: { Authorization: `Bearer ${staffToken}` },
    });
    assert(staffBlockedStaffList.status === 403 && staffBlockedStaffList.body.error.code === 'FORBIDDEN', 'Staff user is strictly blocked (403 FORBIDDEN) from accessing /api/v1/staff');

    const ownerAllowedStaffList = await request('/api/v1/staff', {
      headers: { Authorization: `Bearer ${ownerToken}` },
    });
    assert(ownerAllowedStaffList.status === 200 && ownerAllowedStaffList.body.staff.length >= 3, 'Owner user successfully accesses /api/v1/staff');

    // 10. Archival Protection
    console.log('\n--- 10. Soft Archival Data Protection ---');
    const archiveRes = await request('/api/v1/menu/products/prod_coco_cappuccino', {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${ownerToken}` },
    });
    assert(archiveRes.status === 200, 'Owner archives product successfully');

    const checkArchived = await request('/api/v1/menu/products/prod_coco_cappuccino');
    assert(checkArchived.status === 200 && checkArchived.body.product.isArchived === true && checkArchived.body.product.available === false, 'Archived product is marked isArchived=true and available=false, preserving database integrity');

  } catch (err) {
    console.error('\n❌ Fatal test runner error:', err);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
  }

  console.log('\n======================================================');
  console.log(`  TEST RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log('======================================================\n');

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTests();
