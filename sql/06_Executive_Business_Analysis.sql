/*
===============================================================================
JALLOW MERIDIAN RETAIL GROUP
SQL BUSINESS ANALYSIS 01 — EXECUTIVE PERFORMANCE
Portfolio Project: SQL Server + SSIS + Tableau
===============================================================================

PURPOSE
-------
Use the completed JallowMeridianDW warehouse to answer executive-level
business questions and demonstrate analytical SQL skills.

IMPORTANT BUSINESS RULE
-----------------------
FactSales contains all loaded Jallow Meridian sales lines, including records
whose OrderStatus is Completed, Returned, or Cancelled.

For ETL reconciliation, we keep all valid source records.

For EXECUTIVE REVENUE / PROFIT analysis in this script, we use:

    WHERE OrderStatus = 'Completed'

This prevents cancelled and returned Jallow Meridian lines from being treated
as recognized sales revenue. Crestline legacy transactions were assigned
OrderStatus = 'Completed' in the ETL transformation layer.

RUN THE SECTIONS IN ORDER.
===============================================================================
*/

USE JallowMeridianDW;
GO


/*=============================================================================
SECTION 1 — WAREHOUSE SALES RECONCILIATION
Question:
How many sales lines are stored in FactSales by source system?
=============================================================================*/

SELECT
    SourceSystem,
    COUNT(*) AS SalesLines
FROM dbo.FactSales
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

/*
EXPECTED:
Crestline           17,300
JallowMeridian      60,000

TOTAL                77,300
*/


/*=============================================================================
SECTION 2 — JALLOW MERIDIAN ORDER STATUS PROFILE
Question:
How many loaded sales lines are Completed, Returned, or Cancelled?
=============================================================================*/

SELECT
    OrderStatus,
    COUNT(*) AS SalesLines,
    SUM(SalesAmount) AS SalesAmount,
    SUM(CostAmount) AS CostAmount,
    SUM(ProfitAmount) AS ProfitAmount
FROM dbo.FactSales
WHERE SourceSystem = 'JallowMeridian'
GROUP BY OrderStatus
ORDER BY SalesLines DESC;
GO

/*
EXPECTED APPROXIMATE RESULTS:

Completed
    SalesLines      56,521
    SalesAmount     28,578,310.92
    CostAmount      19,588,128.50
    ProfitAmount     8,990,182.42

Returned
    SalesLines       2,019
    SalesAmount      1,021,002.67
    CostAmount         699,602.40
    ProfitAmount       321,400.27

Cancelled
    SalesLines       1,460
    SalesAmount        741,226.41
    CostAmount         508,194.10
    ProfitAmount       233,032.31
*/


/*=============================================================================
SECTION 3 — CONSOLIDATED EXECUTIVE KPIs
Question:
What is the consolidated performance of COMPLETED sales only?
=============================================================================*/

