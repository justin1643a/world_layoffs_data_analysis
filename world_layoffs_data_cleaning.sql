-- WORLD LAYOFFS DATA CLEANING --

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns OR Rows


/********************************************
 * 1. Remove Duplicates from staging table
 ********************************************/

-- Review the "company" column
SELECT	DISTINCT company
FROM	layoffs_staging2;

/* 
* Remove extra spacing from company column. 
* Show trimmed data next to company original data in order to verify.
*/
SELECT	company, TRIM(company)
FROM	layoffs_staging2;

-- Create new schema to work from
CREATE SCHEMA world_layoffs;

-- Select the new schema
USE	world_layoffs;

-- View data 
SELECT	*
FROM	layoffs;

-- Create copy of table for cleaning
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Populate new table

INSERT layoffs_staging
SELECT	*
FROM	layoffs;

-- Verify

SELECT	*
FROM	layoffs_staging;

-- Find duplicates by creating CTE statement that will add row numbers over the data as row_num column.

WITH duplicate_cte AS 
	(
    SELECT	*,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM	layoffs_staging
    )
SELECT	*
FROM	duplicate_cte
WHERE	row_num > 1;  

-- Verify duplicate data for a single data point
SELECT	*
FROM	layoffs_staging
WHERE	company = 'casper';

/* 
* Create another copy of layoffs_staging so the row number column can be added with actual values to use.
* Use workbench to copy a create table statement from layoffs_staging but adding row_num column.
*/
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int(11) DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int(11) DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copy layoffs_staging data into new layoffs_staging2 table WITH new row_num column data
 INSERT INTO layoffs_staging2
 SELECT	*,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
	FROM	layoffs_staging;
    
-- Verify data with row_num added
SELECT	*
FROM	layoffs_staging2
WHERE	row_num > 1;

-- Verify single data point
SELECT	*
FROM	layoffs_staging2
WHERE	company = 'cazoo'
AND		row_num > 1;	

-- Delete duplicate data
DELETE 
FROM layoffs_staging2
WHERE	row_num > 1;

-- View table
SELECT	*
FROM	layoffs_staging2;

-- View and verify 
SELECT	*
FROM	layoffs_staging2;


/********************************************
 * 2. Standardize the Data
 ********************************************/

-- Review the "company" column
SELECT	DISTINCT company
FROM	layoffs_staging2;

-- Remove extra spacing from company column. 
-- Show trimmed data next to company original data in order to verify.
SELECT	company, TRIM(company)
FROM	layoffs_staging2;

-- Replace company data to new trimmed data without extra spacing
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Review industry column
SELECT	DISTINCT industry
FROM	layoffs_staging2
ORDER BY 1; -- order by 1st column

/* 
* issues found with industry column: 
* blank values, same industry named differently 
*/ 

-- review crypto industry
SELECT	*
FROM	layoffs_staging2
WHERE	industry LIKE 'crypto%';

-- update crypto industry to only show value of Crypto
UPDATE layoffs_staging2
SET	   industry = 'Crypto'
WHERE  industry LIKE 'crypto%';

-- verify change
SELECT	DISTINCT industry
FROM	layoffs_staging2
WHERE   industry LIKE 'crypto%';

-- Review location column
SELECT	DISTINCT location
FROM	layoffs_staging2
ORDER BY 1;

-- Review country column
SELECT	DISTINCT country
FROM	layoffs_staging2
ORDER BY 1;

/*
* issues found with country column:
* extra '.' for United States vs United States. 
*/

-- review United States country data
SELECT	DISTINCT country
FROM	layoffs_staging2
WHERE	country	LIKE 'United States%';

-- Update country value for United States 
UPDATE layoffs_staging2
SET	   country = 'United States'
WHERE  country	LIKE 'United States%';

/* 
* Alternate method to update data ending in '.'
* TRIM(TRAILING '.' FROM country)
*/
-- verify change
SELECT	DISTINCT country
FROM	layoffs_staging2
ORDER BY 1;

/* 
* Date column needs to be standardized
* View date column as new date format 
* example: 1/18/2023 will now be 2023-01-18 
*/
SELECT	`date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM	layoffs_staging2;

-- update date column to new date format
UPDATE	layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- verify
SELECT	`date`
FROM	layoffs_staging2;

-- convert date column data type to DATE instead of TEXT
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


/********************************************
 * 3. Fix null and blank values
 ********************************************/

-- Review null values for total_laid_off column
SELECT	*
FROM	layoffs_staging2
WHERE 	total_laid_off IS NULL;

/* 
* review columns with no laid off data
* possible this may be removed from the table entirely since there is no data in both columns
*/
SELECT	*
FROM	layoffs_staging2
WHERE   total_laid_off IS NULL
AND		percentage_laid_off IS NULL;

-- review industry column for blanks and nulls
SELECT	*
FROM	layoffs_staging2
WHERE 	industry IS NULL
OR		industry = '';

-- review single data point with missing data. 
SELECT	*
FROM	layoffs_staging2
WHERE	company = 'airbnb';

/* 
 * Identify companies with missing industry information using a self-join
 * This query compares two rows for the same company and location:
 * - t1 shows rows where the "industry" is NULL or empty (missing data)
 * - t2 shows the same company and location where "industry" is not NULL
 */
SELECT	t1.company, t2.company, 
		t1.industry, t2.industry
FROM	layoffs_staging2 t1
JOIN	layoffs_staging2 t2
	ON	t1.company = t2.company
	AND	t1.location = t2.location
WHERE	(t1.industry IS NULL OR t1.industry ='')
AND		t2.industry IS NOT NULL
ORDER BY 1;

-- Update the industry data using self join

UPDATE	layoffs_staging2 t1 -- will be updated
JOIN	layoffs_staging2 t2 
		ON	t1.company = t2.company
SET	t1.industry = t2.industry -- t1 no data will now get data from t2
WHERE	(t1.industry IS NULL OR t1.industry ='') -- no data
AND		t2.industry IS NOT NULL; -- has data

/* 
* Fix issue where previous didn't update eveyrthing by setting blank values as NULL
* then re running self join update
*/
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- verify by reviewing previous single data point with missing data. 
SELECT	*
FROM	layoffs_staging2
WHERE	company = 'airbnb';

-- re check industry column 
SELECT	*
FROM	layoffs_staging2
WHERE 	industry IS NULL
OR		industry = '';

-- one company still missing industry, verify only one row in data
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT	*
FROM	layoffs_staging2;

/*
* Unable to populate additional NULL values in %laid_off columns because the data is simply missing.
* No other information to reference in order to determine those values by calculation.
*/


/********************************************
 * 4. Remove Unnecessary Columns
 *******************************************/ 

-- turn off autocommit so we can verify removal query beforehand
SELECT @@autocommit;
SET autocommit = 0;

-- Use previous query to show columns with no %laid_off data
SELECT	*
FROM	layoffs_staging2
WHERE   total_laid_off IS NULL
AND		percentage_laid_off IS NULL;

-- Delete rows with zero values that cannot be used for analysis
DELETE	
FROM	layoffs_staging2
WHERE   total_laid_off IS NULL
AND		percentage_laid_off IS NULL;

SELECT	*
FROM	layoffs_staging2;

-- row_num column no longer needed
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

COMMIT;