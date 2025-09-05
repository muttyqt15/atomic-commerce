CREATE TYPE order_status AS ENUM('pending', 'paid', 'fulfilled');

CREATE TABLE idempotency_keys -- so that people won't be able to spam retries and make duplicate orders
(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key        VARCHAR(255) UNIQUE NOT NULL,
    used_for   VARCHAR(50)         NOT NULL, -- e.g., 'order', 'payment'
    created_at TIMESTAMP        DEFAULT NOW(),

    user_id    UUID REFERENCES users (id)
);

CREATE TABLE orders
(
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quantity           INT            NOT NULL,
    total_price        NUMERIC(10, 2) NOT NULL,
    status             VARCHAR(50)      DEFAULT 'pending',
    created_at         TIMESTAMP        DEFAULT NOW(),
    updated_at         TIMESTAMP        DEFAULT NOW(),

    user_id            UUID           NOT NULL REFERENCES users (id),
    product_id         UUID           NOT NULL REFERENCES products (id),
    store_id           UUID           NOT NULL REFERENCES stores (id),
    idempotency_key_id UUID           NOT NULL REFERENCES idempotency_keys (id),

    CONSTRAINT uq_order UNIQUE (user_id, product_id, idempotency_key_id)
);

CREATE TABLE order_items
(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   UUID NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products (id),
    quantity   INT NOT NULL
);

CREATE TABLE payments
(
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount             NUMERIC(10, 2) NOT NULL,
    method             VARCHAR(50),
    status             VARCHAR(50)      DEFAULT 'pending',
    created_at         TIMESTAMP        DEFAULT NOW(),
    updated_at         TIMESTAMP        DEFAULT NOW(),

    idempotency_key_id UUID           NOT NULL REFERENCES idempotency_keys (id),
    order_id           UUID           NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT uq_payment UNIQUE (order_id, idempotency_key_id)
);