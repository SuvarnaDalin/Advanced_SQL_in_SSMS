----------- What really slows down queries the most?
-- (1) The number one factor is usually joins between large tables. ie. Tables with millions or even hundreds of millions of records.
-- Sln1: Use a filtered data set as much as possible

-- Sln2: Avoid having a lot of joins in a single select query, especially when those joins are bringing in large tables. 
--       By using update statements will actually update our target table based on values in another table.
-- WHY? 
-- Beacause the update statement will just grab the first matching value it finds from the secondary table and then populate the corresponding record in our target table.
-- By contrast, direct joins between tables can require the secondary table to be fully scanned by the database even after a match has been found, because the possibility of additional matches theoretically exists.

-- Sln 3: Apply indexes to fields that will be used in Joins

-- (I) OPTIMIZE WITH UPDATE

-- 1) Create a table with multi joins

SELECT 
	A.SalesOrderID,
	A.OrderDate,
	B.ProductID,
	B.LineTotal,
	C.Name AS ProductName,
	D.Name AS ProductSubCategory,
	E.Name AS ProductCategory

FROM AdventureWorks2019.Sales.SalesOrderHeader A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderDetailID
	JOIN AdventureWorks2019.Production.Product C
		ON B.ProductID = C.ProductID
	JOIN AdventureWorks2019.Production.ProductSubcategory D
		ON C.ProductSubcategoryID = D.ProductSubcategoryID
	JOIN AdventureWorks2019.Production.ProductCategory E
		ON D.ProductCategoryID = E.ProductCategoryID

WHERE Year(A.OrderDate) = 2012;

-- 2) Create base temp tables that can be used to join
-- Sales Table
CREATE TABLE #Sales2012
(
	SalesOrderID INT,
	OrderDate DATE
)
INSERT INTO #Sales2012
(
	SalesOrderID,
	OrderDate
)
SELECT 
	SalesOrderID,
	OrderDate
FROM AdventureWorks2019.Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2012

SELECT COUNT(*) FROM #Sales2012										-- Contains just 3915rows
SELECT COUNT(*) FROM AdventureWorks2019.Sales.SalesOrderHeader		-- Contains 31465 rows

-- Products Sold table
CREATE TABLE #ProductsSold2012
(
	SalesOrderID INT,
	OrderDate DATE,
	LineTotal MONEY,
	ProductID INT,
	ProductName VARCHAR(64),
	ProductSubCategoryID INT,
	ProductSubCategory VARCHAR(64),
	ProductCategoryID INT,
	ProductCategory VARCHAR(64)
)
INSERT INTO #ProductsSold2012
(
	SalesOrderID,
	OrderDate,
	LineTotal,
	ProductID
)
SELECT 
	A.SalesOrderID,
	A.OrderDate,
	B.LineTotal,
	B.ProductID
FROM #Sales2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

Select * From #ProductsSold2012

-- 3) Now populate the remaining columns using UPDATE
UPDATE A
SET 
	ProductName = B.Name,
	ProductSubCategoryID = B.ProductSubCategoryID
FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.Product B
		ON A.ProductID = B.ProductID

UPDATE A
SET 
	ProductSubCategory = B.Name,
	ProductCategoryID = B.ProductCategoryID
FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductSubcategory B
		ON A.ProductSubCategoryID = B.ProductSubCategoryID

UPDATE A
SET
	ProductCategory = B.Name
FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID

Select * From #ProductsSold2012

DROP TABLE #Sales2012
DROP TABLE #ProductsSold2012

-- Exercises (OPTIMIZING WITH UPDATE)
-- Exercise 1: Using UPDATE and TEMP TABLES optimize the below Multi Join code:
SELECT 
	   A.BusinessEntityID
      ,A.Title
      ,A.FirstName
      ,A.MiddleName
      ,A.LastName
	  ,B.PhoneNumber
	  ,PhoneNumberType = C.Name
	  ,D.EmailAddress

