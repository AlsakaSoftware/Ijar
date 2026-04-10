import { Router } from 'express';
import { QueryController } from '../controllers/queryController';
import { validate } from '../middleware/validate';
import { createQuerySchema, updateQuerySchema } from '../schemas';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new QueryController();

router.get('/', async (req, res) => {
  try {
    const queries = await controller.getQueries(res.locals.userId);
    res.json(queries);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load queries');
    res.status(status).json({ error: message });
  }
});

router.post('/', validate(createQuerySchema), async (req, res) => {
  try {
    const query = await controller.createQuery(res.locals.userId, req.body);
    res.json(query);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to create query');
    res.status(status).json({ error: message });
  }
});

router.put('/:id', validate(updateQuerySchema), async (req, res) => {
  try {
    const result = await controller.updateQuery(res.locals.userId, req.params.id as string, req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to update query');
    res.status(status).json({ error: message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await controller.deleteQuery(res.locals.userId, req.params.id as string);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to delete query');
    res.status(status).json({ error: message });
  }
});

export default router;
