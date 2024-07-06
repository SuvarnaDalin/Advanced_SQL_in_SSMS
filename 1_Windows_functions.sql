-- 1) All Rows
Select * 
From [AdventureWorks2019].[Sales].[SalesOrderHeader]

--2) Sum & Max of Total Sales
Select SUM(SalesYTD) as TotalSales, MAX(SalesYTD) as MaxSales
From [AdventureWorks2019].[Sales].[SalesPerson]
 
--3) Sum of Total Sales by Sales Person by Aggregating
Select SUM([SalesYTD]) as TotalSales, BusinessEntityID
From [AdventureWorks2019].[Sales].[SalesPerson]
Group By BusinessEntityID

--------- WINDOW FUNCTIONS ------------
/* Window functions allow you to perform calculations like sum and count across groups of rows within your
data, or alternately, all the rows in your data set.
Whereas aggregate functions collapse the rows of your data into groups based on the unique values and
the columns you include in your select statement. */

-- (I) OVER()
--4) Sum using Window Function making use of 'OVER()' function. Dont have to Group By, can have multiple rows with aggregated value per row.
select 
BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear, 
SUM([SalesYTD]) OVER() as "Total YTD Sales",
MAX([SalesYTD]) OVER() as "Max YTD Sales",
[SalesYTD]/MAX([SalesYTD]) OVER() as "% of Best Performer"
From [AdventureWorks2019].[Sales].[SalesPerson]

--Exercises: OVER()
--Exercise 1: Average Salary
SELECT 
 B.FirstName,
 B.LastName,
 C.JobTitle,
 A.Rate,
 AverageRate = AVG(A.Rate) OVER()

FROM AdventureWorks2019.HumanResources.EmployeePayHistory A
	JOIN AdventureWorks2019.Person.Person B
		ON A.BusinessEntityID = B.BusinessEntityID
	JOIN AdventureWorks2019.HumanResources.Employee C
		ON A.BusinessEntityID = C.BusinessEntityID



--Exercise 2: Maximum Salary
SELECT 
 B.FirstName,
 B.LastName,
 C.JobTitle,
 A.Rate,
 AverageRate = AVG(A.Rate) OVER(),
 MaximumRate = MAX(A.Rate) OVER()

FROM AdventureWorks2019.HumanResources.EmployeePayHistory A
	JOIN AdventureWorks2019.Person.Person B
		ON A.BusinessEntityID = B.BusinessEntityID
	JOIN AdventureWorks2019.HumanResources.Employee C
		ON A.BusinessEntityID = C.BusinessEntityID


--Exercise 3: Add Difference From Avg Salary
Select 
A.FirstName, A.LastName, B.JobTitle, C.Rate, 
AVG(C.Rate) OVER() as AverageRate,
MAX(C.Rate) OVER() as MaximumRate,
C.Rate - AVG(C.Rate) OVER() as DiffFromAvgRate
From AdventureWorks2019.Person.Person A
  Inner join AdventureWorks2019.HumanResources.Employee B
    On A.BusinessEntityID = B.BusinessEntityID
  Inner join AdventureWorks2019.HumanResources.EmployeePayHistory C
    On C.BusinessEntityID = B.BusinessEntityID



--Exercise 4: Enhnace with PercentofMaxRate. NOTE: *100 comes AFTER OVER()
Select 
A.FirstName, A.LastName, B.JobTitle, C.Rate, 
AVG(C.Rate) OVER() as AverageRate,
MAX(C.Rate) OVER() as MaximumRate,
C.Rate - AVG(C.Rate) OVER() as DiffFromAvgRate,
(C.Rate/MAX(C.Rate) OVER()) *100 as PercentofMaxRate
From AdventureWorks2019.Person.Person A
  Inner join AdventureWorks2019.HumanResources.Employee B
    On A.BusinessEntityID = B.BusinessEntityID
  Inner join AdventureWorks2019.HumanResources.EmployeePayHistory C
    On C.BusinessEntityID = B.BusinessEntityID



