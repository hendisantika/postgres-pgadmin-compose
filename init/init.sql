-- Sample database initialization script
-- This script runs automatically on first container startup

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS app;

-- Users table
CREATE TABLE app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE app.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE app.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category_id INTEGER REFERENCES app.categories(id),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE app.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app.users(id),
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    shipping_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE app.order_items (
    id SERIAL PRIMARY KEY,
    order_id UUID REFERENCES app.orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES app.products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON app.users(email);
CREATE INDEX idx_users_username ON app.users(username);
CREATE INDEX idx_products_category ON app.products(category_id);
CREATE INDEX idx_orders_user ON app.orders(user_id);
CREATE INDEX idx_orders_status ON app.orders(status);
CREATE INDEX idx_order_items_order ON app.order_items(order_id);

-- Insert sample categories
INSERT INTO app.categories (name, description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Apparel and fashion items'),
    ('Books', 'Physical and digital books'),
    ('Home & Garden', 'Home decor and gardening supplies'),
    ('Sports', 'Sports equipment and accessories');

-- Insert sample users (passwords are hashed 'password123')
INSERT INTO app.users (username, email, password_hash, full_name) VALUES
    ('johndoe', 'john.doe@example.com', '$2a$10$XQxBtVx5pYqKOqKMvKQz8OxKzCxXQxBtVx5pYqKO', 'John Doe'),
    ('janedoe', 'jane.doe@example.com', '$2a$10$YRyCtWy6qZrLPrLNwLRz9PyLzDyCtWy6qZrLPrLN', 'Jane Doe'),
    ('bobsmith', 'bob.smith@example.com', '$2a$10$ZSzDuXz7rAsNQsNOxNSz0QzNzEzDuXz7rAsNQsNO', 'Bob Smith');

-- Insert sample products
INSERT INTO app.products (name, description, price, stock_quantity, category_id) VALUES
    ('Smartphone X', 'Latest smartphone with advanced features', 999.99, 50, 1),
    ('Laptop Pro', '15-inch professional laptop', 1499.99, 30, 1),
    ('Wireless Earbuds', 'Noise-cancelling wireless earbuds', 199.99, 100, 1),
    ('Cotton T-Shirt', 'Comfortable cotton t-shirt', 29.99, 200, 2),
    ('Denim Jeans', 'Classic blue denim jeans', 59.99, 150, 2),
    ('Running Shoes', 'Lightweight running shoes', 89.99, 75, 2),
    ('PostgreSQL Guide', 'Complete guide to PostgreSQL', 49.99, 40, 3),
    ('Docker Handbook', 'Learn Docker from scratch', 39.99, 60, 3),
    ('Garden Tool Set', '5-piece garden tool set', 45.99, 25, 4),
    ('Indoor Plant Pot', 'Ceramic indoor plant pot', 24.99, 80, 4),
    ('Yoga Mat', 'Non-slip yoga mat', 35.99, 90, 5),
    ('Dumbbell Set', 'Adjustable dumbbell set', 149.99, 20, 5);

-- Insert sample orders
INSERT INTO app.orders (user_id, total_amount, status, shipping_address)
SELECT
    u.id,
    299.98,
    'completed',
    '123 Main St, City, Country'
FROM app.users u WHERE u.username = 'johndoe';

INSERT INTO app.orders (user_id, total_amount, status, shipping_address)
SELECT
    u.id,
    89.98,
    'pending',
    '456 Oak Ave, Town, Country'
FROM app.users u WHERE u.username = 'janedoe';

-- Insert sample order items
INSERT INTO app.order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.id,
    p.id,
    1,
    p.price
FROM app.orders o
JOIN app.users u ON o.user_id = u.id
JOIN app.products p ON p.name = 'Wireless Earbuds'
WHERE u.username = 'johndoe';

INSERT INTO app.order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.id,
    p.id,
    1,
    p.price
FROM app.orders o
JOIN app.users u ON o.user_id = u.id
JOIN app.products p ON p.name = 'Cotton T-Shirt'
WHERE u.username = 'janedoe';

INSERT INTO app.order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.id,
    p.id,
    1,
    p.price
FROM app.orders o
JOIN app.users u ON o.user_id = u.id
JOIN app.products p ON p.name = 'Denim Jeans'
WHERE u.username = 'janedoe';

-- Create a view for order summary
CREATE VIEW app.order_summary AS
SELECT
    o.id AS order_id,
    u.username,
    u.email,
    o.total_amount,
    o.status,
    o.created_at AS order_date,
    COUNT(oi.id) AS total_items
FROM app.orders o
JOIN app.users u ON o.user_id = u.id
LEFT JOIN app.order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.username, u.email, o.total_amount, o.status, o.created_at;

-- Create a function to update timestamp
CREATE OR REPLACE FUNCTION app.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON app.products
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON app.orders
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at();

-- Grant permissions
GRANT USAGE ON SCHEMA app TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO PUBLIC;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO PUBLIC;

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '=== Database Initialization Complete ===';
    RAISE NOTICE 'Schema: app';
    RAISE NOTICE 'Tables: users, categories, products, orders, order_items';
    RAISE NOTICE 'Sample data inserted successfully';
END $$;
