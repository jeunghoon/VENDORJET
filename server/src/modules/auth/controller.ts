import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { db, mapRows } from '../../db/client';
import { env } from '../../config/env';
import { authMiddleware } from '../../middleware/auth';
import { assignOwnerDefaultPosition, assignPendingPosition, ensureTenantPositionDefaults } from './position_utils';

const router = Router();

router.post('/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const userStmt = db.prepare(
    `SELECT id, email, password_hash, user_type, name, phone, language_preference, primary_tenant_id
     FROM users
     WHERE email = ?
     LIMIT 1`
  );
  const user = userStmt.get(email) as
    | {
        id: string;
        email: string;
        password_hash: string;
        user_type?: string;
        name?: string;
        phone?: string;
        language_preference?: string;
        primary_tenant_id?: string;
      }
    | undefined;
  if (!user || user.password_hash !== password) {
    return res.status(401).json({ error: 'invalid credentials' });
  }

  const membershipsRows = db
    .prepare(
      `SELECT user_id, tenant_id, role, status
       FROM memberships
       WHERE user_id = ?
       ORDER BY (status = 'approved') DESC, rowid DESC`
    )
    .all(user.id) as { user_id: string; tenant_id: string; role: string; status?: string }[];
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
  const token = jwt.sign(tokenPayload, env.jwtSecret, { expiresIn: '12h' });
  db.prepare('UPDATE users SET last_login_at = ? WHERE id = ?').run(new Date().toISOString(), user.id);

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
  const email = (req.query.email as string | undefined)?.toLowerCase();
  if (!email) return res.status(400).json({ error: 'email required' });
  const exists = db.prepare('SELECT 1 FROM users WHERE email = ? LIMIT 1').get(email);
  return res.json({ exists: !!exists });
});

router.get('/me', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  return res.json({ user: req.user });
});

router.get('/profile', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const row = db
    .prepare(
      `SELECT id,
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
       WHERE id = ?`
    )
    .get(req.user.userId) as { [key: string]: any } | undefined;
  if (!row) return res.status(404).json({ error: 'not found' });
  if ((row.user_type ?? '') === 'retail') {
    const pending = db
      .prepare(
        `SELECT seller_company
         FROM buyer_requests
         WHERE user_id = ? AND status = 'pending'
         ORDER BY created_at DESC
         LIMIT 1`
      )
      .get(req.user.userId) as { seller_company?: string } | undefined;
    row.pending_seller = pending?.seller_company ?? null;
  }
  return res.json(row);
});

router.patch('/profile', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const {
    email,
    phone,
    name,
    password,
    language,
    primaryTenantId,
  } = req.body || {};
  const updates: string[] = [];
  const params: any[] = [];
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
    const ownsTenant = db
      .prepare(
        `SELECT 1
         FROM memberships
         WHERE user_id = ?
           AND tenant_id = ?
           AND COALESCE(status, 'approved') = 'approved'
         LIMIT 1`
      )
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
  if (updates.length === 0) return res.json({ ok: true });
  const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;
  params.push(req.user.userId);
  db.prepare(sql).run(...params);
  return res.json({ ok: true });
});

router.delete('/profile', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const uid = req.user.userId;
  const userRow = db
    .prepare('SELECT email, user_type FROM users WHERE id = ? LIMIT 1')
    .get(uid) as { email?: string; user_type?: string } | undefined;
  if (!userRow) return res.status(404).json({ error: 'not found' });
  const tx = db.transaction(() => {
    if ((userRow.user_type ?? '') === 'retail' && userRow.email) {
      db.prepare("UPDATE buyer_requests SET status = 'withdrawn' WHERE email = ?").run(userRow.email);
    }
    db.prepare('DELETE FROM memberships WHERE user_id = ?').run(uid);
    db.prepare('DELETE FROM users WHERE id = ?').run(uid);
  });
  tx();
  return res.status(204).end();
});

