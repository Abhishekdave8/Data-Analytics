####################################### Project: Atliq Hardware - Sales insights #################################################

/* 
In This project, I've Collected a busineess problems from Ms. Wanda, Product Owner of the company, solved it
and provided Solutions and insights on company's sales.

Techniques Used: Joins, CTE's, Temporary tables, Views, Windows Function, Aggregate Function, Data Type Conversion, 
				 Stored Procedures, UDFs, Perfomance Optimization, 
*/

##################################### Bussiness Model - Atliq Hardware ############################################
/* 
Atliq Hardware is a company which supplies computer hardware and pheripherals to different customers in many regions of the world.
Atliq has its head office in Delhi and has many reginal offices across India. 
Sales Platforms : It has two Platforms for its sales Brick & Mortar (stores) and E-Commerce websites. 
Sales Channel: They sell their products by to retailers like croma, amzon etc; second by direct channel for which they have their own
stores Atilq Exclusive and online platform Atliq e store; they sell their products to distributors as well like Neptune in China 
*/


######################################## Profit and Loss Statement ##################################################
/*
Gross Price: A base price of any product decided by the company

Pre-Invoice Deduction: Yearly discount agreements made at the begining of a financial Year

Net Invoice Sales : Gross Price - Pre-invoice Deductions

Post-Invoice Deduction: Promotional Offer (offers) + Placement Fees (to place a product at a prime location of any store)
						+ Performance Rebate (Rebate gave on good sales perfomance of the customers)
                        
Net Sales: Net-Invoice Sales - Post-Invoice Deductions.a; also called Revenue

Cost of Goods Services COGS: Manufacturing cost + fright + other cost

Gross Margin: Net Sales - COGS*/ 

############################################## Loading a Database into Mysql ######################################

#loading Database from:

####################################################  Business Problems  ###########################################

###################### Bussiness Problem 1:  Generating a Report

/*Product Owner of Company want to generate a report of individual product sales (aggregated on montly basis at the product code level)
for croma India customer for FY 2021 so that they can track individual product sales and run further product analytics on it in excel
The report should have the following fields:
		1. Month
		2. Product Name
		3. Varient
		4. Sold Quantity
		5. Gross Price Per Iten
		6. Gross Price Total*/

# Solution


# Creating UDF - get_fiscal_year,This will convert my calander dates into financial year of the company.
select year(date_add(date, interval 4 month))from fact_sales_monthly; # This is the concept of converting calandar dates into financial year


select
		s.date,s.product_code,
		p.product, p.variant,
		s.sold_quantity,
        g.gross_price,
        round(g.gross_price * s.sold_quantity,2) as gross_price_total

from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
join fact_gross_price g
on g.product_code = s.product_code and 
   g.fiscal_year = get_fiscal_year(s.date)
where 
	customer_code = "90002002" and # 90002002 is the customor code of Croma India
    get_fiscal_year(date) = 2021
order by date asc;

# Created a Stored Procedure as well -  get_fiscal_Year_gross_sales

select * from fact_sales_monthly 
where 
	customer_code = "90002002" and 
    get_fiscal_year(date) = 2021 and 
    month(date) in(10,11,12)
    #get_fiscal_quarter(date) = 'Q4'
order by date asc;






#################### Bussiness Problem 2: Generating same report but for the Quarter 4 of the fiscal year 2021






############################ Bussiness Problem 3:  Generating a Report (Month and Respective Total Gross Sales)

/*product owner needs an aggregate monthly gorss sales report for CROMA INDIA customer so that they can track 
how much sales this particular customer is generating in Atliq and manage relationships accordingly.
The report should have 
1. Month
2. Total Gross Sales Amount to CROMA INDIA in this month*/ 

# Solution:
select
	s.date,
    sum(g.gross_price * s.sold_quantity) as gross_price_total 
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code and
   g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by s.date
order by s.date asc;

# Created a stored procedure for this as well -  monthly_gross_sales_for_customers

