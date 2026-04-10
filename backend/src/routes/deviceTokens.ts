import { Router } from 'express';
import { DeviceTokenController } from '../controllers/deviceTokenController';
import { validate } from '../middleware/validate';
import { upsertTokenSchema } from '../schemas';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new DeviceTokenController();

router.put('/', validate(upsertTokenSchema), async (req, res) => {
  try {
    const result = await controller.upsertToken(res.locals.userId, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to save device token');
    res.status(status).json({ error: message });
  }
});

router.delete('/', async (req, res) => {
  try {
    const result = await controller.removeTokens(res.locals.userId);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to remove device tokens');
    res.status(status).json({ error: message });
  }
});

export default router;
