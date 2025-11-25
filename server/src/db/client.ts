import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';

// __dirname = server/src/db → 최상위까지 두 단계 올라감
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
        status TEXT,
        created_at TEXT
      );`
    );

    // 확장 컬럼 확인
    ensureColumn('tenants', 'phone', 'TEXT');
    ensureColumn('tenants', 'address', 'TEXT');
    ensureColumn('users', 'name', 'TEXT');
    ensureColumn('users', 'phone', 'TEXT');
    ensureColumn('users', 'address', 'TEXT');
    ensureColumn('users', 'created_at', 'TEXT');
    ensureColumn('users', 'last_login_at', 'TEXT');
    ensureColumn('users', 'user_type', 'TEXT');
    ensureColumn('memberships', 'status', 'TEXT');
    ensureColumn('membership_requests', 'company_phone', 'TEXT');
    ensureColumn('buyer_requests', 'seller_phone', 'TEXT');
    ensureColumn('buyer_requests', 'seller_address', 'TEXT');
    ensureColumn('buyer_requests', 'role', 'TEXT');
    ensureColumn('buyer_requests', 'user_id', 'TEXT');
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
