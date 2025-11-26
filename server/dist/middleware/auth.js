"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const env_1 = require("../config/env");
function authMiddleware(req, res, next) {
    const header = req.headers.authorization;
    if (!header || !header.toLowerCase().startsWith('bearer ')) {
        return res.status(401).json({ error: 'unauthorized' });
    }
    const token = header.slice(7);
    try {
        const payload = jsonwebtoken_1.default.verify(token, env_1.env.jwtSecret);
        if (!payload.tenantId || !payload.userId) {
            return res.status(401).json({ error: 'invalid token' });
        }
        const overrideTenant = req.headers['x-tenant-id'];
        req.user = {
            ...payload,
            tenantId: typeof overrideTenant === 'string' && overrideTenant.length > 0 ? overrideTenant : payload.tenantId,
        };
        next();
    }
    catch (err) {
        return res.status(401).json({ error: 'invalid token' });
    }
}
//# sourceMappingURL=auth.js.map