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
const position_utils_1 = require("./position_utils");
const router = (0, express_1.Router)();
router.post('/login', (req, res) => {
    const { email, password } = req.body || {};
    if (!email || !password) {
        return res.status(400).json({ error: 'email and password are required' });
    }
    const userStmt = client_1.db.prepare(`SELECT id, email, password_hash, user_type, name, phone, language_preference, primary_tenant_id
     FROM users
     WHERE email = ?
     LIMIT 1`);
    const user = userStmt.get(email);
    if (!user || user.password_hash !== password) {
        return res.status(401).json({ error: 'invalid credentials' });
    }
    const membershipsRows = client_1.db
        .prepare(`SELECT user_id, tenant_id, role, status
       FROM memberships
       WHERE user_id = ?
       ORDER BY (status = 'approved') DESC, rowid DESC`)
        .all(user.id);
    const memberships = membershipsRows.map((m) => ({
        tenantId: m.tenant_id,
        role: m.role,
    }));
    const primaryMembership = membershipsRows.find((m) => (m.status ?? 'approved') === 'approved') ?? membershipsRows[0];
    const tokenPayload = {
        userId: user.id,
        email: user.email,
        tenantId: primaryMembership?.tenant_id ?? '',
        role: primaryMembership?.role ?? 'admin',
        userType: user.user_type ?? 'wholesale',
        language: user.language_preference ?? null,
        primaryTenantId: user.primary_tenant_id ?? null,
    };
    const token = jsonwebtoken_1.default.sign(tokenPayload, env_1.env.jwtSecret, { expiresIn: '12h' });
    client_1.db.prepare('UPDATE users SET last_login_at = ? WHERE id = ?').run(new Date().toISOString(), user.id);
    return res.json({
        token,
        user: {
            id: user.id,
            email: user.email,
            userType: user.user_type ?? 'wholesale',
            name: user.name ?? '',
            phone: user.phone ?? '',
            language: user.language_preference ?? '',
            primaryTenantId: user.primary_tenant_id ?? '',
        },
        memberships,
    });
});
router.get('/check-email', (req, res) => {
    const email = req.query.email?.toLowerCase();
    if (!email)
        return res.status(400).json({ error: 'email required' });
    const exists = client_1.db.prepare('SELECT 1 FROM users WHERE email = ? LIMIT 1').get(email);
    return res.json({ exists: !!exists });
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
        .prepare(`SELECT id,
              email,
              name,
              phone,
              address,
              created_at,
              last_login_at,
              user_type,
              language_preference,
              primary_tenant_id
       FROM users
       WHERE id = ?`)
        .get(req.user.userId);
    if (!row)
        return res.status(404).json({ error: 'not found' });
    if ((row.user_type ?? '') === 'retail') {
        const pending = client_1.db
            .prepare(`SELECT seller_company
         FROM buyer_requests
         WHERE user_id = ? AND status = 'pending'
         ORDER BY created_at DESC
         LIMIT 1`)
            .get(req.user.userId);
        row.pending_seller = pending?.seller_company ?? null;
    }
    return res.json(row);
});
router.patch('/profile', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const { email, phone, name, password, language, primaryTenantId, } = req.body || {};
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
    if (name) {
        updates.push('name = ?');
        params.push(name);
    }
    if (language) {
        updates.push('language_preference = ?');
        params.push(language);
    }
    if (primaryTenantId) {
        const ownsTenant = client_1.db
            .prepare(`SELECT 1
         FROM memberships
         WHERE user_id = ?
           AND tenant_id = ?
           AND COALESCE(status, 'approved') = 'approved'
         LIMIT 1`)
            .get(req.user.userId, primaryTenantId);
        if (!ownsTenant) {
            return res.status(400).json({ error: 'invalid tenant' });
        }
        updates.push('primary_tenant_id = ?');
        params.push(primaryTenantId);
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
    const userRow = client_1.db
        .prepare('SELECT email, user_type FROM users WHERE id = ? LIMIT 1')
        .get(uid);
    if (!userRow)
        return res.status(404).json({ error: 'not found' });
    const tx = client_1.db.transaction(() => {
        if ((userRow.user_type ?? '') === 'retail' && userRow.email) {
            client_1.db.prepare("UPDATE buyer_requests SET status = 'withdrawn' WHERE email = ?").run(userRow.email);
        }
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
        .prepare(`SELECT
            t.id,
            t.name,
            t.locale,
            COALESCE(t.phone, '') AS phone,
            COALESCE(t.address, '') AS address,
            COALESCE(t.representative, '') AS representative,
            COALESCE(t.created_at, '') AS created_at,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM memberships mo
                INNER JOIN users uo ON uo.id = mo.user_id
                WHERE mo.tenant_id = t.id
                  AND mo.role = 'owner'
                  AND COALESCE(uo.user_type, 'wholesale') = 'retail'
              )
              THEN 'buyer'
              ELSE 'seller'
            END AS tenant_type,
            CASE WHEN COALESCE(u.primary_tenant_id, '') = t.id THEN 1 ELSE 0 END AS isPrimary
         FROM tenants t
         INNER JOIN memberships m ON m.tenant_id = t.id
         INNER JOIN users u ON u.id = m.user_id
         WHERE m.user_id = ?
         ORDER BY LOWER(t.name)`)
        .all(_req.user.userId));
    res.json(rows);
});
router.get('/tenants-public', (_req, res) => {
    const includeRetail = _req.query.includeRetail === 'true';
    const type = _req.query.type?.toLowerCase();
    let whereClause = "COALESCE(u.user_type, 'wholesale') != 'retail'";
    if (type === 'retail') {
        whereClause = "COALESCE(u.user_type, 'wholesale') = 'retail'";
    }
    else if (type === 'wholesale') {
        whereClause = "COALESCE(u.user_type, 'wholesale') != 'retail'";
    }
    else if (includeRetail) {
        whereClause = '1=1';
    }
    const rows = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT DISTINCT
            t.id,
            t.name,
            CASE
              WHEN COALESCE(u.user_type, 'wholesale') = 'retail' THEN COALESCE((
                SELECT COALESCE(br.phone, '')
                FROM buyer_requests br
                WHERE br.buyer_company = t.name
                ORDER BY br.created_at DESC
                LIMIT 1
              ), COALESCE(t.phone, ''))
              ELSE COALESCE(t.phone, '')
            END AS phone,
            COALESCE(t.address, '') AS address,
            COALESCE(t.representative, '') AS representative,
            CASE WHEN COALESCE(u.user_type, 'wholesale') = 'retail' THEN 'retail' ELSE 'wholesale' END AS tenantType,
            COALESCE((
              SELECT COALESCE(br.selected_segment, br.requested_segment, '')
              FROM buyer_requests br
              WHERE br.buyer_company = t.name
              ORDER BY br.created_at DESC
              LIMIT 1
            ), '') AS segment
         FROM tenants t
         INNER JOIN memberships m ON m.tenant_id = t.id AND m.role = 'owner'
         INNER JOIN users u ON u.id = m.user_id
         WHERE ${whereClause}
         ORDER BY LOWER(t.name)`)
        .all());
    res.json(rows.map((row) => ({
        id: row.id,
        name: row.name,
        phone: row.phone ?? '',
        address: row.address ?? '',
        type: row.tenantType,
        segment: row.segment ?? '',
        representative: row.representative ?? '',
    })));
});
// seller registration: mode=new -> company owner, mode=existing -> membership request pending
router.post('/register', (req, res) => {
    const { companyName, companyAddress = '', companyPhone = '', companyRepresentative = '', name = '', phone = '', email, password, role, mode = 'new', } = req.body || {};
    if (!companyName || !email || !password) {
        return res.status(400).json({ error: 'companyName, email, password required' });
    }
    const normalizedEmail = email.toLowerCase();
    const existingEmail = client_1.db.prepare('SELECT 1 FROM users WHERE email = ? LIMIT 1').get(normalizedEmail);
    if (existingEmail)
        return res.status(409).json({ error: 'email already exists' });
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
            client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address, representative) VALUES (?,?,?,?,?,?,?)').run(tenantId, companyName, 'en', nowIso, companyPhone, companyAddress, companyRepresentative || name);
            client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)')
                .run(userId, normalizedEmail, password, name, phone, companyAddress, nowIso, 'wholesale');
            client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(userId, tenantId, 'owner');
        });
        tx();
        (0, position_utils_1.ensureTenantPositionDefaults)(tenantId);
        (0, position_utils_1.assignOwnerDefaultPosition)(tenantId, userId);
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
    const tenantId = existingTenant.id;
    const userId = `u_${Date.now()}`;
    const normalizedRole = role?.toLowerCase();
    const assignedRole = normalizedRole === 'manager' ? 'manager' : 'staff';
    const txExisting = client_1.db.transaction(() => {
        client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)').run(userId, normalizedEmail, password, name, phone, companyAddress, nowIso, 'wholesale');
        client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(userId, tenantId, assignedRole, 'approved');
    });
    txExisting();
    (0, position_utils_1.assignPendingPosition)(tenantId, userId);
    const token = jsonwebtoken_1.default.sign({ userId, email, tenantId, role: assignedRole }, env_1.env.jwtSecret, { expiresIn: '12h' });
    return res.status(201).json({
        token,
        user: { id: userId, email },
        memberships: [{ tenantId, role: assignedRole }],
    });
});
// buyer registration: seller company must exist, buyer company can be new(owner) or existing(pending)
router.post('/register-buyer', (req, res) => {
    const { sellerCompanyName, buyerCompanyName, buyerAddress = '', buyerRepresentative = '', name = '', phone = '', email, password, attachmentUrl = '', buyerSegment = '', role = 'staff', mode = 'new', } = req.body || {};
    const isNewBuyerCompany = mode === 'new';
    if (!buyerCompanyName || !email || !password) {
        return res.status(400).json({ error: 'buyerCompanyName, email, password required' });
    }
    if (isNewBuyerCompany && !sellerCompanyName) {
        return res.status(400).json({ error: 'sellerCompanyName required for new company' });
    }
    if (!buyerSegment || buyerSegment.toString().trim().length === 0) {
        return res.status(400).json({ error: 'buyerSegment required' });
    }
    if (mode !== 'new' && mode !== 'existing') {
        return res.status(400).json({ error: 'mode must be new or existing' });
    }
    const reqId = `br_${Date.now()}`;
    const nowIso = new Date().toISOString();
    const requestedRoleRaw = (role ?? 'staff').toString().toLowerCase();
    const membershipRole = requestedRoleRaw === 'owner'
        ? 'owner'
        : requestedRoleRaw === 'manager'
            ? 'manager'
            : 'staff';
    const normalizedEmail = email.toLowerCase();
    const existingUser = client_1.db.prepare('SELECT id FROM users WHERE email = ? LIMIT 1').get(normalizedEmail);
    if (existingUser) {
        return res.status(409).json({ error: 'email already exists' });
    }
    const userId = `u_${Date.now()}`;
    client_1.db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)').run(userId, normalizedEmail, password, name, phone, buyerAddress, nowIso, 'retail');
    let resolvedSellerCompany = sellerCompanyName;
    if (!resolvedSellerCompany && mode === 'existing') {
        const prev = client_1.db
            .prepare('SELECT seller_company FROM buyer_requests WHERE buyer_company = ? ORDER BY created_at DESC LIMIT 1')
            .get(buyerCompanyName);
        resolvedSellerCompany = prev?.seller_company;
    }
    let sellerTenant;
    if (resolvedSellerCompany) {
        sellerTenant = client_1.db
            .prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1')
            .get(resolvedSellerCompany);
        if (!sellerTenant) {
            return res.status(404).json({ error: 'seller company not found' });
        }
    }
    const existingBuyerTenant = client_1.db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(buyerCompanyName);
    let buyerTenantId = existingBuyerTenant?.id;
    if (!existingBuyerTenant && mode === 'existing') {
        return res.status(404).json({ error: 'buyer company not found' });
    }
    const createdNewBuyerTenant = !existingBuyerTenant && mode === 'new';
    if (createdNewBuyerTenant) {
        buyerTenantId = `t_${Date.now()}`;
        client_1.db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address, representative) VALUES (?,?,?,?,?,?,?)').run(buyerTenantId, buyerCompanyName, 'en', nowIso, '', buyerAddress, buyerRepresentative || name);
        client_1.db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(userId, buyerTenantId, 'owner', 'approved');
        (0, position_utils_1.ensureTenantPositionDefaults)(buyerTenantId);
        (0, position_utils_1.assignOwnerDefaultPosition)(buyerTenantId, userId);
    }
    else if (buyerTenantId != null && existingBuyerTenant) {
        client_1.db.prepare('INSERT OR IGNORE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(userId, buyerTenantId, membershipRole, 'approved');
        (0, position_utils_1.assignPendingPosition)(buyerTenantId, userId);
    }
    if (!sellerTenant) {
        return res.status(201).json({
            status: 'registered',
            message: 'buyer registered without seller connection',
        });
    }
    client_1.db.prepare('INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at, user_id, buyer_tenant_id, requested_segment) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)').run(reqId, resolvedSellerCompany, buyerCompanyName, buyerAddress, normalizedEmail, name, phone, role, attachmentUrl, 'pending', nowIso, userId, buyerTenantId ?? '', buyerSegment);
    return res.status(202).json({
        status: 'pending',
        requestId: reqId,
        message: 'pending approval',
    });
});
router.post('/buyer/reapply', auth_1.authMiddleware, (req, res) => {
    const user = req.user;
    if (!user)
        return res.status(401).json({ error: 'unauthorized' });
    if ((user.userType ?? 'wholesale') !== 'retail') {
        return res.status(403).json({ error: 'only buyers can reapply' });
    }
    const { sellerCompanyName, buyerCompanyName, buyerAddress = '', buyerSegment = '', attachmentUrl = '', name = '', phone = '', } = req.body || {};
    if (!sellerCompanyName || !buyerCompanyName) {
        return res.status(400).json({ error: 'sellerCompanyName and buyerCompanyName are required' });
    }
    const normalizedSegment = buyerSegment.toString().trim();
    if (!normalizedSegment) {
        return res.status(400).json({ error: 'buyerSegment required' });
    }
    const normalizedSeller = sellerCompanyName.toString().trim();
    const normalizedBuyer = buyerCompanyName.toString().trim();
    if (!normalizedSeller || !normalizedBuyer) {
        return res.status(400).json({ error: 'invalid sellerCompanyName or buyerCompanyName' });
    }
    const userRow = client_1.db
        .prepare('SELECT email, name, phone, address FROM users WHERE id = ? LIMIT 1')
        .get(user.userId);
    if (!userRow?.email) {
        return res.status(404).json({ error: 'user not found' });
    }
    const sellerTenant = client_1.db
        .prepare('SELECT id, phone, address FROM tenants WHERE name = ? LIMIT 1')
        .get(normalizedSeller);
    if (!sellerTenant) {
        return res.status(404).json({ error: 'seller company not found' });
    }
    const buyerTenant = client_1.db
        .prepare('SELECT id, phone, address FROM tenants WHERE name = ? LIMIT 1')
        .get(normalizedBuyer);
    if (!buyerTenant) {
        return res.status(404).json({ error: 'buyer company not found' });
    }
    const buyerMembership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(user.userId, buyerTenant.id);
    if (!buyerMembership || buyerMembership.role !== 'owner') {
        return res.status(403).json({ error: 'only buyer owners can request connections' });
    }
    const existingMembership = client_1.db
        .prepare(`SELECT 1
       FROM memberships
       WHERE user_id = ? AND tenant_id = ? AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(user.userId, sellerTenant.id);
    if (existingMembership) {
        return res.status(409).json({ error: 'already connected' });
    }
    const existingCompanyConnection = client_1.db
        .prepare(`SELECT 1
       FROM memberships seller_m
       WHERE seller_m.tenant_id = ?
         AND COALESCE(seller_m.status, 'approved') = 'approved'
         AND EXISTS (
           SELECT 1
           FROM memberships buyer_m
           WHERE buyer_m.user_id = seller_m.user_id
             AND buyer_m.tenant_id = ?
             AND COALESCE(buyer_m.status, 'approved') = 'approved'
         )
       LIMIT 1`)
        .get(sellerTenant.id, buyerTenant.id);
    if (existingCompanyConnection) {
        return res.status(409).json({ error: 'company already connected' });
    }
    const pendingRequest = client_1.db
        .prepare(`SELECT 1
       FROM buyer_requests
       WHERE user_id = ? AND seller_company = ? AND status = 'pending'
       LIMIT 1`)
        .get(user.userId, normalizedSeller);
    if (pendingRequest) {
        return res.status(409).json({ error: 'pending request already exists' });
    }
    const pendingCompanyRequest = client_1.db
        .prepare(`SELECT 1
       FROM buyer_requests
       WHERE buyer_company = ?
         AND seller_company = ?
         AND status = 'pending'
       LIMIT 1`)
        .get(normalizedBuyer, normalizedSeller);
    if (pendingCompanyRequest) {
        return res.status(409).json({ error: 'company request already pending' });
    }
    const reqId = `br_${Date.now()}`;
    const nowIso = new Date().toISOString();
    const trimmedName = name?.toString().trim() ?? '';
    const trimmedPhone = phone?.toString().trim() ?? '';
    const resolvedName = trimmedName.length === 0 ? userRow.name ?? '' : trimmedName;
    const resolvedPhone = trimmedPhone.length === 0 ? userRow.phone ?? '' : trimmedPhone;
    const normalizedAttachment = attachmentUrl?.toString().trim() ?? '';
    client_1.db.prepare(`INSERT INTO buyer_requests (
        id,
        seller_company,
        seller_phone,
      seller_address,
      buyer_company,
      buyer_address,
      email,
      name,
        phone,
        role,
        attachment_url,
      status,
      created_at,
      user_id,
      buyer_tenant_id,
      requested_segment
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(reqId, normalizedSeller, sellerTenant.phone ?? '', sellerTenant.address ?? '', normalizedBuyer, buyerAddress, userRow.email, resolvedName, resolvedPhone, 'staff', normalizedAttachment, 'pending', nowIso, user.userId, buyerTenant.id, normalizedSegment);
    return res.status(202).json({
        status: 'pending',
        requestId: reqId,
        message: 'pending approval',
    });
});
router.get('/members', auth_1.authMiddleware, (req, res) => {
    const user = req.user;
    if (!user)
        return res.status(401).json({ error: 'unauthorized' });
    const tenantId = (req.query.tenantId?.trim() || user.tenantId)?.trim();
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId required' });
    const membership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(user.userId, tenantId);
    if (!membership)
        return res.status(403).json({ error: 'forbidden' });
    (0, position_utils_1.ensureTenantPositionDefaults)(tenantId);
    const tenantInfo = client_1.db
        .prepare(`SELECT
         CASE
           WHEN EXISTS (
             SELECT 1
             FROM memberships mo
             INNER JOIN users uo ON uo.id = mo.user_id
             WHERE mo.tenant_id = t.id
               AND mo.role = 'owner'
               AND COALESCE(uo.user_type, 'wholesale') = 'retail'
           )
           THEN 'buyer'
           ELSE 'seller'
         END AS tenant_type
       FROM tenants t
       WHERE t.id = ?
       LIMIT 1`)
        .get(tenantId);
    const tenantType = (tenantInfo?.tenant_type ?? 'seller').toLowerCase();
    const allowedUserType = tenantType === 'buyer' ? 'retail' : 'wholesale';
    const userTypeFilter = allowedUserType === 'retail'
        ? "COALESCE(u.user_type, 'wholesale') = 'retail'"
        : "COALESCE(u.user_type, 'wholesale') != 'retail'";
    const rows = (0, client_1.mapRows)(client_1.db
        .prepare(`SELECT u.id   AS user_id,
                COALESCE(u.name, '') AS name,
                COALESCE(u.email, '') AS email,
                COALESCE(u.phone, '') AS phone,
                COALESCE(m.role, 'staff') AS role,
                COALESCE(m.status, 'approved') AS status
         FROM memberships m
         INNER JOIN users u ON u.id = m.user_id
         WHERE m.tenant_id = ?
           AND ${userTypeFilter}
         ORDER BY LOWER(u.email)`)
        .all(tenantId));
    const positionRows = client_1.db
        .prepare('SELECT member_id AS memberId, title, position_id AS positionId FROM member_positions WHERE tenant_id = ?')
        .all(tenantId);
    const positionMap = new Map(positionRows.map((row) => [row.memberId, row]));
    rows
        .filter((row) => row.role === 'owner' && !positionMap.has(row.userId))
        .forEach((ownerRow) => {
        (0, position_utils_1.assignOwnerDefaultPosition)(tenantId, ownerRow.userId);
        const assigned = client_1.db
            .prepare('SELECT member_id AS memberId, title, position_id AS positionId FROM member_positions WHERE tenant_id = ? AND member_id = ? LIMIT 1')
            .get(tenantId, ownerRow.userId);
        if (assigned) {
            positionMap.set(ownerRow.userId, assigned);
        }
    });
    return res.json(rows.map((row) => ({
        ...row,
        positionId: positionMap.get(row.userId)?.positionId ?? null,
        positionTitle: positionMap.get(row.userId)?.title ?? (row.role === 'owner' ? '대표' : null),
        customTitle: positionMap.get(row.userId)?.title ?? null,
    })));
});
router.patch('/members/:memberId', auth_1.authMiddleware, (req, res) => {
    const user = req.user;
    if (!user)
        return res.status(401).json({ error: 'unauthorized' });
    const { tenantId, role } = req.body || {};
    const targetTenantId = tenantId?.trim();
    if (!targetTenantId)
        return res.status(400).json({ error: 'tenantId required' });
    const desiredRole = role?.toLowerCase();
    if (!desiredRole || !['manager', 'staff'].includes(desiredRole)) {
        return res.status(400).json({ error: 'role must be manager or staff' });
    }
    const actor = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(user.userId, targetTenantId);
    if (!actor || actor.role !== 'owner') {
        return res.status(403).json({ error: 'only owners can update roles' });
    }
    const info = client_1.db
        .prepare('UPDATE memberships SET role = ? WHERE user_id = ? AND tenant_id = ?')
        .run(desiredRole, req.params.memberId, targetTenantId);
    if (info.changes === 0) {
        return res.status(404).json({ error: 'membership not found' });
    }
    return res.json({ userId: req.params.memberId, role: desiredRole });
});
router.patch('/member-positions/:memberId', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const memberId = req.params.memberId;
    const tenantId = req.body?.tenantId?.trim();
    const positionId = req.body?.positionId?.trim();
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId required' });
    const actor = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(req.user.userId, tenantId);
    if (!actor || actor.role !== 'owner') {
        return res.status(403).json({ error: 'only owners can update positions' });
    }
    const targetMember = client_1.db
        .prepare('SELECT role FROM memberships WHERE user_id = ? AND tenant_id = ? LIMIT 1')
        .get(memberId, tenantId);
    if (!targetMember) {
        return res.status(404).json({ error: 'member not found' });
    }
    if ((targetMember.role ?? '').toLowerCase() === 'owner') {
        return res.status(403).json({ error: 'owner position cannot be changed' });
    }
    if (!positionId || positionId.length === 0) {
        client_1.db.prepare('DELETE FROM member_positions WHERE tenant_id = ? AND member_id = ?').run(tenantId, memberId);
        return res.json({ tenantId, memberId, positionId: null, title: '' });
    }
    const positionRow = client_1.db
        .prepare('SELECT title, tier FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1')
        .get(positionId, tenantId);
    if (!positionRow) {
        return res.status(404).json({ error: 'position not found' });
    }
    if ((positionRow.tier ?? '').toLowerCase() === 'owner') {
        return res.status(403).json({ error: 'owner position cannot be assigned' });
    }
    client_1.db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(tenantId, memberId, positionId, positionRow.title ?? '');
    return res.json({ tenantId, memberId, positionId, title: positionRow.title ?? '' });
});
router.get('/positions', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const tenantId = req.query.tenantId?.trim();
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId required' });
    const membership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(req.user.userId, tenantId);
    if (!membership)
        return res.status(403).json({ error: 'forbidden' });
    (0, position_utils_1.ensureTenantPositionDefaults)(tenantId);
    const rows = client_1.db
        .prepare(`SELECT id,
              title,
              COALESCE(created_at, '') AS created_at,
              COALESCE(tier, 'staff') AS tier,
              COALESCE(sort_order, 99) AS sort_order,
              COALESCE(is_locked, 0) AS is_locked
       FROM tenant_positions
       WHERE tenant_id = ?
       ORDER BY sort_order ASC, LOWER(title)`)
        .all(tenantId);
    return res.json(rows.map((row) => ({
        id: row.id,
        tenantId,
        title: row.title,
        createdAt: row.created_at ?? '',
        tier: (row.tier ?? 'staff').toLowerCase(),
        sortOrder: row.sort_order ?? 99,
        isLocked: (row.is_locked ?? 0) === 1,
    })));
});
router.post('/positions', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const { tenantId, title } = req.body || {};
    const normalizedTitle = title?.trim();
    if (!tenantId || !normalizedTitle) {
        return res.status(400).json({ error: 'tenantId and title required' });
    }
    const hierarchy = (req.body?.hierarchy ?? req.body?.tier)?.toLowerCase() ?? 'staff';
    if (!['manager', 'staff'].includes(hierarchy)) {
        return res.status(400).json({ error: 'hierarchy must be manager or staff' });
    }
    const membership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(req.user.userId, tenantId);
    if (!membership || membership.role !== 'owner') {
        return res.status(403).json({ error: 'only owners can manage positions' });
    }
    const id = `pos_${Date.now()}`;
    const sortOrder = hierarchy === 'manager' ? 2 : 3;
    client_1.db.prepare('INSERT INTO tenant_positions (id, tenant_id, title, created_at, tier, sort_order, is_locked) VALUES (?,?,?,?,?,?,0)').run(id, tenantId, normalizedTitle, new Date().toISOString(), hierarchy, sortOrder);
    return res.status(201).json({
        id,
        tenantId,
        title: normalizedTitle,
        tier: hierarchy,
        sortOrder,
        isLocked: false,
    });
});
router.patch('/positions/:id', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const { id } = req.params;
    const { tenantId, title } = req.body || {};
    const normalizedTitle = title?.trim();
    if (!tenantId || !normalizedTitle) {
        return res.status(400).json({ error: 'tenantId and title required' });
    }
    const hierarchy = (req.body?.hierarchy ?? req.body?.tier)?.toLowerCase();
    if (hierarchy && !['manager', 'staff'].includes(hierarchy)) {
        return res.status(400).json({ error: 'hierarchy must be manager or staff' });
    }
    const membership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(req.user.userId, tenantId);
    if (!membership || membership.role !== 'owner') {
        return res.status(403).json({ error: 'only owners can manage positions' });
    }
    const existing = client_1.db
        .prepare('SELECT COALESCE(is_locked, 0) AS is_locked, COALESCE(tier, \'staff\') AS tier FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1')
        .get(id, tenantId);
    if (!existing) {
        return res.status(404).json({ error: 'position not found' });
    }
    if ((existing.is_locked ?? 0) === 1) {
        return res.status(403).json({ error: 'position is locked' });
    }
    const targetTier = hierarchy ?? (existing.tier ?? 'staff');
    const sortOrder = targetTier === 'manager' ? 2 : 3;
    client_1.db.prepare('UPDATE tenant_positions SET title = ?, tier = ?, sort_order = ? WHERE id = ? AND tenant_id = ?').run(normalizedTitle, targetTier, sortOrder, id, tenantId);
    client_1.db.prepare('UPDATE member_positions SET title = ? WHERE tenant_id = ? AND position_id = ?').run(normalizedTitle, tenantId, id);
    return res.json({ id, tenantId, title: normalizedTitle, tier: targetTier, sortOrder, isLocked: false });
});
router.delete('/positions/:id', auth_1.authMiddleware, (req, res) => {
    if (!req.user)
        return res.status(401).json({ error: 'unauthorized' });
    const { id } = req.params;
    const tenantId = req.body?.tenantId?.trim() ??
        req.query.tenantId?.trim();
    if (!tenantId)
        return res.status(400).json({ error: 'tenantId required' });
    const membership = client_1.db
        .prepare(`SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`)
        .get(req.user.userId, tenantId);
    if (!membership || membership.role !== 'owner') {
        return res.status(403).json({ error: 'only owners can manage positions' });
    }
    const existing = client_1.db
        .prepare('SELECT COALESCE(is_locked, 0) AS is_locked FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1')
        .get(id, tenantId);
    if (!existing) {
        return res.status(404).json({ error: 'position not found' });
    }
    if ((existing.is_locked ?? 0) === 1) {
        return res.status(403).json({ error: 'position is locked' });
    }
    client_1.db.prepare('DELETE FROM member_positions WHERE tenant_id = ? AND position_id = ?').run(tenantId, id);
    const info = client_1.db.prepare('DELETE FROM tenant_positions WHERE id = ? AND tenant_id = ?').run(id, tenantId);
    if (info.changes === 0) {
        return res.status(404).json({ error: 'position not found' });
    }
    return res.status(204).end();
});
exports.default = router;
//# sourceMappingURL=controller.js.map