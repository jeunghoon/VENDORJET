import { Router } from 'express';
import { db, mapRows } from '../../db/client';
import { authMiddleware } from '../../middleware/auth';

type CustomerRow = {
  id: string;
  tenant_id: string;
  name: string;
  contact_name: string;
  email: string;
  tier: string;
  created_at: string;
  segment: string;
};

const router = Router();
router.use(authMiddleware);

router.get('/', (req, res) => {
  const { q = '', tier, segment } = req.query as Record<string, string>;
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });

  const tenantRow = db.prepare('SELECT name FROM tenants WHERE id = ? LIMIT 1').get(tenantId) as { name?: string } | undefined;
  const sellerName = tenantRow?.name ?? null;
  const statusSubquery = sellerName
    ? `(SELECT status FROM buyer_requests br WHERE br.email = c.email AND br.seller_company = ? ORDER BY br.created_at DESC LIMIT 1)`
    : `(SELECT status FROM buyer_requests br WHERE br.email = c.email ORDER BY br.created_at DESC LIMIT 1)`;
  const phoneSubquery = sellerName
    ? `(SELECT COALESCE(br.phone, '') FROM buyer_requests br WHERE br.seller_company = ? AND br.buyer_company = c.name ORDER BY br.created_at DESC LIMIT 1)`
    : `(SELECT COALESCE(br.phone, '') FROM buyer_requests br WHERE br.buyer_company = c.name ORDER BY br.created_at DESC LIMIT 1)`;
  const addressSubquery = sellerName
    ? `(SELECT COALESCE(br.buyer_address, '') FROM buyer_requests br WHERE br.seller_company = ? AND br.buyer_company = c.name ORDER BY br.created_at DESC LIMIT 1)`
    : `(SELECT COALESCE(br.buyer_address, '') FROM buyer_requests br WHERE br.buyer_company = c.name ORDER BY br.created_at DESC LIMIT 1)`;

  let base = `SELECT c.*,
        COALESCE(${statusSubquery}, '') AS buyer_status,
        COALESCE(${phoneSubquery}, '') AS contact_phone,
        COALESCE(${addressSubquery}, '') AS contact_address
      FROM customers c WHERE c.tenant_id = ?`;
  const params: any[] = [];
  if (sellerName) {
    params.push(sellerName, sellerName, sellerName);
  }
  params.push(tenantId);
  if (tier) {
    base += ' AND c.tier = ?';
    params.push(tier);
  }
  if (segment) {
    base += ' AND c.segment = ?';
    params.push(segment);
  }
  if (q) {
    base += ' AND (LOWER(c.name) LIKE ? OR LOWER(c.contact_name) LIKE ? OR LOWER(c.email) LIKE ?)';
    const like = `%${q.toLowerCase()}%`;
    params.push(like, like, like);
  }
  base += ' ORDER BY c.created_at DESC';

  const rows = db.prepare(base).all(params as any);
  res.json(mapRows(rows as any[]));
});


router.post('/segments', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const { name, original } = req.body || {};
  const trimmed = (name ?? '').toString().trim();
  if (!trimmed) return res.status(400).json({ error: 'name required' });
  const tx = db.transaction(() => {
    if (original) {
      db.prepare('UPDATE segments SET name = ? WHERE tenant_id = ? AND name = ?').run(trimmed, tenantId, original);
      db.prepare('UPDATE customers SET segment = ? WHERE tenant_id = ? AND segment = ?').run(trimmed, tenantId, original);
    }
    const exists = db.prepare('SELECT 1 FROM segments WHERE tenant_id = ? AND name = ? LIMIT 1').get(tenantId, trimmed);
    if (!exists) {
      db.prepare('INSERT INTO segments (tenant_id, name) VALUES (?, ?)').run(tenantId, trimmed);
    }
  });
  tx();
  return res.json({ name: trimmed });
});

router.delete('/segments', (req, res) => {
  const tenantId = req.user?.tenantId;
  const name = (req.query.name as string | undefined)?.toString();
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  if (!name) return res.status(400).json({ error: 'name required' });
  const tx = db.transaction(() => {
    db.prepare('DELETE FROM segments WHERE tenant_id = ? AND name = ?').run(tenantId, name);
    db.prepare('UPDATE customers SET segment = ? WHERE tenant_id = ? AND segment = ?').run('', tenantId, name);
  });
  tx();
  return res.status(204).end();
});

router.get('/segments', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const rows = db
    .prepare('SELECT name FROM segments WHERE tenant_id = ? ORDER BY name ASC')
    .all(tenantId);
  res.json(rows.map((r: any) => r.name));
});

router.post('/', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const { name, contactName = '', email = '', tier = 'silver', segment = '' } = req.body || {};
  if (!name) return res.status(400).json({ error: 'name required' });
  const id = `c_${Date.now()}`;
  const createdAt = new Date().toISOString();
  db.prepare(
    'INSERT INTO customers (id, tenant_id, name, contact_name, email, tier, created_at, segment) VALUES (?,?,?,?,?,?,?,?)'
  ).run(id, tenantId, name, contactName, email, tier, createdAt, segment);
  res.status(201).json({ id, name, contactName, email, tier, segment });
});

router.put('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  const existing = db.prepare('SELECT id FROM customers WHERE id = ? AND tenant_id = ?').get(id, tenantId);
  if (!existing) return res.status(404).json({ error: 'not found' });
  const { name, contactName, email, tier, segment } = req.body || {};
  db.prepare(
    `UPDATE customers
     SET name = COALESCE(?, name),
         contact_name = COALESCE(?, contact_name),
         email = COALESCE(?, email),
         tier = COALESCE(?, tier),
         segment = COALESCE(?, segment)
     WHERE id = ? AND tenant_id = ?`
  ).run(name, contactName, email, tier, segment, id, tenantId);
  res.json({ id, name, contactName, email, tier, segment });
});

router.delete('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const id = req.params.id;
  const existing = db
    .prepare('SELECT name FROM customers WHERE id = ? AND tenant_id = ?')
    .get(id, tenantId) as { name?: string } | undefined;
  db.prepare('DELETE FROM customers WHERE id = ? AND tenant_id = ?').run(id, tenantId);

  if (existing?.name) {
    const tenantRow = db
      .prepare('SELECT name FROM tenants WHERE id = ? LIMIT 1')
      .get(tenantId) as { name?: string } | undefined;
    const sellerName = tenantRow?.name;
    if (sellerName) {
      const relatedRequests = db
        .prepare('SELECT id, user_id FROM buyer_requests WHERE seller_company = ? AND buyer_company = ?')
        .all(sellerName, existing.name) as Array<{ id: string; user_id?: string }>;
      for (const reqRow of relatedRequests) {
        if (reqRow.user_id) {
          db.prepare('DELETE FROM memberships WHERE user_id = ? AND tenant_id = ?').run(reqRow.user_id, tenantId);
        }
        db.prepare('DELETE FROM buyer_requests WHERE id = ?').run(reqRow.id);
      }
    }
  }

  res.status(204).end();
});

export const customersController = router;
