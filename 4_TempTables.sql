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

-- Exercises (CREATE & INSERT)
-- Exercise 1: Rewrite your solution from last video's exercise using CREATE and INSERT instead of SELECT INTO.
CREATE TABLE #Sales
(
       OrderDate DATE
	  ,OrderMonth DATE
      ,TotalDue MONEY
	  ,OrderRank INT
)

INSERT INTO #Sales
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Sales.SalesOrderHeader



CREATE TABLE #SalesMinusTop10
(
OrderMonth DATE,
TotalSales MONEY
)

INSERT INTO #SalesMinusTop10
(
OrderMonth,
TotalSales
)
SELECT
OrderMonth,
TotalSales = SUM(TotalDue)
FROM #Sales
WHERE OrderRank > 10
GROUP BY OrderMonth


CREATE TABLE #Purchases
(
       OrderDate DATE
	  ,OrderMonth DATE
      ,TotalDue MONEY
	  ,OrderRank INT
)

INSERT INTO #Purchases
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader


CREATE TABLE #PurchaseMinusTop10
(
OrderMonth DATE,
TotalPurchases MONEY
)

INSERT INTO #PurchaseMinusTop10
(
OrderMonth,
TotalPurchases
)
SELECT
OrderMonth,
TotalPurchases = SUM(TotalDue)
FROM #Purchases
WHERE OrderRank > 10
GROUP BY OrderMonth



SELECT
A.OrderMonth,
A.TotalSales,
B.TotalPurchases

FROM #SalesMinusTop10 A
	JOIN #PurchaseMinusTop10 B
		ON A.OrderMonth = B.OrderMonth

ORDER BY 1

DROP TABLE #Sales
DROP TABLE #SalesMinusTop10
DROP TABLE #Purchases
DROP TABLE #PurchaseMinusTop10


-- (IV) TRUNCATE - Clearing & Reusing Tables
-- To optimize the previous table creation & deletion steps
-- 7) Create one Orders table with Sales & Purchases
CREATE TABLE #Orders
(
	OrderDate DATETIME,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
);

INSERT INTO #Orders
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

CREATE TABLE #Top10Orders
(
	OrderMonth DATE,
	OrderType VARCHAR(32),
	Top10Total MONEY
);

INSERT INTO #Top10Orders  --- Can be done without using the parenthesis
Select 
	OrderMonth,
	OrderType = 'Sales',
	SUM(TotalDue) Top10Total
From #Orders
Where OrderRank <=10
Group By OrderMonth

TRUNCATE TABLE #Orders			-- Only clears data inside table without removing structore of the table

-- Now insert Purchase data
INSERT INTO #Orders
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
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader;

INSERT INTO #Top10Orders  --- Can be done without using the parenthesis
Select 
	OrderMonth,
	OrderType = 'Purchases',
	SUM(TotalDue) Top10Total
From #Orders
Where OrderRank <=10
Group By OrderMonth

Select * From #Orders
Select * From #Top10Orders --Top10Orders have both Sales & Purchases

--8) Compare MoM for Salse & Purchases
Select 
	A.OrderMonth,
	A.OrderType,
	A.Top10Total,
	B.Top10Total PrevTop10Total
From #Top10Orders A
	LEFT JOIN #Top10Orders B
		ON A.OrderMonth = DATEADD(MONTH, 1, B.OrderMonth)
		AND A.OrderType = B.OrderType
Order By 1,2

DROP TABLE #Orders
DROP TABLE #Top10Orders

-- Exercises (TRUNCATE)
-- Exercise 1:Leverage TRUNCATE to re-use temp tables in your solution to "CREATE and INSERT" exercise
-- Create Common Orders table
CREATE TABLE #Orders
(
       OrderDate DATE
	  ,OrderMonth DATE
      ,TotalDue MONEY
	  ,OrderRank INT
)
INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader


-- Create OrdersMinusTop10 to make common using OrderType
CREATE TABLE #OrdersMinusTop10
(
OrderMonth DATE,
OrderType VARCHAR(32),
TotalDue MONEY
);

INSERT INTO #OrdersMinusTop10
(
	OrderMonth,
	OrderType,
	TotalDue
)
SELECT
	OrderMonth,
	'Sales' OrderType,
	SUM(TotalDue) TotalDue
