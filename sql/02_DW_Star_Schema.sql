
/*
=====================================================================
JALLOW MERIDIAN RETAIL GROUP
Enterprise Data Warehouse – Star Schema Setup
Portfolio Project: SQL Server + SSIS + Tableau
=====================================================================

PURPOSE
-------
This script creates the analytical data warehouse that will receive
cleaned and integrated data from:

1. JallowMeridianSalesDB
2. JallowMeridianCRMDB
3. CrestlineLegacySalesDB

WAREHOUSE DESIGN
----------------
Dimensions:
- DimCustomer
- DimProduct
- DimStore
- DimDate

Fact:
- FactSales

Data Quality / Audit:
- ETLRejectedRecords

FACT TABLE GRAIN
----------------
One row in FactSales represents one sold product line:
- one Jallow Meridian OrderDetails record, OR
- one Crestline LegacyTransactions record.

IMPORTANT
---------
This script creates the warehouse structure only.
It does NOT load source data into the warehouse.
The loading and transformation logic will be handled in later ETL steps.
=====================================================================
*/

SET NOCOUNT ON;
GO

IF DB_ID('JallowMeridianDW') IS NULL
BEGIN
    CREATE DATABASE JallowMeridianDW;
END;
GO

USE JallowMeridianDW;
GO

IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.ETLRejectedRecords', 'U') IS NOT NULL DROP TABLE dbo.ETLRejectedRecords;
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimStore', 'U') IS NOT NULL DROP TABLE dbo.DimStore;
IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimCustomer', 'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
GO

CREATE TABLE dbo.DimCustomer
(
    CustomerKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCustomer PRIMARY KEY,
    SourceSystem VARCHAR(30) NOT NULL,
    SourceCustomerID VARCHAR(20) NOT NULL,
    FirstName VARCHAR(50) NULL,
    LastName VARCHAR(50) NULL,
    Email VARCHAR(120) NULL,
    State CHAR(2) NULL,
    JoinDate DATE NULL,
    Phone VARCHAR(30) NULL,
    CustomerSegment VARCHAR(30) NULL,
    LoyaltyStatus VARCHAR(20) NULL,
    PointsBalance INT NULL,
    PotentialCrossSystemMatch BIT NOT NULL
        CONSTRAINT DF_DimCustomer_PotentialMatch DEFAULT (0),
    LoadDate DATETIME2 NOT NULL
        CONSTRAINT DF_DimCustomer_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_DimCustomer_Source UNIQUE (SourceSystem, SourceCustomerID)
);
GO

CREATE TABLE dbo.DimProduct
(
    ProductKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimProduct PRIMARY KEY,
    SourceSystem VARCHAR(30) NOT NULL,
    SourceProductID VARCHAR(20) NOT NULL,
    ProductName VARCHAR(100) NULL,
    Category VARCHAR(50) NULL,
    SubCategory VARCHAR(50) NULL,
    UnitCost DECIMAL(10,2) NULL,
    ListPrice DECIMAL(10,2) NULL,
    IsActive BIT NULL,
    LoadDate DATETIME2 NOT NULL
        CONSTRAINT DF_DimProduct_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_DimProduct_Source UNIQUE (SourceSystem, SourceProductID)
);
GO

CREATE TABLE dbo.DimStore
(
    StoreKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimStore PRIMARY KEY,
    SourceSystem VARCHAR(30) NOT NULL,
    SourceStoreID VARCHAR(20) NOT NULL,
    StoreName VARCHAR(100) NULL,
    City VARCHAR(60) NULL,
    State CHAR(2) NULL,
    Region VARCHAR(20) NULL,
    OpenDate DATE NULL,
    LoadDate DATETIME2 NOT NULL
        CONSTRAINT DF_DimStore_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_DimStore_Source UNIQUE (SourceSystem, SourceStoreID)
);
GO

CREATE TABLE dbo.DimDate
(
    DateKey INT NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,
    FullDate DATE NULL,
    CalendarYear SMALLINT NULL,
    CalendarQuarter TINYINT NULL,
    MonthNumber TINYINT NULL,
    MonthName VARCHAR(12) NULL,
    YearMonth CHAR(7) NULL,
    DayOfMonth TINYINT NULL,
    DayName VARCHAR(12) NULL,
    IsWeekend BIT NULL
);
GO

CREATE TABLE dbo.FactSales
(
    SalesKey BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactSales PRIMARY KEY,
    SourceSystem VARCHAR(30) NOT NULL,
    SourceTransactionID VARCHAR(30) NOT NULL,
    SourceLineID VARCHAR(30) NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    DateKey INT NOT NULL,
    OrderStatus VARCHAR(20) NULL,
    SalesChannel VARCHAR(20) NULL,
    Quantity INT NULL,
    UnitPrice DECIMAL(12,2) NULL,
    DiscountPct DECIMAL(7,4) NULL,
    DiscountAmount DECIMAL(14,2) NULL,
    SalesAmount DECIMAL(14,2) NULL,
    CostAmount DECIMAL(14,2) NULL,
    ProfitAmount DECIMAL(14,2) NULL,
    LoadDate DATETIME2 NOT NULL
        CONSTRAINT DF_FactSales_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_FactSales_Customer FOREIGN KEY (CustomerKey)
        REFERENCES dbo.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_Product FOREIGN KEY (ProductKey)
        REFERENCES dbo.DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_Store FOREIGN KEY (StoreKey)
        REFERENCES dbo.DimStore(StoreKey),
    CONSTRAINT FK_FactSales_Date FOREIGN KEY (DateKey)
        REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT UQ_FactSales_SourceLine UNIQUE (SourceSystem, SourceLineID)
);
GO

