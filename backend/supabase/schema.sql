-- Simple Property Search Database Schema
-- Just 3 core tables - no duplications, no unused complexity

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User search queries
CREATE TABLE IF NOT EXISTS query (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- from auth.users
    
    -- Query details
    name TEXT NOT NULL,
    location_id TEXT NOT NULL,
    location_name TEXT NOT NULL,
    min_price INTEGER,
    max_price INTEGER,
    min_bedrooms INTEGER,
    max_bedrooms INTEGER,
    min_bathrooms INTEGER,
    max_bathrooms INTEGER,
    radius DECIMAL(3,1),
    furnish_type TEXT,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT query_user_name_unique UNIQUE (user_id, name)
);

-- Properties (deduplicated globally)
CREATE TABLE IF NOT EXISTS property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rightmove_id INTEGER UNIQUE NOT NULL,
    
    -- Property data
    images TEXT[] NOT NULL DEFAULT '{}',
    price TEXT NOT NULL,
    bedrooms INTEGER NOT NULL DEFAULT 0,
    bathrooms INTEGER NOT NULL DEFAULT 0,
    address TEXT NOT NULL,
    area TEXT,
    
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW()
);

-- Links queries to their found properties
CREATE TABLE IF NOT EXISTS query_property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_id UUID NOT NULL REFERENCES query(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES property(id) ON DELETE CASCADE,
    
    -- When this property was found for this query
    found_at TIMESTAMP DEFAULT NOW(),
    
    -- Prevent same property appearing twice for same query
    CONSTRAINT query_property_unique UNIQUE (query_id, property_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_query_user ON query(user_id);
CREATE INDEX IF NOT EXISTS idx_query_active ON query(active);
CREATE INDEX IF NOT EXISTS idx_property_rightmove ON property(rightmove_id);
CREATE INDEX IF NOT EXISTS idx_query_property_query ON query_property(query_id);
CREATE INDEX IF NOT EXISTS idx_query_property_found ON query_property(found_at);

-- Auto-update timestamps
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

-- Row Level Security
ALTER TABLE query ENABLE ROW LEVEL SECURITY;
ALTER TABLE property ENABLE ROW LEVEL SECURITY;
ALTER TABLE query_property ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users manage own queries" ON query
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Properties viewable by everyone" ON property
    FOR SELECT USING (true);

CREATE POLICY "Users view own query results" ON query_property
    FOR SELECT USING (
        query_id IN (
            SELECT id FROM query WHERE user_id = auth.uid()
        )
    );

-- Track user actions on properties (saved/passed)
CREATE TABLE IF NOT EXISTS user_property_action (
    user_id UUID NOT NULL,
    property_id UUID NOT NULL REFERENCES property(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('saved', 'passed')),
    created TIMESTAMP DEFAULT NOW(),
    
    PRIMARY KEY (user_id, property_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_property_action_user ON user_property_action(user_id);

-- RLS for user actions
ALTER TABLE user_property_action ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own property actions" ON user_property_action
    FOR ALL USING (auth.uid() = user_id);

-- Property feed - shows new recommendations for the user (excluding seen ones)
CREATE OR REPLACE VIEW property_feed AS
SELECT 
    p.*,
    qp.found_at,
    q.name as found_by_query
FROM query_property qp
JOIN property p ON qp.property_id = p.id
JOIN query q ON qp.query_id = q.id
WHERE q.user_id = auth.uid()
AND p.id NOT IN (
    SELECT property_id 
    FROM user_property_action 
    WHERE user_id = auth.uid()
)
ORDER BY qp.found_at DESC
LIMIT 50;

-- View for saved properties
CREATE OR REPLACE VIEW saved_properties AS
SELECT 
    p.*,
    upa.created as saved_at
FROM user_property_action upa
JOIN property p ON upa.property_id = p.id
WHERE upa.user_id = auth.uid()
AND upa.action = 'saved'
ORDER BY upa.created DESC;

-- View for all properties user has interacted with (saved or passed)
CREATE OR REPLACE VIEW user_property_history AS
SELECT 
    p.*,
    upa.action,
    upa.created as action_date
FROM user_property_action upa
JOIN property p ON upa.property_id = p.id
WHERE upa.user_id = auth.uid()
ORDER BY upa.created DESC;