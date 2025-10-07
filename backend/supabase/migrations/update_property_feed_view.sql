-- Drop the existing property_feed view
DROP VIEW IF EXISTS property_feed;

-- Recreate the property_feed view to automatically include all property columns
CREATE OR REPLACE VIEW property_feed AS
SELECT
    p.*,  -- Include all columns from the property table automatically
    MAX(qp.found_at) AS found_at,
    STRING_AGG(DISTINCT q.postcode, ', ') AS found_by_query
FROM property p
JOIN query_property qp ON p.id = qp.property_id
JOIN query q ON qp.query_id = q.id
WHERE NOT EXISTS (
    SELECT 1 FROM user_property_action upa
    WHERE upa.property_id = p.id
)
GROUP BY p.id  -- PostgreSQL will understand this groups by the primary key
ORDER BY MAX(qp.found_at) DESC;