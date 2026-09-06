/*
=====================================================================
JALLOW MERIDIAN RETAIL GROUP
Enterprise ETL, Data Warehouse & Tableau Portfolio Project
Phase 1: Build Operational Source Systems
Target Platform: Microsoft SQL Server / SSMS
=====================================================================

BUSINESS SCENARIO
-----------------
You are the owner / lead analyst of Jallow Meridian Retail Group (JMRG),
a growing U.S. retailer specializing in consumer electronics, accessories,
audio products, wearables, and home-office technology.

Jallow Meridian Retail Group has acquired Crestline Electronics & Home,
a hypothetical regional retailer operating in the SAME industry.

The acquisition creates a realistic data-integration challenge:
- Jallow Meridian uses a modern transactional sales database.
- Crestline uses an older legacy sales system with different field names,
  formats, and data-quality standards.
- Jallow Meridian also maintains customer profile and loyalty data in a
  separate CRM database.

Management wants the two businesses integrated into a centralized
enterprise data warehouse so leadership can analyze consolidated sales,
customers, products, stores, profitability, and acquisition performance
in Tableau.

YOUR ROLE
---------
Act as the Business / Data Analyst responsible for:
1. Understanding the source systems.
2. Profiling and identifying data-quality problems.
3. Designing a SQL Server data warehouse.
4. Building the SSIS ETL pipeline.
5. Transforming and validating source data.
6. Integrating Jallow Meridian and Crestline data.
7. Performing reconciliation and data-quality checks.
8. Connecting the completed warehouse to Tableau.
9. Producing executive-level business insights and recommendations.

IMPORTANT
---------
This script creates ONLY the operational source systems.
It intentionally does NOT create the final data warehouse or ETL solution.
Those are part of the hands-on portfolio project.

SOURCE DATABASES CREATED
------------------------
1. JallowMeridianSalesDB
   Jallow Meridian's current transactional sales system.

2. CrestlineLegacySalesDB
   Crestline Electronics & Home's pre-acquisition legacy sales system.

3. JallowMeridianCRMDB
   Jallow Meridian's customer profile and loyalty-management system.

Both Jallow Meridian and Crestline operate in the consumer electronics,
accessories, wearables, audio, and home-office retail industry.
=====================================================================
*/

SET NOCOUNT ON;
GO

/* ============================================================
   1) JALLOW MERIDIAN RETAIL GROUP - CURRENT SALES DATABASE
   ============================================================ */
IF DB_ID('JallowMeridianSalesDB') IS NULL
    CREATE DATABASE JallowMeridianSalesDB;
GO

USE JallowMeridianSalesDB;
GO

IF OBJECT_ID('dbo.OrderDetails','U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Products','U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Stores','U') IS NOT NULL DROP TABLE dbo.Stores;
IF OBJECT_ID('dbo.Customers','U') IS NOT NULL DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers (
    CustomerID      INT            NOT NULL PRIMARY KEY,
    FirstName       VARCHAR(50)    NOT NULL,
    LastName        VARCHAR(50)    NOT NULL,
    Email           VARCHAR(120)   NULL,
    State           VARCHAR(30)    NULL,
    JoinDate        DATE           NOT NULL
);

CREATE TABLE dbo.Products (
    ProductID       INT            NOT NULL PRIMARY KEY,
    ProductName     VARCHAR(100)   NOT NULL,
    Category        VARCHAR(50)    NOT NULL,
    SubCategory     VARCHAR(50)    NOT NULL,
    UnitCost        DECIMAL(10,2)  NOT NULL,
    ListPrice       DECIMAL(10,2)  NOT NULL,
    IsActive        BIT            NOT NULL
);

CREATE TABLE dbo.Stores (
    StoreID         INT            NOT NULL PRIMARY KEY,
    StoreName       VARCHAR(100)   NOT NULL,
    City            VARCHAR(60)    NOT NULL,
    State           CHAR(2)        NOT NULL,
    Region          VARCHAR(20)    NOT NULL,
    OpenDate        DATE           NOT NULL
);

CREATE TABLE dbo.Orders (
    OrderID         INT            NOT NULL PRIMARY KEY,
    CustomerID      INT            NOT NULL,
    StoreID         INT            NOT NULL,
    OrderDate       DATE           NOT NULL,
    OrderStatus     VARCHAR(20)    NOT NULL,
    Channel         VARCHAR(20)    NOT NULL,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID),
    CONSTRAINT FK_Orders_Stores FOREIGN KEY (StoreID) REFERENCES dbo.Stores(StoreID)
);

