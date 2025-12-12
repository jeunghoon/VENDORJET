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
    buyer_tenant_id TEXT,
    requested_segment TEXT,
    selected_segment TEXT,
    selected_tier TEXT,
    user_id TEXT,
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
ensureColumn('buyer_requests', 'requested_segment', 'TEXT');
ensureColumn('buyer_requests', 'selected_segment', 'TEXT');
ensureColumn('buyer_requests', 'selected_tier', 'TEXT');
ensureColumn('tenants', 'segment', 'TEXT');
ensureColumn('products', 'hs_code', 'TEXT');
ensureColumn('products', 'origin_country', 'TEXT');
ensureColumn('products', 'uom', 'TEXT');
ensureColumn('products', 'incoterm', 'TEXT');
ensureColumn('products', 'is_perishable', 'INTEGER');
ensureColumn('products', 'packaging', 'TEXT');
ensureColumn('products', 'trade_term', 'TEXT');
ensureColumn('products', 'eta', 'TEXT');

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
    { id: 't_food', name: 'Acme Foods', locale: 'en', phone: '02-1234-5678', address: 'Seoul, Korea', segment: 'Food & Beverage' },
    { id: 't_apparel', name: 'Nova Apparel', locale: 'ko', phone: '031-987-6543', address: 'Incheon, Korea', segment: 'Apparel' },
    { id: 't_mart', name: 'Bright Mart', locale: 'ko', phone: '02-555-1234', address: 'Seoul, Korea', segment: 'Mart' },
    { id: 't_clothing', name: 'Style Boutique', locale: 'en', phone: '010-8000-1111', address: 'Busan, Korea', segment: 'Boutique' },
  ];
  const insertTenant = db.prepare(
    'INSERT OR REPLACE INTO tenants (id, name, locale, created_at, phone, address, segment) VALUES (?,?,?,?,?,?,?)'
  );
  tenants.forEach((t) => insertTenant.run(t.id, t.name, t.locale, nowIso, t.phone, t.address, t.segment));

  const insertUser = db.prepare(
    'INSERT OR REPLACE INTO users (id, email, password_hash, name, phone, user_type) VALUES (?,?,?,?,?,?)'
  );
  const users = [
    { id: 'u_admin', email: 'admin', name: 'Alex Admin', phone: '010-0000-0000', password: '123', type: 'wholesale' },    
    { id: 'u_food_staff', email: 'ac', name: 'Acme Staff', phone: '010-3333-4444', password: '123', type: 'wholesale' },    
    { id: 'u_apparel_staff', email: 'no', name: 'Nova Staff', phone: '010-4444-6666', password: '123', type: 'wholesale' },
    { id: 'u_mart_buyer', email: 'mm', name: 'Bright Mart Buyer', phone: '010-7777-8888', password: '123', type: 'retail' },
    { id: 'u_style_buyer', email: 'ss', name: 'Style Boutique Buyer', phone: '010-9999-0000', password: '123', type: 'retail' },
  ];
  users.forEach((u) => insertUser.run(u.id, u.email, u.password, u.name, u.phone, u.type));

  const insertMembership = db.prepare(
    'INSERT OR REPLACE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)'
  );
  // 글로벌 관리자: 두 도매 업체 모두 owner, 소매도 관리 가능
  insertMembership.run('u_admin', 't_food', 'owner', 'approved');
  insertMembership.run('u_admin', 't_apparel', 'owner', 'approved');

  insertMembership.run('u_food_staff', 't_food', 'staff', 'approved');

  insertMembership.run('u_apparel_staff', 't_apparel', 'staff', 'approved');

  // 소매 매장 멤버십 (admin은 소매 미보유)
  insertMembership.run('u_mart_buyer', 't_mart', 'owner', 'approved');
  insertMembership.run('u_style_buyer', 't_clothing', 'owner', 'approved');

  // 소매-도매 연결은 고객/요청으로만 관리(교차 멤버십 제거)
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
    `INSERT OR REPLACE INTO products (
      id, tenant_id, sku, name, price, variants_count, categories, tags, low_stock, image_url,
      hs_code, origin_country, uom, incoterm, is_perishable, packaging, trade_term, eta
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  );
  const foodCategories = [
    ['Beverages', 'Coffee'],
    ['Beverages', 'Tea'],
    ['Snacks', 'Chips'],
    ['Frozen', 'Fruit'],
    ['Dairy', 'Milk'],
    ['Dry Goods', 'Pasta'],
    ['Bakery', 'Bread'],
    ['Ingredients', 'Sauce'],
  ];
  const apparelCategories = [
    ['Apparel', 'Tops'],
    ['Apparel', 'Bottoms'],
    ['Apparel', 'Outerwear'],
    ['Apparel', 'Accessories'],
    ['Footwear', 'Sneakers'],
    ['Footwear', 'Sandals'],
  ];

  function insertBatch(params: {
    tenantId: string;
    count: number;
    categories: string[][];
    incoterm: string;
    origin: string;
    prefix: string;
  }) {
    const { tenantId, count, categories, incoterm, origin, prefix } = params;
    if (categories.length === 0) return;
    for (let i = 0; i < count; i++) {
      const cat = categories[i % categories.length]!;
      const price = parseFloat((5 + Math.random() * 45).toFixed(2));
      const low = Math.random() < 0.15 ? 1 : 0;
      const perishable = Math.random() < 0.4 ? 1 : 0;
      const id = `${prefix}${i + 1}`;
      insertProduct.run(
        id,
        tenantId,
        `${prefix.toUpperCase()}-${1000 + i}`,
        `${cat[cat.length - 1]} Item ${i + 1}`,
        price,
        1,
        JSON.stringify(cat),
        JSON.stringify([]),
        low,
        null,
        `HS${8800 + i}`,
        origin,
        'EA',
        incoterm,
        perishable,
        JSON.stringify({
          packType: 'carton',
          lengthCm: 30 + Math.round(Math.random() * 10),
          widthCm: 20 + Math.round(Math.random() * 10),
          heightCm: 18 + Math.round(Math.random() * 8),
          unitsPerPack: 6 + Math.round(Math.random() * 12),
          netWeightKg: parseFloat((3 + Math.random() * 4).toFixed(2)),
          grossWeightKg: parseFloat((3.5 + Math.random() * 4).toFixed(2)),
          volumeCbm: 0.015 + Math.random() * 0.01,
          barcode: `${prefix.toUpperCase()}-PK-${i + 1}`,
        }),
        JSON.stringify({
          incoterm,
          currency: 'USD',
          price,
          portOfLoading: tenantId === 't_food' ? 'Busan' : 'Incheon',
          portOfDischarge: tenantId === 't_food' ? 'Los Angeles' : 'Seattle',
          freight: parseFloat((5 + Math.random() * 3).toFixed(2)),
          insurance: parseFloat((1 + Math.random() * 1.5).toFixed(2)),
          leadTimeDays: 5 + Math.round(Math.random() * 10),
          minOrderQty: 4 + Math.round(Math.random() * 8),
          moqUnit: 'carton',
        }),
        JSON.stringify({
          etd: nowIso,
          eta: new Date(Date.now() + (7 + Math.round(Math.random() * 10)) * 86400000).toISOString(),
          vessel: `VJ-${300 + i}`,
          voyageNo: `NV${400 + i}`,
          status: 'SCHEDULED',
        })
      );
    }
  }

  insertBatch(
    {
      tenantId: 't_food',
      count: 50,
      categories: foodCategories,
      incoterm: 'FOB',
      origin: 'KR',
      prefix: 'p_food_',
    },
  );
  insertBatch(
    {
      tenantId: 't_apparel',
      count: 50,
      categories: apparelCategories,
      incoterm: 'CIF',
      origin: 'VN',
      prefix: 'p_app_',
    },
  );
}

function seedCustomers() {
  const insertCustomer = db.prepare(
    'INSERT OR REPLACE INTO customers (id, tenant_id, name, contact_name, email, tier, created_at, segment) VALUES (?,?,?,?,?,?,?,?)'
  );
  const customers = [
    // 도매-소매 연결
    { id: 'c_food_mart', tenantId: 't_food', name: 'Bright Mart', contact: 'Mart Buyer', email: 'buyer@brightmart.com', tier: 'gold', segment: 'Mart' },
    { id: 'c_food_style', tenantId: 't_food', name: 'Style Boutique', contact: 'Style Buyer', email: 'buyer@style.com', tier: 'silver', segment: 'Fashion' },
    { id: 'c_apparel_mart', tenantId: 't_apparel', name: 'Bright Mart', contact: 'Mart Buyer', email: 'buyer@brightmart.com', tier: 'gold', segment: 'Mart' },
    { id: 'c_apparel_style', tenantId: 't_apparel', name: 'Style Boutique', contact: 'Style Buyer', email: 'buyer@style.com', tier: 'platinum', segment: 'Boutique' },
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

  const tenants = [
    { id: 't_food', actor: 'u_food_staff' },
    { id: 't_apparel', actor: 'u_apparel_staff' },
  ];
  const statuses = ['pending', 'confirmed', 'shipped', 'completed', 'returned', 'canceled'];

  const now = new Date();
  const start = new Date(now.getTime() - 365 * 86400000);
  let orderSeq = 0;

  tenants.forEach((tenant) => {
    const products = db
      .prepare('SELECT id, name, price FROM products WHERE tenant_id = ?')
      .all(tenant.id) as { id: string; name: string; price: number }[];
    const customers = db
      .prepare('SELECT name, contact_name FROM customers WHERE tenant_id = ?')
      .all(tenant.id) as { name: string; contact_name?: string | null }[];
    if (products.length === 0 || customers.length === 0) return;

    for (let m = 0; m < 12; m++) {
      const monthDate = new Date(start.getTime() + m * 30 * 86400000);
      for (let j = 0; j < 8; j++) {
        const dayOffset = Math.floor(Math.random() * 25);
        const createdAt = new Date(monthDate.getTime() + dayOffset * 86400000);
        const code = nextOrderCode(createdAt) + `-${tenant.id}-${orderSeq++}`;
        const orderId = code;
        const status = statuses[(j + m) % statuses.length];
        const buyerIdx = Math.floor(Math.random() * customers.length);
        const buyer = customers[buyerIdx]!;
        const productA = products[j % products.length]!;
        const productB = products[(j + 7) % products.length]!;
        const qtyA = 1 + (j % 4);
        const qtyB = 1 + (j % 3);
        const priceA = productA.price;
        const priceB = productB.price;
        const total = qtyA * priceA + qtyB * priceB;

        insertOrder.run(
          orderId,
          tenant.id,
          code,
          j % 2 === 0 ? 'seller_portal' : 'buyer_portal',
          buyer.name,
          buyer.contact_name ?? '010-1234-5678',
          j % 2 === 0 ? '검토 후 발주' : '빠른 납품 요청',
          status,
          total,
          qtyA + qtyB,
          createdAt.toISOString(),
          tenant.actor,
          createdAt.toISOString(),
          tenant.actor,
          'Auto-generated seed order',
          createdAt.toISOString(),
          tenant.actor,
          new Date(createdAt.getTime() + 5 * 86400000).toISOString()
        );
        insertLine.run(orderId, productA.id, productA.name, qtyA, priceA);
        insertLine.run(orderId, productB.id, productB.name, qtyB, priceB);
        insertEvent.run(orderId, tenant.id, 'created', tenant.actor, 'seed order created', createdAt.toISOString());
      }
    }
  });
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
