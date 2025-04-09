CREATE DATABASE sqlcasestudy;
USE sqlcasestudy;
SELECT * FROM salaries;
/*
Q1. You're a Compensation analyst employed by a multinational corporation. Your 
Assignment is to Pinpoint Countries who give work fully remotely, for the title 
'managers’ Paying salaries Exceeding $90,000 USD 
*/
SELECT DISTINCT company_location FROM salaries WHERE job_title LIKE '%manager%' and salary_in_usd > 90000 and remote_ratio = 100;

/*
2. AS a remote work advocate Working for a progressive HR tech startup who place 
their freshers’ clients IN large tech firms. you're tasked WITH Identifying top 5 
Country Having greatest count of large (company size) number of companies.
*/
SELECT company_location, count(*) as "Count" FROM (
SELECT * FROM salaries WHERE experience_level = 'EN' and company_size = 'L'
)t GROUP BY company_location
ORDER BY Count DESC
LIMIT 5;
/*
3. Picture yourself AS a data scientist Working for a workforce management 
platform. Your objective is to calculate the percentage of employees. Who enjoy 
fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light ON the 
attractiveness of high-paying remote positions IN today's job market.  
*/
SET @total = (SELECT count(*) FROM salaries WHERE salary_in_usd>100000);
SET @count = (SELECT count(*) FROM salaries WHERE salary_in_usd>100000 and remote_ratio = 100);
SET @percentage = (round(((SELECT @count)/(SELECT @total))*100, 2));
SELECT @percentage as "Percentage";
/*
4. Imagine you're a data analyst Working for a global recruitment agency. Your Task 
is to identify the Locations where entry-level average salaries exceed the average 
salary for that job title IN market for entry level, helping your agency guide 
candidates towards lucrative opportunities.
*/
SELECT t.job_title, company_location, average, avg_per_country From
(
SELECT job_title, AVG(salary_in_usd) as 'average' FROM salaries WHERE experience_level = 'EN' GROUP BY job_title 
)t
INNER JOIN 
(
SELECT job_title, company_location, AVG(salary_in_usd) as 'avg_per_country' FROM salaries WHERE experience_level = 'EN' GROUP BY job_title, company_location
)m ON t.job_title = m.job_title WHERE avg_per_country > average;

/*
5. You've been hired by a big HR Consultancy to look at how much people get paid 
IN diAerent Countries. Your job is to Find out for each job title which. Country 
pays the maximum average salary. This helps you to place your candidates IN 
those countries.
*/
SELECT * FROM
(
SELECT *, DENSE_RANK() OVER ( PARTITION BY job_title ORDER BY average DESC) as denseRank From (
SELECT job_title, company_location, AVG(salary_in_usd) as 'average' FROM salaries group by job_title, company_location
)t
)k WHERE denseRank = 1;
/*
6. AS a data-driven Business consultant, you've been hired by a multinational 
corporation to analyze salary trends across diAerent company Locations. Your 
goal is to Pinpoint Locations WHERE the average salary Has consistently 
Increased over the Past few years (Countries WHERE data is available for 3 years 
Only(present year and past two years) providing Insights into Locations 
experiencing Sustained salary growth. 
*/
WITH ct as 
(
	SELECT * FROM salaries WHERE company_location IN
	(
	SELECT company_location FROM 
	(
	SELECT company_location, AVG(salary_in_usd) as "average", COUNT(DISTINCT work_year) as "no_of_year" FROM salaries WHERE 
	work_year>= YEAR(current_date())-3 GROUP BY company_location HAVING no_of_year = 3
	)t
	)
)
SELECT company_location,
MAX(CASE WHEN work_year = 2022 THEN average END) AS "AVG_Salary_2022",
MAX(CASE WHEN work_year = 2023 THEN average END) AS "AVG_Salary_2023",
MAX(CASE WHEN work_year = 2024 THEN average END) AS "AVG_Salary_2024"
FROM
(
SELECT company_location, work_year, AVG(salary_in_usd) as "average" FROM ct GROUP BY company_location, work_year
)q GROUP BY company_location HAVING AVG_Salary_2024>AVG_Salary_2023 AND AVG_Salary_2023>AVG_Salary_2022;