CREATE TABLE dbo.OrderDetails (
    OrderDetailID   INT            NOT NULL PRIMARY KEY,
    OrderID         INT            NOT NULL,
    ProductID       INT            NOT NULL,
    Quantity        INT            NOT NULL,
    UnitPrice       DECIMAL(10,2)  NOT NULL,
    DiscountPct     DECIMAL(5,4)   NOT NULL,
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID)
);
GO

-- 12 stores
INSERT INTO dbo.Stores (StoreID, StoreName, City, State, Region, OpenDate)
VALUES
(1,'Jallow Meridian - Columbus','Columbus','OH','Midwest','2018-03-15'),
(2,'Jallow Meridian - Cleveland','Cleveland','OH','Midwest','2019-06-01'),
(3,'Jallow Meridian - Cincinnati','Cincinnati','OH','Midwest','2020-02-20'),
(4,'Jallow Meridian - Pittsburgh','Pittsburgh','PA','Northeast','2020-09-10'),
(5,'Jallow Meridian - Detroit','Detroit','MI','Midwest','2021-01-18'),
(6,'Jallow Meridian - Indianapolis','Indianapolis','IN','Midwest','2021-07-05'),
(7,'Jallow Meridian - Atlanta','Atlanta','GA','South','2022-03-12'),
(8,'Jallow Meridian - Charlotte','Charlotte','NC','South','2022-08-25'),
(9,'Jallow Meridian - Nashville','Nashville','TN','South','2023-01-10'),
(10,'Jallow Meridian - Dallas','Dallas','TX','South','2023-06-14'),
(11,'Jallow Meridian - Chicago','Chicago','IL','Midwest','2024-02-01'),
(12,'Jallow Meridian - Louisville','Louisville','KY','South','2024-09-09');
GO

