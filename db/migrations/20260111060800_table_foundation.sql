-- +goose Up
-- +goose StatementBegin
CREATE TABLE orders_v18 (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    customer_id UUID NOT NULL,
    total DECIMAL(15,2) NOT NULL
);
-- created_at tidak perlu, pakai uuid_extract_timestamp(id)

-- Virtual = computed saat read (tidak disimpan, hemat storage)
-- Stored = disimpan di disk (lebih cepat read, tapi butuh storage)

CREATE TABLE products_v18 (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name VARCHAR(255) NOT NULL,
    base_price DECIMAL(15,2) NOT NULL,
    tax_rate DECIMAL(5,4) DEFAULT 0.11,
    discount_pct DECIMAL(5,4) DEFAULT 0,
    
    tax_amount DECIMAL(15,2) GENERATED ALWAYS AS (base_price * tax_rate) STORED,
    discount_amount DECIMAL(15,2) GENERATED ALWAYS AS (base_price * discount_pct) STORED,
    final_price DECIMAL(15,2) GENERATED ALWAYS AS (base_price * (1 + tax_rate) * (1 - discount_pct)) STORED,
    
    search_slug VARCHAR(255) GENERATED ALWAYS AS (lower(replace(name, ' ', '-'))) STORED
);

-- VIRTUAL (default di PG18) - computed on read
-- STORED - jika sering diquery dan butuh index
-- Summary

-- KeywordPG                   12-17PG     18+
-- GENERATED ALWAYS AS (...)   = STORED    = VIRTUAL
-- GENERATED ALWAYS AS (...)   STORED✅    ✅
-- GENERATED ALWAYS AS (...)   VIRTUAL❌   Error✅


-- Index pada stored generated column
CREATE INDEX idx_products_slug ON products_v18(search_slug);

-- Inventory dengan virtual columns
CREATE TABLE inventory_v18 (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    product_id UUID NOT NULL,
    qty_on_hand INT NOT NULL DEFAULT 0,
    qty_reserved INT NOT NULL DEFAULT 0,
    unit_cost DECIMAL(15,4) DEFAULT 0,
    
    qty_available INT GENERATED ALWAYS AS (qty_on_hand - qty_reserved) STORED,
    total_value DECIMAL(15,2) GENERATED ALWAYS AS (qty_on_hand * unit_cost) STORED,
    is_low_stock BOOLEAN GENERATED ALWAYS AS (qty_on_hand - qty_reserved < 10) STORED
);
-- Virtual columns (default in PG18) not in 17 and below only stored

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS inventory_v18;
DROP TABLE IF EXISTS products_v18;
DROP TABLE IF EXISTS orders_v18;
-- +goose StatementEnd
