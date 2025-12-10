"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminController = void 0;
const express_1 = require("express");
const client_1 = require("../../db/client");
const position_utils_1 = require("../auth/position_utils");
const router = (0, express_1.Router)();
// 전체 사용자 목록
router.get('/users', (_req, res) => {
    const rows = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT u.id,
                u.email,
                u.name,
                u.phone,
                u.address,
                u.created_at,
                u.last_login_at,
                u.user_type,
                m.role,
                m.status,
                group_concat(distinct t.name) AS tenantNames
         FROM users u
         LEFT JOIN memberships m ON u.id = m.user_id
         LEFT JOIN tenants t ON m.tenant_id = t.id
         GROUP BY u.id, m.role, m.status`)
        .all());
    res.json(rows);
});
// 전체 테넌트(도매/소매) 목록
router.get('/tenants', (_req, res) => {
    const rows = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT t.id,
                t.name,
                t.phone,
                t.address,
                (SELECT COUNT(*) FROM memberships m WHERE m.tenant_id = t.id) AS memberCount
         FROM tenants t`)
        .all());
    res.json(rows);
});
// 테넌트 생성(지정 사용자 owner 연결)
router.post('/tenants', (req, res) => {
    const { name, phone = '', address = '', userId, representative = '' } = req.body || {};
    if (!name || !userId) {
        return res.status(400).json({ error: 'name and userId required' });
    }
    const tenantId = `t_${Date.now()}`;
    const now = new Date().toISOString();
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address, representative) VALUES (?,?,?,?,?,?,?)')
            .run(tenantId, name, 'en', now, phone, address, representative);
        client_1.db.prepare('INSERT OR IGNORE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)')
            .run(userId, tenantId, 'owner', 'approved');
    });
    tx();
    (0, position_utils_1.ensureTenantPositionDefaults)(tenantId);
    (0, position_utils_1.assignOwnerDefaultPosition)(tenantId, userId);
    return res.status(201).json({ id: tenantId, name, phone, address, representative });
});
// 테넌트 수정
router.patch('/tenants/:id', (req, res) => {
    const { id } = req.params;
    const { name, phone, address, representative } = req.body || {};
    if (!name && !phone && !address && !representative)
        return res.json({ ok: true });
    const parts = [];
    const params = [];
    if (name) {
        parts.push('name = ?');
        params.push(name);
    }
    if (phone) {
        parts.push('phone = ?');
        params.push(phone);
    }
    if (address) {
        parts.push('address = ?');
        params.push(address);
    }
    if (representative) {
        parts.push('representative = ?');
        params.push(representative);
    }
    params.push(id);
    client_1.db.prepare(`UPDATE tenants SET ${parts.join(', ')} WHERE id = ?`).run(...params);
    return res.json({ ok: true });
});
// 테넌트 삭제
router.delete('/tenants/:id', (req, res) => {
    const { id } = req.params;
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM memberships WHERE tenant_id = ?').run(id);
        client_1.db.prepare('DELETE FROM tenants WHERE id = ?').run(id);
    });
    tx();
    return res.status(204).end();
});
// 가입/승인 요청
router.get('/requests', (_req, res) => {
    const membershipRequests = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT id,
                tenant_id AS tenantId,
                email,
                name,
                phone,
                role,
                status,
                company_name AS companyName,
                company_address AS companyAddress,
                company_phone AS companyPhone,
                requester_type AS requesterType,
                created_at AS createdAt
         FROM membership_requests`)
        .all()).map((r) => ({ ...r, type: 'membership' }));
    const buyerRequests = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT id,
                seller_company AS sellerCompany,
                seller_phone AS sellerPhone,
                seller_address AS sellerAddress,
                buyer_company AS buyerCompany,
                buyer_address AS buyerAddress,
                email,
                name,
                phone,
                role,
                attachment_url AS attachmentUrl,
                user_id AS userId,
                buyer_tenant_id AS buyerTenantId,
                requested_segment AS requestedSegment,
                selected_segment AS selectedSegment,
                selected_tier AS selectedTier,
                status,
                created_at AS createdAt
         FROM buyer_requests`)
        .all()).map((r) => ({ ...r, type: 'buyer' }));
    res.json({ membershipRequests, buyerRequests });
});
// 요청 승인/거절 (간단히 status만 변경)
router.patch('/requests/:id', (req, res) => {
    const { id } = req.params;
    const { status = 'approved', segment, tier } = req.body || {};
    if (!['approved', 'denied', 'pending'].includes(status)) {
        return res.status(400).json({ error: 'invalid status' });
    }
    const isMembership = id.startsWith('mr_');
    if (isMembership) {
        const reqRow = client_1.db
            .prepare('SELECT * FROM membership_requests WHERE id = ?')
            .get(id);
        if (!reqRow)
            return res.status(404).json({ error: 'request not found' });
        client_1.db.prepare('UPDATE membership_requests SET status = ? WHERE id = ?').run(status, id);
        if (status === 'approved' && reqRow.tenant_id && reqRow.email) {
            const user = client_1.db
                .prepare('SELECT id FROM users WHERE email = ? LIMIT 1')
                .get(reqRow.email);
            if (user) {
                client_1.db.prepare('INSERT OR REPLACE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(user.id, reqRow.tenant_id, reqRow.role ?? 'staff', 'approved');
            }
        }
    }
    else {
        const reqRow = client_1.db
            .prepare('SELECT * FROM buyer_requests WHERE id = ?')
            .get(id);
        if (!reqRow)
            return res.status(404).json({ error: 'request not found' });
        client_1.db.prepare('UPDATE buyer_requests SET status = ?, selected_segment = COALESCE(?, selected_segment), selected_tier = COALESCE(?, selected_tier) WHERE id = ?').run(status, segment, tier, id);
        if (status === 'approved' && reqRow.seller_company) {
            const tenant = client_1.db
                .prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1')
                .get(reqRow.seller_company);
            if (tenant) {
                const nowIso = new Date().toISOString();
                const resolvedSegment = (segment ?? '').toString().trim() ||
                    (reqRow.selected_segment ?? '').toString().trim() ||
                    (reqRow.requested_segment ?? '').toString().trim();
                const resolvedTier = (tier ?? '').toString().trim() ||
                    (reqRow.selected_tier ?? '').toString().trim() ||
                    'silver';
                if (resolvedSegment) {
                    const existingSeg = client_1.db
                        .prepare('SELECT 1 FROM segments WHERE tenant_id = ? AND name = ? LIMIT 1')
                        .get(tenant.id, resolvedSegment);
                    if (!existingSeg) {
                        client_1.db.prepare('INSERT INTO segments (tenant_id, name) VALUES (?, ?)').run(tenant.id, resolvedSegment);
                    }
                }
                if (reqRow.buyer_company) {
                    const existingCustomer = client_1.db
                        .prepare('SELECT id FROM customers WHERE tenant_id = ? AND name = ? LIMIT 1')
                        .get(tenant.id, reqRow.buyer_company);
                    if (existingCustomer) {
                        client_1.db.prepare(`UPDATE customers
               SET contact_name = COALESCE(?, contact_name),
                   email = COALESCE(?, email),
                   tier = ?,
                   segment = COALESCE(?, segment)
               WHERE id = ? AND tenant_id = ?`).run(reqRow.name, reqRow.email, resolvedTier, resolvedSegment, existingCustomer.id, tenant.id);
                    }
                    else {
                        const customerId = `c_${Date.now()}`;
                        client_1.db.prepare('INSERT INTO customers (id, tenant_id, name, contact_name, email, tier, created_at, segment) VALUES (?,?,?,?,?,?,?,?)').run(customerId, tenant.id, reqRow.buyer_company, reqRow.name ?? '', reqRow.email ?? '', resolvedTier, nowIso, resolvedSegment);
                    }
                }
                if (reqRow.user_id) {
                    client_1.db.prepare('INSERT OR REPLACE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(reqRow.user_id, tenant.id, reqRow.role ?? 'staff', 'approved');
                }
            }
        }
        if (status !== 'pending') {
            client_1.db.prepare('DELETE FROM buyer_requests WHERE id = ?').run(id);
        }
    }
    return res.json({ id, status });
});
// 요청 삭제
router.delete('/requests/:id', (req, res) => {
    const { id } = req.params;
    const isMembership = id.startsWith('mr_');
    const stmt = isMembership
        ? client_1.db.prepare('DELETE FROM membership_requests WHERE id = ?')
        : client_1.db.prepare('DELETE FROM buyer_requests WHERE id = ?');
    const info = stmt.run(id);
    if (info.changes === 0)
        return res.status(404).json({ error: 'not found' });
    return res.status(204).end();
});
// 사용자 역할/상태 갱신 (단순 멤버십 업데이트)
router.patch('/users/:id', (req, res) => {
    const { id } = req.params;
    const { role, status, tenantId } = req.body || {};
    if (!role && !status) {
        return res.status(400).json({ error: 'role or status required' });
    }
    const targetTenant = tenantId;
    const stmt = targetTenant
        ? client_1.db.prepare('UPDATE memberships SET role = COALESCE(?, role), status = COALESCE(?, status) WHERE user_id = ? AND tenant_id = ?')
        : client_1.db.prepare('UPDATE memberships SET role = COALESCE(?, role), status = COALESCE(?, status) WHERE user_id = ?');
    const info = targetTenant ? stmt.run(role, status, id, targetTenant) : stmt.run(role, status, id);
    if (info.changes === 0) {
        return res.status(404).json({ error: 'membership not found' });
    }
    return res.json({ id, role, status });
});
// 사용자 삭제
router.delete('/users/:id', (req, res) => {
    const { id } = req.params;
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM memberships WHERE user_id = ?').run(id);
        client_1.db.prepare('DELETE FROM users WHERE id = ?').run(id);
    });
    tx();
    return res.status(204).end();
});
exports.adminController = router;
//# sourceMappingURL=controller.js.map