FROM AdventureWorks2019.Person.Person A
	LEFT JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID
	LEFT JOIN AdventureWorks2019.Person.PhoneNumberType C
		ON B.PhoneNumberTypeID = C.PhoneNumberTypeID
	LEFT JOIN AdventureWorks2019.Person.EmailAddress D
		ON A.BusinessEntityID = D.BusinessEntityID

-- Solution

CREATE TABLE #ContactDetails
(
	   BusinessEntityID INT,
	   Title VARCHAR(8), 
	   FirstName VARCHAR(32), 
	   MiddleName VARCHAR(32), 
	   LastName VARCHAR(32), 
	   PhoneNumber VARCHAR(32),
	   PhoneNumberTypeID VARCHAR(25),
	   PhoneNumberType VARCHAR(32), 
	   EmailAddress VARCHAR(64)
)
INSERT INTO #ContactDetails
(
	BusinessEntityID,
	Title,
	FirstName,
	MiddleName,
	LastName
)
SELECT 
	BusinessEntityID,
	Title,
	FirstName,
	MiddleName,
	LastName	
FROM AdventureWorks2019.Person.Person

UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID
FROM #ContactDetails A
	JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID

UPDATE A
SET
	PhoneNumberType = B.Name
FROM #ContactDetails A
	JOIN AdventureWorks2019.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID

UPDATE A
SET
	EmailAddress = B.EmailAddress
FROM #ContactDetails A
	JOIN AdventureWorks2019.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID

Select * From #ContactDetails

DROP TABLE #ContactDetails

-- (II) OPTIMIZING using Improved EXISTS With UPDATE
-- EXISTS lets you check for matching records from MANY side of relationship without duplicationg data in the ONE side.
-- Exists works just fine if you don't need any additional information about the match other than to know if the match exists or not exists
-- Use UPDATE if you need to see any actual data points or information pertaining to the match

CREATE TABLE #ProductsSold2012
(
	SalesOrderID INT,
	OrderDate DATE,
	LineTotal MONEY,
	ProductID INT
)
INSERT INTO #ProductsSold2012
(
	SalesOrderID,
	OrderDate
)
SELECT
	SalesOrderID,
	OrderDate
FROM AdventureWorks2019.Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2012



UPDATE A
SET 
	LineTotal = B.LineTotal,
	ProductID = B.ProductID
FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B		-- NOTE: There are multiple line order items in SalesOrderDetail table for a single SalesOrderID in SalesOrderHeader table
		ON A.SalesOrderID = B.SalesOrderID

Select * From #ProductsSold2012								-- Here the Multiple line orders did not pull through (3915 rows)

------ USE this only if you want only a single match

-- Want we want to get is the data when run below code
SELECT 
	A.SalesOrderID,
	A.OrderDate,
	B.LineTotal,
	B.ProductID
FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B		
		ON A.SalesOrderID = B.SalesOrderID					-- 21,689 rows

-- 4) Create Sales table using UPDATE with criteria
CREATE TABLE #Sales
(
	SalesOrderID INT,
	OrderDate DATE,
	TotalDue MONEY,
	LineTotal MONEY
)
INSERT INTO #Sales
(
	SalesOrderID,
	OrderDate,
	TotalDue
)
SELECT 
	SalesOrderID,
	OrderDate,
	TotalDue
FROM AdventureWorks2019.Sales.SalesOrderHeader

UPDATE A
SET
	LineTotal = B.LineTotal
FROM #Sales A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID
WHERE B.LineTotal > 10000						-- Those LineTotals with matches(>10000) are updated. Still UPDATE wont grab multiple matches

Select * From #Sales

Select * From #Sales
WHERE LineTotal is not null						-- 416

Select * From #Sales
WHERE LineTotal is null							-- 31,049

-- Double checking using NOT EXISTS
Select
	A.SalesOrderID, A.OrderDate, A.TotalDue
