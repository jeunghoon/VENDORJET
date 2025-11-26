"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buyerController = void 0;
const express_1 = require("express");
const client_1 = require("../../db/client");
const auth_1 = require("../../middleware/auth");
const code_generator_1 = require("../../utils/code_generator");
const router = (0, express_1.Router)();
router.use(auth_1.authMiddleware);
router.get('/stores', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const rows = client_1.db
        .prepare('SELECT id, name FROM customers WHERE tenant_id = ? ORDER BY name ASC')
        .all(tenantId);
    res.json((0, client_1.mapRows)(rows));
});
router.get('/history', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const limit = Number(req.query.limit ?? 10);
    const ordersStmt = client_1.db.prepare(`SELECT id, code, buyer_name, buyer_contact, buyer_note, total, item_count, created_at, desired_delivery_date
     FROM orders WHERE tenant_id = ? ORDER BY created_at DESC LIMIT ?`);
    const orders = (0, client_1.mapRows)(ordersStmt.all([tenantId, limit]));
    const history = orders.map((o) => ({
        ...o,
        summary: `${o.itemCount}개 품목 : 총수량 ${o.itemCount}`,
    }));
    res.json(history);
});
router.post('/cart', (req, res) => {
    const tenantId = req.user?.tenantId;
    const actor = req.user?.userId ?? 'unknown';
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const { storeId, buyerContact = '', desiredDeliveryDate, note = '', items = [] } = req.body || {};
    if (!storeId || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: 'storeId and items are required' });
    }
    const customer = client_1.db
        .prepare('SELECT name FROM customers WHERE id = ? AND tenant_id = ?')
        .get([storeId, tenantId]);
    const buyerName = customer?.name ?? 'Unspecified Store';
    const code = (0, code_generator_1.generateOrderCode)(new Date());
    const id = code;
    const createdAt = new Date();
    let itemCount = 0;
    let total = 0;
    const insertOrder = client_1.db.prepare(`INSERT INTO orders (
      id, tenant_id, code, created_source, buyer_name, buyer_contact, buyer_note, status, total, item_count,
      created_at, created_by, updated_at, updated_by, update_note, status_updated_at, status_updated_by,
      desired_delivery_date
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    const insertLine = client_1.db.prepare('INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)');
    const trx = client_1.db.transaction(() => {
        const normalized = items.map((it) => ({
            productId: it.productId,
            productName: it.productName ?? `Product ${it.productId}`,
            quantity: Number(it.quantity ?? 1),
            unitPrice: Number(it.unitPrice ?? 0),
        }));
        normalized.forEach((n) => {
            itemCount += n.quantity;
            total += n.quantity * n.unitPrice;
        });
        total = parseFloat(total.toFixed(2));
        insertOrder.run(id, tenantId, code, 'buyer_portal', buyerName, buyerContact, note, 'pending', total, itemCount, createdAt.toISOString(), actor, createdAt.toISOString(), actor, 'Created via buyer portal', createdAt.toISOString(), actor, desiredDeliveryDate ?? new Date(createdAt.getTime() + 24 * 60 * 60 * 1000).toISOString());
        normalized.forEach((n) => insertLine.run(id, n.productId, n.productName, n.quantity, n.unitPrice));
    });
    trx();
    client_1.db.prepare('INSERT INTO order_events (order_id, tenant_id, action, actor, note, created_at) VALUES (?,?,?,?,?,?)').run(id, tenantId, 'created', actor, '주문 접수(바이어)', createdAt.toISOString());
    res.status(201).json({ id, code, total, itemCount, buyerName, buyerContact });
});
exports.buyerController = router;
//# sourceMappingURL=controller.js.map