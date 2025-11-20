import { NextFunction, Request, Response } from 'express';
export type AuthUser = {
    userId: string;
    tenantId: string;
    role: string;
    email?: string;
};
declare module 'express-serve-static-core' {
    interface Request {
        user?: AuthUser;
    }
}
export declare function authMiddleware(req: Request, res: Response, next: NextFunction): Response<any, Record<string, any>> | undefined;
//# sourceMappingURL=auth.d.ts.map