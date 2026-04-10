import 'dotenv/config';
import * as http from 'http';

import { Router } from './routes/index';
import { registerSearchRoutes } from './routes/search';
import { registerPropertyRoutes } from './routes/properties';
import { registerGroupRoutes } from './routes/groups';
import { registerUserRoutes } from './routes/user';
import { registerQueryRoutes } from './routes/queries';
import { registerDeviceTokenRoutes } from './routes/deviceTokens';
import { registerMonitorRoutes } from './routes/monitor';

import { RightmoveAPI } from './api';
import { SupabaseService } from './services/supabase';

// Repositories
import { PropertyRepository } from './repositories/propertyRepository';
import { UserPropertyActionRepository } from './repositories/userPropertyActionRepository';
import { GroupRepository } from './repositories/groupRepository';
import { GroupMemberRepository } from './repositories/groupMemberRepository';
import { UserRepository } from './repositories/userRepository';
import { QueryRepository } from './repositories/queryRepository';
import { DeviceTokenRepository } from './repositories/deviceTokenRepository';
import { MonitorRepository } from './repositories/monitorRepository';

// Services
import { PropertyService } from './services/propertyService';
import { GroupService } from './services/groupService';
import { SearchService } from './services/searchService';
import { UserService } from './services/userService';
import { QueryService } from './services/queryService';
import { DeviceTokenService } from './services/deviceTokenService';
import { MonitorService } from './services/monitorService';

// Controllers
import { PropertyController } from './controllers/propertyController';
import { GroupController } from './controllers/groupController';
import { SearchController } from './controllers/searchController';
import { UserController } from './controllers/userController';
import { QueryController } from './controllers/queryController';
import { DeviceTokenController } from './controllers/deviceTokenController';
import { MonitorController } from './controllers/monitorController';

import { sendError } from './utils/http';

const PORT = process.env.PORT || 3001;

// Initialize external clients
const api = new RightmoveAPI();
const supabase = new SupabaseService();
const client = supabase.getClient();

// Repositories
const propertyRepo = new PropertyRepository(client);
const actionRepo = new UserPropertyActionRepository(client);
const groupRepo = new GroupRepository(client);
const groupMemberRepo = new GroupMemberRepository(client);
const userRepo = new UserRepository(client);
const queryRepo = new QueryRepository(client);
const deviceTokenRepo = new DeviceTokenRepository(client);
const monitorRepo = new MonitorRepository();

// Services
const propertyService = new PropertyService(propertyRepo, actionRepo);
const groupService = new GroupService(groupRepo, groupMemberRepo, propertyRepo);
const searchService = new SearchService(api, propertyRepo);
const userService = new UserService(userRepo);
const queryService = new QueryService(queryRepo);
const deviceTokenService = new DeviceTokenService(deviceTokenRepo);
const monitorService = new MonitorService(monitorRepo);

// Controllers
const propertyController = new PropertyController(propertyService);
const groupController = new GroupController(groupService);
const searchController = new SearchController(searchService);
const userController = new UserController(userService);
const queryController = new QueryController(queryService);
const deviceTokenController = new DeviceTokenController(deviceTokenService);
const monitorController = new MonitorController(monitorService);

// Router + routes
const router = new Router();
registerSearchRoutes(router, searchController);
registerPropertyRoutes(router, propertyController);
registerGroupRoutes(router, groupController);
registerUserRoutes(router, userController);
registerQueryRoutes(router, queryController);
registerDeviceTokenRoutes(router, deviceTokenController);
registerMonitorRoutes(router, monitorController);

// Create server
const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Try to match route
  const handled = await router.handle(req, res);

  if (!handled) {
    sendError(res, 'Not found', 404);
  }
});

server.listen(PORT, () => {
  console.log(`\nAPI running at http://localhost:${PORT}`);
  console.log(`\nAll endpoints require Authorization: Bearer <jwt>`);
  console.log(`\nSearch Endpoints:`);
  console.log(`  POST /api/search`);
  console.log(`  POST /api/onboarding-search`);
  console.log(`  GET  /api/property/:id/details`);
  console.log(`\nProperty Endpoints:`);
  console.log(`  POST /api/properties/save`);
  console.log(`  POST /api/properties/unsave`);
  console.log(`  GET  /api/properties/saved`);
  console.log(`  GET  /api/feed`);
  console.log(`  POST /api/properties/:id/action`);
  console.log(`\nGroup Endpoints:`);
  console.log(`  GET    /api/groups`);
  console.log(`  POST   /api/groups`);
  console.log(`  DELETE /api/groups/:id`);
  console.log(`  PATCH  /api/groups/:id`);
  console.log(`  GET    /api/groups/:id/properties`);
  console.log(`  POST   /api/groups/:id/properties`);
  console.log(`  DELETE /api/groups/:id/properties/:propertyId`);
  console.log(`  GET    /api/properties/:id/groups`);
  console.log(`\nUser Endpoints:`);
  console.log(`  GET   /api/user`);
  console.log(`  PUT   /api/user`);
  console.log(`  PATCH /api/user/onboarding`);
  console.log(`\nQuery Endpoints:`);
  console.log(`  GET    /api/queries`);
  console.log(`  POST   /api/queries`);
  console.log(`  PUT    /api/queries/:id`);
  console.log(`  DELETE /api/queries/:id`);
  console.log(`\nDevice Token Endpoints:`);
  console.log(`  PUT    /api/device-tokens`);
  console.log(`  DELETE /api/device-tokens`);
  console.log(`\nMonitor Endpoints:`);
  console.log(`  POST   /api/monitor/refresh`);
  console.log(`\nPress Ctrl+C to stop\n`);
});
