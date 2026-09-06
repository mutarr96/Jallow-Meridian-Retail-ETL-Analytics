
/*
=====================================================================
JALLOW MERIDIAN RETAIL GROUP
ETL TRANSFORMATION LAYER
Portfolio Project: SQL Server + SSIS + Tableau
=====================================================================

PURPOSE
-------
Create reusable SQL views inside JallowMeridianDW that prepare source
data for dimensional warehouse loading.

This layer demonstrates:
- Cross-database querying
- LEFT JOIN / JOIN
- CASE
- LTRIM / RTRIM / LOWER
- TRY_CONVERT
- REPLACE
- COALESCE
- EXISTS
- Calculated sales, cost, discount, and profit measures
- Data-quality flags
- Valid/rejected record separation

IMPORTANT
---------
These views DO NOT modify the operational source databases.
They only present cleaned / standardized versions of the source data.
=====================================================================
*/

USE JallowMeridianDW;
GO


/* ============================================================
   1) CUSTOMER SOURCE VIEW
   Combines current Jallow Meridian customers with Crestline customers.
   CRM and loyalty fields are added for current Jallow Meridian customers.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_DimCustomer_Source
AS

/* ----------------------------
   Jallow Meridian customers
   ---------------------------- */
SELECT
    CAST('JallowMeridian' AS VARCHAR(30)) AS SourceSystem,
    CAST(C.CustomerID AS VARCHAR(20)) AS SourceCustomerID,

    C.FirstName,
    C.LastName,

    CASE
        WHEN C.Email IS NULL THEN NULL
        ELSE LOWER(LTRIM(RTRIM(C.Email)))
    END AS Email,

    CASE UPPER(LTRIM(RTRIM(C.State)))
        WHEN 'OHIO' THEN 'OH'
        WHEN 'OH' THEN 'OH'
        WHEN 'PENNSYLVANIA' THEN 'PA'
        WHEN 'PA' THEN 'PA'
        WHEN 'MICHIGAN' THEN 'MI'
        WHEN 'MI' THEN 'MI'
        WHEN 'INDIANA' THEN 'IN'
        WHEN 'IN' THEN 'IN'
        WHEN 'GEORGIA' THEN 'GA'
        WHEN 'GA' THEN 'GA'
        WHEN 'NORTH CAROLINA' THEN 'NC'
        WHEN 'NC' THEN 'NC'
        WHEN 'TENNESSEE' THEN 'TN'
        WHEN 'TN' THEN 'TN'
        WHEN 'TEXAS' THEN 'TX'
        WHEN 'TX' THEN 'TX'
        WHEN 'ILLINOIS' THEN 'IL'
        WHEN 'IL' THEN 'IL'
        WHEN 'KENTUCKY' THEN 'KY'
        WHEN 'KY' THEN 'KY'
        ELSE NULL
    END AS State,

    C.JoinDate,

    P.Phone,
    P.CustomerSegment,
    L.LoyaltyStatus,
    L.PointsBalance,

    CAST(
        CASE
            WHEN C.Email IS NOT NULL
             AND EXISTS
                (
                    SELECT 1
                    FROM CrestlineLegacySalesDB.dbo.LegacyCustomers AS LC
                    WHERE LC.email_addr IS NOT NULL
                      AND LOWER(LTRIM(RTRIM(LC.email_addr)))
                          = LOWER(LTRIM(RTRIM(C.Email)))
                )
            THEN 1
            ELSE 0
        END
        AS BIT
    ) AS PotentialCrossSystemMatch

FROM JallowMeridianSalesDB.dbo.Customers AS C

LEFT JOIN JallowMeridianCRMDB.dbo.CustomerProfile AS P
    ON C.CustomerID = P.CustomerID

LEFT JOIN JallowMeridianCRMDB.dbo.LoyaltyAccounts AS L
    ON C.CustomerID = L.CustomerID


UNION ALL


/* ----------------------------
   Crestline customers
   ---------------------------- */
