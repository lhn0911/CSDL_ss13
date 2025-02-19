CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_name VARCHAR(100),
    available_seats INT NOT NULL
);

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
CREATE TABLE enrollments_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    action VARCHAR(50),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
CREATE TABLE account (
    acc_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    bank_id INT,
    amount_added DECIMAL(15,2),
    total_amount DECIMAL(15,2),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);

INSERT INTO students (student_name) VALUES ('Nguyễn Văn An'), ('Trần Thị Ba');

INSERT INTO courses (course_name, available_seats) VALUES 
('Lập trình C', 25), 
('Cơ sở dữ liệu', 22);
-- 3

INSERT INTO account (emp_id, bank_id, amount_added, total_amount) VALUES

(1, 1, 0.00, 12500.00),  

(2, 1, 0.00, 8900.00),   

(3, 1, 0.00, 10200.00),  

(4, 1, 0.00, 15000.00),  

(5, 1, 0.00, 7600.00);
-- 4
DELIMITER //

CREATE PROCEDURE TransferSalaryAll()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_emp_id INT;
    DECLARE v_salary DECIMAL(15,2);
    DECLARE v_bank_id INT;
    DECLARE v_company_balance DECIMAL(15,2);
    DECLARE v_total_paid INT DEFAULT 0;
    
    -- Con trỏ để duyệt danh sách nhân viên
    DECLARE cur CURSOR FOR 
    SELECT emp_id, salary, bank_id FROM employees;
    
    -- Xử lý khi kết thúc vòng lặp con trỏ
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- Kiểm tra số dư quỹ công ty
    SELECT balance INTO v_company_balance FROM company_funds WHERE bank_id = (SELECT bank_id FROM company_funds LIMIT 1);
    
    -- Kiểm tra nếu không đủ tiền
    IF v_company_balance <= (SELECT SUM(salary) FROM employees) THEN
        INSERT INTO transaction_log (log_message) VALUES ('FAILED: Not enough company funds');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough company funds';
    END IF;
    
    -- Bắt đầu giao dịch
    START TRANSACTION;
    
    -- Mở con trỏ
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_emp_id, v_salary, v_bank_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Trừ tiền từ quỹ công ty
        UPDATE company_funds SET balance = balance - v_salary WHERE bank_id = v_bank_id;
        
        -- Thêm vào bảng payroll (Trigger sẽ kiểm tra trạng thái ngân hàng)
        INSERT INTO payroll (emp_id, amount, bank_id, pay_date) VALUES (v_emp_id, v_salary, v_bank_id, NOW());
        
        -- Cập nhật ngày trả lương của nhân viên
        UPDATE employees SET last_pay_date = NOW() WHERE emp_id = v_emp_id;
        
        -- Cập nhật tài khoản nhân viên
        UPDATE account 
        SET total_amount = total_amount + v_salary, amount_added = v_salary 
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
-- 5
CALL TransferSalaryAll();
-- 6
SELECT * FROM company_funds;
SELECT * FROM payroll;
SELECT * FROM account;
SELECT * FROM transaction_log;
