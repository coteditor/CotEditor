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

CREATE OR REPLACE FUNCTION app.user_count()
RETURNS BIGINT
LANGUAGE sql
AS $$
    SELECT COUNT(*) FROM app.users;
$$;

ALTER TABLE app.users
ADD COLUMN score INT DEFAULT 0;

UPDATE app.users
SET score = score + 1
WHERE id = 1;

DELETE FROM app.users
WHERE email LIKE '%@example.com';

DROP VIEW IF EXISTS app.active_users;
