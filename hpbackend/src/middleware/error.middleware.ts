// ============================================================
// HungerPoint — Global Error Handler Middleware
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response';

export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: AppError | Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Unexpected errors are logged in every environment — production failures
  // (e.g. image uploads on the host) were invisible when only dev logged them.
  if (process.env.NODE_ENV === 'development') {
    console.error('❌ Error:', err);
  } else if (!(err instanceof AppError)) {
    console.error(`❌ ${req.method} ${req.originalUrl}:`, err);
  }

  // Upload errors (multer)
  if (err.name === 'MulterError') {
    const code = (err as { code?: string }).code;
    if (code === 'LIMIT_FILE_SIZE') {
      sendError(res, 'This picture is too large. Please choose one under 10 MB.', 413);
    } else {
      sendError(res, `Upload failed: ${err.message}`, 400);
    }
    return;
  }

  // MySQL refused a packet bigger than its max_allowed_packet setting (big images).
  if (/max_allowed_packet|packet.*(too large|bigger)/i.test(err.message || '')) {
    sendError(res, 'This picture is too large for the database server. Please use a smaller picture.', 413);
    return;
  }

  // Prisma errors
  if ('code' in err) {
    const prismaError = err as { code: string; meta?: { target?: string[] | string } };

    // Table missing: the schema sync at startup did not run or failed on the host.
    if (prismaError.code === 'P2021') {
      sendError(res, 'The database is missing a table. Restart the backend so it can update the database, then try again.', 500);
      return;
    }

    if (prismaError.code === 'P2002') {
      const target = prismaError.meta?.target;
      const field = (Array.isArray(target) ? target.join(', ') : target || '').toString();
      // Plain wording for the fields people actually collide on.
      const friendly = /phone/i.test(field)
        ? 'This phone number is already used by another account.'
        : /email/i.test(field)
          ? 'This email is already used by another account.'
          : `Duplicate value for: ${field || 'field'}`;
      sendError(res, friendly, 409);
      return;
    }

    if (prismaError.code === 'P2025') {
      sendError(res, 'Record not found', 404);
      return;
    }
  }

  // Known operational errors
  if (err instanceof AppError) {
    sendError(res, err.message, err.statusCode);
    return;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    sendError(res, 'Invalid token', 401);
    return;
  }

  if (err.name === 'TokenExpiredError') {
    sendError(res, 'Token expired', 401);
    return;
  }

  // Default 500
  sendError(res, 'Internal server error', 500);
};
