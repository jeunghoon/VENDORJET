import Database from 'better-sqlite3';
import { format } from 'date-fns';
import path from 'path';

const db = new Database(path.join(__dirname, '..', 'vendorjet.db'));
db.pragma('foreign_keys = ON');

const nowIso = new Date().toISOString();

function resetTables() {
  db.exec(`
    DELETE FROM buyer_requests;
    DELETE FROM membership_requests;
    DELETE FROM order_lines;
    DELETE FROM orders;
    DELETE FROM customers;
    DELETE FROM segments;
    DELETE FROM products;
    DELETE FROM memberships;
    DELETE FROM users;
    DELETE FROM tenants;
    DELETE FROM dashboard_cache;
  `);
}

function seedTenantsUsersMemberships() {
  const tenants = [
    { id: 't_acme', name: 'Acme Foods', locale: 'en', phone: '02-1234-5678', address: 'Seoul, Korea' },
    { id: 't_nova', name: 'Nova Market', locale: 'ko', phone: '031-987-6543', address: 'Incheon, Korea' },
  ];
  const insertTenant = db.prepare(
    'INSERT OR REPLACE INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)'
  );
  tenants.forEach((t) => insertTenant.run(t.id, t.name, t.locale, nowIso, t.phone, t.address));

  const insertUser = db.prepare(
    'INSERT OR REPLACE INTO users (id, email, password_hash, name, phone) VALUES (?,?,?,?,?)'
  );
  insertUser.run('u_admin', 'alex@vendorjet.com', 'welcome1', 'Alex Admin', '010-0000-0000');

  const insertMembership = db.prepare(
    'INSERT OR REPLACE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)'
  );
  tenants.forEach((t) => insertMembership.run('u_admin', t.id, 'owner', 'approved'));
}

function seedSegments() {
  const insertSegment = db.prepare('INSERT OR IGNORE INTO segments (tenant_id, name) VALUES (?, ?)');
  ['Restaurant', 'Hotel', 'Mart', 'Cafe'].forEach((seg) => {
    insertSegment.run('t_acme', seg);
    insertSegment.run('t_nova', seg);
  });
}

function seedProducts() {
  const insertProduct = db.prepare(
    'INSERT OR REPLACE INTO products (id, tenant_id, sku, name, price, variants_count, categories, tags, low_stock, image_url) VALUES (?,?,?,?,?,?,?,?,?,?)'
  );
  const sampleCategories = [
    ['Beverages'],
    ['Snacks'],
    ['Household'],
    ['Fashion'],
    ['Electronics'],
  ];
  for (let i = 0; i < 10; i++) {
    const tenantId = i % 2 === 0 ? 't_acme' : 't_nova';
    const cat = sampleCategories[i % sampleCategories.length];
    insertProduct.run(
      `p_${i + 1}`,
      tenantId,
      `SKU-${1000 + i}`,
      `Sample Product ${i + 1}`,
      10 + i * 2.5,
      1,
      JSON.stringify(cat),
      JSON.stringify([]),
      i % 3 === 0 ? 1 : 0,
      null
    );
  }
}

function seedCustomers() {
  const insertCustomer = db.prepare(
    'INSERT OR REPLACE INTO customers (id, tenant_id, name, contact_name, email, tier, created_at, segment) VALUES (?,?,?,?,?,?,?,?)'
  );
  const customers = [
    { id: 'c_1', tenantId: 't_acme', name: 'Bright Retail', contact: 'Alex Kim', email: 'buyer1@retail.com', tier: 'gold', segment: 'Mart' },
    { id: 'c_2', tenantId: 't_acme', name: 'Sunrise Market', contact: 'Jamie Park', email: 'buyer2@retail.com', tier: 'silver', segment: 'Restaurant' },
    { id: 'c_3', tenantId: 't_nova', name: 'Metro Shops', contact: 'Morgan Lee', email: 'buyer3@retail.com', tier: 'platinum', segment: 'Hotel' },
  ];
  customers.forEach((c, idx) =>
    insertCustomer.run(
      c.id,
      c.tenantId,
      c.name,
      c.contact,
      c.email,
      c.tier,
      new Date(Date.now() - (idx + 1) * 86400000).toISOString(),
      c.segment
    )
  );
}

function seedOrders() {
  const insertOrder = db.prepare(
    'INSERT INTO orders (id, tenant_id, code, buyer_name, buyer_contact, buyer_note, status, total, item_count, created_at, updated_at, update_note, desired_delivery_date) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)'
  );
  const insertLine = db.prepare(
    'INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)'
  );
  for (let i = 0; i < 5; i++) {
    const tenantId = i % 2 === 0 ? 't_acme' : 't_nova';
    const createdAt = new Date(Date.now() - i * 3600000);
    const code = `PO${format(createdAt, 'yyMMdd')}${(i + 1).toString().padStart(4, '0')}`;
    const orderId = `o_${i + 1}`;
    insertOrder.run(
      orderId,
      tenantId,
      code,
      `Buyer ${i + 1}`,
      '010-1234-5678',
      i % 2 === 0 ? '메모 확인' : null,
      i % 2 === 0 ? 'pending' : 'confirmed',
      100 + i * 10,
      2 + i,
      createdAt.toISOString(),
      createdAt.toISOString(),
      'Auto-generated',
      new Date(createdAt.getTime() + 86400000).toISOString()
    );
    insertLine.run(orderId, 'p_1', 'Sample Product 1', 1 + i, 10 + i);
    insertLine.run(orderId, 'p_2', 'Sample Product 2', 1, 12.5);
  }
}

const seedAll = db.transaction(() => {
  resetTables();
  seedTenantsUsersMemberships();
  seedSegments();
  seedProducts();
  seedCustomers();
  seedOrders();
});

seedAll();
db.close();
