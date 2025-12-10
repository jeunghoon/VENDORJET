"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const morgan_1 = __importDefault(require("morgan"));
const env_1 = require("./config/env");
const controller_1 = __importDefault(require("./modules/auth/controller"));
const controller_2 = require("./modules/products/controller");
const controller_3 = require("./modules/customers/controller");
const controller_4 = require("./modules/orders/controller");
const controller_5 = require("./modules/buyer/controller");
const controller_6 = require("./modules/admin/controller");
const client_1 = require("./db/client");
const app = (0, express_1.default)();
function normalizeSellerMembershipRoles() {
    try {
        client_1.db.prepare(`UPDATE memberships
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
         )`).run();
    }
    catch (err) {
        // eslint-disable-next-line no-console
        console.error('[db] failed to normalize membership roles', err);
    }
}
normalizeSellerMembershipRoles();
function resolveBuyerTenantForUser(userId) {
    const row = client_1.db
        .prepare(`SELECT m.tenant_id AS tenant_id
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
       LIMIT 1`)
        .get(userId);
    return row?.tenant_id ?? null;
}
function normalizeBuyerOrderMeta() {
    try {
        const pending = client_1.db
            .prepare(`SELECT o.id, o.created_by
         FROM orders o
         INNER JOIN users u ON u.id = o.created_by
         WHERE COALESCE(u.user_type, 'wholesale') = 'retail'
           AND (o.buyer_tenant_id IS NULL OR o.buyer_tenant_id = '')`)
            .all();
        const updateStmt = client_1.db.prepare('UPDATE orders SET buyer_tenant_id = ?, buyer_user_id = ?, buyer_user_name = COALESCE(buyer_user_name, ?), buyer_user_email = COALESCE(buyer_user_email, ?) WHERE id = ?');
        const userStmt = client_1.db.prepare('SELECT name, email FROM users WHERE id = ? LIMIT 1');
        const tx = client_1.db.transaction(() => {
            for (const row of pending) {
                const tenantId = resolveBuyerTenantForUser(row.created_by);
                if (!tenantId)
                    continue;
                const user = userStmt.get(row.created_by);
                const name = (user?.name ?? '').toString().trim();
                const email = (user?.email ?? '').toString().trim();
                const displayName = name.length > 0 ? name : email;
                updateStmt.run(tenantId, row.created_by, displayName || null, email || null, row.id);
            }
        });
        tx();
    }
    catch (err) {
        // eslint-disable-next-line no-console
        console.error('[db] failed to normalize buyer order metadata', err);
    }
}
normalizeBuyerOrderMeta();
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use((0, morgan_1.default)('dev'));
// 헬스 체크
app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
});
app.use('/auth', controller_1.default);
app.use('/products', controller_2.productsController);
app.use('/customers', controller_3.customersController);
app.use('/orders', controller_4.ordersController);
app.use('/buyer', controller_5.buyerController);
app.use('/admin', controller_6.adminController);
app.listen(env_1.env.port, () => {
    // eslint-disable-next-line no-console
    console.log(`Server listening on http://localhost:${env_1.env.port}`);
});
//# sourceMappingURL=server.js.map