SELECT
    CAST('Crestline' AS VARCHAR(30)) AS SourceSystem,
    CAST(LC.cust_num AS VARCHAR(20)) AS SourceCustomerID,

    LC.fname AS FirstName,
    LC.lname AS LastName,

    CASE
        WHEN LC.email_addr IS NULL THEN NULL
        ELSE LOWER(LTRIM(RTRIM(LC.email_addr)))
    END AS Email,

    CASE UPPER(LTRIM(RTRIM(LC.state_code)))
        WHEN 'OHIO' THEN 'OH'
        WHEN 'OH' THEN 'OH'
        WHEN 'GEORGIA' THEN 'GA'
        WHEN 'GA' THEN 'GA'
        WHEN 'PENNSYLVANIA' THEN 'PA'
        WHEN 'PA' THEN 'PA'
        WHEN 'MICHIGAN' THEN 'MI'
        WHEN 'MI' THEN 'MI'
        WHEN 'TEXAS' THEN 'TX'
        WHEN 'TX' THEN 'TX'
        ELSE NULL
    END AS State,

    COALESCE
    (
        TRY_CONVERT(DATE, LC.signup_dt, 23),
        TRY_CONVERT(DATE, LC.signup_dt, 101)
    ) AS JoinDate,

    CAST(NULL AS VARCHAR(30)) AS Phone,
    CAST(NULL AS VARCHAR(30)) AS CustomerSegment,
    CAST(NULL AS VARCHAR(20)) AS LoyaltyStatus,
    CAST(NULL AS INT) AS PointsBalance,

    CAST(
        CASE
            WHEN LC.email_addr IS NOT NULL
             AND EXISTS
                (
                    SELECT 1
                    FROM JallowMeridianSalesDB.dbo.Customers AS C2
                    WHERE C2.Email IS NOT NULL
                      AND LOWER(LTRIM(RTRIM(C2.Email)))
                          = LOWER(LTRIM(RTRIM(LC.email_addr)))
                )
            THEN 1
            ELSE 0
        END
        AS BIT
    ) AS PotentialCrossSystemMatch

FROM CrestlineLegacySalesDB.dbo.LegacyCustomers AS LC;
GO


