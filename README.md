# SQL Data Cleaning Project – Global Layoffs Dataset


## Table of Contents

- [Project Overview](#project-overview)
- [Project Objectives](#project-objectives)
- [Dataset Description](#dataset-description)
- [Tools and Tecnologies](#tools-and-technologies)
- [Data Cleaning Process](#data-cleaning-process)
- [Final Outcome](#final-outcome)
- [Limitations](#limitations)
- [Acknowledgements](#acknowledgements)



### Project Overview:

This project focuses on cleaning and preparing a real-world layoffs dataset for reliable exploratory data analysis and reporting.
Raw datasets often contain inconsistencies such as duplicates, formatting issues, null values, and incorrect data types. The objective of this project was to transform the raw data into a structured, analysis-ready dataset using SQL best practices.



### Project Objectives:
- Remove duplicate records
- Standardize categorical data
- Handle NULL and blank values
- Correct data types
- Improve overall data integrity
- Produce a clean dataset suitable for analysis and visualization



### Dataset Description:
The dataset used for this project is layoffs.csv. The dataset contains company layoffs data for various companies spanning multiple industries in different parts of the world from the period of March 2020 up until March 2023. 



### Tools and Technologies:
- MySQL
- Window Functions
- CTEs
- Data Type Conversions



### Data Cleaning Process:
Below, I will detail six main steps that were taken in the data cleaning process

1. Creating a Staging Table
   To protect the raw dataset, a staging table was created.
   
   ```sql
   CREATE TABLE layoffs_staging LIKE layoffs;
    INSERT layoffs_staging SELECT * FROM layoffs;
   ```
   This ensures the original dataset remains unchanged.

   
2. Removing Duplicates
   Duplicates were identified using the ROW_NUMBER() window function:

   ```sql
   ROW_NUMBER() OVER (
    PARTITION BY company, location, industry,
    total_laid_off, percentage_laid_off,
    date, stage, country, funds_raised_millions
    )
   ```
  Steps:
  - Generated row numbers per partition
  - Moved results into a second staging table
  - Deleted rows where row_num > 1
This ensured only unique records remained.


3. Standardising Data
   3.1. Trimmed Whitespace

    ```sql
    UPDATE layoffs_staging2
    SET company = TRIM(company);
    ```

    3.2. Standardized Industry Labels
    - Unified variations like “crypto” and “crypto currency”
    - Updated inconsistent naming using pattern matching:
  
      ```sql
      UPDATE layoffs_staging2
      SET industry = 'crypto'
      WHERE industry LIKE 'crypto%';
      ```

      3.3. Corrected Country Formatting
      - Removed trailing punctuation in “United States.”

       ```sql
       UPDATE layoffs_staging2
      SET country = TRIM(TRAILING '.' FROM country)
      WHERE country LIKE 'united states%';
      ```
       

4. Converting Data Types
The date column was originally stored as text.

Converted using:
```sql
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;
```
This ensures proper time-series analysis capability.


5. Handling Null and Blank Values
  5.1. Removed Useless Records
   Rows where both:
   - total_laid_off
   - percentage_laid_off
    were NULL were deleted because they provide no analytical value.

    5.2. Imputed Missing Industry Values
     Using a self-join, missing industry values were filled based on matching company and location records:
     ```sql
     UPDATE layoffs_staging2 t1
    JOIN layoffs_staging2 t2
    ON t1.company = t2.company
    SET t1.industry = t2.industry
    WHERE t1.industry IS NULL
    AND t2.industry IS NOT NULL;
    ```
     This preserved valuable records while improving completeness.

   
6. Removing Temporary Columns
   After deduplication, the helper column row_num was removed:
   ```sql
   ALTER TABLE layoffs_staging2
    DROP COLUMN row_num;
   ```

   
### Final Outcome
The dataset is now:
- Free of duplicate records
- Standardized across categorical variables
- Correctly formatted for time-series analysis
- Cleaned of unusable null-only rows
- Structurally improved for reporting

This cleaned dataset is ready for:
- Exploratory Data Analysis (EDA)
- Trend analysis
- Industry comparisons
- Dashboard development
- Forecasting models



### Limitations:
- Industry imputation assumes company-level consistency.
- No external validation dataset was used.
- Some contextual business information (e.g., reason for layoffs) was not available.



### Acknowledgements:
This project was completed as part of a guided SQL data cleaning tutorial by [Alex The Analyst](https://www.youtube.com/watch?v=4UltKCnnnTA&list=PLUaB-1hjhk8FE_XZ87vPPSfHqb6OcM0cF&index=19)
