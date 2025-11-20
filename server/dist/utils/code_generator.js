"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateOrderCode = generateOrderCode;
const date_fns_1 = require("date-fns");
// 날짜별 시퀀스 캐싱
const sequenceByDate = new Map();
function generateOrderCode(date = new Date()) {
    const datePart = (0, date_fns_1.format)(date, 'yyMMdd');
    const current = sequenceByDate.get(datePart) ?? 0;
    const next = current + 1;
    sequenceByDate.set(datePart, next);
    return `PO${datePart}${`${next}`.padStart(4, '0')}`;
}
//# sourceMappingURL=code_generator.js.map