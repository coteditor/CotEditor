-- SQL sample for tree-sitter highlighting/outline

CREATE SCHEMA app;

CREATE TABLE app.users (
    id BIGINT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON app.users (email);

CREATE VIEW app.active_users AS
SELECT id, name, email
FROM app.users
WHERE email IS NOT NULL;

CREATE TYPE app.user_state AS ENUM ('active', 'disabled');

CREATE OR REPLACE FUNCTION app.user_count()
RETURNS BIGINT
LANGUAGE sql
AS $$
    SELECT COUNT(*) FROM app.users;
$$;

CREATE OR REPLACE FUNCTION app.find_user(
    user_id INTEGER,
    state app.user_state,
    display_name TEXT DEFAULT 'guest',
    VARIADIC tags TEXT[]
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    SELECT user_id;
$$;

CREATE OR REPLACE PROCEDURE app.sync_users(
    INOUT count INTEGER,
    threshold DOUBLE PRECISION
)
LANGUAGE sql
AS $$
    SELECT count;
$$;

CREATE OR REPLACE PROCEDURE app.reset_scores()
LANGUAGE sql
AS $$
    UPDATE app.users
    SET score = 0;
$$;

ALTER TABLE app.users
ADD COLUMN score INT DEFAULT 0;

UPDATE app.users
SET score = score + 1
WHERE id = 1;

DELETE FROM app.users
WHERE email LIKE '%@example.com';

DROP VIEW IF EXISTS app.active_users;
