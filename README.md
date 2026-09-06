# Jallow Meridian Retail Group — Post-Acquisition ETL & Business Intelligence Project

> **Portfolio Case Study:** This project uses a simulated retail acquisition scenario in which **Jallow Meridian Retail Group (JMRG)** acquires **Crestline Electronics & Home**. The companies and data are fictional and were created for portfolio and learning purposes.

## Project Overview

Jallow Meridian Retail Group needed to integrate multiple operational systems following the acquisition of Crestline Electronics & Home. The objective was to create a centralized analytical environment that combined current Jallow Meridian sales and CRM data with Crestline's legacy customer and transaction data.

I built an end-to-end analytics solution using **SQL Server, SSIS, dimensional data modeling, SQL business analysis, and Tableau**.

The project covers:

- Source database creation and profiling
- Legacy-data quality assessment
- SQL transformation views
- Star-schema data warehouse design
- SSIS ETL orchestration
- Rejected-record handling and validation
- Executive SQL analysis
- Tableau dashboard development
- Post-acquisition business recommendations

## Business Problem

After the acquisition, management needed a consolidated view of revenue, profitability, product and category performance, store performance, customer overlap, legacy data-quality issues, and post-acquisition margin improvement opportunities.

The legacy data included inconsistent states, missing emails, invalid dates, negative or missing quantities, currency symbols and nonnumeric prices, negative prices, unmatched product references, and inconsistent customer identifiers.

## Solution Architecture

```text
JallowMeridianSalesDB
JallowMeridianCRMDB
CrestlineLegacySalesDB
        |
        v
SQL Transformation Views
        |
        v
SSIS ETL Pipeline
        |
        v
JallowMeridianDW
        |
        +--> DimCustomer
        +--> DimProduct
        +--> DimStore
        +--> DimDate
        +--> FactSales
        +--> ETLRejectedRecords
        |
        v
SQL Business Analysis
        |
        v
Tableau Executive Dashboard
```

## Technology Stack

- Microsoft SQL Server / SSMS
- SQL
- SQL Server Integration Services (SSIS)
- Visual Studio
- Dimensional Data Modeling / Star Schema
- Tableau / Tableau Public

## Data Warehouse Design

### Dimensions
- `DimCustomer`
- `DimProduct`
- `DimStore`
- `DimDate`

### Fact
- `FactSales`

### Audit / Exception
- `ETLRejectedRecords`

**Fact grain:** one sold product line from either a Jallow Meridian `OrderDetails` record or a valid Crestline `LegacyTransactions` record.

## SSIS ETL Workflow

```text
01 - Reset Warehouse
        |
02 - Load DimCustomer
        |
03 - Load DimProduct
        |
04 - Load DimStore
        |
05 - Load Rejected Records
        |
06 - Load Jallow Meridian Sales
        |
07 - Load Crestline Sales
```

## SQL Skills Demonstrated

- `JOIN`
- `LEFT JOIN`
- `UNION ALL`
- `CASE`
- `COALESCE`
- `TRY_CONVERT`
- `REPLACE`
- `LOWER`
- `LTRIM / RTRIM`
- `EXISTS`
- Cross-database queries
- CTEs
- Conditional aggregation
- Window function `LAG()`
- Data validation and reconciliation
- Dimensional warehouse loading

## ETL Validation Results

| Check | Rows |
|---|---:|
| Customer source view | 5,800 |
| Product source view | 120 |
| Store source view | 24 |
| Jallow Meridian sales source | 60,000 |
| Crestline valid sales | 17,300 |
| Crestline rejected sales | 700 |

### Final Warehouse

| Warehouse Object | Rows |
|---|---:|
| DimCustomer | 5,801 |
| DimProduct | 121 |
| DimStore | 25 |
| DimDate | 2,558 |
| ETLRejectedRecords | 700 |
| FactSales | 77,300 |

### FactSales by Source

| Source | Rows |
|---|---:|
| Jallow Meridian | 60,000 |
| Crestline | 17,300 |
| **Total** | **77,300** |

