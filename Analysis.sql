use walmart_db;
SELECT * FROM walmart;

--  Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

--  Identify the highest-rated category in each branch , Display the branch, category, and avg rating
 SELECT *
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS Ranking
    FROM walmart
    GROUP BY branch, category
) AS ranked
WHERE Ranking = 1;

-- Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS Ranking
    FROM walmart
    GROUP BY branch, day_name
) AS ranked
WHERE Ranking = 1;

-- Calculate the total quantity of items sold per payment method
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating)  AS avg_rating
FROM walmart
GROUP BY city, category;

-- Calculate the total profit for each category
SELECT 
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- Determine the most common payment method for each branch
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS Ranking
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE Ranking = 1;

-- Categorize sales into Morning, Afternoon, and Evening shifts
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

-- Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;

-- Which city has the highest average basket size (avg revenue per transaction)?

SELECT city, ROUND(SUM(total) / COUNT(*), 2) AS avg_basket_size FROM
walmart GROUP BY city ORDER BY avg_basket_size DESC;

-- Which product categories drive the most profit per branch?
SELECT branch, category, ROUND(SUM(unit_price * quantity *
profit_margin),2) AS total_profit FROM walmart GROUP BY branch, category
ORDER BY branch, total_profit DESC;

-- Who are the top 5% of high-value customers?

WITH ranked_transactions AS (
    SELECT 
        invoice_id,
        total,
        NTILE(20) OVER (ORDER BY total DESC) AS percentile_rank
    FROM walmart
)
SELECT *
FROM ranked_transactions
WHERE percentile_rank = 1
ORDER BY total DESC;

-- Which payment method generates the highest average revenue per transaction?

SELECT payment_method, ROUND(SUM(total)/COUNT(*),2) AS
avg_transaction_value FROM walmart GROUP BY payment_method ORDER BY
avg_transaction_value DESC;

-- Which branch is growing the fastest year-over-year?

WITH revenue_per_year AS ( SELECT branch, YEAR(STR_TO_DATE(date,
'%d/%m/%Y')) AS yr, SUM(total) AS revenue FROM walmart GROUP BY branch,
yr ) SELECT branch, SUM(CASE WHEN yr=2022 THEN revenue ELSE 0 END) AS
revenue_2022, SUM(CASE WHEN yr=2023 THEN revenue ELSE 0 END) AS
revenue_2023, ROUND(((SUM(CASE WHEN yr=2023 THEN revenue ELSE 0 END) -
SUM(CASE WHEN yr=2022 THEN revenue ELSE 0 END)) / SUM(CASE WHEN yr=2022
THEN revenue ELSE 0 END))*100,2) AS growth_rate FROM revenue_per_year
GROUP BY branch ORDER BY growth_rate DESC;

-- Which hour of the day generates the highest average rating?

SELECT HOUR(TIME(time)) AS sales_hour, ROUND(AVG(rating),2) AS avg_rating
FROM walmart GROUP BY sales_hour ORDER BY avg_rating DESC;

-- Which categories have the most repeat purchases?

SELECT 
    category,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_quantity
FROM walmart
GROUP BY category
ORDER BY total_transactions DESC;

-- Which branches are most efficient (Revenue per Transaction)?

SELECT branch, ROUND(SUM(total)/COUNT(*),2) AS revenue_per_transaction
FROM walmart GROUP BY branch ORDER BY revenue_per_transaction DESC;

-- What’s the correlation between product category ratings and revenue?

SELECT category, ROUND(AVG(rating),2) AS avg_rating, SUM(total) AS
total_revenue FROM walmart GROUP BY category ORDER BY avg_rating DESC;

-- Which day of the week drives maximum average revenue per customer?

SELECT 
    DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
    ROUND(SUM(total)/COUNT(*),2) AS avg_transaction_value
FROM walmart
GROUP BY day_name
ORDER BY avg_transaction_value DESC;

