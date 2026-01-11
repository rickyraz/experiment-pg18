-- +goose Up
-- +goose StatementBegin
-- Room booking - tidak boleh overlap
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE room_bookings (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    room_id INT NOT NULL,
    booking_period TSTZRANGE NOT NULL,
    guest_name VARCHAR(100) NOT NULL,
    
    CONSTRAINT room_bookings_no_overlap 
        UNIQUE (room_id, booking_period WITHOUT OVERLAPS)
);
-- Temporal PRIMARY KEY - room_id + period tidak boleh overlap

-- Insert bookings
INSERT INTO room_bookings (room_id, booking_period, guest_name) VALUES
(101, '[2025-01-10, 2025-01-15)', 'John Doe'),
(101, '[2025-01-15, 2025-01-20)', 'Jane Smith'),  -- OK, tidak overlap
(102, '[2025-01-10, 2025-01-18)', 'Bob Wilson');

-- Ini akan ERROR karena overlap dengan John Doe
-- INSERT INTO room_bookings (room_id, booking_period, guest_name) VALUES
-- (101, '[2025-01-12, 2025-01-17)', 'Conflict Guest');

-- Employee assignments - satu employee tidak boleh double assignment
CREATE TABLE employee_assignments (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    employee_id UUID NOT NULL,
    project_id UUID NOT NULL,
    assignment_period DATERANGE NOT NULL,
    role VARCHAR(50),
    
    UNIQUE (employee_id, assignment_period WITHOUT OVERLAPS)
);
-- Satu employee tidak bisa di 2 project bersamaan

-- Price history - harga berlaku untuk period tertentu
CREATE TABLE product_prices (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    product_id UUID NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    valid_period TSTZRANGE NOT NULL,
    
    UNIQUE (product_id, valid_period WITHOUT OVERLAPS)
);
-- Satu product hanya punya 1 harga per waktu

-- Insert price history
INSERT INTO product_prices (product_id, price, valid_period) VALUES
('a1b2c3d4-0000-0000-0000-000000000001', 100000, '[2025-01-01, 2025-03-01)'),
('a1b2c3d4-0000-0000-0000-000000000001', 120000, '[2025-03-01, 2025-06-01)'),
('a1b2c3d4-0000-0000-0000-000000000001', 110000, '[2025-06-01, infinity)');

-- INSERT INTO product_prices (product_id, price, valid_period) VALUES
-- ('a1b2c3d4-0000-0000-0000-000000000001', 500000, '[2025-01-02, 2025-02-06)');

-- Query harga saat ini
SELECT * FROM product_prices
WHERE product_id = 'a1b2c3d4-0000-0000-0000-000000000001'
  AND valid_period @> NOW();

-- Temporal FOREIGN KEY
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    customer_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    subscription_period TSTZRANGE NOT NULL,
    
    UNIQUE (customer_id, subscription_period WITHOUT OVERLAPS)
);

CREATE TABLE subscription_usage (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    customer_id UUID NOT NULL,
    usage_period TSTZRANGE NOT NULL,
    amount DECIMAL(15,2),
    
    FOREIGN KEY (customer_id, PERIOD usage_period) 
        REFERENCES subscriptions (customer_id, PERIOD subscription_period)
);
-- FK temporal - usage harus dalam subscription period

-- Insert subscription dan usage
-- subscription_period: [==========1 Jan 2025 - 31 Des 2025==========]
-- usage_period:              [===Mar 2025===]  ← ✅ Ada di dalam

-- subscription_period: [==========1 Jan 2025 - 31 Des 2025==========]
-- usage_period:                                      [===Jun 2026===]  ← ❌ Di luar
-- PERIOD = "Pastikan waktu pemakaian masih dalam waktu langganan aktif"

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS subscription_usage;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS product_prices;
DROP TABLE IF EXISTS employee_assignments;
DROP TABLE IF EXISTS room_bookings;
DROP EXTENSION IF EXISTS btree_gist;
-- +goose StatementEnd
