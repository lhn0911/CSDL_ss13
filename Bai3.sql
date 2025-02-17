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

INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);

-- 3
DELIMITER //

CREATE PROCEDURE process_payroll(
    IN p_emp_id INT
)
BEGIN
    DECLARE emp_salary DECIMAL(10,2);
    DECLARE company_balance DECIMAL(15,2);
    DECLARE bank_system_status BOOLEAN DEFAULT TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred during payroll processing';
    END;

    START TRANSACTION;

    SELECT salary INTO emp_salary
    FROM employees 
    WHERE emp_id = p_emp_id;

    IF emp_salary IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee not found';
    END IF;

    SELECT balance INTO company_balance
    FROM company_funds 
    WHERE fund_id = 1 
    FOR UPDATE;

    IF company_balance < emp_salary THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds in company account';
    END IF;

    SET bank_system_status = TRUE;
    
    IF NOT bank_system_status THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bank system error occurred';
    END IF;

    UPDATE company_funds 
    SET balance = balance - emp_salary 
    WHERE fund_id = 1;

    INSERT INTO payroll (emp_id, salary, pay_date) 
    VALUES (p_emp_id, emp_salary, CURDATE());

    COMMIT;

END //

DELIMITER ;
-- 4
SELECT * FROM company_funds;
SELECT * FROM employees;
SELECT * FROM payroll;
CALL process_payroll(1);
CALL process_payroll(999);
CALL process_payroll(1);
CALL process_payroll(2);
CALL process_payroll(3);
CALL process_payroll(4);
CALL process_payroll(5);
SELECT * FROM company_funds;
SELECT * FROM payroll;