From AdventureWorks2019.Sales.SalesOrderHeader A
Where NOT EXISTS (
	Select 1
	From AdventureWorks2019.Sales.SalesOrderDetail B
	Where A.SalesOrderID = B.SalesOrderID
		AND B.LineTotal > 10000
)												-- 31,049 -- THIS MATCHES THE ABOVE

-- USE a JOIN to return all matching records

DROP TABLE #Sales

-- Exercises (OPTIMIZING using Improved EXISTS With UPDATE)
-- Exercise 1: Re-write the query using Improved UPDATE instead of EXISTS, also include a fourth column called "RejectedQty", which has one value for rejected quantity from the Purchasing.PurchaseOrderDetail table.

SELECT
       A.PurchaseOrderID,
	   A.OrderDate,
	   A.TotalDue

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
WHERE EXISTS (
	SELECT
	1
	FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	WHERE A.PurchaseOrderID = B.PurchaseOrderID
		AND B.RejectedQty > 5
)
ORDER BY 1						-- 466 rows

-- Solution:
CREATE TABLE #PurchaseTable
(
	PurchaseOrderID INT,
	OrderDate DATE,
	TotalDue MONEY,
	RejectedQty INT
)
INSERT INTO #PurchaseTable
(
	PurchaseOrderID,
	OrderDate,
	TotalDue
)
SELECT
	PurchaseOrderID,
	OrderDate,
	TotalDue
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

UPDATE #PurchaseTable
SET
	RejectedQty = B.RejectedQty
FROM #PurchaseTable A
JOIN AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	ON A.PurchaseOrderID = B.PurchaseOrderID
	WHERE B.RejectedQty > 5

Select * From #PurchaseTable
Where RejectedQty is not null						-- 466 rows. MATCHES EXISTS eg Table

DROP TABLE #PurchaseTable

-- (III) OPTIMIZING with INDEX
-- Database objects that can make queries against your tables faster.
-- Indexes do this by sorting the data in the fields that you apply them to.
-- This sorting of the data allows the database engine to find records within a table without having to go through the table row by row
-- 2 Types: Clustered & Non Clustered
-- Clustered - The rows of a table are physically sorted based on the field or fields the index is applied to. 
--				By default --> indexed based on primary key.
--				Only one clustered index is possible for one table
-- Non Clustered -  Table may have many non clustered indexes. 
--				Do not physically sort the data in a table. 
--				Can add as many as required but use judiciously
-- Indexes take up memory in the database, so you should only add them if they're actually needed.
-- Generally add indexes after data has been inserted to the table. Otherwise it takes time to run.

-- 5) Create filtered temp table os sales order header table where year = 2012
DROP TABLE #Sales2012
DROP TABLE #ProductsSold2012

CREATE TABLE #Sales2012
(
	SalesOrderID INT,
	OrderDate DATE
)
INSERT INTO #Sales2012
(
	SalesOrderID,
	OrderDate
)
SELECT 
	SalesOrderID,
	OrderDate
FROM AdventureWorks2019.Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2012

Select * from #Sales2012

-- 6) Create a new temp table after joining in SalesOrderDetail table
CREATE CLUSTERED INDEX Sales2012_idx ON #Sales2012(SalesOrderID)
CREATE TABLE #ProductsSold2012
(
	SalesOrderID INT,
	SalesOrderDetailID INT,
	OrderDate DATE,
	LineTotal MONEY,
	ProductID INT,
	ProductName VARCHAR(64),
	ProductSubCategoryID INT,
	ProductSubCategory VARCHAR(64),
	ProductCategoryID INT,
	ProductCategory VARCHAR(64)
)
INSERT INTO #ProductsSold2012
(
	SalesOrderID,
	SalesOrderDetailID,
	OrderDate,
	LineTotal,
	ProductID
)
SELECT 
	A.SalesOrderID,
	B.SalesOrderDetailID,
	A.OrderDate,
	B.LineTotal,
	B.ProductID
FROM #Sales2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

CREATE CLUSTERED INDEX ProductsSold2012_idx ON #ProductsSold2012(SalesOrderID, SalesOrderDetailID)

