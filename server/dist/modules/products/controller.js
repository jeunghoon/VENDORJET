"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.productsController = void 0;
const express_1 = require("express");
const client_1 = require("../../db/client");
const auth_1 = require("../../middleware/auth");
const router = (0, express_1.Router)();
router.use(auth_1.authMiddleware);
router.get('/', (req, res) => {
    const { q = '', topCategory, lowStockOnly } = req.query;
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    let base = 'SELECT * FROM products WHERE tenant_id = ?';
    const params = [tenantId];
    if (topCategory) {
        base += ' AND json_extract(categories, "$[0]") = ?';
        params.push(topCategory);
    }
    if (lowStockOnly === 'true') {
        base += ' AND low_stock = 1';
    }
    if (q) {
        base += ' AND (LOWER(name) LIKE ? OR LOWER(sku) LIKE ?)';
        params.push(`%${q.toLowerCase()}%`, `%${q.toLowerCase()}%`);
    }
    const rows = client_1.db.prepare(base).all(params);
    const products = (0, client_1.mapRows)(rows).map((r) => ({
        ...r,
        categories: safeJson(r.categories, []),
        tags: safeJson(r.tags, []),
        lowStock: Boolean(r.lowStock ?? r.low_stock),
    }));
    res.json(products);
});
router.get('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const row = client_1.db
        .prepare('SELECT * FROM products WHERE id = ? AND tenant_id = ?')
        .get([id, tenantId]);
    if (!row)
        return res.status(404).json({ error: 'not found' });
    const product = (0, client_1.mapRow)(row);
    return res.json({
        ...product,
        categories: safeJson(product.categories, []),
        tags: safeJson(product.tags, []),
        lowStock: Boolean(product.lowStock),
    });
});
router.post('/', (req, res) => {
    const tenantId = req.user?.tenantId;
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId missing' });
    const { sku, name, price = 0, variantsCount = 1, categories = [], tags = [], lowStock = false, imageUrl = null } = req.body || {};
    if (!sku || !name)
        return res.status(400).json({ error: 'sku and name required' });
    const id = `p_${Date.now()}`;
    client_1.db.prepare('INSERT INTO products (id, tenant_id, sku, name, price, variants_count, categories, tags, low_stock, image_url) VALUES (?,?,?,?,?,?,?,?,?,?)').run(id, tenantId, sku, name, Number(price), Number(variantsCount), JSON.stringify(categories), JSON.stringify(tags), lowStock ? 1 : 0, imageUrl);
    res.status(201).json({ id, sku, name, price: Number(price) });
});
router.put('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    const existing = client_1.db
        .prepare('SELECT id FROM products WHERE id = ? AND tenant_id = ?')
        .get([id, tenantId]);
    if (!existing)
        return res.status(404).json({ error: 'not found' });
    const { sku, name, price, variantsCount, categories, tags, lowStock, imageUrl } = req.body || {};
    client_1.db.prepare(`UPDATE products
     SET sku = COALESCE(?, sku),
         name = COALESCE(?, name),
         price = COALESCE(?, price),
         variants_count = COALESCE(?, variants_count),
         categories = COALESCE(?, categories),
         tags = COALESCE(?, tags),
         low_stock = COALESCE(?, low_stock),
         image_url = COALESCE(?, image_url)
     WHERE id = ? AND tenant_id = ?`).run(sku, name, price !== undefined ? Number(price) : null, variantsCount !== undefined ? Number(variantsCount) : null, categories !== undefined ? JSON.stringify(categories) : null, tags !== undefined ? JSON.stringify(tags) : null, lowStock !== undefined ? (lowStock ? 1 : 0) : null, imageUrl ?? null, id, tenantId);
    res.json({ id, sku, name });
});
router.delete('/:id', (req, res) => {
    const tenantId = req.user?.tenantId;
    const id = req.params.id;
    client_1.db.prepare('DELETE FROM products WHERE id = ? AND tenant_id = ?').run([id, tenantId]);
    res.status(204).end();
});
exports.productsController = router;
function safeJson(value, fallback) {
    try {
        if (typeof value === 'string')
            return JSON.parse(value);
    }
    catch (_) {
        //
    }
    return fallback;
}
//# sourceMappingURL=controller.js.map