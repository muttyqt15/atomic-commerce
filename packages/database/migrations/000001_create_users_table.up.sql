CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Needed for gen_random_uuid()

CREATE TYPE user_role AS ENUM ('admin', 'customer');

CREATE TABLE users (
    id            UUID PRIMARY KEY             DEFAULT gen_random_uuid(),
    name          varchar(100)        NOT NULL,
    email         varchar(255) UNIQUE NOT NULL,
    password_hash varchar(255)        NOT NULL,
    is_active     BOOLEAN             NOT NULL DEFAULT TRUE,
    role          user_role           NOT NULL DEFAULT 'customer',
    created_at    TIMESTAMP                    DEFAULT NOW(),
    updated_at    TIMESTAMP                    DEFAULT NOW()
);