-- Add latitude and longitude columns to property table for location-based features
ALTER TABLE property
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- Add comments for documentation
COMMENT ON COLUMN property.latitude IS 'Latitude coordinate of the property location';
COMMENT ON COLUMN property.longitude IS 'Longitude coordinate of the property location';

-- Add index for geospatial queries (for future optimization)
CREATE INDEX IF NOT EXISTS idx_property_coordinates ON property(latitude, longitude);
