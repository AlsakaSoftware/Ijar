/**
 * Groups Routes
 * Handles property group endpoints
 */

import { Router } from './index';
import { GroupService } from '../services/groups';
import { parseJsonBody, parseQueryParams, sendJson, sendError } from '../utils/http';

export function registerGroupRoutes(router: Router, groupService: GroupService): void {

  // GET /api/groups?userId=xxx - Get all groups for user
  router.get('/api/groups', async (req, res) => {
    try {
      const params = parseQueryParams(req.url || '');

      if (!params.userId) {
        sendError(res, 'userId query param is required', 400);
        return;
      }

      const result = await groupService.getGroups(params.userId);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting groups:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // POST /api/groups - Create a group
  router.post('/api/groups', async (req, res) => {
    try {
      const body = await parseJsonBody<{ userId: string; name: string }>(req);

      if (!body.userId || !body.name) {
        sendError(res, 'userId and name are required', 400);
        return;
      }

      const result = await groupService.createGroup(body.userId, body.name);
      sendJson(res, result, result.group ? 201 : 400);
    } catch (error) {
      console.error('Error creating group:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // DELETE /api/groups/:id - Delete a group
  router.delete('/api/groups/:id', async (req, res, params) => {
    try {
      const result = await groupService.deleteGroup(params.id);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error deleting group:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // PATCH /api/groups/:id - Rename a group
  router.patch('/api/groups/:id', async (req, res, params) => {
    try {
      const body = await parseJsonBody<{ name: string }>(req);

      if (!body.name) {
        sendError(res, 'name is required', 400);
        return;
      }

      const result = await groupService.renameGroup(params.id, body.name);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error renaming group:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // GET /api/groups/:id/properties - Get properties in a group
  router.get('/api/groups/:id/properties', async (req, res, params) => {
    try {
      const result = await groupService.getPropertiesInGroup(params.id);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting group properties:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // POST /api/groups/:id/properties - Add property to group
  router.post('/api/groups/:id/properties', async (req, res, params) => {
    try {
      const body = await parseJsonBody<{ propertyId: string }>(req);

      if (!body.propertyId) {
        sendError(res, 'propertyId is required', 400);
        return;
      }

      const result = await groupService.addPropertyToGroup(params.id, body.propertyId);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error adding property to group:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // DELETE /api/groups/:id/properties/:propertyId - Remove property from group
  router.delete('/api/groups/:id/properties/:propertyId', async (req, res, params) => {
    try {
      const result = await groupService.removePropertyFromGroup(params.id, params.propertyId);
      sendJson(res, result, result.success ? 200 : 400);
    } catch (error) {
      console.error('Error removing property from group:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // GET /api/properties/:id/groups?userId=xxx - Get groups for a property
  router.get('/api/properties/:id/groups', async (req, res, params) => {
    try {
      const queryParams = parseQueryParams(req.url || '');

      if (!queryParams.userId) {
        sendError(res, 'userId query param is required', 400);
        return;
      }

      const result = await groupService.getGroupsForProperty(queryParams.userId, params.id);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting groups for property:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });
}
