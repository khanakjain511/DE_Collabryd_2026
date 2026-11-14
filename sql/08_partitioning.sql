SET search_path TO uber;

CREATE TABLE trips_large (
    LIKE trips INCLUDING DEFAULTS INCLUDING CONSTRAINTS
) PARTITION BY RANGE (requested_at);

ALTER TABLE trips_large ADD CONSTRAINT trips_large_pk PRIMARY KEY (trip_id, requested_at);
ALTER TABLE trips_large ADD CONSTRAINT trips_large_rider_fk FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE SET NULL;
ALTER TABLE trips_large ADD CONSTRAINT trips_large_driver_fk FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE SET NULL;
ALTER TABLE trips_large ADD CONSTRAINT trips_large_vehicle_driver_fk FOREIGN KEY (vehicle_id, driver_id) REFERENCES vehicles(vehicle_id, driver_id) ON DELETE SET NULL (vehicle_id, driver_id);
ALTER TABLE trips_large ADD CONSTRAINT trips_large_city_fk FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE RESTRICT;
ALTER TABLE trips_large ADD CONSTRAINT trips_large_promo_fk FOREIGN KEY (promo_code) REFERENCES promo_codes(promo_code) ON DELETE SET NULL;

DO $$
DECLARE
    month_start date := DATE '2025-01-01';
    month_end date;
    partition_name text;
BEGIN
    WHILE month_start < DATE '2036-01-01' LOOP
        month_end := (month_start + INTERVAL '1 month')::date;
        partition_name := 'trips_large_' || to_char(month_start, 'YYYY_MM');
        EXECUTE format('CREATE TABLE uber.%I PARTITION OF uber.trips_large FOR VALUES FROM (%L) TO (%L)', partition_name, month_start, month_end);
        month_start := month_end;
    END LOOP;
END
$$;

CREATE TABLE trips_large_default PARTITION OF trips_large DEFAULT;
CREATE INDEX trips_large_city_requested_idx ON trips_large (city_id, requested_at);
CREATE INDEX trips_large_rider_requested_idx ON trips_large (rider_id, requested_at DESC);
CREATE INDEX trips_large_driver_requested_idx ON trips_large (driver_id, requested_at) WHERE status = 'COMPLETED';
CREATE INDEX trips_large_dispatch_idx ON trips_large (requested_at) WHERE status IN ('REQUESTED', 'ACCEPTED', 'ONGOING');

INSERT INTO trips_large SELECT * FROM trips;
ANALYZE trips_large;
