USE ss13;

-- Bảng quỹ công ty
CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY AUTO_INCREMENT,
    balance DECIMAL(15,2) NOT NULL
);

-- Bảng nhân viên
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL
);

-- Bảng lương
CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    salary DECIMAL(10,2) NOT NULL,
    pay_date DATE NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Bảng log giao dịch
CREATE TABLE transaction_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    log_message TEXT NOT NULL,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng ngân hàng
CREATE TABLE banks (
    bank_id INT PRIMARY KEY AUTO_INCREMENT,
    bank_name VARCHAR(255) NOT NULL,
    status ENUM('ACTIVE', 'ERROR') NOT NULL DEFAULT 'ACTIVE'
);

-- Bảng tài khoản nhân viên
CREATE TABLE account (
    acc_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    bank_id INT,
    amount_added DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);

-- Thêm dữ liệu mẫu
INSERT INTO company_funds (balance) VALUES (50000.00);

INSERT INTO employees (emp_name, salary) VALUES 
('Nguyễn Văn A', 12000.00), 
('Trần Thị B', 9000.00);

INSERT INTO banks (bank_name) VALUES ('Vietcombank');

INSERT INTO account (emp_id, bank_id, amount_added, total_amount) VALUES
(1, 1, 0.00, 12500.00),  
(2, 1, 0.00, 8900.00);

-- Thủ tục chuyển lương
DELIMITER //

CREATE PROCEDURE TransferSalaryAll()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_emp_id INT;
    DECLARE v_salary DECIMAL(15,2);
    DECLARE v_company_balance DECIMAL(15,2);
    DECLARE v_total_paid INT DEFAULT 0;

    -- Con trỏ lấy danh sách nhân viên
    DECLARE cur CURSOR FOR SELECT emp_id, salary FROM employees;

    -- Bắt lỗi khi duyệt hết danh sách
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Lấy số dư quỹ công ty
    SELECT balance INTO v_company_balance FROM company_funds LIMIT 1;

    -- Nếu số dư không đủ, báo lỗi
    IF v_company_balance < (SELECT SUM(salary) FROM employees) THEN
        INSERT INTO transaction_log (log_message) VALUES ('FAILED: Not enough company funds');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough company funds';
    END IF;

    -- Bắt đầu giao dịch
    START TRANSACTION;

    -- Mở con trỏ
    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_emp_id, v_salary;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Trừ tiền từ quỹ công ty
        UPDATE company_funds SET balance = balance - v_salary;

        -- Ghi vào bảng payroll
        INSERT INTO payroll (emp_id, salary, pay_date) VALUES (v_emp_id, v_salary, NOW());

        -- Cập nhật tài khoản nhân viên
        UPDATE account 
        SET total_amount = total_amount + v_salary, 
            amount_added = v_salary 
        WHERE emp_id = v_emp_id;

        -- Đếm số nhân viên đã nhận lương
        SET v_total_paid = v_total_paid + 1;
    END LOOP;

    -- Đóng con trỏ
    CLOSE cur;

    -- Ghi log thành công
    INSERT INTO transaction_log (log_message) VALUES (CONCAT('SUCCESS: Paid salary to ', v_total_paid, ' employees'));

    -- Commit giao dịch
    COMMIT;
END //

DELIMITER ;

-- Gọi thủ tục
CALL TransferSalaryAll();

-- Kiểm tra dữ liệu
SELECT * FROM company_funds;
SELECT * FROM payroll;
SELECT * FROM account;
SELECT * FROM transaction_log;
