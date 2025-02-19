use ss13;
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

CREATE TABLE transaction_log(
	log_id INT PRIMARY KEY AUTO_INCREMENT,
    log_message TEXT NOT NULL,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2
CREATE TABLE banks(
	bank_id INT PRIMARY KEY AUTO_INCREMENT,
    bank_name VARCHAR(255) NOT NULL,
    status ENUM('ACTIVE', 'ERROR') NOT NULL DEFAULT 'ACTIVE'
);

INSERT INTO employees (emp_name, salary) VALUES
('Nguyễn Văn An', 5000.00),
('Trần Thị Bốn', 4000.00),
('Lê Văn Cường', 3500.00),
('Hoàng Thị Dung', 4500.00),
('Phạm Văn Em', 3800.00);

-- 3
INSERT INTO banks (bank_name, status) VALUES 
('VietinBank', 'ACTIVE'),   
('Sacombank', 'ERROR'),    
('Agribank', 'ACTIVE');

-- 4
ALTER TABLE company_funds
ADD bank_id INT;
ALTER TABLE company_funds
ADD FOREIGN KEY (bank_id) REFERENCES banks(bank_id);

-- 5
INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,1);
SET SQL_SAFE_UPDATES = 0;
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;
INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);

-- 6
DELIMITER //
CREATE TRIGGER CheckBankStatus
BEFORE INSERT ON payroll
FOR EACH ROW
BEGIN
	DECLARE v_statusBank ENUM('ACTIVE', 'ERROR');
    DECLARE v_bankID INT;
    SELECT bank_id FROM company_funds INTO v_bankID;
    SELECT status FROM banks WHERE bank_id = v_bankID INTO v_statusBank;
    IF v_statusBank = 'ERROR' THEN
		SIGNAL SQLSTATE '45000'
        SET message_text = 'ERROR';
	END IF;
END;
// DELIMITER ;

-- 7
DELIMITER //
CREATE PROCEDURE TransferSalary(IN p_emp_id INT)
BEGIN
    DECLARE v_balanceOfCompany DECIMAL(15, 2);
    DECLARE v_employeeCount INT;
    DECLARE v_bankOfCompany INT;
    DECLARE v_statusBank ENUM('ACTIVE', 'ERROR');
    DECLARE v_salaryOfEmployee DECIMAL(10, 2);
    START TRANSACTION;
    SELECT COUNT(emp_id) INTO v_employeeCount FROM employees WHERE emp_id = p_emp_id;
    IF v_employeeCount = 0 THEN
        ROLLBACK;
        INSERT INTO transaction_log(log_message) VALUES ('Nhân viên không tồn tại');
    END IF;
    SELECT balance INTO v_balanceOfCompany FROM company_funds LIMIT 1;
    SELECT bank_id INTO v_bankOfCompany FROM company_funds LIMIT 1;
    SELECT status INTO v_statusBank FROM banks WHERE bank_id = v_bankOfCompany;
    IF v_statusBank = 'ERROR' THEN
        ROLLBACK;
        INSERT INTO transaction_log(log_message) VALUES ('Lỗi ngân hàng, không thể trả lương');
    END IF;
    SELECT salary INTO v_salaryOfEmployee FROM employees WHERE emp_id = p_emp_id;
    IF v_balanceOfCompany < v_salaryOfEmployee THEN
        ROLLBACK;
        INSERT INTO transaction_log(log_message) VALUES ('Không đủ tiền để trả lương');
    END IF;
    UPDATE company_funds SET balance = balance - v_salaryOfEmployee;
    INSERT INTO payroll(emp_id, salary, pay_date) VALUES (p_emp_id, v_salaryOfEmployee, CURRENT_DATE());
    COMMIT;
END;
// DELIMITER ;


-- 8
CALL TransferSalary(1);