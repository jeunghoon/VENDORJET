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

  // 간단히 plaintext 비교 (목업)
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

router.get('/tenants', authMiddleware, (_req, res) => {
  const rows = mapRows<{ id: string; name: string; locale: string }>(
    db.prepare('SELECT * FROM tenants').all()
  );
  res.json(rows);
});

// 판매자 신규 가입: 새 회사면 테넌트+owner 생성, 기존 회사면 승인 요청만 생성
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
      db.prepare('INSERT INTO users (id, email, password_hash, name, phone) VALUES (?,?,?,?,?)')
        .run(userId, email, password, name, phone);
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

  // 기존 회사면 승인 요청 생성
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
  return res.status(202).json({ status: 'pending', requestId: reqId, message: '승인 대기 중입니다.' });
});

// 구매자 가입 요청: 판매자 회사 + 구매자 회사 정보와 첨부파일(옵션) 등록
router.post('/register-buyer', (req, res) => {
  const {
    sellerCompanyName,
    buyerCompanyName,
    buyerAddress = '',
    name = '',
    phone = '',
    email,
    attachmentUrl = '',
    role = 'staff',
  } = req.body || {};
  if (!sellerCompanyName || !buyerCompanyName || !email) {
    return res.status(400).json({ error: 'sellerCompanyName, buyerCompanyName, email required' });
  }
  const reqId = `br_${Date.now()}`;
  db.prepare(
    'INSERT INTO buyer_requests (id, seller_company, buyer_company, buyer_address, email, name, phone, role, attachment_url, status, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)'
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
    new Date().toISOString()
  );
  return res.status(202).json({ status: 'pending', requestId: reqId, message: '판매자 승인 대기 중입니다.' });
});

// 새 테넌트+관리자 생성
// 기존 register 경로는 판매자 신규 플로우로 통합 (상위에서 처리)

// 간단한 사용자 CRUD (목업 수준, 비밀번호 해시 미적용)
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
