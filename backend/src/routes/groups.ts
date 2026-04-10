import { Router } from './index';
import { GroupController } from '../controllers/groupController';

export function registerGroupRoutes(router: Router, controller: GroupController): void {
  router.get('/api/groups', controller.getGroups);
  router.post('/api/groups', controller.createGroup);
  router.delete('/api/groups/:id', controller.deleteGroup);
  router.patch('/api/groups/:id', controller.renameGroup);
  router.get('/api/groups/:id/properties', controller.getGroupProperties);
  router.post('/api/groups/:id/properties', controller.addPropertyToGroup);
  router.delete('/api/groups/:id/properties/:propertyId', controller.removePropertyFromGroup);
  router.get('/api/properties/:id/groups', controller.getGroupsForProperty);
}
