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

  // 媛꾨떒??plaintext 鍮꾧탳 (紐⑹뾽)
  const userStmt = db.prepare(
    'SELECT id, email, password_hash FROM users WHERE email = ? LIMIT 1'
  );
  const user = userStmt.get(email) as { id: string; email: string; password_hash: string } | undefined;
  if (!user || user.password_hash !== password) {
    return res.status(401).json({ error: 'invalid credentials' });
  }

  const membershipsStmt = db.prepare(
    'SELECT user_id, tenant_id, role FROM memberships WHERE user_id = ?'
  );
  const membershipsRows = membershipsStmt.all(user.id) as {
    user_id: string;
    tenant_id: string;
    role: string;
  }[];
  const memberships = membershipsRows.map((m) => ({
    tenantId: m.tenant_id,
    role: m.role,
  }));

  const token = jwt.sign(
    {
      userId: user.id,
      email: user.email,
      tenantId: memberships[0]?.tenantId ?? '',
      role: memberships[0]?.role ?? 'admin',
    },
    env.jwtSecret,
    { expiresIn: '12h' }
  );
  db.prepare('UPDATE users SET last_login_at = ? WHERE id = ?').run(new Date().toISOString(), user.id);

  return res.json({
    token,
    user: { id: user.id, email: user.email },
    memberships,
  });
});

router.get('/me', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  return res.json({ user: req.user });
});

// ???꾨줈??議고쉶
router.get('/profile', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const row = db
    .prepare('SELECT id, email, name, phone, address, created_at, last_login_at, user_type FROM users WHERE id = ?')
    .get(req.user.userId);
  return res.json(row);
});

// ???꾨줈???낅뜲?댄듃
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

// ??怨꾩젙 ??젣
router.delete('/profile', authMiddleware, (req, res) => {
  if (!req.user) return res.status(401).json({ error: 'unauthorized' });
  const uid = req.user.userId;
  const tx = db.transaction(() => {
    db.prepare('DELETE FROM memberships WHERE user_id = ?').run(uid);
    db.prepare('DELETE FROM users WHERE id = ?').run(uid);
  });
  tx();
  return res.status(204).end();
});

router.get('/tenants', authMiddleware, (_req, res) => {
  const rows = mapRows<{ id: string; name: string; locale: string }>(
    db.prepare('SELECT * FROM tenants').all()
  );
  res.json(rows);
});

// 怨듦컻 ?뚮꼳??紐⑸줉 (援щℓ??媛?????먮ℓ??寃?됱슜)
router.get('/tenants-public', (_req, res) => {
  const rows = mapRows<{ id: string; name: string; phone: string; address: string }>(
    db.prepare('SELECT id, name, phone, address FROM tenants').all()
  );
  res.json(rows);
});

