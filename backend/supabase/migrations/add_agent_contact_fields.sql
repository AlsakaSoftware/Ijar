-- Add agent contact information columns to property table
ALTER TABLE property
ADD COLUMN IF NOT EXISTS rightmove_url TEXT,
ADD COLUMN IF NOT EXISTS agent_phone TEXT,
ADD COLUMN IF NOT EXISTS agent_name TEXT,
ADD COLUMN IF NOT EXISTS branch_name TEXT;

-- Add comments for documentation
COMMENT ON COLUMN property.rightmove_url IS 'Full URL to the property on Rightmove';
COMMENT ON COLUMN property.agent_phone IS 'Contact phone number for the listing agent';
COMMENT ON COLUMN property.agent_name IS 'Name of the listing agent or agency';
COMMENT ON COLUMN property.branch_name IS 'Name of the specific branch handling the property';