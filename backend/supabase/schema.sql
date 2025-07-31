-- Properties table schema for Ijar app
-- This schema matches the Swift Property model and enriched Rightmove data

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create properties table
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rightmove_id INTEGER UNIQUE NOT NULL,
    
    -- Basic property information
    images TEXT[] NOT NULL DEFAULT '{}',
    price TEXT NOT NULL,
    bedrooms INTEGER NOT NULL DEFAULT 0,
    bathrooms INTEGER NOT NULL DEFAULT 0,
    address TEXT NOT NULL,
    area TEXT, -- extracted from address/location
    
    -- Location data
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Transport information
    nearest_tube_station TEXT,
    tube_station_distance DECIMAL(5, 2), -- in miles
    nearby_stations JSONB, -- array of station objects with name, types, distance
    transport_description TEXT,
    
    -- Additional Rightmove data
    property_url TEXT,
    contact_url TEXT,
    summary TEXT,
    property_type TEXT,
    display_size TEXT,
    number_of_images INTEGER DEFAULT 0,
    first_visible_date TIMESTAMP,
    
    -- Agent information
    agent_name TEXT,
    agent_phone TEXT,
    brand_name TEXT,
    
    -- Metadata
    search_name TEXT, -- which search config found this property
    first_seen TIMESTAMP DEFAULT NOW(),
    last_updated TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Indexes for common queries
    CONSTRAINT properties_rightmove_id_key UNIQUE (rightmove_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_properties_rightmove_id ON properties(rightmove_id);
CREATE INDEX IF NOT EXISTS idx_properties_location ON properties(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_properties_price_bedrooms ON properties(bedrooms, price);
CREATE INDEX IF NOT EXISTS idx_properties_search_name ON properties(search_name);
CREATE INDEX IF NOT EXISTS idx_properties_first_seen ON properties(first_seen);
CREATE INDEX IF NOT EXISTS idx_properties_active ON properties(is_active);

-- Create a function to update the last_updated timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update last_updated
CREATE TRIGGER update_properties_updated_at 
    BEFORE UPDATE ON properties 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- User saved properties table (for the app)
CREATE TABLE IF NOT EXISTS user_saved_properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- from auth.users
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    saved_at TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    
    CONSTRAINT user_saved_properties_unique UNIQUE (user_id, property_id)
);

-- Create index for user queries
CREATE INDEX IF NOT EXISTS idx_user_saved_properties_user_id ON user_saved_properties(user_id);

-- Row Level Security (RLS) policies
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_properties ENABLE ROW LEVEL SECURITY;

-- Properties are readable by everyone (public data)
CREATE POLICY "Properties are viewable by everyone" ON properties
    FOR SELECT USING (true);

-- Only authenticated users can save properties
CREATE POLICY "Users can view their own saved properties" ON user_saved_properties
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can save properties" ON user_saved_properties
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their saved properties" ON user_saved_properties
    FOR DELETE USING (auth.uid() = user_id);

-- Create a view for properties with saved status for a user
CREATE OR REPLACE VIEW properties_with_saved_status AS
SELECT 
    p.*,
    CASE 
        WHEN usp.property_id IS NOT NULL THEN true 
        ELSE false 
    END as is_saved,
    usp.saved_at,
    usp.notes as saved_notes
FROM properties p
LEFT JOIN user_saved_properties usp ON p.id = usp.property_id 
    AND usp.user_id = auth.uid()
WHERE p.is_active = true;