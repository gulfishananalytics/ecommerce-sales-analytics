   /*
 ===============================================================================

         E-Commerce Sales Analytics System

 ===============================================================================
Company      : Lumora Living
Database     : LumoraLivingDB
Developer    : Gulfishan Zakir
Version      : 1.0
Description  : Database schema for an E-Commerce Sales Analytics project
Created On   : 25-Jul-2026
===============================================================================
*/

-- ==========================================
-- TABLE : CUSTOMERS
-- Purpose :Stores customer master data
-- ==========================================

CREATE TABLE Customers
(
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Gender VARCHAR(10) NOT NULL,
    Age INT,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50) NOT NULL,
    Customer_Type VARCHAR(20) NOT NULL,
    Join_Date DATE NOT NULL
);

-- ==========================================
-- TABLE : PRODUCTS
-- Purpose :Stores product master data
-- ==========================================

CREATE TABLE Products
(
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Sub_Category VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    Selling_Price DECIMAL(10,2) NOT NULL,
    Cost_Price DECIMAL(10,2) NOT NULL
);



-- =============================================================================
-- TABLE : ORDERS
-- Purpose : Stores all customer sales transactions
-- =============================================================================

CREATE TABLE Orders
(
    Order_ID VARCHAR(20) PRIMARY KEY,

    Order_Date DATE NOT NULL,

    Customer_ID INT NOT NULL,

    Product_ID INT NOT NULL,

    Quantity INT NOT NULL,

    Unit_Price NUMERIC(10,2) NOT NULL,

    Discount_Pct INT DEFAULT 0,

    Sales_Amount NUMERIC(10,2) NOT NULL,

    Cost_Amount NUMERIC(10,2) NOT NULL,

    Profit NUMERIC(10,2) NOT NULL,

    Payment_Mode VARCHAR(20) NOT NULL,

    Salesperson_ID VARCHAR(10) NOT NULL,

    CONSTRAINT FK_Customer
        FOREIGN KEY (Customer_ID)
        REFERENCES Customers(Customer_ID),

    CONSTRAINT FK_Product
        FOREIGN KEY (Product_ID)
        REFERENCES Products(Product_ID)
);



-- =============================================================================
-- TABLE : RETURNS
-- Purpose : Stores returned orders
-- =============================================================================
CREATE TABLE Returns
(
    Return_ID INT PRIMARY KEY,

    Order_ID VARCHAR(20) NOT NULL,

    Return_Date DATE NOT NULL,

    Return_Reason VARCHAR(100) NOT NULL,

    Refund_Amount NUMERIC(10,2) NOT NULL,

    CONSTRAINT FK_Order_Return
        FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID)
);



-- =============================================================================
-- TABLE : DELIVERY
-- Purpose : Stores delivery information for each order
-- =============================================================================

CREATE TABLE Delivery
(
    Delivery_ID INT PRIMARY KEY,

    Order_ID VARCHAR(20) NOT NULL,

    Courier_Partner VARCHAR(50) NOT NULL,

    Delivery_Days INT NOT NULL,

    Delivery_Status VARCHAR(30) NOT NULL,

    CONSTRAINT FK_Order_Delivery
        FOREIGN KEY (Order_ID)
        REFERENCES Orders(Order_ID)
);

===============================================================================================================================================
                                               --TABLES--
                                            ================

SELECT COUNT(*) FROM customers;

SELECT COUNT(*) FROM products;

SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM returns;

SELECT COUNT(*) FROM delivery;


===============================================================================================================================================

/*
===========================================================
ANALYSIS AREA 1 — OVERALL SALES PERFORMANCE ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q1 — CATEGORY-WISE REVENUE, ORDERS, UNITS & PROFIT
-----------------------------------------------------------
*/

SELECT p.Category,
        COUNT(*) Total_orders,
	   SUM(o.Quantity)AS Total_Unit_Sold,
       SUM(o.Sales_Amount)AS Revenue,
	   SUM(o.Profit)AS Total_Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Category
ORDER BY Revenue DESC


/*
===========================================================
INSIGHTS
===========================================================

1. Furniture generated approximately ₹100.58 crore in
   revenue, contributing 65.67% of total revenue, while
   Lighting contributed 34.33%.

2. Furniture also generated the larger share of total
   profit, making it the primary revenue and profit driver
   for the business.

3. Furniture recorded 32,542 orders compared with 17,458
   orders for Lighting, indicating substantially higher
   sales volume.

4. The business is more dependent on Furniture performance,
   while Lighting represents a significant secondary
   category with potential for further growth.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Continue investing in the Furniture category by
   identifying and scaling its highest-performing products
   and customer segments.

2. Explore opportunities to increase Lighting revenue and
   order volume through cross-selling, complementary
   products and targeted promotions.

3. Closely monitor Furniture performance because its large
   contribution means a slowdown in this category could
   significantly impact overall business performance.

4. Regularly compare category-level revenue, volume and
   profitability to support sustainable growth while
   protecting profit margins.

===========================================================
*/




/*
===========================================================
ANALYSIS AREA 2 — REVENUE TREND & GROWTH ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q2 — MONTHLY REVENUE & PROFIT
-----------------------------------------------------------
*/

SELECT    EXTRACT(MONTH FROM Order_Date)AS Month_Num,
          EXTRACT(YEAR FROM Order_Date)AS Year,
        TO_CHAR(Order_Date,'MONTH') AS Month,
		COUNT(Order_ID)AS Total_Order,
		SUM(Sales_Amount)AS Revenue,
		SUM(Profit)AS Profit
FROM Orders
GROUP BY EXTRACT(MONTH FROM Order_Date),
         EXTRACT(YEAR FROM Order_Date),
		 TO_CHAR(Order_Date,'MONTH')
ORDER BY YEAR ASC,Month_Num ASC

/*
-----------------------------------------------------------
Q3 — PREVIOUS MONTH REVENUE, DIFFERENCE, GROWTH & STATUS
-----------------------------------------------------------
*/

WITH Monthly_Revenue AS
(
    SELECT
        DATE_TRUNC('month', Order_Date)::DATE AS Month_Start,
        TO_CHAR(DATE_TRUNC('month', Order_Date), 'Month') AS Month,
        SUM(Sales_Amount) AS Monthly_Revenue
    FROM Orders
    GROUP BY DATE_TRUNC('month', Order_Date)
),

Previous_Revenue AS
(
    SELECT
        Month_Start,
        Month,
        Monthly_Revenue,
        LAG(Monthly_Revenue)
            OVER (ORDER BY Month_Start) AS Previous_Month_Revenue
    FROM Monthly_Revenue
)

SELECT
    Month_Start,
    Month,
    Monthly_Revenue,
    Previous_Month_Revenue,

    Monthly_Revenue - Previous_Month_Revenue AS Difference,

    ROUND(
        (
            (Monthly_Revenue - Previous_Month_Revenue) * 100.0
            / NULLIF(Previous_Month_Revenue, 0)
        ), 2
    ) AS Growth_Percent,

    CASE
        WHEN Previous_Month_Revenue IS NULL THEN 'First Month'
        WHEN Monthly_Revenue > Previous_Month_Revenue THEN 'Growth'
        ELSE 'Decline'
    END AS Status