-- (II) PARTITION BY
/* When we combine our OVER() function with partition by, we now have the power to compute aggregate totals
for groups within our data while still retaining that row level detail that distinguishes window functions */

-- 5) Sum of line totals per Order Qty by Group by 
Select ProductID, OrderQty, SUM(LineTotal) LineTotal
From AdventureWorks2019.Sales.SalesOrderDetail
Group By ProductID, OrderQty
Order By ProductID, OrderQty Desc

-- 6) Sum of line totals per Order Qty by OVER()
Select ProductID, SalesOrderID, SalesOrderDetailID, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal,
SUM(LineTotal) OVER() ProductIDLineTotal
From AdventureWorks2019.Sales.SalesOrderDetail
Order By ProductID, OrderQty Desc


-- 7) Sum of line totals per Order Qty by OVER() & PARTITION BY
Select ProductID, SalesOrderID, SalesOrderDetailID, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal,
SUM(LineTotal) OVER(
PARTITION BY ProductID, OrderQty
) ProductIDLineTotal
From AdventureWorks2019.Sales.SalesOrderDetail
Order By ProductID, OrderQty Desc


--Exercises: OVER() & PARTITION BY

--Exercise 1:
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category
From AdventureWorks2019.Production.Product P
	Inner join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 2: Enhance with AvgPriceByCategory 
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,
AVG(P.ListPrice) OVER(
PARTITION BY PC.Name
) as AvgPriceByCategory 
From AdventureWorks2019.Production.Product P
	Inner join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 3: Enhance with AvgPriceByCategoryAndSubcategory 
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

AVG(P.ListPrice) OVER(
PARTITION BY PC.Name
) as AvgPriceByCategory, 

AVG(P.ListPrice) OVER(
PARTITION BY PC.Name, PSC.Name
) as AvgPriceByCategoryAndSubcategory 

From AdventureWorks2019.Production.Product P
	Inner join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 4: Enhance with ProductVsCategoryDelta = list price MINUS the average ListPrice for that Product category
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

AVG(P.ListPrice) OVER(
PARTITION BY PC.Name
) as AvgPriceByCategory, 

AVG(P.ListPrice) OVER(
PARTITION BY PC.Name, PSC.Name
) as AvgPriceByCategoryAndSubcategory, 

P.ListPrice - AVG(P.ListPrice) OVER(
PARTITION BY PC.Name
) as ProductVsCategoryDelta

From AdventureWorks2019.Production.Product P
	Inner join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID


-- (III) RANKING WITH ROW_NUMBER()
-- Ranking is done using ROW_NUMBER(), RANK(), DENSE RANK()
-- 8) Ranking (Ascending) all records within each group of sales order IDs
select SalesOrderID, SalesOrderDetailID, LineTotal,

SUM(LineTotal) OVER(
PARTITION BY SalesOrderID
) ProductIDLineTotal,

ROW_NUMBER() OVER(
PARTITION BY SalesOrderID ORDER BY LineTotal
) Ranking

From AdventureWorks2019.Sales.SalesOrderDetail
Order By SalesOrderID

-- 9) Ranking (Descending) all records within each group of sales order IDs(Partitioned)
select SalesOrderID, SalesOrderDetailID, LineTotal,

SUM(LineTotal) OVER(
PARTITION BY SalesOrderID
) ProductIDLineTotal,

ROW_NUMBER() OVER(
PARTITION BY SalesOrderID ORDER BY LineTotal DESC
) Ranking

From AdventureWorks2019.Sales.SalesOrderDetail
Order By SalesOrderID

-- 9) Ranking (Descending) all records W.R.T LineTotal
select SalesOrderID, SalesOrderDetailID, LineTotal,

SUM(LineTotal) OVER(
PARTITION BY SalesOrderID
) ProductIDLineTotal,

ROW_NUMBER() OVER(
Order By LineTotal DESC
) Ranking

From AdventureWorks2019.Sales.SalesOrderDetail
Order By Ranking

