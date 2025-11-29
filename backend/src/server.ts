import * as http from 'http';
import { RightmoveScraper } from './rightmove-scraper';
import { LiveSearchProperty, transformProperty } from './models/property';

const PORT = process.env.PORT || 3001;

interface LiveSearchRequest {
  postcode: string;
  minPrice?: number;
  maxPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  minBathrooms?: number;
  maxBathrooms?: number;
  radius?: number;
  furnishType?: string;
  index?: number;
}

interface LiveSearchResponse {
  properties: LiveSearchProperty[];
  total: number;
  hasMore: boolean;
  nextIndex: number | null;
}

async function handleSearch(body: LiveSearchRequest): Promise<LiveSearchResponse> {
  const scraper = new RightmoveScraper();

  let furnishTypes: 'furnished' | 'unfurnished' | 'partFurnished' | 'furnished_or_unfurnished' | undefined;
  if (body.furnishType === 'furnished') {
    furnishTypes = 'furnished';
  } else if (body.furnishType === 'unfurnished') {
    furnishTypes = 'unfurnished';
  } else if (body.furnishType === 'partFurnished') {
    furnishTypes = 'partFurnished';
  }

  const results = await scraper.searchProperties({
    searchType: 'RENT',
    postcode: body.postcode,
    minPrice: body.minPrice,
    maxPrice: body.maxPrice,
    minBedrooms: body.minBedrooms,
    maxBedrooms: body.maxBedrooms,
    minBathrooms: body.minBathrooms,
    maxBathrooms: body.maxBathrooms,
    radius: body.radius,
    furnishTypes,
    getAllPages: false,
    quiet: false
  });

  const properties = results.properties.map(transformProperty);
  const currentIndex = body.index || 0;
  const hasMore = currentIndex + properties.length < results.total;
  const nextIndex = hasMore ? currentIndex + 24 : null;

  return {
    properties,
    total: results.total,
    hasMore,
    nextIndex
  };
}

const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.url === '/api/search' && req.method === 'POST') {
    let body = '';

    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const data = JSON.parse(body) as LiveSearchRequest;

        if (!data.postcode || data.postcode.trim() === '') {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'postcode is required' }));
          return;
        }

        console.log('\n--- Search Request ---');
        console.log('Postcode:', data.postcode);
        console.log('Price:', data.minPrice || 'any', '-', data.maxPrice || 'any');
        console.log('Beds:', data.minBedrooms || 'any', '-', data.maxBedrooms || 'any');
        console.log('Index:', data.index || 0);

        const result = await handleSearch(data);

        console.log('\n--- Results ---');
        console.log('Total:', result.total);
        console.log('Returned:', result.properties.length);
        console.log('Has more:', result.hasMore);

        res.writeHead(200);
        res.end(JSON.stringify(result));

      } catch (error) {
        console.error('Error:', error);
        const message = error instanceof Error ? error.message : 'Unknown error';
        res.writeHead(500);
        res.end(JSON.stringify({ error: message }));
      }
    });

  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found. Use POST /api/search' }));
  }
});

server.listen(PORT, () => {
  console.log(`\n🚀 Live Search API running at http://localhost:${PORT}`);
  console.log(`\nEndpoint: POST /api/search`);
  console.log(`\nTest with:`);
  console.log(`curl -X POST http://localhost:${PORT}/api/search \\`);
  console.log(`  -H "Content-Type: application/json" \\`);
  console.log(`  -d '{"postcode": "SW6 1BA", "maxPrice": 3000, "minBedrooms": 2}'`);
  console.log(`\nPress Ctrl+C to stop\n`);
});