FROM Previous_Revenue
ORDER BY Month_Start;

/*
-----------------------------------------------------------
Q4 — NEXT MONTH REVENUE, DIFFERENCE & STATUS
-----------------------------------------------------------
*/

WITH Monthly_Revenue AS
(
    SELECT
        DATE_TRUNC('month', Order_Date)::DATE AS Month_Start,
        TO_CHAR(DATE_TRUNC('month', Order_Date), 'Month') AS Month,
        SUM(Sales_Amount) AS Monthly_Revenue
    FROM Orders
    GROUP BY DATE_TRUNC('month', Order_Date)
),

Performance AS
(
    SELECT
        Month_Start,
        Month,
        Monthly_Revenue,

        LEAD(Monthly_Revenue)
            OVER (ORDER BY Month_Start) AS Next_Month_Revenue

    FROM Monthly_Revenue
)

SELECT
    Month_Start,
    Month,
    Monthly_Revenue,
    Next_Month_Revenue,

    Next_Month_Revenue - Monthly_Revenue AS Difference,

    CASE
        WHEN Next_Month_Revenue IS NULL THEN 'No Next Month'
        WHEN Next_Month_Revenue > Monthly_Revenue THEN 'Better'
        WHEN Next_Month_Revenue < Monthly_Revenue THEN 'Worse'
        ELSE 'No Change'
    END AS Status

FROM Performance
ORDER BY Month_Start;

/*
-----------------------------------------------------------
Q5 — RUNNING REVENUE (CUMULATIVE REVENUE ANALYSIS)
-----------------------------------------------------------
*/

WITH Monthly_Revenue AS
(
    SELECT
        DATE_TRUNC('month', Order_Date)::DATE AS Month_Start,
        TO_CHAR(DATE_TRUNC('month', Order_Date), 'Month') AS Month,
        SUM(Sales_Amount) AS Monthly_Revenue
    FROM Orders
    GROUP BY DATE_TRUNC('month', Order_Date)
)

SELECT
    Month_Start,
    Month,
    Monthly_Revenue,

    SUM(Monthly_Revenue)
        OVER (
            ORDER BY Month_Start
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS Running_Total

FROM Monthly_Revenue
ORDER BY Month_Start;

/*
-----------------------------------------------------------
Q6 — 3 MONTH MOVING AVERAGE
-----------------------------------------------------------
*/

WITH Monthly_Revenue AS
(
    SELECT
        DATE_TRUNC('month', Order_Date)::DATE AS Month_Start,
        TO_CHAR(DATE_TRUNC('month', Order_Date), 'Month') AS Month,
        SUM(Sales_Amount) AS Monthly_Revenue
    FROM Orders
    GROUP BY DATE_TRUNC('month', Order_Date)
)

SELECT
    Month_Start,
    Month,
    Monthly_Revenue,

    ROUND(
        AVG(Monthly_Revenue)
            OVER (
                ORDER BY Month_Start
                ROWS BETWEEN 2 PRECEDING
                AND CURRENT ROW
            ),
        2
    ) AS Three_Month_Moving_Avg

FROM Monthly_Revenue
ORDER BY Month_Start;


/*
-----------------------------------------------------------
Q7 — CATEGORY-WISE MONTHLY REVENUE TREND
-----------------------------------------------------------
*/

SELECT p.Category,
      EXTRACT(YEAR FROM o.Order_Date)AS Purchase_Year,
EXTRACT(MONTH FROM o.Order_Date)AS Month_Num,
TO_CHAR(o.Order_Date,'FMMONTH')AS Purchase_Month,
      SUM(o.Sales_Amount)AS Revenue
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Category,
       EXTRACT(YEAR FROM o.Order_Date),
       EXTRACT(MONTH FROM o.Order_Date),
       TO_CHAR(o.Order_Date,'FMMONTH')
ORDER BY Purchase_Year,
        Month_Num 
		

/*
===========================================================
INSIGHTS
===========================================================

1. Revenue performance showed noticeable monthly
   fluctuations, with 4 growth months and 7 decline months.
   The largest month-over-month decline occurred in February
   at 11.29%, while March recorded the strongest growth at
   9.88%.

2. Revenue weakened consistently from August through
   November, with November recording a 6.18% decline.
   The 3-month moving average also reached its lowest level
   in November at approximately ₹12.43 crore.

3. December showed a strong recovery, with revenue increasing
   by 8.60% compared with November and rising by approximately
   ₹1.02 crore.

4. Cumulative revenue reached approximately ₹153.16 crore
   by December, indicating continued revenue accumulation
   despite monthly fluctuations.

5. Furniture consistently generated higher monthly revenue
   than Lighting across both 2024 and 2025, making Furniture
   the dominant contributor to the overall revenue trend.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Investigate the recurring August-to-November slowdown by
   analysing seasonal demand, product mix, pricing, discounting
   and promotional activity.

2. Analyse the factors behind strong-growth months such as
   March, May and December and evaluate whether successful
   strategies can be replicated during weaker periods.

3. Continue supporting the strong-performing Furniture category
   while developing targeted strategies to increase Lighting
   revenue through cross-selling and complementary products.

4. Use the 3-month moving average as a monitoring KPI to
   identify sustained revenue slowdowns earlier and support
   more informed business decisions.

===========================================================
*/





/*
===========================================================
ANALYSIS AREA 3 — CUSTOMER PERFORMANCE ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q8 — TOP CUSTOMERS BY REVENUE
-----------------------------------------------------------
*/


SELECT c.Customer_ID,
       c.Customer_Name,
	   COUNT(Order_ID)AS Total_Orders,
	   SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
ORDER BY Revenue DESC
LIMIT 10


/*
-------------------------------------------
Q9 — TOP CUSTOMERS BY PROFIT 
-------------------------------------------
*/


SELECT c.Customer_ID,
       c.Customer_Name,
      SUM(o.Profit)AS Profit
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
ORDER BY Profit DESC
LIMIT 5



/*
-----------------------------------------------------------
Q10 — TOP CUSTOMERS HIGHEST AVERAGE ORDER VALUE
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	AVG(o.Sales_Amount)AS avg_Order_Value
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
ORDER BY avg_Order_Value DESC
LIMIT 5


/*
-----------------------------------------------------------
Q11 — TOP CUSTOMERS HIGHEST AVERAGE PROFIT PER ORDER 
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	AVG(o.Profit)AS avg_profit_per_order
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
ORDER BY avg_profit_per_order DESC
LIMIT 5



/*
-----------------------------------------------------------
Q12 — TOP 10 CUSTOMERS REVENUE COMPARE THEIR PROFIT
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	SUM(o.Sales_Amount)AS Revenue,
    SUM(o.Profit)AS Profit
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
ORDER BY Revenue DESC
LIMIT 10



/*
--------------------------------------------------------------------
Q13 — TOP CUSTOMERS HIGHEST REVENUE WITH THEIR LOW PROFIT ORDER
--------------------------------------------------------------------
*/


SELECT
    c.Customer_ID,
    c.Customer_Name,
	SUM(o.Sales_Amount)AS Revenue,
    SUM(o.Profit)AS Profit
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
HAVING SUM(o.Sales_Amount)>500000
ORDER BY Profit ASC
LIMIT 5


/*
---------------------------------------------------------------
Q14 — CUSTOMERS REVENUE HIGHER THAN AVERAGE CUSTOMER REVENUE
---------------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
    SUM(o.Sales_Amount) AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY
    c.Customer_ID,
    c.Customer_Name
HAVING  SUM(o.Sales_Amount)>
(
         SELECT AVG(Revenue)
		 FROM(
    SELECT Customer_ID,
	    SUM(Sales_Amount) AS Revenue
   FROM Orders
   GROUP BY Customer_ID
		 )Avg_Revenue
);  


/*
-----------------------------------------------
Q15 — CUSTOMERS REVENUE PERCENT RANK
-----------------------------------------------
*/

WITH Customer_Revenue AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
	   SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
),Revenue_Ranking AS
  (
  SELECT 
       Customer_ID,
	   Customer_Name,
	   Revenue,
	   Percent_Rank()
	   OVER(ORDER BY Revenue DESC)
	   AS Revenue_Percent_Rank
FROM Customer_Revenue 
)
 SELECT 
       Customer_ID,
	   Customer_Name,
	   Revenue,
	   Revenue_Percent_Rank
