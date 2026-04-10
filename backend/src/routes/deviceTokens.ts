import { Router } from './index';
import { DeviceTokenController } from '../controllers/deviceTokenController';

export function registerDeviceTokenRoutes(router: Router, controller: DeviceTokenController): void {
  router.put('/api/device-tokens', controller.upsertToken);
  router.delete('/api/device-tokens', controller.removeTokens);
}
