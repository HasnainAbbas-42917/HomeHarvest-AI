CREATE DATABASE IF NOT EXISTS homeharvest;
USE homeharvest;

CREATE TABLE IF NOT EXISTS users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100)        NOT NULL,
    email      VARCHAR(150) UNIQUE NOT NULL,
    phone      VARCHAR(20)         NOT NULL,
    password   VARCHAR(255)        NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(150)  NOT NULL,
    price      DECIMAL(10,2) NOT NULL,
    image_url  VARCHAR(500)  NOT NULL,
    category   VARCHAR(50)   NOT NULL,
    type       VARCHAR(50)   NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    order_number     VARCHAR(20)    NOT NULL UNIQUE,
    customer_name    VARCHAR(100)   NOT NULL,
    customer_email   VARCHAR(150)   NOT NULL,
    customer_phone   VARCHAR(20)    NOT NULL,
    delivery_address TEXT           NOT NULL,
    subtotal         DECIMAL(10,2)  NOT NULL,
    shipping         DECIMAL(10,2)  NOT NULL DEFAULT 150.00,
    total            DECIMAL(10,2)  NOT NULL,
    payment_method   VARCHAR(50)    NOT NULL DEFAULT 'Cash on Delivery',
    status           VARCHAR(30)    NOT NULL DEFAULT 'Pending',
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    order_id    INT           NOT NULL,
    name        VARCHAR(150)  NOT NULL,
    price       DECIMAL(10,2) NOT NULL,
    quantity    INT           NOT NULL,
    image_url   VARCHAR(500),
    category    VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS chat_history (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    role       VARCHAR(10)  NOT NULL,
    message    TEXT         NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    session_id INT          NOT NULL DEFAULT 1
);
