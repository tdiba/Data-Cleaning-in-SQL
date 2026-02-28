-- DATA CLEANING PROJECT

select*
from layoffs;

-- Steps to be taken in Project
-- 1. Remove Duplicates
-- 2. Standardise the data (e.g. deal with spelling errors, etc.)
-- 3. Deal with NULL values or blank values
-- 4. Remove unnecessary columns and rows

#Copy data from the original raw file into another one with exact data. That is called Staging
#We do this as we could make mistakes and we don't want those mistakes to affect the original data
create table layoffs_staging
like layoffs;

select* from layoffs_staging;

#Insert data from the original table to the staging table
insert layoffs_staging
select*
from layoffs;



-- 1. REMOVE DUPLICATES
#Do a row number, match it against all the columns and see if there are any duplicates
select*,
row_number() over ( 
partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num #we are going to partition by all the columns
from layoffs_staging;

#when we run it, all seems to be unique. if row number has two or above, it means that there are duplicates

#Create a CTE to put the above into
with duplicate_cte as
(
select*,
row_number() over ( 
partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num #we are going to partition by all the columns
from layoffs_staging
)
select*
from duplicate_cte
where row_num >1;

#The result will show a row_num with a value of 2. That indicates that those are duplicates

#Check if those are really duplicates by pulling up one company name shown in the results list
select*
from layoffs_staging
where company ='oda';

#The result shows that they are not legit duplicates
#This shows that we need to do the partition by, by every single column in the table

select*,
row_number() over ( 
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num #we are going to partition by all the columns
from layoffs_staging;

#let's put it in a CTE again
with duplicate_cte as
(select*,
row_number() over ( 
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num #we are going to partition by all the columns
from layoffs_staging
)
select*
from duplicate_cte
where row_num >1;

#let's check one of the companies again to see if it worked
select*
from layoffs_staging
where company = 'casper'; 
#Result shows that it does indeed have duplicates

#Here is how we are going to remove the duplicates
#create a new table called staging2 that will contain all the data inside the CTE and then delet from there
#It's like creating another table that has the extra row and then deleting fromthat table

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select* from layoffs_staging2; #refresh first and then check if table was created

#insert data from layoffs_staging to the new table to include the row_num column
insert into layoffs_staging2
select*,
row_number() over ( 
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num #we are going to partition by all the columns
from layoffs_staging;

select* from layoffs_staging2; #check to see if data has been inserted
#Result shows that all teh data was inserted


#filter on the row_num
select* 
from layoffs_staging2
where row_num > 1;



#the result shows duplicates that we are going to delete

DELETE FROM layoffs_staging2
WHERE row_num >1;



-- 2. STANDARDISING DATA
#Standardising data is about finding issues inyour data and then fixing them

select* 
from layoffs_staging2;

#do a trim on company column to remove unnecesary white space
select distinct(trim(company))
from layoffs_staging2;
#white space in company column removed

select company, trim(company)
from layoffs_staging2;

#we are going to update the layoffs_staging2 table
update layoffs_staging2
set company = trim(company); #this will update the company column to be exactly like the trim(company) column. it should be updated after running the code

#we are now going to look at the industry
select distinct(industry)
from layoffs_staging2
order by 1; 
#result shows that there's a blank space and a null value in the column
#We also see crypto and crypto currency, which should be under one label or name entry. it's important for exploratory data analysis

select*
from layoffs_staging2
where industry like 'crypto%'; #we want to see all the industry entries with crypto in the name
#Result shows that more than 90% of them is crypto so the name will be updated to crypto

#Update all industry names with crypto in it to all be crypto
update layoffs_staging2
set industry = 'crypto'
where industry like 'crypto%';
#all should by updated to crypto after running the code

#we will look at the location column now
select distinct(location)
from layoffs_staging2
order by 1;  #appear in alphabetical order

#we will look at the country column
select distinct(country)
from layoffs_staging2
order by 1;  #appear in alphabetical order
#after running we see that one of the united states entries has a period at the end

#look at all entries related to united states
select*
from layoffs_staging2
where country like 'united states%';
#it's supposed to be united states and not united states dot, so we need to fix that

#fix the issue using trailing
select distinct country, trim(trailing '.' from country) #we specified we are look to remove or trim a period at the end of country. specify when it's not white space
from layoffs_staging2
where country like 'united states%';

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'united states%';
#period should be removed after running the update. you should have one united states entry

#The date column is currently text. We want to change that to date-time format to help when we do visualisations and time-series
select `date`
STR_TO_DATE(`date`, ) #this helps us go from a string to date data type
from layoffs_staging2;

#update date column with the new data type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); #this helps us go from a string to date data type. inside parenthesis you put the data type, followed by teh format you want

#now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

select `date`
from layoffs_staging2;
#the update was successful

select* 
from layoffs_staging2;


-- DEALING WITH NULL AND BLANK VALUES

#start with total_laid_off column
select*
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
#if both these columns are null, then they are totally useless to us

#let's look at the industry where we remember having a blank and a null
select*
from layoffs_staging2
where industry is null
or industry = '';

#see if any of those company entries have a populated industry column
#Take airbnb first
select*
from layoffs_staging2
where company = 'Airbnb';
#after running, we see that the company is listed in the travel industry

#first set all the blanks to null
update layoffs_staging2
set industry = null
where industry ='';

#we look at same companies where some have blank columns and match with populated columns to see what kind of data needs to be put into the blank columns
select*
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry ='')
and t2.industry is not null;


#we will now update the blank entries with the known values
update layoffs_staging2 t1  #we are updateing the table t1 where the 
join layoffs_staging2 t2 #we are joining on t2
	on t1.company = t2.company #where the company has the exact same name
set t1.industry =t2.industry #we will set the t1 industry, which is the blank industry to have the values of t2 industry where t2 is thepopulated one
where t1.industry is null
and t2.industry is not null;


-- 4. REMOVING UNNECESSARY COLUMNS AND ROWS
#start by getting rid of total_laid_off and percentage_laid_off column
select*
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
#if both these columns are null, then they are totally useless to us

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
#after running the code we we see that all the data related to those columns has been deleted

#get rid of the row_num column because we don't need it anymore
alter table layoffs_staging2
drop column row_num;

#run entire table again to see if the column is gone
select*
from layoffs_staging2;
#after running code, we see that the column is  gone