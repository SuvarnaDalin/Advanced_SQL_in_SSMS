--------- TOPICS COVERED ------------
/*
	(I) SCALAR SUB QUERIES
	(II) CORRELATED SUB QUERIES
	(III) SUBQUERIES WITH EXISTS AND NOT EXISTS
	(IV) SUBQUERIES with 'FOR XML PATH' and 'STUFF'
	(V) SUBQUERIES with PIVOT
*/

-- SUB QUERY CAN RETURN ONLY A SINGLE COLUMN
-- (I) SCALAR SUB QUERIES
-- Does similar things Window function does
-- Main Difference compared to Window Functions: we cannot include window functions in the where clause, but we can include scalar subqueries.
-- Used in Aggregate Functions
-- 1) Get Avg List price displayed in all rows of the table and get Difference btwn ListPrice & AvgListPrice
Select 
	ProductID,
	[Name],
	StandardCost,
	ListPrice,
	(Select AVG(ListPrice) From AdventureWorks2019.Production.Product) AvgListPrice,					--Sub Query
	ListPrice - (Select AVG(ListPrice) From AdventureWorks2019.Production.Product ) AvgListPriceDiff	--Sub Query used in Difference
From AdventureWorks2019.Production.Product

-- 2) Modify above, Where ListPrice > AvgListPrice
Select 
	ProductID,
	[Name],
	StandardCost,
	ListPrice,
	(Select AVG(ListPrice) From AdventureWorks2019.Production.Product) AvgListPrice,					--Sub Query
	ListPrice - (Select AVG(ListPrice) From AdventureWorks2019.Production.Product ) AvgListPriceDiff	--Sub Query used in Difference
From AdventureWorks2019.Production.Product
Where ListPrice > (Select AVG(ListPrice) From AdventureWorks2019.Production.Product)
Order by ListPrice

-- Exercises: SCALAR SUB QUERIES
-- Exercise 1: Create a query that includes a derived column called "MaxVacationHours" that returns the maximum amount of vacation hours for any one employee, in any given row.
Select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	(Select MAX(VacationHours) 
	From AdventureWorks2019.HumanResources.Employee
	) MaxVacationHours
From AdventureWorks2019.HumanResources.Employee

-- Exercise 2: Modify with percent an individual employees' vacation hours are, of the maximum vacation hours for any employee. 
Select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	(Select MAX(VacationHours) 
	From AdventureWorks2019.HumanResources.Employee
	) MaxVacationHours,
	(VacationHours*1.0 / (Select MAX(VacationHours) From AdventureWorks2019.HumanResources.Employee)) * 100 PercOfMaxVacationHours
From AdventureWorks2019.HumanResources.Employee

-- Exercise 3: Modify with return only employees who have at least 80% as much vacation time as the employee with the most vacation time.
Select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	(Select MAX(VacationHours) 
	From AdventureWorks2019.HumanResources.Employee
	) MaxVacationHours,
	(VacationHours*1.0 / (Select MAX(VacationHours) From AdventureWorks2019.HumanResources.Employee)) * 100 PercOfMaxVacationHours
From AdventureWorks2019.HumanResources.Employee
Where (VacationHours*1.0 / (Select MAX(VacationHours) From AdventureWorks2019.HumanResources.Employee)) * 100 >= 80
Order By VacationHours DESC

-- (II) CORRELATED SUB QUERIES
-- correlated subqueries are subqueries that run once for each record in the main or outer query and then return a single value for that record.
-- They are typically connected to the outer query by some common field like a join.
-- 3) If we want one row per sales order with a column that tells us how many items within that order had a quantity greater than one, a correlated subquery is probably the fastest way to achieve
Select 
	SalesOrderID,
	OrderDate,
	SubTotal,
	TaxAmt,
	Freight,
	TotalDue,
	(
	Select COUNT(*)
	From AdventureWorks2019.Sales.SalesOrderDetail B
	Where B.SalesOrderID = A.SalesOrderID		-- Here it works like JOIN btwn Outer Query Table & Inner Table Query (Joined On SalesOrderID)
	And B.OrderQty > 1
	) MultiOrderCount
From AdventureWorks2019.Sales.SalesOrderHeader A