############################ Bussiness Problem 4:  Generating a Report

/* 
Generate a yearly report for Croma India where there are two columns
1. Fiscal Year
2. Total Gross Sales amount In that year from Croma
*/

select
            get_fiscal_year(date) as fiscal_year,
            sum(round(sold_quantity*g.gross_price,2)) as yearly_sales
	from fact_sales_monthly s
	join fact_gross_price g
	on 
	    g.fiscal_year=get_fiscal_year(s.date) and
	    g.product_code=s.product_code
	where
	    customer_code=90002002
	group by get_fiscal_year(date)
	order by fiscal_year;
    
# Created Stored Procedure for this as well 


############################ Bussiness Problem 5:  Generating a Report (Providing market with a badge as per sales)
/* 
Create a stored procedure that can determine the market badge based on the following logic :
if total sold quantity > 5 million that market is considerd gold else it is silver

my input will be 
1. market
2. fiscal Year
and output
1. market badge
*/ 

# Solution 1 By creating a stored procedure 

declare qty int default 0;
               
        # set default market to be India
        if in_markt = "" then
			set in_markt = "India";
		end if;
        
         # it retrive total qty for a given year and market 
		select
			sum(sold_quantity) into qty
		from fact_sales_monthly s
		join dim_customer c
		on s.customer_code = c.customer_code
		where 
			get_fiscal_year(s.date) = in_fiscal_year and
			c.market = in_markt
		group by c.market;
        
        
        # determine market badge
        
        if qty >5000000 then
			set out_badge = "Gold";
		else
			set out_badge = "Silver";
		end if;


END;


# Solution 2 By creating a new column

select
	c.market,
    sum(s.sold_quantity),
case
	when sum(s.sold_quantity) > 5000000 then "Gold"
    else "silver"
end as market_badge
	
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code

group by market
order by sum(s.sold_quantity) desc;


############################ Bussiness Problem 6: Calculate Net Sales

# Calculate Net Invoice sales ( gross sales - new invoice deductions) 

with cte1 as (
select
	s.date, s.fiscal_year,  s.product_code, d.product, d.variant, s.sold_quantity, g.gross_price as gross_price_per_item,
    (s.sold_quantity * g.gross_price) as total_gross_price, pr.pre_invoice_discount_pct
from fact_sales_monthly s


join fact_gross_price g
on s.product_code = g.product_code and
s.fiscal_year = g.fiscal_year

join fact_pre_invoice_deductions pr
on s.customer_code = pr.customer_code and
	s.fiscal_year = pr.fiscal_year
    
    
    
join dim_product d
on d.product_code = s.product_code

where 
	s.fiscal_year = 2021
limit 1000000
)
select *,
		(total_gross_price - (total_gross_price * pre_invoice_discount_pct)) as net_invoice_sales
 from cte1
;

/*
# Doint the above by sql database views viz called database views;  it is a virtual table,
physical table are saved on disks and virtual tables are derived virtualy on the fly by running some queries on some physical tables.
Benifits of Views are
1. simplify queries
2. It gives you central place to store your logic which means you have less erros. 
3. user access control - you can give access to certain veiws to certain users so that they are not accessing your database directly 
*/
select *,
		(1-pre_invoice_discount_pct) * total_gross_price as net_invoice_sales, # total_gross_price - total_gross_price * pre_invoice_discount_pct
        (po.discounts_pct + other_deductions_pct) as post_discount_pct
from sales_perinv_discount sp
join fact_post_invoice_deductions po
on po.customer_code = sp.customer_code and
   po.product_code = sp.product_code and
   po.date = sp.date
;

# I have created a view with the above formula using sp.coulmn names.a

select *,
		(1-post_discount_pct)*net_invoice_sales as Net_sales		
from sales_postinv_discount;

############################ Bussiness Problem 7