From #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth

TRUNCATE TABLE #Orders

-- Insert Purchase Orders
INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

-- Insert Purchase Minus stuff
INSERT INTO #OrdersMinusTop10
(
	OrderMonth,
	OrderType,
	TotalDue
)
SELECT
	OrderMonth,
	'Purchases' OrderType,
	SUM(TotalDue) TotalDue
From #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth

-- MoM comparison
SELECT
A.OrderMonth,
TotalSales = A.TotalDue,
TotalPurchases = B.TotalDue

FROM #OrdersMinusTop10 A
	JOIN #OrdersMinusTop10 B
		ON A.OrderMonth = B.OrderMonth
			AND B.OrderType = 'Purchases'
WHERE A.OrderType = 'Sales'
ORDER BY 1

DROP TABLE #OrdersMinusTop10
DROP TABLE #Orders

-- (V) UPDATE 
-- For modifying tables - No SELECT required
-- Same UPDATE statement CAN BE RUN ANY NO OF TIMES Unlike INSERT whuch duplicates coolumns when same statement is rerun
-- 9) Create a table and update columns later

CREATE TABLE #SalesOrders
(
	SalesOrderID INT,
	OrderDate DATE,
	TaxAmt MONEY,
	Freight MONEY,
	TotalDue MONEY,
	TaxFreightPercent FLOAT,
	TaxFreightBucket VARCHAR(32),
	OrderAmtBucket VARCHAR(32),
	OrderCategory VARCHAR(32),
	OrderSubcategory VARCHAR(32)
)

INSERT INTO #SalesOrders
(
	SalesOrderID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue,
	OrderCategory
)
SELECT
	SalesOrderID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue,
	'Non-holiday Order' OrderCategory			-- We will use UPDATE to add more Categories
FROM AdventureWorks2019.Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013

Select * From #SalesOrders						
-- We will use UPDATE to populate other columns
-- Using calculated columns like below
SELECT (TaxAmt + Freight)/TotalDue TaxFreightPercent
FROM #SalesOrders

--Use UPDATE now

UPDATE #SalesOrders
SET 
	TaxFreightPercent = (TaxAmt + Freight)/TotalDue,
	OrderAmtBucket = 
		CASE
			WHEN TotalDue < 100 THEN 'Small'
			WHEN TotalDue < 1000 THEN 'Medium'
			ELSE 'Large'
		END

UPDATE #SalesOrders
SET 
	TaxFreightBucket =
		CASE
			WHEN TaxFreightPercent < 0.1 THEN 'Small'
			WHEN TaxFreightPercent  < 0.2 THEN 'Medium'
			ELSE 'Large'
		END

UPDATE #SalesOrders
SET
	OrderCategory = 'Holiday'
	WHERE DATEPART(QUARTER, OrderDate) = 4		-- UPDATES ONLY THOSE THOSE FOR Quarter 4 unlike earlier Updates that updated all rows

Select * From #SalesOrders	

-- Exercises (UPDATE)
-- Exercise 1: update the value in the "OrderSubcategory" field as follows: "Value in OrderCategory field" - "Value in OrderAmtBucket" using concatenate
-- Eg: Non-holiday Order - Large

UPDATE #SalesOrders
SET
	OrderSubcategory = CONCAT(OrderCategory, ' - ', OrderAmtBucket)

Select * From #SalesOrders	
DROP TABLE #SalesOrders

-- (VI) DELETE 
-- To selectively delete data from tables
-- 10) Create Sales table and delet all Orders with OrderRank > 10

CREATE TABLE #Sales
(
	OrderDate DATETIME,
	OrderMonth DATE,
	TotalDue MONEY,
	OrderRank INT
)
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
	ROW_NUMBER() OVER( PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
From AdventureWorks2019.Sales.SalesOrderHeader

-- Get Top10 records using SELECT
Select * from #Sales
WHERE OrderRank <= 10	

-- Instead DELETE Orders with OrderRank > 10

DELETE From #Sales
WHERE OrderRank > 10

Select * from #Sales	-- Now this shows only Top 10 records without criteria (WHERE OrderRank > 10)

DELETE From #Sales		-- DELETEs the entire table
-- So DELETE can be very dangerous. BE VERY CAREFUL!!