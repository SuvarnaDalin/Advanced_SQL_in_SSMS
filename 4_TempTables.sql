-- Temp Tables vs CTE
-- CTEs can only be used in the current query scope & hence we cannot re use the virtual tables created by CTEs for different purposes.
-- Tem Tables  instead of being limited by the scope of the current query, are only limited by the current session.
-- Session basically is defined by the code editor window which you are currently working on. A seesion is killed only if the current window is closed.

-- TEMP TABLES

-- (I) Using SELECT INTO TEMP_TBL_NAME (TBL name should start with #)
-- 1) Convert the previous session CTE to Temp Table

SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank

INTO #Sales
FROM AdventureWorks2019.Sales.SalesOrderHeader;

-- Checking the Temp table
Select * from #Sales;

-- 2) Define Top10Sales Temp table
Select 
	OrderMonth,
	SUM(TotalDue) Top10Total
INTO #Top10Sales
From #Sales
Where OrderRank <=10
Group By OrderMonth

-- Checking the Temp table
Select * from #Top10Sales;

-- 3) Get MOM Comparison suing the abouve Temp tables
Select 
	A.OrderMonth,
	A.Top10Total,
	B.Top10Total PrevTop10Total
From #Top10Sales A
	LEFT JOIN #Top10Sales B
	ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
Order By A.OrderMonth

-- (II) DELETE TEMP TABLE
-- Use DROP TABLE

-- 4) Get Top5 Sales from #Sales and run together with #Top10Sales query
Select * From #Sales 
Where OrderRank <= 5

---- ERROR: There is already an object named '#Top10Sales' in the database.
-- Implies we have to delete the earlier table to get a new table named #Sales

DROP TABLE #Sales;
--Check
-- Select * from #Sales --> ERROR as its already deleted
DROP TABLE #Top10Sales;

-- ALways delete Temp tables after the session as it consumes a lot of memory depending on the table size

-- When TEMP TABLES are recommended?
-- using temp tables when you need to reference one of your virtual tables in multiple outputs
-- when needed to join massive data sets in your virtual tables.
-- need a script instead of a query.


-- Exercises
-- Exercise 1: Refactor your solution to the exercise from the section on CTEs (average sales/purchases minus top 10) using temp tables in place of CTEs.
-- Sales Temp table
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
INTO #Sales
FROM AdventureWorks2019.Sales.SalesOrderHeader;

-- SalesExceptTop10 Temp table
Select
	OrderMonth,
	SUM(TotalDue) TotalSales
INTO #SalesExceptTop10
From #Sales
Where OrderRank > 10
Group By OrderMonth;

-- Purchases Temp table
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
INTO #Purchases
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

-- PurchasesExceptTop10 Tenp table
Select 
	OrderMonth,
	SUM(TotalDue) TotalPurchases
INTO #PurchasesExceptTop10
From #Purchases
Where OrderRank > 10
Group By OrderMonth

-- Final
Select 
	SET10.OrderMonth,
	SET10.TotalSales,
	PET10.TotalPurchases
From #SalesExceptTop10 SET10
	Join #PurchasesExceptTop10 PET10
	On SET10.OrderMonth = PET10.OrderMonth
Order By 1;

DROP TABLE #Sales;
DROP TABLE #SalesExceptTop10;
DROP TABLE #Purchases;
DROP TABLE #PurchasesExceptTop10;


-- (III) CREATE and INSERT using TEMP TABLES
-- 5) Creates the Sales table as above but insert columns into blank table
CREATE TABLE #Sales
(
	OrderDate DATETIME,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
);

-- 6) Add Data
INSERT INTO #Sales
(
	OrderDate,
	OrderMonth,
	TotalDue,
	OrderRank
)
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
FROM AdventureWorks2019.Sales.SalesOrderHeader;

-- 3) Change Data type of the OrderDate column
DROP TABLE #Sales;  -- have to drop table frist before recreatong with data type changes

-- Recreate table
CREATE TABLE #Sales
(
	OrderDate DATE,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
);

-- Re insert data
INSERT INTO #Sales
(
	OrderDate,
	OrderMonth,
	TotalDue,
	OrderRank
)
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
FROM AdventureWorks2019.Sales.SalesOrderHeader;


-- 4) Create the Top10Sales Temp table
CREATE TABLE #Top10Sales
(
	OrderMonth DATE,
	Top10Total MONEY
)


-- Add data using a different technique (NOT RECOMMENDED)
INSERT INTO #Top10Sales  --- Can be done without using the parenthesis
Select 
	OrderMonth,
	SUM(TotalDue) Top10Total
From #Sales
Where OrderRank <=10
Group By OrderMonth;

-- Try the tables
Select 
	A.OrderMonth,
	A.Top10Total,
	B.Top10Total PrevTop10Total
From #Top10Sales A
	LEFT JOIN #Top10Sales B
	ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
Order By A.OrderMonth;

select * From #Sales Where OrderRank <= 5

DROP TABLE #Sales
DROP TABLE #Top10Sales

Select * From #Top10Sales