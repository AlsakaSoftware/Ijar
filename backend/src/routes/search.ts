import { Router } from './index';
import { SearchController } from '../controllers/searchController';

export function registerSearchRoutes(router: Router, controller: SearchController): void {
  router.post('/api/search', controller.search);
  router.post('/api/onboarding-search', controller.onboardingSearch);
  router.get('/api/property/:id/details', controller.getPropertyDetails);
}