-- 7) Add Product data with UPDATE
CREATE NONCLUSTERED INDEX ProductsSold2012_idx2 ON #ProductsSold2012(ProductID)
UPDATE A
SET
	ProductName = B.Name,
	ProductSubCategoryID = B.ProductSubcategoryID
From #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.Product B
		ON A.ProductID = B.ProductID

-- 8) Add Product SubCategory with UPDATE
CREATE NONCLUSTERED INDEX ProductsSold2012_idx3 ON #ProductsSold2012(ProductSubcategoryID)
UPDATE A
SET
	ProductSubCategory = B.Name,
	ProductCategoryID = B.ProductCategoryID
From #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductSubcategory B
		ON A.ProductSubcategoryID = B.ProductSubcategoryID

-- 9) Add Product Category with UPDATE
CREATE NONCLUSTERED INDEX ProductsSold2012_idx4 ON #ProductsSold2012(ProductCategoryID)
UPDATE A
SET
	ProductCategory = B.Name
From #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID

Select * From #ProductsSold2012


-- Exercises (OPTIMIZING using INDEX)
-- Exercise 1:Optimize tith INDEX the starter code below

------------------------------------------------ Starter Code -----------------------------------
CREATE TABLE #PersonContactInfo
(
	   BusinessEntityID INT
      ,Title VARCHAR(8)
      ,FirstName VARCHAR(50)
      ,MiddleName VARCHAR(50)
      ,LastName VARCHAR(50)
	  ,PhoneNumber VARCHAR(25)
	  ,PhoneNumberTypeID VARCHAR(25)
	  ,PhoneNumberType VARCHAR(25)
	  ,EmailAddress VARCHAR(50)
)

INSERT INTO #PersonContactInfo
(
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
)

SELECT
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName

FROM AdventureWorks2019.Person.Person

UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID


UPDATE A
SET	PhoneNumberType = B.Name

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID


UPDATE A
SET	EmailAddress = B.EmailAddress

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID


SELECT * FROM #PersonContactInfo
DROP TABLE #PersonContactInfo
------------------------------------------------ Starter Code End -----------------------------------

--Solution
CREATE TABLE #PersonContactInfo1
(
	   BusinessEntityID INT
      ,Title VARCHAR(8)
      ,FirstName VARCHAR(50)
      ,MiddleName VARCHAR(50)
      ,LastName VARCHAR(50)
	  ,PhoneNumber VARCHAR(25)
	  ,PhoneNumberTypeID VARCHAR(25)
	  ,PhoneNumberType VARCHAR(25)
	  ,EmailAddress VARCHAR(50)
)

INSERT INTO #PersonContactInfo1
(
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
)

SELECT
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
FROM AdventureWorks2019.Person.Person

CREATE CLUSTERED INDEX pci_bus_idx ON #PersonContactInfo1(BusinessEntityID)

UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID

FROM #PersonContactInfo1 A
	JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID

CREATE NONCLUSTERED INDEX pci_phn_idx ON #PersonContactInfo1(PhoneNumberTypeID)

UPDATE A
SET	PhoneNumberType = B.Name

FROM #PersonContactInfo1 A
	JOIN AdventureWorks2019.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID


UPDATE A
SET	EmailAddress = B.EmailAddress

FROM #PersonContactInfo1 A
	JOIN AdventureWorks2019.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID

Select * from #PersonContactInfo1

DROP TABLE #PersonContactInfo1
DROP TABLE #ProductsSold2012
DROP TABLE #Sales2012

-- (IV) OPTIMIZING with LOOKUP TABLES
-- Make something permanent with temp tables knowledge
-- The commands used to define and manipulate temporary tables are broadly classified into DDL & DMl commands
-- DDL commands -> Data Defenition Language commands; pertain to the definition and structure of our database objects. egs: create, drop and truncate
-- DML commands -> Data manipulation Langauage commands; involve manipulating data in existing objects. egs: insert, update and delete