router.get('/tenants', authMiddleware, (_req, res) => {
  if (!_req.user) return res.status(401).json({ error: 'unauthorized' });
  const rows = mapRows<{
    id: string;
    name: string;
    locale: string;
    phone: string;
    address: string;
    representative: string;
    created_at: string;
    tenant_type: string;
    isPrimary: number;
  }>(
    db
      .prepare(
        `SELECT
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
         ORDER BY LOWER(t.name)`
      )
      .all(_req.user.userId)
  );
  res.json(rows);
});

router.get('/tenants-public', (_req, res) => {
  const includeRetail = (_req.query.includeRetail as string | undefined) === 'true';
  const type = (_req.query.type as string | undefined)?.toLowerCase();
  let whereClause = "COALESCE(u.user_type, 'wholesale') != 'retail'";
  if (type === 'retail') {
    whereClause = "COALESCE(u.user_type, 'wholesale') = 'retail'";
  } else if (type === 'wholesale') {
    whereClause = "COALESCE(u.user_type, 'wholesale') != 'retail'";
  } else if (includeRetail) {
    whereClause = '1=1';
  }

  const rows = mapRows<{
    id: string;
    name: string;
    phone: string;
    address: string;
    tenantType: string;
    segment: string;
    representative: string;
  }>(
    db
      .prepare(
        `SELECT DISTINCT
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
         ORDER BY LOWER(t.name)`
      )
      .all()
  );
  res.json(
    rows.map((row) => ({
      id: row.id,
      name: row.name,
      phone: row.phone ?? '',
      address: row.address ?? '',
      type: row.tenantType,
      segment: row.segment ?? '',
      representative: row.representative ?? '',
    })),
  );
});

// seller registration: mode=new -> company owner, mode=existing -> membership request pending
router.post('/register', (req, res) => {
  const {
    companyName,
    companyAddress = '',
    companyPhone = '',
    companyRepresentative = '',
    name = '',
    phone = '',
    email,
    password,
    role,
    mode = 'new',
  } = req.body || {};
  if (!companyName || !email || !password) {
    return res.status(400).json({ error: 'companyName, email, password required' });
  }
  const normalizedEmail = email.toLowerCase();
  const existingEmail = db.prepare('SELECT 1 FROM users WHERE email = ? LIMIT 1').get(normalizedEmail);
  if (existingEmail) return res.status(409).json({ error: 'email already exists' });
  if (mode !== 'new' && mode !== 'existing') {
    return res.status(400).json({ error: 'mode must be new or existing' });
  }
  const nowIso = new Date().toISOString();
  const existingTenant = db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(companyName) as any;

  if (!existingTenant) {
    if (mode === 'existing') return res.status(404).json({ error: 'company not found' });
    const tenantId = `t_${Date.now()}`;
    const userId = `u_${Date.now()}`;
    const tx = db.transaction(() => {
      db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address, representative) VALUES (?,?,?,?,?,?,?)').run(
        tenantId,
        companyName,
        'en',
        nowIso,
        companyPhone,
        companyAddress,
        companyRepresentative || name
      );
      db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)')
        .run(userId, normalizedEmail, password, name, phone, companyAddress, nowIso, 'wholesale');
      db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(userId, tenantId, 'owner');
    });
    tx();
    ensureTenantPositionDefaults(tenantId);
    assignOwnerDefaultPosition(tenantId, userId);
    const token = jwt.sign({ userId, email, tenantId, role: 'owner' }, env.jwtSecret, { expiresIn: '12h' });
    return res.status(201).json({
      token,
      user: { id: userId, email },
      memberships: [{ tenantId, role: 'owner' }],
    });
  }

  if (mode === 'new') {
    return res.status(400).json({ error: 'company already exists, choose existing mode' });
  }

  const tenantId = (existingTenant as any).id as string;
  const userId = `u_${Date.now()}`;
  const normalizedRole = (role as string | undefined)?.toLowerCase();
  const assignedRole = normalizedRole === 'manager' ? 'manager' : 'staff';
  const txExisting = db.transaction(() => {
    db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)').run(
      userId,
      normalizedEmail,
      password,
      name,
      phone,
      companyAddress,
      nowIso,
      'wholesale',
    );
    db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(userId, tenantId, assignedRole, 'approved');
  });
  txExisting();
  assignPendingPosition(tenantId, userId);
  const token = jwt.sign({ userId, email, tenantId, role: assignedRole }, env.jwtSecret, { expiresIn: '12h' });
  return res.status(201).json({
    token,
    user: { id: userId, email },
    memberships: [{ tenantId, role: assignedRole }],
  });
});

