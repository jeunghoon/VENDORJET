"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = void 0;
exports.mapRow = mapRow;
exports.mapRows = mapRows;
const better_sqlite3_1 = __importDefault(require("better-sqlite3"));
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
// __dirname = server/src/db → 최상위까지 두 단계 올라감
const dbPath = path_1.default.join(__dirname, '..', '..', 'vendorjet.db');
const schemaPath = path_1.default.join(__dirname, '..', '..', 'schema.sql');
exports.db = new better_sqlite3_1.default(dbPath);
ensureSchema();
// snake_case -> camelCase 변환
const camel = (key) => key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
function mapRow(row) {
    if (!row)
        return row;
    const mapped = {};
    Object.keys(row).forEach((k) => {
        mapped[camel(k)] = row[k];
    });
    return mapped;
}
function mapRows(rows) {
    return rows.map((r) => mapRow(r));
}
function ensureSchema() {
    try {
        const rows = exports.db
            .prepare("SELECT name FROM sqlite_master WHERE type='table';")
            .all()
            .map((r) => r.name);
        const hasCore = rows.includes('users') && rows.includes('tenants');
        if (!hasCore) {
            const schema = fs_1.default.readFileSync(schemaPath, 'utf8');
            exports.db.exec(schema);
            // eslint-disable-next-line no-console
            console.log('[db] schema applied (core tables created)');
        }
        ensureTable('membership_requests', `CREATE TABLE IF NOT EXISTS membership_requests (
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
      );`);
        ensureTable('buyer_requests', `CREATE TABLE IF NOT EXISTS buyer_requests (
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
      );`);
        // 확장 컬럼 확인
        ensureColumn('tenants', 'phone', 'TEXT');
        ensureColumn('tenants', 'address', 'TEXT');
        ensureColumn('users', 'name', 'TEXT');
        ensureColumn('users', 'phone', 'TEXT');
        ensureColumn('memberships', 'status', 'TEXT');
        ensureColumn('membership_requests', 'company_phone', 'TEXT');
        ensureColumn('buyer_requests', 'seller_phone', 'TEXT');
        ensureColumn('buyer_requests', 'seller_address', 'TEXT');
        ensureColumn('buyer_requests', 'role', 'TEXT');
    }
    catch (err) {
        // eslint-disable-next-line no-console
        console.error('[db] schema check failed:', err);
    }
}
function ensureTable(name, createSql) {
    const exists = exports.db
        .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name = ?")
        .get(name);
    if (!exists) {
        exports.db.exec(createSql);
        // eslint-disable-next-line no-console
        console.log(`[db] table created: ${name}`);
    }
}
function ensureColumn(table, column, type) {
    const info = exports.db.prepare(`PRAGMA table_info(${table});`).all();
    const columnExists = info.some((c) => c.name === column);
    if (!columnExists) {
        exports.db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${type};`);
        // eslint-disable-next-line no-console
        console.log(`[db] column added: ${table}.${column}`);
    }
}
//# sourceMappingURL=client.js.map