/* ============================================================
   2) PRODUCT SOURCE VIEW
   Jallow Meridian's current Products table is the master product catalog.
   Crestline item_num values will be looked up against SourceProductID.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_DimProduct_Source
AS

SELECT
    CAST('JallowMeridian' AS VARCHAR(30)) AS SourceSystem,
    CAST(P.ProductID AS VARCHAR(20)) AS SourceProductID,
    P.ProductName,
    P.Category,
    P.SubCategory,
    P.UnitCost,
    P.ListPrice,
    P.IsActive
FROM JallowMeridianSalesDB.dbo.Products AS P;
GO


/* ============================================================
   3) STORE SOURCE VIEW
   Includes current stores plus the 12 Crestline legacy store codes.
   Crestline location attributes remain Unknown because the legacy
   source provides only store_code.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_DimStore_Source
AS

SELECT
    CAST('JallowMeridian' AS VARCHAR(30)) AS SourceSystem,
    CAST(S.StoreID AS VARCHAR(20)) AS SourceStoreID,
    S.StoreName,
    S.City,
    S.State,
    S.Region,
    S.OpenDate
FROM JallowMeridianSalesDB.dbo.Stores AS S

UNION ALL

SELECT DISTINCT
    CAST('Crestline' AS VARCHAR(30)) AS SourceSystem,
    CAST(LT.store_code AS VARCHAR(20)) AS SourceStoreID,
    CAST(CONCAT('Crestline Store ', LT.store_code) AS VARCHAR(100)) AS StoreName,
    CAST(NULL AS VARCHAR(60)) AS City,
    CAST(NULL AS CHAR(2)) AS State,
    CAST('Unknown' AS VARCHAR(20)) AS Region,
    CAST(NULL AS DATE) AS OpenDate
FROM CrestlineLegacySalesDB.dbo.LegacyTransactions AS LT
WHERE LT.store_code IS NOT NULL;
GO


/* ============================================================
   4) JALLOW MERIDIAN SALES SOURCE VIEW
   Grain = one OrderDetails row.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_JallowMeridian_FactSales_Source
AS

SELECT
    CAST('JallowMeridian' AS VARCHAR(30)) AS SourceSystem,

    CAST(O.OrderID AS VARCHAR(30)) AS SourceTransactionID,
    CAST(OD.OrderDetailID AS VARCHAR(30)) AS SourceLineID,

    CAST(O.CustomerID AS VARCHAR(20)) AS SourceCustomerID,
    CAST(OD.ProductID AS VARCHAR(20)) AS SourceProductID,
    CAST(O.StoreID AS VARCHAR(20)) AS SourceStoreID,

    O.OrderDate AS TransactionDate,

    O.OrderStatus,
    O.Channel AS SalesChannel,

    OD.Quantity,

    CAST(OD.UnitPrice AS DECIMAL(12,2)) AS UnitPrice,
    CAST(OD.DiscountPct AS DECIMAL(7,4)) AS DiscountPct,

    CAST(
        OD.Quantity * OD.UnitPrice * OD.DiscountPct
        AS DECIMAL(14,2)
    ) AS DiscountAmount,

    CAST(
        OD.Quantity * OD.UnitPrice * (1 - OD.DiscountPct)
        AS DECIMAL(14,2)
    ) AS SalesAmount,

    CAST(
        OD.Quantity * P.UnitCost
        AS DECIMAL(14,2)
    ) AS CostAmount,

    CAST(
        (OD.Quantity * OD.UnitPrice * (1 - OD.DiscountPct))
        - (OD.Quantity * P.UnitCost)
        AS DECIMAL(14,2)
    ) AS ProfitAmount

FROM JallowMeridianSalesDB.dbo.Orders AS O

INNER JOIN JallowMeridianSalesDB.dbo.OrderDetails AS OD
    ON O.OrderID = OD.OrderID

INNER JOIN JallowMeridianSalesDB.dbo.Products AS P
    ON OD.ProductID = P.ProductID;
GO


/* ============================================================
   5) CRESTLINE SALES PROFILING / TRANSFORMATION VIEW

   This converts recoverable formats but also flags records that
   require rejection/review.

   Portfolio rule used here:
   - NULL quantity: reject
   - negative quantity: reject/review
   - NULL price: reject
   - FREE / nonnumeric price: reject/review
   - negative price: reject/review
   - invalid transaction date: reject
   - missing product match: reject
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_Crestline_FactSales_Profile
AS

SELECT
    CAST('Crestline' AS VARCHAR(30)) AS SourceSystem,

    CAST(LT.txn_id AS VARCHAR(30)) AS SourceTransactionID,
    CAST(LT.txn_id AS VARCHAR(30)) AS SourceLineID,

    CAST(LT.cust_num AS VARCHAR(20)) AS SourceCustomerID,
    CAST(LT.item_num AS VARCHAR(20)) AS SourceProductID,
    CAST(LT.store_code AS VARCHAR(20)) AS SourceStoreID,

    COALESCE
    (
        TRY_CONVERT(DATE, LT.txn_date, 23),
        TRY_CONVERT(DATE, LT.txn_date, 101)
    ) AS TransactionDate,

    CAST('Completed' AS VARCHAR(20)) AS OrderStatus,
    CAST('Legacy' AS VARCHAR(20)) AS SalesChannel,

    LT.qty AS Quantity,

    TRY_CONVERT
    (
        DECIMAL(12,2),
        REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
    ) AS UnitPrice,

    CAST(0 AS DECIMAL(7,4)) AS DiscountPct,

    CAST(0 AS DECIMAL(14,2)) AS DiscountAmount,

    CAST(
        CASE
            WHEN LT.qty > 0
             AND TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) >= 0
            THEN
                LT.qty *
                TRY_CONVERT
                (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                )
            ELSE NULL
        END
        AS DECIMAL(14,2)
    ) AS SalesAmount,

    CAST(
        CASE
            WHEN LT.qty > 0
             AND P.ProductID IS NOT NULL
            THEN LT.qty * P.UnitCost
            ELSE NULL
        END
        AS DECIMAL(14,2)
    ) AS CostAmount,

    CAST(
        CASE
            WHEN LT.qty > 0
             AND P.ProductID IS NOT NULL
             AND TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) >= 0
            THEN
                (
                    LT.qty *
                    TRY_CONVERT
                    (
                        DECIMAL(12,2),
                        REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                    )
                )
                -
                (LT.qty * P.UnitCost)
            ELSE NULL
        END
        AS DECIMAL(14,2)
    ) AS ProfitAmount,

    /* -------- Data-quality flags -------- */

    CAST(CASE WHEN LT.qty IS NULL THEN 1 ELSE 0 END AS BIT)
        AS IsNullQuantity,

    CAST(CASE WHEN LT.qty < 0 THEN 1 ELSE 0 END AS BIT)
        AS IsNegativeQuantity,

    CAST(CASE WHEN LT.price IS NULL THEN 1 ELSE 0 END AS BIT)
        AS IsNullPrice,

    CAST(
        CASE
            WHEN LT.price IS NOT NULL
             AND TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) IS NULL
            THEN 1
            ELSE 0
        END
        AS BIT
    ) AS IsInvalidPrice,

    CAST(
        CASE
            WHEN TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) < 0
            THEN 1
            ELSE 0
        END
        AS BIT
    ) AS IsNegativePrice,

    CAST(
        CASE
            WHEN COALESCE
                 (
                    TRY_CONVERT(DATE, LT.txn_date, 23),
                    TRY_CONVERT(DATE, LT.txn_date, 101)
                 ) IS NULL
            THEN 1
            ELSE 0
        END
        AS BIT
    ) AS IsInvalidDate,

    CAST(CASE WHEN P.ProductID IS NULL THEN 1 ELSE 0 END AS BIT)
        AS IsUnknownProduct,

    CAST(
        CASE
            WHEN LT.qty IS NULL
              OR LT.qty < 0
              OR LT.price IS NULL
              OR TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) IS NULL
              OR TRY_CONVERT
                 (
                    DECIMAL(12,2),
                    REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                 ) < 0
              OR COALESCE
                 (
                    TRY_CONVERT(DATE, LT.txn_date, 23),
                    TRY_CONVERT(DATE, LT.txn_date, 101)
                 ) IS NULL
              OR P.ProductID IS NULL
            THEN 0
            ELSE 1
        END
        AS BIT
    ) AS IsValidForWarehouse,

    CAST(
        CONCAT
        (
            CASE WHEN LT.qty IS NULL
                 THEN 'NULL quantity; ' ELSE '' END,

            CASE WHEN LT.qty < 0
                 THEN 'Negative quantity; ' ELSE '' END,

            CASE WHEN LT.price IS NULL
                 THEN 'NULL price; ' ELSE '' END,

            CASE
                WHEN LT.price IS NOT NULL
                 AND TRY_CONVERT
                     (
                        DECIMAL(12,2),
                        REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                     ) IS NULL
                THEN 'Nonnumeric price; '
                ELSE ''
            END,

            CASE
                WHEN TRY_CONVERT
                     (
                        DECIMAL(12,2),
                        REPLACE(LTRIM(RTRIM(LT.price)), '$', '')
                     ) < 0
                THEN 'Negative price; '
                ELSE ''
            END,

            CASE
                WHEN COALESCE
                     (
                        TRY_CONVERT(DATE, LT.txn_date, 23),
                        TRY_CONVERT(DATE, LT.txn_date, 101)
                     ) IS NULL
                THEN 'Invalid transaction date; '
                ELSE ''
            END,

            CASE WHEN P.ProductID IS NULL
                 THEN 'Unknown product; ' ELSE '' END
        )
        AS VARCHAR(500)
    ) AS RejectReason