/*
7.  Picture yourself AS a workforce strategist employed by a global HR tech startup. 
Your Mission is to Determine the percentage of fully remote work for each 
experience level IN 2021 and compare it WITH the corresponding figures for 2024, 
Highlighting any significant Increases or decreases IN remote work Adoption over 
the years.
*/ 
SELECT * FROM
(
	SELECT *, ROUND(((count_remote)/(total)*100), 2) AS remote_2021 FROM 
	(
		SELECT a.experience_level, total, count_remote FROM
		( SELECT experience_level, COUNT(*) AS total FROM salaries WHERE work_year =2021 GROUP BY experience_level
		)a INNER JOIN
		(SELECT experience_level, COUNT(*) AS count_remote FROM salaries WHERE work_year =2021 AND remote_ratio = 100 GROUP BY experience_level
		)b ON a.experience_level = b.experience_level
	)t
)m INNER JOIN    
(	SELECT *, ROUND(((count_remote)/(total)*100), 2) AS remote_2024 FROM 
	(
		SELECT a.experience_level, total, count_remote FROM
		( SELECT experience_level, COUNT(*) AS total FROM salaries WHERE work_year =2024 GROUP BY experience_level
		)a INNER JOIN
		(SELECT experience_level, COUNT(*) AS count_remote FROM salaries WHERE work_year =2024 AND remote_ratio = 100 GROUP BY experience_level
		)b ON a.experience_level = b.experience_level
	)t
)n on m.experience_level = n.experience_level;

/*
8. AS a Compensation specialist at a Fortune 500 company, you're tasked WITH 
analyzing salary trends over time. Your objective is to calculate the average salary 
increase percentage for each experience level and job title between the years 
2023 and 2024, helping the company stay competitive IN the talent market. 
*/
WITH ct as
(
SELECT experience_level, job_title, work_year, AVG(salary_in_usd) as AVG_salary 
FROM salaries WHERE work_year IN (2023, 2024) GROUP BY experience_level, job_title, work_year
)
SELECT *, ROUND(((AVG_Salary_2024 - AVG_Salary_2023)/(AVG_Salary_2023)*100), 2) AS CHANGES
FROM (
	SELECT experience_level, job_title,
	MAX(CASE WHEN work_year = 2023 THEN AVG_salary END) AS AVG_Salary_2023,
	MAX(CASE WHEN work_year = 2024 THEN AVG_salary END) AS AVG_Salary_2024
	FROM ct GROUP BY experience_level, job_title
    )a WHERE ((AVG_Salary_2024 - AVG_Salary_2023)/(AVG_Salary_2023)*100) IS NOT NULL; 
/*
9. You're a database administrator tasked with role-based access control for a 
company's employee database. Your goal is to implement a security measure 
where employees in diAerent experience level (e.g. Entry Level, Senior level etc.) 
can only access details relevant to their respective experience level, ensuring 
data confidentiality and minimizing the risk of unauthorized access.
*/
SELECT DISTINCT experience_level FROM salaries;
SHOW PRIVILEGES;
CREATE USER 'Entry_level'@'%' IDENTIFIED BY 'EN';
CREATE USER 'Junior_Mid_level'@'%' IDENTIFIED BY 'MI';
CREATE USER 'Senior_level'@'%' IDENTIFIED BY 'SE';
CREATE USER 'Expert_Executive_level'@'%' IDENTIFIED BY 'EX';

CREATE VIEW entry_level AS SELECT * FROM salaries WHERE experience_level = 'EN' ;
CREATE VIEW Mid_level AS SELECT * FROM salaries WHERE experience_level = 'MI' ;
CREATE VIEW Senior_level AS SELECT * FROM salaries WHERE experience_level = 'SE' ;
CREATE VIEW expert_level AS SELECT * FROM salaries WHERE experience_level = 'EX' ;

GRANT SELECT ON sqlcasestudy.entry_level TO 'Entry_level'@'%';
GRANT SELECT ON sqlcasestudy.mid_level TO 'Junior_Mid_level'@'%';
GRANT SELECT ON sqlcasestudy.senior_level TO 'Senior_level'@'%';
GRANT SELECT ON sqlcasestudy.expert_level TO 'Expert_Executive_level'@'%';

/*
10. You are working with a consultancy firm, your client comes to you with certain 
data and preferences such as (their year of experience , their employment type, 
company location and company size )  and want to make an transaction into 
diAerent domain in data industry (like  a person is working as a data analyst and 
want to move to some other domain such as data science or data engineering 
etc.) your work is to  guide them to which domain they should switch to base on  
the input they provided, so that they can now update their knowledge as  per the 
suggestion/.. The Suggestion should be based on average salary. 
*/
DELIMITER //
CREATE PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(2), IN comp_loc VARCHAR(2),IN camp_size VARCHAR(2))
BEGIN 
	SELECT job_title, experience_level, employment_type, company_location, company_size, ROUND(AVG(salary_in_usd)) as averageSalaryUSD 
	FROM salaries 
	WHERE experience_level = exp_lev AND employment_type = emp_type AND company_location = comp_loc AND company_size = camp_size 
	GROUP BY experience_level, employment_type, company_location, company_size, job_title ORDER BY averageSalaryUSD DESC;
END //
DELIMITER ;

CALL GetAverageSalary( 'EN', 'FT', 'PK', 'M');
DROP PROCEDURE GetAverageSalary;