/*
As a product owner, I want a report for top markets, products, customers by net sales for a given financial year so
that I can have a holistic view of our financial performance and can take appropriate actions to address any
potential issues.
We will probably write stored proc for this as we will need this report going forward as well.
  1. Report for top markets
  2. Report for top Products,
*/
 # 1
select
	market,
    sum(Net_sales)
    
from net_sales
group by market
order by sum(Net_sales) desc
limit 3;

# lets decrease some time by filtering a data i.e by using where

select
	market,
    round(sum(net_sales)/1000000,2) as net_sales_in_millions
from net_sales
where fiscal_year = 2019
group by market
order by net_sales_in_millions desc
limit 5;



# create stored procedure as well. 
#2.

select 
	market,
	product,
    round(sum(net_sales)/1000000,2) as net_sales_in_million
from net_sales
where fiscal_year = 2021 and market = 'india'
group by product
order by sum(net_sales) desc
limit 5;

# create a stored procedure for this as well 
	

#3

select
	dc.customer,
	round(sum(ns.net_sales)/1000000,2) as net_sales_in_millions
from net_sales ns
join dim_customer dc
on ns.customer_code = dc.customer_code
where fiscal_year = 2021
group by customer
order by net_sales_in_millions desc
limit 5;

# make a stored procedure of above all queries. 


############################ Bussiness Problem 8 : Calculate Forcast Accuracy Percentage

select * from fact_act_est;

select *,
		sum((forcast_quantity - sold_quantity)) as net_error,
        sum((forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as `net_error_pct`,
        sum(abs(forcast_quantity - sold_quantity)) as abs_error,
        sum(abs(forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as abs_error_pct # it will gives us an absolute value
from  fact_act_est s
where s.fiscal_year = 2021
group by customer_code
order by abs_error_pct desc;

# to calcute forcast accuracy we need to do (1-abs_erro_pct) which is derived column in above query so either we use cte or create view.
with cte1 as(
select *,
		sum((forcast_quantity - sold_quantity)) as net_error,
        sum((forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as `net_error_pct`,
        sum(abs(forcast_quantity - sold_quantity)) as abs_error,
        sum(abs(forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as abs_error_pct # it will gives us an absolute value
from  fact_act_est s
where s.fiscal_year = 2021
group by customer_code
)

select *,
		(100-abs_error_pct) as forcast_accuracy_pct
from cte1
order by forcast_accuracy_pct;

# by running above code some of my forcast accuracy pct is is negative because it cant be negative it can be zero but not negative
# is is because my abs eoor pct is above zero and by (100-abs_error_pct) it is comming in negative thats why we do
# if(abs_error_pct >100,0,(100-abs_error_pct)

with cte1 as(
select *,
		sum((forcast_quantity - sold_quantity)) as net_error,
        sum((forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as `net_error_pct`,
        sum(abs(forcast_quantity - sold_quantity)) as abs_error,
        sum(abs(forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as abs_error_pct # it will gives us an absolute value
from  fact_act_est s
where s.fiscal_year = 2021
group by customer_code
)

select *,
		if (abs_error_pct >100,0, (100-abs_error_pct)) as forcast_accuracy_pct
from cte1
order by forcast_accuracy_pct;

# if you want to print customer name then join it by dim_cutomer

with cte1 as(
select *,
		sum((forcast_quantity - sold_quantity)) as net_error,
        sum((forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as `net_error_pct`,
        sum(abs(forcast_quantity - sold_quantity)) as abs_error,
        sum(abs(forcast_quantity - sold_quantity))*100/sum(forcast_quantity) as abs_error_pct # it will gives us an absolute value
from  fact_act_est s
where s.fiscal_year = 2021
group by customer_code
)
select c.*,
		d.customer,
        d.market,
        
		if (abs_error_pct >100,0, (100-abs_error_pct)) as forcast_accuracy_pct
from cte1 c
join dim_customer d
using(customer_code)
order by forcast_accuracy_pct desc;


############################################ The End ###########################################################

    
    