// buyer registration: seller company must exist, buyer company can be new(owner) or existing(pending)
router.post('/register-buyer', (req, res) => {
  const {
    sellerCompanyName,
    buyerCompanyName,
    buyerAddress = '',
    buyerRepresentative = '',
    name = '',
    phone = '',
    email,
    password,
    attachmentUrl = '',
    buyerSegment = '',
    role = 'staff',
    mode = 'new',
  } = req.body || {};
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
  const membershipRole =
    requestedRoleRaw === 'owner'
      ? 'owner'
      : requestedRoleRaw === 'manager'
          ? 'manager'
          : 'staff';

  const normalizedEmail = email.toLowerCase();
  const existingUser = db.prepare('SELECT id FROM users WHERE email = ? LIMIT 1').get(normalizedEmail) as
    | { id: string }
    | undefined;
  if (existingUser) {
    return res.status(409).json({ error: 'email already exists' });
  }
  const userId = `u_${Date.now()}`;
  db.prepare(
    'INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)'
  ).run(userId, normalizedEmail, password, name, phone, buyerAddress, nowIso, 'retail');

  let resolvedSellerCompany = sellerCompanyName;
  if (!resolvedSellerCompany && mode === 'existing') {
    const prev = db
      .prepare('SELECT seller_company FROM buyer_requests WHERE buyer_company = ? ORDER BY created_at DESC LIMIT 1')
      .get(buyerCompanyName) as { seller_company?: string } | undefined;
    resolvedSellerCompany = prev?.seller_company;
  }
  let sellerTenant: { id: string } | undefined;
  if (resolvedSellerCompany) {
    sellerTenant = db
      .prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1')
      .get(resolvedSellerCompany) as { id: string } | undefined;
    if (!sellerTenant) {
      return res.status(404).json({ error: 'seller company not found' });
    }
  }

  const existingBuyerTenant = db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(buyerCompanyName) as any;
  let buyerTenantId = existingBuyerTenant?.id as string | undefined;
  if (!existingBuyerTenant && mode === 'existing') {
    return res.status(404).json({ error: 'buyer company not found' });
  }
  const createdNewBuyerTenant = !existingBuyerTenant && mode === 'new';
  if (createdNewBuyerTenant) {
    buyerTenantId = `t_${Date.now()}`;
    db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address, representative) VALUES (?,?,?,?,?,?,?)').run(
      buyerTenantId,
      buyerCompanyName,
      'en',
      nowIso,
      '',
      buyerAddress,
      buyerRepresentative || name
    );
    db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(
      userId,
      buyerTenantId,
      'owner',
      'approved'
    );
    ensureTenantPositionDefaults(buyerTenantId);
    assignOwnerDefaultPosition(buyerTenantId, userId);
  } else if (buyerTenantId != null && existingBuyerTenant) {
    db.prepare('INSERT OR IGNORE INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(
      userId,
      buyerTenantId,
      membershipRole,
      'approved'
    );
    assignPendingPosition(buyerTenantId, userId);
  }

  if (!sellerTenant) {
    return res.status(201).json({
      status: 'registered',
      message: 'buyer registered without seller connection',
    });
  }

  db.prepare(
    'INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at, user_id, buyer_tenant_id, requested_segment) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
  ).run(
    reqId,
    resolvedSellerCompany,
    buyerCompanyName,
    buyerAddress,
    normalizedEmail,
    name,
    phone,
    role,
    attachmentUrl,
    'pending',
    nowIso,
    userId,
    buyerTenantId ?? '',
    buyerSegment
  );

  return res.status(202).json({
    status: 'pending',
    requestId: reqId,
    message: 'pending approval',
  });
});

