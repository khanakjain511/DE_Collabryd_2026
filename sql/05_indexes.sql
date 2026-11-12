SET search_path TO uber;

-- R01, R18: Rider history and CRM last trip lookup
CREATE INDEX IF NOT EXISTS trips_rider_requested_idx ON trips (rider_id, requested_at DESC);

-- R02, R07: Driver completed trips, earnings, and quarterly rankings
CREATE INDEX IF NOT EXISTS trips_driver_requested_completed_idx ON trips (driver_id, requested_at) INCLUDE (fare_amount) WHERE status = 'COMPLETED';

-- R04, R06, R12, R23: City-filtered trips and hourly analytics
CREATE INDEX IF NOT EXISTS trips_city_requested_idx ON trips (city_id, requested_at);

-- R05: Active dispatch queue
CREATE INDEX IF NOT EXISTS trips_dispatch_requested_idx ON trips (requested_at) WHERE status IN ('REQUESTED', 'ACCEPTED', 'ONGOING');

-- R10, W05: Trip status lookups and cancellation retention purge
CREATE INDEX IF NOT EXISTS trips_status_requested_idx ON trips (status, requested_at);

-- R21: Promo code usage analytics
CREATE INDEX IF NOT EXISTS trips_promo_code_idx ON trips (promo_code);

-- R06, R19, R20: Completed trips aggregation and daily running revenue
CREATE INDEX IF NOT EXISTS trips_completed_requested_idx ON trips (requested_at) INCLUDE (city_id, driver_id, fare_amount) WHERE status = 'COMPLETED';

-- Driver general trip lookup
CREATE INDEX IF NOT EXISTS trips_driver_requested_idx ON trips (driver_id, requested_at);

-- W02: Driver app finishing oldest ongoing trip
CREATE INDEX IF NOT EXISTS trips_ongoing_trip_id_idx ON trips (trip_id) WHERE status = 'ONGOING';

-- R24: Fraud check for long duration or distance trips
CREATE INDEX IF NOT EXISTS trips_long_completed_idx ON trips (fare_amount DESC) INCLUDE (trip_id, driver_id, distance_km, duration_min) WHERE status = 'COMPLETED' AND (distance_km > 43 OR duration_min > 150);

-- R25: Fraud check for exorbitant fare per km (> 100 Rs/km)
CREATE INDEX IF NOT EXISTS trips_fare_per_km_completed_idx ON trips (round(fare_amount / NULLIF(distance_km, 0), 2) DESC) INCLUDE (trip_id, city_id, distance_km, fare_amount) WHERE status = 'COMPLETED' AND fare_amount / NULLIF(distance_km, 0) > 100;

-- R03: Case-insensitive email login
CREATE INDEX IF NOT EXISTS riders_lower_email_idx ON riders (lower(email));

-- R09, R18: Riders by home city
CREATE INDEX IF NOT EXISTS riders_city_idx ON riders (home_city_id);

-- R13: Substring search on rider names using trigrams
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS riders_name_trgm_idx ON riders USING gin (full_name gin_trgm_ops);

-- R11: Directional ratings lookup
CREATE INDEX IF NOT EXISTS ratings_rated_by_trip_idx ON ratings (rated_by, trip_id);

-- R08, R22: Payment status and settlement date lookup
CREATE INDEX IF NOT EXISTS payments_status_paid_at_idx ON payments (payment_status, paid_at DESC) INCLUDE (trip_id, amount, method);

ANALYZE;