-- Easiest to understand how the subquery works by first coding it independently. Get OrderQty per OrderID (Eg: 43659)
/*
Select SalesOrderID, OrderQty
From Sales.SalesOrderDetail
Where SalesOrderID = 43659 -- Here there are 6 Orders with OrderQty>1 (OrderQty's 2,2,3,4,5,6)
*/

-- Exercises: CORRELATED SUB QUERIES
-- Exercise 2: Create a query that includes a derived column called NonRejectedItems which returns, for each purchase order ID in the query output, the number of line items from the Purchasing.PurchaseOrderDetail table which did not have any rejections (i.e., RejectedQty = 0)
Select
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TotalDue,
	(
	Select COUNT(*)
	From AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	Where B.PurchaseOrderID = A.PurchaseOrderID
	And B.RejectedQty = 0
	) NonRejectedItems
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A

/*
Select 
	PurchaseOrderID,
	RejectedQty
From Purchasing.PurchaseOrderDetail
Where PurchaseOrderID = 27
*/

-- Exercise 3: Modify with MostExpensiveItem, (return, for each purchase order ID, the UnitPrice of the most expensive item for that order in the Purchasing.PurchaseOrderDetail table)
Select
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TotalDue,
	(
	Select COUNT(*)
	From Purchasing.PurchaseOrderDetail B
		Where B.PurchaseOrderID = A.PurchaseOrderID
		And B.RejectedQty = 0
	) NonRejectedItems,
	(
	Select MAX(B.UnitPrice)
	From Purchasing.PurchaseOrderDetail B
		Where B.PurchaseOrderID = A.PurchaseOrderID
	) MostExpensiveItem
From Purchasing.PurchaseOrderHeader A

/*
Select 
	PurchaseOrderID,
	UnitPrice
From Purchasing.PurchaseOrderDetail
Where PurchaseOrderID = 4
*/

-- (III) SUBQUERIES WITH EXISTS AND NOT EXISTS
/* USES EXISTS IF:
You want to apply criteria to fields from a secondary table but don't need to include those fields in your output.(Provided tables have 1 to 1 relationship)
You only want one record in your output per each match from the one side of the relationship stick with exists.
You need to check a secondary table to make sure a match of some type does not exist.
*/
-- 4) Using Joins get all customer orders that have at least one item with a line total of more than $10,000.
-- Use the below 1 to Many tables
Select * From AdventureWorks2019.Sales.SalesOrderHeader Where SalesOrderID = 43683
Select * From AdventureWorks2019.Sales.SalesOrderDetail Where SalesOrderID = 43683

Select 
	SH.SalesOrderID,
	OrderDate,
	TotalDue,
	SD.SalesOrderDetailID,
	SD.LineTotal
From AdventureWorks2019.Sales.SalesOrderHeader SH
	Inner Join AdventureWorks2019.Sales.SalesOrderDetail SD
		On SH.SalesOrderID = SD.SalesOrderID
Where SD.LineTotal > 10000
Order By 1

-- Here Sales Order Lines are duplicated to show all LineTotals within that line having LineTotals > 10000, but we dont want any linew within an order to show up if there are none lines with LineTotal >10000. If there is atleast one order line  with LineTotal > 10000 Show the order details. If none dont show any of the order lines within that orderID.
-- In that case use EXISTS
-- EXISTS subquery doesn't actually return any data NO counts, sums or maxes.
-- Actually doesn't matter what you put in the select clause of the exist subquery as long as you put something.

-- 4) Using EXISTS to pick ONLY THE RECORDS WE NEED
Select
	A.SalesOrderID,
	A.OrderDate,
	A.TotalDue
From AdventureWorks2019.Sales.SalesOrderHeader A
Where EXISTS (		-- SubQuery Starts Here
	Select 
	1 -- DOES NOT MATTER WHAT YOU PUT HERE, AS EXISTS DOES NOT RETURN ANYTHING
	From AdventureWorks2019.Sales.SalesOrderDetail B
	Where B.LineTotal > 10000
	AND A.SalesOrderID = B.SalesOrderID
)
-- AND A.SalesOrderID = 43683 -- Records related to this SalesOrderID WILL appear as there are ATLEAST ONE line on this OrderID with LineTotal > 10000 
-- AND A.SalesOrderID = 43659 -- Records related to this SalesOrderID WILL NOT appear as there are no lines on this OrderID with LineTotal > 10000
Order By 1

