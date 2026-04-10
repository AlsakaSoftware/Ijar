import * as http from 'http';
import { SearchService } from '../services/searchService';
import { SearchBodySchema, OnboardingSearchBodySchema } from '../schemas/searchSchemas';
import { parseJsonBody, sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';
import { validateBody } from '../utils/validate';

export class SearchController {
  constructor(private searchService: SearchService) {}

  search = async (req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(SearchBodySchema, rawBody);
      const result = await this.searchService.searchProperties(body);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  onboardingSearch = async (req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(OnboardingSearchBodySchema, rawBody);
      const result = await this.searchService.onboardingSearch(body);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  getPropertyDetails = async (_req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const result = await this.searchService.getPropertyDetails(params.id);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
