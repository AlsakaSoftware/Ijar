import { z } from 'zod';
import { ApiError, ErrorCodes } from './errors';

export function validateBody<T>(schema: z.ZodSchema<T>, body: unknown): T {
  const result = schema.safeParse(body);
  if (!result.success) {
    const message = result.error.issues
      .map(issue => `${issue.path.join('.')}: ${issue.message}`)
      .join(', ');
    throw new ApiError(ErrorCodes.INVALID_REQUEST_BODY, message, 400);
  }
  return result.data;
}
