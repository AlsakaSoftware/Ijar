import 'dotenv/config';
import express from 'express';
import { authMiddleware } from './middleware/auth';
import { GroupController } from './controllers/groupController';
import { toErrorResponse } from './errors';

import searchRoutes from './routes/search';
import propertyRoutes from './routes/properties';
import groupRoutes from './routes/groups';
import feedRoutes from './routes/feed';
import userRoutes from './routes/user';
import queryRoutes from './routes/queries';
import deviceTokenRoutes from './routes/deviceTokens';
import monitorRoutes from './routes/monitor';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

// CORS
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
    return;
  }

  next();
});

// All routes require auth
app.use('/api', authMiddleware);

// Routes
app.use('/api', searchRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/feed', feedRoutes);
app.use('/api/user', userRoutes);
app.use('/api/queries', queryRoutes);
app.use('/api/device-tokens', deviceTokenRoutes);
app.use('/api/monitor', monitorRoutes);

// GET /api/properties/:id/groups — mounted separately since it crosses resource boundaries
const groupController = new GroupController();
app.get('/api/properties/:id/groups', async (req, res) => {
  try {
    const groupIds = await groupController.getGroupsForProperty(res.locals.userId, req.params.id);
    res.json(groupIds);
  } catch (error) {
    const { status, message } = toErrorResponse(error, 'Failed to get groups for property');
    res.status(status).json({ error: message });
  }
});

app.listen(PORT, () => {
  console.log(`\nAPI running at http://localhost:${PORT}`);
  console.log(`All endpoints require Authorization: Bearer <jwt>\n`);
});
