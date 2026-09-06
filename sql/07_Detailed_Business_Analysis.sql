/*
===============================================================================
JALLOW MERIDIAN RETAIL GROUP
SQL BUSINESS ANALYSIS 02 — DETAILED BUSINESS PERFORMANCE
Portfolio Project: SQL Server + SSIS + Tableau
===============================================================================

PURPOSE
-------
Use the completed JallowMeridianDW warehouse to analyze:

1. Product performance
2. Category and subcategory performance
3. Store performance
4. Sales-channel performance
5. Customer performance
6. Monthly and yearly trends
7. Top and bottom performers
8. Crestline acquisition opportunities

BUSINESS RULE
-------------
For revenue, profit, and margin analysis, this script uses:

    WHERE F.OrderStatus = 'Completed'

This keeps the analytical treatment consistent with Business Analysis 01.

RUN THE SECTIONS IN ORDER.
===============================================================================
*/

USE JallowMeridianDW;
GO

/*=============================================================================
SECTION 1 — CATEGORY PERFORMANCE
=============================================================================*/
SELECT
    P.Category,
    COUNT(*) AS SalesLines,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
WHERE F.OrderStatus = 'Completed'
GROUP BY P.Category
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 2 — SUBCATEGORY PERFORMANCE
=============================================================================*/
SELECT
    P.Category,
    P.SubCategory,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
WHERE F.OrderStatus = 'Completed'
GROUP BY P.Category, P.SubCategory
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 3 — TOP 10 PRODUCTS BY REVENUE
=============================================================================*/
SELECT TOP 10
    P.ProductName,
    P.Category,
    P.SubCategory,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
WHERE F.OrderStatus = 'Completed'
GROUP BY P.ProductName, P.Category, P.SubCategory
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 4 — TOP 10 PRODUCTS BY PROFIT
=============================================================================*/
SELECT TOP 10
    P.ProductName,
    P.Category,
    P.SubCategory,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
WHERE F.OrderStatus = 'Completed'
GROUP BY P.ProductName, P.Category, P.SubCategory
ORDER BY Profit DESC;
GO

/*=============================================================================
SECTION 5 — LOWEST-MARGIN PRODUCTS WITH MEANINGFUL REVENUE
=============================================================================*/
WITH ProductPerformance AS
(
    SELECT
        P.ProductName,
        P.Category,
        P.SubCategory,
        SUM(F.SalesAmount) AS Revenue,
        SUM(F.ProfitAmount) AS Profit,
        CAST(
            100.0 * SUM(F.ProfitAmount)
            / NULLIF(SUM(F.SalesAmount), 0)
            AS DECIMAL(10,2)
        ) AS ProfitMarginPct
    FROM dbo.FactSales AS F
    INNER JOIN dbo.DimProduct AS P
        ON F.ProductKey = P.ProductKey
    WHERE F.OrderStatus = 'Completed'
    GROUP BY P.ProductName, P.Category, P.SubCategory
)
SELECT TOP 10
    ProductName,
    Category,
    SubCategory,
    Revenue,
    Profit,
    ProfitMarginPct
FROM ProductPerformance
WHERE Revenue >= 100000
ORDER BY ProfitMarginPct ASC, Revenue DESC;
GO

/*=============================================================================
SECTION 6 — STORE PERFORMANCE
=============================================================================*/
SELECT
    S.SourceSystem,
    S.StoreName,
    S.City,
    S.State,
    S.Region,
    COUNT(*) AS SalesLines,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimStore AS S
    ON F.StoreKey = S.StoreKey
WHERE F.OrderStatus = 'Completed'
GROUP BY
    S.SourceSystem,
    S.StoreName,
    S.City,
    S.State,
    S.Region
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 7 — SALES CHANNEL PERFORMANCE
=============================================================================*/
SELECT
    F.SourceSystem,
    F.SalesChannel,
    COUNT(*) AS SalesLines,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
