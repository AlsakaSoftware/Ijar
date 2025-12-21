/**
 * Error Utilities
 * Structured error handling for API
 */

import * as http from 'http';

// =============================================================================
// Error Codes
// =============================================================================

export const ErrorCodes = {
  // Validation errors (400)
  MISSING_REQUIRED_FIELD: 'MISSING_REQUIRED_FIELD',
  INVALID_PROPERTY_ID: 'INVALID_PROPERTY_ID',
  INVALID_REQUEST_BODY: 'INVALID_REQUEST_BODY',

  // Auth errors (401)
  UNAUTHORIZED: 'UNAUTHORIZED',

  // Not found errors (404)
  PROPERTY_NOT_FOUND: 'PROPERTY_NOT_FOUND',
  GROUP_NOT_FOUND: 'GROUP_NOT_FOUND',

  // Server errors (500)
  DATABASE_ERROR: 'DATABASE_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type ErrorCode = typeof ErrorCodes[keyof typeof ErrorCodes];

// =============================================================================
// API Error Class
// =============================================================================

export class ApiError extends Error {
  constructor(
    public code: ErrorCode,
    message: string,
    public status: number = 500
  ) {
    super(message);
    this.name = 'ApiError';
  }

  toJSON() {
    return {
      error: this.message,
      code: this.code,
    };
  }
}

// =============================================================================
// Error Factory Functions
// =============================================================================

export function badRequest(code: ErrorCode, message: string): ApiError {
  return new ApiError(code, message, 400);
}

export function notFound(code: ErrorCode, message: string): ApiError {
  return new ApiError(code, message, 404);
}

export function unauthorized(message = 'Unauthorized'): ApiError {
  return new ApiError(ErrorCodes.UNAUTHORIZED, message, 401);
}

export function serverError(message = 'Internal server error'): ApiError {
  return new ApiError(ErrorCodes.INTERNAL_ERROR, message, 500);
}

export function databaseError(message: string): ApiError {
  return new ApiError(ErrorCodes.DATABASE_ERROR, message, 500);
}

// =============================================================================
// Error Response Helper
// =============================================================================

export function sendApiError(res: http.ServerResponse, error: unknown): void {
  if (error instanceof ApiError) {
    res.writeHead(error.status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(error.toJSON()));
  } else {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      error: message,
      code: ErrorCodes.INTERNAL_ERROR
    }));
  }
}

// =============================================================================
// Validation Helpers
// =============================================================================

export function requireFields<T>(
  body: T,
  fields: (keyof T)[]
): void {
  for (const field of fields) {
    const value = body[field];
    if (value === undefined || value === null || value === '') {
      throw badRequest(
        ErrorCodes.MISSING_REQUIRED_FIELD,
        `${String(field)} is required`
      );
    }
  }
}

export function requireQueryParam(
  params: Record<string, string>,
  name: string
): string {
  const value = params[name];
  if (!value) {
    throw badRequest(
      ErrorCodes.MISSING_REQUIRED_FIELD,
      `${name} query param is required`
    );
  }
  return value;
}
