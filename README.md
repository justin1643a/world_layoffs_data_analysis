

# World Layoffs Data Analysis

## Description
This project focuses on cleaning a global layoffs dataset using SQL. The dataset contains information about companies, locations, industries, layoffs, and more. The objective is to prepare the data for analysis by removing duplicates, standardizing formats, handling null/blank values, and removing unnecessary columns or rows.

## Project Outline and Steps

### 1. Remove Duplicates
Duplicates are identified and removed to ensure data integrity. A staging table preserves the original data, and duplicates are detected using `ROW_NUMBER()`.

**Code Example: Identifying Duplicates**
```sql
WITH duplicate_cte AS 
(
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
```

**Code Example: Deleting Duplicates**
```sql
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;
```

### 2. Standardize the Data
Data is standardized for consistency, including trimming spaces, unifying industry names, correcting country names, and converting the date column to `DATE` format.

**Code Example: Trimming Company Names**
```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```

**Code Example: Standardizing Industry Names**
```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';
```

**Code Example: Converting Date Format**
```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

### 3. Handle Null and Blank Values
Null or blank values are addressed where possible, such as populating missing industry values using a self-join.

**Code Example: Identifying Missing Industry Values**
```sql
SELECT	t1.company, t2.company, 
		t1.industry, t2.industry
FROM	layoffs_staging2 t1
JOIN	layoffs_staging2 t2
	ON	t1.company = t2.company
	AND	t1.location = t2.location
WHERE	(t1.industry IS NULL OR t1.industry ='')
AND		t2.industry IS NOT NULL
ORDER BY 1;
```

**Code Example: Updating Missing Industry Values**
```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
```

### 4. Remove Unnecessary Columns and Rows
Rows with missing critical data (e.g., both `total_laid_off` and `percentage_laid_off` are null) and unnecessary columns (e.g., `row_num`) are removed.

**Code Example: Deleting Rows with Missing Data**
```sql
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

**Code Example: Dropping Unnecessary Column**
```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

## How to Run the Project
1. **Prerequisites**: Install a MySQL database environment (e.g., MySQL Workbench or another SQL client).
2. **Setup Database**:
   - Import the layoffs.csv dataset into your MySQL database
   - The dataset should include columns: `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`.

## Conclusion
This project showcases a structured approach to cleaning a real-world dataset using SQL. By addressing duplicates, standardizing data, handling missing values, and removing unnecessary data, the dataset is now ready for accurate analysis, ensuring high-quality data for decision-making.

## Contact Information
- **LinkedIn:** [My LinkedIn Profile](https://www.linkedin.com/in/justin1643a)

Thanks for reviewing this project. 




