-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS products_audit_demo (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    stock INT DEFAULT 0
);

ALTER TABLE products_audit_demo ADD CONSTRAINT  products_name_unique UNIQUE (name);

INSERT INTO products_audit_demo (name, price, stock) VALUES 
('Laptop', 15000000, 50),
('Mouse', 250000, 200),
('Keyboard', 500000, 150);

-- UPDATE dengan OLD/NEW values
UPDATE products_audit_demo 
SET price = price * 1.10
WHERE price < 1000000
RETURNING 
    id,
    name,
    old.price AS price_before,
    new.price AS price_after,
    new.price - old.price AS price_diff;

-- DELETE dengan OLD values
DELETE FROM products_audit_demo 
WHERE stock < 100
RETURNING 
    old.id,
    old.name AS deleted_name,
    old.price AS deleted_price,
    old.stock AS deleted_stock;

-- INSERT ON CONFLICT (Upsert) dengan change tracking
INSERT INTO products_audit_demo (id, name, price, stock)
VALUES (uuidv7(), 'Laptop', 16000000, 60)
ON CONFLICT (name) DO UPDATE 
SET price = EXCLUDED.price, stock = EXCLUDED.stock
RETURNING 
    id,
    name,
    old.price AS prev_price,
    new.price AS curr_price,
    old.stock AS prev_stock,
    new.stock AS curr_stock,
    (old.price IS NULL) AS is_new_record;

-- Audit log otomatis dengan RETURNING OLD/NEW
CREATE TABLE IF NOT EXISTS audit_log_v18 (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    table_name VARCHAR(100),
    record_id UUID,
    action VARCHAR(10),
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function untuk audit dengan RETURNING
CREATE OR REPLACE FUNCTION audit_product_update(
    p_id UUID,
    p_new_price DECIMAL,
    p_new_stock INT
)
RETURNS TABLE (
    record_id UUID,
    price_before DECIMAL,
    price_after DECIMAL,
    stock_before INT,
    stock_after INT
) AS $$
DECLARE
    v_old_price DECIMAL;
    v_old_stock INT;
    v_new_price DECIMAL;
    v_new_stock INT;
BEGIN
    UPDATE products_audit_demo
    SET price = p_new_price, stock = p_new_stock
    WHERE id = p_id
    RETURNING 
        id, old.price, new.price, old.stock, new.stock
    INTO record_id, v_old_price, v_new_price, v_old_stock, v_new_stock;
    
    -- Log ke audit table
    INSERT INTO audit_log_v18 (table_name, record_id, action, old_data, new_data)
    VALUES (
        'products_audit_demo',
        p_id,
        'UPDATE',
        jsonb_build_object('price', v_old_price, 'stock', v_old_stock),
        jsonb_build_object('price', v_new_price, 'stock', v_new_stock)
    );
    
    price_before := v_old_price;
    price_after := v_new_price;
    stock_before := v_old_stock;
    stock_after := v_new_stock;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS audit_product_update(UUID, DECIMAL, INT);
DROP TABLE IF EXISTS audit_log_v18;
DROP TABLE IF EXISTS products_audit_demo;
-- +goose StatementEnd