import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import authController from './modules/auth/controller';
import { productsController } from './modules/products/controller';
import { customersController } from './modules/customers/controller';
import { ordersController } from './modules/orders/controller';
import { buyerController } from './modules/buyer/controller';
import { adminController } from './modules/admin/controller';
import { db } from './db/client';

const app = express();

function normalizeSellerMembershipRoles() {
  try {
    db.prepare(
      `UPDATE memberships
       SET role = 'manager'
       WHERE role = 'owner'
         AND user_id IN (
           SELECT id FROM users WHERE COALESCE(user_type, 'wholesale') = 'retail'
         )
         AND tenant_id IN (
           SELECT DISTINCT m.tenant_id
           FROM memberships m
           INNER JOIN users u ON u.id = m.user_id
           WHERE m.role = 'owner' AND COALESCE(u.user_type, 'wholesale') != 'retail'
         )`
    ).run();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[db] failed to normalize membership roles', err);
  }
}

normalizeSellerMembershipRoles();

function resolveBuyerTenantForUser(userId: string) {
  const row = db
    .prepare(
      `SELECT m.tenant_id AS tenant_id
       FROM memberships m
       WHERE m.user_id = ?
         AND EXISTS (
           SELECT 1
           FROM memberships owners
           INNER JOIN users ownerUsers ON ownerUsers.id = owners.user_id
           WHERE owners.tenant_id = m.tenant_id
             AND owners.role = 'owner'
             AND COALESCE(ownerUsers.user_type, 'wholesale') = 'retail'
         )
       ORDER BY m.rowid DESC
       LIMIT 1`
    )
    .get(userId) as { tenant_id?: string } | undefined;
  return row?.tenant_id ?? null;
}

function normalizeBuyerOrderMeta() {
  try {
    const pending = db
      .prepare(
        `SELECT o.id, o.created_by
         FROM orders o
         INNER JOIN users u ON u.id = o.created_by
         WHERE COALESCE(u.user_type, 'wholesale') = 'retail'
           AND (o.buyer_tenant_id IS NULL OR o.buyer_tenant_id = '')`
      )
      .all() as Array<{ id: string; created_by: string }>;
    const updateStmt = db.prepare(
      'UPDATE orders SET buyer_tenant_id = ?, buyer_user_id = ?, buyer_user_name = COALESCE(buyer_user_name, ?), buyer_user_email = COALESCE(buyer_user_email, ?) WHERE id = ?'
    );
    const userStmt = db.prepare('SELECT name, email FROM users WHERE id = ? LIMIT 1');
    const tx = db.transaction(() => {
      for (const row of pending) {
        const tenantId = resolveBuyerTenantForUser(row.created_by);
        if (!tenantId) continue;
        const user = userStmt.get(row.created_by) as { name?: string; email?: string } | undefined;
        const name = (user?.name ?? '').toString().trim();
        const email = (user?.email ?? '').toString().trim();
        const displayName = name.length > 0 ? name : email;
        updateStmt.run(tenantId, row.created_by, displayName || null, email || null, row.id);
      }
    });
    tx();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[db] failed to normalize buyer order metadata', err);
  }
}

normalizeBuyerOrderMeta();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// 헬스 체크
app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', authController);
app.use('/products', productsController);
app.use('/customers', customersController);
app.use('/orders', ordersController);
app.use('/buyer', buyerController);
app.use('/admin', adminController);

app.listen(env.port, () => {
  // eslint-disable-next-line no-console
  console.log(`Server listening on http://localhost:${env.port}`);
});
