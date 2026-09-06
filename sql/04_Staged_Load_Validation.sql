/*
===============================================================================
JALLOW MERIDIAN RETAIL GROUP
CORRECTED DATA WAREHOUSE LOAD + VALIDATION SCRIPT
Portfolio Project: SQL Server + SSIS + Tableau
===============================================================================

PURPOSE
-------
This is the corrected, staged warehouse-loading script.

IMPORTANT
---------
Run the sections IN ORDER.

Do not move to the next section until the validation result from the current
section matches the expected result shown in the comments.

This staged approach is intentional:
- It makes troubleshooting easier.
- It prevents one later failure from rolling back everything loaded earlier.
- It mirrors a practical ETL validation workflow.

PREREQUISITES
-------------
Before running this script, these must already exist and work:

Database:
    JallowMeridianDW

Warehouse tables:
    dbo.DimCustomer
    dbo.DimProduct
    dbo.DimStore
    dbo.DimDate
    dbo.FactSales
    dbo.ETLRejectedRecords

Transformation views:
    dbo.vw_ETL_DimCustomer_Source
    dbo.vw_ETL_DimProduct_Source
    dbo.vw_ETL_DimStore_Source
    dbo.vw_ETL_JallowMeridian_FactSales_Source
    dbo.vw_ETL_Crestline_FactSales_Profile
    dbo.vw_ETL_Crestline_FactSales_Valid
    dbo.vw_ETL_Crestline_FactSales_Rejected

EXPECTED FINAL RESULTS
----------------------
DimCustomer             5,801
DimProduct                121
DimStore                   25
DimDate                 2,558
ETLRejectedRecords        700
FactSales              77,300

FactSales by SourceSystem:
    JallowMeridian      60,000
    Crestline           17,300

Unknown dimension-key usage:
    CustomerKey = 0          0 rows
    ProductKey  = 0          0 rows
    StoreKey    = 0          0 rows
    DateKey     = 0          0 rows
===============================================================================
*/


/*=============================================================================
STEP 0 — RUN FIRST
VERIFY THE TRANSFORMATION VIEWS BEFORE LOADING ANYTHING
=============================================================================*/

USE JallowMeridianDW;
GO

SELECT 'Customer Source View' AS CheckName, COUNT(*) AS RowCount
FROM dbo.vw_ETL_DimCustomer_Source

UNION ALL

SELECT 'Product Source View', COUNT(*)
FROM dbo.vw_ETL_DimProduct_Source

UNION ALL

SELECT 'Store Source View', COUNT(*)
FROM dbo.vw_ETL_DimStore_Source

UNION ALL

SELECT 'Jallow Sales Source', COUNT(*)
FROM dbo.vw_ETL_JallowMeridian_FactSales_Source

UNION ALL

SELECT 'Crestline Valid Sales', COUNT(*)
FROM dbo.vw_ETL_Crestline_FactSales_Valid

UNION ALL

SELECT 'Crestline Rejected Sales', COUNT(*)
FROM dbo.vw_ETL_Crestline_FactSales_Rejected;
GO

/*
EXPECTED:
Customer Source View       5,800
Product Source View          120
Store Source View             24
Jallow Sales Source       60,000
Crestline Valid Sales     17,300
Crestline Rejected Sales     700

STOP if these numbers do not match.
*/


/*=============================================================================
STEP 1 — RUN SECOND
CLEAR PRIOR DEVELOPMENT LOADS

This keeps:
- the Unknown dimension records with key 0
- the already populated DimDate table
=============================================================================*/

USE JallowMeridianDW;
GO

DELETE FROM dbo.FactSales;
DELETE FROM dbo.ETLRejectedRecords;

DELETE FROM dbo.DimCustomer
WHERE CustomerKey <> 0;

DELETE FROM dbo.DimProduct
WHERE ProductKey <> 0;

DELETE FROM dbo.DimStore
WHERE StoreKey <> 0;
GO

