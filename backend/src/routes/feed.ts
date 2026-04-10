import { Router } from 'express';
import { PropertyController } from '../controllers/propertyController';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new PropertyController();

router.get('/', async (req, res) => {
  try {
    const properties = await controller.getFeed(res.locals.userId);
    res.json(properties);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load feed');
    res.status(status).json({ error: message });
  }
});

export default router;