SELECT
    COUNT(*) AS CompletedSalesLines,
    SUM(SalesAmount) AS TotalRevenue,
    SUM(CostAmount) AS TotalCost,
    SUM(ProfitAmount) AS TotalProfit,

    CAST(
        100.0 * SUM(ProfitAmount)
        / NULLIF(SUM(SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct

FROM dbo.FactSales
WHERE OrderStatus = 'Completed';
GO

/*
EXPECTED:

CompletedSalesLines    73,821
TotalRevenue           35,064,845.17
TotalCost              25,589,979.65
TotalProfit             9,474,865.52
ProfitMarginPct                27.02
*/


/*=============================================================================
SECTION 4 — PERFORMANCE BY SOURCE SYSTEM
Question:
How does Jallow Meridian compare with acquired Crestline?
=============================================================================*/

SELECT
    SourceSystem,
    COUNT(*) AS CompletedSalesLines,
    SUM(SalesAmount) AS Revenue,
    SUM(CostAmount) AS Cost,
    SUM(ProfitAmount) AS Profit,

    CAST(
        100.0 * SUM(ProfitAmount)
        / NULLIF(SUM(SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct

FROM dbo.FactSales
WHERE OrderStatus = 'Completed'
GROUP BY SourceSystem
ORDER BY Revenue DESC;
GO

/*
EXPECTED:

JallowMeridian
    CompletedSalesLines    56,521
    Revenue                28,578,310.92
    Cost                   19,588,128.50
    Profit                  8,990,182.42
    ProfitMarginPct                31.46

Crestline
    CompletedSalesLines    17,300
    Revenue                 6,486,534.25
    Cost                    6,001,851.15
    Profit                    484,683.10
    ProfitMarginPct                 7.47

KEY BUSINESS OBSERVATION:
Crestline contributes meaningful sales volume and revenue, but its margin is
substantially lower than Jallow Meridian's.
*/


/*=============================================================================
SECTION 5 — CRESTLINE ACQUISITION CONTRIBUTION
Question:
What percentage of consolidated completed sales volume, revenue, and profit
comes from Crestline?
=============================================================================*/

WITH CompletedPerformance AS
(
    SELECT
        SourceSystem,
        COUNT(*) AS SalesLines,
        SUM(SalesAmount) AS Revenue,
        SUM(ProfitAmount) AS Profit
    FROM dbo.FactSales
    WHERE OrderStatus = 'Completed'
    GROUP BY SourceSystem
),
Totals AS
(
    SELECT
        SUM(SalesLines) AS TotalSalesLines,
        SUM(Revenue) AS TotalRevenue,
        SUM(Profit) AS TotalProfit
    FROM CompletedPerformance
)
SELECT
    CP.SourceSystem,
    CP.SalesLines,
    CP.Revenue,
    CP.Profit,

    CAST(
        100.0 * CP.SalesLines
        / NULLIF(T.TotalSalesLines, 0)
        AS DECIMAL(10,2)
    ) AS SalesLineSharePct,

    CAST(
        100.0 * CP.Revenue
        / NULLIF(T.TotalRevenue, 0)
        AS DECIMAL(10,2)
    ) AS RevenueSharePct,

    CAST(
        100.0 * CP.Profit
        / NULLIF(T.TotalProfit, 0)
        AS DECIMAL(10,2)
    ) AS ProfitSharePct

FROM CompletedPerformance AS CP
CROSS JOIN Totals AS T
ORDER BY CP.Revenue DESC;
GO

/*
EXPECTED CRESTLINE CONTRIBUTION:

SalesLineSharePct    23.44%
RevenueSharePct      18.50%
ProfitSharePct        5.12%

INTERPRETATION:
Crestline represents almost one-quarter of completed sales lines and about
18.5% of consolidated revenue, but only about 5.1% of consolidated profit.
This suggests a post-acquisition margin-improvement opportunity.
*/


/*=============================================================================
SECTION 6 — CRESTLINE DATA-QUALITY / ETL SUCCESS RATE
Question:
What percentage of Crestline legacy transactions passed warehouse quality
rules and what percentage were rejected?
=============================================================================*/

WITH CrestlineQuality AS
(
    SELECT
        (SELECT COUNT(*)
         FROM CrestlineLegacySalesDB.dbo.LegacyTransactions)
            AS OriginalTransactions,

        (SELECT COUNT(*)
         FROM dbo.FactSales
         WHERE SourceSystem = 'Crestline')
            AS LoadedTransactions,

        (SELECT COUNT(*)
         FROM dbo.ETLRejectedRecords
         WHERE SourceSystem = 'Crestline')
            AS RejectedTransactions
)
SELECT
    OriginalTransactions,
    LoadedTransactions,
    RejectedTransactions,

    CAST(
        100.0 * LoadedTransactions
        / NULLIF(OriginalTransactions, 0)
        AS DECIMAL(10,2)
    ) AS LoadSuccessRatePct,

    CAST(
        100.0 * RejectedTransactions
        / NULLIF(OriginalTransactions, 0)
        AS DECIMAL(10,2)
    ) AS RejectionRatePct

FROM CrestlineQuality;
GO

/*
EXPECTED:

OriginalTransactions    18,000
LoadedTransactions      17,300
RejectedTransactions       700
LoadSuccessRatePct         96.11
RejectionRatePct            3.89
*/


/*=============================================================================
SECTION 7 — POTENTIAL CROSS-SYSTEM CUSTOMER MATCHES
Question:
How much customer overlap was identified during the acquisition integration?
=============================================================================*/

SELECT
    SourceSystem,
    COUNT(*) AS TotalCustomers,

    SUM(
        CASE
            WHEN PotentialCrossSystemMatch = 1 THEN 1
            ELSE 0
        END
    ) AS PotentialMatches,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN PotentialCrossSystemMatch = 1 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS PotentialMatchRatePct

FROM dbo.DimCustomer
WHERE CustomerKey <> 0
GROUP BY SourceSystem
ORDER BY SourceSystem;
GO

/*
EXPECTED:

Crestline
    TotalCustomers            1,800
    PotentialMatches            487
    PotentialMatchRatePct      27.06

JallowMeridian
    TotalCustomers            4,000
    PotentialMatches            487
    PotentialMatchRatePct      12.18

NOTE:
These are POTENTIAL matches based primarily on standardized email overlap.
They should not automatically be interpreted as confirmed duplicate customers.
*/


/*=============================================================================
SECTION 8 — FINAL EXECUTIVE SUMMARY QUERY
This produces a compact KPI row that can later be replicated in Tableau.
=============================================================================*/

SELECT
    COUNT(*) AS CompletedSalesLines,

    COUNT(DISTINCT CustomerKey) AS CustomersWithCompletedSales,

    SUM(SalesAmount) AS Revenue,
    SUM(ProfitAmount) AS Profit,

    CAST(
        100.0 * SUM(ProfitAmount)
        / NULLIF(SUM(SalesAmount), 0)
        AS DECIMAL(10,2)
    ) AS ProfitMarginPct,

    SUM(
        CASE
            WHEN SourceSystem = 'Crestline'
            THEN SalesAmount
            ELSE 0
        END
    ) AS CrestlineRevenue

FROM dbo.FactSales
WHERE OrderStatus = 'Completed';
GO


PRINT '===============================================================';
PRINT 'SQL Business Analysis 01 completed.';
PRINT 'Next analysis: product, category, store, channel, customer, and time trends.';
PRINT '===============================================================';
GO