All loaded fact rows resolved successfully to valid customer, product, store, and date dimension keys.

## Crestline Data Quality Results

Of **18,000** Crestline legacy transactions:

- **17,300** passed warehouse quality rules
- **700** were routed to the rejection process
- **96.11%** successfully loaded
- **3.89%** were rejected

Issues included NULL or negative quantities, NULL or nonnumeric prices, negative prices, invalid transaction dates, and unmatched products.

## Tableau Dashboard

### Executive KPIs
- **Total Revenue:** $35.06M
- **Total Profit:** $9.47M
- **Profit Margin:** 27.02%
- **Completed Sales Lines:** 73,821

### Visualizations
- Monthly Revenue & Profit Trend
- Jallow Meridian vs. Crestline
- Revenue & Margin by Category
- Top 5 Products by Revenue
- Top 5 Stores by Revenue

### Filters
- Company
- Calendar Year
- Category

**Tableau Public:** [Add your Tableau Public dashboard link here](YOUR_TABLEAU_PUBLIC_LINK)

## Key Business Insights

1. Consolidated completed sales generated approximately **$35.06M in revenue** and **$9.47M in profit**, producing a **27.02% margin**.
2. Crestline contributed approximately **$6.49M in revenue** but only **$0.48M in profit**.
3. Jallow Meridian achieved an estimated **31.46% margin** versus **7.47% for Crestline**, highlighting a major margin-improvement opportunity.
4. Wearables generated approximately **$8.09M**, the highest category revenue.
5. The ETL pipeline successfully loaded **96.11%** of Crestline legacy transactions.
6. **487 potential cross-system customer matches** were identified using standardized email addresses.

## Recommendations

- Prioritize a Crestline profitability-improvement program focused on pricing, procurement, discounting, and product mix.
- Benchmark Crestline against Jallow Meridian's stronger operating and merchandising practices.
- Protect inventory and merchandising investment in high-revenue categories such as Wearables and Home Office.
- Maintain automated ETL data-quality checks for invalid quantities, prices, dates, and product references.
- Build a formal customer-master strategy using multiple matching attributes before merging potential duplicates.
- Continue monitoring acquisition performance through the centralized warehouse and Tableau dashboard.

## Suggested Repository Structure

```text
Jallow-Meridian-Retail-ETL-Analytics/
|
|-- README.md
|-- sql/
|   |-- 01_Source_Databases.sql
|   |-- 02_DW_Star_Schema.sql
|   |-- 03_ETL_Transformation_Views.sql
|   |-- 04_Staged_Load_Validation.sql
|   |-- 05_SSIS_Load_Ready_Views.sql
|   |-- 06_Executive_Analysis.sql
|   `-- 07_Detailed_Business_Analysis.sql
|-- ssis/
|   `-- JallowMeridianWarehouseLoad.dtsx
|-- tableau/
|   `-- Jallow_Meridian_Dashboard.twb
|-- images/
|   |-- dashboard.png
|   |-- ssis_control_flow.png
|   |-- ssis_data_flow.png
|   `-- ssis_success.png
`-- documentation/
    `-- project_notes.md
```

## How to Reproduce

Run the SQL files in this order:

1. Source database setup
2. Data warehouse star-schema setup
3. ETL transformation views
4. Corrected staged load and validation
5. SSIS load-ready views
6. Executive SQL analysis
7. Detailed SQL business analysis

Then run the SSIS package in Visual Studio and connect Tableau to `JallowMeridianDW`.

## Resume Summary

Built an end-to-end SQL Server/SSIS/Tableau analytics pipeline for a simulated retail acquisition, integrating 3 source databases into a star-schema warehouse with 77K+ fact records, automated legacy-data quality checks and rejection handling, advanced SQL analysis, and an executive dashboard covering $35M+ in completed-sales revenue.

## Disclaimer

This project is a **simulated portfolio case study**. Jallow Meridian Retail Group and Crestline Electronics & Home are fictional companies, and the dataset was created for educational and portfolio purposes.
