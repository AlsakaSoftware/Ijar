-- Migration: Replace location_id and location_name with postcode
-- This migration assumes location_id contains postcode-like data

BEGIN;

-- Step 1: Add the new postcode column
ALTER TABLE query ADD COLUMN postcode TEXT;

-- Step 2: Migrate existing data (assuming location_id contains postcode data)
-- You may need to adjust this based on your existing data format
UPDATE query SET postcode = location_id WHERE postcode IS NULL;

-- Step 3: Make postcode NOT NULL after data migration
ALTER TABLE query ALTER COLUMN postcode SET NOT NULL;

-- Step 4: Drop the old columns
ALTER TABLE query DROP COLUMN location_id;
ALTER TABLE query DROP COLUMN location_name;

-- Step 5: Update any views that reference the old columns
DROP VIEW IF EXISTS user_query_summary;
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
    COUNT(qp.property_id) as property_count,
    MAX(qp.found_at) as last_result
FROM query q
LEFT JOIN query_property qp ON q.id = qp.query_id
WHERE q.user_id = auth.uid()
GROUP BY q.id, q.name, q.postcode, q.min_price, q.max_price, q.min_bedrooms, q.max_bedrooms, q.active, q.created
ORDER BY q.created DESC;

COMMIT;