-- ============================================================
--   GROCERY STORE MANAGEMENT - SQL PROJECT
--   Covers: Schema Creation → Data Import → Analysis Queries
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE & SCHEMA SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS grocery_store;
USE grocery_store;

-- 1. Supplier Table
CREATE TABLE IF NOT EXISTS supplier (
    sup_id   TINYINT AUTO_INCREMENT PRIMARY KEY,
    sup_name VARCHAR(255),
    address  TEXT
);

-- 2. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    cat_id   TINYINT AUTO_INCREMENT PRIMARY KEY,
    cat_name VARCHAR(255)
);

-- 3. Employees Table
CREATE TABLE IF NOT EXISTS employees (
    emp_id    TINYINT AUTO_INCREMENT PRIMARY KEY,
    emp_name  VARCHAR(255),
    hire_date VARCHAR(255)
);

-- 4. Customers Table
CREATE TABLE IF NOT EXISTS customers (
    cust_id   SMALLINT AUTO_INCREMENT PRIMARY KEY,
    cust_name VARCHAR(255),
    address   TEXT
);

-- 5. Products Table
CREATE TABLE IF NOT EXISTS products (
    prod_id  TINYINT AUTO_INCREMENT PRIMARY KEY,
    prod_name VARCHAR(255),
    sup_id   TINYINT,
    cat_id   TINYINT,
    price    DECIMAL(10,2),
    FOREIGN KEY (sup_id) REFERENCES supplier(sup_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (cat_id) REFERENCES categories(cat_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 6. Orders Table
CREATE TABLE IF NOT EXISTS orders (
    ord_id     SMALLINT AUTO_INCREMENT PRIMARY KEY,
    cust_id    SMALLINT,
    emp_id     TINYINT,
    order_date VARCHAR(255),
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 7. Order Details Table
CREATE TABLE IF NOT EXISTS order_details (
    ord_detID   SMALLINT AUTO_INCREMENT PRIMARY KEY,
    ord_id      SMALLINT,
    prod_id     TINYINT,
    quantity    TINYINT,
    each_price  DECIMAL(10,2),
    total_price DECIMAL(10,2),
    FOREIGN KEY (ord_id) REFERENCES orders(ord_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (prod_id) REFERENCES products(prod_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- ============================================================
-- SECTION 2: DATA IMPORT INSTRUCTIONS
-- ============================================================
-- After creating the schema, import CSVs in this exact order
-- (parent tables before child tables to respect FK constraints):
--
--   1. supplier         ← from Suppliers.csv
--   2. categories       ← from Categories.csv
--   3. employees        ← from Store_Employees.csv
--   4. customers        ← from Customers.csv
--   5. products         ← from Products.csv
--   6. orders           ← from Orders.csv
--   7. order_details    ← from OrderDetails.csv
--
-- CSV column → Table column mapping:
--   Suppliers.csv     : SupplierID→sup_id, SupplierName→sup_name, Address→address
--   Categories.csv    : CategoryID→cat_id, CategoryName→cat_name
--   Store_Employees   : EmployeeID→emp_id, Name→emp_name, HireDate→hire_date
--   Customers.csv     : CustomerID→cust_id, Name→cust_name, Address→address
--   Products.csv      : ProductID→prod_id, Name→prod_name, SupplierID→sup_id,
--                       CategoryID→cat_id, Price→price
--   Orders.csv        : OrderID→ord_id, CustomerID→cust_id, EmployeeID→emp_id,
--                       OrderDate→order_date
--   OrderDetails.csv  : OrderDetailID→ord_detID, OrderID→ord_id,
--                       ProductID→prod_id, Quantity→quantity,
--                       PriceEach→each_price, TotalPrice→total_price
--
-- In MySQL Workbench: Table Data Import Wizard (right-click table → Import Wizard)
-- OR use LOAD DATA INFILE (adjust path as needed):
--
-- LOAD DATA INFILE '/path/to/Suppliers.csv'
-- INTO TABLE supplier
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (sup_id, sup_name, address);
-- ============================================================


-- ============================================================
-- SECTION 3: ANALYSIS QUERIES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 3.1  CUSTOMER INSIGHTS
-- ────────────────────────────────────────────────────────────

-- Q1. How many unique customers have placed orders?
SELECT COUNT(DISTINCT cust_id) AS unique_customers_with_orders
FROM orders;

-- Q2. Which customers have placed the highest number of orders?
SELECT
    c.cust_name,
    COUNT(o.ord_id) AS total_orders
FROM customers c
JOIN orders o ON c.cust_id = o.cust_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_orders DESC
LIMIT 10;

-- Q3. Total and average purchase value per customer
SELECT
    c.cust_name,
    ROUND(SUM(od.total_price), 2) AS total_purchase,
    ROUND(AVG(od.total_price), 2) AS avg_purchase_per_item
FROM customers c
JOIN orders o    ON c.cust_id = o.cust_id
JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_purchase DESC;

-- Q4. Top 5 customers by total purchase amount
SELECT
    c.cust_name,
    ROUND(SUM(od.total_price), 2) AS total_spent
FROM customers c
JOIN orders o         ON c.cust_id = o.cust_id
JOIN order_details od ON o.ord_id  = od.ord_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_spent DESC
LIMIT 5;


-- ────────────────────────────────────────────────────────────
-- 3.2  PRODUCT PERFORMANCE
-- ────────────────────────────────────────────────────────────

-- Q5. How many products exist in each category?
SELECT
    cat.cat_name,
    COUNT(p.prod_id) AS product_count
FROM categories cat
JOIN products p ON cat.cat_id = p.cat_id
GROUP BY cat.cat_id, cat.cat_name
ORDER BY product_count DESC;

-- Q6. Average price of products by category
SELECT
    cat.cat_name,
    ROUND(AVG(p.price), 2) AS avg_price
FROM categories cat
JOIN products p ON cat.cat_id = p.cat_id
GROUP BY cat.cat_id, cat.cat_name
ORDER BY avg_price DESC;

-- Q7. Products with the highest total sales volume (by quantity)
SELECT
    p.prod_name,
    SUM(od.quantity) AS total_quantity_sold
FROM products p
JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Q8. Total revenue generated by each product
SELECT
    p.prod_name,
    ROUND(SUM(od.total_price), 2) AS total_revenue
FROM products p
JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY total_revenue DESC;

-- Q9. Product sales by category and supplier
SELECT
    cat.cat_name,
    s.sup_name,
    ROUND(SUM(od.total_price), 2) AS revenue,
    SUM(od.quantity)              AS units_sold
FROM products p
JOIN categories    cat ON p.cat_id  = cat.cat_id
JOIN supplier        s ON p.sup_id  = s.sup_id
JOIN order_details  od ON p.prod_id = od.prod_id
GROUP BY cat.cat_id, cat.cat_name, s.sup_id, s.sup_name
ORDER BY revenue DESC;


-- ────────────────────────────────────────────────────────────
-- 3.3  SALES AND ORDER TRENDS
-- ────────────────────────────────────────────────────────────

-- Q10. Total number of orders placed
SELECT COUNT(*) AS total_orders
FROM orders;

-- Q11. Average value per order
SELECT
    ROUND(AVG(order_total), 2) AS avg_order_value
FROM (
    SELECT ord_id, SUM(total_price) AS order_total
    FROM order_details
    GROUP BY ord_id
) AS order_totals;

-- Q12. Dates with the most orders placed
SELECT
    order_date,
    COUNT(*) AS orders_on_date
FROM orders
GROUP BY order_date
ORDER BY orders_on_date DESC
LIMIT 10;

-- Q13. Monthly trends in order volume and revenue
--      (order_date stored as VARCHAR M/D/YYYY → use STR_TO_DATE)
SELECT
    DATE_FORMAT(STR_TO_DATE(o.order_date, '%m/%d/%Y'), '%Y-%m') AS year_month,
    COUNT(DISTINCT o.ord_id)                                      AS order_count,
    ROUND(SUM(od.total_price), 2)                                 AS monthly_revenue
FROM orders o
JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY year_month
ORDER BY year_month;

-- Q14. Order patterns across weekdays vs weekends
SELECT
    CASE
        WHEN DAYOFWEEK(STR_TO_DATE(order_date, '%m/%d/%Y')) IN (1, 7)
             THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS order_count
FROM orders
GROUP BY day_type;


-- ────────────────────────────────────────────────────────────
-- 3.4  SUPPLIER CONTRIBUTION
-- ────────────────────────────────────────────────────────────

-- Q15. How many suppliers are in the database?
SELECT COUNT(*) AS total_suppliers
FROM supplier;

-- Q16. Which supplier provides the most products?
SELECT
    s.sup_name,
    COUNT(p.prod_id) AS product_count
FROM supplier s
JOIN products p ON s.sup_id = p.sup_id
GROUP BY s.sup_id, s.sup_name
ORDER BY product_count DESC;

-- Q17. Average price of products from each supplier
SELECT
    s.sup_name,
    ROUND(AVG(p.price), 2) AS avg_product_price
FROM supplier s
JOIN products p ON s.sup_id = p.sup_id
GROUP BY s.sup_id, s.sup_name
ORDER BY avg_product_price DESC;

-- Q18. Suppliers contributing most to total product revenue
SELECT
    s.sup_name,
    ROUND(SUM(od.total_price), 2) AS total_revenue,
    SUM(od.quantity)              AS units_sold
FROM supplier s
JOIN products      p  ON s.sup_id  = p.sup_id
JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY s.sup_id, s.sup_name
ORDER BY total_revenue DESC;


-- ────────────────────────────────────────────────────────────
-- 3.5  EMPLOYEE PERFORMANCE
-- ────────────────────────────────────────────────────────────

-- Q19. How many employees have processed orders?
SELECT COUNT(DISTINCT emp_id) AS employees_with_orders
FROM orders;

-- Q20. Employees who handled the most orders
SELECT
    e.emp_name,
    COUNT(o.ord_id) AS orders_handled
FROM employees e
JOIN orders o ON e.emp_id = o.emp_id
GROUP BY e.emp_id, e.emp_name
ORDER BY orders_handled DESC;

-- Q21. Total sales value processed by each employee
SELECT
    e.emp_name,
    ROUND(SUM(od.total_price), 2) AS total_sales_processed
FROM employees e
JOIN orders        o  ON e.emp_id = o.emp_id
JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY e.emp_id, e.emp_name
ORDER BY total_sales_processed DESC;

-- Q22. Average order value handled per employee
SELECT
    e.emp_name,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM employees e
JOIN orders o ON e.emp_id = o.emp_id
JOIN (
    SELECT ord_id, SUM(total_price) AS order_value
    FROM order_details
    GROUP BY ord_id
) AS ov ON o.ord_id = ov.ord_id
GROUP BY e.emp_id, e.emp_name
ORDER BY avg_order_value DESC;


-- ────────────────────────────────────────────────────────────
-- 3.6  ORDER DETAILS DEEP DIVE
-- ────────────────────────────────────────────────────────────

-- Q23. Relationship between quantity ordered and total price (correlation view)
SELECT
    quantity,
    ROUND(AVG(total_price), 2) AS avg_total_price,
    COUNT(*)                   AS occurrences
FROM order_details
GROUP BY quantity
ORDER BY quantity;

-- Q24. Average quantity ordered per product
SELECT
    p.prod_name,
    ROUND(AVG(od.quantity), 2) AS avg_quantity_per_order
FROM products p
JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY avg_quantity_per_order DESC;

-- Q25. Unit price variation across products and orders
SELECT
    p.prod_name,
    ROUND(MIN(od.each_price), 2) AS min_unit_price,
    ROUND(MAX(od.each_price), 2) AS max_unit_price,
    ROUND(AVG(od.each_price), 2) AS avg_unit_price,
    ROUND(STDDEV(od.each_price), 2) AS price_stddev
FROM products p
JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY price_stddev DESC;


-- ============================================================
-- END OF PROJECT
-- ============================================================