/* Reset identity counters so the next generated keys begin cleanly. */

DBCC CHECKIDENT ('dbo.FactSales', RESEED, 0);
DBCC CHECKIDENT ('dbo.ETLRejectedRecords', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimCustomer', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimProduct', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimStore', RESEED, 0);
GO

/* Verify cleanup */

SELECT 'DimCustomer' AS TableName, COUNT(*) AS TotalRows
FROM dbo.DimCustomer

UNION ALL

SELECT 'DimProduct', COUNT(*)
FROM dbo.DimProduct

UNION ALL

SELECT 'DimStore', COUNT(*)
FROM dbo.DimStore

UNION ALL

SELECT 'ETLRejectedRecords', COUNT(*)
FROM dbo.ETLRejectedRecords

UNION ALL

SELECT 'FactSales', COUNT(*)
FROM dbo.FactSales;
GO

/*
EXPECTED AFTER CLEANUP:
DimCustomer             1
DimProduct              1
DimStore                1
ETLRejectedRecords      0
FactSales               0
*/


/*=============================================================================
STEP 2 — RUN THIRD
LOAD DimCustomer
=============================================================================*/

INSERT INTO dbo.DimCustomer
(
    SourceSystem,
    SourceCustomerID,
    FirstName,
    LastName,
    Email,
    State,
    JoinDate,
    Phone,
    CustomerSegment,
    LoyaltyStatus,
    PointsBalance,
    PotentialCrossSystemMatch
)
SELECT
    SourceSystem,
    SourceCustomerID,
    FirstName,
    LastName,
    Email,
    State,
    JoinDate,
    Phone,
    CustomerSegment,
    LoyaltyStatus,
    PointsBalance,
    PotentialCrossSystemMatch
FROM dbo.vw_ETL_DimCustomer_Source;
GO

/* Verify DimCustomer */

SELECT COUNT(*) AS DimCustomerRows
FROM dbo.DimCustomer;
GO

/*
EXPECTED:
5,801
= 5,800 source customer rows + 1 Unknown customer
*/


/*=============================================================================
STEP 3 — RUN FOURTH
LOAD DimProduct
=============================================================================*/

INSERT INTO dbo.DimProduct
(
    SourceSystem,
    SourceProductID,
    ProductName,
    Category,
    SubCategory,
    UnitCost,
    ListPrice,
    IsActive
)
SELECT
    SourceSystem,
    SourceProductID,
    ProductName,
    Category,
    SubCategory,
    UnitCost,
    ListPrice,
    IsActive
FROM dbo.vw_ETL_DimProduct_Source;
GO

/* Verify DimProduct */

SELECT COUNT(*) AS DimProductRows
FROM dbo.DimProduct;
GO

/*
EXPECTED:
121
= 120 source products + 1 Unknown product
*/


/*=============================================================================
STEP 4 — RUN FIFTH
LOAD DimStore
=============================================================================*/

INSERT INTO dbo.DimStore
(
    SourceSystem,
    SourceStoreID,
    StoreName,
    City,
    State,
    Region,
    OpenDate
)
SELECT
    SourceSystem,
    SourceStoreID,
    StoreName,
    City,
    State,
    Region,
    OpenDate
FROM dbo.vw_ETL_DimStore_Source;
GO

/* Verify DimStore */

SELECT
    SourceSystem,
    COUNT(*) AS StoreRows
FROM dbo.DimStore
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

/*
EXPECTED:
Crestline          12
JallowMeridian     12
Unknown             1

TOTAL = 25
*/


/*=============================================================================
STEP 5 — RUN SIXTH
VERIFY ALL DIMENSIONS BEFORE MOVING TO TRANSACTIONS
=============================================================================*/

SELECT 'DimCustomer' AS TableName, COUNT(*) AS TotalRows
FROM dbo.DimCustomer

UNION ALL

SELECT 'DimProduct', COUNT(*)
FROM dbo.DimProduct

UNION ALL

SELECT 'DimStore', COUNT(*)
FROM dbo.DimStore

UNION ALL

SELECT 'DimDate', COUNT(*)
FROM dbo.DimDate;
GO

/*
EXPECTED:
DimCustomer     5,801
DimProduct        121
DimStore           25
DimDate         2,558
*/


/*=============================================================================
STEP 6 — RUN SEVENTH
LOAD CRESTLINE REJECTED / EXCEPTION RECORDS
=============================================================================*/

DELETE FROM dbo.ETLRejectedRecords;
GO

INSERT INTO dbo.ETLRejectedRecords
(
    SourceSystem,
    SourceTable,
    SourceRecordID,
    RejectReason,
    RejectColumn,
    RejectValue
)
SELECT
    'Crestline' AS SourceSystem,
    'LegacyTransactions' AS SourceTable,
    R.SourceTransactionID,
    LEFT(NULLIF(R.RejectReason, ''), 250) AS RejectReason,

    CASE
        WHEN R.IsNullQuantity = 1
          OR R.IsNegativeQuantity = 1
            THEN 'qty'

        WHEN R.IsNullPrice = 1
          OR R.IsInvalidPrice = 1
          OR R.IsNegativePrice = 1
            THEN 'price'

        WHEN R.IsInvalidDate = 1
            THEN 'txn_date'

        WHEN R.IsUnknownProduct = 1
            THEN 'item_num'

        ELSE 'Unknown'
    END AS RejectColumn,

    CASE
        WHEN R.IsNullQuantity = 1
            THEN 'NULL'

        WHEN R.IsNegativeQuantity = 1
            THEN CAST(LT.qty AS VARCHAR(250))

        WHEN R.IsNullPrice = 1
            THEN 'NULL'

        WHEN R.IsInvalidPrice = 1
          OR R.IsNegativePrice = 1
            THEN LT.price

        WHEN R.IsInvalidDate = 1
            THEN LT.txn_date

        WHEN R.IsUnknownProduct = 1
            THEN CAST(LT.item_num AS VARCHAR(250))

        ELSE NULL
    END AS RejectValue

FROM dbo.vw_ETL_Crestline_FactSales_Rejected AS R

INNER JOIN CrestlineLegacySalesDB.dbo.LegacyTransactions AS LT
    ON CAST(LT.txn_id AS VARCHAR(30)) = R.SourceTransactionID;
GO

/* Verify rejected rows */

SELECT COUNT(*) AS RejectedRows
FROM dbo.ETLRejectedRecords;
GO

/*
EXPECTED:
700
*/


/*=============================================================================
STEP 7 — RUN EIGHTH
LOAD JALLOW MERIDIAN SALES INTO FactSales
=============================================================================*/

/* FactSales should still be empty at this point. */

DELETE FROM dbo.FactSales;
GO

INSERT INTO dbo.FactSales
(
    SourceSystem,
    SourceTransactionID,
    SourceLineID,
    CustomerKey,
    ProductKey,
    StoreKey,
    DateKey,
    OrderStatus,
    SalesChannel,
    Quantity,
    UnitPrice,
    DiscountPct,
    DiscountAmount,
    SalesAmount,
    CostAmount,
    ProfitAmount
)
SELECT
    S.SourceSystem,
    S.SourceTransactionID,
    S.SourceLineID,

    COALESCE(C.CustomerKey, 0) AS CustomerKey,
    COALESCE(P.ProductKey, 0) AS ProductKey,
    COALESCE(ST.StoreKey, 0) AS StoreKey,
    COALESCE(D.DateKey, 0) AS DateKey,

    S.OrderStatus,
    S.SalesChannel,
    S.Quantity,
    S.UnitPrice,
    S.DiscountPct,
    S.DiscountAmount,
    S.SalesAmount,
    S.CostAmount,
    S.ProfitAmount

FROM dbo.vw_ETL_JallowMeridian_FactSales_Source AS S

LEFT JOIN dbo.DimCustomer AS C
    ON C.SourceSystem = 'JallowMeridian'
   AND C.SourceCustomerID = S.SourceCustomerID

LEFT JOIN dbo.DimProduct AS P
    ON P.SourceSystem = 'JallowMeridian'
   AND P.SourceProductID = S.SourceProductID

LEFT JOIN dbo.DimStore AS ST
    ON ST.SourceSystem = 'JallowMeridian'
   AND ST.SourceStoreID = S.SourceStoreID

LEFT JOIN dbo.DimDate AS D
    ON D.FullDate = S.TransactionDate;
GO


/*=============================================================================
STEP 8 — RUN NINTH
VERIFY JALLOW MERIDIAN FactSales BEFORE LOADING CRESTLINE
=============================================================================*/

SELECT
    SourceSystem,
    COUNT(*) AS FactRows
FROM dbo.FactSales
GROUP BY SourceSystem;
GO

/*
EXPECTED:
JallowMeridian     60,000
*/


/* Verify that all dimension lookups succeeded */

SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END) AS UnknownCustomers,
    SUM(CASE WHEN ProductKey  = 0 THEN 1 ELSE 0 END) AS UnknownProducts,
    SUM(CASE WHEN StoreKey    = 0 THEN 1 ELSE 0 END) AS UnknownStores,
    SUM(CASE WHEN DateKey     = 0 THEN 1 ELSE 0 END) AS UnknownDates