router.post('/buyer/reapply', authMiddleware, (req, res) => {
  const user = req.user;
  if (!user) return res.status(401).json({ error: 'unauthorized' });
  if ((user.userType ?? 'wholesale') !== 'retail') {
    return res.status(403).json({ error: 'only buyers can reapply' });
  }
  const {
    sellerCompanyName,
    buyerCompanyName,
    buyerAddress = '',
    buyerSegment = '',
    attachmentUrl = '',
    name = '',
    phone = '',
  } = req.body || {};
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

  const userRow = db
    .prepare('SELECT email, name, phone, address FROM users WHERE id = ? LIMIT 1')
    .get(user.userId) as { email?: string; name?: string; phone?: string; address?: string } | undefined;
  if (!userRow?.email) {
    return res.status(404).json({ error: 'user not found' });
  }

  const sellerTenant = db
    .prepare('SELECT id, phone, address FROM tenants WHERE name = ? LIMIT 1')
    .get(normalizedSeller) as { id: string; phone?: string; address?: string } | undefined;
  if (!sellerTenant) {
    return res.status(404).json({ error: 'seller company not found' });
  }

  const buyerTenant = db
    .prepare('SELECT id, phone, address FROM tenants WHERE name = ? LIMIT 1')
    .get(normalizedBuyer) as { id: string; phone?: string; address?: string } | undefined;
  if (!buyerTenant) {
    return res.status(404).json({ error: 'buyer company not found' });
  }
  const buyerMembership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(user.userId, buyerTenant.id) as { role?: string } | undefined;
  if (!buyerMembership || buyerMembership.role !== 'owner') {
    return res.status(403).json({ error: 'only buyer owners can request connections' });
  }

  const existingMembership = db
    .prepare(
      `SELECT 1
       FROM memberships
       WHERE user_id = ? AND tenant_id = ? AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`
    )
    .get(user.userId, sellerTenant.id);
  if (existingMembership) {
    return res.status(409).json({ error: 'already connected' });
  }

  const existingCompanyConnection = db
    .prepare(
      `SELECT 1
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
       LIMIT 1`
    )
    .get(sellerTenant.id, buyerTenant.id);
  if (existingCompanyConnection) {
    return res.status(409).json({ error: 'company already connected' });
  }

  const pendingRequest = db
    .prepare(
      `SELECT 1
       FROM buyer_requests
       WHERE user_id = ? AND seller_company = ? AND status = 'pending'
       LIMIT 1`
    )
    .get(user.userId, normalizedSeller);
  if (pendingRequest) {
    return res.status(409).json({ error: 'pending request already exists' });
  }

  const pendingCompanyRequest = db
    .prepare(
      `SELECT 1
       FROM buyer_requests
       WHERE buyer_company = ?
         AND seller_company = ?
         AND status = 'pending'
       LIMIT 1`
    )
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
  db.prepare(
    `INSERT INTO buyer_requests (
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
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`
  ).run(
    reqId,
    normalizedSeller,
    sellerTenant.phone ?? '',
    sellerTenant.address ?? '',
    normalizedBuyer,
    buyerAddress,
    userRow.email,
    resolvedName,
    resolvedPhone,
    'staff',
    normalizedAttachment,
    'pending',
    nowIso,
    user.userId,
    buyerTenant.id,
    normalizedSegment
  );

  return res.status(202).json({
    status: 'pending',
    requestId: reqId,
    message: 'pending approval',
  });
});

