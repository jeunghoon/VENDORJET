import { Router } from 'express';
import { db, mapRows, mapRow } from '../../db/client';
import { authMiddleware } from '../../middleware/auth';

const router = Router();

type ProductRow = {
  id: string;
  tenant_id: string;
  sku: string;
  name: string;
  price: number;
  variants_count: number;
  categories: string;
  tags: string;
  low_stock: number;
  image_url?: string | null;
};

router.use(authMiddleware);

router.get('/', (req, res) => {
  const { q = '', topCategory, lowStockOnly } = req.query as Record<string, string>;
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });

  let base = 'SELECT * FROM products WHERE tenant_id = ?';
  const params: any[] = [tenantId];

  if (lowStockOnly === 'true') {
    base += ' AND low_stock = 1';
  }
  if (q) {
    base += ' AND (LOWER(name) LIKE ? OR LOWER(sku) LIKE ?)';
    params.push(`%${q.toLowerCase()}%`, `%${q.toLowerCase()}%`);
  }

  const rows = db.prepare(base).all(params as any);
  let products = mapRows<ProductRow>(rows as any[]).map((r: any) => ({
    ...r,
    categories: safeJson(r.categories, []),
    tags: safeJson(r.tags, []),
    lowStock: Boolean(r.lowStock ?? r.low_stock),
  }));
  if (topCategory) {
    const target = topCategory.toString();
    products = products.filter(
      (p: any) => Array.isArray(p.categories) && p.categories.length > 0 && p.categories[0] === target
    );
  }
  res.json(products);
});

router.get('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  const row = db
    .prepare('SELECT * FROM products WHERE id = ? AND tenant_id = ?')
    .get([id, tenantId] as any);
  if (!row) return res.status(404).json({ error: 'not found' });
  const product = mapRow<ProductRow>(row);
  return res.json({
    ...product,
    categories: safeJson(product.categories, []),
    tags: safeJson(product.tags, []),
    lowStock: Boolean((product as any).lowStock),
  });
});

router.post('/', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const { sku, name, price = 0, variantsCount = 1, categories = [], tags = [], lowStock = false, imageUrl = null } =
    req.body || {};
  if (!sku || !name) return res.status(400).json({ error: 'sku and name required' });
  const id = `p_${Date.now()}`;
  db.prepare(
    'INSERT INTO products (id, tenant_id, sku, name, price, variants_count, categories, tags, low_stock, image_url) VALUES (?,?,?,?,?,?,?,?,?,?)'
  ).run(
    id,
    tenantId,
    sku,
    name,
    Number(price),
    Number(variantsCount),
    JSON.stringify(categories),
    JSON.stringify(tags),
    lowStock ? 1 : 0,
    imageUrl
  );
  res.status(201).json({ id, sku, name, price: Number(price) });
});

router.put('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  const existing = db
    .prepare('SELECT id FROM products WHERE id = ? AND tenant_id = ?')
    .get([id, tenantId] as any);
  if (!existing) return res.status(404).json({ error: 'not found' });
  const { sku, name, price, variantsCount, categories, tags, lowStock, imageUrl } = req.body || {};
  db.prepare(
    `UPDATE products
     SET sku = COALESCE(?, sku),
         name = COALESCE(?, name),
         price = COALESCE(?, price),
         variants_count = COALESCE(?, variants_count),
         categories = COALESCE(?, categories),
         tags = COALESCE(?, tags),
         low_stock = COALESCE(?, low_stock),
         image_url = COALESCE(?, image_url)
     WHERE id = ? AND tenant_id = ?`
  ).run(
    sku,
    name,
    price !== undefined ? Number(price) : null,
    variantsCount !== undefined ? Number(variantsCount) : null,
    categories !== undefined ? JSON.stringify(categories) : null,
    tags !== undefined ? JSON.stringify(tags) : null,
    lowStock !== undefined ? (lowStock ? 1 : 0) : null,
    imageUrl ?? null,
    id,
    tenantId
  );
  res.json({ id, sku, name });
});

router.delete('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  db.prepare('DELETE FROM products WHERE id = ? AND tenant_id = ?').run([id, tenantId] as any);
  res.status(204).end();
});

export const productsController = router;

function safeJson<T>(value: any, fallback: T): T {
  try {
    if (typeof value === 'string') return JSON.parse(value) as T;
  } catch (_) {
    //
  }
  return fallback;
}
