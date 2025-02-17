-- 1
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(50),
    price DECIMAL(10,2),
    stock INT NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    quantity INT NOT NULL,
    total_price DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO products (product_name, price, stock) VALUES
('Laptop Dell', 1500.00, 10),
('iPhone 13', 1200.00, 8),
('Samsung TV', 800.00, 5),
('AirPods Pro', 250.00, 20),
('MacBook Air', 1300.00, 7);
-- 2
DELIMITER //

CREATE PROCEDURE process_order(
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE current_stock INT;
    DECLARE product_price DECIMAL(10,2);
    DECLARE total DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred during order processing';
    END;

    START TRANSACTION;

    SELECT stock, price 
    INTO current_stock, product_price
    FROM products 
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF current_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product not found';
    END IF;

    IF current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    SET total = product_price * p_quantity;

    INSERT INTO orders (product_id, quantity, total_price)
    VALUES (p_product_id, p_quantity, total);

    UPDATE products 
    SET stock = stock - p_quantity
    WHERE product_id = p_product_id;

    COMMIT;

END //

DELIMITER ;
-- 3
CALL process_order(1, 2);
CALL process_order(3, 10);
CALL process_order(999, 1);
SELECT * FROM orders;
SELECT * FROM products;