FROM Revenue_Ranking
WHERE Revenue_Percent_Rank<=0.10



/*
-----------------------------------------------------------
Q16 — CUSTOMERS CUME_DIST
-----------------------------------------------------------
*/

WITH Customer_Revenue AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
	   SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
)
  SELECT 
       Customer_ID,
	   Customer_Name,
	   Revenue,
	   CUME_DIST()
	   OVER(ORDER BY Revenue DESC)
	   AS Cumulative_Distribution
FROM Customer_Revenue


/*
-----------------------------------------------------------
Q17 — CUSTOMERS HIGHEST REVENUE CONTRIBUTION PERCENT
-----------------------------------------------------------
*/

WITH Total_Revenue AS
(
SELECT c.Customer_ID,
      c.Customer_Name,
      SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
        c.Customer_Name
),Cumulative AS
(
SELECT  Customer_ID,
      Customer_Name,
	  Revenue,
     SUM(Revenue)
	OVER()AS Company_Total_Revenue,
ROUND(
      (Revenue*100.0/
	   SUM(Revenue)
	   OVER() 
	   ),2
	)AS Contribution_Percent
FROM Total_Revenue
)
SELECT  Customer_ID,
        Customer_Name,
       Revenue,
	   Contribution_Percent,
	   SUM(Contribution_Percent)
	   OVER
	   (ORDER BY Revenue DESC
	   ROWS BETWEEN UNBOUNDED PRECEDING
	   AND CURRENT ROW
	   )AS Cumulative_Percent
FROM Cumulative
ORDER BY Revenue DESC


/*
===========================================================
INSIGHTS
===========================================================

1. A small group of customers generated exceptionally high
   revenue, with the top customers generating approximately
   ₹12.9–₹14.4 lakh each. Meera Sharma was the highest
   revenue customer approximately
   ₹14.38 lakh.

2. High revenue does not always correspond directly with
   the highest order frequency. For example, Meera Sharma
   generated higher revenue than Arjun Singh despite having
   fewer orders, showing that order count alone is not a
   sufficient measure of customer value.

3. Customer revenue contribution varies across customers,
   indicating that some customers have a substantially
   greater financial impact on overall business performance.

4. Customer rankings show that revenue performance can be
   compared systematically to identify the highest-value
   customers and prioritize them for further analysis.

5. The customer analysis demonstrates that revenue, order
   frequency and contribution should be evaluated together
   to obtain a more complete picture of customer value.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Prioritize high-value customers with targeted retention
   strategies such as personalized offers, loyalty benefits
   and premium customer experiences.

2. Do not evaluate customer importance using order frequency
   alone. Combine revenue, order count and contribution
   metrics when identifying valuable customers.

3. Develop customer segments based on revenue and purchasing
   behaviour so that marketing and retention strategies can
   be targeted more effectively.

4. Identify opportunities to increase the value of existing
   customers through cross-selling, upselling and
   complementary-product recommendations.

5. Regularly monitor customer rankings and contribution to
   identify changes in high-value customer behaviour and
   reduce dependency on a limited group of major customers.

===========================================================
*/






 /*
===========================================================
ANALYSIS AREA 4 — CUSTOMER PURCHASING BEHAVIOUR ANALYSIS
===========================================================
*/





/*
-----------------------------------------------------------
Q18 — CUSTOMERS PURCHASING FROM BOTH CATEGORIES
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	COUNT(DISTINCT p.Category)AS Category
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID	
JOIN Products p
ON p.Product_ID=o.Product_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
HAVING COUNT(DISTINCT p.Category)=2



/*
-----------------------------------------------------------
Q19 — HIGH-UNIT CUSTOMERS: ORDERS, REVENUE & PROFIT
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	COUNT(o.Order_ID)AS Total_order,
	SUM(o.Sales_Amount)AS Revenue,
    SUM(o.Profit)AS Profit,
	 SUM(o.Quantity)AS Total_Unit_Sold
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
HAVING  SUM(o.Quantity)>20
ORDER BY Total_Unit_Sold DESC






/*
-----------------------------------------------------------
Q20 — HIGH-ORDER CUSTOMERS: REVENUE, PROFIT & AOV
-----------------------------------------------------------
*/

WITH customer_order_report AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
	    SUM(o.Sales_Amount)AS Revenue,
		 SUM(o.Profit)AS Profit,
	   COUNT(o.Order_ID)AS Total_Orders,
	   DENSE_RANK()
	   OVER(ORDER BY COUNT(o.Order_ID) DESC
	   )AS Top_Orders
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID	  
GROUP BY c.Customer_ID,
       c.Customer_Name
)
SELECT Customer_ID,
       Customer_Name,
	   Revenue,
	   Profit,
	   Total_Orders,
	   Top_Orders,
	   ROUND(
   (Revenue*1.0/
   NULLIF(Total_Orders,0)),2
	   )AS Average_Order_Value
FROM customer_order_report 
WHERE Top_Orders<=10 


/*
-----------------------------------------------------------
Q21 — REPEAT CUSTOMER ANALYSIS
-----------------------------------------------------------
*/


WITH Customer_Type_Report AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
	    SUM(o.Sales_Amount)AS Revenue,
	   COUNT(o.Order_ID)AS Total_Orders,
	CASE
	     WHEN  COUNT(o.Order_ID)=1 
		      THEN 'One_Time_Customer'
		 ELSE
		    'Repeat_Customer'
		 END AS Customer_Type
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID	  
GROUP BY c.Customer_ID,
         c.Customer_Name
)
SELECT Customer_ID,
       Customer_Name,
	   Revenue,
	   Total_Orders,
	   Customer_Type
FROM  Customer_Type_Report
WHERE Customer_Type='Repeat_Customer'



