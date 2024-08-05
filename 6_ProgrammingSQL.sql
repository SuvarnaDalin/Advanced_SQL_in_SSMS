-------------- Topics Covered --------------
/*
	(I) Variables
	(II) User Defined Functions
*/

-- To push past traditional SQL querying and introduce some programming techniques more commonly associated with programming languages like Python and JavaScript.


-- (I) Variables
-- A named placeholder for a value or set of values. 
-- Main advantages of variables:
--		Only have to define them once, we can reuse them as many times as we want
--		
-- Cantains variable declaration, Data Type, Setting a avalue
-- Variable declaration starts with @. Setting value is done by SET
-- IMPORTANT: To run a Select statement on a variable the declaration statement has to be run along with the Select

-- 1) Define a variable

---------------------------- RUN From Here -->
DECLARE @Myvar INT

SET @Myvar = 11

Select @Myvar
---------------------------- To Here <--

-- 2) Define variable using an alternative condensed syntax that declares and sets the variable value on a single line.
---------------------------- RUN From Here -->
DECLARE @Myvar1 INT = 11

Select @Myvar1
---------------------------- To Here <--


-- 3) Use variable concept to get all from Product table where ListPrice >= 1000

DECLARE @MinPrice MONEY 
SET @MinPrice = 1000
Select *
From AdventureWorks2019.Production.Product
Where ListPrice >= @MinPrice				-- Now to change multiple occurances of this variable value, just have to change at the declaration statement


-- 4) Rdefine embedded sub query in below base query using variables
------------------------ Base Query ---------------
-- Embedded sub query: (Select AVG(ListPrice) From AdventureWorks2019.Production.Product)
Select
	ProductID,
	Name,
	StandardCost,
	ListPrice,
	(Select AVG(ListPrice) From AdventureWorks2019.Production.Product) AvgListPrice,
	ListPrice - (Select AVG(ListPrice) From AdventureWorks2019.Production.Product) AvgListPriceDiff
From AdventureWorks2019.Production.Product
Where ListPrice > (Select AVG(ListPrice) From AdventureWorks2019.Production.Product)
Order By ListPrice ASC;
------------------------------------------------------
----- DRY ----- DONT REPEAT YOURSELF
------------------------------------------------------

-- WORKAROUND
DECLARE @AvgPrice MONEY
SET @AvgPrice = (Select AVG(ListPrice) From AdventureWorks2019.Production.Product )

Select
	ProductID,
	Name,
	StandardCost,
	ListPrice,
	@AvgPrice AvgListPrice,
	(ListPrice - @AvgPrice) AvgListPriceDiff
From AdventureWorks2019.Production.Product
Where ListPrice > @AvgPrice
Order By ListPrice ASC;

-- 5) Define the Previous Month variable to uncomlicate the below Code
---------------------------------
SELECT DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(CAST(GETDATE() AS DATE)), MONTH(CAST(GETDATE() AS DATE)), 1))
---------------------------------

DECLARE @Today DATE
SET @Today = CAST(GETDATE() AS DATE)

DECLARE @BOM DATE	-- Beginning of Month
SET @BOM = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)

DECLARE @PrevBOM DATE
SET @PrevBOM = DATEADD(MONTH, -1, @BOM)

DECLARE @PrevEOM DATE	-- End of Month
SET @PrevEOM = DATEADD(DAY, -1, @BOM)

Select *
From AdventureWorks2019.dbo.Calendar
Where DateValue BETWEEN @PrevBOM AND @PrevEOM


-- EXERCISES: Variables
-- Exercise 1: Refactor the provided code in Base Query to utilize variables instead of embedded scalar subqueries.

----------------------------------------------- Base Query -------------------------------------------------------
SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
	  ,PercentOfMaxVacationHours = (VacationHours * 1.0) / (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)

FROM AdventureWorks2019.HumanResources.Employee

WHERE (VacationHours * 1.0) / (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) >= 0.8
------------------------------------------------------------------------------------------------------------------

-- Solution:
DECLARE @MaxVacationHrs FLOAT
SET @MaxVacationHrs = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)

SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = @MaxVacationHrs
	  ,PercentOfMaxVacationHours = VacationHours / @MaxVacationHrs

FROM AdventureWorks2019.HumanResources.Employee

WHERE VacationHours / @MaxVacationHrs >= 0.8


-- Exercise 2: A company pays once per month, on the 15th. Set up variables defining the beginning and end of the previous pay period in this scenario.
-- Select the variables to ensure they are working properly.

DECLARE @Today DATE = CAST(GETDATE() AS DATE)

DECLARE @Current14 DATE = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),14)


DECLARE @PayPeriodEnd DATE = 
	CASE
		WHEN DAY(@Today) < 15 THEN DATEADD(MONTH,-1,@Current14)
		ELSE @Current14
	END

DECLARE @PayPeriodStart DATE = DATEADD(DAY,1,DATEADD(MONTH,-1,@PayPeriodEnd))


SELECT @PayPeriodStart
SELECT @PayPeriodEnd


-- (II) User Defined Functions
-- Define new fundtions which may not already be there in SQL language
-- Naming convention start with ufn - user defined function
-- After 'Returns' statement follow the syntax as a template
-- User Defined Funtions live inside 'Programmability'--> 'Functions' in Object Explorer

-- 6) Define a function that returns todays date
USE AdventureWorks2019
GO
CREATE FUNCTION dbo.ufnCurrentDate()
RETURNS DATE
AS
BEGIN
	RETURN CAST(GETDATE() AS DATE)
END

-- 7) Use the new function created
Select 
	SalesOrderID,
	OrderDate,
	DueDate,
	ShipDate,
	dbo.ufnCurrentDate() [Today]
From AdventureWorks2019.Sales.SalesOrderHeader A
Where YEAR(A.OrderDate) = 2011


-- 8) Create a function to return ElapsedBusinessDays shown in the below query
Select
	SalesOrderID,
	OrderDate,
	DueDate,
	ShipDate,
	ElapsedBusinessDays = (
	Select COUNT(*)
	From AdventureWorks2019.dbo.Calendar B
	Where B.DateValue between A.OrderDate AND A.SHipDate
		AND B.WeekendFlag = 0
		AND B.HolidayFlag = 0
	)-1
From AdventureWorks2019.Sales.SalesOrderHeader A
Where YEAR(A.OrderDate) = 2011

--------------- FUNCTION -----------------
USE AdventureWorks2019
GO
CREATE FUNCTION dbo.ufnElapsedBusinessdays(@StartDate DATE, @EndDate DATE)
RETURNS INT
AS
BEGIN
RETURN
(
	Select COUNT(*)
	From AdventureWorks2019.dbo.Calendar
	Where DateValue between @StartDate AND @EndDate
		AND WeekendFlag = 0
		AND HolidayFlag = 0
) -1
END

-- 9) Use the new function in the above query
Select
	SalesOrderID,
	OrderDate,
	DueDate,
	ShipDate,
	dbo.ufnElapsedBusinessdays(OrderDate, ShipDate) ElapsedBusinessDays
From AdventureWorks2019.Sales.SalesOrderHeader
Where YEAR(OrderDate) = 2011