FROM CrestlineLegacySalesDB.dbo.LegacyTransactions AS LT

LEFT JOIN JallowMeridianSalesDB.dbo.Products AS P
    ON LT.item_num = P.ProductID;
GO


/* ============================================================
   6) CRESTLINE VALID SALES VIEW
   Only rows that pass all documented quality rules.
   Expected rows with supplied project data: 17,300.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_Crestline_FactSales_Valid
AS

SELECT
    SourceSystem,
    SourceTransactionID,
    SourceLineID,
    SourceCustomerID,
    SourceProductID,
    SourceStoreID,
    TransactionDate,
    OrderStatus,
    SalesChannel,
    Quantity,
    UnitPrice,
    DiscountPct,
    DiscountAmount,
    SalesAmount,
    CostAmount,
    ProfitAmount

FROM dbo.vw_ETL_Crestline_FactSales_Profile

WHERE IsValidForWarehouse = 1;
GO


/* ============================================================
   7) CRESTLINE REJECTED SALES VIEW
   Rows that fail one or more warehouse-quality rules.
   Expected rows with supplied project data: 700.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ETL_Crestline_FactSales_Rejected
AS

SELECT
    SourceSystem,
    SourceTransactionID,
    SourceLineID,
    SourceCustomerID,
    SourceProductID,
    SourceStoreID,
    TransactionDate,
    Quantity,
    UnitPrice,
    IsNullQuantity,
    IsNegativeQuantity,
    IsNullPrice,
    IsInvalidPrice,
    IsNegativePrice,
    IsInvalidDate,
    IsUnknownProduct,
    RejectReason

FROM dbo.vw_ETL_Crestline_FactSales_Profile

WHERE IsValidForWarehouse = 0;
GO


/* ============================================================
   8) VALIDATION QUERIES
   ============================================================ */