-- Lookup tables benefits
	-- Eliminate duplicated effort by locating frequently used attributes in one place. Eg: Creating a Calendar table
	-- Prmote dat aintegrity by consolidating a single version of the truth in a central location

-- 10) Create a permanent calendar table
-- To create a permanent table - Instead of # sign specify the database and the schema that we will be creating the table on

CREATE TABLE AdventureWorks2019.dbo.Calendar
(
	DateValue DATE,
	DayofWeekNumber INT,
	DayofWeekName VARCHAR(32),
	DayofMonthNumber INT,
	MonthNumber INT,
	YearNumber INT,
	WeekendFlag TINYINT,
	HolidayFlag TINYINT
)

INSERT INTO AdventureWorks2019.dbo.Calendar
(
	DateValue,
	DayofWeekNumber,
	DayofWeekName,
	DayofMonthNumber,
	MonthNumber,
	YearNumber,
	WeekendFlag,
	HolidayFlag
)
VALUES
(CAST('01-01-2011' AS DATE), 7, 'Saturday', 1, 1, 2011, 1, 1),
(CAST('01-02-2011' AS DATE), 1, 'Sunday', 2, 1, 2011, 1, 1)

-- DO NOT manually enter date values
-- Use recursive CTEs

TRUNCATE TABLE AdventureWorks2019.dbo.Calendar;			-- Table cleared and ready to insert new values

-- Recursive CTE
WITH Dates AS
(
SELECT
	CAST('01-01-2011' AS DATE) AS MyDate

UNION ALL

SELECT
	DATEADD(DAY, 1, MyDate)
From Dates
WHERE MyDate < CAST('12-31-2030' AS DATE)
)

INSERT INTO AdventureWorks2019.dbo.Calendar(
DateValue
)
SELECT MyDate From Dates
OPTION (MAXRECURSION 10000);

UPDATE AdventureWorks2019.dbo.Calendar
SET
	DayofWeekNumber = DATEPART(WEEKDAY, DateValue),
	DayofWeekName = FORMAT(DateValue, 'dddd'),
	DayofMonthNumber = DAY(DateValue),
	MonthNumber = MONTH(DateValue),
	YearNumber = YEAR(DateValue)

UPDATE AdventureWorks2019.dbo.Calendar
SET
	WeekendFlag = 
		CASE 
			WHEN DayofWeekName in ('Saturday', 'Sunday') THEN 1
			ELSE 0
		END

UPDATE AdventureWorks2019.dbo.Calendar
SET
	HolidayFlag = 
		CASE 
			WHEN DayofMonthNumber = 1 AND MonthNumber = 1 THEN 1		-- New Year Day
			ELSE 0
		END

Select 
	A.*
From AdventureWorks2019.Sales.SalesOrderHeader A
	JOIN AdventureWorks2019.dbo.Calendar B
		ON A.OrderDate = B.DateValue
WHERE B.WeekendFlag = 1

Select * from AdventureWorks2019.dbo.Calendar


-- Exercises (OPTIMIZING using LOOKUP TABLE)
-- Exercise 1: Update your calendar lookup table with a few holidays of your choice that always fall on the same day of the year - for example, New Year's.
UPDATE AdventureWorks2019.dbo.Calendar
SET
	HolidayFlag = 
		CASE
			WHEN DayofMonthNumber = 1 AND MonthNumber = 1 THEN 1		-- New Year Day
			WHEN DayofMonthNumber = 15 AND MonthNumber = 8 THEN 1		-- Independence Day
			WHEN DayofMonthNumber = 25 AND MonthNumber = 12 THEN 1		-- Christmas Day
			WHEN DayofMonthNumber = 16 AND MonthNumber = 4 THEN 1		-- Random day
			ELSE 0
		END

-- Exercise 2: Using your updated calendar table, pull all purchasing orders that were made on a holiday. It's fine to simply select all columns via SELECT *.
Select A.* 
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	JOIN AdventureWorks2019.dbo.Calendar B
		ON A.OrderDate = B.DateValue
