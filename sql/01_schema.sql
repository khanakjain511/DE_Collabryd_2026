CREATE SCHEMA uber;
SET search_path TO uber;

CREATE TABLE cities (
    city_id integer PRIMARY KEY,
    city_name varchar(40) NOT NULL UNIQUE,
    state varchar(40) NOT NULL,
    base_fare numeric(8,2) NOT NULL CHECK (base_fare >= 0),
    per_km_rate numeric(8,2) NOT NULL CHECK (per_km_rate >= 0),
    per_min_rate numeric(8,2) NOT NULL CHECK (per_min_rate >= 0),
    launched_on date NOT NULL
);

CREATE TABLE riders (
    rider_id integer PRIMARY KEY,
    full_name varchar(100) NOT NULL,
    email varchar(254) NOT NULL UNIQUE,
    phone varchar(20) NOT NULL UNIQUE,
    home_city_id integer NOT NULL REFERENCES cities(city_id) ON DELETE RESTRICT,
    signup_date date NOT NULL,
    rider_rating numeric(2,1) CHECK (rider_rating BETWEEN 1.0 AND 5.0),
    is_active boolean NOT NULL
);

CREATE TABLE drivers (
    driver_id integer PRIMARY KEY,
    full_name varchar(100) NOT NULL,
    phone varchar(20) NOT NULL UNIQUE,
    license_no varchar(30) NOT NULL UNIQUE,
    city_id integer NOT NULL REFERENCES cities(city_id) ON DELETE RESTRICT,
    joined_on date NOT NULL,
    driver_rating numeric(2,1) NOT NULL CHECK (driver_rating BETWEEN 1.0 AND 5.0),
    status varchar(12) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);

CREATE TABLE vehicles (
    vehicle_id integer PRIMARY KEY,
    driver_id integer NOT NULL REFERENCES drivers(driver_id) ON DELETE RESTRICT,
    registration_no varchar(20) NOT NULL UNIQUE,
    make varchar(40) NOT NULL,
    model varchar(40) NOT NULL,
    manufacture_year smallint NOT NULL CHECK (manufacture_year BETWEEN 1980 AND 2100),
    vehicle_type varchar(10) NOT NULL CHECK (vehicle_type IN ('MINI', 'SEDAN', 'SUV', 'BIKE', 'AUTO')),
    seat_capacity smallint NOT NULL CHECK (seat_capacity BETWEEN 1 AND 8),
    UNIQUE (vehicle_id, driver_id),
    CHECK ((vehicle_type = 'BIKE' AND seat_capacity = 1) OR (vehicle_type = 'AUTO' AND seat_capacity = 3) OR (vehicle_type = 'MINI' AND seat_capacity = 4) OR (vehicle_type = 'SEDAN' AND seat_capacity = 4) OR (vehicle_type = 'SUV' AND seat_capacity BETWEEN 6 AND 7))
);

CREATE TABLE promo_codes (
    promo_code varchar(20) PRIMARY KEY,
    discount_pct numeric(5,2) NOT NULL CHECK (discount_pct > 0 AND discount_pct <= 100),
    max_discount numeric(8,2) NOT NULL CHECK (max_discount >= 0),
    valid_from date NOT NULL,
    valid_to date NOT NULL,
    is_active boolean NOT NULL,
    CHECK (valid_to >= valid_from)
);

CREATE TABLE trips (
    trip_id bigint PRIMARY KEY,
    rider_id integer REFERENCES riders(rider_id) ON DELETE SET NULL,
    driver_id integer REFERENCES drivers(driver_id) ON DELETE SET NULL,
    vehicle_id integer,
    city_id integer NOT NULL REFERENCES cities(city_id) ON DELETE RESTRICT,
    promo_code varchar(20) REFERENCES promo_codes(promo_code) ON DELETE SET NULL,
    requested_at timestamptz NOT NULL,
    pickup_at timestamptz,
    dropoff_at timestamptz,
    pickup_lat numeric(9,6) NOT NULL CHECK (pickup_lat BETWEEN -90 AND 90),
    pickup_lng numeric(9,6) NOT NULL CHECK (pickup_lng BETWEEN -180 AND 180),
    drop_lat numeric(9,6) NOT NULL CHECK (drop_lat BETWEEN -90 AND 90),
    drop_lng numeric(9,6) NOT NULL CHECK (drop_lng BETWEEN -180 AND 180),
    distance_km numeric(8,2) CHECK (distance_km >= 0),
    duration_min smallint CHECK (duration_min >= 0),
    surge_multiplier numeric(5,2) NOT NULL CHECK (surge_multiplier >= 1.00),
    fare_amount numeric(10,2) CHECK (fare_amount >= 0),
    status varchar(24) NOT NULL CHECK (status IN ('REQUESTED', 'ACCEPTED', 'ONGOING', 'COMPLETED', 'CANCELLED_BY_RIDER', 'CANCELLED_BY_DRIVER')),
    FOREIGN KEY (vehicle_id, driver_id) REFERENCES vehicles(vehicle_id, driver_id) ON DELETE SET NULL (vehicle_id, driver_id),
    CHECK ((driver_id IS NULL) = (vehicle_id IS NULL)),
    CHECK (pickup_at IS NULL OR pickup_at >= requested_at),
    CHECK (dropoff_at IS NULL OR (pickup_at IS NOT NULL AND dropoff_at >= pickup_at)),
    CHECK ((status = 'COMPLETED' AND driver_id IS NOT NULL AND vehicle_id IS NOT NULL AND pickup_at IS NOT NULL AND dropoff_at IS NOT NULL AND distance_km IS NOT NULL AND duration_min IS NOT NULL AND fare_amount IS NOT NULL) OR status <> 'COMPLETED'),
    CHECK (status <> 'ONGOING' OR (driver_id IS NOT NULL AND vehicle_id IS NOT NULL AND pickup_at IS NOT NULL AND dropoff_at IS NULL))
);

CREATE TABLE payments (
    payment_id bigint PRIMARY KEY,
    trip_id bigint NOT NULL UNIQUE REFERENCES trips(trip_id) ON DELETE CASCADE,
    amount numeric(10,2) NOT NULL CHECK (amount >= 0),
    method varchar(10) NOT NULL CHECK (method IN ('UPI', 'CASH', 'CARD', 'WALLET')),
    payment_status varchar(10) NOT NULL CHECK (payment_status IN ('SUCCESS', 'FAILED', 'REFUNDED')),
    paid_at timestamptz NOT NULL
);

CREATE TABLE ratings (
    trip_id bigint NOT NULL REFERENCES trips(trip_id) ON DELETE CASCADE,
    rated_by varchar(6) NOT NULL CHECK (rated_by IN ('RIDER', 'DRIVER')),
    stars smallint NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment text,
    created_at timestamptz NOT NULL,
    PRIMARY KEY (trip_id, rated_by)
);
