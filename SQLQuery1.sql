use RetailCaseStudy;

select * from RetailCaseStudy_Orders;

--1. Detailed Exploratory Analysis:

/*The number of orders, Number of customers,Total Discount, percentage of discount,Total Revenue, 
Total Profit, percentage of profit,Total Cost, Total quantity, Total products, Total categories, 
Total stores, Total locations, Total Regions, Total channels, Total payment methods, Average order value or Average Bill Value*/

select count(distinct orders.order_id) as no_of_orders,
count(distinct customer_id) as no_of_customers,
sum(discount) as total_discount,
round((sum(discount)/sum(total_amount))*100,2) as discount_percentage,
round(sum(total_amount),0) as total_revenue,
round(sum(total_amount)-sum(cost_per_unit),2) as total_profit,
round(((sum(total_amount)-sum(cost_per_unit))/sum(total_amount))*100,2) as profit_percentage,
round(sum(total_amount),2) as total_cost,
sum(quantity) as total_quantity,
count(distinct orders.product_id) as total_products,
count(distinct category) as total_categories,
count(distinct si.StoreID) as total_stores,
count(distinct seller_city) as total_Locations,
count(distinct Region) as total_regions,
count(distinct channel) as total_channels,
count(distinct payment_type) as payment_methods,
round(avg(cast(orders.Total_Amount as float)),2) as avg_order_value
from StoresInfo as si 
inner join [RetailCaseStudy_Orders] as orders
on si.StoreID=orders.Delivered_StoreID
inner join OrderPayments as op
on orders.order_id=op.order_id
inner join ProductsInfo as prodinfo
on orders.product_id=prodinfo.product_id;


/* Average discount per customer, Average Sales per Customer,
Average profit per customer, Transactions per Customer,
*/

select round(avg(avg_discount_per_customer),2) as avg_of_discount,
round(avg(avg_sales),2) as avg_of_sales,
round(avg(avg_profit_per_customer),2) as avg_of_profits,
round(avg(no_of_transactions),2) as avg_no_of_transactions
from 
( select customer_id, cast(avg(discount) as float) as avg_discount_per_customer,
avg(total_amount) as avg_sales,
sum(total_amount)-sum(cost_per_unit) as avg_profit_per_customer,
count(Bill_date_timestamp) as no_of_transactions
from [RetailCaseStudy_Orders]
group by customer_id 
) a
; 

/* Average discount per order,  average number of categories per order, average number of items per order,
*/

select avg(avg_discount) as complete_avg, avg(no_of_categories) as avg_no_of_categories,
avg(no_of_items_per_order)
from
(select order_id, avg(discount) as avg_discount,
count(category) as no_of_categories,
count(quantity) as no_of_items_per_order
from [RetailCaseStudy_Orders] as orders
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
group by order_id
) as a ;


--repeat customer percentage
select 
(cast(count(distinct customer_id) as float) / (select count(distinct customer_id)
												from RetailCaseStudy_Orders)) * 100 as repeat_customer_percentage
from (
select customer_id
from RetailCaseStudy_Orders
group by customer_id
having count(distinct order_id) > 1
) as repeat_customers ;
--- the above query indicates that very less customers are being repeated

-- percentage of one time buyers
with one_time_buyers as
(
select count(a.Customer_id) as no_of_one_time_buyers
from
(
select Customer_id,count(distinct order_id) as no_of_transc
from RetailCaseStudy_Orders 
group by Customer_id
having count(distinct order_id)=1
) as a
),
total_no_of_buyers as
(
select count(distinct customer_id) as total_no_buyers
from RetailCaseStudy_Orders
)
select
 cast(no_of_one_time_buyers as float)/cast(total_no_buyers as float)*100 as percentage_of_one_time_buyers
 from one_time_buyers 
 cross join total_no_of_buyers
 ;
--the above query indicates that one time buyer % is very high, meaning the customer retention is low, 
--this is not a good indication--> customers not happy
 

--Average number of days between two transactions (if the customer has more than one transaction),

