-- Properties table schema for Ijar app
-- This schema matches the Swift Property model and enriched Rightmove data

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create properties table (core data only)
CREATE TABLE IF NOT EXISTS property (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rightmove_id INTEGER UNIQUE NOT NULL,
    
    -- App fields only
    images TEXT[] NOT NULL DEFAULT '{}',
    price TEXT NOT NULL,
    bedrooms INTEGER NOT NULL DEFAULT 0,
    bathrooms INTEGER NOT NULL DEFAULT 0,
    address TEXT NOT NULL,
    area TEXT,
    
    -- Metadata for workflow
    search TEXT,
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT property_rightmove_id_key UNIQUE (rightmove_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_property_bedrooms ON property(bedrooms);
CREATE INDEX IF NOT EXISTS idx_property_search ON property(search);
CREATE INDEX IF NOT EXISTS idx_property_created ON property(created);
CREATE INDEX IF NOT EXISTS idx_property_active ON property(active);

-- Create a function to update the updated timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated
CREATE TRIGGER update_property_timestamp
    BEFORE UPDATE ON property 
    FOR EACH ROW 
    EXECUTE FUNCTION update_timestamp();

-- User saved properties table
CREATE TABLE IF NOT EXISTS saved (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    property_id UUID NOT NULL REFERENCES property(id) ON DELETE CASCADE,
    created TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    
    CONSTRAINT saved_unique UNIQUE (user_id, property_id)
);

-- Create index for user queries
CREATE INDEX IF NOT EXISTS idx_saved_user ON saved(user_id);

-- Row Level Security (RLS) policies
ALTER TABLE property ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved ENABLE ROW LEVEL SECURITY;

-- Properties are readable by everyone (public data)
CREATE POLICY "Properties viewable by everyone" ON property
    FOR SELECT USING (true);

-- Only authenticated users can save properties
CREATE POLICY "Users view own saves" ON saved
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users save properties" ON saved
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users delete saves" ON saved
    FOR DELETE USING (auth.uid() = user_id);

-- Create a view for properties with saved status
CREATE OR REPLACE VIEW property_saved AS
SELECT 
    p.*,
    CASE 
        WHEN s.property_id IS NOT NULL THEN true 
        ELSE false 
    END as saved,
    s.created as saved_at,
    s.notes as saved_notes
FROM property p
LEFT JOIN saved s ON p.id = s.property_id 
    AND s.user_id = auth.uid()
WHERE p.active = true;