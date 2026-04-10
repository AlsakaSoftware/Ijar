import * as http from 'http';
import { authenticateRequest } from '../middleware/auth';
import { sendApiError } from '../utils/errors';

export type RouteHandler = (
  req: http.IncomingMessage,
  res: http.ServerResponse,
  params: Record<string, string>,
  userId: string
) => Promise<void>;

interface Route {
  method: string;
  pattern: RegExp;
  paramNames: string[];
  handler: RouteHandler;
}

export class Router {
  private routes: Route[] = [];

  register(method: string, pattern: string, handler: RouteHandler): void {
    const paramNames: string[] = [];

    const regexPattern = pattern.replace(/:([^/]+)/g, (_, paramName) => {
      paramNames.push(paramName);
      return '([^/]+)';
    });

    this.routes.push({
      method: method.toUpperCase(),
      pattern: new RegExp(`^${regexPattern}$`),
      paramNames,
      handler,
    });
  }

  get(pattern: string, handler: RouteHandler): void {
    this.register('GET', pattern, handler);
  }

  post(pattern: string, handler: RouteHandler): void {
    this.register('POST', pattern, handler);
  }

  put(pattern: string, handler: RouteHandler): void {
    this.register('PUT', pattern, handler);
  }

  patch(pattern: string, handler: RouteHandler): void {
    this.register('PATCH', pattern, handler);
  }

  delete(pattern: string, handler: RouteHandler): void {
    this.register('DELETE', pattern, handler);
  }

  match(method: string, url: string): { handler: RouteHandler; params: Record<string, string> } | null {
    const path = url.split('?')[0];

    for (const route of this.routes) {
      if (route.method !== method.toUpperCase()) continue;

      const match = path.match(route.pattern);
      if (match) {
        const params: Record<string, string> = {};
        route.paramNames.forEach((name, i) => {
          params[name] = match[i + 1];
        });
        return { handler: route.handler, params };
      }
    }

    return null;
  }

  async handle(req: http.IncomingMessage, res: http.ServerResponse): Promise<boolean> {
    const result = this.match(req.method || 'GET', req.url || '/');

    if (!result) return false;

    try {
      const userId = authenticateRequest(req);
      await result.handler(req, res, result.params, userId);
    } catch (error) {
      sendApiError(res, error);
    }

    return true;
  }
}