FROM dbo.FactSales;
GO

/*
EXPECTED:
UnknownCustomers    0
UnknownProducts     0
UnknownStores       0
UnknownDates        0

STOP if any value is greater than 0.
*/


/*=============================================================================
STEP 9 — RUN TENTH
LOAD VALID CRESTLINE SALES INTO FactSales
=============================================================================*/

INSERT INTO dbo.FactSales
(
    SourceSystem,
    SourceTransactionID,
    SourceLineID,
    CustomerKey,
    ProductKey,
    StoreKey,
    DateKey,
    OrderStatus,
    SalesChannel,
    Quantity,
    UnitPrice,
    DiscountPct,
    DiscountAmount,
    SalesAmount,
    CostAmount,
    ProfitAmount
)
SELECT
    S.SourceSystem,
    S.SourceTransactionID,
    S.SourceLineID,

    COALESCE(C.CustomerKey, 0) AS CustomerKey,
    COALESCE(P.ProductKey, 0) AS ProductKey,
    COALESCE(ST.StoreKey, 0) AS StoreKey,
    COALESCE(D.DateKey, 0) AS DateKey,

    S.OrderStatus,
    S.SalesChannel,
    S.Quantity,
    S.UnitPrice,
    S.DiscountPct,
    S.DiscountAmount,
    S.SalesAmount,
    S.CostAmount,
    S.ProfitAmount

