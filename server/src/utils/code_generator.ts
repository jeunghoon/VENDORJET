import { format } from 'date-fns';

// 날짜별 시퀀스 캐싱
const sequenceByDate = new Map<string, number>();

export function generateOrderCode(date: Date = new Date()): string {
  const datePart = format(date, 'yyMMdd');
  const current = sequenceByDate.get(datePart) ?? 0;
  const next = current + 1;
  sequenceByDate.set(datePart, next);
  return `PO${datePart}${`${next}`.padStart(4, '0')}`;
}