-- 5) GET Opposite Order Not havin >10000. Use NOT EXISTS
-- Using Join this WILL NOT work as it shows all those lines with LineTotal <10000 and NOT the orders with atleast one line with LineTotal <10000
/*
Select 
	SH.SalesOrderID,
	OrderDate,
	TotalDue,
	SD.SalesOrderDetailID,
	SD.LineTotal
From AdventureWorks2019.Sales.SalesOrderHeader SH
	Inner Join AdventureWorks2019.Sales.SalesOrderDetail SD
		On SH.SalesOrderID = SD.SalesOrderID
Where SD.LineTotal < 10000
Order By 1
*/

Select
	A.SalesOrderID,
	A.OrderDate,
	A.TotalDue
From AdventureWorks2019.Sales.SalesOrderHeader A
Where NOT EXISTS (		-- SubQuery Starts Here
	Select 
	1 -- DOES NOT MATTER WHAT YOU PUT HERE, AS EXISTS DOES NOT RETURN ANYTHING
	From AdventureWorks2019.Sales.SalesOrderDetail B
	Where B.LineTotal > 10000
	AND A.SalesOrderID = B.SalesOrderID
)
-- AND A.SalesOrderID = 43683 -- Records related to this SalesOrderID WILL NOT appear as there are ATLEAST ONE line on this OrderID with LineTotal > 10000 
-- AND A.SalesOrderID = 43659 -- Records related to this SalesOrderID WILL appear as there are no lines on this OrderID with LineTotal > 10000
Order By 1

-- Exercises: EXISTS & NOT EXISTS SUB QUERIES
-- Exercise 1: at least one item in the order with an order quantity greater than 500
Select 
	A.PurchaseOrderID,
	A.OrderDate,
	A.SubTotal,
	A.TaxAmt
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A
Where EXISTS (
	Select 1
	From AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	Where B.OrderQty > 500
	And A.PurchaseOrderID = B.PurchaseOrderID
)
Order By 1

-- Exercise 2: Modify 1, with at least one item in the order with an order quantity greater than 500, AND a unit price greater than $50.00.
Select 
	A.*
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A
Where EXISTS (
	Select 1
	From AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	Where B.OrderQty > 500
	And B.UnitPrice > 50
	And A.PurchaseOrderID = B.PurchaseOrderID
)
Order By 1

-- Exercise 3: NONE of the items within the order have a rejected quantity greater than 0.
Select 
	A.*
From AdventureWorks2019.Purchasing.PurchaseOrderHeader A
Where NOT EXISTS (
	Select 1
	From AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	Where B.RejectedQty > 0
	And A.PurchaseOrderID = B.PurchaseOrderID
)
Order By 1

-- (IV) SUBQUERIES with 'FOR XML PATH' and 'STUFF'
-- Flattening Multiple rows into one sepearated by Commas

-- 6) Flatten LineTotals by SalesOrderID
/*
Select *
From AdventureWorks2019.Sales.SalesOrderDetail A
Where A.SalesOrderID = 43659 

-- Try with just FOR XML PATH
Select 
LineTotal
From AdventureWorks2019.Sales.SalesOrderDetail A
Where A.SalesOrderID = 43659
FOR XML PATH ('') 

-- Now remove <LineTotal> tags and replace with comma
Select 
',' + CAST(CAST(LineTotal AS MONEY) AS VARCHAR)
From AdventureWorks2019.Sales.SalesOrderDetail A
Where A.SalesOrderID = 43659
FOR XML PATH ('') 

-- Now use STUFF and sub query to remove the first comma
Select
STUFF(
		( -- Sub Query which is first argument of STUFF is the XML String
		Select 
		',' + CAST(CAST(LineTotal AS MONEY) AS VARCHAR)
		From AdventureWorks2019.Sales.SalesOrderDetail A
		Where A.SalesOrderID = 43659
		FOR XML PATH ('')
		),
		1,1,'') -- STUFF has 4 argument (string to stuff, position of string to truncate, length of string to truncate, '')

*/
-- Now plug this in as inner correlated sub query
Select				-- Outer query
	SalesOrderID,
	OrderDate,
	SubTotal,
	TaxAmt,
	Freight,
	TotalDue,
	STUFF(				-- Inner query
		( -- Sub Query which is first argument of STUFF is the XML String
		Select 
		',' + CAST(CAST(LineTotal AS MONEY) AS VARCHAR)
		From AdventureWorks2019.Sales.SalesOrderDetail B
		Where A.SalesOrderID = B.SalesOrderID
		FOR XML PATH ('')
		),
		1,1,'') LineTotals