WITH TransactionDifferences AS (
    SELECT
        customer_id,
        Bill_date_timestamp,
        LAG(Bill_date_timestamp) OVER (PARTITION BY customer_id ORDER BY Bill_date_timestamp) AS previous_order_date
    FROM RetailCaseStudy_Orders
),
Differences AS (
    SELECT
        customer_id,
        DATEDIFF(day, previous_order_date, Bill_date_timestamp) AS days_difference
    FROM TransactionDifferences
    WHERE previous_order_date IS NOT NULL
)
SELECT
    customer_id, AVG(days_difference) AS avg_days_between_transactions
FROM Differences
group by Customer_id
order by avg_days_between_transactions desc
;

-- Understanding how many new customers acquired every month (who made transaction first time in the data)

select month_of_transc, avg(new_customer) as new_customers
from
(select year(Bill_date_timestamp) as year_of_transc,
MONTH(Bill_date_timestamp) as month_of_transc, 
count(distinct customer_id) as new_customer
from [RetailCaseStudy_Orders]
group by MONTH(Bill_date_timestamp), year(Bill_date_timestamp) 
) a
group by month_of_transc;


--Understand the trends/seasonality of sales, quantity by category, region, store, channel, payment method etc…

select region, StoreID, round(sum(total_amount),2) as sales_amount, sum(quantity) as Quantity_sold
from StoresInfo as si 
inner join RetailCaseStudy_Orders as orders
on orders.Delivered_StoreID=si.StoreID
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
group by Region, StoreID
order by Quantity_sold desc
;

---How the revenues from existing/new customers on month on month basis 

 select month(Bill_date_timestamp) as month_of_purchase,
 round(sum(total_amount),2) as total_sales_existing_customer
 from
(select customer_id
from RetailCaseStudy_Orders
group by customer_id
having count(order_id) >1
) as a
inner join RetailCaseStudy_Orders as b
on a.Customer_id=b.Customer_id
group by month(Bill_date_timestamp)
order by total_sales_existing_customer desc;
 

--Popular categories/Popular Products by store, state, region. 

 Select Category, sum(total_amount) as sales
 from RetailCaseStudy_Orders o
 inner join ProductsInfo p
 on o.product_id=p.product_id
 group by Category
 order by sales desc;


--List the top 10 most expensive products sorted by price and their contribution to sales
  select category, product_id, Cost_price, product_sales
 from
 (select category, o.product_id, max(Cost_Per_Unit) as Cost_price,
 sum(total_amount) as product_sales
 from RetailCaseStudy_Orders o
 inner join ProductsInfo p
 on o.product_id=p.product_id
 group by o.product_id, Category
 ) a
 order by Cost_price desc
;

--Which product appeared in the transactions?

select product_id, COUNT(Bill_date_timestamp) no_of_transactions
from RetailCaseStudy_Orders
group by product_id
order by no_of_transactions desc;


--Top 10-performing & worst 10 performance stores in terms of sales

select top 10 Delivered_StoreID, round(sum(Total_Amount),2) as total_sales
from RetailCaseStudy_Orders
group by Delivered_StoreID
order by total_sales desc;

--Worst 10 performance stores in terms of sales

select top 10 Delivered_StoreID, round(sum(Total_Amount),2) as total_sales
from RetailCaseStudy_Orders
group by Delivered_StoreID
order by total_sales asc;



--2. Customer Behaviour
 
--Segment the customers (divide the customers into groups) based on the revenue