router.get('/members', authMiddleware, (req, res) => {
  const user = req.user;
  if (!user) return res.status(401).json({ error: 'unauthorized' });
  const tenantId = ((req.query.tenantId as string | undefined)?.trim() || user.tenantId)?.trim();
  if (!tenantId) return res.status(400).json({ error: 'tenantId required' });
  const membership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`
    )
    .get(user.userId, tenantId) as { role?: string } | undefined;
  if (!membership) return res.status(403).json({ error: 'forbidden' });
  ensureTenantPositionDefaults(tenantId);
  const tenantInfo = db
    .prepare(
      `SELECT
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
       LIMIT 1`
    )
    .get(tenantId) as { tenant_type?: string } | undefined;
  const tenantType = (tenantInfo?.tenant_type ?? 'seller').toLowerCase();
  const allowedUserType = tenantType === 'buyer' ? 'retail' : 'wholesale';

  const userTypeFilter =
    allowedUserType === 'retail'
      ? "COALESCE(u.user_type, 'wholesale') = 'retail'"
      : "COALESCE(u.user_type, 'wholesale') != 'retail'";
  const rows = mapRows<{
    userId: string;
    name: string;
    email: string;
    phone: string;
    role: string;
    status: string;
  }>(
    db
      .prepare(
        `SELECT u.id   AS user_id,
                COALESCE(u.name, '') AS name,
                COALESCE(u.email, '') AS email,
                COALESCE(u.phone, '') AS phone,
                COALESCE(m.role, 'staff') AS role,
                COALESCE(m.status, 'approved') AS status
         FROM memberships m
         INNER JOIN users u ON u.id = m.user_id
         WHERE m.tenant_id = ?
           AND ${userTypeFilter}
         ORDER BY LOWER(u.email)`
      )
      .all(tenantId)
  );
  const positionRows = db
    .prepare(
      'SELECT member_id AS memberId, title, position_id AS positionId FROM member_positions WHERE tenant_id = ?',
    )
    .all(tenantId) as { memberId: string; title: string; positionId?: string }[];
  const positionMap = new Map(positionRows.map((row) => [row.memberId, row]));
  rows
    .filter((row) => row.role === 'owner' && !positionMap.has(row.userId))
    .forEach((ownerRow) => {
      assignOwnerDefaultPosition(tenantId, ownerRow.userId);
      const assigned = db
        .prepare('SELECT member_id AS memberId, title, position_id AS positionId FROM member_positions WHERE tenant_id = ? AND member_id = ? LIMIT 1')
        .get(tenantId, ownerRow.userId) as { memberId: string; title: string; positionId?: string } | undefined;
      if (assigned) {
        positionMap.set(ownerRow.userId, assigned);
      }
    });
  return res.json(
    rows.map((row) => ({
      ...row,
      positionId: positionMap.get(row.userId)?.positionId ?? null,
      positionTitle: positionMap.get(row.userId)?.title ?? (row.role === 'owner' ? '대표' : null),
      customTitle: positionMap.get(row.userId)?.title ?? null,
    })),
  );
});

router.patch('/members/:memberId', authMiddleware, (req, res) => {
  const user = req.user;
  if (!user) return res.status(401).json({ error: 'unauthorized' });
  const { tenantId, role } = req.body || {};
  const targetTenantId = (tenantId as string | undefined)?.trim();
  if (!targetTenantId) return res.status(400).json({ error: 'tenantId required' });
  const desiredRole = (role as string | undefined)?.toLowerCase();
  if (!desiredRole || !['manager', 'staff'].includes(desiredRole)) {
    return res.status(400).json({ error: 'role must be manager or staff' });
  }
  const actor = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`
    )
    .get(user.userId, targetTenantId) as { role?: string } | undefined;
  if (!actor || actor.role !== 'owner') {
    return res.status(403).json({ error: 'only owners can update roles' });
  }
  const info = db
    .prepare('UPDATE memberships SET role = ? WHERE user_id = ? AND tenant_id = ?')
    .run(desiredRole, req.params.memberId, targetTenantId);
  if (info.changes === 0) {
    return res.status(404).json({ error: 'membership not found' });
  }
  return res.json({ userId: req.params.memberId, role: desiredRole });
});

