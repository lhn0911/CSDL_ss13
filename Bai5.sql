-- 1
CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL -- Số dư quỹ công ty
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,   -- Tên nhân viên
    salary DECIMAL(10,2) NOT NULL    -- Lương nhân viên
);

CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,                      -- ID nhân viên (FK)
    salary DECIMAL(10,2) NOT NULL,   -- Lương được nhận
    pay_date DATE NOT NULL,          -- Ngày nhận lương
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE transaction_log (
	log_id int primary key auto_increment,
    log_message text not null,
    log_time timestamp default current_timestamp
);
INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);
-- 3
ALTER TABLE employees
ADD COLUMN last_pay_date DATE;
-- 4
DELIMITER //

CREATE PROCEDURE process_payroll_with_logs(
    IN p_emp_id INT
)
BEGIN
    DECLARE emp_salary DECIMAL(10,2);
    DECLARE company_balance DECIMAL(15,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        INSERT INTO transaction_log (log_message) 
        VALUES ('Lỗi hệ thống khi xử lý lương');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred during payroll processing';
    END;

    START TRANSACTION;

    -- Check if employee exists
    SELECT salary INTO emp_salary
    FROM employees 
    WHERE emp_id = p_emp_id;

    IF emp_salary IS NULL THEN
        INSERT INTO transaction_log (log_message) 
        VALUES (CONCAT('Nhân viên không tồn tại - ID: ', p_emp_id));
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee not found';
    END IF;

    -- Check company funds
    SELECT balance INTO company_balance
    FROM company_funds 
    WHERE fund_id = 1 
    FOR UPDATE;

    IF company_balance < emp_salary THEN
        INSERT INTO transaction_log (log_message) 
        VALUES (CONCAT('Quỹ không đủ tiền để trả lương cho nhân viên ID: ', p_emp_id));
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds in company account';
    END IF;

    -- Process payroll
    UPDATE company_funds 
    SET balance = balance - emp_salary 
    WHERE fund_id = 1;

    INSERT INTO payroll (emp_id, salary, pay_date) 
    VALUES (p_emp_id, emp_salary, CURDATE());

    UPDATE employees 
    SET last_pay_date = CURDATE()
    WHERE emp_id = p_emp_id;

    INSERT INTO transaction_log (log_message) 
    VALUES (CONCAT('Chuyển lương cho nhân viên thành công - ID: ', p_emp_id));

    COMMIT;

END //

DELIMITER ;
-- 5
SELECT * FROM company_funds;
SELECT * FROM employees;
SELECT * FROM payroll;
SELECT * FROM transaction_log;
CALL process_payroll_with_logs(1);
CALL process_payroll_with_logs(999);
UPDATE company_funds SET balance = 1000 WHERE fund_id = 1;
CALL process_payroll_with_logs(2);
SELECT * FROM company_funds;
SELECT * FROM employees;
SELECT * FROM payroll;
SELECT * FROM transaction_log;
