WITH CustomerRevenue AS (
  SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalOrderValue
   FROM Customers c
   JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY c.CustomerID, c.CompanyName)
  SELECT CustomerID, CompanyName, TotalOrderValue,
    RANK() OVER (ORDER BY TotalOrderValue DESC) AS CustomerRank
     FROM CustomerRevenue;

    GO

 WITH RankedProducts AS (
  SELECT ProductName, CategoryID, UnitPrice,
    DENSE_RANK() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) as PriceRank
     FROM Products)
      SELECT ProductName, CategoryID, UnitPrice
  FROM RankedProducts
 WHERE PriceRank = 2;

   GO

 WITH EmployeeSales AS (
  SELECT e.EmployeeID, (e.FirstName + ' ' + e.LastName) AS EmployeeName, 
     SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
     FROM Employees e
   JOIN Orders o ON e.EmployeeID = o.EmployeeID
   JOIN [Order Details] od ON o.OrderID = od.OrderID
   GROUP BY e.EmployeeID, e.FirstName, e.LastName)
  SELECT EmployeeID, EmployeeName, TotalSales,
     SUM(TotalSales) OVER (ORDER BY TotalSales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
  FROM EmployeeSales;

   GO

  WITH EmployeeAvgOrder AS (
   SELECT e.EmployeeID, (e.FirstName + ' ' + e.LastName) AS EmployeeName,
     AVG(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS AvgOrderVal
   FROM Employees e
    JOIN Orders o ON e.EmployeeID = o.EmployeeID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
   GROUP BY e.EmployeeID, e.FirstName, e.LastName)
  SELECT EmployeeID, EmployeeName, AvgOrderVal
 FROM EmployeeAvgOrder
   WHERE AvgOrderVal > (SELECT AVG(UnitPrice * Quantity * (1 - Discount)) FROM [Order Details]);

  GO

  WITH YearlyEmployeeOrders AS (
   SELECT YEAR(o.OrderDate) AS OrderYear, e.EmployeeID, (e.FirstName + ' ' + e.LastName) AS EmployeeName,
     COUNT(o.OrderID) AS OrderCount,
     ROW_NUMBER() OVER (PARTITION BY YEAR(o.OrderDate) ORDER BY COUNT(o.OrderID) DESC) as RN
   FROM Employees e
   JOIN Orders o ON e.EmployeeID = o.EmployeeID
   GROUP BY YEAR(o.OrderDate), e.EmployeeID, e.FirstName, e.LastName)
    
 SELECT OrderYear, EmployeeID, EmployeeName, OrderCount
   FROM YearlyEmployeeOrders
 WHERE RN = 1;

  GO

  WITH RankedExpensiveProducts AS (
   SELECT p.ProductName, c.CategoryName, p.UnitPrice,
     ROW_NUMBER() OVER (PARTITION BY p.CategoryID ORDER BY p.UnitPrice DESC) as RN
    FROM Products p
   JOIN Categories c ON p.CategoryID = c.CategoryID)
  SELECT CategoryName, ProductName, UnitPrice
   FROM RankedExpensiveProducts
  WHERE RN <= 3;

  GO

  WITH ProductSalesByCategory AS (
    SELECT c.CategoryName, p.ProductName,
      SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
    FROM Categories c
     JOIN Products p ON c.CategoryID = p.CategoryID
     JOIN [Order Details] od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryName, p.ProductName)
  SELECT CategoryName, ProductName, TotalSales,
   DENSE_RANK() OVER (PARTITION BY CategoryName ORDER BY TotalSales DESC) AS SalesRank
  FROM ProductSalesByCategory;

  GO

  WITH OrderValues AS (
    SELECT o.EmployeeID, o.OrderID, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderTotal,
      ROW_NUMBER() OVER (PARTITION BY o.EmployeeID ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC) AS RN
    FROM Orders o
     JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY o.EmployeeID, o.OrderID)
  SELECT EmployeeID, OrderID, OrderTotal
   FROM OrderValues
  WHERE RN = 1;

  GO

 WITH CategorySales AS (
  SELECT c.CategoryName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS CatSales
   FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN [Order Details] od ON p.ProductID = od.ProductID
   GROUP BY c.CategoryName)
SELECT CategoryName, CatSales,
   (CatSales * 100.0 / (SELECT SUM(UnitPrice * Quantity * (1 - Discount)) FROM [Order Details])) AS SalesPercentage
FROM CategorySales;

 GO

 WITH CustomerTotal AS (
  SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotVal
   FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
   GROUP BY c.CustomerID, c.CompanyName)
SELECT CustomerID, CompanyName, TotVal
 FROM CustomerTotal
WHERE TotVal > (SELECT AVG(TotVal) FROM CustomerTotal);

 GO

SELECT ProductID, ProductName
  FROM Products
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM [Order Details]);

 GO

 SELECT e.EmployeeID, (e.FirstName + ' ' + e.LastName) AS EmployeeName,
   YEAR(o.OrderDate) AS SalesYear,
   SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalYearlySales
 FROM Employees e
  JOIN Orders o ON e.EmployeeID = o.EmployeeID
  JOIN [Order Details] od ON o.OrderID = od.OrderID
 GROUP BY e.EmployeeID, e.FirstName, e.LastName, YEAR(o.OrderDate)
 ORDER BY EmployeeID, SalesYear;