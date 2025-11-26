import { format } from 'date-fns';
import { db } from '../db/client';

// DB 기반으로 날짜별 연속 번호를 관리해 주문번호를 전역 고유하게 생성
export function generateOrderCode(date: Date = new Date()): string {
  const datePart = format(date, 'yyMMdd');
  const nextSeq = db.transaction((targetDate: string) => {
    const current = db
      .prepare('SELECT last_seq FROM order_code_sequences WHERE date = ?')
      .get(targetDate) as { last_seq?: number } | undefined;
    const next = (current?.last_seq ?? 0) + 1;
    db.prepare(
      `INSERT INTO order_code_sequences (date, last_seq) VALUES (?, ?)
       ON CONFLICT(date) DO UPDATE SET last_seq = excluded.last_seq`
    ).run(targetDate, next);
    return next;
  })(datePart);

  return `PO${datePart}${`${nextSeq}`.padStart(4, '0')}`;
}
