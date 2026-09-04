// ============================================================
// HungerPoint — 404 Not Found Middleware
// ============================================================

import { Request, Response } from 'express';
import { sendNotFound } from '../utils/response';

export const notFound = (req: Request, res: Response): void => {
  sendNotFound(res, `Route not found: ${req.method} ${req.originalUrl}`);
};
