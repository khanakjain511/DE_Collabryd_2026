SET search_path TO uber;
\copy cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true)
\copy riders FROM 'seed_data/riders.csv' WITH (FORMAT csv, HEADER true)
\copy drivers FROM 'seed_data/drivers.csv' WITH (FORMAT csv, HEADER true)
\copy vehicles FROM 'seed_data/vehicles.csv' WITH (FORMAT csv, HEADER true)
\copy promo_codes FROM 'seed_data/promo_codes.csv' WITH (FORMAT csv, HEADER true)
\copy trips FROM 'seed_data/trips.csv' WITH (FORMAT csv, HEADER true)
\copy payments FROM 'seed_data/payments.csv' WITH (FORMAT csv, HEADER true)
\copy ratings FROM 'seed_data/ratings.csv' WITH (FORMAT csv, HEADER true)
ANALYZE;

SELECT 'cities' AS table_name, count(*) AS row_count FROM cities
UNION ALL SELECT 'riders', count(*) FROM riders
UNION ALL SELECT 'drivers', count(*) FROM drivers
UNION ALL SELECT 'vehicles', count(*) FROM vehicles
UNION ALL SELECT 'promo_codes', count(*) FROM promo_codes
UNION ALL SELECT 'trips', count(*) FROM trips
UNION ALL SELECT 'payments', count(*) FROM payments
UNION ALL SELECT 'ratings', count(*) FROM ratings;

SELECT count(*) AS completed_trips_without_payment
FROM trips t LEFT JOIN payments p USING (trip_id)
WHERE t.status = 'COMPLETED' AND p.trip_id IS NULL;

SELECT count(*) AS trips_with_vehicle_driver_mismatch
FROM trips t JOIN vehicles v ON v.vehicle_id = t.vehicle_id
WHERE t.driver_id IS DISTINCT FROM v.driver_id;

SELECT count(*) AS payments_without_completed_trip
FROM payments p JOIN trips t USING (trip_id)
WHERE t.status <> 'COMPLETED';
