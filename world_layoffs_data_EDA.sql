-- WORLD LAYOFFS EDA DATA ANALYSIS --

SELECT	*
FROM	layoffs_staging2;

/********************************************
* Verify date range of data
********************************************/
SELECT	MIN(`date`), MAX(`date`)
FROM	layoffs_staging2;

-- 3 years of data from 2020 to 2023

/********************************************
* Which country had the most lay offs?
* How did that country differ from the second highest country?
********************************************/
SELECT	country, SUM(total_laid_off)
FROM	layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- The United States experienced the highest number of layoffs between 2020 and 2023, totaling 256,420.
-- This is a significant gap compared to the second-highest, India, which had 35,793 layoffs during the same period.

/********************************************
* How many lay offs per year and which year had 
* the highest number of lay offs?
********************************************/
SELECT	YEAR(`date`), SUM(total_laid_off)
FROM	layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- The year 2022 saw the highest number of layoffs, with a total of 160,322.
-- In contrast, 2021 recorded the lowest number of layoffs, totaling 15,823.

/********************************************
* How many companies had 100% lay offs?
********************************************/
SELECT	company
FROM	layoffs_staging2
WHERE	percentage_laid_off = 1;

-- Between 2020 and 2023, 115 companies laid off their entire workforce.
-- Note: percentage_laid_off is stored as a decimal, where 1.0 represents 100%.


/********************************************
* Which industries have experienced the highest average percentage of layoffs, 
* and how does that relate to the maximum funding levels companies in those industries have raised?
********************************************/

-- Analyze average percentage_laid_off to assess layoff trends over time,
-- and compare that to the maximum funding raised by companies in each industry.
-- Include total_laid_off to provide additional context on the overall impact.
SELECT	industry,
		AVG(percentage_laid_off), 
        SUM(total_laid_off), 
        MAX(funds_raised_millions) 
FROM	layoffs_staging2
GROUP BY industry
ORDER BY MAX(funds_raised_millions) DESC;

-- From 2020 to 2023, the Aerospace industry had the highest average layoff rate at 56%.
-- During the same period, companies in this industry raised up to $3 billion in funding.
-- Despite the high average layoff rate, Aerospace had the third-lowest total number of layoffs among all industries.
-- Funding alone doesn't shield an industry from downsizing.


/********************************************
* How many companies are represented by each industry?
********************************************/
SELECT	industry, COUNT(company)
FROM	layoffs_staging2
GROUP BY industry;

-- Although the Aerospace industry has the highest average layoff rate, it is represented by only five companies in the dataset.


/********************************************
* Which industries experienced the highest number of layoffs in 2023, 
* and how do these compare to 2020?
********************************************/
 
 -- Get total_laid_off by industry and year 2023
SELECT	industry, SUM(total_laid_off) AS layoffs_2023
FROM	layoffs_staging2
WHERE YEAR(`date`) = 2023
GROUP BY industry
ORDER BY 2 DESC;

-- The top 5 industries with the highest number of layoffs in 2023 were:
-- 'Other' (28,512), Consumer (15,663), Retail (13,609), Hardware (13,223), and Healthcare (9,770).


-- Compare layoffs 2023 vs 2020 using CASE statement. 
-- Add a difference column for easier comparison
SELECT	industry,
		SUM(CASE WHEN YEAR(date) = 2023 THEN total_laid_off ELSE 0 END) AS layoffs_2023,
        SUM(CASE WHEN YEAR(date) = 2020 THEN total_laid_off ELSE 0 END) AS layoffs_2020,
        SUM(CASE WHEN YEAR(date) = 2023 THEN total_laid_off ELSE 0 END) -
        SUM(CASE WHEN YEAR(date) = 2020 THEN total_laid_off ELSE 0 END) AS layoffs_difference
FROM	layoffs_staging2
GROUP BY industry;

