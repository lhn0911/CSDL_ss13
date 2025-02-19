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
-- 4
DELIMITER //

CREATE PROCEDURE RegisterCourse(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_status ENUM('ACTIVE', 'GRADUATED', 'SUSPENDED');
    DECLARE v_available_seats INT;
    DECLARE exit HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra sinh viên có tồn tại không
    SELECT student_id INTO v_student_id FROM students WHERE student_name = p_student_name;
    IF v_student_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action) VALUES (NULL, NULL, 'FAILED: Student does not exist');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student does not exist';
    END IF;
    
    -- Kiểm tra môn học có tồn tại không
    SELECT course_id, available_seats INTO v_course_id, v_available_seats FROM courses WHERE course_name = p_course_name;
    IF v_course_id IS NULL THEN
        INSERT INTO enrollments_history (student_id, course_id, action) VALUES (v_student_id, NULL, 'FAILED: Course does not exist');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course does not exist';
    END IF;
    
    -- Kiểm tra sinh viên đã đăng ký môn học chưa
    IF EXISTS (SELECT 1 FROM enrollments WHERE student_id = v_student_id AND course_id = v_course_id) THEN
        INSERT INTO enrollments_history (student_id, course_id, action) VALUES (v_student_id, v_course_id, 'FAILED: Already enrolled');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Already enrolled';
    END IF;
    
    -- Kiểm tra trạng thái của sinh viên
    SELECT status INTO v_status FROM student_status WHERE student_id = v_student_id;
    IF v_status IN ('GRADUATED', 'SUSPENDED') THEN
        INSERT INTO enrollments_history (student_id, course_id, action) VALUES (v_student_id, v_course_id, 'FAILED: Student not eligible');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not eligible';
    END IF;
    
    -- Kiểm tra số chỗ trống của môn học
    IF v_available_seats <= 0 THEN
        INSERT INTO enrollments_history (student_id, course_id, action) VALUES (v_student_id, v_course_id, 'FAILED: No available seats');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available seats';
    END IF;
    
    -- Tiến hành đăng ký
    INSERT INTO enrollments (student_id, course_id) VALUES (v_student_id, v_course_id);
    UPDATE courses SET available_seats = available_seats - 1 WHERE course_id = v_course_id;
    INSERT INTO enrollments_history (student_id, course_id, action) VALUES (v_student_id, v_course_id, 'REGISTERED');
    
    COMMIT;
END //

DELIMITER ;

-- 5
CALL RegisterCourse('Nguyễn Văn An', 'Lập trình C');

-- 6
SELECT * FROM enrollments;
SELECT * FROM courses;
SELECT * FROM enrollments_history;
