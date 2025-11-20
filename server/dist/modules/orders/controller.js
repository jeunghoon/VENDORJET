"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ordersController = void 0;
const express_1 = require("express");
const client_1 = require("../../db/client");
const auth_1 = require("../../middleware/auth");
const code_generator_1 = require("../../utils/code_generator");
const router = (0, express_1.Router)();
router.use(auth_1.authMiddleware);
router.get('/', (req, res) => {
    const { q = '', status, openOnly, date } = req.query;
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    let base = 'SELECT * FROM orders WHERE tenant_id = ?';
    const params = [tenantId];
    if (status) {
        base += ' AND status = ?';
        params.push(status);
    }
    if (openOnly === 'true') {
        base += " AND status IN ('pending','confirmed','shipped')";
    }
    if (date) {
        base += ' AND substr(created_at,1,10) = ?';
        params.push(date);
    }
    if (q) {
        const like = `%${q.toLowerCase()}%`;
        base += ' AND (LOWER(code) LIKE ? OR LOWER(buyer_name) LIKE ? OR LOWER(buyer_contact) LIKE ?)';
        params.push(like, like, like);
    }
    base += ' ORDER BY created_at DESC';
    const rows = client_1.db.prepare(base).all(params);
    res.json((0, client_1.mapRows)(rows));
});
router.get('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const orderRow = client_1.db
        .prepare('SELECT * FROM orders WHERE id = ? AND tenant_id = ?')
        .get([id, tenantId]);
    if (!orderRow)
        return res.status(404).json({ error: 'not found' });
    const lines = (0, client_1.mapRows)(client_1.db.prepare('SELECT * FROM order_lines WHERE order_id = ? ORDER BY id ASC').all(id));
    const order = (0, client_1.mapRow)(orderRow);
    order.lines = lines;
    res.json(order);
});
router.post('/', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const { buyerName = '', buyerContact = '', buyerNote = null, items = [], desiredDeliveryDate } = req.body || {};
    if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: 'items required' });
    }
    const id = `o_${Date.now()}`;
    const code = (0, code_generator_1.generateOrderCode)(new Date());
    const createdAt = new Date();
    let itemCount = 0;
    let total = 0;
    const normalizedItems = [];
    for (const it of items) {
        if (!it.productId || !it.quantity || !it.unitPrice)
            continue;
        itemCount += Number(it.quantity);
        total += Number(it.quantity) * Number(it.unitPrice);
        normalizedItems.push({
            productId: it.productId,
            productName: it.productName ?? `Product ${it.productId}`,
            quantity: Number(it.quantity),
            unitPrice: Number(it.unitPrice),
        });
    }
    total = parseFloat(total.toFixed(2));
    const insertOrder = client_1.db.prepare('INSERT INTO orders (id, tenant_id, code, buyer_name, buyer_contact, buyer_note, status, total, item_count, created_at, updated_at, update_note, desired_delivery_date) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)');
    const insertLine = client_1.db.prepare('INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)');
    const trx = client_1.db.transaction(() => {
        insertOrder.run(id, tenantId, code, buyerName, buyerContact, buyerNote, 'pending', total, itemCount, createdAt.toISOString(), createdAt.toISOString(), 'Created via API', desiredDeliveryDate ?? new Date(createdAt.getTime() + 24 * 60 * 60 * 1000).toISOString());
        normalizedItems.forEach((line) => {
            insertLine.run(id, line.productId, line.productName, line.quantity, line.unitPrice);
        });
    });
    trx();
    res.status(201).json({ id, code, total, itemCount, status: 'pending', createdAt, buyerName, buyerContact });
});
// 상태/배송 메타 업데이트 (배송 처리/완료 등)
router.patch('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const { status, buyerNote, updateNote, desiredDeliveryDate } = req.body || {};
    const existing = client_1.db
        .prepare('SELECT id FROM orders WHERE id = ? AND tenant_id = ?')
        .get(id, tenantId);
    if (!existing)
        return res.status(404).json({ error: 'not found' });
    client_1.db.prepare(`UPDATE orders
     SET status = COALESCE(?, status),
         buyer_note = COALESCE(?, buyer_note),
         update_note = COALESCE(?, update_note),
         desired_delivery_date = COALESCE(?, desired_delivery_date),
         updated_at = ?
     WHERE id = ? AND tenant_id = ?`).run(status, buyerNote, updateNote, desiredDeliveryDate, new Date().toISOString(), id, tenantId);
    res.json({ id, status, buyerNote, updateNote, desiredDeliveryDate });
});
router.delete('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const trx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM order_lines WHERE order_id = ?').run(id);
        client_1.db.prepare('DELETE FROM orders WHERE id = ? AND tenant_id = ?').run(id, tenantId);
    });
    trx();
    res.status(204).end();
});
exports.ordersController = router;
//# sourceMappingURL=controller.js.map