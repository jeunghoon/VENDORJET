import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

// .env 로드
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const schema = z.object({
  PORT: z
    .preprocess((v) => Number(v ?? '4110'), z.number().int().positive())
    .default(4110),
  JWT_SECRET: z.string().min(4).default('local-vendorjet'),
  ADMIN_EMAIL: z.string().email().default('alex@vendorjet.com'),
  ADMIN_PASSWORD: z.string().min(1).default('welcome1'),
});

const parsed = schema.parse(process.env);

export const env = {
  port: parsed.PORT,
  jwtSecret: parsed.JWT_SECRET,
  adminEmail: parsed.ADMIN_EMAIL,
  adminPassword: parsed.ADMIN_PASSWORD,
};
