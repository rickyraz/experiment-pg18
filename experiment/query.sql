-- Generate UUIDv7
SELECT uuidv7();

-- Extract timestamp dari UUIDv7 (NATIVE PG18)
SELECT uuid_extract_timestamp(uuidv7());

-- uuidv4() sekarang alias untuk gen_random_uuid()
SELECT uuidv4();  -- sama dengan gen_random_uuid()

-- name: GetProduct :one
SELECT * FROM products_v18 WHERE id = $1;

-- name: ListProducts :many
SELECT * FROM products_v18 ORDER BY id LIMIT $1;

-- name: CreateProduct :one
INSERT INTO products_v18 (name, base_price, tax_rate, discount_pct)
VALUES ($1, $2, $3, $4)
RETURNING *;
