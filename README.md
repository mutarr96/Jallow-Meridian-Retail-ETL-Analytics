# Jallow Meridian Retail Group — Post-Acquisition ETL & Business Intelligence Project

> **Portfolio Case Study:** This project simulates the acquisition of **Crestline Electronics & Home** by **Jallow Meridian Retail Group (JMRG)**. The companies and data are fictional and were created for educational and portfolio purposes.

## Project Overview

I designed and implemented an **end-to-end ETL and business intelligence solution** to simulate the integration of multiple data systems following a retail acquisition.

The project demonstrates the complete analytics workflow from operational SQL Server databases through data transformation, SSIS-based ETL, dimensional data warehousing, SQL business analysis, and an interactive Tableau executive dashboard.

### End-to-End Analytics Workflow

```text
SQL Server Source Databases
        ↓
SQL Data Profiling & Transformation
        ↓
SSIS / Visual Studio ETL Pipeline
        ↓
Star-Schema Data Warehouse
        ↓
SQL Business Analysis
        ↓
Tableau Executive Dashboard
```

**Core technologies:** SQL Server • SSMS • SQL • SSIS • Visual Studio • Dimensional Modeling • Tableau

---

## Executive Dashboard

[![Jallow Meridian Executive Dashboard](images/dashboard.png)](https://public.tableau.com/app/profile/mutarr.jallow/viz/JallowMeridianExecutiveDashboard/JallowMeridianExecutiveDashboard)

### [View the Interactive Tableau Dashboard →](https://public.tableau.com/app/profile/mutarr.jallow/viz/JallowMeridianExecutiveDashboard/JallowMeridianExecutiveDashboard)

The executive dashboard provides interactive analysis of consolidated revenue, profitability, acquisition performance, products, stores, and business trends.

### Dashboard KPIs

| KPI | Result |
|---|---:|
| Completed-Sales Revenue | **$35.06M** |
| Profit | **$9.47M** |
| Profit Margin | **27.02%** |
| Completed Sales Lines | **73,821** |

### Interactive Filters

- Company
- Calendar Year
- Product Category

---

## Explore the Technical Work

- [View SQL Scripts](sql/)
- [View SSIS / Visual Studio Package](ssis/)
- [View Tableau Workbook](tableau/)
- [View Project Screenshots](images/)
- [View Interactive Tableau Dashboard](https://public.tableau.com/app/profile/mutarr.jallow/viz/JallowMeridianExecutiveDashboard/JallowMeridianExecutiveDashboard)

---

## Business Problem

Following the simulated acquisition of Crestline Electronics & Home, Jallow Meridian Retail Group needed to integrate data from multiple operational systems into a centralized analytical environment.

Management needed a consolidated view of:

- Revenue and profitability
- Acquisition performance
- Product and category performance
- Store performance
- Customer activity
- Cross-system customer overlap
- Legacy-data quality issues
- Post-acquisition margin improvement opportunities

The acquired legacy system contained several data-quality challenges, including:

- Inconsistent state formats
- Missing email addresses
- Invalid customer signup dates
- Invalid transaction dates
- Missing quantities
- Negative quantities
- Missing prices
- Nonnumeric prices
- Negative prices
- Unknown product references
- Different customer identifier formats across systems

The objective was therefore not simply to create a dashboard, but to build a reliable **ETL and analytical infrastructure** capable of transforming inconsistent operational data into decision-ready business information.

---

## Source Systems

The project integrates three SQL Server databases.

### JallowMeridianSalesDB

Primary transactional system containing:

- Customers
- Products
- Stores
- Orders
- OrderDetails

### JallowMeridianCRMDB

Customer relationship and loyalty system containing:

- CustomerProfile
- LoyaltyAccounts

### CrestlineLegacySalesDB

Legacy acquisition system containing:

- LegacyCustomers
- LegacyTransactions

---

## Solution Architecture

```text
JallowMeridianSalesDB ─────┐
                           │
JallowMeridianCRMDB ───────┼──> SQL Transformation Views
                           │             ↓
CrestlineLegacySalesDB ────┘        SSIS ETL
                                         ↓
                                JallowMeridianDW
                                         ↓
                     ┌───────────────────┼───────────────────┐
                     ↓                   ↓                   ↓
               Dimension Tables     FactSales      ETLRejectedRecords
                     │                   │                   │
                     └───────────────────┼───────────────────┘
                                         ↓
                                SQL Business Analysis
                                         ↓
                                  Tableau Dashboard
```

---

## Data Warehouse Design

I designed a **star-schema data warehouse** named `JallowMeridianDW`.

### Dimension Tables

- `DimCustomer`
- `DimProduct`
- `DimStore`
- `DimDate`

### Fact Table

- `FactSales`

### Audit / Exception Table

- `ETLRejectedRecords`

### Fact Table Grain

One row in `FactSales` represents one sold product line from either:

- a Jallow Meridian `OrderDetails` record, or
- a valid Crestline `LegacyTransactions` record.

Warehouse surrogate keys are used for customer, product, store, and date dimensions while source-system identifiers are retained for traceability.

---

## SQL Transformation Layer

SQL transformation views were developed between the operational source systems and the warehouse.

Transformation logic included:

- Email standardization
- State-code normalization
- Safe date conversion
- Price cleaning and numeric conversion
- CRM enrichment
- Cross-database joins
- Customer-match identification
- Product validation
- Transaction-quality profiling
- Valid/rejected transaction separation

### SQL Skills Demonstrated

- `INNER JOIN`
- `LEFT JOIN`
- `UNION ALL`
- `CASE`
- `COALESCE`
- `TRY_CONVERT`
- `REPLACE`
- `LOWER`
- `LTRIM`
- `RTRIM`
- `EXISTS`
- Cross-database querying
- Common Table Expressions (CTEs)
- Conditional aggregation
- Window functions
- `LAG()`
- Data-quality validation
- Reconciliation queries
- Dimensional warehouse loading

---

## SSIS ETL Pipeline

The warehouse load was orchestrated using **SQL Server Integration Services (SSIS)** in Visual Studio.

### SSIS Load Sequence

```text
01 - Reset Warehouse
        ↓
02 - Load DimCustomer
        ↓
03 - Load DimProduct
        ↓
04 - Load DimStore
        ↓
05 - Load Rejected Records
        ↓
06 - Load Jallow Meridian Sales
        ↓
07 - Load Crestline Sales
```

The SSIS package uses OLE DB sources and destinations to move transformed data from SQL Server views into the warehouse.

### Control Flow

![SSIS Control Flow](images/ssis_control_flow.png)

### Data Flow

![SSIS Data Flow](images/ssis_data_flow.png)

### Successful Package Execution

![SSIS Successful Execution](images/ssis_success.png)

---

## ETL Validation Results

### Transformation / Source Views

| Validation Check | Rows |
|---|---:|
| Customer Source View | 5,800 |
| Product Source View | 120 |
| Store Source View | 24 |
| Jallow Meridian Sales Source | 60,000 |
| Crestline Valid Transactions | 17,300 |
| Crestline Rejected Transactions | 700 |

### Final Data Warehouse

| Warehouse Object | Rows |
|---|---:|
| DimCustomer | 5,801 |
| DimProduct | 121 |
| DimStore | 25 |
| DimDate | 2,558 |
| ETLRejectedRecords | 700 |
| FactSales | **77,300** |

### FactSales by Source System

| Source System | Rows |
|---|---:|
| Jallow Meridian | 60,000 |
| Crestline | 17,300 |
| **Total** | **77,300** |

Validation confirmed that all loaded fact records successfully resolved to valid customer, product, store, and date dimension keys.

---

## Legacy Data Quality Management

Crestline's legacy system contained **18,000 transactions**.

The ETL process classified the records as follows:

| Result | Transactions | Rate |
|---|---:|---:|
| Successfully Loaded | **17,300** | **96.11%** |
| Rejected for Data Quality | **700** | **3.89%** |
| Total | **18,000** | **100%** |

Rejected-record conditions included:

- NULL quantities
- Negative quantities
- NULL prices
- Nonnumeric prices
- Negative prices
- Invalid transaction dates
- Unknown product references

Rather than silently discarding invalid records, the ETL workflow preserved them in `ETLRejectedRecords` for auditability and investigation.

---

## SQL Business Analysis

After loading the warehouse, I developed SQL analyses to evaluate consolidated and post-acquisition business performance.

### Executive Analysis

The executive SQL analysis covered:

- Revenue
- Cost
- Profit
- Profit margin
- Completed transaction volume
- Jallow Meridian vs. Crestline performance
- Acquisition contribution
- ETL success rate
- Customer overlap

### Detailed Analysis

The detailed SQL analysis covered:

- Category performance
- Subcategory performance
- Top products
- Low-margin products
- Store performance
- Sales-channel performance
- Customer-segment performance
- Top customers
- Annual trends
- Monthly trends
- Month-over-month performance
- Company/category comparisons
- Crestline profitability gaps
- Customer overlap

CTEs and the `LAG()` window function were used for month-over-month analysis.

---

## Tableau Business Intelligence Dashboard

The final Tableau dashboard translates the warehouse data into an interactive executive view.

### Visualizations

- Monthly Revenue & Profit Trend
- Jallow Meridian vs. Crestline
- Revenue & Margin by Category
- Top 5 Products by Revenue
- Top 5 Stores by Revenue

### Executive KPIs

- **Revenue:** $35.06M
- **Profit:** $9.47M
- **Profit Margin:** 27.02%
- **Completed Sales Lines:** 73,821

### Interactive Dashboard

### [Open Dashboard on Tableau Public →](https://public.tableau.com/app/profile/mutarr.jallow/viz/JallowMeridianExecutiveDashboard/JallowMeridianExecutiveDashboard)

---

## Key Business Insights

### 1. Strong Consolidated Performance

Completed sales generated approximately **$35.06M in revenue** and **$9.47M in profit**, producing an overall **27.02% profit margin**.

### 2. Crestline Added Revenue but Limited Profit

Crestline generated approximately **$6.49M in revenue**, compared with approximately **$28.58M for Jallow Meridian**.

However, Crestline contributed only approximately **$0.48M in profit**, compared with approximately **$8.99M for Jallow Meridian**.

### 3. Significant Post-Acquisition Margin Gap

Jallow Meridian achieved an estimated **31.46% profit margin**, while Crestline achieved approximately **7.47%**.

This nearly 24-percentage-point difference indicates a significant post-acquisition profitability-improvement opportunity.

### 4. Wearables Was the Largest Revenue Category

Approximate category revenue:

| Category | Revenue |
|---|---:|
| Wearables | **$8.09M** |
| Home Office | **$7.33M** |
| Audio | **$6.74M** |
| Accessories | **$6.58M** |
| Computers | **$6.33M** |

### 5. Legacy Data Integration Was Highly Successful

The ETL pipeline successfully loaded **17,300 of 18,000 Crestline transactions**, representing a **96.11% successful-load rate**.

### 6. Customer Integration Opportunity

The analysis identified **487 potential cross-system customer matches** using standardized email addresses.

These records were flagged rather than automatically merged to reduce the risk of incorrect customer consolidation.

---

## Business Recommendations

### Improve Crestline Profitability

Investigate Crestline's:

- Pricing strategy
- Product mix
- Procurement costs
- Discounting practices
- Cost structure

The significant margin difference represents the largest identified post-acquisition improvement opportunity.

### Benchmark Jallow Meridian Best Practices

Evaluate whether Jallow Meridian's stronger pricing, sourcing, merchandising, and operating practices can be transferred to the acquired business.

### Protect High-Revenue Categories

Prioritize inventory availability, merchandising, and performance monitoring for high-revenue categories, particularly **Wearables** and **Home Office**.

### Maintain Formal Data-Quality Controls

Continue validating:

- Transaction dates
- Quantities
- Prices
- Product references
- Customer identifiers

Invalid records should continue to be captured through an auditable exception-management process.

### Develop a Customer Master Strategy

Potential duplicate customers should be validated using multiple attributes before records are merged into a unified customer master.

---

## How to Reproduce the Project

Run the SQL components in the following order:

1. Create the three source databases and populate the simulated source data.
2. Create the `JallowMeridianDW` star schema.
3. Create the SQL ETL transformation views.
4. Create the SSIS load-ready views.
5. Open `JallowMeridianWarehouseLoad.dtsx` in Visual Studio.
6. Run the SSIS package to populate the warehouse.
7. Execute the executive SQL business analysis.
8. Execute the detailed SQL business analysis.
9. Connect Tableau to `JallowMeridianDW` to reproduce the dashboard analysis.

The repository also includes a staged SQL load and validation script that was used during ETL development and testing.

---

## Skills Demonstrated

This project demonstrates practical experience with:

- SQL Server
- SQL
- ETL development
- SSIS
- Visual Studio
- Data profiling
- Data cleaning
- Data transformation
- Data validation
- Data warehousing
- Star-schema dimensional modeling
- Data-quality management
- Business intelligence
- Business analysis
- Tableau dashboard development
- KPI development
- Acquisition performance analysis

---

## Project Summary for Recruiters

Built an end-to-end **SQL Server → SSIS → Data Warehouse → Tableau** analytics pipeline for a simulated retail acquisition. Integrated three operational databases into a star-schema warehouse containing **77,300 fact records**, implemented automated legacy-data validation and rejected-record handling, developed advanced SQL business analyses using joins, CTEs, conditional aggregation, and window functions, and created an interactive Tableau executive dashboard analyzing more than **$35M in completed-sales revenue**.

---

## Disclaimer

This project is a **simulated portfolio case study**. Jallow Meridian Retail Group and Crestline Electronics & Home are fictional companies, and the dataset was created for educational and portfolio purposes.
