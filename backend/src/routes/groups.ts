import { Router } from 'express';
import { GroupController } from '../controllers/groupController';
import { validate } from '../middleware/validate';
import { createGroupSchema, renameGroupSchema, addPropertyToGroupSchema } from '../schemas';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new GroupController();

router.get('/', async (req, res) => {
  try {
    const groups = await controller.getGroups(res.locals.userId);
    res.json(groups);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load groups');
    res.status(status).json({ error: message });
  }
});

router.post('/', validate(createGroupSchema), async (req, res) => {
  try {
    const group = await controller.createGroup(res.locals.userId, req.body);
    res.json({ group });
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to create group');
    res.status(status).json({ error: message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await controller.deleteGroup(req.params.id as string);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to delete group');
    res.status(status).json({ error: message });
  }
});

router.patch('/:id', validate(renameGroupSchema), async (req, res) => {
  try {
    const result = await controller.renameGroup(req.params.id as string, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to rename group');
    res.status(status).json({ error: message });
  }
});

router.get('/:id/properties', async (req, res) => {
  try {
    const properties = await controller.getGroupProperties(req.params.id as string);
    res.json(properties);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load group properties');
    res.status(status).json({ error: message });
  }
});

router.post('/:id/properties', validate(addPropertyToGroupSchema), async (req, res) => {
  try {
    const result = await controller.addPropertyToGroup(req.params.id as string, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to add property to group');
    res.status(status).json({ error: message });
  }
});

router.delete('/:id/properties/:propertyId', async (req, res) => {
  try {
    const result = await controller.removePropertyFromGroup(req.params.id as string, req.params.propertyId as string);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to remove property from group');
    res.status(status).json({ error: message });
  }
});

export default router;
