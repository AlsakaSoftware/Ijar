-- Remove property_feed limit to return all unseen properties
-- The app only renders 3 cards at a time, so this won't impact performance
-- With 2-page scraping (max 50 props/query × 5 queries = 250 max), this is safe

DROP VIEW IF EXISTS property_feed;

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
ORDER BY qp.found_at DESC;