-- ** BUT TOWARDS THE END SAME LINETOTAL HAVE DIFFERENT RANKS WHEN USING ROW_NUMBER(). INSTEAD DENSE RANK CAN BE USED

--Exercises: OVER() & PARTITION BY & ROW_NUMBER()

--Exercise 1:
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category 
From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 2: Enhance with PriceRank (ranks all records in the dataset by ListPrice, in descending order. That is to say, the product with the most expensive price should have a rank of 1, and the product with the least expensive price should have a rank equal to the number of records in the dataset)
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) PriceRank

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 3: Enhance with Category Price Rank (ranks all products by ListPrice – within each category - in descending order. In other words, every product within a given category should be ranked relative to other products in the same category)
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) PriceRank,

ROW_NUMBER() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
) CategoryPriceRank

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 4: Enhance with "Top 5 Price In Category" (that returns the string “Yes” if a product has one of the top 5 list prices in its product category, and “No” if it does not. You can try incorporating your logic from Exercise 3 into a CASE statement to make this work.)
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) PriceRank,

ROW_NUMBER() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
) CategoryPriceRank,

CASE 
	WHEN ROW_NUMBER() OVER(PARTITION BY PC.Name ORDER BY P.ListPrice DESC) <= 5 THEN 'Yes'
	ELSE 'No' 
END "Top 5 Price In Category"

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

-- (III) RANKING WITH RANK()
--10) Ranking ALL records by Line Total - no groups
select SalesOrderID, SalesOrderDetailID, LineTotal,

ROW_NUMBER() OVER( PARTITION BY SalesOrderID ORDER BY LineTotal DESC) Ranking,
RANK() OVER( PARTITION BY SalesOrderID ORDER BY LineTotal DESC) RankingByRank

From AdventureWorks2019.Sales.SalesOrderDetail
Order By SalesOrderID, LineTotal DESC

-- WITH RANK() The ranking does not move from one number to next number if there are repeated ranks (1,2, 3,3,3, to 6) instead skips the number depending on number of repeats
-- Hence use Dense_Rank()

-- (III) RANKING WITH DENSE_RANK()
--10) Ranking ALL records by Line Total - no groups
select SalesOrderID, SalesOrderDetailID, LineTotal,

ROW_NUMBER() OVER( PARTITION BY SalesOrderID ORDER BY LineTotal DESC) Ranking,
RANK() OVER( PARTITION BY SalesOrderID ORDER BY LineTotal DESC) RankingByRank,
DENSE_RANK() OVER( PARTITION BY SalesOrderID ORDER BY LineTotal DESC) RankingByDense_Rank

From AdventureWorks2019.Sales.SalesOrderDetail
Order By SalesOrderID, LineTotal DESC

--Exercises: OVER() & PARTITION BY & ROW_NUMBER() & RANK()
--Exercise 1: Enhance previous Exercise 4 with “Category Price Rank With Rank” that uses the RANK function to rank all products by ListPrice – within each category - in descending order)
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) "Price Rank",

ROW_NUMBER() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
) "Category Price Rank",

RANK() OVER(
PARTITION BY PC.Name Order By P.ListPrice DESC
) "Category Price Rank with Rank",

CASE 
	WHEN ROW_NUMBER() OVER(PARTITION BY PC.Name ORDER BY P.ListPrice DESC) <= 5 THEN 'Yes'
	ELSE 'No' 
END "Top 5 Price In Category"

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 2: Enhance with "Category Price Rank With Dense Rank" that that uses the DENSE_RANK function to rank all products by ListPrice – within each category - in descending order
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) "Price Rank",

ROW_NUMBER() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
) "Category Price Rank",

RANK() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
)  "Category Price Rank with Rank",

DENSE_RANK() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
)  "Category Price Rank with Dense Rank",

CASE
	WHEN ROW_NUMBER() OVER(PARTITION BY PC.Name ORDER BY P.ListPrice DESC) <=5 THEN 'Yes'
	ELSE 'N'
