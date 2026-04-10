import { MonitorRepository } from '../repositories/monitorRepository';

export class MonitorService {
  constructor(private monitorRepo: MonitorRepository) {}

  async refreshPropertiesForUser(userId: string): Promise<{ success: boolean }> {
    await this.monitorRepo.triggerWorkflow(userId);
    return { success: true };
  }
}
