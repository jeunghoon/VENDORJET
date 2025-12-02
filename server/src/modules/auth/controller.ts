import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { db, mapRows } from '../../db/client';
import { env } from '../../config/env';
import { authMiddleware } from '../../middleware/auth';

const router = Router();

router.post('/login', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const userStmt = db.prepare('SELECT id, email, password_hash, user_type FROM users WHERE email = ? LIMIT 1');
  const user = userStmt.get(email) as
    | { id: string; email: string; password_hash: string; user_type?: string }
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

  const token = jwt.sign(
    {
      userId: user.id,
      email: user.email,
      tenantId: primaryMembership?.tenant_id ?? '',
      role: primaryMembership?.role ?? 'admin',
      userType: user.user_type ?? 'wholesale',
    },
    env.jwtSecret,
    { expiresIn: '12h' }
  );
  db.prepare('UPDATE users SET last_login_at = ? WHERE id = ?').run(new Date().toISOString(), user.id);

  return res.json({
    token,
    user: { id: user.id, email: user.email, userType: user.user_type ?? 'wholesale' },
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
    .prepare('SELECT id, email, name, phone, address, created_at, last_login_at, user_type FROM users WHERE id = ?')
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
  const { email, phone, address, name, password } = req.body || {};
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
  const rows = mapRows<{ id: string; name: string; locale: string }>(
    db
      .prepare(
        `SELECT t.id, t.name, t.locale, t.phone, t.address
         FROM tenants t
         INNER JOIN memberships m ON m.tenant_id = t.id
         WHERE m.user_id = ?`
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
  }>(
    db
      .prepare(
        `SELECT
            t.id,
            t.name,
            COALESCE(t.phone, '') AS phone,
            COALESCE(t.address, '') AS address,
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
    })),
  );
});

// seller registration: mode=new -> company owner, mode=existing -> membership request pending
router.post('/register', (req, res) => {
  const {
    companyName,
    companyAddress = '',
    companyPhone = '',
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
      db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)').run(
        tenantId,
        companyName,
        'en',
        nowIso,
        companyPhone,
        companyAddress
      );
      db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)')
        .run(userId, normalizedEmail, password, name, phone, companyAddress, nowIso, 'wholesale');
      db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(userId, tenantId, 'owner');
      db.prepare(
        'INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
      ).run(
        `mr_${Date.now()}`,
        tenantId,
        normalizedEmail,
        name,
        phone,
        'owner',
        'approved',
        companyName,
        companyAddress,
        companyPhone,
        'seller_owner',
        nowIso
      );
    });
    tx();
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

  const reqId = `mr_${Date.now()}`;
  db.prepare(
    'INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
  ).run(
    reqId,
    (existingTenant as any).id,
    normalizedEmail,
    name,
    phone,
    role ?? 'staff',
    'pending',
    companyName,
    companyAddress,
    companyPhone,
    'seller_staff',
    nowIso
  );
  return res.status(202).json({ status: 'pending', requestId: reqId, message: 'pending approval by owner' });
});

// buyer registration: seller company must exist, buyer company can be new(owner) or existing(pending)
router.post('/register-buyer', (req, res) => {
  const {
    sellerCompanyName,
    buyerCompanyName,
    buyerAddress = '',
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
  if (!resolvedSellerCompany) {
    return res.status(400).json({ error: 'sellerCompanyName required' });
  }
  const sellerTenant = db
    .prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1')
    .get(resolvedSellerCompany) as any;
  if (!sellerTenant) {
    return res.status(404).json({ error: 'seller company not found' });
  }

  const existingBuyerTenant = db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(buyerCompanyName) as any;
  let buyerTenantId = existingBuyerTenant?.id as string | undefined;
  if (!existingBuyerTenant && mode === 'existing') {
    return res.status(404).json({ error: 'buyer company not found' });
  }
  if (!existingBuyerTenant && mode === 'new') {
    buyerTenantId = `t_${Date.now()}`;
    db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)').run(
      buyerTenantId,
      buyerCompanyName,
      'en',
      nowIso,
      '',
      buyerAddress
    );
    db.prepare('INSERT INTO memberships (user_id, tenant_id, role, status) VALUES (?,?,?,?)').run(
      userId,
      buyerTenantId,
      'owner',
      'approved'
    );
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

export default router;