/*
-----------------------------------------------------------
Q22 — CUSTOMERS PURCHASING ACROSS MULTIPLE MONTHS
-----------------------------------------------------------
*/

SELECT 
      c.Customer_ID,
      c.Customer_Name,
   COUNT(DISTINCT DATE_TRUNC('MONTH',o.Order_Date)
            )AS Purchase_Month
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
        c.Customer_Name
HAVING COUNT(DISTINCT DATE_TRUNC('MONTH',o.Order_Date))>1
ORDER BY Purchase_Month DESC



/*
===========================================================
INSIGHTS
===========================================================

1. Customers with higher purchase frequency represent an
   important revenue segment. The analysis of customers
   placing more than 10 orders shows that frequent purchasing
   can generate substantial revenue and profit.

2. High purchase frequency does not automatically mean high
   Average Order Value. Therefore, customer performance
   should be evaluated using both order frequency and AOV.

3. Customers purchasing products from both Furniture and
   Lighting demonstrate broader category engagement and
   represent potential cross-selling opportunities.

4. High-unit customers contribute meaningful order volume,
   revenue and profit, indicating that purchase quantity is
   another important dimension for understanding customer
   value.

5. Repeat customers form an important customer group. The
   repeat-customer analysis shows customers with multiple
   orders and substantial revenue, making retention an
   important part of customer strategy.

6. Customers purchasing across multiple months demonstrate
   stronger purchasing continuity than customers whose
   purchases are concentrated in a single month.

7. Overall, customer purchasing behaviour should be evaluated
   using multiple dimensions — order frequency, AOV, units
   purchased, product breadth, category breadth and purchase
   continuity.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Identify high-frequency customers and use personalized
   offers, loyalty benefits and targeted recommendations to
   encourage continued purchases.

2. Focus on increasing AOV among frequent customers through
   upselling, product bundles and complementary-product
   recommendations.

3. Use cross-selling strategies for customers purchasing
   from both Furniture and Lighting to increase their overall
   customer value.

4. Monitor high-unit customers separately and identify
   opportunities to increase their purchase value without
   negatively affecting profitability.

5. Prioritize repeat customers for retention campaigns because
   repeated purchasing indicates stronger engagement with the
   business.

6. Analyse customers with purchases across multiple months
   and use their purchasing patterns to design personalized
   re-engagement and repeat-purchase campaigns.

7. Build customer behaviour segments using frequency, AOV,
   product breadth, category breadth and purchase continuity
   instead of relying on a single customer KPI.

===========================================================
*/                                     
             




/*
===========================================================
ANALYSIS AREA 5 — CUSTOMER SEGMENTATION & ACQUISITION ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q23 — CUSTOMER SEGMENTATION
-----------------------------------------------------------
*/

SELECT c.Customer_ID,
    c.Customer_Name,
	SUM(o.Sales_Amount)AS Revenue,
	CASE  
         WHEN SUM(o.Sales_Amount)>=500000 THEN 'VIP'
		 WHEN SUM(o.Sales_Amount)>=200000 THEN 'Regular'
		 ELSE 'Low Value'
     END AS Customer_Type
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
    c.Customer_Name



/*
-----------------------------------------------------------
Q24 — CUSTOMER SEGMENTATION BY NTILE
-----------------------------------------------------------
*/


WITH Groups_Revenue AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
	   SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
),Performance AS
(
  SELECT 
       Customer_ID,
	   Customer_Name,
	   Revenue,
	   NTILE(4)
	   OVER(ORDER BY Revenue DESC)AS Performance_Group
FROM Groups_Revenue
)
SELECT  Customer_ID,
	    Customer_Name,
	     Revenue,
CASE 
     WHEN Performance_Group=1 THEN 'Gold'
     WHEN Performance_Group=2 THEN 'Silver'
     WHEN Performance_Group=3 THEN 'Bronze'
     ELSE 'Low_Performer'
   END AS Customer_Segment
FROM Performance


/*
-----------------------------------------------------------
Q25 — NEW CUSTOMERS BY MONTH
-----------------------------------------------------------
*/

 WITH New_Customers_Report AS
(
SELECT 
      c.Customer_ID,
      c.Customer_Name,
    MIN(o.Order_Date)AS First_Purchase_Date
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
        c.Customer_Name
)
SELECT  
EXTRACT(YEAR FROM First_Purchase_Date)AS Purchase_Year,
EXTRACT(MONTH FROM First_Purchase_Date)AS Month_Num,
TO_CHAR(First_Purchase_Date,'FMMONTH')AS Purchase_Month,
 COUNT(DISTINCT Customer_ID)AS New_Customer_Count
 FROM New_Customers_Report
 GROUP BY
		EXTRACT(YEAR FROM First_Purchase_Date),
        EXTRACT(MONTH FROM First_Purchase_Date),
        TO_CHAR(First_Purchase_Date,'FMMONTH')
 ORDER BY
        Purchase_Year,
		  Month_Num



/*
===========================================================
INSIGHTS
===========================================================

1. The analysis identifies different customer groups based
   on their purchasing behaviour and value.

2. Customer acquisition varies across months, allowing the
   business to identify periods with stronger or weaker
   customer acquisition.

3. Tracking the number of new customers by month helps
   evaluate the effectiveness of marketing and acquisition
   activities over time.

4. Customer segmentation allows the business to distinguish
   valuable customer groups and design more targeted
   strategies instead of treating all customers equally.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Focus acquisition campaigns on months that demonstrate
   stronger new-customer acquisition and investigate weaker
   periods.

2. Develop targeted marketing strategies for different
   customer segments based on their purchasing behaviour
   and value.

3. Track new-customer acquisition regularly to evaluate
   marketing performance and identify changes in customer
   acquisition trends.

4. Combine acquisition data with customer revenue and
   purchasing behaviour to identify which customer segments
   are most valuable to the business.

===========================================================
*/






/*
===========================================================
ANALYSIS AREA 6 — CUSTOMER ACTIVITY & RETENTION ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q26 — CUSTOMER RECENCY / DAYS SINCE LAST PURCHASE
-----------------------------------------------------------
*/

WITH Customers_Activity_Report AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
       MIN(o.Order_Date)AS First_Purchase_Date,
	   MAX(o.Order_Date)AS Last_Purchase_Date
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID	  
GROUP BY c.Customer_ID,
         c.Customer_Name
)	
SELECT
         Customer_ID,
         Customer_Name,
		 First_Purchase_Date,
		 Last_Purchase_Date,
		(CURRENT_DATE - Last_Purchase_Date)AS Days_Since_Last_Purchase
  FROM Customers_Activity_Report 
  ORDER BY Days_Since_Last_Purchase DESC



/*
-----------------------------------------------------------
Q27 — CUSTOMER TENURE
-----------------------------------------------------------
*/

