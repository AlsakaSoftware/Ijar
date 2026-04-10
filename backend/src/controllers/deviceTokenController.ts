import * as http from 'http';
import { DeviceTokenService } from '../services/deviceTokenService';
import { UpsertTokenBodySchema } from '../schemas/deviceTokenSchemas';
import { parseJsonBody, sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';
import { validateBody } from '../utils/validate';

export class DeviceTokenController {
  constructor(private tokenService: DeviceTokenService) {}

  upsertToken = async (req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const rawBody = await parseJsonBody(req);
      const body = validateBody(UpsertTokenBodySchema, rawBody);
      const result = await this.tokenService.upsertToken(userId, body.token, body.deviceType);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };

  removeTokens = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const result = await this.tokenService.removeTokens(userId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
