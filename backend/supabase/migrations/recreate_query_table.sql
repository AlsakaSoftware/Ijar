-- Complete recreation of query table with new schema
-- WARNING: This will delete all existing query data!

BEGIN;

-- Drop dependent views first
DROP VIEW IF EXISTS user_query_summary;
DROP VIEW IF EXISTS query_results;

-- Drop and recreate the table
DROP TABLE IF EXISTS query CASCADE;

CREATE TABLE query (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- from auth.users

    -- Query details
    name TEXT NOT NULL,
    postcode TEXT NOT NULL,
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

    -- Foreign key constraint (if you have user table)
    CONSTRAINT fk_query_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Recreate views
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