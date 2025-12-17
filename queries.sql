-- 1. Список студентов по определённому предмету (пример: Математика)
SELECT DISTINCT
    s.student_id,
    s.last_name,
    s.first_name,
    g.group_code
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings o ON o.offering_id = e.offering_id
JOIN subjects subj ON subj.subject_id = o.subject_id
JOIN study_groups g ON g.group_id = s.group_id
WHERE subj.subject_name = 'Математика';

-- 2. Список предметов, которые преподаёт конкретный преподаватель (Иванов)
SELECT DISTINCT
    subj.subject_name
FROM teachers t
JOIN course_offerings o ON o.teacher_id = t.teacher_id
JOIN subjects subj ON subj.subject_id = o.subject_id
WHERE t.last_name = 'Иванов';

-- 3. Средний балл студента по всем предметам (пример: S-001)
SELECT
    s.student_number,
    ROUND(AVG(gr.grade_value), 2) AS avg_grade
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN grades gr ON gr.enrollment_id = e.enrollment_id
WHERE s.student_number = 'S-001'
GROUP BY s.student_number;

-- 4. Рейтинг преподавателей по средней оценке студентов
SELECT
    t.last_name,
    ROUND(AVG(gr.grade_value), 2) AS avg_grade
FROM teachers t
JOIN course_offerings o ON o.teacher_id = t.teacher_id
JOIN enrollments e ON e.offering_id = o.offering_id
JOIN grades gr ON gr.enrollment_id = e.enrollment_id
GROUP BY t.teacher_id
ORDER BY avg_grade DESC;

-- 5. Преподаватели, которые преподавали более 3 предметов за последний учебный год
SELECT
    t.last_name,
    COUNT(DISTINCT o.subject_id) AS subject_count
FROM teachers t
JOIN course_offerings o ON o.teacher_id = t.teacher_id
JOIN terms tr ON tr.term_id = o.term_id
WHERE tr.academic_year = (SELECT MAX(academic_year) FROM terms)
GROUP BY t.teacher_id
HAVING COUNT(DISTINCT o.subject_id) > 3;

-- 6. Студенты с средним баллом >4 по математическим и <3 по гуманитарным предметам
SELECT
    s.student_number,
    s.last_name,
    s.first_name
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN grades g ON g.enrollment_id = e.enrollment_id
JOIN course_offerings o ON o.offering_id = e.offering_id
JOIN subjects subj ON subj.subject_id = o.subject_id
GROUP BY s.student_id
HAVING
    AVG(CASE WHEN subj.category = 'MATH' THEN g.grade_value END) > 4
    AND
    AVG(CASE WHEN subj.category = 'HUMANITIES' THEN g.grade_value END) < 3;

-- 7. Предметы с максимальным количеством двоек в текущем семестре
WITH current_term AS (
    SELECT term_id
    FROM terms
    ORDER BY academic_year DESC, semester_no DESC
    LIMIT 1
),
twos AS (
    SELECT
        o.subject_id,
        COUNT(*) AS cnt
    FROM grades g
    JOIN enrollments e ON e.enrollment_id = g.enrollment_id
    JOIN course_offerings o ON o.offering_id = e.offering_id
    WHERE g.grade_value = 2
      AND o.term_id = (SELECT term_id FROM current_term)
    GROUP BY o.subject_id
)
SELECT
    subj.subject_name,
    t.cnt
FROM twos t
JOIN subjects subj ON subj.subject_id = t.subject_id
WHERE t.cnt = (SELECT MAX(cnt) FROM twos);

-- 8. Студенты, получившие высший балл по всем экзаменам, и преподаватели этих предметов
WITH excellent_students AS (
    SELECT
        s.student_id
    FROM students s
    JOIN enrollments e ON e.student_id = s.student_id
    JOIN grades g ON g.enrollment_id = e.enrollment_id
    GROUP BY s.student_id
    HAVING MIN(g.grade_value) = 5 AND MAX(g.grade_value) = 5
)
SELECT DISTINCT
    s.student_number,
    subj.subject_name,
    t.last_name AS teacher_last_name
FROM excellent_students ex
JOIN students s ON s.student_id = ex.student_id
JOIN enrollments e ON e.student_id = s.student_id
JOIN course_offerings o ON o.offering_id = e.offering_id
JOIN subjects subj ON subj.subject_id = o.subject_id
JOIN teachers t ON t.teacher_id = o.teacher_id;

-- 9. Изменение среднего балла студента по годам обучения (пример: S-001)
SELECT
    s.student_number,
    tr.academic_year,
    ROUND(AVG(g.grade_value), 2) AS avg_grade
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
JOIN grades g ON g.enrollment_id = e.enrollment_id
JOIN course_offerings o ON o.offering_id = e.offering_id
JOIN terms tr ON tr.term_id = o.term_id
WHERE s.student_number = 'S-001'
GROUP BY s.student_number, tr.academic_year
ORDER BY tr.academic_year;

-- 10. Группы с наивысшим средним баллом по одинаковым предметам
WITH grp_avg AS (
    SELECT
        subj.subject_name,
        g.group_code,
        ROUND(AVG(gr.grade_value), 2) AS avg_grade
    FROM grades gr
    JOIN enrollments e ON e.enrollment_id = gr.enrollment_id
    JOIN course_offerings o ON o.offering_id = e.offering_id
    JOIN study_groups g ON g.group_id = o.group_id
    JOIN subjects subj ON subj.subject_id = o.subject_id
    GROUP BY subj.subject_name, g.group_code
),
ranked AS (
    SELECT
        subject_name,
        group_code,
        avg_grade,
        DENSE_RANK() OVER (PARTITION BY subject_name ORDER BY avg_grade DESC) AS rnk
    FROM grp_avg
)
SELECT
    subject_name,
    group_code,
    avg_grade
FROM ranked
WHERE rnk = 1
ORDER BY subject_name;

-- CRUD

-- Вставка нового студента
INSERT INTO students (student_number, last_name, first_name, birth_date, email, group_id)
SELECT 'S-005', 'Новиков', 'Сергей', '2004-07-01', 's5@stud.test', 1
WHERE NOT EXISTS (
    SELECT 1 FROM students WHERE student_number = 'S-005'
);

-- Обновление контактной информации преподавателя
UPDATE teachers
SET email = 'ivanov_new@uni.test'
WHERE teacher_number = 'T-001';

-- Удаление предмета без зависимостей (демонстрация учёта ограничений)
INSERT INTO subjects (subject_name, category)
SELECT 'Правоведение', 'HUMANITIES'
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE subject_name = 'Правоведение');

DELETE FROM subjects
WHERE subject_name = 'Правоведение';

-- Вставка новой оценки с указанием предмета, преподавателя и даты
INSERT INTO grades (enrollment_id, grade_value, grade_date)
SELECT
    e.enrollment_id,
    4,
    '2024-12-25'
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN course_offerings o ON o.offering_id = e.offering_id
JOIN subjects subj ON subj.subject_id = o.subject_id
JOIN teachers t ON t.teacher_id = o.teacher_id
LEFT JOIN grades g ON g.enrollment_id = e.enrollment_id
WHERE s.student_number = 'S-002'
  AND subj.subject_name = 'Экономика'
  AND t.teacher_number = 'T-002'
  AND g.enrollment_id IS NULL;

