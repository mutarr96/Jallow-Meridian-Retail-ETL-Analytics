/*
===============================================================================
JALLOW MERIDIAN RETAIL GROUP
SSIS LOAD-READY VIEWS
Portfolio Project: SQL Server + SSIS + Tableau
===============================================================================

PURPOSE
-------
These views make the SSIS package simple and visual:

    OLE DB Source  --->  OLE DB Destination

The existing transformation views already clean the source data.
These SSIS-specific views additionally resolve warehouse surrogate keys
for the FactSales loads and prepare rejected records for the audit table.

IMPORTANT LOAD ORDER IN SSIS
----------------------------
1. Reset warehouse load
2. Load DimCustomer
3. Load DimProduct
4. Load DimStore
5. Load ETLRejectedRecords
6. Load Jallow Meridian FactSales
7. Load Crestline FactSales
8. Validate in SSMS

The FactSales ready views depend on the dimensions already being loaded.
===============================================================================
*/

USE JallowMeridianDW;
GO


/*=============================================================================
1) SSIS-READY REJECTED RECORDS
=============================================================================*/

CREATE OR ALTER VIEW dbo.vw_SSIS_RejectedRecords_Ready
AS
SELECT
    CAST('Crestline' AS VARCHAR(30)) AS SourceSystem,
    CAST('LegacyTransactions' AS VARCHAR(60)) AS SourceTable,
    R.SourceTransactionID AS SourceRecordID,
    LEFT(NULLIF(R.RejectReason, ''), 250) AS RejectReason,

    CAST(
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
        END
        AS VARCHAR(60)
    ) AS RejectColumn,

    CAST(
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
        END
        AS VARCHAR(250)
    ) AS RejectValue

FROM dbo.vw_ETL_Crestline_FactSales_Rejected AS R

INNER JOIN CrestlineLegacySalesDB.dbo.LegacyTransactions AS LT
    ON CAST(LT.txn_id AS VARCHAR(30)) = R.SourceTransactionID;
GO


/*=============================================================================
2) SSIS-READY JALLOW MERIDIAN FACTSALES

This view resolves:
- CustomerKey
- ProductKey
- StoreKey
- DateKey

The source should return 60,000 rows after dimensions are loaded.
=============================================================================*/

CREATE OR ALTER VIEW dbo.vw_SSIS_JallowMeridian_FactSales_Ready
AS
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
3) SSIS-READY CRESTLINE FACTSALES

Valid Crestline transactions only.
Crestline item_num values map to Jallow Meridian's product master.

The source should return 17,300 rows after dimensions are loaded.
=============================================================================*/

CREATE OR ALTER VIEW dbo.vw_SSIS_Crestline_FactSales_Ready
AS
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
4) OPTIONAL COMBINED FACT VIEW
Useful later for quick validation or a single-source SSIS design.
=============================================================================*/

CREATE OR ALTER VIEW dbo.vw_SSIS_All_FactSales_Ready
AS
SELECT *
FROM dbo.vw_SSIS_JallowMeridian_FactSales_Ready

UNION ALL

SELECT *
FROM dbo.vw_SSIS_Crestline_FactSales_Ready;
GO


/*=============================================================================
5) VALIDATION
NOTE:
The FactSales-ready views should be checked AFTER the dimensions have data.
=============================================================================*/

SELECT COUNT(*) AS RejectedRows
FROM dbo.vw_SSIS_RejectedRecords_Ready;
GO
-- Expected: 700

SELECT COUNT(*) AS JallowFactRows
FROM dbo.vw_SSIS_JallowMeridian_FactSales_Ready;
GO
-- Expected: 60,000

SELECT COUNT(*) AS CrestlineFactRows
FROM dbo.vw_SSIS_Crestline_FactSales_Ready;
GO
-- Expected: 17,300

SELECT COUNT(*) AS AllFactRows
FROM dbo.vw_SSIS_All_FactSales_Ready;
GO
-- Expected: 77,300

SELECT
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END) AS UnknownCustomers,
    SUM(CASE WHEN ProductKey  = 0 THEN 1 ELSE 0 END) AS UnknownProducts,
    SUM(CASE WHEN StoreKey    = 0 THEN 1 ELSE 0 END) AS UnknownStores,
    SUM(CASE WHEN DateKey     = 0 THEN 1 ELSE 0 END) AS UnknownDates
FROM dbo.vw_SSIS_All_FactSales_Ready;
GO
-- Expected: 0, 0, 0, 0

PRINT 'SSIS load-ready views created successfully.';
GO
