import { Router } from 'express';
import { db, mapRow, mapRows } from '../../db/client';
import { authMiddleware } from '../../middleware/auth';
import { generateOrderCode } from '../../utils/code_generator';

type OrderRow = {
  id: string;
  tenant_id: string;
  code: string;
  created_source?: string | null;
  buyer_name: string;
  buyer_contact: string;
  buyer_note?: string | null;
  status: string;
  total: number;
  item_count: number;
  created_at: string;
  created_by?: string | null;
  updated_at?: string | null;
  updated_by?: string | null;
  update_note?: string | null;
  desired_delivery_date?: string | null;
  status_updated_at?: string | null;
  status_updated_by?: string | null;
};

type OrderLineRow = {
  id: number;
  order_id: string;
  product_id: string;
  product_name: string;
  quantity: number;
  unit_price: number;
};

const router = Router();
router.use(authMiddleware);

const selectOrderStmt = db.prepare('SELECT * FROM orders WHERE id = ? AND tenant_id = ?');
const selectLinesStmt = db.prepare('SELECT * FROM order_lines WHERE order_id = ? ORDER BY id ASC');
const selectEventsStmt = db.prepare(
  'SELECT id, action, actor, note, created_at FROM order_events WHERE order_id = ? AND tenant_id = ? ORDER BY id DESC'
);

function recordEvent(orderId: string, tenantId: string, action: string, actor: string, note?: string) {
  db.prepare(
    'INSERT INTO order_events (order_id, tenant_id, action, actor, note, created_at) VALUES (?,?,?,?,?,?)'
  ).run(orderId, tenantId, action, actor, note ?? null, new Date().toISOString());
}

router.get('/', (req, res) => {
  const { q = '', status, openOnly, date } = req.query as Record<string, string>;
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });

  let base = 'SELECT * FROM orders WHERE tenant_id = ?';
  const params: any[] = [tenantId];
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

  const rows = db.prepare(base).all(params as any);
  res.json(mapRows(rows as any[]));
});

router.get('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });

  const order = loadOrderWithLines(id, tenantId);
  if (!order) return res.status(404).json({ error: 'not found' });
  res.json(order);
});

