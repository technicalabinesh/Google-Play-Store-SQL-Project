-- Google Play Store MySQL Data Analysis Project
-- MySQL 8.0+
-- Run this script in MySQL Workbench.
-- This file creates the database, table, and analysis queries.
-- Import your cleaned CSV data into the apps table before running the analysis queries.

CREATE DATABASE IF NOT EXISTS app_store_db;
USE app_store_db;

CREATE TABLE IF NOT EXISTS apps (
    App             VARCHAR(255) NOT NULL,
    Category        VARCHAR(100),
    Rating          DECIMAL(3,2),
    Reviews         BIGINT UNSIGNED,
    Installs        BIGINT UNSIGNED,
    Type            VARCHAR(20),
    Price           DECIMAL(10,2),
    Content_Rating  VARCHAR(50),
    Genres          VARCHAR(255),
    Primary_Genre   VARCHAR(100),
    Last_Updated    DATE,
    Current_Ver     VARCHAR(100),
    Android_Ver     VARCHAR(100),
    Size_MB         DECIMAL(10,2),
    Min_Android     VARCHAR(50),
    PRIMARY KEY (App),
    CONSTRAINT chk_apps_rating CHECK (Rating IS NULL OR Rating BETWEEN 1 AND 5),
    CONSTRAINT chk_apps_price CHECK (Price IS NULL OR Price >= 0)
);

-- =========================================================
-- DATA QUALITY CHECKS
-- =========================================================

-- 1. Total rows
SELECT COUNT(*) AS total_apps
FROM apps;

-- 2. Missing values in key columns
SELECT
    SUM(App IS NULL OR TRIM(App) = '') AS missing_app_names,
    SUM(Category IS NULL OR TRIM(Category) = '') AS missing_categories,
    SUM(Rating IS NULL) AS missing_ratings,
    SUM(Reviews IS NULL) AS missing_reviews,
    SUM(Installs IS NULL) AS missing_installs
FROM apps;

-- 3. Check duplicate app names (the primary key prevents exact duplicates)
SELECT App, COUNT(*) AS row_count
FROM apps
GROUP BY App
HAVING COUNT(*) > 1;

-- =========================================================
-- BUSINESS ANALYSIS
-- =========================================================

-- 4. Apps by category
SELECT Category, COUNT(*) AS total_apps
FROM apps
GROUP BY Category
ORDER BY total_apps DESC;

-- 5. Average rating by category
SELECT
    Category,
    ROUND(AVG(Rating), 2) AS average_rating,
    COUNT(*) AS rated_apps
FROM apps
WHERE Rating BETWEEN 1 AND 5
GROUP BY Category
ORDER BY average_rating DESC;

-- 6. Top 10 apps by installs
SELECT App, Category, Installs, Rating
FROM apps
WHERE Installs IS NOT NULL
ORDER BY Installs DESC
LIMIT 10;

-- 7. Top 10 most-reviewed apps
SELECT App, Category, Reviews, Rating
FROM apps
WHERE Reviews IS NOT NULL
ORDER BY Reviews DESC
LIMIT 10;

-- 8. Free vs paid app comparison
SELECT
    Type,
    COUNT(*) AS total_apps,
    ROUND(AVG(Rating), 2) AS average_rating,
    ROUND(AVG(Price), 2) AS average_price
FROM apps
GROUP BY Type;

-- 9. Categories with the highest total installs
SELECT
    Category,
    SUM(Installs) AS total_installs
FROM apps
GROUP BY Category
ORDER BY total_installs DESC
LIMIT 10;

-- 10. Price analysis for paid apps
SELECT
    Category,
    COUNT(*) AS paid_apps,
    ROUND(AVG(Price), 2) AS average_price,
    ROUND(MAX(Price), 2) AS maximum_price
FROM apps
WHERE Type = 'Paid' AND Price > 0
GROUP BY Category
ORDER BY average_price DESC;

-- 11. Content rating distribution
SELECT Content_Rating, COUNT(*) AS total_apps
FROM apps
GROUP BY Content_Rating
ORDER BY total_apps DESC;

-- 12. Apps with high ratings and at least 100,000 reviews
SELECT App, Category, Rating, Reviews, Installs
FROM apps
WHERE Rating >= 4.5
  AND Reviews >= 100000
ORDER BY Rating DESC, Reviews DESC;

-- 13. Rank apps by installs within each category (MySQL 8.0+)
WITH ranked_apps AS (
    SELECT
        App,
        Category,
        Installs,
        Rating,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY Installs DESC
        ) AS install_rank
    FROM apps
    WHERE Installs IS NOT NULL
)
SELECT App, Category, Installs, Rating, install_rank
FROM ranked_apps
WHERE install_rank <= 3
ORDER BY Category, install_rank;

-- 14. Categories with above-average ratings (CTE)
WITH category_ratings AS (
    SELECT Category, AVG(Rating) AS avg_rating
    FROM apps
    WHERE Rating BETWEEN 1 AND 5
    GROUP BY Category
),
overall_rating AS (
    SELECT AVG(Rating) AS avg_rating
    FROM apps
    WHERE Rating BETWEEN 1 AND 5
)
SELECT
    cr.Category,
    ROUND(cr.avg_rating, 2) AS category_average,
    ROUND(orx.avg_rating, 2) AS overall_average
FROM category_ratings cr
CROSS JOIN overall_rating orx
WHERE cr.avg_rating > orx.avg_rating
ORDER BY cr.avg_rating DESC;

-- 15. Recently updated apps (after CSV dates are imported)
SELECT App, Category, Last_Updated, Current_Ver
FROM apps
WHERE Last_Updated IS NOT NULL
ORDER BY Last_Updated DESC
LIMIT 20;
