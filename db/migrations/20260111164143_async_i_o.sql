-- +goose Up
-- +goose StatementBegin
SHOW io_method;
ALTER SYSTEM SET io_method = 'io_uring';
SELECT pg_reload_conf();

SHOW io_method;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
SELECT 'down SQL query';
-- +goose StatementEnd