-- The Travel and Transportation industries saw the biggest drop in layoffs between 2020 and 2023.
-- Travel layoffs dropped from 13,983 in 2020 to 1,539 in 2023.
-- Transportation layoffs decreased from 14,656 in 2020 to 3,665 in 2023.
-- The 'Other' category had a high number of layoffs, with 28,512 reported in 2023 compared to 466 2020.
-- Consumer, Healthcare, and Sales industries saw higher layoffs in 2023 than in 2020.
-- The Hardware industry had 13,223 layoffs recorded in 2023 but no layoffs data for 2020.


SELECT	*
FROM	layoffs_staging2;

/********************************************
* Which company experienced the highest number of layoffs 
* and what industry was it part of?
********************************************/
SELECT	company, industry,
		SUM(total_laid_off)
FROM	layoffs_staging2
GROUP BY company, industry
ORDER BY SUM(total_laid_off) DESC;

-- Amazon had 18,150 total layoffs and is considered Retail industry

/********************************************
* Compare company layoffs for each year. What impact did the pandemic have on these layoff figures?
* How did the company with the most layoffs look over time? 
********************************************/

SELECT	company,
        SUM(CASE WHEN YEAR(date) = 2020 THEN total_laid_off ELSE 0 END) AS layoffs_2020,
		SUM(CASE WHEN YEAR(date) = 2021 THEN total_laid_off ELSE 0 END) AS layoffs_2021,
		SUM(CASE WHEN YEAR(date) = 2022 THEN total_laid_off ELSE 0 END) AS layoffs_2022,
		SUM(CASE WHEN YEAR(date) = 2023 THEN total_laid_off ELSE 0 END) AS layoffs_2023
FROM	layoffs_staging2
GROUP BY company
ORDER BY 1;

-- Amazon reported no layoff data for 2020 and 2021, but experienced a significant spike in 2022 with 10,150 layoffs, 
-- followed by another 8,000 in 2023. This suggests Amazon maintained its full workforce during the peak of the pandemic 
-- and later reduced workforce as demand normalized.
-- Uber experienced the highest number of layoffs in 2020, with 7,525 employees affected. 
-- This corresponds with the sharp decline in travel demand due to stay-at-home orders during the pandemic.
-- Booking.com had the second-highest layoffs that year, also impacted by the significant drop in global travel activity.

/********************************************
* Show running total of layoffs by Month/Year
********************************************/
-- (`date`,1,7) show date as YEAR-MM
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL 
GROUP BY `MONTH`
ORDER BY 1;

-- create cte
WITH rolling_total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL -- defined before select statement so use substring
GROUP BY `MONTH`
ORDER BY 1
)
SELECT	`MONTH`, total_laid_off,
		SUM(total_laid_off) OVER(ORDER BY `MONTH`) AS rolling_total -- row by row order of month
FROM	rolling_total; 

/********************************************
* Rank company layoffs by year showing top 5 per year
********************************************/

WITH company_year (company, years, total_laid_off) AS
(
SELECT	company, YEAR(`date`), 
		SUM(total_laid_off)
FROM	layoffs_staging2
GROUP BY company, YEAR(`date`)
),
company_year_rank AS 
(
SELECT	*, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking 
FROM 	company_year
WHERE years IS NOT NULL
)
SELECT	*
FROM	company_year_rank
WHERE	RANKING <= 5;

-- The largest layoffs in 2020 were at Uber (ranked 1) and Booking.com (ranked 2), both heavily impacted by the pandemic. 
-- Surprisingly, Airbnb, despite being in the same industry, had only 1,900 layoffs and ranked 5th.
-- In 2022 Meta had a significate lay off of 11,000 employees. Amazon shared simliar trend of 10,150 employees. This was possibly
-- due to overstaffing during the pandemic years.
-- Continuing the trend of major tech company layoffs, 2023 saw Google and Microsoft join the list with 12,000 and 10,000 layoffs, respectively.