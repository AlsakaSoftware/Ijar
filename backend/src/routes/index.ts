/**
 * Simple Router
 * Handles route registration and matching with path params
 */

import * as http from 'http';

export type RouteHandler = (
  req: http.IncomingMessage,
  res: http.ServerResponse,
  params: Record<string, string>
) => Promise<void>;

interface Route {
  method: string;
  pattern: RegExp;
  paramNames: string[];
  handler: RouteHandler;
}

export class Router {
  private routes: Route[] = [];

  /**
   * Register a route
   * Pattern can include :param placeholders like /api/groups/:id
   */
  register(method: string, pattern: string, handler: RouteHandler): void {
    const paramNames: string[] = [];

    // Convert /api/groups/:id to regex /api/groups/([^/]+)
    const regexPattern = pattern.replace(/:([^/]+)/g, (_, paramName) => {
      paramNames.push(paramName);
      return '([^/]+)';
    });

    this.routes.push({
      method: method.toUpperCase(),
      pattern: new RegExp(`^${regexPattern}$`),
      paramNames,
      handler
    });
  }

  // Convenience methods
  get(pattern: string, handler: RouteHandler): void {
    this.register('GET', pattern, handler);
  }

  post(pattern: string, handler: RouteHandler): void {
    this.register('POST', pattern, handler);
  }

  patch(pattern: string, handler: RouteHandler): void {
    this.register('PATCH', pattern, handler);
  }

  delete(pattern: string, handler: RouteHandler): void {
    this.register('DELETE', pattern, handler);
  }

  /**
   * Match a request to a route
   * Returns handler and extracted params, or null if no match
   */
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

  /**
   * Handle a request
   */
  async handle(req: http.IncomingMessage, res: http.ServerResponse): Promise<boolean> {
    const result = this.match(req.method || 'GET', req.url || '/');

    if (result) {
      await result.handler(req, res, result.params);
      return true;
    }

    return false;
  }
}
