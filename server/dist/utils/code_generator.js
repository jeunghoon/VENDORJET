"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateOrderCode = generateOrderCode;
const date_fns_1 = require("date-fns");
const client_1 = require("../db/client");
// DB 기반으로 날짜별 연속 번호를 관리해 주문번호를 전역 고유하게 생성
function generateOrderCode(date = new Date()) {
    const datePart = (0, date_fns_1.format)(date, 'yyMMdd');
    const nextSeq = client_1.db.transaction((targetDate) => {
        const current = client_1.db
            .prepare('SELECT last_seq FROM order_code_sequences WHERE date = ?')
            .get(targetDate);
        const next = (current?.last_seq ?? 0) + 1;
        client_1.db.prepare(`INSERT INTO order_code_sequences (date, last_seq) VALUES (?, ?)
       ON CONFLICT(date) DO UPDATE SET last_seq = excluded.last_seq`).run(targetDate, next);
        return next;
    })(datePart);
    return `PO${datePart}${`${nextSeq}`.padStart(4, '0')}`;
}
//# sourceMappingURL=code_generator.js.map