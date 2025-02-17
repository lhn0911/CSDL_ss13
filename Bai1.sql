create database ss13;
use ss13;
-- 1
create table accounts(
account_id int primary key auto_increment,
account_name varchar(50) not null,
balance decimal(10,2) 
);
-- 2
INSERT INTO accounts (account_name, balance) VALUES 
('Nguyễn Văn An', 1000.00),
('Trần Thị Bảy', 500.00);
-- 3
DELIMITER //

CREATE PROCEDURE transfer_money(
    IN from_account INT,
    IN to_account INT,
    IN amount DECIMAL(10,2)
)
BEGIN
    DECLARE current_balance DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred during the transfer';
    END;

    START TRANSACTION;

    SELECT balance INTO current_balance 
    FROM accounts 
    WHERE account_id = from_account 
    FOR UPDATE;

    IF current_balance IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Source account not found';
    END IF;

    IF current_balance < amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = to_account) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Destination account not found';
    END IF;

    UPDATE accounts 
    SET balance = balance - amount 
    WHERE account_id = from_account;

    UPDATE accounts 
    SET balance = balance + amount 
    WHERE account_id = to_account;

    COMMIT;

END //

DELIMITER ;
-- 4
CALL transfer_money(1, 2, 200.00);
CALL transfer_money(1, 2, 2000.00);
CALL transfer_money(999, 1, 100.00);