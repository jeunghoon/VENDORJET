"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.customersController = void 0;
const express_1 = require("express");
const client_1 = require("../../db/client");
const auth_1 = require("../../middleware/auth");
const router = (0, express_1.Router)();
router.use(auth_1.authMiddleware);
router.get('/', (req, res) => {
    const { q = '', tier, segment } = req.query;
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const tenantRow = client_1.db.prepare('SELECT name FROM tenants WHERE id = ? LIMIT 1').get(tenantId);
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
    const params = [];
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
    const rows = client_1.db.prepare(base).all(params);
    res.json((0, client_1.mapRows)(rows));
});
router.post('/segments', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const { name, original } = req.body || {};
    const trimmed = (name ?? '').toString().trim();
    if (!trimmed)
        return res.status(400).json({ error: 'name required' });
    const tx = client_1.db.transaction(() => {
        if (original) {
            client_1.db.prepare('UPDATE segments SET name = ? WHERE tenant_id = ? AND name = ?').run(trimmed, tenantId, original);
            client_1.db.prepare('UPDATE customers SET segment = ? WHERE tenant_id = ? AND segment = ?').run(trimmed, tenantId, original);
        }
        const exists = client_1.db.prepare('SELECT 1 FROM segments WHERE tenant_id = ? AND name = ? LIMIT 1').get(tenantId, trimmed);
        if (!exists) {
            client_1.db.prepare('INSERT INTO segments (tenant_id, name) VALUES (?, ?)').run(tenantId, trimmed);
        }
    });
    tx();
    return res.json({ name: trimmed });
});
router.delete('/segments', (req, res) => {
    const tenantId = req.user?.tenantId;
    const name = req.query.name?.toString();
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    if (!name)
        return res.status(400).json({ error: 'name required' });
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM segments WHERE tenant_id = ? AND name = ?').run(tenantId, name);
        client_1.db.prepare('UPDATE customers SET segment = ? WHERE tenant_id = ? AND segment = ?').run('', tenantId, name);
    });
    tx();
    return res.status(204).end();
});
router.get('/segments', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const rows = client_1.db
        .prepare('SELECT name FROM segments WHERE tenant_id = ? ORDER BY name ASC')
        .all(tenantId);
    res.json(rows.map((r) => r.name));
});
router.post('/', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const { name, contactName = '', email = '', tier = 'silver', segment = '' } = req.body || {};
    if (!name)
        return res.status(400).json({ error: 'name required' });
    const id = `c_${Date.now()}`;
    const createdAt = new Date().toISOString();
    client_1.db.prepare('INSERT INTO customers (id, tenant_id, name, contact_name, email, tier, created_at, segment) VALUES (?,?,?,?,?,?,?,?)').run(id, tenantId, name, contactName, email, tier, createdAt, segment);
    res.status(201).json({ id, name, contactName, email, tier, segment });
});
router.put('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const existing = client_1.db.prepare('SELECT id FROM customers WHERE id = ? AND tenant_id = ?').get(id, tenantId);
    if (!existing)
        return res.status(404).json({ error: 'not found' });
    const { name, contactName, email, tier, segment } = req.body || {};
    client_1.db.prepare(`UPDATE customers
     SET name = COALESCE(?, name),
         contact_name = COALESCE(?, contact_name),
         email = COALESCE(?, email),
         tier = COALESCE(?, tier),
         segment = COALESCE(?, segment)
     WHERE id = ? AND tenant_id = ?`).run(name, contactName, email, tier, segment, id, tenantId);
    res.json({ id, name, contactName, email, tier, segment });
});
router.delete('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const id = req.params.id;
    const existing = client_1.db
        .prepare('SELECT name FROM customers WHERE id = ? AND tenant_id = ?')
        .get(id, tenantId);
    client_1.db.prepare('DELETE FROM customers WHERE id = ? AND tenant_id = ?').run(id, tenantId);
    if (existing?.name) {
        const tenantRow = client_1.db
            .prepare('SELECT name FROM tenants WHERE id = ? LIMIT 1')
            .get(tenantId);
        const sellerName = tenantRow?.name;
        if (sellerName) {
            const relatedRequests = client_1.db
                .prepare('SELECT id, user_id FROM buyer_requests WHERE seller_company = ? AND buyer_company = ?')
                .all(sellerName, existing.name);
            for (const reqRow of relatedRequests) {
                if (reqRow.user_id) {
                    client_1.db.prepare('DELETE FROM memberships WHERE user_id = ? AND tenant_id = ?').run(reqRow.user_id, tenantId);
                }
                client_1.db.prepare('DELETE FROM buyer_requests WHERE id = ?').run(reqRow.id);
            }
        }
    }
    res.status(204).end();
});
exports.customersController = router;
//# sourceMappingURL=controller.js.map