Where B.HolidayFlag = 1

-- Exercise 3: Again using your updated calendar table, now pull all purchasing orders that were made on a holiday that also fell on a weekend.
Select A.*
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	JOIN AdventureWorks2019.dbo.Calendar B
		ON A.OrderDate = B.DateValue
Where B.HolidayFlag = 1
	And B.WeekendFlag = 1

Select * from AdventureWorks2019.dbo.Calendar;

-- (V) OPTIMIZING with VIEWS
-- A view is essentially a virtual table based on the result set of a SQL query. It contains rows and columns just like a real table.
-- Offers Simplification, Consistent Logic, Query Abstraction
-- Particularly useful for users who might not know how to write complex queries or who might not be intimately familiar with how the tables in that particular database are related and thus not know how to join them together.


-- 11) Create a view making use of Rows between clause
CREATE VIEW Sales.VW_SalesRolling3Days AS 
Select
	OrderDate,
	TotalDue,
	SUM(TotalDue) OVER(ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)	SalesLast3Days
From (
	Select	
		OrderDate,
		SUM(TotalDue) TotalDue
	From AdventureWorks2019.Sales.SalesOrderHeader
	Where YEAR(OrderDate) = 2014
	Group By OrderDate
) Y

-- 12) Query the newly created View after creating a derived value
SELECT [OrderDate]
      ,[TotalDue]
      ,[SalesLast3Days]
	  ,FORMAT([TotalDue]/[SalesLast3Days], 'p') [% Rolling 3 Days Sales]
  FROM [AdventureWorks2019].[Sales].[VW_SalesRolling3Days];

-- EXERCISES (OPTIMIZING USING VIEWS)
-- Exercise 1: Create a view named vw_Top10MonthOverMonth in AdventureWorks.Sales, based on the query below.

CREATE VIEW Sales.vw_Top10MonthOverMonth AS 
-- The base Query
------------------------------------------------------------------
WITH Sales AS
(
SELECT
	 OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader
),
Top10Sales AS
(
SELECT
	OrderMonth,
	Top10Total = SUM(TotalDue)
FROM Sales
WHERE OrderRank <= 10
GROUP BY OrderMonth
)
SELECT
	A.OrderMonth,
	A.Top10Total,
	PrevTop10Total = B.Top10Total
FROM Top10Sales A
LEFT JOIN Top10Sales B
ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)

-- Order By 1				-- Removed when creating the View
--------------------------------------------------------------
-- Testing the View
SELECT TOP (1000) [OrderMonth]
      ,[Top10Total]
      ,[PrevTop10Total]
  FROM [AdventureWorks2019].[Sales].[vw_Top10MonthOverMonth]
 Order By 1

 -- Exercise 2: Try converting the below base query to a view.
 -- What happens? Why?

 CREATE VIEW Sales.vw_Top10SalesTempTable AS		-- WILL NOT WORK ON TEMP TABLES
-------------- The base Query -----------------------
 SELECT
	 OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #Sales
FROM AdventureWorks2019.Sales.SalesOrderHeader
 
SELECT
	OrderMonth,
	Top10Total = SUM(TotalDue)
INTO #Top10Sales
FROM #Sales
WHERE OrderRank <= 10
GROUP BY OrderMonth
 
SELECT
	A.OrderMonth,
	A.Top10Total,
	PrevTop10Total = B.Top10Total
FROM #Top10Sales A
LEFT JOIN #Top10Sales B
ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
-------------------------------------------------------------------------
/*
If a temporary table is used in a view definition, you'll receive an error.
In SQL Server, you cannot include temporary tables (either local or global) as part of a view definition. Temporary tables have a 
limited scope and lifespan; they exist only for the duration of a user session or the scope of the routine they were created in. 
Because of this transient nature, they cannot be used as part of a view, which should have a more permanent and consistent structure.
*/












