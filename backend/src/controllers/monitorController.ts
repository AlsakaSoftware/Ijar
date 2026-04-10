import * as http from 'http';
import { MonitorService } from '../services/monitorService';
import { sendJson } from '../utils/http';
import { sendApiError } from '../utils/errors';

export class MonitorController {
  constructor(private monitorService: MonitorService) {}

  refreshProperties = async (_req: http.IncomingMessage, res: http.ServerResponse, _params: Record<string, string>, userId: string): Promise<void> => {
    try {
      const result = await this.monitorService.refreshPropertiesForUser(userId);
      sendJson(res, result);
    } catch (error) {
      sendApiError(res, error);
    }
  };
}
