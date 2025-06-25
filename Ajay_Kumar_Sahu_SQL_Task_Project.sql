CREATE DATABASE IF NOT EXISTS workbook ;

USE workbook ;

CREATE TABLE college_courses (
    sr_no INT,
    district VARCHAR(100),
    taluka VARCHAR(100),
    college_name VARCHAR(255),
    university VARCHAR(255),
    college_type VARCHAR(100),
    course_name TEXT,
    course_type VARCHAR(100),
    is_professional VARCHAR(100),
    course VARCHAR(50),
    course_duration INT,
    course_category VARCHAR(100)
);

SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Workfile.csv'
INTO TABLE college_courses
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(sr_no, district, taluka, college_name, university, college_type, 
 course_name, course_type, is_professional, course, 
 course_duration, course_category);
 
  SELECT * FROM college_courses ;
  
  -- Count how many colleges offer professional courses in each district
SELECT 
    district, 
    COUNT(DISTINCT college_name) AS total_professional_colleges
FROM college_courses
WHERE is_professional = 'Professional Course'
GROUP BY district
ORDER BY total_professional_colleges DESC
LIMIT 5;

-- Calculate average duration for each course type
SELECT 
    course_type,
    ROUND(AVG(course_duration), 2) AS avg_duration_months
FROM college_courses
GROUP BY course_type
ORDER BY avg_duration_months DESC;

-- Count unique colleges offering each course category
SELECT 
    course_category,
    COUNT(DISTINCT college_name) AS total_colleges
FROM college_courses
GROUP BY course_category
ORDER BY total_colleges DESC;

-- Get colleges that offer both PG and UG courses
SELECT college_name
FROM college_courses
WHERE course_type IN ('Post Graduate Course', 'Under Graduate Course')
GROUP BY college_name
HAVING COUNT(DISTINCT course_type) = 2;

-- Find universities with more than 10 unaided and non-professional courses
SELECT 
    university,
    COUNT(*) AS total_courses
FROM college_courses
WHERE course = 'Unaided'
  AND is_professional = 'Non-Professional Course'
GROUP BY university
HAVING total_courses > 10
ORDER BY total_courses DESC;

-- Find colleges in 'Engineering' where at least one course is above average duration
SELECT DISTINCT college_name
FROM college_courses
WHERE course_category = 'Engineering'
  AND course_duration > (
      SELECT AVG(course_duration)
      FROM college_courses
      WHERE course_category = 'Engineering'
  );
  
  -- Rank courses within each college based on course duration (longest first)
SELECT 
    college_name,
    course_name,
    course_duration,
    RANK() OVER (
        PARTITION BY college_name
        ORDER BY course_duration DESC
    ) AS course_rank
FROM college_courses;

-- Show colleges where course duration gap is more than 24 months
SELECT 
    college_name,
    MAX(course_duration) AS max_duration,
    MIN(course_duration) AS min_duration,
    (MAX(course_duration) - MIN(course_duration)) AS duration_gap
FROM college_courses
GROUP BY college_name
HAVING duration_gap > 24;

-- List cumulative count of professional courses by university (A to Z)
SELECT 
    university,
    COUNT(*) AS professional_course_count,
    SUM(COUNT(*)) OVER (ORDER BY university) AS cumulative_total
FROM college_courses
WHERE is_professional = 'Professional Course'
GROUP BY university
ORDER BY university;


-- Use CTE to count distinct course categories per college
WITH category_count AS (
    SELECT 
        college_name, 
        COUNT(DISTINCT course_category) AS total_categories
    FROM college_courses
    GROUP BY college_name
)
SELECT college_name
FROM category_count
WHERE total_categories > 1;

-- Step 1: Calculate average course duration for each district
WITH district_avg_duration AS (
    SELECT 
        district,
        AVG(course_duration) AS district_avg
    FROM college_courses
    GROUP BY district
),




-- Step 2: Calculate average course duration for each taluka 
taluka_avg_duration AS (
    SELECT 
        district,
        taluka,
        AVG(course_duration) AS taluka_avg
    FROM college_courses
    GROUP BY district, taluka
)

-- Step 3: Compare taluka average with district average
SELECT 
    t.taluka,
    t.district,
    ROUND(t.taluka_avg, 2) AS taluka_avg_duration,
    ROUND(d.district_avg, 2) AS district_avg_duration
FROM taluka_avg_duration t
JOIN district_avg_duration d ON t.district = d.district
WHERE t.taluka_avg > d.district_avg
ORDER BY t.district, t.taluka_avg DESC;

-- Classify courses by duration and count them per course category
SELECT 
    course_category,
    
    CASE 
        WHEN course_duration < 12 THEN 'Short'
        WHEN course_duration BETWEEN 12 AND 36 THEN 'Medium'
        WHEN course_duration > 36 THEN 'Long'
        ELSE 'Unknown'
    END AS duration_type,
    
    COUNT(*) AS total_courses
FROM college_courses
GROUP BY course_category, duration_type
ORDER BY course_category, duration_type;

-- Extract specialization from course_name after the last dash (-)
SELECT 
    course_name,
    TRIM(SUBSTRING_INDEX(course_name, '-', -1)) AS specialization
FROM college_courses
WHERE course_name LIKE '%-%';

-- Count courses that have the word 'Engineering' in their name
SELECT 
    COUNT(*) AS total_engineering_courses
FROM college_courses
WHERE course_name LIKE '%Engineering%';

-- Show distinct combinations of course name, type, and category
SELECT DISTINCT 
    course_name,
    course_type,
    course_category
FROM college_courses
ORDER BY course_name;

-- Find courses that are not offered by any government college
SELECT DISTINCT course_name
FROM college_courses
WHERE college_type <> 'Government';

-- Find the university with the second-highest number of aided courses
SELECT university, total_aided_courses
FROM (
    SELECT 
        university,
        COUNT(*) AS total_aided_courses,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_num
    FROM college_courses
    WHERE course = 'Aided'
    GROUP BY university
) AS ranked_universities
WHERE rank_num = 2;

-- Find courses that have duration above the median
SELECT course_name, course_duration
FROM college_courses
WHERE course_duration > (
    SELECT course_duration
    FROM (
        SELECT course_duration,
               ROW_NUMBER() OVER (ORDER BY course_duration) AS row_num,
               COUNT(*) OVER () AS total_rows
        FROM college_courses
    ) AS ranked
    WHERE row_num = FLOOR((total_rows + 1) / 2)
);


-- Calculate percentage of unaided courses that are professional for each university
SELECT 
    university,
    ROUND(
        SUM(CASE WHEN is_professional = 'Professional Course' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 2
    ) AS professional_percentage
FROM college_courses
WHERE course = 'Unaided'
GROUP BY university
ORDER BY professional_percentage DESC;


-- Get top 3 course categories with highest average duration
SELECT 
    course_category,
    ROUND(AVG(course_duration), 2) AS avg_duration
FROM college_courses
GROUP BY course_category
ORDER BY avg_duration DESC
LIMIT 3;













 