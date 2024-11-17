-- =============================
-- Step 1: Create Database
-- =============================
-- Create the TelecomMaintenance database. 
-- This database will store the fact and dimension tables used for analysis. import flat file into database
CREATE DATABASE TelecomMaintenance;


-- =============================
-- Step 2: Check Existing Data
-- =============================
-- Check contents of the fact table (nr) to verify the data.
SELECT * 
FROM nr;

-- Check contents of the dimension table (class) to verify the data.
SELECT * 
FROM class;


-- =============================
-- Step 3a: Prepare Data - Add Project Column
-- =============================
-- The class table contains additional details about projects.
-- Add the 'project' column to the nr table by performing a LEFT JOIN with the class table.
-- The join condition is based on the 'Job_Description' field.
SELECT nr.Request_date, 
       nr.Site_ID, 
       nr.Job_Type, 
       nr.Job_Description, 
       nr.Qty_Used, 
       nr.Unit_Price, 
       nr.Qty_Approved, 
       nr.Approved_Unit_Price, 
       nr.Customer_Name, 
       nr.Approval_Date, 
       nr.Job_Status, 
       nr.Closure_Date, 
       nr.Execution_Type, 
       nr.Customer_Validation_Month, 
       nr.Revenue_Month, 
       class.project
FROM nr
LEFT JOIN class 
  ON nr.Job_Description = class.fault;


-- =============================
-- Step 3b: Prepare Data - Handle NULL values in Project
-- =============================
-- There may be cases where the Job_Description from nr does not exist in class.
-- Use COALESCE to handle NULL values in the 'project' column, defaulting them to 'Other Capex'.
SELECT nr.Request_date, 
       nr.Site_ID, 
       nr.Job_Type, 
       nr.Job_Description, 
       nr.Qty_Used, 
       nr.Unit_Price, 
       nr.Qty_Approved, 
       nr.Approved_Unit_Price, 
       nr.Customer_Name, 
       nr.Approval_Date, 
       nr.Job_Status, 
       nr.Closure_Date, 
       nr.Execution_Type, 
       nr.Customer_Validation_Month, 
       nr.Revenue_Month, 
       COALESCE(class.project, 'Other Capex') AS project
FROM nr
LEFT JOIN class 
  ON nr.Job_Description = class.fault;


-- =============================
-- Step 3c: Prepare Data - Check for Empty Expense Rows
-- =============================
-- Check for rows in the nr table where Unit_Price is 0.
-- These rows may represent jobs with no cost, and they should be excluded in future queries.
SELECT * 
FROM nr
WHERE Unit_Price = 0;


-- =============================
-- Step 3d: Prepare Data - Exclude Rows with Unit_Price = 0
-- =============================
-- Exclude rows with Unit_Price = 0 from our main query.
-- The goal is to only focus on rows where jobs have associated costs.
SELECT nr.Request_date, 
       nr.Site_ID, 
       nr.Job_Type, 
       nr.Job_Description, 
       nr.Qty_Used, 
       nr.Unit_Price, 
       nr.Qty_Approved, 
       nr.Approved_Unit_Price, 
       nr.Customer_Name, 
       nr.Approval_Date, 
       nr.Job_Status, 
       nr.Closure_Date, 
       nr.Execution_Type, 
       nr.Customer_Validation_Month, 
       nr.Revenue_Month, 
       COALESCE(class.project, 'Other Capex') AS project
FROM nr
LEFT JOIN class 
  ON nr.Job_Description = class.fault
WHERE nr.Unit_Price <> 0;


-- =============================
-- Step 4a: Create Temporary Table
-- =============================
-- Create a temporary table called #NRJobs to store the results of our query.
-- This table will hold all the relevant columns needed for further analysis.
CREATE TABLE #NRJobs (
    Request_Date DATE,
    Site_ID VARCHAR(255),
    Job_Type VARCHAR(255),
    Job_Description VARCHAR(255),
    Qty_Used FLOAT,
    Unit_Price FLOAT,
    Qty_Approved INT,
    Approved_Unit_Price FLOAT,
    Customer_Name VARCHAR(255),
    Approval_Date DATE,
    Job_Status VARCHAR(255),
    Closure_Date DATE,
    Execution_Type VARCHAR(255),
    Customer_Validation_Month DATE,
    Revenue_Month DATE,
    Project VARCHAR(255)
);


-- =============================
-- Step 4b: Insert Data into Temp Table
-- =============================
-- Insert the filtered data from the nr and class tables into the temporary table #NRJobs.
-- Only include rows where Unit_Price is not 0.
INSERT INTO #NRJobs
SELECT nr.Request_date, 
       nr.Site_ID, 
       nr.Job_Type, 
       nr.Job_Description, 
       nr.Qty_Used, 
       nr.Unit_Price, 
       nr.Qty_Approved, 
       nr.Approved_Unit_Price, 
       nr.Customer_Name, 
       nr.Approval_Date, 
       nr.Job_Status, 
       nr.Closure_Date, 
       nr.Execution_Type, 
       nr.Customer_Validation_Month, 
       nr.Revenue_Month, 
       COALESCE(class.project, 'Other Capex') AS project
FROM nr
LEFT JOIN class 
  ON nr.Job_Description = class.fault
WHERE nr.Unit_Price <> 0;


-- =============================
-- Step 4c: Handle NULL Values in Date Columns
-- =============================
-- If NULL values exist in the 'Customer_Validation_Month' or 'Revenue_Month' columns,
-- Use COALESCE to set them to a default value of '1900-01'.
-- Drop the existing temp table first if it exists to avoid conflicts.
IF OBJECT_ID('tempdb..#NRJobs') IS NOT NULL
    DROP TABLE #NRJobs;