END "Top 5 Price In Category"

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

--Exercise 3: Correct “Top 5 Price In Category” (most appropriate to return a true top 5 products by price, assuming we want to see the top 5 distinct prices AND we want “ties” (by price) to all share the same rank.)
Select P.Name ProductName, P.ListPrice, PSC.Name SubCategory, PC.Name Category,

ROW_NUMBER() OVER(
ORDER BY P.ListPrice DESC
) "Price Rank",

ROW_NUMBER() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
) "Category Price Rank",

RANK() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
)  "Category Price Rank with Rank",

DENSE_RANK() OVER(
PARTITION BY PC.Name ORDER BY P.ListPrice DESC
)  "Category Price Rank with Dense Rank",

CASE
	WHEN DENSE_RANK() OVER(PARTITION BY PC.Name ORDER BY P.ListPrice DESC) <=5 THEN 'Yes'
	ELSE 'N'
END "Top 5 Price In Category"

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductSubcategory PSC
		On P.ProductSubcategoryID = PSC.ProductSubcategoryID
	Inner Join AdventureWorks2019.Production.ProductCategory PC
		On PSC.ProductCategoryID = PC.ProductCategoryID

-- (IV) LEAD & LAG
/* Used Any time we want to compare a value in a given column to the next or previous value in the same column,
but side by side in the same row. BEST Results: USE DEFAULT SORT ORDER*/
-- 11) Use Lead & Lag w.r.t SalesOrderID to calculate NextTotalDue & PreviousTotalDue
Select SalesOrderID, OrderDate, CustomerID, TotalDue,

LEAD(TotalDue,1) OVER(ORDER BY SalesOrderID) NextTotalDue, --One Row into Future
LAG(TotalDue,1) OVER(ORDER BY SalesOrderID) PreviousTotalDue, --One Row into Past

LEAD(TotalDue,2) OVER(ORDER BY SalesOrderID) NextTotalDue, --Two Rows into Future
LAG(TotalDue,2) OVER(ORDER BY SalesOrderID) PreviousTotalDue --Two Rows into Past

From AdventureWorks2019.Sales.SalesOrderHeader
Order By salesOrderID

-- 12) Use Lead & Lag w.r.t SalesOrderID to calculate NextTotalDue & PreviousTotalDue partition by CustomerID
Select SalesOrderID, OrderDate, CustomerID, TotalDue,

LEAD(TotalDue,1) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) NextTotalDue, --One Row into Future
LAG(TotalDue,1) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) PreviousTotalDue --One Row into Past

From AdventureWorks2019.Sales.SalesOrderHeader
Order By CustomerID, SalesOrderID

--Exercises: OVER() & PARTITION BY & LEAD() & LAG()
-- Exercise 1: Get table with Order Year >= 2023 and Total Due > $500
Select P.PurchaseOrderID, P.OrderDate, P.TotalDue, PV.Name VendorName
From AdventureWorks2019.Purchasing.PurchaseOrderHeader P
 Inner Join AdventureWorks2019.Purchasing.Vendor PV
	On P.VendorID = PV.BusinessEntityID
 Where YEAR(P.OrderDate) >= 2013
	And P.TotalDue > 500

-- Exercise 2: Enhance with "PrevOrderFromVendorAmt", (returns the “previous” TotalDue value (relative to the current row) within the group of all orders with the same vendor ID. We are defining “previous” based on order date.)
Select P.PurchaseOrderID, P.VendorID, P.OrderDate, P.TotalDue, PV.Name VendorName,

LAG(TotalDue,1) OVER (PARTITION BY P.VendorID ORDER BY P.OrderDate) PrevOrderFromVendorAmt

From AdventureWorks2019.Purchasing.PurchaseOrderHeader P
 Inner Join AdventureWorks2019.Purchasing.Vendor PV
	On P.VendorID = PV.BusinessEntityID
 Where YEAR(P.OrderDate) >= 2013
	And P.TotalDue > 500

Order By P.VendorID, P.OrderDate

