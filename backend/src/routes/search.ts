import { Router } from 'express';
import { SearchController } from '../controllers/searchController';
import { validate } from '../middleware/validate';
import { searchSchema, onboardingSearchSchema } from '../schemas';
import { toErrorResponse } from '../errors';

const router = Router();
const controller = new SearchController();

router.post('/search', validate(searchSchema), async (req, res) => {
  try {
    const result = await controller.search(req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Search failed');
    res.status(status).json({ error: message });
  }
});

router.post('/onboarding-search', validate(onboardingSearchSchema), async (req, res) => {
  try {
    const result = await controller.onboardingSearch(req.body);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Onboarding search failed');
    res.status(status).json({ error: message });
  }
});

router.get('/property/:id/details', async (req, res) => {
  try {
    const result = await controller.getPropertyDetails(req.params.id as string);
    res.json(result);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to load property details');
    res.status(status).json({ error: message });
  }
});

export default router;
