import { Router } from './index';
import { UserController } from '../controllers/userController';

export function registerUserRoutes(router: Router, controller: UserController): void {
  router.get('/api/user', controller.getUser);
  router.put('/api/user', controller.upsertUser);
  router.patch('/api/user/onboarding', controller.markOnboardingComplete);
}