-- Exercise 3: Enhance with "NextOrderByEmployeeVendor", (returns the “next” vendor name (the “name” field from Purchasing.Vendor) within the group of all orders that have the same EmployeeID value in Purchasing.PurchaseOrderHeader)
Select P.PurchaseOrderID, P.EmployeeID, P.OrderDate, P.TotalDue, PV.Name VendorName,

LAG(TotalDue,1) OVER (PARTITION BY P.VendorID ORDER BY P.OrderDate) PrevOrderFromVendorAmt,
LEAD(PV.Name,1) OVER (PARTITION BY P.EmployeeID ORDER BY P.OrderDate) NextOrderByEmployeeVendor

From AdventureWorks2019.Purchasing.PurchaseOrderHeader P
 Inner Join AdventureWorks2019.Purchasing.Vendor PV
	On P.VendorID = PV.BusinessEntityID
 Where YEAR(P.OrderDate) >= 2013
	And P.TotalDue > 500

Order By P.EmployeeID,P.OrderDate

-- Exercise 4: Enhance with "Next2OrderByEmployeeVendor" (returns, within the group of all orders that have the same EmployeeID, the vendor name offset TWO orders into the “future” relative to the order in the current row.)
Select P.PurchaseOrderID, P.EmployeeID, P.OrderDate, P.TotalDue, PV.Name VendorName,

LAG(TotalDue,1) OVER (PARTITION BY P.VendorID ORDER BY P.OrderDate) PrevOrderFromVendorAmt,
LEAD(PV.Name,1) OVER (PARTITION BY P.EmployeeID ORDER BY P.OrderDate) NextOrderByEmployeeVendor,
LEAD(PV.Name,2) OVER (PARTITION BY P.EmployeeID ORDER BY P.OrderDate) Next2OrderByEmployeeVendor

From AdventureWorks2019.Purchasing.PurchaseOrderHeader P
 Inner Join AdventureWorks2019.Purchasing.Vendor PV
	On P.VendorID = PV.BusinessEntityID
 Where YEAR(P.OrderDate) >= 2013
	And P.TotalDue > 500

Order By P.EmployeeID,P.OrderDate


-- (V) FIRST_VALUE()
/*  Returns column with the highest value(Sorted DESC) or Lowest value (Default Sort) in the column mentioned within () for any given partition. 
OR Returns the value from Oldest date(default Sort) or the value from Newest date(DESC Sort)if ordered by Date) */
-- 13) Highest & Lowest LineTotal Value per Sales Order
Select SalesOrderID, SalesOrderDetailID, LineTotal,

ROW_NUMBER() OVER(
PARTITION BY SalesOrderID ORDER BY LineTotal DESC
) Ranking,

FIRST_VALUE(LineTotal) OVER(
PARTITION BY SalesOrderID ORDER BY LineTotal DESC
) HighestTotal,

FIRST_VALUE(LineTotal) OVER(
PARTITION BY SalesOrderID ORDER BY LineTotal
) LowestTotal

From AdventureWorks2019.Sales.SalesOrderDetail

-- 14) Oldest Customer Order & Most Recent Order amount by CustomerID
Select CustomerID, OrderDate, TotalDue,

FIRST_VALUE(TotalDue) OVER(
PARTITION BY CustomerID ORDER BY OrderDate
) FirstOrderAmount,

FIRST_VALUE(TotalDue) OVER(
PARTITION BY CustomerID ORDER BY OrderDate DESC
) MostRecentOrderAmount

From AdventureWorks2019.Sales.SalesOrderHeader

--Exercises: OVER() & PARTITION BY & FIRST_VALUE()

-- Exercise 1: “FirstHireVacationHours” that displays – for a given job title – the amount of vacation hours possessed by the first employee hired who has that same job title. For example, if 5 employees have the title “Data Guru”, and the one of those 5 with the oldest hire date has 99 vacation hours, “FirstHireVacationHours” should display “99” for all 5 of those employees’ corresponding records in the query.)
Select BusinessEntityID EmployeeID, JobTitle, HireDate, VacationHours,

