import { DeviceTokenService } from '../services/deviceTokenService';
import { UpsertTokenRequest } from '../schemas';

export class DeviceTokenController {
  constructor(private tokenService: DeviceTokenService = new DeviceTokenService()) {}

  async upsertToken(userId: string, data: UpsertTokenRequest) {
    return this.tokenService.upsertToken(userId, data.token, data.deviceType);
  }

  async removeTokens(userId: string) {
    return this.tokenService.removeTokens(userId);
  }
}