CREATE TABLE dbo.ETLRejectedRecords
(
    RejectID BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_ETLRejectedRecords PRIMARY KEY,
    SourceSystem VARCHAR(30) NOT NULL,
    SourceTable VARCHAR(60) NOT NULL,
    SourceRecordID VARCHAR(50) NULL,
    RejectReason VARCHAR(250) NOT NULL,
    RejectColumn VARCHAR(60) NULL,
    RejectValue VARCHAR(250) NULL,
    RejectedAt DATETIME2 NOT NULL
        CONSTRAINT DF_ETLRejectedRecords_RejectedAt DEFAULT (SYSDATETIME())
);
GO

SET IDENTITY_INSERT dbo.DimCustomer ON;
INSERT INTO dbo.DimCustomer
(
    CustomerKey, SourceSystem, SourceCustomerID,
    FirstName, LastName, Email, State, JoinDate,
    Phone, CustomerSegment, LoyaltyStatus, PointsBalance,
    PotentialCrossSystemMatch
)
VALUES
(
    0, 'Unknown', 'UNKNOWN',
    'Unknown', 'Unknown', NULL, NULL, NULL,
    NULL, 'Unknown', 'Unknown', NULL, 0
);
SET IDENTITY_INSERT dbo.DimCustomer OFF;
GO

SET IDENTITY_INSERT dbo.DimProduct ON;
INSERT INTO dbo.DimProduct
(
    ProductKey, SourceSystem, SourceProductID,
    ProductName, Category, SubCategory,
    UnitCost, ListPrice, IsActive
)
VALUES
(
    0, 'Unknown', 'UNKNOWN',
    'Unknown Product', 'Unknown', 'Unknown',
    NULL, NULL, NULL
);
SET IDENTITY_INSERT dbo.DimProduct OFF;
GO

SET IDENTITY_INSERT dbo.DimStore ON;
INSERT INTO dbo.DimStore
(
    StoreKey, SourceSystem, SourceStoreID,
    StoreName, City, State, Region, OpenDate
)
VALUES
(
    0, 'Unknown', 'UNKNOWN',
    'Unknown Store', NULL, NULL, 'Unknown', NULL
);
SET IDENTITY_INSERT dbo.DimStore OFF;
GO

INSERT INTO dbo.DimDate
(
    DateKey, FullDate, CalendarYear, CalendarQuarter,
    MonthNumber, MonthName, YearMonth,
    DayOfMonth, DayName, IsWeekend
)
VALUES
(
    0, NULL, NULL, NULL,
    NULL, 'Unknown', NULL,
    NULL, NULL, NULL
);
GO

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate   DATE = '2026-12-31';

;WITH DateSeries AS
(
    SELECT @StartDate AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < @EndDate
)
INSERT INTO dbo.DimDate
(
    DateKey, FullDate, CalendarYear, CalendarQuarter,
    MonthNumber, MonthName, YearMonth,
    DayOfMonth, DayName, IsWeekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),
    FullDate,
    YEAR(FullDate),
    DATEPART(QUARTER, FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    CONVERT(CHAR(7), FullDate, 126),
    DAY(FullDate),
    DATENAME(WEEKDAY, FullDate),
    CASE
        WHEN DATENAME(WEEKDAY, FullDate) IN ('Saturday', 'Sunday') THEN 1
        ELSE 0
    END
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

CREATE INDEX IX_DimCustomer_Email ON dbo.DimCustomer (Email);
CREATE INDEX IX_FactSales_CustomerKey ON dbo.FactSales (CustomerKey);
CREATE INDEX IX_FactSales_ProductKey ON dbo.FactSales (ProductKey);
CREATE INDEX IX_FactSales_StoreKey ON dbo.FactSales (StoreKey);
CREATE INDEX IX_FactSales_DateKey ON dbo.FactSales (DateKey);
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

SELECT COUNT(*) AS DateDimensionRows
FROM dbo.DimDate;
GO

SELECT CustomerKey, SourceSystem, SourceCustomerID, FirstName, LastName
FROM dbo.DimCustomer
WHERE CustomerKey = 0;
GO

SELECT ProductKey, SourceSystem, SourceProductID, ProductName
FROM dbo.DimProduct
WHERE ProductKey = 0;
GO

SELECT StoreKey, SourceSystem, SourceStoreID, StoreName
FROM dbo.DimStore
WHERE StoreKey = 0;
GO

PRINT 'JallowMeridianDW star schema created successfully.';
PRINT 'Next step: build SQL transformation views for Jallow Meridian and Crestline source data.';
GO
