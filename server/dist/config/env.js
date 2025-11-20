"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
const zod_1 = require("zod");
// .env 로드
dotenv_1.default.config({ path: path_1.default.join(__dirname, '..', '.env') });
const schema = zod_1.z.object({
    PORT: zod_1.z
        .preprocess((v) => Number(v ?? '4110'), zod_1.z.number().int().positive())
        .default(4110),
    JWT_SECRET: zod_1.z.string().min(4).default('local-vendorjet'),
    ADMIN_EMAIL: zod_1.z.string().email().default('alex@vendorjet.com'),
    ADMIN_PASSWORD: zod_1.z.string().min(1).default('welcome1'),
});
const parsed = schema.parse(process.env);
exports.env = {
    port: parsed.PORT,
    jwtSecret: parsed.JWT_SECRET,
    adminEmail: parsed.ADMIN_EMAIL,
    adminPassword: parsed.ADMIN_PASSWORD,
};
//# sourceMappingURL=env.js.map