WITH Customers_Purchase_Gap AS
(
SELECT c.Customer_ID,
       c.Customer_Name,
       MIN(o.Order_Date)AS First_Purchase_Date,
	   MAX(o.Order_Date)AS Last_Purchase_Date
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID	  
GROUP BY c.Customer_ID,
         c.Customer_Name
)	
 SELECT
         Customer_ID,
         Customer_Name,
		 First_Purchase_Date,
		 Last_Purchase_Date,
		( Last_Purchase_Date - First_Purchase_Date)AS Customer_Tenure_Days
  FROM  Customers_Purchase_Gap
  ORDER BY Customer_Tenure_Days DESC



/*
-----------------------------------------------------------
Q28 — CUSTOMER AVERAGE GAP BETWEEN ORDERS
-----------------------------------------------------------
*/

WITH Customer_Orders AS
(
SELECT
    c.Customer_ID,
    c.Customer_Name,
    o.Order_Date,

    LEAD(o.Order_Date)
    OVER
    (
        PARTITION BY c.Customer_ID
        ORDER BY o.Order_Date
    ) AS Next_Order_Date

FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
),

Customer_Avg_Gap AS
(
SELECT
    Customer_ID,
    Customer_Name,

    AVG(Next_Order_Date - Order_Date) AS Avg_Order_Gap_Days

FROM Customer_Orders

WHERE Next_Order_Date IS NOT NULL

GROUP BY
    Customer_ID,
    Customer_Name
)

SELECT *
FROM Customer_Avg_Gap
ORDER BY Avg_Order_Gap_Days DESC;



/*
-----------------------------------------------------------
Q29 — VALUABLE BUT RECENTLY INACTIVE CUSTOMERS
-----------------------------------------------------------
*/


WITH VIP_Customers_Report AS
(
SELECT 
      c.Customer_ID,
      c.Customer_Name,
	  SUM(o.Sales_Amount)AS Revenue,
	  COUNT(o.Order_ID)AS Total_Orders,
    MAX(o.Order_Date)AS Last_Purchase_Date,
	DATE '2025-12-31'- MAX(o.Order_Date)AS Customer_Inactivity
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
        c.Customer_Name
)
SELECT Customer_ID,
       Customer_Name,
	   Revenue,
	   Total_Orders,
	   Last_Purchase_Date,
	   Customer_Inactivity
FROM VIP_Customers_Report
WHERE Revenue>50000
AND  Customer_Inactivity>90
AND Total_Orders>=2
ORDER BY Revenue DESC



/*
===========================================================
INSIGHTS
===========================================================

1. Customer activity varies considerably, with some
   customers having a much longer gap since their most
   recent purchase.

2. Customer tenure helps identify how long customers have
   remained active between their first and last purchases,
   providing a view of customer relationship duration.

3. Average gaps between orders highlight differences in
   purchasing frequency and can help identify customers
   who may require re-engagement.

4. The analysis identifies valuable customers who have
   generated significant revenue but have also become
   inactive, creating a clear retention opportunity.

5. Combining recency, tenure, purchase gaps and customer
   value provides a stronger basis for identifying
   retention risks than using revenue alone.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Prioritize high-value customers with long inactivity
   periods for targeted win-back campaigns.

2. Use customers' average order gaps to determine suitable
   re-engagement timing instead of sending campaigns at
   the same frequency to every customer.

3. Monitor customer recency regularly to identify declining
   activity before valuable customers become fully inactive.

4. Use customer tenure and purchase frequency to design
   differentiated retention strategies for newer and
   longer-standing customers.

5. Build a customer-retention dashboard tracking recency,
   inactivity days, order gaps, revenue and order frequency
   to support timely intervention.

===========================================================
*/





/*
===========================================================
ANALYSIS AREA 7 — PRODUCT SALES & VOLUME ANALYSIS
===========================================================
*/





/*
-----------------------------------------------------------
Q30 — TOP PRODUCT SALES BY ORDER
-----------------------------------------------------------
*/



SELECT p.Product_ID,
       p.Product_Name,
     SUM(o.Quantity)AS Total_Quantity_Sold
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,p.Product_Name
ORDER BY Total_Quantity_Sold DESC
LIMIT 5	


/*
-----------------------------------------------------------
Q31 — BOTTOM PRODUCT SALES PERFORMANCE
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
     SUM(o.Sales_Amount)AS Revenue
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,p.Product_Name
ORDER BY Revenue ASC
LIMIT 5


/*
-----------------------------------------------------------
Q32 — TOP PRODUCT BY REVENUE AND PROFIT
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
	   SUM(o.Sales_Amount)AS Revenue,
       SUM(o.Profit)AS Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
ORDER BY Revenue DESC
LIMIT 10


/*
-----------------------------------------------------------
Q33 — TOP 3 PRODUCT BY REVENUE IN EACH CATEGORY
-----------------------------------------------------------
*/

WITH Top AS
(
SELECT p.Product_ID,
       p.Category,
       p.Product_Name,
        SUM(o.Sales_Amount)AS Revenue,
 RANK()
	OVER(PARTITION BY p.Category
	  ORDER BY SUM(o.Sales_Amount) DESC)AS Product_Rank
	  
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
          p.Category,
       p.Product_Name
)

SELECT Product_ID,
       Category,
       Product_Name,
	    Revenue,
	   Product_Rank
FROM Top
WHERE Product_Rank<=3
ORDER BY Category,Product_Rank 


/*
===========================================================
INSIGHTS
===========================================================

1. Product-level performance varies considerably, with a
   small group of products generating substantially higher
   revenue than other products.

2. High-revenue products are important contributors to
   overall sales and should be monitored closely for
   continued availability and demand.

3. Product sales volume provides a different perspective
   from revenue. Products selling higher quantities are not
   necessarily the same products generating the highest
   revenue.

4. Combining revenue and sales volume provides a more
   complete understanding of product performance than using
   revenue alone.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Prioritize high-revenue products for inventory planning,
   availability and promotional strategies.

2. Identify high-volume products separately and evaluate
   whether their pricing, margins and sales strategy can be
   improved.

3. Analyse the relationship between units sold and revenue
   to identify products that generate strong sales volume
   but comparatively lower revenue.

4. Regularly monitor product revenue and volume together to
   support product assortment, inventory and promotional
   decisions.

===========================================================
*/







/*
===========================================================
ANALYSIS AREA 8 — PRODUCT PROFITABILITY ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q34 — HIGH-REVENUE BUT LOW-PROFIT PRODUCTS
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
	   SUM(o.Sales_Amount)AS Revenue,
       SUM(o.Profit)AS Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
HAVING SUM(o.Profit)<50000
AND SUM(o.Sales_Amount)>200000



/*
-----------------------------------------------------------
Q35 — PRODUCTS GENERATING NEGATIVE PROFIT
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
       SUM(o.Profit)AS Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
HAVING SUM(o.Profit)<0



/*
-----------------------------------------------------------
Q36 — BOTTOM 10 PRODUCTS BY TOTAL PROFIT
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
       SUM(o.Profit)AS Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
ORDER BY Profit ASC
LIMIT 10




/*
-----------------------------------------------------------
Q37 — PRODUCTS WITH LOW AVERAGE PROFIT PER ORDER
-----------------------------------------------------------
*/