WHERE F.OrderStatus = 'Completed'
GROUP BY F.SourceSystem, F.SalesChannel
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 8 — CUSTOMER SEGMENT PERFORMANCE
=============================================================================*/
SELECT
    COALESCE(C.CustomerSegment, 'Unclassified') AS CustomerSegment,
    COUNT(DISTINCT F.CustomerKey) AS Customers,
    COUNT(*) AS SalesLines,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimCustomer AS C
    ON F.CustomerKey = C.CustomerKey
WHERE F.OrderStatus = 'Completed'
GROUP BY COALESCE(C.CustomerSegment, 'Unclassified')
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 9 — TOP 10 CUSTOMERS BY REVENUE
=============================================================================*/
SELECT TOP 10
    C.SourceSystem,
    C.SourceCustomerID,
    C.FirstName,
    C.LastName,
    C.CustomerSegment,
    COUNT(*) AS SalesLines,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit
FROM dbo.FactSales AS F
INNER JOIN dbo.DimCustomer AS C
    ON F.CustomerKey = C.CustomerKey
WHERE F.OrderStatus = 'Completed'
GROUP BY
    C.SourceSystem,
    C.SourceCustomerID,
    C.FirstName,
    C.LastName,
    C.CustomerSegment
ORDER BY Revenue DESC;
GO

/*=============================================================================
SECTION 10 — YEARLY PERFORMANCE TREND
=============================================================================*/
SELECT
    D.CalendarYear,
    COUNT(*) AS SalesLines,
    SUM(F.Quantity) AS UnitsSold,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimDate AS D
    ON F.DateKey = D.DateKey
WHERE F.OrderStatus = 'Completed'
GROUP BY D.CalendarYear
ORDER BY D.CalendarYear;
GO

/*=============================================================================
SECTION 11 — MONTHLY PERFORMANCE TREND
=============================================================================*/
SELECT
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName,
    D.YearMonth,
    COUNT(*) AS SalesLines,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimDate AS D
    ON F.DateKey = D.DateKey
WHERE F.OrderStatus = 'Completed'
GROUP BY
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName,
    D.YearMonth
ORDER BY
    D.CalendarYear,
    D.MonthNumber;
GO

/*=============================================================================
SECTION 12 — MONTH-OVER-MONTH REVENUE GROWTH
Demonstrates CTEs and the LAG window function.
=============================================================================*/
WITH MonthlyRevenue AS
(
    SELECT
        D.YearMonth,
        MIN(D.FullDate) AS MonthStart,
        SUM(F.SalesAmount) AS Revenue
    FROM dbo.FactSales AS F
    INNER JOIN dbo.DimDate AS D
        ON F.DateKey = D.DateKey
    WHERE F.OrderStatus = 'Completed'
    GROUP BY D.YearMonth
),
RevenueWithPreviousMonth AS
(
    SELECT
        YearMonth,
        MonthStart,
        Revenue,
        LAG(Revenue) OVER (ORDER BY MonthStart) AS PreviousMonthRevenue
    FROM MonthlyRevenue
)
SELECT
    YearMonth,
    Revenue,
    PreviousMonthRevenue,
    CAST(
        100.0 * (Revenue - PreviousMonthRevenue)
        / NULLIF(PreviousMonthRevenue, 0)
        AS DECIMAL(10,2)
    ) AS MonthOverMonthGrowthPct
FROM RevenueWithPreviousMonth
ORDER BY MonthStart;
GO