select *
from customers;
select * from [RetailCaseStudy_Orders] ;
 
 --Find out the number of customers who purchased in all the channels and find the key metrics.

 select COUNT(customer_id) as no_of_customers_per_channel, channel
 from [RetailCaseStudy_Orders]
 group by channel
 order by no_of_customers_per_channel desc;

 -- Recency is about when the last order of a customer. 
 --It means the number of days since a customer made the last purchase.

 select count(distinct Customer_id) no_of_customers, 
 Recency_rate
 from
 (select customer_id,
 case when no_of_active_days between 0 and 114 
		then 'Standard'
	  when no_of_active_days between 115 and 228
		then 'Silver'
	  when no_of_active_days between 229 and 342
		then 'Gold'
	  else 'Premium'
	end as Recency_rate
 from
 ( select DATEDIFF(DAY,min(Bill_date_timestamp),max(Bill_date_timestamp)) as no_of_active_days,
 customer_id
 from [RetailCaseStudy_Orders]
 group by customer_id
 ) a
 )b
 group by Recency_rate
 ;

 
 /*Frequency is about the number of purchases in a given period. 
 It could be 3 months, 6 months, or 1 year. 
 So we can understand this value as for how often or how many customers use the product of a company. 
 The bigger the value is, the more engaged the customers are.  
Alternatively, We can define, the average duration between two transactions */

select count( distinct customer_id), Frequency_rate
from
 (select customer_id, year_no,quarter,
 case when no_of_orders between 0 and 10
	then 'Standard'
	when no_of_orders between 11 and 20
	then 'Silver'
	when no_of_orders between 21 and 40
	then 'Gold'
	else 'Premium'
 end as Frequency_rate
 from
 (select Customer_id, year_no, Quarter,sum(no_of_orders) as no_of_orders
 from
 (select Customer_id,year_no,
 case when month_no/3 in (1,2,3,4)
		then month_no/3
	  else floor((month_no/3)+1)
end as Quarter,
no_of_orders
 from
 (select customer_id,year(Bill_date_timestamp) as year_no, month(Bill_date_timestamp) as month_no, 
 count(distinct order_id) as no_of_orders
 from RetailCaseStudy_Orders
 group by Customer_id,month(Bill_date_timestamp),year(Bill_date_timestamp)
 ) a
) b
group by Customer_id,year_no,Quarter
)c
) d
group by Frequency_rate
;


-- most of the buyers are standard, since the freq of each buyer is very less.

 /*Monetary is the total amount of money a customer spent in that given period.
 Therefore big spenders will be differentiated from other customers such as MVP or VIP. */

 select COUNT( distinct customer_id) as no_customers, Monetary_rate
 from
 (select customer_id, year_no,quarter,
 case when sales_amount between 0 and 2000
	then 'Standard'
	when sales_amount between 2001 and 4000
	then 'Silver'
	when sales_amount between 4001 and 6000
	then 'Gold'
	else 'Premium'
 end as Monetary_rate
 from
 (select Customer_id, year_no, Quarter, sum(total_sales) as sales_amount
 from
 (select Customer_id,year_no,
 case when month_no/3 in (1,2,3,4)
		then month_no/3
	  else floor((month_no/3)+1)
end as Quarter,
total_sales
 from
 (select customer_id,year(Bill_date_timestamp) as year_no, month(Bill_date_timestamp) as month_no, 
 sum(total_amount) as total_sales
 from RetailCaseStudy_Orders
 group by Customer_id,month(Bill_date_timestamp),year(Bill_date_timestamp)
 ) a
) b
group by Customer_id,year_no,Quarter
)c
)d
group by Monetary_rate;



 --Find out the number of customers who purchased in all the channels and find the key metrics.

select Channel, round(count(distinct Customer_id),2) as no_of_customers,
 round(sum(total_amount),2) as sales_per_channel,
 avg(discount) as avg_discount,
