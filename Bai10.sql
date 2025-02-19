-- 1
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
CREATE TABLE student_status (
    student_id INT PRIMARY KEY,
    status ENUM('ACTIVE', 'GRADUATED', 'SUSPENDED') NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

INSERT INTO students (student_name) VALUES ('Nguyễn Văn An'), ('Trần Thị Ba');

INSERT INTO courses (course_name, available_seats) VALUES 
('Lập trình C', 25), 
('Cơ sở dữ liệu', 22);
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký
-- 2
CREATE TABLE course_fees (

    course_id INT PRIMARY KEY,

    fee DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE

);

CREATE TABLE student_wallets (

    student_id INT PRIMARY KEY,

    balance DECIMAL(10,2) NOT NULL DEFAULT 0,

    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE

);
-- 3
INSERT INTO course_fees (course_id, fee) VALUES

(1, 100.00), -- Lập trình C: 100$

(2, 150.00); -- Cơ sở dữ liệu: 150$

 

INSERT INTO student_wallets (student_id, balance) VALUES

(1, 200.00), -- Nguyễn Văn An có 200$

(2, 50.00);  -- Trần Thị Ba chỉ có 50$
-- 4
DELIMITER //

CREATE PROCEDURE AutoEnrollStudents(IN p_course_name VARCHAR(100))
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_balance DECIMAL(10,2);
    DECLARE v_available_seats INT;
    DECLARE done INT DEFAULT 0;

    -- Con trỏ để duyệt danh sách sinh viên chưa đăng ký
    DECLARE cur CURSOR FOR 
    SELECT student_id FROM students 
    WHERE student_id NOT IN (SELECT student_id FROM enrollments WHERE course_id = v_course_id);

    -- Xử lý lỗi con trỏ
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Lấy thông tin môn học
    SELECT course_id, available_seats INTO v_course_id, v_available_seats 
    FROM courses WHERE name = p_course_name;
    
    IF v_course_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course does not exist';
    END IF;

    -- Nếu không còn chỗ trống, thoát
    IF v_available_seats <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available seats';
    END IF;

    -- Mở con trỏ
    OPEN cur;

    -- Lặp qua danh sách sinh viên
    enroll_loop: LOOP
        FETCH cur INTO v_student_id;
        IF done = 1 THEN 
            LEAVE enroll_loop; 
        END IF;

        -- Kiểm tra số dư tài khoản sinh viên
        SELECT balance INTO v_balance FROM student_wallets WHERE student_id = v_student_id;
        SELECT fee INTO v_fee FROM course_fees WHERE course_id = v_course_id;

        -- Nếu sinh viên không đủ tiền -> bỏ qua sinh viên này
        IF v_balance < v_fee THEN
            INSERT INTO enrollment_history (student_id, course_id, status) 
            VALUES (v_student_id, v_course_id, 'FAILED: Insufficient balance');
            ITERATE enroll_loop; 
        END IF;

        -- Đăng ký môn học
        INSERT INTO enrollments (student_id, course_id, enrollment_date) 
        VALUES (v_student_id, v_course_id, NOW());

        -- Trừ tiền từ tài khoản sinh viên
        UPDATE student_wallets SET balance = balance - v_fee WHERE student_id = v_student_id;

        -- Giảm số lượng chỗ trống của môn học
        UPDATE courses SET available_seats = available_seats - 1 WHERE course_id = v_course_id;

        -- Ghi vào bảng lịch sử đăng ký
        INSERT INTO enrollment_history (student_id, course_id, status) 
        VALUES (v_student_id, v_course_id, 'REGISTERED');

    END LOOP;

    -- Đóng con trỏ
    CLOSE cur;

    -- Commit transaction
    COMMIT;
END //

DELIMITER ;

-- 5
CALL AutoEnrollStudents('Database Systems');

-- 6
SELECT * FROM student_wallets WHERE student_id = (SELECT student_id FROM students WHERE name = 'Nguyen Van A');
