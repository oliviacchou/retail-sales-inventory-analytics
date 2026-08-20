-- =============================================================
-- ABC Foodmart -- Analytical SQL Queries
-- APAN 5310 - Group 2
-- 10 queries covering Finance, Sales, Operations, and HR
-- =============================================================


-- =============================================================
-- QUERY 1: Total Revenue by Store
-- Business question: Which stores are generating the most revenue?
-- Module: Finance
-- =============================================================

SELECT store_name,
       borough,
       total_revenue
FROM   store_profitability
ORDER  BY total_revenue DESC;


-- =============================================================
-- QUERY 2: Product Revenue Ranking (Window Function)
-- Business question: How do all products rank by revenue?
-- Uses RANK() so analysts can filter by any threshold, not fixed N.
-- Module: Sales
-- =============================================================

SELECT product_name,
       category,
       revenue,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM (
    SELECT p.product_name,
           p.category,
           SUM(ti.quantity * ti.unit_price * (1 - ti.discount / 100)) AS revenue
    FROM   Transaction_Items ti
    JOIN   Products p     ON p.product_id = ti.product_id
    JOIN   Transactions t ON t.txn_id     = ti.txn_id
    WHERE  t.txn_date >= '2025-01-01'
    GROUP  BY p.product_name, p.category
) ranked_products
ORDER  BY revenue_rank;


-- =============================================================
-- QUERY 3: Low Inventory Alert
-- Business question: Which products need to be reordered at each store?
-- Sorted by urgency (units below threshold descending).
-- Module: Operations
-- =============================================================

SELECT s.store_name,
       p.product_name,
       p.category,
       i.quantity,
       i.reorder_level,
       (i.reorder_level - i.quantity) AS units_below_threshold
FROM   Inventory i
JOIN   Stores s   ON s.store_id   = i.store_id
JOIN   Products p ON p.product_id = i.product_id
WHERE  i.quantity <= i.reorder_level
ORDER  BY s.store_name, units_below_threshold DESC;


-- =============================================================
-- QUERY 4: Labor Cost by Store and Month
-- Business question: How does payroll vary by store and period?
-- Helps identify stores with disproportionately high labor spend.
-- Module: Finance
-- =============================================================

SELECT s.store_name,
       s.borough,
       pr.pay_period,
       SUM(pr.base_pay + pr.overtime) AS total_labor_cost,
       SUM(pr.overtime)               AS total_overtime_pay
FROM   Payroll pr
JOIN   Employees e ON e.emp_id   = pr.emp_id
JOIN   Stores s    ON s.store_id = e.store_id
GROUP  BY s.store_name, s.borough, pr.pay_period
ORDER  BY pr.pay_period, total_labor_cost DESC;


-- =============================================================
-- QUERY 5: Top Customers by Loyalty and Spend
-- Business question: Who are our most valuable customers?
-- Combines total spend, transaction frequency, and loyalty points.
-- Module: Customer
-- =============================================================

SELECT c.first_name || ' ' || c.last_name        AS customer_name,
       c.loyalty_points,
       COUNT(t.txn_id)                            AS total_transactions,
       SUM(t.total_amount)                        AS total_spend,
       ROUND(AVG(t.total_amount)::numeric, 2)     AS avg_basket_size
FROM   Customers c
JOIN   Transactions t ON t.customer_id = c.customer_id
GROUP  BY c.customer_id, c.first_name, c.last_name, c.loyalty_points
ORDER  BY total_spend DESC
LIMIT  20;


-- =============================================================
-- QUERY 6: Daily Revenue Trend per Store
-- Business question: Are there patterns in daily revenue?
-- Helps inform staffing and inventory planning decisions.
-- Module: Sales
-- =============================================================

SELECT s.store_name,
       DATE(t.txn_date)    AS sale_date,
       COUNT(t.txn_id)     AS num_transactions,
       SUM(t.total_amount) AS daily_revenue
FROM   Transactions t
JOIN   Stores s ON s.store_id = t.store_id
GROUP  BY s.store_name, DATE(t.txn_date)
ORDER  BY sale_date, s.store_name;


