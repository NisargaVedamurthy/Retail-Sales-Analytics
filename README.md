Data has been provided from Sep 2021 to Oct 2023 for randomly selected 39 stores in India out of 535 stores for specific categories of products for randomly selected customers.
Data Overview:
The dataset has 6 tables, 1 FACT table and 5 DIM Tables
1. DIM table : Customers- contains information about customers data with fields like Customer ID, City, State and Gender.
2. DIM table : ProductInfo- contains informations about the various products sold at the stores, the category they belong to and further description
3. DIM Table : StoresInfo- cotains information about the stores, their location and Store ID
4. DIM Table : OrderPayments- consists of fields like OrderID, payment type and payment value
5. DIM Table : OrderReviewRatings - consists of OrderID, CustomerID and Satisfaction score
6. FACT Table : Orders - Customer_id, order_id, product_id, Channel, Delivered_StoreID, Bill_date_timestamp, Quantity, CostPerUnit, MRP, Discount and  Total Amount

The Analysis done are - EDA, Customer Behaviour, Cross Selling of Products, Category Behaviour, Customer retention for month-on-month and analysis related to Sales Trends, Patterns and Seasonality
