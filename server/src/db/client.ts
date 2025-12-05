import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';

// DB 파일 경로/스키마 경로를 고정 정의
const dbPath = path.join(__dirname, '..', '..', 'vendorjet.db');
const schemaPath = path.join(__dirname, '..', '..', 'schema.sql');
export const db: Database.Database = new Database(dbPath);

ensureSchema();

// snake_case -> camelCase 변환
const camel = (key: string) => key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());

export function mapRow<T = Record<string, unknown>>(row: any): T {
  if (!row) return row;
  const mapped: Record<string, unknown> = {};
  Object.keys(row).forEach((k) => {
    mapped[camel(k)] = row[k];
  });
  return mapped as T;
}

export function mapRows<T = Record<string, unknown>>(rows: any[]): T[] {
  return rows.map((r) => mapRow<T>(r));
}

function ensureSchema() {
  try {
    const rows = db
      .prepare("SELECT name FROM sqlite_master WHERE type='table';")
      .all()
      .map((r: any) => r.name);
    const hasCore = rows.includes('users') && rows.includes('tenants');
    if (!hasCore) {
      const schema = fs.readFileSync(schemaPath, 'utf8');
      db.exec(schema);
      // eslint-disable-next-line no-console
      console.log('[db] schema applied (core tables created)');
    }

    ensureTable(
      'membership_requests',
      `CREATE TABLE IF NOT EXISTS membership_requests (
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
      );`
    );

    ensureTable(
      'buyer_requests',
      `CREATE TABLE IF NOT EXISTS buyer_requests (
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
      );`
    );

    ensureTable(
      'order_code_sequences',
      `CREATE TABLE IF NOT EXISTS order_code_sequences (
        date TEXT PRIMARY KEY,
        last_seq INTEGER
      );`
    );
    ensureTable(
      'order_events',
      `CREATE TABLE IF NOT EXISTS order_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT,
        tenant_id TEXT,
        action TEXT,
        actor TEXT,
        note TEXT,
        created_at TEXT
      );`
    );

    // 추가 컬럼/인덱스 확인
    ensureColumn('tenants', 'phone', 'TEXT');
    ensureColumn('tenants', 'address', 'TEXT');
    ensureColumn('users', 'name', 'TEXT');
    ensureColumn('users', 'phone', 'TEXT');
    ensureColumn('users', 'address', 'TEXT');
    ensureColumn('users', 'created_at', 'TEXT');
    ensureColumn('users', 'last_login_at', 'TEXT');
    ensureColumn('users', 'user_type', 'TEXT');
    ensureColumn('users', 'language_preference', 'TEXT');
    ensureColumn('users', 'primary_tenant_id', 'TEXT');
    ensureColumn('memberships', 'status', 'TEXT');
    ensureColumn('membership_requests', 'company_phone', 'TEXT');
    ensureColumn('buyer_requests', 'seller_phone', 'TEXT');
    ensureColumn('buyer_requests', 'seller_address', 'TEXT');
    ensureColumn('buyer_requests', 'role', 'TEXT');
    ensureColumn('buyer_requests', 'user_id', 'TEXT');
    ensureColumn('buyer_requests', 'buyer_tenant_id', 'TEXT');
    ensureColumn('buyer_requests', 'requested_segment', 'TEXT');
    ensureColumn('buyer_requests', 'selected_segment', 'TEXT');
    ensureColumn('buyer_requests', 'selected_tier', 'TEXT');
    ensureColumn('orders', 'created_by', 'TEXT');
    ensureColumn('orders', 'updated_by', 'TEXT');
    ensureColumn('orders', 'status_updated_by', 'TEXT');
    ensureColumn('orders', 'status_updated_at', 'TEXT');
    ensureColumn('orders', 'created_source', 'TEXT');
    ensureColumn('tenants', 'representative', 'TEXT');
    ensureColumn('orders', 'buyer_tenant_id', 'TEXT');
    ensureColumn('orders', 'buyer_user_id', 'TEXT');
    ensureColumn('orders', 'buyer_user_name', 'TEXT');
    ensureColumn('orders', 'buyer_user_email', 'TEXT');
    ensureIndex(
      'orders',
      'idx_orders_code_unique',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_code_unique ON orders(code);'
    );
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[db] schema check failed:', err);
  }
}

function ensureTable(name: string, createSql: string) {
  const exists = db
    .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name = ?")
    .get(name);
  if (!exists) {
    db.exec(createSql);
    // eslint-disable-next-line no-console
    console.log(`[db] table created: ${name}`);
  }
}

function ensureColumn(table: string, column: string, type: string) {
  const info = db.prepare(`PRAGMA table_info(${table});`).all() as any[];
  const columnExists = info.some((c) => c.name === column);
  if (!columnExists) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${type};`);
    // eslint-disable-next-line no-console
    console.log(`[db] column added: ${table}.${column}`);
  }
}

function ensureIndex(table: string, name: string, createSql: string) {
  const info = db.prepare(`PRAGMA index_list(${table});`).all() as any[];
  const exists = info.some((idx) => idx.name === name);
  if (!exists) {
    db.exec(createSql);
    // eslint-disable-next-line no-console
    console.log(`[db] index created: ${name}`);
  }
}
