-- Property Search App Database Schema - Final Version
-- Users create custom queries, workflow runs them daily, shows best results per query

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User queries/searches table
CREATE TABLE IF NOT EXISTS query (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- from auth.users
    
    -- Query configuration
    name TEXT NOT NULL, -- "Canary Wharf 3-bed", "Cheap Mile End"
    postcode TEXT NOT NULL, -- UK postcode like "E14 6FT"
    
    -- Price filters
    min_price INTEGER,
    max_price INTEGER,
    
    -- Property filters
    min_bedrooms INTEGER,
    max_bedrooms INTEGER,
    min_bathrooms INTEGER,
    max_bathrooms INTEGER,
    
    -- Additional filters
    radius DECIMAL(3,1), -- search radius in miles
    furnish_type TEXT, -- 'furnished', 'unfurnished', 'any'
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW(),
    
    -- User can have multiple queries with unique names
    CONSTRAINT query_user_name_unique UNIQUE (user_id, name)
);

-- Properties table (core data only)
CREATE TABLE IF NOT EXISTS property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rightmove_id INTEGER UNIQUE NOT NULL,
    
    -- Core property data
    images TEXT[] NOT NULL DEFAULT '{}',
    price TEXT NOT NULL,
    bedrooms INTEGER NOT NULL DEFAULT 0,
    bathrooms INTEGER NOT NULL DEFAULT 0,
    address TEXT NOT NULL,
    area TEXT,
    
    -- Metadata
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT property_rightmove_id_key UNIQUE (rightmove_id)
);

-- Links queries to properties with metadata
CREATE TABLE IF NOT EXISTS query_property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_id UUID NOT NULL REFERENCES query(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES property(id) ON DELETE CASCADE,
    
    -- Result metadata (this is what makes it smart!)
    found_at TIMESTAMP DEFAULT NOW(),
    score INTEGER DEFAULT 0, -- ranking score (recency + photos + price fit + etc)
    
    -- Prevent duplicates per query
    CONSTRAINT query_property_unique UNIQUE (query_id, property_id)
);

-- User saved properties (favorites across all queries)
CREATE TABLE IF NOT EXISTS saved_property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    property_id UUID NOT NULL REFERENCES property(id) ON DELETE CASCADE,
    created TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    
    CONSTRAINT saved_property_unique UNIQUE (user_id, property_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_query_user ON query(user_id);
CREATE INDEX IF NOT EXISTS idx_query_active ON query(active);

CREATE INDEX IF NOT EXISTS idx_property_bedrooms ON property(bedrooms);
CREATE INDEX IF NOT EXISTS idx_property_created ON property(created);

CREATE INDEX IF NOT EXISTS idx_query_property_query ON query_property(query_id);
CREATE INDEX IF NOT EXISTS idx_query_property_found ON query_property(found_at);
CREATE INDEX IF NOT EXISTS idx_query_property_score ON query_property(score);

CREATE INDEX IF NOT EXISTS idx_saved_property_user ON saved_property(user_id);

-- Update timestamps automatically
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_query_timestamp
    BEFORE UPDATE ON query 
    FOR EACH ROW 
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_property_timestamp
    BEFORE UPDATE ON property 
    FOR EACH ROW 
    EXECUTE FUNCTION update_timestamp();

-- Row Level Security (RLS)
ALTER TABLE query ENABLE ROW LEVEL SECURITY;
ALTER TABLE property ENABLE ROW LEVEL SECURITY;
ALTER TABLE query_property ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_property ENABLE ROW LEVEL SECURITY;

-- Query policies - users can only manage their own queries
CREATE POLICY "Users manage own queries" ON query
    FOR ALL USING (auth.uid() = user_id);

-- Property policies - properties are public (read-only for users)
CREATE POLICY "Properties viewable by everyone" ON property
    FOR SELECT USING (true);

-- Query property policies - users can only see results for their queries
CREATE POLICY "Users view own query results" ON query_property
    FOR SELECT USING (
        query_id IN (
            SELECT id FROM query WHERE user_id = auth.uid()
        )
    );

-- Saved property policies
CREATE POLICY "Users manage own saved properties" ON saved_property
    FOR ALL USING (auth.uid() = user_id);

-- Useful views for the app

-- User's queries with summary stats
CREATE OR REPLACE VIEW user_query_summary AS
SELECT
    q.id,
    q.name,
    q.postcode,
    q.min_price,
    q.max_price,
    q.min_bedrooms,
    q.max_bedrooms,
    q.active,
    q.created,
    COUNT(qp.id) as total_properties,
    COUNT(CASE WHEN qp.found_at > NOW() - INTERVAL '7 days' THEN 1 END) as new_this_week,
    COUNT(CASE WHEN qp.found_at > NOW() - INTERVAL '1 day' THEN 1 END) as new_today,
    MAX(qp.found_at) as last_result
FROM query q
LEFT JOIN query_property qp ON q.id = qp.query_id
WHERE q.user_id = auth.uid()
GROUP BY q.id, q.name, q.postcode, q.min_price, q.max_price, q.min_bedrooms, q.max_bedrooms, q.active, q.created
ORDER BY q.created DESC;

-- Properties for a specific query with saved status
CREATE OR REPLACE VIEW query_results AS
SELECT 
    qp.query_id,
    q.name as query_name,
    p.*,
    qp.score,
    qp.found_at,
    CASE 
        WHEN sp.property_id IS NOT NULL THEN true 
        ELSE false 
    END as is_saved,
    sp.created as saved_at,
    sp.notes as saved_notes
FROM query_property qp
JOIN property p ON qp.property_id = p.id
JOIN query q ON qp.query_id = q.id
LEFT JOIN saved_property sp ON p.id = sp.property_id AND sp.user_id = auth.uid()
WHERE q.user_id = auth.uid()
ORDER BY qp.score DESC, qp.found_at DESC;

-- Daily digest - best new properties from all user queries
CREATE OR REPLACE VIEW daily_digest AS
SELECT 
    p.*,
    qp.score,
    qp.found_at,
    q.name as found_by_query,
    CASE 
        WHEN sp.property_id IS NOT NULL THEN true 
        ELSE false 
    END as is_saved
FROM query_property qp
JOIN property p ON qp.property_id = p.id
JOIN query q ON qp.query_id = q.id
LEFT JOIN saved_property sp ON p.id = sp.property_id AND sp.user_id = auth.uid()
WHERE q.user_id = auth.uid()
AND qp.found_at > NOW() - INTERVAL '1 day'  -- Last 24 hours
ORDER BY qp.score DESC, qp.found_at DESC
LIMIT 20;