SELECT p.Product_ID,
       p.Product_Name,
       COUNT(o.Order_ID)AS Total_Order,
	  SUM(o.Sales_Amount) AS Revenue,
     AVG(o.Profit) AS Avg_Profit_Per_Order
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
HAVING AVG(o.Profit)<200		 
ORDER BY Avg_Profit_Per_order ASC




/*
-----------------------------------------------------------
Q38 — HIGH-VALUE BUT LOW-PROFIT MARGIN PRODUCTS
-----------------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
	  SUM(o.Sales_Amount) AS Revenue,
	   SUM(o.Profit)AS Profit,
   ROUND(
     SUM(o.Profit)*100.0/
	 SUM(Sales_Amount),2
	 )AS Profit_Margin
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Product_ID,
         p.Product_Name
HAVING SUM(o.Sales_Amount)>500000
ORDER BY Profit_Margin ASC
LIMIT 10


/*
===========================================================
INSIGHTS
===========================================================

1. Some products generate significant revenue but relatively
   low profit, indicating that strong sales volume does not
   always translate into strong profitability.

2. Products generating negative profit represent direct
   profitability concerns and require immediate investigation.

3. The bottom-performing products by total profit highlight
   products that contribute relatively weak financial returns
   compared with other products.

4. Low average profit per order indicates that certain
   products may have weak profitability at the individual
   transaction level.

5. High-value but low-margin products are particularly
   important because their large revenue contribution can
   create a misleading impression of strong performance.

6. Overall, product performance should therefore be evaluated
   using revenue together with total profit, profit per order
   and profit margin.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Review pricing, cost structure and discount levels for
   high-revenue but low-profit products to improve margins.

2. Investigate negative-profit products and determine whether
   they should be repriced, cost-optimized, promoted
   differently or discontinued.

3. Review the bottom-performing products regularly and
   evaluate whether they should remain part of the product
   portfolio.

4. Identify products with low profit per order and explore
   opportunities to improve their unit economics through
   pricing, sourcing or reduced costs.

5. Closely monitor high-revenue but low-margin products
   because even a small margin improvement on these products
   can have a meaningful impact on total profit.

6. Use revenue, total profit, average profit per order and
   profit margin together as core product profitability KPIs.

===========================================================
*/





 /*
=================================================================
ANALYSIS AREA 9 — CATEGORY PERFORMANCE & CONTRIBUTION ANALYSIS
=================================================================
*/


	


/*
-----------------------------------------------------------
Q39 — CATEGORY REVENUE & PROFIT CONTRIBUTION
-----------------------------------------------------------
*/

WITH Total_Revenue AS
(
SELECT p.Category,
      SUM(o.Sales_Amount)AS Revenue
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Category
),Cumulative AS
(
SELECT Category,
       Revenue,
     SUM(Revenue)
	OVER()AS Company_Total_Revenue,
ROUND(
      (Revenue*100.0/
	   SUM(Revenue)
	   OVER() ),2
	)AS Contribution_Percent
FROM Total_Revenue
)
SELECT Category,
       Revenue,
	   Contribution_Percent,
	   SUM(Contribution_Percent)
	   OVER(ORDER BY Revenue DESC
	   ROWS BETWEEN UNBOUNDED PRECEDING
	   AND CURRENT ROW)AS Cumulative_Percent
FROM Cumulative


/*
-----------------------------------------------------------
Q40 — CATEGORY-WISE MONTHLY REVENUE TREND
-----------------------------------------------------------
*/

SELECT p.Category,
      EXTRACT(YEAR FROM o.Order_Date)AS Purchase_Year,
EXTRACT(MONTH FROM o.Order_Date)AS Month_Num,
TO_CHAR(o.Order_Date,'FMMONTH')AS Purchase_Month,
      SUM(o.Sales_Amount)AS Revenue
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
GROUP BY p.Category,
       EXTRACT(YEAR FROM o.Order_Date),
       EXTRACT(MONTH FROM o.Order_Date),
       TO_CHAR(o.Order_Date,'FMMONTH')
ORDER BY Purchase_Year,
        Month_Num 



/*
===========================================================
INSIGHTS
===========================================================

1. Furniture is the dominant category, generating
   approximately ₹100.58 crore in revenue and contributing
   65.67% of total revenue.

2. Lighting generated approximately ₹52.58 crore in revenue,
   contributing 34.33% of total revenue.

3. Furniture also generated substantially higher profit,
   indicating that its stronger revenue contribution is
   supported by significant profitability.

4. Both categories show relatively consistent monthly
   revenue patterns across 2024 and 2025, with Furniture
   remaining ahead of Lighting throughout the period.

5. The category-wise monthly trend provides a clear view of
   how each category contributes to overall sales and helps
   identify stronger and weaker periods within each category.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Continue investing in the Furniture category because it
   is the primary revenue and profit driver of the business.

2. Identify opportunities to grow the Lighting category
   without compromising its profitability, reducing the
   business's dependence on Furniture.

3. Analyse the strongest and weakest months for each category
   and align inventory, promotions and marketing campaigns
   accordingly.

4. Use category-level revenue and profit contribution
   together when making product assortment and investment
   decisions.

5. Investigate successful strategies behind Furniture's
   stronger performance and evaluate whether relevant
   approaches can be applied to Lighting.

===========================================================
*/
									



                                             
/*
===========================================================
ANALYSIS AREA 10 — RETURNS & RETURN BEHAVIOUR ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q41 — TOP CUSTOMERS BY RETURN COUNT
-----------------------------------------------------------
*/

SELECT c.Customer_ID,
       c.Customer_Name,
	   COUNT(r.Return_ID)AS Total_Returns
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
JOIN Returns r
ON o.Order_ID=r.Order_ID
GROUP BY c.Customer_ID,
       c.Customer_Name
ORDER BY Total_Returns DESC
LIMIT 5



/*
-----------------------------------------------------------
Q42 — RETURN REASONS
-----------------------------------------------------------
*/

SELECT Return_Reason,
      COUNT(Return_ID)AS Total_Returns
FROM Returns 
GROUP BY  Return_Reason
ORDER BY Total_Returns DESC
LIMIT 5

/*
-----------------------------------------------------------
Q43 — TOP CUSTOMERS BY REVENUE FROM NON-RETURNED ORDERS
-----------------------------------------------------------
*/


SELECT c.Customer_ID,
       c.Customer_Name,
	   SUM(o.Sales_Amount)AS Revenue
FROM Customers c
LEFT JOIN Orders o
ON c.Customer_ID=o.Customer_ID
LEFT JOIN Returns r
ON o.Order_ID=r.Order_ID
WHERE r.Return_ID IS NULL
GROUP BY c.Customer_ID,
       c.Customer_Name
ORDER BY Revenue DESC
LIMIT 5



