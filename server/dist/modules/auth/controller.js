"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authController = void 0;
const express_1 = require("express");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const client_1 = require("../../db/client");
const env_1 = require("../../config/env");
const auth_1 = require("../../middleware/auth");
const router = (0, express_1.Router)();
router.post('/login', (req, res) => {
    const { email, password } = req.body || {};
    if (!email || !password) {
        return res.status(400).json({ error: 'email and password are required' });
    }
    // 간단히 plaintext 비교 (목업)
    const userStmt = client_1.db.prepare('SELECT id, email, password_hash FROM users WHERE email = ? LIMIT 1');
    const user = userStmt.get(email);
    if (!user || user.password_hash !== password) {
        return res.status(401).json({ error: 'invalid credentials' });
    }
    const membershipsStmt = client_1.db.prepare('SELECT user_id, tenant_id, role FROM memberships WHERE user_id = ?');
    const membershipsRows = membershipsStmt.all(user.id);
    const memberships = membershipsRows.map((m) => ({
        tenantId: m.tenant_id,
        role: m.role,
    }));
    const token = jsonwebtoken_1.default.sign({
        userId: user.id,
        email: user.email,
        tenantId: memberships[0]?.tenantId ?? '',
        role: memberships[0]?.role ?? 'admin',
    }, env_1.env.jwtSecret, { expiresIn: '12h' });
    return res.json({
        token,
        user: { id: user.id, email: user.email },
        memberships,
    });
});
router.get('/me', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    return res.json({ user: req.user });
});
router.get('/tenants', auth_1.authMiddleware, (_req, res) => {
    const rows = (0, client_1.mapRows)(client_1.db.prepare('SELECT * FROM tenants').all());
    res.json(rows);
});
// 판매자 신규 가입: 새 회사면 테넌트+owner 생성, 기존 회사면 승인 요청만 생성
router.post('/register', (req, res) => {
    const { companyName, companyAddress = '', companyPhone = '', name = '', phone = '', email, password, role, } = req.body || {};
    if (!companyName || !email || !password) {
        return res.status(400).json({ error: 'companyName, email, password required' });
    }
    const nowIso = new Date().toISOString();
    const existingTenant = client_1.db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(companyName);
    if (!existingTenant) {
        const tenantId = `t_${Date.now()}`;
        const userId = `u_${Date.now()}`;
        const tx = client_1.db.transaction(() => {
            client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)')
                .run(tenantId, companyName, 'en', nowIso, companyPhone, companyAddress);
            client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone) VALUES (?,?,?,?,?)')
                .run(userId, email, password, name, phone);
            client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)')
                .run(userId, tenantId, 'owner');
            client_1.db.prepare('INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)').run(`mr_${Date.now()}`, tenantId, email, name, phone, 'owner', 'approved', companyName, companyAddress, companyPhone, 'seller_owner', nowIso);
        });
        tx();
        const token = jsonwebtoken_1.default.sign({ userId, email, tenantId, role: 'owner' }, env_1.env.jwtSecret, { expiresIn: '12h' });
        return res.status(201).json({
            token,
            user: { id: userId, email },
            memberships: [{ tenantId, role: 'owner' }],
        });
    }
    // 기존 회사면 승인 요청 생성
    const reqId = `mr_${Date.now()}`;
    client_1.db.prepare('INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)').run(reqId, existingTenant.id, email, name, phone, role ?? 'staff', 'pending', companyName, companyAddress, companyPhone, 'seller_staff', nowIso);
    return res.status(202).json({ status: 'pending', requestId: reqId, message: '승인 대기 중입니다.' });
});
// 구매자 가입 요청: 판매자 회사 + 구매자 회사 정보와 첨부파일(옵션) 등록
router.post('/register-buyer', (req, res) => {
    const { sellerCompanyName, buyerCompanyName, buyerAddress = '', name = '', phone = '', email, attachmentUrl = '', role = 'staff', } = req.body || {};
    if (!sellerCompanyName || !buyerCompanyName || !email) {
        return res.status(400).json({ error: 'sellerCompanyName, buyerCompanyName, email required' });
    }
    const reqId = `br_${Date.now()}`;
    client_1.db.prepare('INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)').run(reqId, sellerCompanyName, buyerCompanyName, buyerAddress, email, name, phone, role, attachmentUrl, 'pending', new Date().toISOString());
    return res.status(202).json({ status: 'pending', requestId: reqId, message: '판매자 승인 대기 중입니다.' });
});
// 새 테넌트+관리자 생성
// 기존 register 경로는 판매자 신규 플로우로 통합 (상위에서 처리)
// 간단한 사용자 CRUD (목업 수준, 비밀번호 해시 미적용)
router.post('/users', auth_1.authMiddleware, (req, res) => {
    const { email, password, tenantId, role = 'admin' } = req.body || {};
    const resolvedTenant = tenantId ?? req.user?.tenantId;
    if (!email || !password || !resolvedTenant) {
        return res.status(400).json({ error: 'email, password, tenantId required' });
    }
    const userId = `u_${Date.now()}`;
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('INSERT INTO users (id, email, password_hash) VALUES (?,?,?)').run(userId, email, password);
        client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(userId, resolvedTenant, role);
    });
    tx();
    res.status(201).json({ id: userId, email, tenantId: resolvedTenant, role });
});
router.put('/users/:id', auth_1.authMiddleware, (req, res) => {
    const userId = req.params.id;
    const { email, password, role, tenantId } = req.body || {};
    const user = client_1.db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
    if (!user)
        return res.status(404).json({ error: 'not found' });
    const tx = client_1.db.transaction(() => {
        if (email || password) {
            client_1.db.prepare('UPDATE users SET email = COALESCE(?, email), password_hash = COALESCE(?, password_hash) WHERE id = ?')
                .run(email, password, userId);
        }
        if (tenantId) {
            client_1.db.prepare('DELETE FROM memberships WHERE user_id = ?').run(userId);
            client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)')
                .run(userId, tenantId, role ?? 'admin');
        }
        else if (role) {
            client_1.db.prepare('UPDATE memberships SET role = ? WHERE user_id = ?').run(role, userId);
        }
    });
    tx();
    res.json({ id: userId, email: email ?? user.email ?? '', tenantId: tenantId ?? req.user?.tenantId, role: role ?? 'admin' });
});
router.delete('/users/:id', auth_1.authMiddleware, (req, res) => {
    const userId = req.params.id;
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM memberships WHERE user_id = ?').run(userId);
        client_1.db.prepare('DELETE FROM users WHERE id = ?').run(userId);
    });
    tx();
    res.status(204).end();
});
exports.authController = router;
//# sourceMappingURL=controller.js.map