// ?먮ℓ???좉퇋 媛?? ???뚯궗硫??뚮꼳??owner ?앹꽦, 湲곗〈 ?뚯궗硫??뱀씤 ?붿껌留??앹꽦
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
  } = req.body || {};
  if (!companyName || !email || !password) {
    return res.status(400).json({ error: 'companyName, email, password required' });
  }
  const nowIso = new Date().toISOString();
  const existingTenant = db.prepare('SELECT id FROM tenants WHERE name = ? LIMIT 1').get(companyName) as any;
  if (!existingTenant) {
    const tenantId = `t_${Date.now()}`;
    const userId = `u_${Date.now()}`;
    const tx = db.transaction(() => {
      db.prepare('INSERT INTO tenants (id, name, locale, created_at, phone, address) VALUES (?,?,?,?,?,?)')
        .run(tenantId, companyName, 'en', nowIso, companyPhone, companyAddress);
      db.prepare('INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)')
        .run(userId, email, password, name, phone, companyAddress, nowIso, 'wholesale');
      db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)')
        .run(userId, tenantId, 'owner');
      db.prepare(
        'INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
      ).run(
        `mr_${Date.now()}`,
        tenantId,
        email,
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
    const token = jwt.sign(
      { userId, email, tenantId, role: 'owner' },
      env.jwtSecret,
      { expiresIn: '12h' }
    );
    return res.status(201).json({
      token,
      user: { id: userId, email },
      memberships: [{ tenantId, role: 'owner' }],
    });
  }

  // 湲곗〈 ?뚯궗硫??뱀씤 ?붿껌 ?앹꽦
  const reqId = `mr_${Date.now()}`;
  db.prepare(
    'INSERT INTO membership_requests (id, tenant_id, email, name, phone, role, status, company_name, company_address, company_phone, requester_type, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
  ).run(
    reqId,
    (existingTenant as any).id,
    email,
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
  return res.status(202).json({ status: 'pending', requestId: reqId, message: '?뱀씤 ?湲?以묒엯?덈떎.' });
});

// 援щℓ??媛???붿껌: ?먮ℓ???뚯궗 + 援щℓ???뚯궗 ?뺣낫? 泥⑤??뚯씪(?듭뀡) ?깅줉
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
    role = 'staff',
  } = req.body || {};
  if (!sellerCompanyName || !buyerCompanyName || !email || !password) {
    return res
      .status(400)
      .json({ error: 'sellerCompanyName, buyerCompanyName, email, password required' });
  }
  const reqId = `br_${Date.now()}`;
  const nowIso = new Date().toISOString();

  const existingUser = db.prepare('SELECT id FROM users WHERE email = ? LIMIT 1').get(email) as
    | { id: string }
    | undefined;
  const userId = existingUser?.id ?? `u_${Date.now()}`;
  const upsertUser = db.transaction(() => {
    if (existingUser) {
      db.prepare(
        'UPDATE users SET password_hash = COALESCE(?, password_hash), name = COALESCE(?, name), phone = COALESCE(?, phone), address = COALESCE(?, address), user_type = COALESCE(?, user_type), updated_at = ? WHERE id = ?'
      ).run(password, name, phone, buyerAddress, 'buyer', nowIso, userId);
    } else {
      db.prepare(
        'INSERT INTO users (id, email, password_hash, name, phone, address, created_at, user_type) VALUES (?,?,?,?,?,?,?,?)'
      ).run(userId, email, password, name, phone, buyerAddress, nowIso, 'buyer');
    }
  });
  upsertUser();

  db.prepare(
    'INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at, user_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
  ).run(
    reqId,
    sellerCompanyName,
    buyerCompanyName,
    buyerAddress,
    email,
    name,
    phone,
    role,
    attachmentUrl,
    'pending',
    nowIso,
    userId
  );
  return res
    .status(202)
    .json({ status: 'pending', requestId: reqId, message: '판매자 승인 대기중입니다.' });
});
router.post('/users', authMiddleware, (req, res) => {
  const { email, password, tenantId, role = 'admin' } = req.body || {};
  const resolvedTenant = tenantId ?? req.user?.tenantId;
  if (!email || !password || !resolvedTenant) {
    return res.status(400).json({ error: 'email, password, tenantId required' });
  }
  const userId = `u_${Date.now()}`;
  const tx = db.transaction(() => {
    db.prepare('INSERT INTO users (id, email, password_hash) VALUES (?,?,?)').run(
      userId,
      email,
      password
    );
    db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)').run(
      userId,
      resolvedTenant,
      role
    );
  });
  tx();
  res.status(201).json({ id: userId, email, tenantId: resolvedTenant, role });
});

router.put('/users/:id', authMiddleware, (req, res) => {
  const userId = req.params.id;
  const { email, password, role, tenantId } = req.body || {};
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as { email?: string } | undefined;
  if (!user) return res.status(404).json({ error: 'not found' });

  const tx = db.transaction(() => {
    if (email || password) {
      db.prepare('UPDATE users SET email = COALESCE(?, email), password_hash = COALESCE(?, password_hash) WHERE id = ?')
        .run(email, password, userId);
    }
    if (tenantId) {
      db.prepare('DELETE FROM memberships WHERE user_id = ?').run(userId);
      db.prepare('INSERT INTO memberships (user_id, tenant_id, role) VALUES (?,?,?)')
        .run(userId, tenantId, role ?? 'admin');
    } else if (role) {
      db.prepare('UPDATE memberships SET role = ? WHERE user_id = ?').run(role, userId);
    }
  });
  tx();
  res.json({ id: userId, email: email ?? user.email ?? '', tenantId: tenantId ?? req.user?.tenantId, role: role ?? 'admin' });
});

router.delete('/users/:id', authMiddleware, (req, res) => {
  const userId = req.params.id;
  const tx = db.transaction(() => {
    db.prepare('DELETE FROM memberships WHERE user_id = ?').run(userId);
    db.prepare('DELETE FROM users WHERE id = ?').run(userId);
  });
  tx();
  res.status(204).end();
});

export const authController = router;
