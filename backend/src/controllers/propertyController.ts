import * as http from 'http';
import { PropertyService } from '../services/propertyService';
import { SavePropertyBodySchema, UnsavePropertyBodySchema, TrackActionBodySchema } from '../schemas/propertySchemas';
import { parseJsonBody, sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';
import { validateBody } from '../utils/validate';

export class PropertyController {
  constructor(private propertyService: PropertyService) {}

  saveProperty = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(SavePropertyBodySchema, rawBody);
      const result = await this.propertyService.saveProperty(userId, body.property);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  unsaveProperty = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(UnsavePropertyBodySchema, rawBody);
      const result = await this.propertyService.unsaveProperty(userId, body.propertyId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  getSavedProperties = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const properties = await this.propertyService.getSavedProperties(userId);
      sendJson(res, properties);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  getFeed = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const properties = await this.propertyService.getFeedProperties(userId);
      sendJson(res, properties);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  trackAction = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(TrackActionBodySchema, rawBody);
      const result = await this.propertyService.trackAction(userId, params.id, body.action);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