router.post('/', (req, res) => {
  const tenantId = req.user?.tenantId;
  const actor = req.user?.userId ?? 'unknown';
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const { buyerName = '', buyerContact = '', buyerNote = null, items = [], desiredDeliveryDate } =
    req.body || {};
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'items required' });
  }

  const code = generateOrderCode(new Date());
  const id = code; // 주문 번호 자체를 기본 키로 사용
  const createdAt = new Date();
  let itemCount = 0;
  let total = 0;
  const normalizedItems: { productId: string; productName: string; quantity: number; unitPrice: number }[] =
    [];
  for (const it of items) {
    if (!it.productId || !it.quantity || !it.unitPrice) continue;
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

  const insertOrder = db.prepare(
    `INSERT INTO orders (
      id, tenant_id, code, created_source, buyer_name, buyer_contact, buyer_note, status, total, item_count,
      created_at, created_by, updated_at, updated_by, update_note, status_updated_at, status_updated_by,
      desired_delivery_date
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  );
  const insertLine = db.prepare(
    'INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)'
  );

  const trx = db.transaction(() => {
    insertOrder.run(
      id,
      tenantId,
      code,
      'seller_portal',
      buyerName,
      buyerContact,
      buyerNote,
      'pending',
      total,
      itemCount,
      createdAt.toISOString(),
      actor,
      createdAt.toISOString(),
      actor,
      'Created via API',
      createdAt.toISOString(),
      actor,
      desiredDeliveryDate ?? new Date(createdAt.getTime() + 24 * 60 * 60 * 1000).toISOString()
    );
    normalizedItems.forEach((line) => {
      insertLine.run(id, line.productId, line.productName, line.quantity, line.unitPrice);
    });
    recordEvent(id, tenantId, 'created', actor, '주문 접수');
  });

  trx();

  const created = loadOrderWithLines(id, tenantId);
  res.status(201).json(created);
});

// 상태/배송 메타 업데이트
router.patch('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const actor = req.user?.userId ?? 'unknown';
  const id = req.params.id;
  const { status, buyerNote, updateNote, desiredDeliveryDate, lines, total, itemCount } = req.body || {};
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });

  const existing = db
    .prepare('SELECT status, status_updated_at, status_updated_by, total, item_count, desired_delivery_date FROM orders WHERE id = ? AND tenant_id = ?')
    .get(id, tenantId) as any;
  if (!existing) return res.status(404).json({ error: 'not found' });
  const existingLines = mapRows<OrderLineRow>(
    db.prepare('SELECT * FROM order_lines WHERE order_id = ? ORDER BY id ASC').all(id) as any[]
  );

  const nowIso = new Date().toISOString();
  const statusChanged = typeof status === 'string' && status.length > 0 && status !== existing.status;
  const statusUpdatedAt = statusChanged ? nowIso : undefined;
  const statusUpdatedBy = statusChanged ? actor : undefined;
  let normalizedLines: OrderLineRow[] | undefined;
  let newItemCount = existing.item_count as number;
  let newTotal = existing.total as number;

  if (Array.isArray(lines) && lines.length > 0) {
    normalizedLines = (lines as any[]).map((it, idx) => ({
      id: idx + 1,
      order_id: id,
      product_id: it.productId ?? it.product_id ?? `manual_${idx + 1}`,
      product_name: it.productName ?? it.product_name ?? `Item ${idx + 1}`,
      quantity: Number(it.quantity ?? 0),
      unit_price: Number(it.unitPrice ?? 0),
    }));
    newItemCount = normalizedLines.reduce((sum, l) => sum + l.quantity, 0);
    newTotal = normalizedLines.reduce((sum, l) => sum + l.quantity * l.unit_price, 0);
  }

  if (typeof total === 'number' && !isNaN(total)) {
    newTotal = total;
  }
  if (typeof itemCount === 'number' && !isNaN(itemCount)) {
    newItemCount = itemCount;
  }

  db.prepare(
    `UPDATE orders
     SET status = COALESCE(?, status),
         buyer_note = COALESCE(?, buyer_note),
         update_note = COALESCE(?, update_note),
         desired_delivery_date = COALESCE(?, desired_delivery_date),
         item_count = ?,
         total = ?,
         updated_at = ?,
         updated_by = ?,
         status_updated_at = COALESCE(?, status_updated_at),
         status_updated_by = COALESCE(?, status_updated_by)
     WHERE id = ? AND tenant_id = ?`
  ).run(
    status,
    buyerNote,
    updateNote,
    desiredDeliveryDate,
    newItemCount,
    newTotal,
    nowIso,
    actor,
    statusUpdatedAt,
    statusUpdatedBy,
    id,
    tenantId
  );

  if (normalizedLines) {
    const trxLines = db.transaction(() => {
      db.prepare('DELETE FROM order_lines WHERE order_id = ?').run(id);
      const insertLine = db.prepare(
        'INSERT INTO order_lines (order_id, product_id, product_name, quantity, unit_price) VALUES (?,?,?,?,?)'
      );
      normalizedLines!.forEach((line) => {
        insertLine.run(id, line.product_id, line.product_name, line.quantity, line.unit_price);
      });
    });
    trxLines();
  }

  if (statusChanged) {
    recordEvent(id, tenantId, 'status_changed', actor, status);
  }
  const changeNotes: string[] = [];
  if (normalizedLines) {
    changeNotes.push('품목/금액 수정');
    changeNotes.push(..._diffLines(existingLines, normalizedLines));
  }
  if (buyerNote) changeNotes.push('구매자 메모 변경');
  if (updateNote) changeNotes.push(updateNote);
  if (desiredDeliveryDate && desiredDeliveryDate !== existing.desired_delivery_date) {
    changeNotes.push(`출고일 ${existing.desired_delivery_date ?? ''} -> ${desiredDeliveryDate}`);
  }
  if (newTotal !== existing.total) {
    changeNotes.push(`총액 ${existing.total} -> ${newTotal}`);
  }
  if (changeNotes.length > 0) {
    recordEvent(id, tenantId, 'updated', actor, changeNotes.join('; '));
  }

  const updated = loadOrderWithLines(id, tenantId);
  res.json(updated);
});

router.delete('/:id', (req, res) => {
  const tenantId = req.user?.tenantId;
  const id = req.params.id;
  if (!tenantId) return res.status(400).json({ error: 'tenantId missing' });
  const trx = db.transaction(() => {
    db.prepare('DELETE FROM order_lines WHERE order_id = ?').run(id);
    db.prepare('DELETE FROM orders WHERE id = ? AND tenant_id = ?').run(id, tenantId);
  });
  trx();
  res.status(204).end();
});

function loadOrderWithLines(id: string, tenantId: string) {
  const orderRow = selectOrderStmt.get([id, tenantId] as any) as OrderRow | undefined;
  if (!orderRow) return null;
  const lines = mapRows<OrderLineRow>(selectLinesStmt.all(id) as any[]);
  const events = mapRows<any>(selectEventsStmt.all(id, tenantId) as any[]);
  const order = mapRow<OrderRow>(orderRow) as any;
  order.lines = lines;
  order.events = events;
  return order;
}

function _diffLines(prev: OrderLineRow[], next: OrderLineRow[]) {
  const notes: string[] = [];
  const maxLen = Math.max(prev.length, next.length);
  for (let i = 0; i < maxLen; i++) {
    const oldLine = prev[i];
    const newLine = next[i];
    if (!oldLine && newLine) {
      notes.push(`${newLine.product_name} 추가 ${newLine.quantity}개`);
      continue;
    }
    if (oldLine && !newLine) {
      notes.push(`${oldLine.product_name} 제거`);
      continue;
    }
    if (!oldLine || !newLine) continue;
    if (oldLine.product_name !== newLine.product_name) {
      notes.push(`${oldLine.product_name} -> ${newLine.product_name}`);
    }
    if (oldLine.quantity !== newLine.quantity) {
      notes.push(`${newLine.product_name} 수량 ${oldLine.quantity} -> ${newLine.quantity}`);
    }
    if (oldLine.unit_price !== newLine.unit_price) {
      notes.push(`${newLine.product_name} 단가 ${oldLine.unit_price} -> ${newLine.unit_price}`);
    }
  }
  return notes;
}

export const ordersController = router;