FIRST_VALUE(VacationHours) OVER (
PARTITION BY JobTitle ORDER BY HireDate
) FirstHireVacationHours

From AdventureWorks2019.HumanResources.Employee
Order By JobTitle, HireDate

-- Exercise 2: 
/* “HighestPrice” that displays – for a given product – the highest price that product has been listed at
   “LowestCost” that displays the all-time lowest price for a given product
   “PriceRange” that reflects, for a given product, the difference between its highest and lowest ever list prices */
Select P.ProductID, P.Name ProductName, PLH.ListPrice, PLH.ModifiedDate,

FIRST_VALUE(PLH.ListPrice) OVER(
PARTITION BY P.ProductID Order By PLH.ListPrice DESC
) HighestPrice,

FIRST_VALUE(PLH.ListPrice) OVER(
PARTITION BY P.ProductID Order By PLH.ListPrice
) LowestPrice,

FIRST_VALUE(PLH.ListPrice) OVER(PARTITION BY P.ProductID Order By PLH.ListPrice DESC) -
FIRST_VALUE(PLH.ListPrice) OVER(PARTITION BY P.ProductID Order By PLH.ListPrice) PriceRange

From AdventureWorks2019.Production.Product P
	Inner Join AdventureWorks2019.Production.ProductListPriceHistory PLH
		On P.ProductID = PLH.ProductID
Order By P.ProductID, ModifiedDate


-- (VI) SUBQUERIES IN WINDOW FUNCTIONS
-- 15) Create Ranking column using ROW_NUMBER() and select only those where Ranking = 1
Select * 

From

--Sub Query
(Select 
	SalesOrderID,
	SalesOrderDetailID,
	LineTotal,
	ROW_NUMBER() OVER (
		PARTITION BY SalesOrderID ORDER BY LineTotal DESC
		) Ranking
From AdventureWorks2019.Sales.SalesOrderDetail
) RankTable -- ALIASING IS VERY IMPORTANT

Where Ranking = 1

--Exercises: OVER() & PARTITION BY & SUB QUERY

-- Exercise 1: Get most expensive orders, per vendor ID. There should ONLY be three records per Vendor ID, even if some of the total amounts due are identical
Select * 
From
(Select 
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue,
	ROW_NUMBER() OVER(
		PARTITION BY VendorID  ORDER BY TotalDue DESC
		) PurchaseOrderRank
From AdventureWorks2019.Purchasing.PurchaseOrderHeader
) RankedTable
Where PurchaseOrderRank <= 3

-- Exercise 2: Modify Ex 1, top three purchase order amounts are returned, regardless of how many records are returned per Vendor Id. 
Select PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue
From
(
	Select 
		PurchaseOrderID,
		VendorID,
		OrderDate,
		TaxAmt,
		Freight,
		TotalDue,
		DENSE_RANK() OVER(
			PARTITION BY VendorID ORDER BY TotalDue DESC
			) PurchaseOrderRank
	From AdventureWorks2019.Purchasing.PurchaseOrderHeader
) DenseRankedTbl
Where PurchaseOrderRank <= 3


-- (VII) ROWS BETWEEN
/* Target the current row and the two rows prior. OR Target the current row and three rows after that 
Useful to calculate Rolling Totals & Rolling/ Moving average
Moving averages are good at smoothing out short term fluctuations in the overall trending of our data, making it easier to identify patterns and longer term trends.*/

-- 16) Rollong 3 Day Total (Including current row & not including Current Row)
Select 
	OrderDate,
	TotalDues,
	SUM(TotalDues) OVER( 
		ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Including Current Row
	) RollingLast3DayTotal,

	SUM(TotalDues) OVER(
		ORDER BY OrderDate ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
	) RollingPrevious3DayTotal

From (
	Select 
		OrderDate, sum(TotalDue) TotalDues
	From 
		AdventureWorks2019.Sales.SalesOrderHeader
	Where YEAR(OrderDate) = 2014
	Group By 
		OrderDate
) DuesTbl
Order By 
	OrderDate