/*=============================================================================
SECTION 13 — JALLOW MERIDIAN VS CRESTLINE BY CATEGORY
=============================================================================*/
SELECT
    P.Category,
    F.SourceSystem,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit,
    CAST(
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct
FROM dbo.FactSales AS F
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
WHERE F.OrderStatus = 'Completed'
GROUP BY P.Category, F.SourceSystem
ORDER BY P.Category, Revenue DESC;
GO

/*=============================================================================
SECTION 14 — CRESTLINE MARGIN GAP BY CATEGORY
Demonstrates conditional aggregation.
=============================================================================*/
WITH CategorySourcePerformance AS
(
    SELECT
        P.Category,
        F.SourceSystem,
        SUM(F.SalesAmount) AS Revenue,
        SUM(F.ProfitAmount) AS Profit,
        100.0 * SUM(F.ProfitAmount)
        / NULLIF(SUM(F.SalesAmount), 0) AS MarginPct
    FROM dbo.FactSales AS F
    INNER JOIN dbo.DimProduct AS P
        ON F.ProductKey = P.ProductKey
    WHERE F.OrderStatus = 'Completed'
    GROUP BY P.Category, F.SourceSystem
)
SELECT
    Category,
    CAST(
        MAX(CASE WHEN SourceSystem = 'JallowMeridian'
                 THEN MarginPct END)
        AS DECIMAL(10,2)
    ) AS JallowMeridianMarginPct,
    CAST(
        MAX(CASE WHEN SourceSystem = 'Crestline'
                 THEN MarginPct END)
        AS DECIMAL(10,2)
    ) AS CrestlineMarginPct,
    CAST(
        MAX(CASE WHEN SourceSystem = 'JallowMeridian'
                 THEN MarginPct END)
        -
        MAX(CASE WHEN SourceSystem = 'Crestline'
                 THEN MarginPct END)
        AS DECIMAL(10,2)
    ) AS MarginGapPctPoints,
    CAST(
        MAX(CASE WHEN SourceSystem = 'Crestline'
                 THEN Revenue END)
        AS DECIMAL(18,2)
    ) AS CrestlineRevenue
FROM CategorySourcePerformance
GROUP BY Category
ORDER BY MarginGapPctPoints DESC;
GO

/*=============================================================================
SECTION 15 — CUSTOMER OVERLAP VALUE
=============================================================================*/
SELECT
    C.SourceSystem,
    C.PotentialCrossSystemMatch,
    COUNT(DISTINCT C.CustomerKey) AS Customers,
    SUM(F.SalesAmount) AS Revenue,
    SUM(F.ProfitAmount) AS Profit
FROM dbo.FactSales AS F
INNER JOIN dbo.DimCustomer AS C
    ON F.CustomerKey = C.CustomerKey
WHERE F.OrderStatus = 'Completed'
GROUP BY
    C.SourceSystem,
    C.PotentialCrossSystemMatch
ORDER BY
    C.SourceSystem,
    C.PotentialCrossSystemMatch DESC;
GO

/*=============================================================================
SECTION 16 — TABLEAU-READY EXECUTIVE DATASET
One row remains one completed FactSales sales line.
=============================================================================*/
SELECT
    F.SalesKey,
    F.SourceSystem,
    F.SourceTransactionID,

    D.FullDate,
    D.CalendarYear,
    D.CalendarQuarter,
    D.MonthNumber,
    D.MonthName,
    D.YearMonth,

    C.SourceCustomerID,
    C.FirstName,
    C.LastName,
    C.State AS CustomerState,
    COALESCE(C.CustomerSegment, 'Unclassified') AS CustomerSegment,
    C.PotentialCrossSystemMatch,

    P.ProductName,
    P.Category,
    P.SubCategory,

    S.StoreName,
    S.City AS StoreCity,
    S.State AS StoreState,
    S.Region,

    F.OrderStatus,
    F.SalesChannel,
    F.Quantity,
    F.UnitPrice,
    F.DiscountPct,
    F.DiscountAmount,
    F.SalesAmount,
    F.CostAmount,
    F.ProfitAmount,

    CAST(
        CASE
            WHEN F.SalesAmount <> 0
            THEN 100.0 * F.ProfitAmount / F.SalesAmount
            ELSE NULL
        END
        AS DECIMAL(10,2)
    ) AS LineProfitMarginPct

FROM dbo.FactSales AS F
INNER JOIN dbo.DimDate AS D
    ON F.DateKey = D.DateKey
INNER JOIN dbo.DimCustomer AS C
    ON F.CustomerKey = C.CustomerKey
INNER JOIN dbo.DimProduct AS P
    ON F.ProductKey = P.ProductKey
INNER JOIN dbo.DimStore AS S
    ON F.StoreKey = S.StoreKey
WHERE F.OrderStatus = 'Completed';
GO

PRINT '================================================================';
PRINT 'SQL Business Analysis 02 completed.';
PRINT 'SQL business-analysis phase is now complete.';
PRINT 'Next phase: Tableau executive dashboard.';
PRINT '================================================================';
GO
