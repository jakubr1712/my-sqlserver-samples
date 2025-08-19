--1
DECLARE @ProductsTemp TABLE (
	ProductID INT,
   CategoryID INT,
   ProductName NVARCHAR(50),
   CategoryName NVARCHAR(50)
)
INSERT INTO @ProductsTemp (ProductID, CategoryID, ProductName, CategoryName)
SELECT ProductID, C.CategoryID, ProductName, CategoryName FROM Products P 
JOIN Categories C ON C.CategoryID=P.CategoryID WHERE C.CategoryName='Beverages';

SELECT * FROM @ProductsTemp
--2
DECLARE @OrdersVinetTemp TABLE (
   OrderID INT,
   CustomerID NCHAR(5),
   EmployeeID INT,
   OrderDate DATETIME,
   RequiredDate DATETIME,
   ShippedDate DATETIME,
   ShipVia INT,
   Freight MONEY,
   ShipName NVARCHAR(40),
   ShipAddress NVARCHAR(60),
   ShipCity NVARCHAR(15),
   ShipRegion NVARCHAR(15),
   ShipPostalCode NVARCHAR(10),
   ShipCountry NVARCHAR(15)
)

INSERT INTO @OrdersVinetTemp (
   OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate,
   ShipVia, Freight, ShipName, ShipAddress, ShipCity, ShipRegion,
   ShipPostalCode, ShipCountry
)
SELECT 
   OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate,
   ShipVia, Freight, ShipName, ShipAddress, ShipCity, ShipRegion,
   ShipPostalCode, ShipCountry
FROM Orders
WHERE CustomerID = 'VINET'
SELECT * FROM @OrdersVinetTemp
--3
DECLARE @ManagersTemp TABLE (
	FirstName NVARCHAR(30),
	LastName NVARCHAR(30)
)
INSERT INTO @ManagersTemp
SELECT DISTINCT FirstName, LastName FROM Employees WHERE EmployeeID IN (
   SELECT DISTINCT ReportsTo
   FROM Employees
   WHERE ReportsTo IS NOT NULL)
SELECT * FROM @ManagersTemp
--4
CREATE TABLE #Over30Temp (
	ProductID INT,
   ProductName NVARCHAR(40),
   UnitPrice MONEY	
)
INSERT INTO #Over30Temp (ProductID, ProductName, UnitPrice)
SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE UnitPrice > 30
SELECT * FROM #Over30Temp
DROP TABLE #Over30Temp
--5
CREATE TABLE #Orders1997 (
   OrderID INT,
   CustomerID NCHAR(5),
   EmployeeID INT,
   OrderDate DATETIME,
   RequiredDate DATETIME,
   ShippedDate DATETIME
)

INSERT INTO #Orders1997 (OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate)
SELECT OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate
FROM Orders
WHERE YEAR(OrderDate) = 1997

SELECT * FROM #Orders1997
--6
CREATE TABLE ##FrenchClients (
	ContactName NVARCHAR(50),
	ContactTitle NVARCHAR(50),
	City NVARCHAR(50)
)
INSERT INTO ##FrenchClients (ContactName, ContactTitle, City)
SELECT ContactName, ContactTitle, City FROM Customers WHERE Country = 'France'

SELECT * FROM ##FrenchClients
DROP TABLE ##FrenchClients
---------------------------------------Kursory
--1
DECLARE @OrderID INT
DECLARE @OrderDate DATETIME

DECLARE zamowienia_cursor CURSOR FOR
SELECT OrderID, OrderDate
FROM Orders
WHERE CustomerID = 'ALFKI'

OPEN zamowienia_cursor

FETCH NEXT FROM zamowienia_cursor INTO @OrderID, @OrderDate

WHILE @@FETCH_STATUS = 0
BEGIN
   PRINT 'Zam�wienie nr: ' + CAST(@OrderID AS NVARCHAR(10)) + 
         ', data: ' + CONVERT(NVARCHAR(20), @OrderDate, 120)

   FETCH NEXT FROM zamowienia_cursor INTO @OrderID, @OrderDate
END

CLOSE zamowienia_cursor
DEALLOCATE zamowienia_cursor
2
CREATE TABLE EmployeeData (
   EmployeeID INT PRIMARY KEY,
   FirstName NVARCHAR(30),
   LastName NVARCHAR(30),
   Title NVARCHAR(50),
   Address NVARCHAR(60),
   City NVARCHAR(30),
   LastModified DATETIME
)
GO
CREATE OR ALTER PROCEDURE UpsertEmployeeData
   @EmployeeID INT,
   @FirstName NVARCHAR(30),
   @LastName NVARCHAR(30),
   @Title NVARCHAR(50),
   @Address NVARCHAR(60),
   @City NVARCHAR(30)
AS
BEGIN
   IF EXISTS (SELECT 1 FROM EmployeeData WHERE EmployeeID = @EmployeeID)
   BEGIN
       UPDATE EmployeeData
       SET FirstName = @FirstName,
           LastName = @LastName,
           Title = @Title,
           Address = @Address,
           City = @City,
           LastModified = GETDATE()
       WHERE EmployeeID = @EmployeeID
   END
   ELSE
   BEGIN
       INSERT INTO EmployeeData (EmployeeID, FirstName, LastName, Title, Address, City, LastModified)
       VALUES (@EmployeeID, @FirstName, @LastName, @Title, @Address, @City, GETDATE())
   END
END
GO
DECLARE 
   @ID INT,
   @FirstName NVARCHAR(30),
   @LastName NVARCHAR(30),
   @Title NVARCHAR(50),
   @Address NVARCHAR(60),
   @City NVARCHAR(30),
   @Country NVARCHAR(30)

DECLARE emp_cursor CURSOR FOR
SELECT EmployeeID, FirstName, LastName, Title, Address, City, Country
FROM Employees

OPEN emp_cursor

FETCH NEXT FROM emp_cursor INTO @ID, @FirstName, @LastName, @Title, @Address, @City, @Country

WHILE @@FETCH_STATUS = 0
BEGIN
   IF @Country = 'USA'
       SET @Title = 'unknown'

   EXEC UpsertEmployeeData @ID, @FirstName, @LastName, @Title, @Address, @City

   FETCH NEXT FROM emp_cursor INTO @ID, @FirstName, @LastName, @Title, @Address, @City, @Country
END

CLOSE emp_cursor
DEALLOCATE emp_cursor
SELECT * FROM EmployeeData