-- A. Customer source row count
SELECT
    SourceSystem,
    COUNT(*) AS CustomerRows
FROM dbo.vw_ETL_DimCustomer_Source
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

-- Expected:
-- Crestline       = 1,800
-- JallowMeridian  = 4,000


-- B. Potential acquisition overlap
SELECT
    SourceSystem,
    SUM(CASE WHEN PotentialCrossSystemMatch = 1 THEN 1 ELSE 0 END)
        AS PotentialMatchingCustomers
FROM dbo.vw_ETL_DimCustomer_Source
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

-- With the supplied project data, each side should identify 487 records
-- with a standardized email appearing in the other source system.


-- C. Product source count
SELECT COUNT(*) AS ProductRows
FROM dbo.vw_ETL_DimProduct_Source;
GO
-- Expected: 120


-- D. Store source counts
SELECT
    SourceSystem,
    COUNT(*) AS StoreRows
FROM dbo.vw_ETL_DimStore_Source
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

-- Expected:
-- Crestline       = 12
-- JallowMeridian  = 12


-- E. Jallow Meridian fact-source rows
SELECT COUNT(*) AS JallowMeridianSalesRows
FROM dbo.vw_ETL_JallowMeridian_FactSales_Source;
GO
-- Expected: 60,000


-- F. Crestline profile counts
SELECT
    COUNT(*) AS TotalCrestlineTransactions,
    SUM(CASE WHEN IsValidForWarehouse = 1 THEN 1 ELSE 0 END) AS ValidRows,
    SUM(CASE WHEN IsValidForWarehouse = 0 THEN 1 ELSE 0 END) AS RejectedRows
FROM dbo.vw_ETL_Crestline_FactSales_Profile;
GO

-- Expected:
-- TotalCrestlineTransactions = 18,000
-- ValidRows                  = 17,300
-- RejectedRows               = 700


-- G. Rejection reasons / quality counts
SELECT
    SUM(CASE WHEN IsNullQuantity = 1 THEN 1 ELSE 0 END)
        AS NullQuantityRows,

    SUM(CASE WHEN IsNegativeQuantity = 1 THEN 1 ELSE 0 END)
        AS NegativeQuantityRows,

    SUM(CASE WHEN IsNullPrice = 1 THEN 1 ELSE 0 END)
        AS NullPriceRows,

    SUM(CASE WHEN IsInvalidPrice = 1 THEN 1 ELSE 0 END)
        AS InvalidPriceRows,

    SUM(CASE WHEN IsNegativePrice = 1 THEN 1 ELSE 0 END)
        AS NegativePriceRows,

    SUM(CASE WHEN IsInvalidDate = 1 THEN 1 ELSE 0 END)
        AS InvalidDateRows,

    SUM(CASE WHEN IsUnknownProduct = 1 THEN 1 ELSE 0 END)
        AS UnknownProductRows

FROM dbo.vw_ETL_Crestline_FactSales_Profile;
GO

-- Expected with supplied source data:
-- NullQuantityRows     = 120
-- NegativeQuantityRows = 104
-- NullPriceRows        = 107
-- InvalidPriceRows     = 91
-- NegativePriceRows    = 99
-- InvalidDateRows      = 94
-- UnknownProductRows   = 85


-- H. Inspect transformed customer records
SELECT TOP 20 *
FROM dbo.vw_ETL_DimCustomer_Source
ORDER BY SourceSystem, SourceCustomerID;
GO


-- I. Inspect valid Crestline sales
SELECT TOP 20 *
FROM dbo.vw_ETL_Crestline_FactSales_Valid
ORDER BY SourceTransactionID;
GO


-- J. Inspect rejected Crestline sales
SELECT TOP 20 *
FROM dbo.vw_ETL_Crestline_FactSales_Rejected
ORDER BY SourceTransactionID;
GO


PRINT 'Jallow Meridian ETL transformation views created successfully.';
PRINT 'Next step: load dimensions, rejected records, and FactSales into JallowMeridianDW.';
GO
