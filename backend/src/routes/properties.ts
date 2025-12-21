/**
 * Properties Routes
 * Handles saved property endpoints
 */

import { Router } from './index';
import { PropertySaveService } from '../services/properties';
import { parseJsonBody, parseQueryParams, sendJson } from '../utils/http';
import { sendApiError, requireFields, requireQueryParam } from '../utils/errors';
import { SavePropertyRequest, UnsavePropertyRequest } from '../types/api';

export function registerPropertyRoutes(router: Router, propertySaveService: PropertySaveService): void {

  // POST /api/properties/save - Save a property
  router.post('/api/properties/save', async (req, res) => {
    try {
      const body = await parseJsonBody<SavePropertyRequest>(req);
      requireFields(body, ['userId', 'property']);

      const result = await propertySaveService.saveProperty(body.userId, body.property);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error saving property:', error);
      sendApiError(res, error);
    }
  });

  // POST /api/properties/unsave - Unsave a property
  router.post('/api/properties/unsave', async (req, res) => {
    try {
      const body = await parseJsonBody<UnsavePropertyRequest>(req);
      requireFields(body, ['userId', 'propertyId']);

      const result = await propertySaveService.unsaveProperty(body.userId, body.propertyId);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error unsaving property:', error);
      sendApiError(res, error);
    }
  });

  // GET /api/properties/saved?userId=xxx - Get all saved properties
  router.get('/api/properties/saved', async (req, res) => {
    try {
      const params = parseQueryParams(req.url || '');
      const userId = requireQueryParam(params, 'userId');

      const result = await propertySaveService.getSavedProperties(userId);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting saved properties:', error);
      sendApiError(res, error);
    }
  });
}
