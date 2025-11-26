import Database from 'better-sqlite3';
import { format } from 'date-fns';
import path from 'path';
import fs from 'fs';

const db = new Database(path.join(__dirname, '..', 'vendorjet.db'));
db.pragma('foreign_keys = ON');

const nowIso = new Date().toISOString();
const schemaPath = path.join(__dirname, '..', 'schema.sql');

// 코어 테이블이 없을 때만 스키마 전체 적용
const schemaSql = fs.readFileSync(schemaPath, 'utf8');
const names = db
  .prepare("SELECT name FROM sqlite_master WHERE type='table';")
  .all()
  .map((r: any) => r.name);
const coreTables = ['users', 'tenants', 'orders', 'order_lines'];
const missingCore = coreTables.some((t) => !names.includes(t));
if (missingCore) {
  db.exec(schemaSql);
}

function ensureColumn(table: string, column: string, type: string) {
  const info = db.prepare(`PRAGMA table_info(${table});`).all() as any[];
  const columnExists = info.some((c) => c.name === column);
  if (!columnExists) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${type};`);
  }
}

// 누락 테이블 보강
db.exec(`
  CREATE TABLE IF NOT EXISTS buyer_requests (
    id TEXT PRIMARY KEY,
    seller_company TEXT,
    seller_phone TEXT,
    seller_address TEXT,
    buyer_company TEXT,
    buyer_address TEXT,
    email TEXT,
    name TEXT,
    phone TEXT,
    role TEXT,
    attachment_url TEXT,
    status TEXT,
    created_at TEXT
  );
  CREATE TABLE IF NOT EXISTS membership_requests (
    id TEXT PRIMARY KEY,
    tenant_id TEXT,
    email TEXT,
    name TEXT,
    phone TEXT,
    role TEXT,
    status TEXT,
    company_name TEXT,
    company_address TEXT,
    company_phone TEXT,
    attachments TEXT,
    requester_type TEXT,
    created_at TEXT
  );
  CREATE TABLE IF NOT EXISTS order_code_sequences (
    date TEXT PRIMARY KEY,
    last_seq INTEGER
  );
  CREATE TABLE IF NOT EXISTS order_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT,
    tenant_id TEXT,
    action TEXT,
    actor TEXT,
    note TEXT,
    created_at TEXT
  );
`);

// ensure missing columns on existing DB
ensureColumn('users', 'user_type', 'TEXT');
ensureColumn('users', 'last_login_at', 'TEXT');
ensureColumn('users', 'created_at', 'TEXT');
ensureColumn('users', 'updated_at', 'TEXT');
ensureColumn('orders', 'created_source', 'TEXT');
ensureColumn('orders', 'created_by', 'TEXT');
ensureColumn('orders', 'updated_by', 'TEXT');
ensureColumn('orders', 'status_updated_by', 'TEXT');
ensureColumn('orders', 'status_updated_at', 'TEXT');
ensureColumn('buyer_requests', 'buyer_tenant_id', 'TEXT');

function resetTables() {
  db.exec(`
    DELETE FROM buyer_requests;
    DELETE FROM membership_requests;
    DELETE FROM order_lines;
    DELETE FROM orders;
    DELETE FROM order_code_sequences;
    DELETE FROM order_events;
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
    'INSERT OR REPLACE INTO users (id, email, password_hash, name, phone, user_type) VALUES (?,?,?,?,?,?)'
  );
  const users = [
    { id: 'u_admin', email: 'admin@vendorjet.com', name: 'Alex Admin', phone: '010-0000-0000', password: 'welcome1', type: 'wholesale' },
    { id: 'u_seller_acme', email: 'seller@acme.com', name: 'Acme Owner', phone: '010-1111-2222', password: 'welcome1', type: 'wholesale' },
    { id: 'u_staff_acme', email: 'staff@acme.com', name: 'Acme Staff', phone: '010-3333-4444', password: 'welcome1', type: 'wholesale' },
    { id: 'u_seller_nova', email: 'seller@nova.com', name: 'Nova Owner', phone: '010-5555-6666', password: 'welcome1', type: 'wholesale' },
    { id: 'u_buyer_bright', email: 'buyer@bright.com', name: 'Bright Retail Buyer', phone: '010-7777-8888', password: 'welcome1', type: 'retail' },
    { id: 'u_buyer_sunrise', email: 'buyer@sunrise.com', name: 'Sunrise Buyer', phone: '010-9999-0000', password: 'welcome1', type: 'retail' },
    { id: 'u_buyer_metro', email: 'buyer@metro.com', name: 'Metro Buyer', phone: '010-1212-3434', password: 'welcome1', type: 'retail' },
  ];
  users.forEach((u) => insertUser.run(u.id, u.email, u.password, u.name, u.phone, u.type));

  const insertMembership = db.prepare(
    'INSERT OR REPLACE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)'
  );
  tenants.forEach((t) => insertMembership.run('u_admin', t.id, 'owner', 'approved'));
  insertMembership.run('u_seller_acme', 't_acme', 'owner', 'approved');
  insertMembership.run('u_staff_acme', 't_acme', 'staff', 'approved');
  insertMembership.run('u_seller_nova', 't_nova', 'owner', 'approved');
  insertMembership.run('u_buyer_bright', 't_acme', 'staff', 'approved');
  insertMembership.run('u_buyer_sunrise', 't_acme', 'staff', 'approved');
  insertMembership.run('u_buyer_metro', 't_nova', 'staff', 'approved');
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
  const acmeProducts = [
    { sku: 'ACM-COFF-001', name: 'Coldbrew Concentrate 2L', price: 24.5, cat: ['Beverages', 'Coffee'], low: 0 },
    { sku: 'ACM-TEA-002', name: 'Jasmine Green Tea 500ml', price: 2.9, cat: ['Beverages', 'Tea'], low: 0 },
    { sku: 'ACM-SYR-003', name: 'Vanilla Syrup 1kg', price: 8.5, cat: ['Ingredients', 'Syrup'], low: 0 },
    { sku: 'ACM-DRY-004', name: 'Penne Rigate 5kg', price: 11.0, cat: ['Dry Goods', 'Pasta'], low: 0 },
    { sku: 'ACM-SNCK-005', name: 'Sea Salt Chips 150g', price: 3.2, cat: ['Snacks', 'Chips'], low: 1 },
    { sku: 'ACM-DAIR-006', name: 'Whole Milk 1L', price: 1.8, cat: ['Dairy', 'Milk'], low: 0 },
    { sku: 'ACM-FRZN-007', name: 'Frozen Blueberries 2kg', price: 9.9, cat: ['Frozen', 'Fruit'], low: 0 },
    { sku: 'ACM-CLN-008', name: 'Kitchen Paper Towel 12roll', price: 7.5, cat: ['Household', 'Supplies'], low: 0 },
  ];
  acmeProducts.forEach((p, idx) =>
    insertProduct.run(
      `p_acm_${idx + 1}`,
      't_acme',
      p.sku,
      p.name,
      p.price,
      1,
      JSON.stringify(p.cat),
      JSON.stringify([]),
      p.low,
      null
    )
  );

  const novaProducts = [
    { sku: 'NOV-DRNK-010', name: 'Sparkling Water 500ml', price: 1.5, cat: ['Beverages', 'Water'], low: 0 },
    { sku: 'NOV-BAKE-011', name: 'Brioche Bun 12ct', price: 6.8, cat: ['Bakery', 'Bread'], low: 0 },
    { sku: 'NOV-MEAT-012', name: 'Chicken Breast 2kg', price: 13.2, cat: ['Meat', 'Poultry'], low: 0 },
    { sku: 'NOV-VEG-013', name: 'Fresh Spinach 1kg', price: 3.9, cat: ['Produce', 'Leafy'], low: 1 },
    { sku: 'NOV-FRZN-014', name: 'Frozen French Fries 2.5kg', price: 5.4, cat: ['Frozen', 'Potato'], low: 0 },
  ];
  novaProducts.forEach((p, idx) =>
    insertProduct.run(
      `p_nov_${idx + 1}`,
      't_nova',
      p.sku,
      p.name,
      p.price,
      1,
      JSON.stringify(p.cat),
      JSON.stringify([]),
      p.low,
      null
    )
  );
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