/*
------------------------------------------------------------------
Q44 — TOP CUSTOMERS WITH HIGH ORDER VOLUME WITH NO RETURN ORDER
------------------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
    COUNT(o.Order_ID) AS Total_Orders
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
WHERE c.Customer_ID NOT IN
(
    SELECT o.Customer_ID
    FROM Orders o
    JOIN Returns r
    ON o.Order_ID = r.Order_ID
)
GROUP BY
    c.Customer_ID,
    c.Customer_Name
ORDER BY Total_Orders DESC
LIMIT 5;



/*
--------------------------------------------------------------------
Q45 — TOP CUSTOMERS BY HIGHEST PROFIT BUT ALSO AT LEAST ONE RETURN 
---------------------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	COUNT(r.Return_ID)AS Total_Returns,
    SUM(o.Profit) AS Profit
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
JOIN Returns r
ON o.Order_ID = r.Order_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
ORDER BY Profit DESC
LIMIT 5 



/*
--------------------------------------------------
Q46 — TOP PRODUCTS WITH HIGHEST RETURN COUNT
--------------------------------------------------
*/

SELECT p.Product_ID,
       p.Product_Name,
     COUNT(r.Return_ID)AS Total_Returns,
	 SUM(o.Sales_Amount)AS Revenue,
	 SUM(o.Profit) AS Profit
FROM Products p
JOIN Orders o
ON p.Product_ID=o.Product_ID
JOIN Returns r
ON o.Order_ID = r.Order_ID
GROUP BY p.Product_ID,p.Product_Name
ORDER BY Total_Returns DESC
LIMIT 5


/*
===========================================================
INSIGHTS
===========================================================

1. The return analysis highlights the overall level of
   product returns and provides an important measure of
   post-purchase customer behaviour.

2. Return reasons are distributed across multiple factors,
   including Customer Changed Mind, Wrong Item, Damaged,
   Late Delivery and Size Issue. Each reason represents a
   different operational or customer-experience problem.

3. Category-level return analysis helps identify whether
   returns are concentrated in a particular product category.

4. Product-level return rates help identify individual
   products that may require closer investigation for
   quality, sizing, product information or fulfilment issues.

5. A small group of customers may account for a relatively
   high number or value of returns, making customer-level
   return behaviour important for identifying recurring
   issues.

6. Return analysis should therefore be evaluated together
   with return reason, category, product and customer
   behaviour rather than using overall return rate alone.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Prioritize the most frequent return reasons and identify
   the operational or product-level causes behind them.

2. Investigate products with unusually high return rates
   for potential quality, sizing, description or fulfilment
   issues.

3. Review categories with higher return rates and determine
   whether product mix, quality or customer expectations are
   contributing to the issue.

4. Monitor customers with consistently high return activity
   and analyse their return patterns before designing
   appropriate retention or service strategies.

5. Use return-reason data to improve product descriptions,
   quality control, packaging, sizing information and
   delivery processes.

6. Track return rate and return value as regular business
   KPIs so that improvements can be measured over time.

===========================================================
*/                                        





 /*
===========================================================
ANALYSIS AREA 11 — DELIVERY & COURIER PERFORMANCE ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q47 — DELIVERY STATUS & ORDER VOLUME
-----------------------------------------------------------
*/

SELECT Delivery_Status,
       COUNT(Order_ID)AS Total_Orders
FROM Delivery
GROUP BY Delivery_Status


/*
-----------------------------------------------------------
Q48 — TOP COURIER PARTNERS BY ORDER VOLUME
-----------------------------------------------------------
*/

SELECT Courier_Partner,
       COUNT(Order_ID)AS Total_Orders
FROM Delivery
GROUP BY Courier_Partner
ORDER BY Total_Orders DESC
LIMIT 5


/*
-----------------------------------------------------------
Q49 — COURIER PARTNERS HIGHEST AVERAGE DELIVERY TIME
-----------------------------------------------------------
*/

SELECT Courier_Partner,
       AVG(Delivery_Days)AS Avg_Delivery_Days
FROM Delivery
GROUP BY Courier_Partner
ORDER BY Avg_Delivery_Days DESC


/*
===========================================================
INSIGHTS
===========================================================

1. The delivery-status analysis provides visibility into
   the current distribution of orders across different
   delivery stages.

2. Courier partners handle different order volumes, allowing
   the business to identify which partners are responsible
   for the largest share of deliveries.

3. Average delivery time varies across courier partners,
   indicating differences in delivery efficiency.

4. A courier handling a high volume of orders should not be
   evaluated only on order capacity; its average delivery
   time should also be considered.

5. Combining delivery status, order volume and average
   delivery time provides a more complete view of courier
   performance.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Monitor delivery-status distribution regularly to identify
   orders that remain in non-completed stages for longer than
   expected.

2. Compare courier partners using both order volume and
   average delivery time before allocating additional order
   volume.

3. Investigate courier partners with relatively high average
   delivery times and identify opportunities to improve
   delivery efficiency.

4. Maintain strong-performing courier partnerships while
   reviewing underperforming partners through regular
   delivery-performance reviews.

5. Use courier performance metrics to support future order
   allocation and logistics planning decisions.

===========================================================
*/                               




/*
===========================================================
ANALYSIS AREA 12 — GEOGRAPHIC SALES & PROFITABILITY ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q50 — TOP 5 CITIES BY REVENUE
-----------------------------------------------------------
*/

SELECT c.City,
        COUNT(*)AS Total_Orders,
        SUM(o.Sales_Amount)AS Revenue
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID
GROUP BY c.City
ORDER BY Revenue DESC
LIMIT 5
									   



/*
-----------------------------------------------------------
Q51 — TOP 5 MOST PROFITABLE CITIES
-----------------------------------------------------------
*/

    
SELECT c.City,
      COUNT(o.Order_ID)AS Total_order,
	SUM(o.Sales_Amount)AS Revenue,
    SUM(o.Profit)AS Profit
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
ORDER BY Profit DESC
LIMIT 5


/*
-----------------------------------------------------------
Q52 — TOP 5 CITIES BY AVERAGE PROFIT PER ORDER
-----------------------------------------------------------
*/

SELECT c.City,
 COUNT(o.Order_ID)AS Total_order,
    SUM(o.Profit)AS Profit,
       SUM(o.Profit)*1.0/
	   COUNT(o.Order_ID)AS Avg__Profit_Per_order
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
ORDER BY Avg__Profit_Per_order DESC
LIMIT 5


/*
-----------------------------------------------------------
Q53 — TOP 5 CITIES BY PROFIT MARGIN
-----------------------------------------------------------
*/


SELECT c.City,
     SUM(o.Sales_Amount)AS Revenue,         
    SUM(o.Profit)AS Profit,

        ROUND(
   SUM(o.Profit)*100.0/
	  SUM(o.Sales_Amount),2
	 ) AS Profit_Margin
 FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
ORDER BY Profit_Margin DESC
LIMIT 5



/*
-----------------------------------------------------------
Q54 — HIGH-REVENUE BUT LOW-PROFIT-MARGIN CITIES
-----------------------------------------------------------
*/

SELECT c.City,
     SUM(o.Sales_Amount)AS Revenue,
	 SUM(o.Profit) AS Profit,
ROUND(
   SUM(o.Profit)*100.0/
	  SUM(o.Sales_Amount),2
	 ) AS Profit_Margin
 FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
HAVING SUM(o.Sales_Amount)>500000
ORDER BY Profit_Margin ASC
LIMIT 5


/*
-----------------------------------------------------------
Q55 — TOP 5 CITIES BY AVERAGE ORDER VALUE
-----------------------------------------------------------
*/

