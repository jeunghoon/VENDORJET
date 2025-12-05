CREATE TABLE tenants (
  id TEXT PRIMARY KEY,
  name TEXT,
  locale TEXT,
  created_at TEXT,
  phone TEXT,
  address TEXT,
  representative TEXT
);

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  password_hash TEXT,
  name TEXT,
  phone TEXT,
  language_preference TEXT,
  primary_tenant_id TEXT
);

CREATE TABLE memberships (
  user_id TEXT,
  tenant_id TEXT,
  role TEXT,
  status TEXT,
  PRIMARY KEY (user_id, tenant_id)
);
   CREATE TABLE products (id TEXT PRIMARY KEY, tenant_id TEXT, sku TEXT, name TEXT, price REAL, variants_count INTEGER, categories TEXT, tags TEXT, low_stock INTEGER, image_url TEXT);
   CREATE TABLE customers (id TEXT PRIMARY KEY, tenant_id TEXT, name TEXT, contact_name TEXT, email TEXT, tier TEXT, created_at TEXT, segment TEXT);
   CREATE TABLE segments (id INTEGER PRIMARY KEY AUTOINCREMENT, tenant_id TEXT, name TEXT);
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  tenant_id TEXT,
  code TEXT UNIQUE,
  created_source TEXT,
  buyer_name TEXT,
  buyer_contact TEXT,
  buyer_note TEXT,
  status TEXT,
  total REAL,
  item_count INTEGER,
  created_at TEXT,
  created_by TEXT,
  updated_at TEXT,
  updated_by TEXT,
  update_note TEXT,
  status_updated_at TEXT,
  status_updated_by TEXT,
  desired_delivery_date TEXT
);
CREATE TABLE order_lines (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT, product_id TEXT, product_name TEXT, quantity INTEGER, unit_price REAL);
CREATE TABLE order_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT,
  tenant_id TEXT,
  action TEXT,
  actor TEXT,
  note TEXT,
  created_at TEXT
);
CREATE TABLE order_code_sequences (date TEXT PRIMARY KEY, last_seq INTEGER);
CREATE TABLE dashboard_cache (tenant_id TEXT PRIMARY KEY, snapshot_json TEXT, cached_at TEXT);
CREATE TABLE membership_requests (
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

CREATE TABLE buyer_requests (
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