FROM dbo.vw_ETL_Crestline_FactSales_Valid AS S

LEFT JOIN dbo.DimCustomer AS C
    ON C.SourceSystem = 'Crestline'
   AND C.SourceCustomerID = S.SourceCustomerID

/*
IMPORTANT:
Crestline item_num values are mapped to the Jallow Meridian product catalog,
which is being used as the enterprise product master.
*/
LEFT JOIN dbo.DimProduct AS P
    ON P.SourceSystem = 'JallowMeridian'
   AND P.SourceProductID = S.SourceProductID

LEFT JOIN dbo.DimStore AS ST
    ON ST.SourceSystem = 'Crestline'
   AND ST.SourceStoreID = S.SourceStoreID

LEFT JOIN dbo.DimDate AS D
    ON D.FullDate = S.TransactionDate;
GO


/*=============================================================================
STEP 10 — RUN ELEVENTH
FINAL WAREHOUSE VALIDATION
=============================================================================*/


/* A. Final warehouse object counts */

SELECT 'DimCustomer' AS WarehouseObject, COUNT(*) AS TotalRows
FROM dbo.DimCustomer

UNION ALL

SELECT 'DimProduct', COUNT(*)
FROM dbo.DimProduct

UNION ALL

SELECT 'DimStore', COUNT(*)
FROM dbo.DimStore

