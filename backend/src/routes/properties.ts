import { Router } from 'express';
import { PropertyController } from '../controllers/propertyController';
import { validate } from '../middleware/validate';
import { savePropertySchema, unsavePropertySchema, trackActionSchema } from '../schemas';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new PropertyController();

router.post('/save', validate(savePropertySchema), async (req, res) => {
  try {
    const result = await controller.saveProperty(res.locals.userId, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to save property');
    res.status(status).json({ error: message });
  }
});

router.post('/unsave', validate(unsavePropertySchema), async (req, res) => {
  try {
    const result = await controller.unsaveProperty(res.locals.userId, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to unsave property');
    res.status(status).json({ error: message });
  }
});

router.get('/saved', async (req, res) => {
  try {
    const properties = await controller.getSavedProperties(res.locals.userId);
    res.json(properties);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load saved properties');
    res.status(status).json({ error: message });
  }
});

router.post('/:id/action', validate(trackActionSchema), async (req, res) => {
  try {
    const result = await controller.trackAction(res.locals.userId, req.params.id as string, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to track action');
    res.status(status).json({ error: message });
  }
});

export default router;