From AdventureWorks2019.Sales.SalesOrderHeader A

-- Exercises: FOR XML PATH & STUFF SUB QUERIES
-- Exercise 1: A derived field called "Products", for each Subcategory, a semicolon-separated list of all products
Select
	A.Name SubcategoryName,
	STUFF(
		(
		Select
			';' + B.Name
		From AdventureWorks2019.Production.Product B
		Where A.ProductSubcategoryID = B.ProductSubcategoryID
		For XML PATH ('')
		),1,1,'' 
	) Products
From AdventureWorks2019.Production.ProductSubcategory A

-- Exercise 2: Modify the query such that only products with a ListPrice value greater than $50 are listed in the "Products" field.
Select
	A.Name SubcategoryName,
	STUFF(
		(
		Select
			';' + B.Name
		From AdventureWorks2019.Production.Product B
		Where A.ProductSubcategoryID = B.ProductSubcategoryID
			AND B.ListPrice > 50
		FOR XML PATH ('')
		),1,1,''
	) Products
From AdventureWorks2019.Production.ProductSubcategory A

-- (V) SUBQUERIES with PIVOT
-- Flattening Multiple rows into one sepearated by Commas

-- 7) Create a pivot Table for Product categories vs LineTotal using PIVOT 
-- You will need a subquery with product category & line total, and a PIVOT section that defines th aggregate of the LineTotal and points out the distinct items in the product category column.
-- Then select the list of distinct items defined in PIVOT from the sub query
Select 
	[Bikes], 
	[Clothing], 
	[Accessories], 
	[Components]
From
	( -- SubQuery Aliased as A
	Select
		D.Name ProductCategoryName,
		A.LineTotal
	From AdventureWorks2019.Sales.SalesOrderDetail A
		Inner Join AdventureWorks2019.Production.Product B
			On A.ProductID = B.ProductID
		Inner Join AdventureWorks2019.Production.ProductSubcategory C
			On B.ProductSubcategoryID = C.ProductSubcategoryID
		Inner Join AdventureWorks2019.Production.ProductCategory D
			On C.ProductCategoryID = D.ProductCategoryID
	) A
PIVOT (
SUM(LineTotal) 
FOR ProductCategoryName IN([Bikes], [Clothing], [Accessories], [Components])
) B

-- 8) Modify to show Linetotals oer category by OrderQty
Select * 
From
	(
	Select
		A.OrderQty [Order Quantity], -- Give an Alias thats business Friendly
		D.Name ProductCategoryName,
		A.LineTotal
	From AdventureWorks2019.Sales.SalesOrderDetail A
		Inner Join AdventureWorks2019.Production.Product B
			On A.ProductID = B.ProductID
		Inner Join AdventureWorks2019.Production.ProductSubcategory C
			On B.ProductSubcategoryID = C.ProductSubcategoryID
		Inner Join AdventureWorks2019.Production.ProductCategory D
			On C.ProductCategoryID = D.ProductCategoryID
	) A
PIVOT(
SUM(LineTotal)
FOR ProductCategoryName IN([Bikes], [Clothing], [Accessories], [Components])
) B
Order By [Order Quantity]

-- Exercises: PIVOT SUB QUERIES
-- Exercise 1: Using PIVOT, write a query against the HumanResources.Employee table summarizes the average amount of vacation time for Sales Representative, Buyer, and Janitor
Select *
From
	(
	Select 
		JobTitle,
		VacationHours
	From AdventureWorks2019.HumanResources.Employee
	) A
PIVOT
(
AVG(VacationHours)
FOR JobTitle IN ([Sales Representative], [Buyer], [Janitor])
) B

-- Exercise 2: Modify such that the results are broken out by Gender. Alias the Gender field as "Employee Gender" in your output.
Select *
From
	(
	Select 
		Gender [Employee Gender],
		JobTitle,
		VacationHours
	From AdventureWorks2019.HumanResources.Employee
	) A
PIVOT
(
AVG(VacationHours)
FOR JobTitle IN ([Sales Representative], [Buyer], [Janitor])
) B



