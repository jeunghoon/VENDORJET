"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureTenantPositionDefaults = ensureTenantPositionDefaults;
exports.assignOwnerDefaultPosition = assignOwnerDefaultPosition;
exports.assignPendingPosition = assignPendingPosition;
const client_1 = require("../../db/client");
const DEFAULT_POSITIONS = [
    { tier: 'owner', title: '\ub300\ud45c', sortOrder: 1, isLocked: 1 },
    { tier: 'manager', title: '\uad00\ub9ac\uc790', sortOrder: 2, isLocked: 0 },
    { tier: 'staff', title: '\uc9c1\uc6d0', sortOrder: 3, isLocked: 0 },
    { tier: 'pending', title: '\ubbf8\uc2b9\uc778', sortOrder: 4, isLocked: 1 },
];
function ensureTenantPositionDefaults(tenantId) {
    const existingRows = client_1.db
        .prepare('SELECT tier, title, sort_order AS sortOrder, is_locked AS isLocked FROM tenant_positions WHERE tenant_id = ?')
        .all(tenantId);
    const existingMap = new Map(existingRows
        .map((row) => [((row.tier ?? '').toLowerCase()), row])
        .filter((entry) => entry[0] !== ''));
    const insert = client_1.db.prepare(`INSERT INTO tenant_positions (id, tenant_id, title, created_at, tier, sort_order, is_locked)
     VALUES (?,?,?,?,?,?,?)`);
    const now = new Date().toISOString();
    for (const seed of DEFAULT_POSITIONS) {
        const existing = existingMap.get(seed.tier);
        const corrupted = !!existing?.title && existing.title.includes('?');
        if (existing) {
            if ((existing.isLocked ?? 0) === 1 || corrupted) {
                client_1.db.prepare('UPDATE tenant_positions SET title = ?, sort_order = ?, is_locked = ? WHERE tenant_id = ? AND LOWER(tier) = ?')
                    .run(seed.title, seed.sortOrder, seed.isLocked, tenantId, seed.tier);
            }
            continue;
        }
        insert.run(`pos_${seed.tier}_${Date.now()}_${Math.round(Math.random() * 1000)}`, tenantId, seed.title, now, seed.tier, seed.sortOrder, seed.isLocked);
    }
}
function assignOwnerDefaultPosition(tenantId, ownerUserId) {
    ensureTenantPositionDefaults(tenantId);
    const ownerPosition = client_1.db
        .prepare('SELECT id, title FROM tenant_positions WHERE tenant_id = ? AND tier = ? LIMIT 1')
        .get(tenantId, 'owner');
    if (!ownerPosition?.id)
        return;
    client_1.db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(tenantId, ownerUserId, ownerPosition.id, ownerPosition.title ?? '\ub300\ud45c');
}
function assignPendingPosition(tenantId, memberId) {
    ensureTenantPositionDefaults(tenantId);
    const pendingPosition = client_1.db
        .prepare('SELECT id, title FROM tenant_positions WHERE tenant_id = ? AND tier = ? LIMIT 1')
        .get(tenantId, 'pending');
    if (!pendingPosition?.id)
        return;
    client_1.db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(tenantId, memberId, pendingPosition.id, pendingPosition.title ?? '\ubbf8\uc2b9\uc778');
}
//# sourceMappingURL=position_utils.js.map