use RetailCaseStudy;

select count( distinct customer_id), rfm_segmentation
from
(
select recencytable.Customer_id,
case when Recency_rate='Premium' or Frequency_rate='Premium' or Monetary_rate='Premium'
then 'Premium'
when Recency_rate='Gold' or Frequency_rate='Gold' or Monetary_rate='Gold'
then 'Gold'
when Recency_rate='Silver' or Frequency_rate='Silver' or Monetary_rate='Silver'
then 'Silver'
else 'Standard'
end as rfm_segmentation
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
 ) recencytable
 inner join 
 (
 select customer_id, year_no,quarter,
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
) frequencytable
on recencytable.Customer_id=frequencytable.Customer_id
inner join
(
select customer_id, year_no,quarter,
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
) monetarytable
on frequencytable.Customer_id=monetarytable.Customer_id
) rfmvalue
group by rfm_segmentation
;