-- =============================================================
-- QUERY 7: Vendor Delivery Reliability
-- Business question: Which vendors are most reliable?
-- Computes delivery completion rate per vendor.
-- Module: Operations
-- =============================================================

SELECT v.company_name,
       COUNT(*)                                                        AS total_deliveries,
       SUM(CASE WHEN d.status = 'delivered' THEN 1 ELSE 0 END)        AS completed_deliveries,
       ROUND(
           100.0 * SUM(CASE WHEN d.status = 'delivered' THEN 1 ELSE 0 END)
           / COUNT(*), 1
       )                                                               AS completion_rate_pct
FROM   Deliveries d
JOIN   Vendors v ON v.vendor_id = d.vendor_id
GROUP  BY v.company_name
ORDER  BY completion_rate_pct DESC;


-- =============================================================
-- QUERY 8: Overtime by Employee
-- Business question: Which employees are consistently working overtime?
-- HAVING clause filters to only employees with significant overtime.
-- Module: HR
-- =============================================================

SELECT e.first_name || ' ' || e.last_name AS employee_name,
       e.role,
       s.store_name,
       SUM(pr.overtime_hours)             AS total_overtime_hours,
       SUM(pr.overtime)                   AS total_overtime_pay
FROM   Payroll pr
JOIN   Employees e ON e.emp_id   = pr.emp_id
JOIN   Stores s    ON s.store_id = e.store_id
GROUP  BY e.emp_id, e.first_name, e.last_name, e.role, s.store_name
HAVING SUM(pr.overtime_hours) > 10
ORDER  BY total_overtime_hours DESC;


-- =============================================================
-- QUERY 9: Category Revenue Share per Store (Window Function)
-- Business question: What proportion of revenue comes from each category?
-- Uses SUM() OVER (PARTITION BY) to compute percentage within each store.
-- Module: Finance
-- =============================================================

SELECT s.store_name,
       p.category,
       ROUND(
           SUM(ti.quantity * ti.unit_price * (1 - ti.discount / 100))::numeric, 2
       )                                                                AS category_revenue,
       ROUND(
           100.0 * SUM(ti.quantity * ti.unit_price * (1 - ti.discount / 100))
           / SUM(SUM(ti.quantity * ti.unit_price * (1 - ti.discount / 100)))
             OVER (PARTITION BY s.store_name), 2
       )                                                                AS pct_of_store_revenue
FROM   Transaction_Items ti
JOIN   Transactions t ON t.txn_id     = ti.txn_id
JOIN   Stores s       ON s.store_id   = t.store_id
JOIN   Products p     ON p.product_id = ti.product_id
GROUP  BY s.store_name, p.category
ORDER  BY s.store_name, category_revenue DESC;


-- =============================================================
-- QUERY 10: Month-over-Month Revenue Growth (Window Function)
-- Business question: Is revenue growing or declining month over month?
-- Uses LAG() to compare each month against the prior month per store.
-- Module: Finance
-- =============================================================

WITH monthly AS (
    SELECT s.store_name,
           DATE_TRUNC('month', t.txn_date) AS month,
           SUM(t.total_amount)             AS monthly_revenue
    FROM   Transactions t
    JOIN   Stores s ON s.store_id = t.store_id
    GROUP  BY s.store_name, DATE_TRUNC('month', t.txn_date)
)
SELECT store_name,
       month,
       monthly_revenue,
       LAG(monthly_revenue) OVER (
           PARTITION BY store_name ORDER BY month
       )                                                        AS prior_month_revenue,
       ROUND(
           100.0 * (
               monthly_revenue
               - LAG(monthly_revenue) OVER (PARTITION BY store_name ORDER BY month)
           )
           / NULLIF(
               LAG(monthly_revenue) OVER (PARTITION BY store_name ORDER BY month), 0
           ), 2
       )                                                        AS mom_growth_pct
FROM   monthly
ORDER  BY store_name, month;
