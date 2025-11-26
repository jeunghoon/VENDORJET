import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import authController from './modules/auth/controller';
import { productsController } from './modules/products/controller';
import { customersController } from './modules/customers/controller';
import { ordersController } from './modules/orders/controller';
import { buyerController } from './modules/buyer/controller';
import { adminController } from './modules/admin/controller';

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// 헬스 체크
app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', authController);
app.use('/products', productsController);
app.use('/customers', customersController);
app.use('/orders', ordersController);
app.use('/buyer', buyerController);
app.use('/admin', adminController);

app.listen(env.port, () => {
  // eslint-disable-next-line no-console
  console.log(`Server listening on http://localhost:${env.port}`);
});
