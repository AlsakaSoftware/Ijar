import { MonitorService } from '../services/monitorService';

export class MonitorController {
  constructor(private monitorService: MonitorService = new MonitorService()) {}

  async refreshProperties(userId: string) {
    return this.monitorService.refreshPropertiesForUser(userId);
  }
}
