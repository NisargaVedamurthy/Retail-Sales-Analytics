use RetailCaseStudy;


select MIN(Bill_date_timestamp), max(Bill_date_timestamp)
from RetailCaseStudy_Orders


--no. of duplicates in orders table: 

select order_id, product_id, count(*) as cnt
from RetailCaseStudy_Orders
group by order_id, product_id
having count(*)>1;

select * 
from RetailCaseStudy_Orders
where order_id='8cd68144cdb62dc0d60848cf8616d2a4'

select count(distinct Customer_id)
from RetailCaseStudy_Orders

--indicates no returns
select order_id, sum(quantity) as qty_sum
from [RetailCaseStudy_Orders]
where Quantity>1
group by order_id
having sum(quantity)<0
order by qty_sum desc;


--no of orders and no of customers
select count(distinct order_id) as no_of_orders, count(distinct customer_id) as no_of_customers
from RetailCaseStudy_Orders;

--indicates that no.of orders differ in both the tables
select count(distinct o.order_id) as orders_in_orders_table, count(distinct op.order_id) as orders_in_Payments_table
from RetailCaseStudy_Orders as o
full outer join OrderPayments as op
on o.order_id=op.order_id
;
--
select distinct order_id 
from RetailCaseStudy_Orders
where order_id not in 
(
select distinct order_id
from OrderPayments
)

select sum(total_amount) from RetailCaseStudy_Orders
where order_id='bfbd0f9bdef84302105ad712db648a6c'

insert into OrderPayments
values
('bfbd0f9bdef84302105ad712db648a6c','others',286.92000579834)

--indicates that no. of stores differ in both the table
select count(distinct o.Delivered_StoreID) as no_of_stores_in_orders_table, 
count(distinct si.StoreID) as no_of_stores_in_storesinfo_table
from RetailCaseStudy_Orders as o
full outer join StoresInfo as si
on o.Delivered_StoreID=si.StoreID

--identifying orders whose sum(total_amount) does not match with payment_value

select a.order_id
from
(select order_id, sum(total_amount) as sum_amt
from RetailCaseStudy_Orders
group by order_id ) as a
inner join
(
select order_id, sum(payment_value) as sum_paid
from OrderPayments
group by order_id
) as b
on a.order_id=b.order_id
where sum_amt!=sum_paid
;

select *
from RetailCaseStudy_Orders
where order_id='0008288aa423d2a3f00fcb17cd7d8719'

select * from OrderPayments
where order_id='0008288aa423d2a3f00fcb17cd7d8719'

----


--Procedure to display one customer_id with one order_id and product_id BUT DIFFERENT NO OF QUANTITIES----
create procedure display_data @cust_id nvarchar(30)
as
select * 
from RetailCaseStudy_Orders
where Customer_id=@cust_id
GO

exec display_data @cust_id=7836871951

---------------

--Cleaning data for customers or orders with more quantity
--setting quantity as 1
update RetailCaseStudy_Orders
set quantity=1
 where order_id  in 
 ( 
 select a.order_id
from
(select order_id, sum(total_amount) as sum_amt
from RetailCaseStudy_Orders
group by order_id ) as a
inner join
(
select order_id, sum(payment_value) as sum_paid
from OrderPayments
group by order_id
) as b
on a.order_id=b.order_id
where sum_amt!=sum_paid
 )

 --setting total_amount based on the quantity
update RetailCaseStudy_Orders
set Total_Amount=Quantity*(MRP-Discount)
where order_id in
(
 select a.order_id
from
(select order_id, sum(total_amount) as sum_amt
from RetailCaseStudy_Orders
group by order_id ) as a
inner join
(
select order_id, sum(payment_value) as sum_paid
from OrderPayments
group by order_id
) as b
on a.order_id=b.order_id
where sum_amt!=sum_paid
)

 ----------

 -- for a given order_id we found two different bill_dates, for the same customer
select *
from RetailCaseStudy_Orders
where order_id='01cce1175ac3c4a450e3a0f856d02734'
 
 -----

