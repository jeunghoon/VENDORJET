import { db } from '../../db/client';

type PositionSeed = {
  tier: string;
  title: string;
  sortOrder: number;
  isLocked: number;
};

const DEFAULT_POSITIONS: PositionSeed[] = [
  { tier: 'owner', title: '\ub300\ud45c', sortOrder: 1, isLocked: 1 },
  { tier: 'manager', title: '\uad00\ub9ac\uc790', sortOrder: 2, isLocked: 0 },
  { tier: 'staff', title: '\uc9c1\uc6d0', sortOrder: 3, isLocked: 0 },
  { tier: 'pending', title: '\ubbf8\uc2b9\uc778', sortOrder: 4, isLocked: 1 },
];

export function ensureTenantPositionDefaults(tenantId: string): void {
  const existingRows = db
    .prepare('SELECT tier, title, sort_order AS sortOrder, is_locked AS isLocked FROM tenant_positions WHERE tenant_id = ?')
    .all(tenantId) as { tier?: string; title?: string; sortOrder?: number; isLocked?: number }[];
  const existingMap = new Map(
    existingRows
      .map((row) => [((row.tier ?? '').toLowerCase()), row])
      .filter((entry) => entry[0] !== '') as [string, { tier?: string; title?: string; sortOrder?: number; isLocked?: number }][],
  );
  const insert = db.prepare(
    `INSERT INTO tenant_positions (id, tenant_id, title, created_at, tier, sort_order, is_locked)
     VALUES (?,?,?,?,?,?,?)`,
  );
  const now = new Date().toISOString();
  for (const seed of DEFAULT_POSITIONS) {
    const existing = existingMap.get(seed.tier);
    const corrupted = !!existing?.title && existing.title.includes('?');
    if (existing) {
      if ((existing.isLocked ?? 0) === 1 || corrupted) {
        db.prepare('UPDATE tenant_positions SET title = ?, sort_order = ?, is_locked = ? WHERE tenant_id = ? AND LOWER(tier) = ?')
          .run(seed.title, seed.sortOrder, seed.isLocked, tenantId, seed.tier);
      }
      continue;
    }
    insert.run(
      `pos_${seed.tier}_${Date.now()}_${Math.round(Math.random() * 1000)}`,
      tenantId,
      seed.title,
      now,
      seed.tier,
      seed.sortOrder,
      seed.isLocked,
    );
  }
}

export function assignOwnerDefaultPosition(tenantId: string, ownerUserId: string): void {
  ensureTenantPositionDefaults(tenantId);
  const ownerPosition = db
    .prepare('SELECT id, title FROM tenant_positions WHERE tenant_id = ? AND tier = ? LIMIT 1')
    .get(tenantId, 'owner') as { id?: string; title?: string } | undefined;
  if (!ownerPosition?.id) return;
  db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(
    tenantId,
    ownerUserId,
    ownerPosition.id,
    ownerPosition.title ?? '\ub300\ud45c',
  );
}

export function assignPendingPosition(tenantId: string, memberId: string): void {
  ensureTenantPositionDefaults(tenantId);
  const pendingPosition = db
    .prepare('SELECT id, title FROM tenant_positions WHERE tenant_id = ? AND tier = ? LIMIT 1')
    .get(tenantId, 'pending') as { id?: string; title?: string } | undefined;
  if (!pendingPosition?.id) return;
  db.prepare('INSERT OR REPLACE INTO member_positions (tenant_id, member_id, position_id, title) VALUES (?,?,?,?)').run(
    tenantId,
    memberId,
    pendingPosition.id,
    pendingPosition.title ?? '\ubbf8\uc2b9\uc778',
  );
}
