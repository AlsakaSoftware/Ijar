-- Recreate saved_properties view to include all new property columns
-- (agent contact fields, latitude, longitude, etc.)

DROP VIEW IF EXISTS saved_properties CASCADE;

CREATE VIEW saved_properties AS
SELECT
    p.*,
    upa.created as saved_at
FROM user_property_action upa
JOIN property p ON upa.property_id = p.id
WHERE upa.user_id = auth.uid()
AND upa.action = 'saved'
ORDER BY upa.created DESC;
