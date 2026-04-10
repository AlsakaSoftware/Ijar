import * as http from 'http';
import { QueryService } from '../services/queryService';
import { CreateQueryBodySchema, UpdateQueryBodySchema } from '../schemas/querySchemas';
import { parseJsonBody, sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';
import { validateBody } from '../utils/validate';

export class QueryController {
  constructor(private queryService: QueryService) {}

  getQueries = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const queries = await this.queryService.getQueries(userId);
      sendJson(res, queries);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  createQuery = async (req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(CreateQueryBodySchema, rawBody);
      const query = await this.queryService.createQuery(userId, body);
      sendJson(res, query);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  updateQuery = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(UpdateQueryBodySchema, rawBody);
      const result = await this.queryService.updateQuery(userId, params.id, body);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  deleteQuery = async (_req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const result = await this.queryService.deleteQuery(userId, params.id);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