-- Recreate the temp table with NVARCHAR(10) for date fields to handle string format.
CREATE TABLE #NRJobs (
    Request_Date NVARCHAR(10),
    Site_ID VARCHAR(255),
    Job_Type VARCHAR(255),
    Job_Description VARCHAR(255),
    Qty_Used FLOAT,
    Unit_Price FLOAT,
    Qty_Approved INT,
    Approved_Unit_Price FLOAT,
    Customer_Name VARCHAR(255),
    Approval_Date NVARCHAR(10),
    Job_Status VARCHAR(255),
    Closure_Date NVARCHAR(10),
    Execution_Type VARCHAR(255),
    Customer_Validation_Month NVARCHAR(10),
    Revenue_Month NVARCHAR(10),
    Project VARCHAR(255)
);

-- Insert data into the temp table, handling NULL values in date fields with COALESCE.
INSERT INTO #NRJobs
SELECT 
    CAST(nr.Request_Date AS NVARCHAR(10)), 
    nr.Site_ID, 
    nr.Job_Type, 
    nr.Job_Description, 
    nr.Qty_Used, 
    nr.Unit_Price,
    nr.Qty_Approved, 
    nr.Approved_Unit_Price, 
    nr.Customer_Name, 
    CAST(nr.Approval_Date AS NVARCHAR(10)), 
    nr.Job_Status, 
    CAST(nr.Closure_Date AS NVARCHAR(10)), 
    nr.Execution_Type, 
    COALESCE(CAST(nr.Customer_Validation_Month AS NVARCHAR(10)), '1900-01') AS Customer_Validation_Month, 
    COALESCE(CAST(nr.Revenue_Month AS NVARCHAR(10)), '1900-01') AS Revenue_Month, 
    COALESCE(class.project, 'Other Capex') AS project
FROM nr
LEFT JOIN class 
  ON nr.Job_Description = class.fault
WHERE nr.Unit_Price <> 0;


-- =============================
-- Step 4d: Verify Temp Table Data
-- =============================
-- Check the contents of the #NRJobs temp table to ensure the data was inserted correctly.
SELECT * 
FROM #NRJobs;


-- =============================
-- Step 5: Lets explore our Data...again :)
-- =============================
-- Check project distribution.
SELECT Project, 
	COUNT(Project) AS Distribution
FROM #NRJobs
GROUP BY Project
ORDER BY Distribution DESC;

-- Calculate total revenue by site for Top 10
SELECT TOP 10 
    Site_ID, 
    SUM(Qty_Approved * Approved_Unit_Price) AS Total_Revenue
FROM #NRJobs
GROUP BY Site_ID
ORDER BY Total_Revenue DESC;

-- Monthly revenue amount Trend
SELECT DATEPART(MONTH, Request_Date) AS Month, 
	SUM(Qty_Approved * Approved_Unit_Price) AS Monthly_Revenue
FROM #NRJobs
GROUP BY DATEPART(MONTH, Request_Date)
ORDER BY Monthly_Revenue DESC;

-- Most Frequent Jobs
SELECT TOP 10
	Job_Description, 
	COUNT(*) AS Job_Count
FROM #NRJobs
GROUP BY Job_Description
ORDER BY Job_Count DESC;

-- Check execution distribution alongside expense
SELECT Execution_Type, 
	COUNT(Execution_Type) AS Distribution,
	SUM(Qty_Used * Unit_Price) AS Total_Expense,
	AVG(Qty_Used * Unit_Price) AS Average_Expense
FROM #NRJobs
GROUP BY Execution_Type
ORDER BY Distribution DESC;

-- Average expense per job type
SELECT Job_Type, 
	COUNT(Job_Type) AS Distribution,
	AVG(Qty_Used * Unit_Price) AS Avg_Expense
FROM #NRJobs
GROUP BY Job_Type
ORDER BY Avg_Expense DESC;

-- Average profit per job type ratio count of job
SELECT 
    Job_Type, 
    COUNT(Job_Type) AS Distribution,
    AVG(Qty_Used * Unit_Price) AS Avg_Expense,
    AVG(Qty_Approved * Approved_Unit_Price) AS Avg_Revenue,
    (AVG(Qty_Approved * Approved_Unit_Price) - AVG(Qty_Used * Unit_Price)) AS Profit,
    ((AVG(Qty_Approved * Approved_Unit_Price) - AVG(Qty_Used * Unit_Price)) / COUNT(Job_Type)) AS Ratio
FROM #NRJobs
GROUP BY Job_Type
HAVING COUNT(Job_Type) > 10
ORDER BY Ratio DESC;



-- =============================
-- Step 6: Create a new table to exported to Power BI
-- =============================
-- Drop the existing table if it exists
IF OBJECT_ID('dbo.NRJobs', 'U') IS NOT NULL
   DROP TABLE dbo.NRJobs;


-- Create the new permanent table
CREATE TABLE dbo.NRJobs (
    Request_Date NVARCHAR(10),
    Site_ID VARCHAR(255),
    Job_Type VARCHAR(255),
    Job_Description VARCHAR(255),
    Qty_Used FLOAT,
    Unit_Price FLOAT,
    Qty_Approved INT,
    Approved_Unit_Price FLOAT,
    Customer_Name VARCHAR(255),
    Approval_Date NVARCHAR(10),
    Job_Status VARCHAR(255),
    Closure_Date NVARCHAR(10),
    Execution_Type VARCHAR(255),
    Customer_Validation_Month NVARCHAR(10),
    Revenue_Month NVARCHAR(10),
    Project VARCHAR(255)
);

-- Insert data from temp table into the new permanent table
INSERT INTO dbo.NRJobs
SELECT * FROM #NRJobs;

