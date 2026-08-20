# Cross-Store Sales & Inventory Analytics — ABC Foodmart Database System

A full-stack **relational database design and analytics project**: designed a normalized PostgreSQL schema for a 5-location retail grocery chain, built a Python ETL pipeline to populate it, wrote 10 analytical SQL queries, and delivered an executive Metabase dashboard.

**Group project** — APAN 5310 (SQL), Columbia University. 

---

## Problem

ABC Foodmart, a 30-year-old neighborhood grocery chain in Queens, NY, was expanding from 2 to 5 stores (adding 3 Brooklyn locations) while still running on spreadsheets and paper binders. This made it impossible to get a centralized view of inventory, compare sales across stores, track customer loyalty, or calculate payroll without manual work. We were engaged to design and implement a centralized relational database to replace this infrastructure.

## Data Model

- **16 tables, fully normalized to 3NF**, organized into 4 modules: **Store & Staff**, **Supply Chain & Inventory**, **Sales & Customers**, and **Finance**
- Resolved a **circular foreign key** dependency (`Stores.manager_id` ↔ `Employees.store_id`) by creating `Stores` first without the FK, then adding the constraint via `ALTER TABLE` after `Employees` was populated
- **3 automated triggers**: decrement inventory after each sale, credit customer loyalty points after each transaction, and auto-update inventory timestamps
- A `store_profitability` view pre-aggregates revenue, expenses, and payroll per store
- ~6,300 records loaded across all 16 tables (5 stores, 50 employees, 200 customers, 1,000 transactions, 3,726 transaction line items, and more)

## ETL

A Python script (`populate_data.py`) using `faker` and `psycopg2` generates realistic synthetic data and loads it in strict foreign-key dependency order, with a fixed random seed for reproducibility and inventory checks before each transaction insert to prevent negative stock.

## Analytical Queries (my contribution)

10 SQL queries answering real business questions across Finance, Sales, Operations, and HR, using **CTEs, window functions (`RANK()`, `LAG()`, `SUM() OVER (PARTITION BY)`), joins, and aggregate/HAVING logic**:

| # | Query | Business Question |
|---|---|---|
| 1 | Total Revenue by Store | Which stores generate the most revenue? |
| 2 | Product Revenue Ranking | How do all products rank by revenue (window function)? |
| 3 | Low Inventory Alert | Which products need reordering, and where? |
| 4 | Labor Cost by Store & Month | How does payroll vary by store over time? |
| 5 | Top Customers by Loyalty & Spend | Who are the most valuable customers? |
| 6 | Daily Revenue Trend per Store | What daily sales patterns exist per store? |
| 7 | Vendor Delivery Reliability | Which vendors have the best completion rates? |
| 8 | Overtime by Employee | Who is consistently working overtime? |
| 9 | Category Revenue Share per Store | What % of each store's revenue comes from each category? |
| 10 | Month-over-Month Revenue Growth | Is revenue growing or declining, store by store? |

## Executive Dashboard

I built an interactive **Metabase** dashboard (connected live to PostgreSQL) with three tabs so non-technical stakeholders could self-serve insights:
- **Financial Overview** — revenue and labor cost by store
- **Sales & Products** — daily revenue trend, top products, transaction volume
- **Operations** — low-inventory alerts, top-20 customer rankings

*(Screenshots included in the [project report](./docs/Project_Report.pdf).)*

## Key Results

- Replaced a fragmented, error-prone spreadsheet/paper system with a single normalized source of truth across 5 stores
- Automated inventory decrements, loyalty point crediting, and payroll calculation — eliminating manual entry errors
- Enabled cross-store benchmarking (e.g., new Brooklyn stores vs. established Queens locations) that was previously impossible
- Flagged ~75 low-stock SKUs daily and surfaced the top 20 highest-value customers for targeted retention

## Repo Structure

```
retail-sales-inventory-analytics/
├── README.md
├── sql/
│   ├── schema.sql                # Full CREATE TABLE DDL, constraints, triggers, view
│   └── analytical_queries.sql    # 10 business-question SQL queries
├── etl/
│   └── populate_data.py          # Python data generation & loading script (faker + psycopg2)
└── docs/
    ├── Project_Report.pdf        # Full written report (schema, ETL, queries, dashboard)
    └── Presentation_Slides.pdf   # Client-facing presentation deck
```

## How to Run

1. Create a PostgreSQL database and run `sql/schema.sql` to build all tables, triggers, and the profitability view
2. Install dependencies: `pip install faker psycopg2-binary`
3. Update the `DB_CONFIG` dictionary at the top of `etl/populate_data.py` with your own database credentials (do **not** commit real credentials)
4. Run `python etl/populate_data.py` to populate the database with sample data
5. Run any query in `sql/analytical_queries.sql` against the populated database

## Tools

`PostgreSQL` · `SQL` (CTEs, window functions, triggers, views) · `Python` (`psycopg2`, `faker`) · `Metabase` · `Docker`

## Project Context

Built as a team project for **APAN 5310: SQL** at **Columbia University**, simulating a real consulting engagement for a client database migration.
