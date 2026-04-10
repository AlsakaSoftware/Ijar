import * as http from 'http';
import { GroupService } from '../services/groupService';
import { CreateGroupBodySchema, RenameGroupBodySchema, AddPropertyToGroupBodySchema } from '../schemas/groupSchemas';
import { parseJsonBody, sendJson, parseQueryParams } from '../utils/http';
import { sendApiError } from '../utils/errors';
import { validateBody } from '../utils/validate';

export class GroupController {
  constructor(private groupService: GroupService) {}

  getGroups = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const groups = await this.groupService.getGroups(userId);
      sendJson(res, groups);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  createGroup = async (req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(CreateGroupBodySchema, rawBody);
      const group = await this.groupService.createGroup(userId, body.name);
      sendJson(res, { group });
    } catch (error) {
      sendApiError(res, error);
    }
  };

  deleteGroup = async (_req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const result = await this.groupService.deleteGroup(params.id);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  renameGroup = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(RenameGroupBodySchema, rawBody);
      const result = await this.groupService.renameGroup(params.id, body.name);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  getGroupProperties = async (_req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const properties = await this.groupService.getGroupProperties(params.id);
      sendJson(res, properties);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  addPropertyToGroup = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(AddPropertyToGroupBodySchema, rawBody);
      const result = await this.groupService.addPropertyToGroup(params.id, body.propertyId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  removePropertyFromGroup = async (_req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, _userId: string): Promise<void> => {
    try {
      const result = await this.groupService.removePropertyFromGroup(params.id, params.propertyId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  getGroupsForProperty = async (req: http.IncomingMessage, res: http.ServerResponse, params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const groupIds = await this.groupService.getGroupsForProperty(userId, params.id);
      sendJson(res, groupIds);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
