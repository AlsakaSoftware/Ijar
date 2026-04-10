import { Router } from './index';
import { PropertyController } from '../controllers/propertyController';

export function registerPropertyRoutes(router: Router, controller: PropertyController): void {
  router.post('/api/properties/save', controller.saveProperty);
  router.post('/api/properties/unsave', controller.unsaveProperty);
  router.get('/api/properties/saved', controller.getSavedProperties);
  router.get('/api/feed', controller.getFeed);
  router.post('/api/properties/:id/action', controller.trackAction);
}
