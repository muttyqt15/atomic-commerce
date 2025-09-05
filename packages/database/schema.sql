-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- Needed for gen_random_uuid()

-- =====================================
-- STORES
-- =====================================
CREATE TABLE stores (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        name VARCHAR(150) NOT NULL,
                        domain VARCHAR(255), -- optional: store domain (e.g., shop.brand.com)
                        is_active BOOLEAN DEFAULT TRUE,
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- USERS
-- =====================================
CREATE TABLE users (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
                       name VARCHAR(100) NOT NULL,
                       email VARCHAR(255) NOT NULL,
                       password_hash TEXT NOT NULL,
                       role VARCHAR(20) NOT NULL DEFAULT 'customer', -- 'customer', 'admin'
                       created_at TIMESTAMP DEFAULT NOW(),
                       updated_at TIMESTAMP DEFAULT NOW(),
                       UNIQUE (store_id, email)
);

-- =====================================
-- MERCH DROPS
-- =====================================
CREATE TABLE merch_drops (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
                             name VARCHAR(150) NOT NULL,
                             description TEXT,
                             start_time TIMESTAMP NOT NULL,
                             end_time TIMESTAMP,
                             is_active BOOLEAN DEFAULT FALSE,
                             created_at TIMESTAMP DEFAULT NOW(),
                             updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- PRODUCTS
-- =====================================
CREATE TABLE products (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          drop_id UUID NOT NULL REFERENCES merch_drops(id) ON DELETE CASCADE,
                          name VARCHAR(150) NOT NULL,
                          description TEXT,
                          price_cents INT NOT NULL CHECK (price_cents > 0),
                          image_url TEXT,
                          created_at TIMESTAMP DEFAULT NOW(),
                          updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- PRODUCT VARIANTS
-- =====================================
CREATE TABLE product_variants (
                                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
                                  size VARCHAR(50),
                                  color VARCHAR(50),
                                  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
                                  created_at TIMESTAMP DEFAULT NOW(),
                                  updated_at TIMESTAMP DEFAULT NOW(),
                                  UNIQUE (product_id, size, color)
);

-- =====================================
-- ORDERS
-- =====================================
CREATE TABLE orders (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
                        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                        drop_id UUID NOT NULL REFERENCES merch_drops(id) ON DELETE CASCADE,
                        status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'shipped', 'cancelled'
                        total_cents INT NOT NULL CHECK (total_cents >= 0),
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- ORDER ITEMS
-- =====================================
CREATE TABLE order_items (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
                             product_variant_id UUID NOT NULL REFERENCES product_variants(id),
                             quantity INT NOT NULL CHECK (quantity > 0),
                             price_cents INT NOT NULL CHECK (price_cents > 0), -- snapshot at time of purchase
                             created_at TIMESTAMP DEFAULT NOW(),
                             updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- PAYMENTS
-- =====================================
CREATE TABLE payments (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
                          provider VARCHAR(50),        -- 'stripe', 'paypal', etc.
                          amount_cents INT NOT NULL CHECK (amount_cents >= 0),
                          status VARCHAR(20) NOT NULL, -- 'pending', 'paid', 'failed'
                          transaction_id TEXT NOT NULL,
                          created_at TIMESTAMP DEFAULT NOW(),
                          updated_at TIMESTAMP DEFAULT NOW(),
                          UNIQUE (transaction_id)
);

-- =====================================
-- IDEMPOTENCY KEYS (FOR SAFE RETRIES)
-- =====================================
CREATE TABLE idempotency_keys (
                                  key TEXT PRIMARY KEY,
                                  created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================
-- INDEXES
-- =====================================
CREATE INDEX idx_products_drop_id ON products(drop_id);
CREATE INDEX idx_variants_product_id ON product_variants(product_id);
CREATE INDEX idx_orders_store_id ON orders(store_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
