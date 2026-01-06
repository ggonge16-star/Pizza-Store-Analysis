
CREATE DATABASE pizza_store;
USE pizza_store;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
);

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Pizza Types
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(200) PRIMARY KEY,
    name VARCHAR(255),
    category VARCHAR(100),
    ingredients TEXT
);
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Pizzas
CREATE TABLE pizzas (
    pizza_id VARCHAR(200) PRIMARY KEY,
    pizza_type_id VARCHAR(200),
    size VARCHAR(50),
    price DECIMAL(10,2),
    FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id)
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Order Details
CREATE TABLE order_details (
    order_details_id INT PRIMARY KEY,
    order_id INT,
    pizza_id VARCHAR(200),
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)
);


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select  * from order_details;
select  * from pizzas;
select  * from pizza_types;
select  * from orders;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE orders;
TRUNCATE TABLE order_details;
SET FOREIGN_KEY_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 1;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


## orders
USE pizza_store;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv' 
INTO TABLE orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'  -- Changed from '\n' to '\r\n'
IGNORE 1 ROWS 
(order_id, order_date, order_time);

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## order_details
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_details.csv'
INTO TABLE order_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(order_details_id, order_id, pizza_id, quantity);

------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------


SHOW VARIABLES LIKE 'secure_file_priv';

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT pizza_id FROM order_details;

SELECT pizza_id FROM pizzas;

SELECT DISTINCT od.pizza_id
FROM order_details od
LEFT JOIN pizzas p
ON od.pizza_id = p.pizza_id
WHERE p.pizza_id IS NULL;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT pizza_id 
FROM order_details 
WHERE pizza_id NOT IN (SELECT pizza_id FROM pizzas);

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use pizza_store;

## Assignments Tasks

-- Retrieve the total number of orders placed.

select count(*) as total_orders
from orders;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculate the total revenue generated from pizza sales.

select sum(od.quantity * p.price) as total_revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify the highest-priced pizza.

SELECT p.pizza_id, pt.name AS pizza_name,p.size,p.price
FROM pizzas p
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify the most common pizza size ordered.
SELECT 
    p.size,
    SUM(od.quantity) AS total_orders
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_orders DESC
LIMIT 1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

-- Find the total quantity of each pizza category ordered.

SELECT 
    pt.category,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Find the category-wise distribution of pizzas (count of pizza types per category)
SELECT 
    category,
    COUNT(pizza_type_id) AS pizza_type_count
FROM pizza_types
GROUP BY category
ORDER BY pizza_type_count DESC;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    order_date,
    SUM(od.quantity) AS total_pizzas
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY order_date;

SELECT 
    AVG(daily_total) AS avg_pizzas_per_day
FROM (
    SELECT 
        o.order_date,
        SUM(od.quantity) AS daily_total
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY o.order_date
) AS daily_orders;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Determine the top 3 most ordered pizza types based on revenue
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 3;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculate the percentage contribution of each pizza type to total revenue
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity * p.price) AS pizza_revenue,
    ROUND(
        (SUM(od.quantity * p.price) / 
         (SELECT SUM(od2.quantity * p2.price)
          FROM order_details od2
          JOIN pizzas p2 ON od2.pizza_id = p2.pizza_id)
        ) * 100, 2
    ) AS revenue_percentage
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue_percentage DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analyze the cumulative revenue generated over time.
SELECT 
    o.order_date,
    SUM(p.price * od.quantity) AS daily_revenue,
    SUM(SUM(p.price * od.quantity)) 
        OVER (ORDER BY o.order_date) AS cumulative_revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category
SELECT 
    category,
    pizza_name,
    total_revenue
FROM (
    SELECT 
        pt.category,
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS total_revenue,
        RANK() OVER (
            PARTITION BY pt.category 
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS revenue_rank
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
) ranked_pizzas
WHERE revenue_rank <= 3
ORDER BY category, total_revenue DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Find orders where multiple pizzas were ordered but all pizzas are from the same category.

SELECT 
    od.order_id,
    pt.category,
    SUM(od.quantity) AS total_pizzas
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY od.order_id, pt.category
HAVING 
    SUM(od.quantity) > 1
    AND COUNT(DISTINCT pt.category) = 1;
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Find the ingredient that contributes the most to revenue.

SELECT 
    ingredient,
    SUM(p.price * od.quantity) AS total_revenue
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
JOIN (
    SELECT 
        pizza_type_id,
        TRIM(
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(ingredients, ',', n.n),
                ',', -1
            )
        ) AS ingredient
    FROM pizza_types
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
        SELECT 7 UNION ALL SELECT 8
    ) n
    ON CHAR_LENGTH(ingredients) 
       - CHAR_LENGTH(REPLACE(ingredients, ',', '')) >= n.n - 1
) ing
ON pt.pizza_type_id = ing.pizza_type_id
GROUP BY ingredient
ORDER BY total_revenue DESC
LIMIT 1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select * from order_details;
select * from orders;
select * from pizza_types;
select * from pizzas;
