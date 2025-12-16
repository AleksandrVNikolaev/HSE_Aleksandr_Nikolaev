DROP DATABASE IF EXISTS education_db;
CREATE DATABASE education_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE education_db;

CREATE TABLE study_groups (
  group_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_code VARCHAR(20) NOT NULL,
  admission_year SMALLINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_study_groups_code (group_code)
) ENGINE=InnoDB;

CREATE TABLE students (
  student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_number VARCHAR(20) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  birth_date DATE NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  group_id INT UNSIGNED NOT NULL,

  UNIQUE KEY uq_students_number (student_number),
  UNIQUE KEY uq_students_email (email),
  KEY idx_students_group (group_id),

  CONSTRAINT fk_students_group
    FOREIGN KEY (group_id)
    REFERENCES study_groups(group_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE teachers (
  teacher_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  teacher_number VARCHAR(20) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  birth_date DATE,
  email VARCHAR(255),
  phone VARCHAR(50),

  UNIQUE KEY uq_teachers_number (teacher_number),
  UNIQUE KEY uq_teachers_email (email)
) ENGINE=InnoDB;

CREATE TABLE subjects (
  subject_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  subject_name VARCHAR(255) NOT NULL,
  category ENUM('MATH','HUMANITIES','OTHER') NOT NULL,
  UNIQUE KEY uq_subjects_name (subject_name)
) ENGINE=InnoDB;

CREATE TABLE terms (
  term_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  academic_year SMALLINT UNSIGNED NOT NULL,
  semester_no TINYINT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,

  CONSTRAINT chk_terms_semester CHECK (semester_no IN (1,2)),
  CONSTRAINT chk_terms_dates CHECK (start_date < end_date),
  UNIQUE KEY uq_terms_year_sem (academic_year, semester_no)
) ENGINE=InnoDB;

CREATE TABLE course_offerings (
  offering_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  subject_id INT UNSIGNED NOT NULL,
  teacher_id INT UNSIGNED NOT NULL,
  group_id INT UNSIGNED NOT NULL,
  term_id INT UNSIGNED NOT NULL,

  UNIQUE KEY uq_offerings (subject_id, group_id, term_id),

  CONSTRAINT fk_off_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
  CONSTRAINT fk_off_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
  CONSTRAINT fk_off_group FOREIGN KEY (group_id) REFERENCES study_groups(group_id),
  CONSTRAINT fk_off_term FOREIGN KEY (term_id) REFERENCES terms(term_id)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
  enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  offering_id INT UNSIGNED NOT NULL,
  enrolled_at DATE NOT NULL,

  UNIQUE KEY uq_enrollments (student_id, offering_id),

  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students(student_id),
  CONSTRAINT fk_enroll_offering FOREIGN KEY (offering_id) REFERENCES course_offerings(offering_id)
) ENGINE=InnoDB;

CREATE TABLE grades (
  grade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT UNSIGNED NOT NULL,
  grade_value TINYINT UNSIGNED NOT NULL,
  grade_date DATE NOT NULL,

  CONSTRAINT chk_grade_value CHECK (grade_value BETWEEN 1 AND 5),
  UNIQUE KEY uq_grades_enrollment (enrollment_id),

  CONSTRAINT fk_grades_enrollment
    FOREIGN KEY (enrollment_id)
    REFERENCES enrollments(enrollment_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

