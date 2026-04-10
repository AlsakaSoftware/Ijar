import { ApiError } from './utils/errors';

export function toErrorResponse(error: unknown, fallback: string) {
  if (error instanceof ApiError) {
    return { status: error.status, message: error.message };
  }

  console.error(fallback, error);
  return { status: 500, message: fallback };
}
