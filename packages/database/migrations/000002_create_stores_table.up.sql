CREATE TABLE stores
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        varchar(100) NOT NULL,
    domain      varchar(100),
    description varchar(255) NOT NULL,
    created_at  TIMESTAMP        DEFAULT NOW(),
    updated_at  TIMESTAMP        DEFAULT NOW(),

    admin_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE products
(
    id          UUID PRIMARY KEY        DEFAULT gen_random_uuid(),
    name        varchar(100)   NOT NULL,
    description varchar(255)   NOT NULL,
    price       NUMERIC(12, 2) NOT NULL DEFAULT 0,
    stock       INT            NOT NULL DEFAULT 0,
    created_at  TIMESTAMP               DEFAULT NOW(),
    updated_at  TIMESTAMP               DEFAULT NOW(),

    store_id    UUID           NOT NULL REFERENCES stores (id) ON DELETE CASCADE
);