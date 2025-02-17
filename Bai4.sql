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
INSERT INTO students (student_name) VALUES ('Nguyễn Văn An'), ('Trần Thị Ba');

INSERT INTO courses (course_name, available_seats) VALUES 
('Lập trình C', 25), 
('Cơ sở dữ liệu', 22);
-- 2
DELIMITER //

CREATE PROCEDURE enroll_student(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_available_seats INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An error occurred during enrollment';
    END;

    START TRANSACTION;

    SELECT student_id INTO v_student_id 
    FROM students 
    WHERE student_name = p_student_name;

    IF v_student_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student not found';
    END IF;

    SELECT course_id, available_seats INTO v_course_id, v_available_seats 
    FROM courses 
    WHERE course_name = p_course_name 
    FOR UPDATE;

    IF v_course_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Course not found';
    END IF;

    IF v_available_seats <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available seats in this course';
    END IF;

    IF EXISTS (
        SELECT 1 FROM enrollments 
        WHERE student_id = v_student_id AND course_id = v_course_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student already enrolled in this course';
    END IF;

    INSERT INTO enrollments (student_id, course_id)
    VALUES (v_student_id, v_course_id);

    UPDATE courses 
    SET available_seats = available_seats - 1
    WHERE course_id = v_course_id;

    COMMIT;

END //

DELIMITER ;
-- 3
SELECT * FROM courses;
SELECT * FROM enrollments;
CALL enroll_student('Nguyễn Văn An', 'Lập trình C');
CALL enroll_student('Nguyễn Văn An', 'Lập trình C');
CALL enroll_student('Nguyễn Văn XYZ', 'Lập trình C');
CALL enroll_student('Nguyễn Văn An', 'Khóa học XYZ');
UPDATE courses SET available_seats = 0 WHERE course_name = 'Cơ sở dữ liệu';
CALL enroll_student('Trần Thị Ba', 'Cơ sở dữ liệu');
SELECT * FROM courses;
SELECT * FROM enrollments;
