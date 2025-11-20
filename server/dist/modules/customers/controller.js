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
    let base = 'SELECT * FROM customers WHERE tenant_id = ?';
    const params = [tenantId];
    if (tier) {
        base += ' AND tier = ?';
        params.push(tier);
    }
    if (segment) {
        base += ' AND segment = ?';
        params.push(segment);
    }
    if (q) {
        base += ' AND (LOWER(name) LIKE ? OR LOWER(contact_name) LIKE ? OR LOWER(email) LIKE ?)';
        const like = `%${q.toLowerCase()}%`;
        params.push(like, like, like);
    }
    base += ' ORDER BY created_at DESC';
    const rows = client_1.db.prepare(base).all(params);
    res.json((0, client_1.mapRows)(rows));
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
    const id = req.params.id;
    client_1.db.prepare('DELETE FROM customers WHERE id = ? AND tenant_id = ?').run(id, tenantId);
    res.status(204).end();
});
exports.customersController = router;
//# sourceMappingURL=controller.js.map