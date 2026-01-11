-- +goose Up
-- +goose StatementBegin
-- Timestamp ke UUID minimum (untuk >= comparison)
CREATE OR REPLACE FUNCTION ts_to_uuid_min(ts TIMESTAMPTZ)
RETURNS UUID AS $$
DECLARE
    ms BIGINT;
    hex TEXT;
BEGIN
    ms := (EXTRACT(EPOCH FROM ts) * 1000)::BIGINT;
    hex := lpad(to_hex(ms), 12, '0');
    RETURN (
        substring(hex, 1, 8) || '-' || 
        substring(hex, 9, 4) || '-7000-8000-000000000000'
    )::UUID;
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
-- Timestamp ke UUID maximum (untuk < atau <= comparison)
CREATE OR REPLACE FUNCTION ts_to_uuid_max(ts TIMESTAMPTZ)
RETURNS UUID AS $$
DECLARE
    ms BIGINT;
    hex TEXT;
BEGIN
    ms := (EXTRACT(EPOCH FROM ts) * 1000)::BIGINT;
    hex := lpad(to_hex(ms), 12, '0');
    RETURN (
        substring(hex, 1, 8) || '-' || 
        substring(hex, 9, 4) || '-7fff-bfff-ffffffffffff'
    )::UUID;
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS ts_to_uuid_min(TIMESTAMPTZ);
DROP FUNCTION IF EXISTS ts_to_uuid_max(TIMESTAMPTZ);
-- +goose StatementEnd
