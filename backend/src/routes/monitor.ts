import { Router } from './index';
import { MonitorController } from '../controllers/monitorController';

export function registerMonitorRoutes(router: Router, controller: MonitorController): void {
  router.post('/api/monitor/refresh', controller.refreshProperties);
}