router.patch('/member-positions/:memberId', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const memberId = req.params.memberId;
  const tenantId = (req.body?.tenantId as string | undefined)?.trim();
  const positionId = (req.body?.positionId as string | undefined)?.trim();
  if (!tenantId) return res.status(400).json({ error: 'tenantId required' });
  const actor = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(req.user.userId, tenantId) as { role?: string } | undefined;
  if (!actor || actor.role !== 'owner') {
    return res.status(403).json({ error: 'only owners can update positions' });
  }
  const targetMember = db
    .prepare('SELECT role FROM memberships WHERE user_id = ? AND tenant_id = ? LIMIT 1')
    .get(memberId, tenantId) as { role?: string } | undefined;
  if (!targetMember) {
    return res.status(404).json({ error: 'member not found' });
  }
  if ((targetMember.role ?? '').toLowerCase() === 'owner') {
    return res.status(403).json({ error: 'owner position cannot be changed' });
  }
  if (!positionId || positionId.length === 0) {
    db.prepare('DELETE FROM member_positions WHERE tenant_id = ? AND member_id = ?').run(tenantId, memberId);
    return res.json({ tenantId, memberId, positionId: null, title: '' });
  }
  const positionRow = db
    .prepare('SELECT title, tier FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1')
    .get(positionId, tenantId) as { title?: string; tier?: string } | undefined;
  if (!positionRow) {
    return res.status(404).json({ error: 'position not found' });
  }
  if ((positionRow.tier ?? '').toLowerCase() === 'owner') {
    return res.status(403).json({ error: 'owner position cannot be assigned' });
  }
  db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(
    tenantId,
    memberId,
    positionId,
    positionRow.title ?? '',
  );
  return res.json({ tenantId, memberId, positionId, title: positionRow.title ?? '' });
});

router.get('/positions', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const tenantId = (req.query.tenantId as string | undefined)?.trim();
  if (!tenantId) return res.status(400).json({ error: 'tenantId required' });
  const membership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(req.user.userId, tenantId) as { role?: string } | undefined;
  if (!membership) return res.status(403).json({ error: 'forbidden' });
  ensureTenantPositionDefaults(tenantId);
  const rows = db
    .prepare(
      `SELECT id,
              title,
              COALESCE(created_at, '') AS created_at,
              COALESCE(tier, 'staff') AS tier,
              COALESCE(sort_order, 99) AS sort_order,
              COALESCE(is_locked, 0) AS is_locked
       FROM tenant_positions
       WHERE tenant_id = ?
       ORDER BY sort_order ASC, LOWER(title)`
    )
    .all(tenantId) as {
      id: string;
      title: string;
      created_at?: string;
      tier?: string;
      sort_order?: number;
      is_locked?: number;
    }[];
  return res.json(
    rows.map((row) => ({
      id: row.id,
      tenantId,
      title: row.title,
      createdAt: row.created_at ?? '',
      tier: (row.tier ?? 'staff').toLowerCase(),
      sortOrder: row.sort_order ?? 99,
      isLocked: (row.is_locked ?? 0) === 1,
    })),
  );
});

router.post('/positions', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const { tenantId, title } = req.body || {};
  const normalizedTitle = (title as string | undefined)?.trim();
  if (!tenantId || !normalizedTitle) {
    return res.status(400).json({ error: 'tenantId and title required' });
  }
  const hierarchy = ((req.body?.hierarchy ?? req.body?.tier) as string | undefined)?.toLowerCase() ?? 'staff';
  if (!['manager', 'staff'].includes(hierarchy)) {
    return res.status(400).json({ error: 'hierarchy must be manager or staff' });
  }
  const membership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(req.user.userId, tenantId) as { role?: string } | undefined;
  if (!membership || membership.role !== 'owner') {
    return res.status(403).json({ error: 'only owners can manage positions' });
  }
  const id = `pos_${Date.now()}`;
  const sortOrder = hierarchy === 'manager' ? 2 : 3;
  db.prepare(
    'INSERT INTO tenant_positions (id, tenant_id, title, created_at, tier, sort_order, is_locked) VALUES (?,?,?,?,?,?,0)',
  ).run(
    id,
    tenantId,
    normalizedTitle,
    new Date().toISOString(),
    hierarchy,
    sortOrder,
  );
  return res.status(201).json({
    id,
    tenantId,
    title: normalizedTitle,
    tier: hierarchy,
    sortOrder,
    isLocked: false,
  });
});

