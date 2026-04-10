import * as http from 'http';
import jwt from 'jsonwebtoken';
import { unauthorized } from '../utils/errors';

const JWT_SECRET = process.env.SUPABASE_JWT_SECRET;

export function authenticateRequest(req: http.IncomingMessage): string {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    throw unauthorized('Missing authorization header');
  }

  if (!authHeader.startsWith('Bearer ')) {
    throw unauthorized('Invalid authorization header format');
  }

  const token = authHeader.slice(7);

  if (!JWT_SECRET) {
    throw new Error('SUPABASE_JWT_SECRET environment variable is not set');
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] }) as jwt.JwtPayload;

    if (!payload.sub) {
      throw unauthorized('Token missing subject claim');
    }

    return payload.sub;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw unauthorized('Token expired');
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw unauthorized('Invalid token');
    }
    throw error;
  }
}
