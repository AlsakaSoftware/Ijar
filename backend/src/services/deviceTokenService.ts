import { DeviceTokenRepository } from '../repositories/deviceTokenRepository';

export class DeviceTokenService {
  constructor(private tokenRepo: DeviceTokenRepository = new DeviceTokenRepository()) {}

  async upsertToken(userId: string, token: string, deviceType: string): Promise<{ success: boolean }> {
    await this.tokenRepo.upsert(userId, token, deviceType);
    return { success: true };
  }

  async removeTokens(userId: string): Promise<{ success: boolean }> {
    await this.tokenRepo.removeForUser(userId);
    return { success: true };
  }
}
