# Online Retail Analysis Project (link: https://www.kaggle.com/datasets/dvaser/online-retail-ii)

## Business Question

This project works with customer sales data from the years 2009 to 2011 for 
a company that operates in the United Kingdom but has transactions in other countries as well. 
The stakeholders and management have approached with a business question to help increase sales 
and understand the performance of the company more clearly. How can the company increase sales 
performance by understanding customer behavior, product performance, regional trends,
and operational inefficiencies? To answer these questions, revenue assessment, RFM analysis of customer 
behavior, product performance, seasonality, and geographical assessments were all taken into account. 

Specifically, this analysis answers: 
	- Revenue Performance
		How is revenue changing over time?
		What years/months generate the most sales?
		Are there growth or decline trends?
	- Customer Behavior (RFM Analysis)
		Who are the highest-value customers?
		Which customers are at risk of becoming inactive?
		How concentrated is revenue among customers (Pareto analysis)?
	- Product Performance
		Which products drive the most revenue?
		Are there products that may need promotion or inventory adjustments?
	- Seasonality
		Are there predictable periods of high or low demand?
		How should the business prepare inventory and marketing campaigns?
	- Geographic/Regional Analysis
		Which countries/regions generate the most revenue?
		Are there underperforming markets with potential?
		
##. Tools Used
- Excel
- BigQuery SQL
- Power BI

## Data Cleaning & Preparation

The data was first uploaded to Excel for cleaning purposes. Data types were converted 
to the correct type, duplicates were removed, and column data was standardized. There 
are two datasets in total, one from 2009-2010 and the other from 2010-2011. Both datasets 
have columns Invoice, for the transaction invoice number, Stockcode, for the stock code 
number, Description, for the description of the product that was purchased. It also 
includes Quantity, which is the amount of the product in each transaction, InvoiceDate 
and InvoiceTime, which show the date and time the transaction was made, respectively. 
Price is the unit price per product. Customer ID refers to the specific customer that 
bought the product, and Country is the customer's country of origin. These tables are 
later merged in bigQuery SQL and used to create fact and dimension tables for the PowerBI visualizations.

## Data Limitations 

A significant portion of transactions contained missing Customer IDs and/or product descriptions. Rather than removing these transactions entirely, records were retained for analyses that did not require customer-level identification. Missing Customer IDs were categorized as "Unknown," while missing product descriptions were categorized as "No Description." Customer-level analyses such as RFM segmentation were restricted to transactions with valid Customer IDs to avoid aggregating unrelated transactions under a single unknown customer. 

## Exploratory Data Analysis (EDA)

![Executive Summary](./Retail_Visuals.png)

There was a total of 22.6 million pounds in sales for the company across the entire sales data. 
There were around 5,000 total customers to the company from 2009 to 2011, with an average order 
value of 21.48 pounds. The United Kingdom itself serves as the main country providing the most 
revenue. In BigQuery, a monthly seasonality index was calculated by comparing monthly revenue 
against the average monthly revenue for the corresponding period.
Seasonality performance was the best from December of 2010 to January of 2011 as well 
as around December of 2011.

## Key Insights

Also in BigQuery, a pareto analysis was conducted to see the effects of the high value customer base. 
According to this analysis, 20 percent of the customer base in the data contribute 85 percent of the total sales. 
From the seasonality indices, November and December appear to be the best performing months 
out of the different years because the monthly sales exceed the average monthly sales and overall average sales. 
The fourth quarter of the different years have the most sale activity as well. The recency, frequency, 
and monetary rating scores tell much about the different customers in the dataset. 
Year-over-Year (YoY) growth and Month-over-month (MoM) growth in BigQuery show high volatility 
between the different months and years. 

## Recommendations

Since that 20% of the customer base contributes a large percentage of the total sales, 
the company should focus on these individuals to drive up revenue. They should spend more 
on advertising campaigns to increase the longevity of these customers. It should prioritize 
retention strategies for high-value customers, such as targeted promotions, loyalty programs, 
and personalized marketing campaigns. The RFM Analysis Sheet shows a table visualization of the 
different types of customers based on their RFM score. The customer id slicer can be used 
to view a customer or group of customers and their rating. Stakeholders may use this to 
target active customers as well as reach out to underperforming ones. Since the UK is the 
top performing country, the company should focus its business operations there. However, it 
may be of use to target lower performing countries like Canada and the United States to generate 
more sales there as well. 