function nextOrderCode(date: Date) {
  const datePart = format(date, 'yyMMdd');
  const current = db
    .prepare('SELECT last_seq FROM order_code_sequences WHERE date = ?')
    .get(datePart) as { last_seq?: number } | undefined;
  const next = (current?.last_seq ?? 0) + 1;
  db.prepare(
    `INSERT INTO order_code_sequences (date, last_seq) VALUES (?, ?)
     ON CONFLICT(date) DO UPDATE SET last_seq = excluded.last_seq`
  ).run(datePart, next);
  return `PO${datePart}${`${next}`.padStart(4, '0')}`;
}

function seedOrders() {
  const insertOrder = db.prepare(
    `INSERT INTO orders (
      id, tenant_id, code, created_source, buyer_name, buyer_contact, buyer_note, status, total, item_count,
      created_at, created_by, updated_at, updated_by, update_note, status_updated_at, status_updated_by,
      desired_delivery_date
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  );
  const insertLine = db.prepare(
    'INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)'
  );
  const insertEvent = db.prepare(
    'INSERT INTO order_events (order_id, tenant_id, action, actor, note, created_at) VALUES (?,?,?,?,?,?)'
  );
  for (let i = 0; i < 5; i++) {
    const tenantId = i % 2 === 0 ? 't_acme' : 't_nova';
    const createdAt = new Date(Date.now() - i * 3600000);
    const code = nextOrderCode(createdAt);
    const orderId = code;
    const actor = tenantId === 't_acme' ? 'u_staff_acme' : 'u_seller_nova';
    const productA = tenantId === 't_acme' ? 'p_acm_1' : 'p_nov_1';
    const productB = tenantId === 't_acme' ? 'p_acm_2' : 'p_nov_2';
    insertOrder.run(
      orderId,
      tenantId,
      code,
      tenantId === 't_acme' ? 'seller_portal' : 'buyer_portal',
      `Buyer ${i + 1}`,
      '010-1234-5678',
      i % 2 === 0 ? '메모 확인' : null,
      i % 2 === 0 ? 'pending' : 'confirmed',
      100 + i * 10,
      2 + i,
      createdAt.toISOString(),
      actor,
      createdAt.toISOString(),
      actor,
      'Auto-generated seed order',
      createdAt.toISOString(),
      actor,
      new Date(createdAt.getTime() + 86400000).toISOString()
    );
    insertLine.run(orderId, productA, 'Starter Pack', 1 + i, 10 + i);
    insertLine.run(orderId, productB, 'Add-on Item', 1, 12.5);
    insertEvent.run(orderId, tenantId, 'created', actor, 'seed order created', createdAt.toISOString());
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
