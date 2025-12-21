/**
 * HTTP Utilities
 * Common helpers for request/response handling
 */

import * as http from 'http';

/**
 * Parse request body as string
 */
export function parseBody(req: http.IncomingMessage): Promise<string> {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => body += chunk.toString());
    req.on('end', () => resolve(body));
  });
}

/**
 * Parse JSON body
 */
export async function parseJsonBody<T>(req: http.IncomingMessage): Promise<T> {
  const body = await parseBody(req);
  return JSON.parse(body) as T;
}

/**
 * Parse query params from URL
 */
export function parseQueryParams(url: string): Record<string, string> {
  const params: Record<string, string> = {};
  const queryStart = url.indexOf('?');
  if (queryStart === -1) return params;

  const queryString = url.substring(queryStart + 1);
  for (const pair of queryString.split('&')) {
    const [key, value] = pair.split('=');
    if (key && value) {
      params[decodeURIComponent(key)] = decodeURIComponent(value);
    }
  }
  return params;
}

/**
 * Send JSON response
 */
export function sendJson(res: http.ServerResponse, data: unknown, status = 200): void {
  res.writeHead(status);
  res.end(JSON.stringify(data));
}

/**
 * Send error response
 */
export function sendError(res: http.ServerResponse, message: string, status = 500): void {
  res.writeHead(status);
  res.end(JSON.stringify({ error: message }));
}
