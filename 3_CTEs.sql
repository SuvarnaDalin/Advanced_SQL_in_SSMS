----------------- CTE and Recursive CTEs
-- (I) CTE

-- 1) Using Subquery do the following
-- Identify the ten biggest sales orders per month 
-- Aggregate these into a sum total, by month
-- Compare the sum of the ten biggest sales orders per month against the same total for the previous month.

Select
A.OrderMonth,
A.Top10Total,
B.Top10Total PrevTop10Total
From
(
Select 
OrderMonth,
SUM(TotalDue) Top10Total
FROM(
	Select 
		OrderDate,
		TotalDue,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) OrderMonth,			-- DATEFROMPARTS() returns Month in date form for all dates
		ROW_NUMBER() OVER( 
		PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)		-- Get Rank of TotalDue by OrderMonth
		ORDER BY TotalDue DESC
		) OrderRank
	From [AdventureWorks2019].[Sales].[SalesOrderHeader]
) X																				-- INNERMOST SUBQUERY
Where OrderRank <= 10
Group By OrderMonth
) A
LEFT JOIN
(
Select 
OrderMonth,
SUM(TotalDue) Top10Total
FROM(
	Select 
		OrderDate,
		TotalDue,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) OrderMonth,			-- DATEFROMPARTS() returns Month in date form for all dates
		ROW_NUMBER() OVER( 
		PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)		-- Get Rank of TotalDue by OrderMonth
		ORDER BY TotalDue DESC
		) OrderRank
	From [AdventureWorks2019].[Sales].[SalesOrderHeader]
) X																				-- INNERMOST SUBQUERY
Where OrderRank <= 10
Group By OrderMonth
) B
ON A.OrderMonth = DATEADD(MONTH, 1, B.OrderMonth)								-- Currnet Month = NextMonth
Order By 1

-- 2) Using CTE do the same
WITH Sales AS					-- First virtual Table (Step 1)
(
Select 
	OrderDate,
	TotalDue,
	DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) OrderMonth,			-- DATEFROMPARTS() returns Month in date form for all dates
	ROW_NUMBER() OVER( 
	PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)		-- Get Rank of TotalDue by OrderMonth
	ORDER BY TotalDue DESC
	) OrderRank
From [AdventureWorks2019].[Sales].[SalesOrderHeader]
),
Top10 AS
(
Select 
	OrderMonth,
	SUM(TotalDue) Top10Total
FROM Sales
Where OrderRank <= 10
Group By OrderMonth
)
Select 
	A.OrderMonth,
	A.Top10Total,
	B.Top10Total PrevTop10Total
From Top10 A
	Left Join Top10 B
	ON A.OrderMonth = DATEADD(MONTH, 1, B.OrderMonth)
Order By OrderMonth

--Exercises: CTE
--Exercise 1: Top 10 orders per month are actually outliers that need to be clipped out of our data before doing meaningful analysis. (Get Sales except Top10)
-- Further the sum of sales AND purchases (minus these "outliers") listed side by side, by month. (Get Purchases except Top10)
WITH Top10Sales AS
(
SELECT
	OrderMonth,
	SUM(TotalDue) TotalSales
FROM (
	SELECT 
		OrderDate,
		DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
		TotalDue,
		ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
	FROM AdventureWorks2019.Sales.SalesOrderHeader
	) S
WHERE OrderRank > 10
GROUP BY OrderMonth
),
Top10Purchases AS
(
SELECT
	OrderMonth,
	SUM(TotalDue) TotalPurchases
FROM (
	SELECT 
		OrderDate,
		DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
		TotalDue,
		ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
	FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader
	) P
WHERE OrderRank > 10
GROUP BY OrderMonth
)
Select 
	TopS.OrderMonth, 
	TotalSales, 
	TotalPurchases
From Top10Sales TopS
	Join Top10Purchases TopP
	On TopS.OrderMonth = TopP.OrderMonth
Order By OrderMonth;


-- METHOD 2 - NO Sub Queries only CTE
WITH SALES AS
(
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
FROM AdventureWorks2019.Sales.SalesOrderHeader
),
SalesExceptTop10 AS
(
Select
	OrderMonth,
	SUM(TotalDue) TotalSales
From Sales
Where OrderRank > 10
Group By OrderMonth
),
Purchases AS
(
SELECT 
	OrderDate,
	DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) OrderMonth,
	TotalDue,
	ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC) OrderRank
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader
),
PurchasesExceptTop10 AS
(
Select 
	OrderMonth,
	SUM(TotalDue) TotalPurchases
From Purchases
Where OrderRank > 10
Group By OrderMonth
)
Select 
	SET10.OrderMonth,
	SET10.TotalSales,
	PET10.TotalPurchases
From SalesExceptTop10 SET10
	Join PurchasesExceptTop10 PET10
	On SET10.OrderMonth = PET10.OrderMonth
Order By 1

-- (II) Recursive CTEs
-- Contains 3 elements:
--	1. Anchor Member
--	2. UNION ALL
--	3. Recursive Member

-- 3) Create Number Series using Recursive CTE

WITH NumberSeries as
(
Select 1 as MyNumber			-- Anchor member

UNION ALL						-- Union All

Select MyNumber + 1				-- Recursive Member
From NumberSeries
Where MyNumber < 100
-- Where MyNumber <= 100		-- Generates 101 nos

)
Select MyNumber -- Instead of Where clause can use Top 100
From NumberSeries;

-- 4) Create Date Series using Recursive CTE

WITH DateSeries AS
(
Select CAST('01-01-2021' AS DATE) AS MyDate

UNION ALL

Select DATEADD(DAY, 1, MyDate)
From DateSeries
Where MyDate < CAST('12-31-2021' AS DATE)
)
Select MyDate
From DateSeries
OPTION (MAXRECURSION 365)


--Exercises: Recursive CTE
--Exercise 1: Generate a list of all odd numbers between 1 and 100.
WITH OddSeries as
(
Select 1 as OddNumber			-- Anchor member

UNION ALL						-- Union All

Select OddNumber + 2				-- Recursive Member
From OddSeries
Where OddNumber < 99

)
Select OddNumber -- Instead of Where clause can use Top 100
From OddSeries;

-- Exercise 2: Use a recursive CTE to generate a date series of all FIRST days of the month (1/1/2021, 2/1/2021, etc.) from 1/1/2020 to 12/1/2029.
WITH DateSeries AS
(
Select CAST('01-01-2021' AS DATE) AS MyDate

UNION ALL

Select DATEADD(MONTH, 1, MyDate)
From DateSeries
Where MyDate < CAST('12-01-2029' AS DATE)
)
Select MyDate
From DateSeries
OPTION (MAXRECURSION 365)



























