UNION ALL

SELECT 'DimDate', COUNT(*)
FROM dbo.DimDate

UNION ALL

SELECT 'ETLRejectedRecords', COUNT(*)
FROM dbo.ETLRejectedRecords

UNION ALL

SELECT 'FactSales', COUNT(*)
FROM dbo.FactSales;
GO

/*
EXPECTED:
DimCustomer             5,801
DimProduct                121
DimStore                   25
DimDate                 2,558
ETLRejectedRecords        700
FactSales              77,300
*/


/* B. FactSales reconciliation by source system */

SELECT
    SourceSystem,
    COUNT(*) AS FactRows
FROM dbo.FactSales
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

/*
EXPECTED:
Crestline          17,300
JallowMeridian     60,000

TOTAL:
77,300
*/


/* C. Confirm total FactSales rows */

SELECT COUNT(*) AS TotalFactSalesRows
FROM dbo.FactSales;
GO

/*
EXPECTED:
77,300
*/


/* D. Verify no loaded fact uses an Unknown dimension key */

SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END) AS UnknownCustomers,
    SUM(CASE WHEN ProductKey  = 0 THEN 1 ELSE 0 END) AS UnknownProducts,
    SUM(CASE WHEN StoreKey    = 0 THEN 1 ELSE 0 END) AS UnknownStores,
    SUM(CASE WHEN DateKey     = 0 THEN 1 ELSE 0 END) AS UnknownDates
FROM dbo.FactSales;
GO

/*
EXPECTED:
0   0   0   0
*/


/* E. Verify no duplicate source lines were loaded */

SELECT
    SourceSystem,
    SourceLineID,
    COUNT(*) AS DuplicateCount
FROM dbo.FactSales
GROUP BY
    SourceSystem,
    SourceLineID
HAVING COUNT(*) > 1;
GO

/*
EXPECTED:
NO ROWS RETURNED
*/


/* F. Reconcile the Crestline acquisition transactions */

SELECT
    (SELECT COUNT(*)
     FROM CrestlineLegacySalesDB.dbo.LegacyTransactions)
        AS OriginalCrestlineTransactions,

    (SELECT COUNT(*)
     FROM dbo.FactSales
     WHERE SourceSystem = 'Crestline')
        AS CrestlineLoadedToFactSales,

    (SELECT COUNT(*)
     FROM dbo.ETLRejectedRecords
     WHERE SourceSystem = 'Crestline')
        AS CrestlineRejectedRecords;
GO

/*
EXPECTED:
OriginalCrestlineTransactions     18,000
CrestlineLoadedToFactSales        17,300
CrestlineRejectedRecords             700

17,300 + 700 = 18,000
*/


/* G. Optional financial validation */

SELECT
    SourceSystem,
    COUNT(*) AS SalesLines,
    SUM(SalesAmount) AS TotalSalesAmount,
    SUM(CostAmount) AS TotalCostAmount,
    SUM(ProfitAmount) AS TotalProfitAmount
FROM dbo.FactSales
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO


/* H. Optional potential customer-overlap validation */

SELECT
    SourceSystem,
    SUM(CASE WHEN PotentialCrossSystemMatch = 1 THEN 1 ELSE 0 END)
        AS PotentialMatches
FROM dbo.DimCustomer
WHERE CustomerKey <> 0
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

/*
EXPECTED WITH THE PROJECT DATA:
Crestline            487
JallowMeridian       487
*/


PRINT '============================================================';
PRINT 'JallowMeridianDW staged warehouse load successfully completed.';
PRINT 'Expected FactSales rows: 77,300.';
PRINT 'Expected rejected Crestline transactions: 700.';
PRINT 'Next project phase: SSIS ETL package.';
PRINT '============================================================';
GO
