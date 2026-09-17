// ============================================================
// HungerPoint Backend — Express App
// ============================================================

import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import 'dotenv/config';

// Route imports
import authRoutes from './modules/auth/auth.routes';
import userRoutes from './modules/users/user.routes';
import customerRoutes from './modules/customers/customer.routes';
import branchRoutes from './modules/branches/branch.routes';
import categoryRoutes from './modules/categories/category.routes';
import productRoutes from './modules/products/product.routes';
import cartRoutes from './modules/cart/cart.routes';
import orderRoutes from './modules/orders/order.routes';
import paymentRoutes from './modules/payments/payment.routes';
import kitchenRoutes from './modules/kitchen/kitchen.routes';
import riderRoutes from './modules/riders/rider.routes';
import deliveryRoutes from './modules/delivery/delivery.routes';
import inventoryRoutes from './modules/inventory/inventory.routes';
import promotionRoutes from './modules/promotions/promotion.routes';
import couponRoutes from './modules/coupons/coupon.routes';
import reviewRoutes from './modules/reviews/review.routes';
import favoriteRoutes from './modules/favorites/favorite.routes';
import settingRoutes from './modules/settings/setting.routes';
import loyaltyRoutes from './modules/loyalty/loyalty.routes';
import notificationRoutes from './modules/notifications/notification.routes';
import reportRoutes from './modules/reports/report.routes';

// Middleware imports
import { errorHandler } from './middleware/error.middleware';
import { notFound } from './middleware/notFound.middleware';
import path from 'path';
import fs from 'fs';
import multer from 'multer';

const app: Application = express();

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// ─── Security ────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: false }));

// ─── Static Uploads ──────────────────────────────────────────
app.use('/uploads', express.static(uploadDir));

// ─── CORS ────────────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000').split(',');
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || process.env.NODE_ENV === 'development' || allowedOrigins.includes(origin) || origin.startsWith('http://localhost')) {
      callback(null, true);
    } else {
      callback(new Error(`CORS blocked: ${origin}`));
    }
  },
  credentials: true,
}));

// ─── Rate Limiting ───────────────────────────────────────────
const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api', limiter);

// ─── Body Parsing ────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// express.json()/urlencoded() leave req.body as `undefined` (not `{}`) when a
// request has no body at all — e.g. a PATCH action with no payload. Normalize
// it here so every controller can safely destructure req.body without a crash.
app.use((req: Request, _res: Response, next: NextFunction) => {
  if (req.body === undefined) req.body = {};
  next();
});

// ─── Logging ─────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ─── Health Check ────────────────────────────────────────────
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    success: true,
    message: 'HungerPoint API is running',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
    database: 'hungerpointdb',
  });
});

// ─── API Routes ──────────────────────────────────────────────
const API = '/api/v1';

app.use(`${API}/auth`,          authRoutes);
app.use(`${API}/users`,         userRoutes);
app.use(`${API}/customers`,     customerRoutes);
app.use(`${API}/branches`,      branchRoutes);
app.use(`${API}/categories`,    categoryRoutes);
app.use(`${API}/products`,      productRoutes);
app.use(`${API}/cart`,          cartRoutes);
app.use(`${API}/orders`,        orderRoutes);
app.use(`${API}/payments`,      paymentRoutes);
app.use(`${API}/kitchen`,       kitchenRoutes);
app.use(`${API}/riders`,        riderRoutes);
app.use(`${API}/deliveries`,    deliveryRoutes);
app.use(`${API}/inventory`,     inventoryRoutes);
app.use(`${API}/promotions`,    promotionRoutes);
app.use(`${API}/coupons`,       couponRoutes);
app.use(`${API}/reviews`,       reviewRoutes);
app.use(`${API}/favorites`,     favoriteRoutes);
app.use(`${API}/settings`,      settingRoutes);
app.use(`${API}/loyalty`,       loyaltyRoutes);
app.use(`${API}/notifications`, notificationRoutes);
app.use(`${API}/reports`,       reportRoutes);

// ─── Local File Upload Route ──────────────────────────────────
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'img-' + uniqueSuffix + ext);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

app.post(`${API}/upload`, upload.single('image'), (req: Request, res: Response) => {
  if (!req.file) {
    res.status(400).json({ success: false, message: 'No file uploaded' });
    return;
  }
  const host = req.get('host') || 'localhost:5000';
  const protocol = req.protocol || 'http';
  const fileUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
  res.json({
    success: true,
    message: 'File uploaded successfully',
    data: {
      url: fileUrl,
      filename: req.file.filename,
      size: req.file.size,
    },
  });
});

// ─── Error Handlers ──────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

export default app;