router.patch('/positions/:id', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const { id } = req.params;
  const { tenantId, title } = req.body || {};
  const normalizedTitle = (title as string | undefined)?.trim();
  if (!tenantId || !normalizedTitle) {
    return res.status(400).json({ error: 'tenantId and title required' });
  }
  const hierarchy = ((req.body?.hierarchy ?? req.body?.tier) as string | undefined)?.toLowerCase();
  if (hierarchy && !['manager', 'staff'].includes(hierarchy)) {
    return res.status(400).json({ error: 'hierarchy must be manager or staff' });
  }
  const membership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(req.user.userId, tenantId) as { role?: string } | undefined;
  if (!membership || membership.role !== 'owner') {
    return res.status(403).json({ error: 'only owners can manage positions' });
  }
  const existing = db
    .prepare(
      'SELECT COALESCE(is_locked, 0) AS is_locked, COALESCE(tier, \'staff\') AS tier FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1',
    )
    .get(id, tenantId) as { is_locked?: number; tier?: string } | undefined;
  if (!existing) {
    return res.status(404).json({ error: 'position not found' });
  }
  if ((existing.is_locked ?? 0) === 1) {
    return res.status(403).json({ error: 'position is locked' });
  }
  const targetTier = hierarchy ?? (existing.tier ?? 'staff');
  const sortOrder = targetTier === 'manager' ? 2 : 3;
  db.prepare('UPDATE tenant_positions SET title = ?, tier = ?, sort_order = ? WHERE id = ? AND tenant_id = ?').run(
    normalizedTitle,
    targetTier,
    sortOrder,
    id,
    tenantId,
  );
  db.prepare('UPDATE member_positions SET title = ? WHERE tenant_id = ? AND position_id = ?').run(
    normalizedTitle,
    tenantId,
    id,
  );
  return res.json({ id, tenantId, title: normalizedTitle, tier: targetTier, sortOrder, isLocked: false });
});

router.delete('/positions/:id', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const { id } = req.params;
  const tenantId = (req.body?.tenantId as string | undefined)?.trim() ??
    (req.query.tenantId as string | undefined)?.trim();
  if (!tenantId) return res.status(400).json({ error: 'tenantId required' });
  const membership = db
    .prepare(
      `SELECT role
       FROM memberships
       WHERE user_id = ?
         AND tenant_id = ?
         AND COALESCE(status, 'approved') = 'approved'
       LIMIT 1`,
    )
    .get(req.user.userId, tenantId) as { role?: string } | undefined;
  if (!membership || membership.role !== 'owner') {
    return res.status(403).json({ error: 'only owners can manage positions' });
  }
  const existing = db
    .prepare('SELECT COALESCE(is_locked, 0) AS is_locked FROM tenant_positions WHERE id = ? AND tenant_id = ? LIMIT 1')
    .get(id, tenantId) as { is_locked?: number } | undefined;
  if (!existing) {
    return res.status(404).json({ error: 'position not found' });
  }
  if ((existing.is_locked ?? 0) === 1) {
    return res.status(403).json({ error: 'position is locked' });
  }
  db.prepare('DELETE FROM member_positions WHERE tenant_id = ? AND position_id = ?').run(tenantId, id);
  const info = db.prepare('DELETE FROM tenant_positions WHERE id = ? AND tenant_id = ?').run(id, tenantId);
  if (info.changes === 0) {
    return res.status(404).json({ error: 'position not found' });
  }
  return res.status(204).end();
});

export default router;
