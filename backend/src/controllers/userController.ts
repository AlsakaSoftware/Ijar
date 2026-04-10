import * as http from 'http';
import { UserService } from '../services/userService';
import { sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';

export class UserController {
  constructor(private userService: UserService) {}

  getUser = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const user = await this.userService.getUser(userId);
      sendJson(res, user);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  upsertUser = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const user = await this.userService.upsertUser(userId);
      sendJson(res, user);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  markOnboardingComplete = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const result = await this.userService.markOnboardingComplete(userId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