-- 17) Rollong 3 Day Total (Including preceding, current row, row after  & not including Current Row)
Select 
	OrderDate,
	TotalDues,
	SUM(TotalDues) OVER( 
		ORDER BY OrderDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	) Rolling3DayTotal_b4CRTaftr,

	SUM(TotalDues) OVER(
		ORDER BY OrderDate ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
	) Rolling3DayTotal_CRT2aftr

From (
	Select 
		OrderDate, sum(TotalDue) TotalDues
	From 
		AdventureWorks2019.Sales.SalesOrderHeader
	Where YEAR(OrderDate) = 2014
	Group By 
		OrderDate
) DuesTbl
Order By 
	OrderDate

-- 18) Moving 3 Day Average
Select 
	OrderDate,
	TotalDues,
	AVG(TotalDues) OVER( 
		ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) RollingLast3DayAvg

From (
	Select 
		OrderDate, sum(TotalDue) TotalDues
	From 
		AdventureWorks2019.Sales.SalesOrderHeader
	Where YEAR(OrderDate) = 2014
	Group By 
		OrderDate
) DuesTbl
Order By 
	OrderDate

--Exercises: OVER() & PARTITION BY & SUB QUERY & ROWS BETWEEN

-- Exercise 1: 
Select  
	YEAR(OrderDate) OrderYear, 
	MONTH(OrderDate) OrderMonth,
	SUM(SubTotal) SubTotals
From AdventureWorks2019.Purchasing.PurchaseOrderHeader
Group By YEAR(OrderDate), MONTH(OrderDate)
Order By YEAR(OrderDate), MONTH(OrderDate)

-- Exercise 2: Modify add "Rolling3MonthTotal", that displays  - for a given row - a running total of “SubTotal” for the prior three months (including the current row).
Select *,
	SUM(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Including Current Row
	) Rolling3MonthTotal
From(
	Select  
		YEAR(OrderDate) OrderYear, 
		MONTH(OrderDate) OrderMonth,
		SUM(SubTotal) SubTotals
	From AdventureWorks2019.Purchasing.PurchaseOrderHeader
	Group By YEAR(OrderDate), MONTH(OrderDate)
) SubTotTbl
Order By OrderYear, OrderMonth

-- Exercise 3: Modify with "MovingAvg6Month", that calculates a rolling average of “SubTotal” for the previous 6 months, relative to the month in the “current” row. Note that this average should NOT include the current row
Select *,
	SUM(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Including Current Row
	) Rolling3MonthTotal,
	AVG(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING -- Not Including Current Row
	) MovingAvg6Month
From(
	Select  
		YEAR(OrderDate) OrderYear, 
		MONTH(OrderDate) OrderMonth,
		SUM(SubTotal) SubTotals
	From AdventureWorks2019.Purchasing.PurchaseOrderHeader
	Group By YEAR(OrderDate), MONTH(OrderDate)
) SubTotTbl
Order By OrderYear, OrderMonth

-- Exercise 4: Modify with “MovingAvgNext2Months” , that calculates a rolling average of “SubTotal” for the month in the current row and the next two months after that. This moving average will provide a kind of "forecast" for Subtotal by month
Select *,
	SUM(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Including Current Row
	) Rolling3MonthTotal,
	AVG(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING -- Not Including Current Row
	) MovingAvg6Month,
	AVG(SubTotals) OVER(
	ORDER BY OrderYear, OrderMonth ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING -- Including Current Row
	) MovingAvgNext2Months
From(
	Select  
		YEAR(OrderDate) OrderYear, 
		MONTH(OrderDate) OrderMonth,
		SUM(SubTotal) SubTotals
	From AdventureWorks2019.Purchasing.PurchaseOrderHeader
	Group By YEAR(OrderDate), MONTH(OrderDate)
) SubTotTbl
Order By OrderYear, OrderMonth