round((sum(total_amount)-sum(cost_per_unit)),2) as profit_per_channel
 from RetailCaseStudy_Orders o
 inner join StoresInfo si
 on si.StoreID=o.Delivered_StoreID
 group by Channel
  order by no_of_customers desc;

  

 --Understand the behavior of discount seekers & non discount seekers

 --discount seekers
  select count(distinct Customer_id) as no_of_customers,
  avg(discount_taken) as avg_discount, avg(total_sales) avg_sales
  from
  (select  distinct Customer_id, sum(Discount) as discount_taken, sum(total_amount) as total_sales
    from RetailCaseStudy_Orders o
  group by Customer_id
  )a
  where discount_taken>0
  ;

  select * from RetailCaseStudy_Orders
  where Customer_id='1111819100';

  --non-discount seekers
  select COUNT(distinct Customer_id) as no_of_customers, avg(total_sales) as avg_sales,
  avg(no_of_products) as avg_products
  from
  (select distinct Customer_id, sum(discount) as discount_taken, sum(total_amount) as total_sales,
  count(distinct product_id) as no_of_products
  from RetailCaseStudy_Orders
   group by Customer_id) a
   where discount_taken=0
  ;


 --Understand preferences of customers (preferred channel, Preferred payment method,
--preferred store, discount preference, preferred categories etc.

 --customers preferring a certain payment type
 select count(distinct customer_id) as no_of_customers, payment_type
 from RetailCaseStudy_Orders as o
 inner join OrderPayments as op
 on op.order_id=o.order_id
 group by payment_type


 --customers preferring a certain category
 select category, count(distinct Customer_id) as no_of_customers
 from RetailCaseStudy_Orders o
 inner join ProductsInfo p
 on o.product_id=p.product_id
 group by Category


 --customers preferring a certain channel
 select channel, count(distinct customer_id) as no_of_customers
 from RetailCaseStudy_Orders
 group by Channel;

 --customers preferring a certain store and the state and region
 select Delivered_StoreID, seller_state, region, count(distinct Customer_id) as no_of_customers
 from RetailCaseStudy_Orders as o
 inner join StoresInfo as si
 on o.Delivered_StoreID=si.StoreID
 group by Delivered_StoreID, seller_state, Region
 order by no_of_customers desc;

--Understand the behavior of customers who purchased one category and purchased multiple categories

--customers who has purchased from one category - FINDING AVG SALES
select round(avg(profit),2) as avg_profit
from
(
select customer_id, avg(sales_amount) as avg_sales,
sum(sales_amount)-sum(Costprice) as profit
from
( --below code finds the no of customers with only 1 category
select Customer_id, count(distinct category) as count_of_categories, sum(total_amount) as sales_amount,
sum(cost_per_unit*Quantity) as Costprice
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id
having count(distinct Category)>1
)  a 
group by Customer_id
) b
;


--customers who have purchased from one category - across regions and states
select Region,seller_state, 
count( distinct customer_id) as no_of_customers, round(avg(sales_amount),2) as avg_sales
from
( --below code finds the no of customers with only 1 category
select distinct Customer_id, count(distinct category) as count_of_categories,count(o.product_id) as count_of_products,
sum(total_amount) as sales_amount, Delivered_StoreID
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id,Delivered_StoreID
having count(distinct Category)=1
)  a  
INNER JOIN StoresInfo si 
on a.Delivered_StoreID=si.StoreID
group by Region,seller_state 
order by avg_sales desc;

-- checking if the customer id is duplicated or has bought from multiple stores
select *
from
(select distinct Customer_id, count(distinct category) as count_of_categories,count(o.product_id) as count_of_products,
sum(total_amount) as sales_amount, Delivered_StoreID
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id,Delivered_StoreID
having count(distinct Category)=1
) a
INNER JOIN StoresInfo si 
on a.Delivered_StoreID=si.StoreID
where Customer_id=1149964891



--how many customers have bought from different states
select Customer_id, count(distinct seller_state) 
from
(select distinct Customer_id, count(distinct category) as count_of_categories,count(o.product_id) as count_of_products,
sum(total_amount) as sales_amount, Delivered_StoreID
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id,Delivered_StoreID
having count(distinct Category)=1
) a
INNER JOIN StoresInfo si 
on a.Delivered_StoreID=si.StoreID
group by Customer_id
having count(distinct seller_state)=3
;


customer = state
421 = 2
7 = 3
2 = 4


--customers who have purchased from multiple category
select count(customer_id) as no_of_customers, avg(sales_amount) as avg_sales
from
( --below code finds the no of customers with 2 and above category
select Customer_id, count(distinct category) as count_of_categories, sum(total_amount) as sales_amount
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id
having count(distinct Category)>1
)  a ;


--customers who have purchased from multiple categories - across stores, regions and states 
select Region,seller_state, 
count(customer_id) as no_of_customers, round(avg(sales_amount),2) as avg_sales
from
( --below code finds the no of customers with more than 1 category
select Customer_id, count(distinct category) as count_of_categories,count(o.product_id) as count_of_products,
sum(total_amount) as sales_amount, Delivered_StoreID
from RetailCaseStudy_Orders o
inner join ProductsInfo p
on o.product_id=p.product_id
group by customer_id, Delivered_StoreID
having count(distinct Category)>1
)  a  
INNER JOIN StoresInfo si 
on a.Delivered_StoreID=si.StoreID
group by Region,seller_state 
order by avg_sales desc, no_of_customers desc;
/*the above query indicates that in andhra, there is only 1 customer who purchased from multiple categories and
made the highest avg_sales, but if we go through the output, we see that there 80 customers in gujarat and
85 customers in andhra who didnt make the highest avg_sales but they bought across multiple categories*/


--Understand the behavior of one time buyers and repeat buyers

--behaviour of one time buyers ( dist orderid)
select count(customer_id) no_of_one_time_buyers, avg(sales_amount) as avg_sales, avg(total_discount) as avg_discount 
from
(select distinct Customer_id, count(distinct order_id) as orders_made, sum(Total_Amount) as sales_amount,
sum(discount) as total_discount
from RetailCaseStudy_Orders 
group by Customer_id
having count(distinct order_id)=1
) as a ;

--categories sold for one time buyers
select category, count(distinct customer_id) as no_of_customers, avg(sum_sales) as avg_sales
from
(
select Customer_id, product_id, sum(total_amount) as sum_sales
from RetailCaseStudy_Orders o 
group by Customer_id, product_id
having count(distinct order_id)=1
)as a
inner join ProductsInfo p
on a.product_id=p.product_id
group by Category
order by avg_sales desc;

--behaviour of repeat buyers (more than 1 order_id)
select count(distinct customer_id) no_of_repeat_customers, avg(sales_amount) as avg_sales, avg(total_discount) as avg_discount
from
(select customer_id,  
count(distinct order_id) no_of_orders, sum(total_amount) as sales_amount,
sum(discount) as total_discount
from RetailCaseStudy_Orders
group by Customer_id
having count(distinct order_id)>1
) as b
;


-- repeat buyers spread over categories
select category, count(o1.Customer_id) as no_of_customers, round(avg(sum_sales),2) as avg_sales
from
(
select Customer_id, sum(total_amount) as sum_sales
from RetailCaseStudy_Orders o 
group by Customer_id
having count(distinct order_id)>1
)as a
inner join RetailCaseStudy_Orders o1
on a.Customer_id=o1.Customer_id
inner join ProductsInfo p
on o1.product_id=p.product_id
group by Category;



--Understand the behavior of discount seekers & non discount seekers

--behaviour of non- discount seekers
select count(customer_id) no_of_discount_seekers, avg(sales_amount) as avg_sales
from
(select distinct Customer_id, count(distinct order_id) as orders_made, sum(Total_Amount) as sales_amount
from RetailCaseStudy_Orders 
group by Customer_id
having sum(Discount)=0
) as a ;

--category spread of non-discount seekers
select category, COUNT(p.product_id) as no_of_products, avg(sales) as avg_sales
from
(
select Customer_id, product_id, sum(total_amount) as sales
from RetailCaseStudy_Orders o 
group by Customer_id, product_id
having sum(discount)=0
)as a
inner join ProductsInfo p
on a.product_id=p.product_id
group by Category
order by no_of_products desc;

--non discount seekers vs state and city
select seller_state, COUNT(Customer_id) as no_of_customers
from
(
select Customer_id, Delivered_StoreID
from RetailCaseStudy_Orders o 
group by Customer_id, Delivered_StoreID
having sum(discount)=0
)as a
inner join StoresInfo si
on a.Delivered_StoreID=si.StoreID
group by seller_state
order by no_of_customers desc;


--behaviour of discount seekers
select count(customer_id) no_of_repeat_customers, avg(sales_amount) as avg_sales
from
(select customer_id, count(distinct order_id) no_of_orders, sum(total_amount) as sales_amount
from RetailCaseStudy_Orders
group by Customer_id
having sum(discount)>0
) as b

--category spread of discount seekers
select category, COUNT(p.product_id) as no_of_products
from
(
select Customer_id, product_id
from RetailCaseStudy_Orders o 
group by Customer_id, product_id
having sum(discount)>0
)as a
inner join ProductsInfo p
on a.product_id=p.product_id
group by Category
order by no_of_products desc;

--behaviour of discount seekers vs state, city
select seller_state, COUNT(Customer_id) as no_of_customers
from
(
select Customer_id, Delivered_StoreID
from RetailCaseStudy_Orders o 
group by Customer_id, Delivered_StoreID
having sum(discount)>0
)as a
inner join StoresInfo si
on a.Delivered_StoreID=si.StoreID
group by seller_state
order by no_of_customers desc;




 --3. Hint: We need to find which of the top 10 combinations of products are selling together in each transaction. 
 --(combination of 2 or 3 buying together) 

 select products_bought_together, count(*) as count_of_products
 from
 (
 select order_id, string_agg(product_id,'-') within group (order by product_id) as products_bought_together
 from
 (select order_id, product_id
 from RetailCaseStudy_Orders
 group by order_id,product_id
 ) a 
 group by order_id
 having count(distinct product_id)>2 
 ) b
 group by products_bought_together
 order by count_of_products desc
 ;

 -- 4. Understand the Category Behavior
/*Total Sales & Percentage of sales by category (Perform Pareto Analysis) and 
Most profitable category and contribution */

select category, round(sum(total_amount),2) as category_sales,
(sum(total_amount)/total_sales)*100 as percentage_category_sales
from RetailCaseStudy_Orders as o
inner join ProductsInfo as p
on o.product_id=p.product_id
cross join 
(select sum(total_amount) as total_sales 
from RetailCaseStudy_Orders 
) d
group by Category,total_sales
order by percentage_category_sales desc;

--Category Penetration Analysis by month on month 
--(Category Penetration = number of orders containing the category/number of orders)

select c.month, category, 
(cast(category_orders as float)/cast(total_orders as float))*100 as category_penetration
from
(select month(Bill_date_timestamp) as month, category, count(distinct order_id) as category_orders
from RetailCaseStudy_Orders as o
inner join ProductsInfo as p
on o.product_id=p.product_id
group by month(Bill_date_timestamp), Category
) c
inner join 
(select count(distinct order_id) as total_orders, MONTH(Bill_date_timestamp) as month
from RetailCaseStudy_Orders 
group by month(Bill_date_timestamp)
) d
on c.month=d.month
order by category_penetration desc;


/*Cross Category Analysis by month on Month (In Every Bill, how many categories shopped.
Need to calculate average number of categories shopped in each bill by Region, By State etc)
*/
--by region
select month_of_billing, avg(no_of_orders) as avg_no_of_orders, avg(no_of_categories) as avg_no_of_categories, 
Region
from
(select month(Bill_date_timestamp) as month_of_billing, Delivered_StoreID, count(order_id) as no_of_orders, 
count( distinct Category) as no_of_categories 
from RetailCaseStudy_Orders as o
inner join ProductsInfo as p
on o.product_id=p.product_id
group by month(Bill_date_timestamp), Delivered_StoreID
) a
inner join StoresInfo as si
on a.Delivered_StoreID=si.StoreID
group by Region, month_of_billing
order by avg_no_of_categories desc ;


--Most popular category during first purchase of customer
select category, count(p.product_id) as no_of_products
from
(select Customer_id, order_id,
rank() over (partition by customer_id, order_id order by Bill_date_timestamp) as rnk
from
(
select Customer_id, order_id, min(bill_date_timestamp) as Bill_date_timestamp
from RetailCaseStudy_Orders
group by Customer_id, order_id
) a
) b
inner join RetailCaseStudy_Orders o
on b.order_id=o.order_id
inner join ProductsInfo p
on o.product_id=p.product_id
where rnk=1
group by Category
order by no_of_products desc;


 --5. Customer satisfaction towards category & product 
--Which categories (top 10) are maximum rated & minimum rated and average rating score? 

--top 10 max rated products and categories
select top 10 orders.product_id,category,max(Customer_Satisfaction_Score) as max_rated
from OrderReview_Ratings as ratings
inner join RetailCaseStudy_Orders as orders
on ratings.order_id=orders.order_id
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
where Category!='#N/A'
group by orders.product_id,Category
order by max_rated desc;


--top 10 min rated products and categories

select top 10 orders.product_id,category,min(Customer_Satisfaction_Score) as min_rated
from OrderReview_Ratings as ratings
inner join RetailCaseStudy_Orders as orders
on ratings.order_id=orders.order_id
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
where Category!='#N/A'
group by orders.product_id,Category
order by min_rated asc;

--top 10 avg rated products and categories

select * from OrderReview_Ratings;

select top 10 a.product_id, Category, Customer_Satisfaction_Score
from
(select product_id, Customer_Satisfaction_Score
from OrderReview_Ratings r
inner join RetailCaseStudy_Orders o
on r.order_id=o.order_id
where Customer_Satisfaction_Score=3
) a
inner join productsinfo p
on a.product_id=p.product_id
where Category!='#N/A' ;


--Average rating by location, store, product, category, month, etc.

select seller_city,seller_state, StoreID, orders.product_id, category, avg(Customer_Satisfaction_Score) as avg_rating
from StoresInfo as si
inner join RetailCaseStudy_Orders as orders
on si.StoreID=orders.Delivered_StoreID
inner join OrderReview_Ratings as ratings
on orders.order_id=ratings.order_id
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
group by orders.product_id, seller_city, seller_state, StoreID, Category
;


/*6. Perform cohort analysis (customer retention for month on month and retention for fixed month)
*/
--Which Month cohort has maximum retention?
select year, month, count(customer_id) as no_of_customers_retained
from
(select year(Bill_date_timestamp) as year, MONTH(Bill_date_timestamp) as month, Customer_id, 
rank() over (partition by customer_id order by year(Bill_date_timestamp),month(Bill_date_timestamp)) as rnk
from RetailCaseStudy_Orders
group by MONTH(Bill_date_timestamp), Customer_id,year(Bill_date_timestamp) 
) a
where rnk>1
group by month, year
;

--"Customers who started in each month and understand their behavior in the respective months"
select year, month, region, seller_state, count(distinct a.Customer_id) as no_of_customers,
sum(total_amount) as total_sales
from
(select year(Bill_date_timestamp) as year, MONTH(Bill_date_timestamp) as month, Customer_id, 
rank() over (partition by customer_id order by year(Bill_date_timestamp),month(Bill_date_timestamp)) as rnk
from RetailCaseStudy_Orders
group by MONTH(Bill_date_timestamp), Customer_id,year(Bill_date_timestamp) 
) a
inner join RetailCaseStudy_Orders o
on a.Customer_id=o.Customer_id
inner join StoresInfo si
on o.Delivered_StoreID=si.StoreID
where rnk>1
group by month, year, Region, seller_state
order by total_sales desc
;


-- 7. Perform analysis related to Sales Trends, patterns, and seasonality. 
--Which months have had the highest sales, what is the sales amount and contribution in percentage?

create procedure monthly_sales
as
begin 
	select year(Bill_date_timestamp) as sale_year, 
	month(Bill_date_timestamp) as sale_month,
	round(sum(total_amount),2)as sales_amount
	from RetailCaseStudy_Orders 
	group by year(Bill_date_timestamp),month(Bill_date_timestamp) ;
end

execute monthly_sales;

select Bill_date_timestamp, Total_Amount
from RetailCaseStudy_Orders
where year(Bill_date_timestamp)=2021 and MONTH(bill_date_timestamp)=12

--  total sales by month and overall total sales
WITH monthly_sales AS (
    SELECT 
        MONTH(Bill_date_timestamp) AS sale_month,
        SUM(total_amount) AS monthly_sales 
    FROM RetailCaseStudy_Orders
    GROUP BY  MONTH(Bill_date_timestamp)     
),
total_sales AS (
    SELECT 
        SUM(total_amount) AS total_sales
    FROM RetailCaseStudy_Orders
)
-- months with the highest sales, their sales amount, and their percentage contribution
SELECT 
    ms.sale_month,
    ms.monthly_sales,
	--ts.total_sales,
   round((ms.monthly_sales * 100.0 / ts.total_sales),2) AS percentage_contribution
FROM 
    monthly_sales ms
    CROSS JOIN total_sales ts
ORDER BY 
    ms.monthly_sales DESC;

	
--Which months have had the least sales, what is the sales amount and contribution in percentage?  
--  total sales by month and overall total sales
WITH monthly_sales AS (
    SELECT 
        MONTH(Bill_date_timestamp) AS sale_month,
        SUM(total_amount) AS monthly_sales 
    FROM RetailCaseStudy_Orders
    GROUP BY  MONTH(Bill_date_timestamp)     
),
total_sales AS (
    SELECT 
        SUM(total_amount) AS total_sales
    FROM RetailCaseStudy_Orders
)

-- months with the highest sales, their sales amount, and their percentage contribution
SELECT 
    ms.sale_month,
    ms.monthly_sales,
	ts.total_sales,
   round((ms.monthly_sales * 100.0 / ts.total_sales),2) AS percentage_contribution
FROM 
    monthly_sales ms
    CROSS JOIN total_sales ts
ORDER BY 
    ms.monthly_sales asc;



--Sales trend by month   
--Is there any seasonality in the sales (weekdays vs. weekends, months, days of week, weeks etc.)?
--Total Sales by Week of the Day, Week, Month, Quarter, Weekdays vs. weekends etc."

select region,weekday, sum(sales_amount) as weekday_sales
from
(select Region,
year(Bill_date_timestamp) as year, 
datename(month, Bill_date_timestamp) as month,
datename(quarter, Bill_date_timestamp) as quarter,
DATENAME(week, Bill_date_timestamp) as week,
datename(dw, Bill_date_timestamp) as weekday,
round(sum(total_amount),2) as sales_amount
from RetailCaseStudy_Orders o
inner join StoresInfo si
on si.StoreID=o.Delivered_StoreID
group by year(Bill_date_timestamp),
datename(month, Bill_date_timestamp),
datename(quarter, Bill_date_timestamp),
DATENAME(week, Bill_date_timestamp),
datename(dw, Bill_date_timestamp),
Region
) a
group by weekday, Region
order by weekday_sales desc
;


select year, sum(sales_amount) as yearly_sales
from
(select year(Bill_date_timestamp) as year, 
datename(month, Bill_date_timestamp) as month,
datename(quarter, Bill_date_timestamp) as quarter,
DATENAME(week, Bill_date_timestamp) as week,
datename(dw, Bill_date_timestamp) as weekday,
round(sum(total_amount),2) as sales_amount
from RetailCaseStudy_Orders
group by year(Bill_date_timestamp),
datename(month, Bill_date_timestamp),
datename(quarter, Bill_date_timestamp),
DATENAME(week, Bill_date_timestamp),
datename(dw, Bill_date_timestamp) 
) a
group by year 
order by yearly_sales desc
;

select  region, month, sum(sales_amount) as monthly_sales
from
(select region,
year(Bill_date_timestamp) as year, 
datename(month, Bill_date_timestamp) as month,
datename(quarter, Bill_date_timestamp) as quarter,
DATENAME(week, Bill_date_timestamp) as week,
datename(dw, Bill_date_timestamp) as weekday,
round(sum(total_amount),2) as sales_amount
from RetailCaseStudy_Orders o
inner join StoresInfo s
on s.StoreID=o.Delivered_StoreID
group by year(Bill_date_timestamp),
datename(month, Bill_date_timestamp),
datename(quarter, Bill_date_timestamp),
DATENAME(week, Bill_date_timestamp),
datename(dw, Bill_date_timestamp),
Region
) a
group by month, Region
order by monthly_sales desc
;
