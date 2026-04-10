import { Router } from './index';
import { QueryController } from '../controllers/queryController';

export function registerQueryRoutes(router: Router, controller: QueryController): void {
  router.get('/api/queries', controller.getQueries);
  router.post('/api/queries', controller.createQuery);
  router.put('/api/queries/:id', controller.updateQuery);
  router.delete('/api/queries/:id', controller.deleteQuery);
}
