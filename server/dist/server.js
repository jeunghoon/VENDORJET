"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const morgan_1 = __importDefault(require("morgan"));
const env_1 = require("./config/env");
const controller_1 = __importDefault(require("./modules/auth/controller"));
const controller_2 = require("./modules/products/controller");
const controller_3 = require("./modules/customers/controller");
const controller_4 = require("./modules/orders/controller");
const controller_5 = require("./modules/buyer/controller");
const controller_6 = require("./modules/admin/controller");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use((0, morgan_1.default)('dev'));
// 헬스 체크
app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
});
app.use('/auth', controller_1.default);
app.use('/products', controller_2.productsController);
app.use('/customers', controller_3.customersController);
app.use('/orders', controller_4.ordersController);
app.use('/buyer', controller_5.buyerController);
app.use('/admin', controller_6.adminController);
app.listen(env_1.env.port, () => {
    // eslint-disable-next-line no-console
    console.log(`Server listening on http://localhost:${env_1.env.port}`);
});
//# sourceMappingURL=server.js.map