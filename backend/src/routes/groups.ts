/**
 * Groups Routes
 * Handles property group endpoints
 */

import { Router } from './index';
import { GroupService } from '../services/groups';
import { parseJsonBody, parseQueryParams, sendJson } from '../utils/http';
import { sendApiError, requireFields, requireQueryParam } from '../utils/errors';
import { CreateGroupRequest, RenameGroupRequest, AddPropertyToGroupRequest } from '../types/api';

export function registerGroupRoutes(router: Router, groupService: GroupService): void {

  // GET /api/groups?userId=xxx - Get all groups for user
  router.get('/api/groups', async (req, res) => {
    try {
      const params = parseQueryParams(req.url || '');
      const userId = requireQueryParam(params, 'userId');

      const result = await groupService.getGroups(userId);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting groups:', error);
      sendApiError(res, error);
    }
  });

  // POST /api/groups - Create a group
  router.post('/api/groups', async (req, res) => {
    try {
      const body = await parseJsonBody<CreateGroupRequest>(req);
      requireFields(body, ['userId', 'name']);

      const group = await groupService.createGroup(body.userId, body.name);
      sendJson(res, { group }, group ? 201 : 400);
    } catch (error) {
      console.error('Error creating group:', error);
      sendApiError(res, error);
    }
  });

  // DELETE /api/groups/:id - Delete a group
  router.delete('/api/groups/:id', async (req, res, params) => {
    try {
      const success = await groupService.deleteGroup(params.id);
      sendJson(res, { success });
    } catch (error) {
      console.error('Error deleting group:', error);
      sendApiError(res, error);
    }
  });

  // PATCH /api/groups/:id - Rename a group
  router.patch('/api/groups/:id', async (req, res, params) => {
    try {
      const body = await parseJsonBody<RenameGroupRequest>(req);
      requireFields(body, ['name']);

      const success = await groupService.renameGroup(params.id, body.name);
      sendJson(res, { success });
    } catch (error) {
      console.error('Error renaming group:', error);
      sendApiError(res, error);
    }
  });

  // GET /api/groups/:id/properties - Get properties in a group
  router.get('/api/groups/:id/properties', async (req, res, params) => {
    try {
      const result = await groupService.getPropertiesInGroup(params.id);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting group properties:', error);
      sendApiError(res, error);
    }
  });

  // POST /api/groups/:id/properties - Add property to group
  router.post('/api/groups/:id/properties', async (req, res, params) => {
    try {
      const body = await parseJsonBody<AddPropertyToGroupRequest>(req);
      requireFields(body, ['propertyId']);

      const success = await groupService.addPropertyToGroup(params.id, body.propertyId);
      sendJson(res, { success });
    } catch (error) {
      console.error('Error adding property to group:', error);
      sendApiError(res, error);
    }
  });

  // DELETE /api/groups/:id/properties/:propertyId - Remove property from group
  router.delete('/api/groups/:id/properties/:propertyId', async (req, res, params) => {
    try {
      const success = await groupService.removePropertyFromGroup(params.id, params.propertyId);
      sendJson(res, { success });
    } catch (error) {
      console.error('Error removing property from group:', error);
      sendApiError(res, error);
    }
  });

  // GET /api/properties/:id/groups?userId=xxx - Get groups for a property
  router.get('/api/properties/:id/groups', async (req, res, params) => {
    try {
      const queryParams = parseQueryParams(req.url || '');
      const userId = requireQueryParam(queryParams, 'userId');

      const result = await groupService.getGroupsForProperty(userId, params.id);
      sendJson(res, result);
    } catch (error) {
      console.error('Error getting groups for property:', error);
      sendApiError(res, error);
    }
  });
}
