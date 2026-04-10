import { Router } from 'express';
import { MonitorController } from '../controllers/monitorController';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new MonitorController();

router.post('/refresh', async (req, res) => {
  try {
    const result = await controller.refreshProperties(res.locals.userId);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to trigger refresh');
    res.status(status).json({ error: message });
  }
});

export default router;