SELECT c.City,
      COUNT(o.Order_ID)AS Total_Order,
     SUM(o.Sales_Amount)AS Revenue,
	 AVG(o.Sales_Amount) AS Avg_Order_Value
 FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
ORDER BY Avg_Order_Value DESC
LIMIT 5


/*
===========================================================
INSIGHTS
===========================================================

1. Pune was the highest-revenue city in the analysis,
   generating approximately ₹17.10 crore in revenue,
   followed by Chandigarh and Lucknow.

2. Pune, Chandigarh, Lucknow, Gurugram and Bengaluru
   appeared among the leading cities by revenue/profit,
   indicating that these markets are important contributors
   to overall business performance.

3. Bengaluru recorded the highest average profit per order
   at approximately ₹8,245, followed by Pune at approximately
   ₹8,205. This indicates that a city with fewer orders can
   still generate strong profitability per transaction.

4. Profit margin performance was relatively consistent
   across the leading cities, with margins generally in the
   range of approximately 26%. Faridabad recorded the highest
   margin in the provided analysis at 26.62%, while
   Chandigarh was among the lower-margin cities at 25.96%.

5. The analysis of high-revenue but low-margin cities shows
   that strong sales volume does not automatically translate
   into the strongest profitability. Revenue and margin
   therefore need to be evaluated together.

6. Average Order Value provides another perspective on
   geographic performance by identifying cities where
   customers generate higher-value transactions.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Continue investing in high-performing cities such as
   Pune and Lucknow while protecting their profitability
   through effective pricing, inventory and promotional
   strategies.

2. Analyse Bengaluru's strong average profit per order and
   identify whether its pricing, product mix or customer
   behaviour can provide learnings for other cities.

3. Investigate cities with high revenue but comparatively
   lower profit margins to identify opportunities related
   to pricing, discounts, product mix and operating costs.

4. Use city-level profit margin and average profit per order
   together when deciding where to increase marketing or
   sales investment.

5. Identify cities with high Average Order Value and use
   their successful customer or product strategies as
   benchmarks for lower-AOV markets.

6. Avoid evaluating geographic performance using revenue
   alone. A balanced city scorecard should include revenue,
   orders, profit, profit margin, average profit per order
   and Average Order Value.

===========================================================
*/                                        





  /*
===========================================================
ANALYSIS AREA 13 — SALESPERSON PERFORMANCE ANALYSIS
===========================================================
*/


/*
-----------------------------------------------------------
Q56 — TOP SALESPERSONS BY REVENUE AND PROFIT
-----------------------------------------------------------
*/


SELECT SalesPerson_ID,
        COUNT(*)AS Total_Orders,
        SUM(Sales_Amount)AS Revenue,
	   SUM(Profit)AS Total_Profit
FROM Orders
GROUP BY SalesPerson_ID
ORDER BY Revenue DESC
LIMIT 5


/*
===========================================================
INSIGHTS
===========================================================

1. Sales performance varies across salespersons, with a
   small group generating higher revenue than others.

2. The top-performing salesperson generated approximately
   ₹5.39 crore in revenue, indicating a significant
   contribution to overall sales performance.

3. The analysis helps identify the salespersons who are
   currently contributing the most revenue and can be used
   as a benchmark for evaluating other sales team members.

4. Revenue-based performance provides visibility into sales
   contribution, but should ideally be considered alongside
   profitability and order volume when evaluating overall
   salesperson effectiveness.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Recognize and study the practices of top-performing
   salespersons to identify strategies that can be shared
   across the wider sales team.

2. Use top-performer benchmarks to set realistic performance
   targets for other salespersons.

3. Investigate differences in customer mix, product mix and
   order volume across salespersons to understand the drivers
   behind revenue differences.

4. Evaluate salesperson performance using revenue together
   with profit and order-related KPIs where available, rather
   than relying on revenue alone.

5. Use salesperson-level analysis to support targeted
   coaching, performance reviews and incentive planning.

===========================================================
*/                                       





/*
===================================================================
ANALYSIS AREA 14 — CUSTOMER ENGAGEMENT & PRODUCT BREADTH ANALYSIS
===================================================================
*/


/*
-----------------------------------------------------------
Q57 — CUSTOMERS PURCHASING FROM BOTH CATEGORIES
-----------------------------------------------------------
*/

SELECT
    c.Customer_ID,
    c.Customer_Name,
	COUNT(DISTINCT p.Category)AS Category
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID	
JOIN Products p
ON p.Product_ID=o.Product_ID
GROUP BY c.Customer_ID,
    c.Customer_Name
HAVING COUNT(DISTINCT p.Category)=2
									 
										   
/*
-----------------------------------------------------------
Q58 — CUSTOMER PRODUCT BREADTH
-----------------------------------------------------------
*/
SELECT c.Customer_ID,
       c.Customer_Name,
	    SUM(o.Sales_Amount)AS Revenue,
	   COUNT(DISTINCT o.Product_ID)AS Total_Products
FROM Customers c
JOIN Orders o
ON c.Customer_ID=o.Customer_ID	  
GROUP BY c.Customer_ID,
       c.Customer_Name
ORDER BY Total_Products DESC


/*
-----------------------------------------------------------
Q59 — CUSTOMERS PURCHASING ACROSS MULTIPLE MONTHS
-----------------------------------------------------------
*/

SELECT 
      c.Customer_ID,
      c.Customer_Name,
   COUNT(DISTINCT DATE_TRUNC('MONTH',o.Order_Date)
            )AS Purchase_Month
FROM Customers c
JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID,
        c.Customer_Name
HAVING COUNT(DISTINCT DATE_TRUNC('MONTH',o.Order_Date))>1
ORDER BY Purchase_Month DESC




/*
===========================================================
INSIGHTS
===========================================================

1. Customers purchasing from both Furniture and Lighting
   demonstrate broader category engagement and have
   opportunities for cross-category purchasing.

2. Customer product breadth varies, with some customers
   purchasing a wider range of different products than
   others. Higher product breadth indicates stronger
   engagement with the product portfolio.

3. Customers purchasing across multiple months demonstrate
   more consistent engagement than customers whose purchases
   are concentrated within a single month.

4. Category breadth, product breadth and purchase continuity
   together provide a stronger indication of customer
   engagement than order count alone.

5. Customers showing strong engagement across multiple
   products, categories and months represent valuable
   opportunities for retention and cross-selling.


===========================================================
BUSINESS RECOMMENDATIONS
===========================================================

1. Use cross-selling campaigns to encourage customers
   purchasing from one category to explore complementary
   products from the other category.

2. Recommend relevant products to customers with low product
   breadth to increase product discovery and customer value.

3. Identify customers with purchases across multiple months
   and prioritize them for loyalty and retention initiatives.

4. Use customer product breadth and category engagement to
   create targeted customer segments for personalized
   recommendations.

5. Combine product breadth, category breadth and purchase
   continuity in the Power BI dashboard to identify highly
   engaged customers and potential cross-selling
   opportunities.

===========================================================
*/                                     

									 