-- 120 products
;WITH N AS (
    SELECT TOP (120) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Products (ProductID, ProductName, Category, SubCategory, UnitCost, ListPrice, IsActive)
SELECT
    n,
    CONCAT(
        CASE (n-1)%6
            WHEN 0 THEN 'Aurora'
            WHEN 1 THEN 'Summit'
            WHEN 2 THEN 'Metro'
            WHEN 3 THEN 'Vista'
            WHEN 4 THEN 'Pulse'
            ELSE 'Trail'
        END,
        ' ',
        CASE (n-1)%10
            WHEN 0 THEN 'Laptop'
            WHEN 1 THEN 'Monitor'
            WHEN 2 THEN 'Keyboard'
            WHEN 3 THEN 'Mouse'
            WHEN 4 THEN 'Headphones'
            WHEN 5 THEN 'Smartwatch'
            WHEN 6 THEN 'Backpack'
            WHEN 7 THEN 'Desk Lamp'
            WHEN 8 THEN 'Webcam'
            ELSE 'Speaker'
        END,
        ' ', FORMAT(n,'000')
    ),
    CASE (n-1)%5
        WHEN 0 THEN 'Computers'
        WHEN 1 THEN 'Accessories'
        WHEN 2 THEN 'Audio'
        WHEN 3 THEN 'Wearables'
        ELSE 'Home Office'
    END,
    CASE (n-1)%10
        WHEN 0 THEN 'Laptops'
        WHEN 1 THEN 'Monitors'
        WHEN 2 THEN 'Keyboards'
        WHEN 3 THEN 'Mice'
        WHEN 4 THEN 'Headphones'
        WHEN 5 THEN 'Smartwatches'
        WHEN 6 THEN 'Bags'
        WHEN 7 THEN 'Lighting'
        WHEN 8 THEN 'Webcams'
        ELSE 'Speakers'
    END,
    CAST(8 + ((n * 17) % 260) + ((n % 7) * 0.35) AS DECIMAL(10,2)),
    CAST((8 + ((n * 17) % 260) + ((n % 7) * 0.35)) * (1.35 + ((n % 5) * 0.08)) AS DECIMAL(10,2)),
    CASE WHEN n IN (13,47,88,119) THEN 0 ELSE 1 END
FROM N;
GO

-- 4,000 customers. A small number of records contain realistic imperfections.
;WITH N AS (
    SELECT TOP (4000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Customers (CustomerID, FirstName, LastName, Email, State, JoinDate)
SELECT
    n,
    CASE n%12
        WHEN 0 THEN 'James' WHEN 1 THEN 'Mary' WHEN 2 THEN 'John' WHEN 3 THEN 'Patricia'
        WHEN 4 THEN 'Robert' WHEN 5 THEN 'Jennifer' WHEN 6 THEN 'Michael' WHEN 7 THEN 'Linda'
        WHEN 8 THEN 'David' WHEN 9 THEN 'Elizabeth' WHEN 10 THEN 'Daniel' ELSE 'Sarah'
    END,
    CASE n%12
        WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams' WHEN 3 THEN 'Brown'
        WHEN 4 THEN 'Jones' WHEN 5 THEN 'Garcia' WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis'
        WHEN 8 THEN 'Wilson' WHEN 9 THEN 'Anderson' WHEN 10 THEN 'Thomas' ELSE 'Taylor'
    END,
    CASE WHEN n%97=0 THEN NULL
         WHEN n%89=0 THEN UPPER(CONCAT('customer',n,'@example.com'))
         ELSE CONCAT('customer',n,'@example.com') END,
    CASE n%12
        WHEN 0 THEN 'OH' WHEN 1 THEN 'Ohio' WHEN 2 THEN 'PA' WHEN 3 THEN 'MI'
        WHEN 4 THEN 'IN' WHEN 5 THEN 'GA' WHEN 6 THEN 'NC' WHEN 7 THEN 'TN'
        WHEN 8 THEN 'TX' WHEN 9 THEN 'IL' WHEN 10 THEN 'KY' ELSE 'ohio'
    END,
    DATEADD(DAY, -(n%2200), CAST('2026-06-30' AS DATE))
FROM N;
GO

-- 25,000 orders
;WITH N AS (
    SELECT TOP (25000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Orders (OrderID, CustomerID, StoreID, OrderDate, OrderStatus, Channel)
SELECT
    n,
    ((n * 37) % 4000) + 1,
    ((n * 7) % 12) + 1,
    DATEADD(DAY, -(n % 900), CAST('2026-06-30' AS DATE)),
    CASE WHEN n%41=0 THEN 'Cancelled'
         WHEN n%29=0 THEN 'Returned'
         ELSE 'Completed' END,
    CASE n%3 WHEN 0 THEN 'Online' WHEN 1 THEN 'Store' ELSE 'Mobile' END
FROM N;
GO

-- 60,000 order-detail rows
;WITH N AS (
    SELECT TOP (60000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice, DiscountPct)
SELECT
    n,
    ((n * 13) % 25000) + 1,
    ((n * 17) % 120) + 1,
    (n % 4) + 1,
    p.ListPrice,
    CAST(CASE n%10 WHEN 0 THEN 0.20 WHEN 1 THEN 0.10 WHEN 2 THEN 0.05 ELSE 0 END AS DECIMAL(5,4))
FROM N
JOIN dbo.Products p ON p.ProductID = ((n * 17) % 120) + 1;
GO

/* ============================================================
   2) CRESTLINE ELECTRONICS & HOME - ACQUIRED LEGACY SALES DATABASE
   ============================================================ */
IF DB_ID('CrestlineLegacySalesDB') IS NULL
    CREATE DATABASE CrestlineLegacySalesDB;
GO

USE CrestlineLegacySalesDB;
GO

IF OBJECT_ID('dbo.LegacyTransactions','U') IS NOT NULL DROP TABLE dbo.LegacyTransactions;
IF OBJECT_ID('dbo.LegacyCustomers','U') IS NOT NULL DROP TABLE dbo.LegacyCustomers;
GO

CREATE TABLE dbo.LegacyCustomers (
    cust_num        VARCHAR(12)    NOT NULL PRIMARY KEY,
    fname           VARCHAR(50)    NULL,
    lname           VARCHAR(50)    NULL,
    email_addr      VARCHAR(120)   NULL,
    state_code      VARCHAR(30)    NULL,
    signup_dt       VARCHAR(20)    NULL
);

CREATE TABLE dbo.LegacyTransactions (
    txn_id          INT            NOT NULL PRIMARY KEY,
    cust_num        VARCHAR(12)    NOT NULL,
    item_num        INT            NULL,
    qty             INT            NULL,
    price           VARCHAR(30)    NULL,
    txn_date        VARCHAR(20)    NULL,
    store_code      VARCHAR(10)    NULL,
    CONSTRAINT FK_LegacyTxn_Cust FOREIGN KEY (cust_num) REFERENCES dbo.LegacyCustomers(cust_num)
);
GO

-- 1,800 customers inherited from Crestline Electronics & Home.
-- Some Crestline emails overlap with existing Jallow Meridian customers,
-- creating a realistic post-acquisition deduplication / customer-identity challenge.
;WITH N AS (
    SELECT TOP (1800) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.LegacyCustomers (cust_num, fname, lname, email_addr, state_code, signup_dt)
SELECT
    CONCAT('LC-',FORMAT(n,'00000')),
    CASE n%10
        WHEN 0 THEN 'James' WHEN 1 THEN 'Mary' WHEN 2 THEN 'John' WHEN 3 THEN 'Patricia'
        WHEN 4 THEN 'Robert' WHEN 5 THEN 'Jennifer' WHEN 6 THEN 'Michael' WHEN 7 THEN 'Linda'
        WHEN 8 THEN 'David' ELSE 'Sarah'
    END,
    CASE n%10
        WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams' WHEN 3 THEN 'Brown'
        WHEN 4 THEN 'Jones' WHEN 5 THEN 'Garcia' WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis'
        WHEN 8 THEN 'Wilson' ELSE 'Taylor'
    END,
    CASE
        WHEN n%67=0 THEN NULL
        WHEN n<=500 THEN CONCAT('CUSTOMER', (2800+n), '@EXAMPLE.COM')
        ELSE CONCAT('legacy',n,'@oldmail.com')
    END,
    CASE n%12
        WHEN 0 THEN 'OH' WHEN 1 THEN 'Ohio' WHEN 2 THEN 'ohio' WHEN 3 THEN 'OHIO'
        WHEN 4 THEN 'Georgia' WHEN 5 THEN 'GA' WHEN 6 THEN 'Pennsylvania' WHEN 7 THEN 'PA'
        WHEN 8 THEN 'Michigan' WHEN 9 THEN 'MI' WHEN 10 THEN 'Texas' ELSE 'TX'
    END,
    CASE WHEN n%83=0 THEN 'not-a-date'
         ELSE CONVERT(VARCHAR(10),DATEADD(DAY,-(n%2500),CAST('2026-06-30' AS DATE)),101) END
FROM N;
GO

-- 18,000 pre-acquisition Crestline transactions with intentional data-quality issues.
;WITH N AS (
    SELECT TOP (18000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.LegacyTransactions (txn_id, cust_num, item_num, qty, price, txn_date, store_code)
SELECT
    500000 + n,
    CONCAT('LC-',FORMAT(((n*19)%1800)+1,'00000')),
    CASE WHEN n%211=0 THEN 9999 ELSE ((n*23)%120)+1 END,
    CASE WHEN n%173=0 THEN -1 WHEN n%149=0 THEN NULL ELSE (n%4)+1 END,
    CASE
        WHEN n%197=0 THEN 'FREE'
        WHEN n%181=0 THEN '-25.00'
        WHEN n%167=0 THEN NULL
        WHEN n%23=0 THEN CONCAT('$',CAST(CAST(10 + ((n*11)%280) AS DECIMAL(10,2)) AS VARCHAR(30)))
        ELSE CAST(CAST(10 + ((n*11)%280) + ((n%5)*0.25) AS DECIMAL(10,2)) AS VARCHAR(30))
    END,
    CASE
        WHEN n%191=0 THEN '13/45/2025'
        WHEN n%37=0 THEN CONVERT(VARCHAR(10),DATEADD(DAY,-(n%900),CAST('2026-06-30' AS DATE)),101)
        ELSE CONVERT(VARCHAR(10),DATEADD(DAY,-(n%900),CAST('2026-06-30' AS DATE)),23)
    END,
    CONCAT('S',FORMAT(((n*7)%12)+1,'00'))
FROM N;
GO

/* ============================================================
   3) JALLOW MERIDIAN RETAIL GROUP - CUSTOMER CRM DATABASE
   ============================================================ */
IF DB_ID('JallowMeridianCRMDB') IS NULL
    CREATE DATABASE JallowMeridianCRMDB;
GO

USE JallowMeridianCRMDB;
GO

IF OBJECT_ID('dbo.LoyaltyAccounts','U') IS NOT NULL DROP TABLE dbo.LoyaltyAccounts;
IF OBJECT_ID('dbo.CustomerProfile','U') IS NOT NULL DROP TABLE dbo.CustomerProfile;
GO

CREATE TABLE dbo.CustomerProfile (
    CustomerID       INT            NOT NULL PRIMARY KEY,
    Phone            VARCHAR(30)    NULL,
    CustomerSegment  VARCHAR(30)    NULL,
    DateOfBirth      DATE           NULL,
    LastUpdated      DATETIME2      NOT NULL
);

CREATE TABLE dbo.LoyaltyAccounts (
    LoyaltyID        INT            NOT NULL PRIMARY KEY,
    CustomerID       INT            NOT NULL,
    LoyaltyStatus    VARCHAR(20)    NULL,
    PointsBalance    INT            NULL,
    EnrollDate       DATE           NULL,
    CONSTRAINT FK_Loyalty_Profile FOREIGN KEY (CustomerID) REFERENCES dbo.CustomerProfile(CustomerID)
);
GO

-- Profiles exist for 3,700 of the 4,000 current customers.
;WITH N AS (
    SELECT TOP (3700) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.CustomerProfile (CustomerID, Phone, CustomerSegment, DateOfBirth, LastUpdated)
SELECT
    n,
    CASE
        WHEN n%101=0 THEN NULL
        WHEN n%9=0 THEN CONCAT('(',200+(n%700),') ',100+((n*3)%900),'-',FORMAT((n*17)%10000,'0000'))
        WHEN n%7=0 THEN CONCAT(200+(n%700),'.',100+((n*3)%900),'.',FORMAT((n*17)%10000,'0000'))
        ELSE CONCAT(200+(n%700),'-',100+((n*3)%900),'-',FORMAT((n*17)%10000,'0000'))
    END,
    CASE n%4 WHEN 0 THEN 'Consumer' WHEN 1 THEN 'Corporate' WHEN 2 THEN 'Small Business' ELSE 'Home Office' END,
    DATEADD(DAY,-(7000 + (n%15000)),CAST('2026-06-30' AS DATE)),
    DATEADD(MINUTE,-(n%200000),CAST('2026-06-30T12:00:00' AS DATETIME2))
FROM N;
GO

-- Not every CRM customer has a loyalty account.
;WITH N AS (
    SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.LoyaltyAccounts (LoyaltyID, CustomerID, LoyaltyStatus, PointsBalance, EnrollDate)
SELECT
    100000+n,
    n,
    CASE n%4 WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' WHEN 2 THEN 'Gold' ELSE 'Platinum' END,
    CASE WHEN n%113=0 THEN NULL ELSE (n*31)%15000 END,
    DATEADD(DAY,-(n%1800),CAST('2026-06-30' AS DATE))
FROM N;
GO

/* ============================================================
   QUICK INSTALLATION CHECKS
   These are only setup checks, not the ETL solution.
   ============================================================ */
SELECT 'JallowMeridianSalesDB.Customers' AS SourceTable, COUNT(*) AS TotalRows FROM JallowMeridianSalesDB.dbo.Customers
UNION ALL
SELECT 'JallowMeridianSalesDB.Products', COUNT(*) FROM JallowMeridianSalesDB.dbo.Products
UNION ALL
SELECT 'JallowMeridianSalesDB.Stores', COUNT(*) FROM JallowMeridianSalesDB.dbo.Stores
UNION ALL
SELECT 'JallowMeridianSalesDB.Orders', COUNT(*) FROM JallowMeridianSalesDB.dbo.Orders
UNION ALL
SELECT 'JallowMeridianSalesDB.OrderDetails', COUNT(*) FROM JallowMeridianSalesDB.dbo.OrderDetails
UNION ALL
SELECT 'CrestlineLegacySalesDB.LegacyCustomers', COUNT(*) FROM CrestlineLegacySalesDB.dbo.LegacyCustomers
UNION ALL
SELECT 'CrestlineLegacySalesDB.LegacyTransactions', COUNT(*) FROM CrestlineLegacySalesDB.dbo.LegacyTransactions
UNION ALL
SELECT 'JallowMeridianCRMDB.CustomerProfile', COUNT(*) FROM JallowMeridianCRMDB.dbo.CustomerProfile
UNION ALL
SELECT 'JallowMeridianCRMDB.LoyaltyAccounts', COUNT(*) FROM JallowMeridianCRMDB.dbo.LoyaltyAccounts;
GO

PRINT 'Jallow Meridian Retail Group source systems created successfully. Next step: profile Jallow Meridian and Crestline data before designing the enterprise data warehouse.';
GO
