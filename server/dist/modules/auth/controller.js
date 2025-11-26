"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
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
    const userStmt = client_1.db.prepare('SELECT id, email, password_hash, user_type FROM users WHERE email = ? LIMIT 1');
    const user = userStmt.get(email);
    if (!user || user.password_hash !== password) {
        return res.status(401).json({ error: 'invalid credentials' });
    }
    const membershipsRows = client_1.db
        .prepare('SELECT user_id, tenant_id, role FROM memberships WHERE user_id = ?')
        .all(user.id);
    const memberships = membershipsRows.map((m) => ({
        tenantId: m.tenant_id,
        role: m.role,
    }));
    const token = jsonwebtoken_1.default.sign({
        userId: user.id,
        email: user.email,
        tenantId: memberships[0]?.tenantId ?? '',
        role: memberships[0]?.role ?? 'admin',
        userType: user.user_type ?? 'wholesale',
    }, env_1.env.jwtSecret, { expiresIn: '12h' });
    client_1.db.prepare('UPDATE users SET last_login_at = ? WHERE id = ?').run(new Date().toISOString(), user.id);
    return res.json({
        token,
        user: { id: user.id, email: user.email, userType: user.user_type ?? 'wholesale' },
        memberships,
    });
});
router.get('/me', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    return res.json({ user: req.user });
});
router.get('/profile', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const row = client_1.db
        .prepare('SELECT id, email, name, phone, address, created_at, last_login_at, user_type FROM users WHERE id = ?')
        .get(req.user.userId);
    return res.json(row);
});
router.patch('/profile', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const { email, phone, address, name, password } = req.body || {};
    const updates = [];
    const params = [];
    if (email) {
        updates.push('email = ?');
        params.push(email);
    }
    if (phone) {
        updates.push('phone = ?');
        params.push(phone);
    }
    if (address) {
        updates.push('address = ?');
        params.push(address);
    }
    if (name) {
        updates.push('name = ?');
        params.push(name);
    }
    if (password) {
        updates.push('password_hash = ?');
        params.push(password);
    }
    if (updates.length === 0)
        return res.json({ ok: true });
    const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;
    params.push(req.user.userId);
    client_1.db.prepare(sql).run(...params);
    return res.json({ ok: true });
});
router.delete('/profile', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const uid = req.user.userId;
    const tx = client_1.db.transaction(() => {
        client_1.db.prepare('DELETE FROM memberships WHERE user_id = ?').run(uid);
        client_1.db.prepare('DELETE FROM users WHERE id = ?').run(uid);
    });
    tx();
    return res.status(204).end();
});
router.get('/tenants', auth_1.authMiddleware, (_req, res) => {
    if (!_req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const rows = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT t.id, t.name, t.locale, t.phone, t.address
         FROM tenants t
         INNER JOIN memberships m ON m.tenant_id = t.id
         WHERE m.user_id = ?`)
        .all(_req.user.userId));
    res.json(rows);
});
router.get('/tenants-public', (_req, res) => {
    const rows = (0, client_1.mapRows)(client_1.db.prepare('SELECT id, name, phone, address FROM tenants').all());
    res.json(rows);
});
// seller registration: mode=new -> company owner, mode=existing -> membership request pending
router.post('/register', (req, res) => {
    const { companyName, companyAddress = '', companyPhone = '', name = '', phone = '', email, password, role, mode = 'new', } = req.body || {};
    if (!companyName || !email || !password) {
        return res.status(400).json({ error: 'companyName, email, password required' });
    }
    if (mode !== 'new' && mode !== 'existing') {
        return res.status(400).json({ error: 'mode must be new or existing' });
    }
    const nowIso = new Date().toISOString();
    const existingTenant = client_1.db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(companyName);
    if (!existingTenant) {
        if (mode === 'existing')
            return res.status(404).json({ error: 'company not found' });
        const tenantId = `t_${Date.now()}`;
        const userId = `u_${Date.now()}`;
        const tx = client_1.db.transaction(() => {
            client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)').run(tenantId, companyName, 'en', nowIso, companyPhone, companyAddress);
            client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)')
                .run(userId, email, password, name, phone, companyAddress, nowIso, 'wholesale');
            client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(userId, tenantId, 'owner');
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
    if (mode === 'new') {
        return res.status(400).json({ error: 'company already exists, choose existing mode' });
    }
    const reqId = `mr_${Date.now()}`;
    client_1.db.prepare('INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)').run(reqId, existingTenant.id, email, name, phone, role ?? 'staff', 'pending', companyName, companyAddress, companyPhone, 'seller_staff', nowIso);
    return res.status(202).json({ status: 'pending', requestId: reqId, message: 'pending approval by owner' });
});
// buyer registration: seller company must exist, buyer company can be new(owner) or existing(pending)
router.post('/register-buyer', (req, res) => {
    const { sellerCompanyName, buyerCompanyName, buyerAddress = '', name = '', phone = '', email, password, attachmentUrl = '', role = 'staff', mode = 'new', } = req.body || {};
    if (!sellerCompanyName || !buyerCompanyName || !email || !password) {
        return res.status(400).json({ error: 'sellerCompanyName, buyerCompanyName, email, password required' });
    }
    if (mode !== 'new' && mode !== 'existing') {
        return res.status(400).json({ error: 'mode must be new or existing' });
    }
    const reqId = `br_${Date.now()}`;
    const nowIso = new Date().toISOString();
    const existingUser = client_1.db.prepare('SELECT id FROM users WHERE email = ? LIMIT 1').get(email);
    const userId = existingUser?.id ?? `u_${Date.now()}`;
    const upsertUser = client_1.db.transaction(() => {
        if (existingUser) {
            client_1.db.prepare('UPDATE users SET password_hash = COALESCE(?, password_hash), name = COALESCE(?, name), phone = COALESCE(?, phone), address = COALESCE(?, address), user_type = COALESCE(?, user_type), updated_at = ? WHERE id = ?').run(password, name, phone, buyerAddress, 'retail', nowIso, userId);
        }
        else {
            client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)').run(userId, email, password, name, phone, buyerAddress, nowIso, 'retail');
        }
    });
    upsertUser();
    const sellerTenant = client_1.db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(sellerCompanyName);
    if (!sellerTenant) {
        return res.status(404).json({ error: 'seller company not found' });
    }
    const existingBuyerTenant = client_1.db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(buyerCompanyName);
    let buyerTenantId = existingBuyerTenant?.id;
    if (!existingBuyerTenant && mode === 'existing') {
        return res.status(404).json({ error: 'buyer company not found' });
    }
    if (!existingBuyerTenant && mode === 'new') {
        buyerTenantId = `t_${Date.now()}`;
        client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)').run(buyerTenantId, buyerCompanyName, 'en', nowIso, '', buyerAddress);
        client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(userId, buyerTenantId, 'owner', 'approved');
    }
    client_1.db.prepare('INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at, user_id, buyer_tenant_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)').run(reqId, sellerCompanyName, buyerCompanyName, buyerAddress, email, name, phone, role, attachmentUrl, 'pending', nowIso, userId, buyerTenantId ?? '');
    return res.status(202).json({
        status: 'pending',
        requestId: reqId,
        message: 'pending approval',
    });
});
exports.default = router;
//# sourceMappingURL=controller.js.map