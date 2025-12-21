/**
 * Live Search API Server
 */

import 'dotenv/config';
import * as http from 'http';

import { Router } from './routes/index';
import { registerSearchRoutes } from './routes/search';
import { registerPropertyRoutes } from './routes/properties';
import { registerGroupRoutes } from './routes/groups';

import { RightmoveAPI } from './api';
import { SupabaseService } from './services/supabase';
import { PropertySaveService } from './services/properties';
import { GroupService } from './services/groups';
import { sendError } from './utils/http';

const PORT = process.env.PORT || 3001;

// Initialize services
const api = new RightmoveAPI();
const supabase = new SupabaseService();
const propertySaveService = new PropertySaveService(supabase.getClient());
const groupService = new GroupService(supabase.getClient());

// Initialize router and register routes
const router = new Router();
registerSearchRoutes(router, api, supabase);
registerPropertyRoutes(router, propertySaveService);
registerGroupRoutes(router, groupService);

// Create server
const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
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
  console.log(`\n🚀 Live Search API running at http://localhost:${PORT}`);
  console.log(`\nSearch Endpoints:`);
  console.log(`  POST /api/search - Search properties`);
  console.log(`  POST /api/onboarding-search - Search, fetch HD images, save to DB`);
  console.log(`  GET  /api/property/:id/details - Get property details`);
  console.log(`\nSaved Properties Endpoints:`);
  console.log(`  POST /api/properties/save - Save a property`);
  console.log(`  POST /api/properties/unsave - Unsave a property`);
  console.log(`  GET  /api/properties/saved?userId=xxx - Get all saved properties`);
  console.log(`\nGroup Endpoints:`);
  console.log(`  GET    /api/groups?userId=xxx - List groups`);
  console.log(`  POST   /api/groups - Create group`);
  console.log(`  DELETE /api/groups/:id - Delete group`);
  console.log(`  PATCH  /api/groups/:id - Rename group`);
  console.log(`  GET    /api/groups/:id/properties - Get properties in group`);
  console.log(`  POST   /api/groups/:id/properties - Add property to group`);
  console.log(`  DELETE /api/groups/:id/properties/:propertyId - Remove from group`);
  console.log(`  GET    /api/properties/:id/groups?userId=xxx - Get groups for property`);
  console.log(`\nPress Ctrl+C to stop\n`);
});
