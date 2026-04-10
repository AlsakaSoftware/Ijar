import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new UserController();

router.get('/', async (req, res) => {
  try {
    const user = await controller.getUser(res.locals.userId);
    res.json(user);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load user');
    res.status(status).json({ error: message });
  }
});

router.put('/', async (req, res) => {
  try {
    const user = await controller.upsertUser(res.locals.userId);
    res.json(user);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to upsert user');
    res.status(status).json({ error: message });
  }
});

router.patch('/onboarding', async (req, res) => {
  try {
    const result = await controller.markOnboardingComplete(res.locals.userId);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to update onboarding');
    res.status(status).json({ error: message });
  }
});

export default router;
