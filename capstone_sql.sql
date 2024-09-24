--ADET BAZLI EN AZ VE ÇOK SATILAN 5 ÜRÜN
select 	
		p.product_id,
		p.product_name,	
		sum(od.quantity) as total_quantity
		from order_details as od
	left join products as p
	 on p.product_id=od.product_id
			group by p.product_id
			order by total_quantity asc, desc
			limit 5
	
--AYLARA GÖRE NET KAZANÇ
select 
	to_char(order_date, 'YYYY-MM') AS year_month,
	sum(od.unit_price * od.quantity ) as net_revenue
		from orders as o
	left join order_details as od
	 on o.order_id=od.order_id
		group by year_month
		order by net_revenue
	
--AYLARA GÖRE SİPARİŞ SAYILARI
	
SELECT 
	to_char(order_date, 'YYYY-MM') AS year_month,
    count(order_id)
    from orders
		group by year_month
		order by year_month asc
DEVAM EDEN- ETMEYEN ÜRÜN SAYILARI
select discontinued, count(discontinued)
	from products
		group by discontinued

--FİYAT ARALIKLARINA GÖRE ÜRÜN SAYILARI

WITH PriceRanges AS (
    SELECT 
        product_id,
        product_name,
        unit_price,
        CASE
            WHEN unit_price BETWEEN 0 AND 25 THEN '0-25'
            WHEN unit_price BETWEEN 26 AND 50 THEN '26-50'
            WHEN unit_price BETWEEN 51 AND 75 THEN '51-75'
            WHEN unit_price BETWEEN 76 AND 100 THEN '76-100'
            ELSE '100+'
        END AS price_range
    FROM products
)
SELECT 
    price_range,
    COUNT(*) AS product_count
FROM PriceRanges
GROUP BY price_range
ORDER BY price_range asc;
KATEGORİ BAZLI ORTALAMA ÜCRET
select p.category_id,
	c.category_name,
   avg(p.unit_price) as average_unit_price
from 
    products as p
left join categories as c
on p.category_id = c.category_id
group by p.category_id,c.category_name
order by p.category_id

--KATEGORİ BAZLI TOPLAM SATIŞ
select 
	c.category_id,
	c.category_name,
	sum(od.unit_price * od.quantity ) as net_revenue
		from order_details as od
	left join products as p
	 on p.product_id=od.product_id
	left join categories as c
	on c.category_id=p.category_id	
		group by c.category_id,category_name
		order by c.category_id


--KATEGORİLERE GÖRE STOK
select
	p.category_id,
	c.category_name,
	sum(unit_in_stock) as stok
	from products as p
		left join categories as c
	on p.category_id=c.category_id
		group by p.category_id,c.category_name

--MÜŞTERİLERE YAPILAN İNDİRİM ORTALAMALARI VE SİPARİŞ BİLGİLERİ
	
select 
	o.customer_id,
	c.company_name,
	avg(discount) as indirim,
	count(distinct od.order_id) sipariş_sayısı,
	sum(revenue)
	from order_details as od
	left join orders as o
	on o.order_id=od.order_id
	left join customers as c
	on o.customer_id=c.customer_id
		group by o.customer_id,c.company_name
		order by indirim desc
limit 10
	
RFM ANALİZİ
	
CREATE OR REPLACE VIEW rfm_view AS
WITH RecencyCTE AS (
    SELECT 
        C.Customer_id,
        '1998-06-05'::date - MAX(O.Order_date) AS Recency
    FROM 
        Orders O
        LEFT JOIN Customers C ON O.Customer_id = C.Customer_id
    GROUP BY 
        C.Customer_id
),

FrequencyCTE AS (
    SELECT 
        C.Customer_id,
        COUNT(O.Order_id) AS Frequency
    FROM 
        Orders O
        JOIN Customers C ON O.Customer_id = C.Customer_id
    GROUP BY 
        C.Customer_id
),

MonetaryCTE AS (
    SELECT 
        C.Customer_id,
        SUM(OD.Unit_Price * OD.Quantity) AS Monetary
    FROM 
        Orders O
        JOIN Order_Details OD ON O.Order_id = OD.Order_id
        JOIN Customers C ON O.Customer_id = C.Customer_id
    GROUP BY 
        C.Customer_id
),

RFM_Scores AS (
    SELECT 
        R.Customer_id,
        NTILE(5) OVER (ORDER BY R.Recency DESC) AS Recency_Score,
        NTILE(5) OVER (ORDER BY F.Frequency) AS Frequency_Score,
        NTILE(5) OVER (ORDER BY M.Monetary) AS Monetary_Score
    FROM 
        RecencyCTE R
        JOIN FrequencyCTE F ON R.Customer_id = F.Customer_id
        JOIN MonetaryCTE M ON R.Customer_id = M.Customer_id
)

SELECT 
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    (CAST(recency_score AS TEXT) || 
     CAST(frequency_score AS TEXT) || 
     CAST(monetary_score AS TEXT)) AS rfm_segment
FROM 
    RFM_Scores;

SELECT 
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    rfm_segment,
    CASE
        WHEN rfm_segment ~ '^1[1-2]' OR rfm_segment ~ '^2[1-2]' THEN 'hibernating'
        WHEN rfm_segment ~ '^1[3-4]' OR rfm_segment ~ '^2[3-4]' THEN 'at_Risk'
        WHEN rfm_segment ~ '^[1-2]5' THEN 'cant_loose'
        WHEN rfm_segment ~ '^3[1-2]' THEN 'about_to_sleep'
        WHEN rfm_segment = '33' THEN 'need_attention'
        WHEN rfm_segment ~ '^[3-4][4-5]' THEN 'loyal_customers'
        WHEN rfm_segment = '41' THEN 'promising'
        WHEN rfm_segment = '51' THEN 'new_customers'
        WHEN rfm_segment ~ '^[4-5][2-3]' THEN 'potential_loyalists'
        WHEN rfm_segment ~ '^5[4-5]' THEN 'champions'
        ELSE 'undefined'
    END AS customer_segment
FROM 
    rfm_view

--SHİPPER PERFORMANS
select 
	s.shipper_id,
	s.company_name,
	count(o.ship_via) as gönderim_sayısı,
	avg (o.shipped_date-o.order_date) ort_gün,
	avg(o.freight) as ort_ucret
	from orders as o
		left join shippers as s
		on o.ship_via=s.shipper_id
	group by s.shipper_id
	order by s.shipper_id
	
--SİPARİŞ SAYILARINA GÖRE MÜŞTERİ TEMSİLCİLERİ
select 
	o.employee_id,
	first_name|| ' ' || last_name as name,
	count(distinct order_id) as sipariş_sayısı
		from orders as o
			left join employees as e
		on o.employee_id=e.employee_id
			group by o.employee_id,name
			order by sipariş_sayısı desc

--SİPARİŞ SAYILARINA GNE EN YÜKSEK MÜŞTERİLER
select 
	o.customer_id,
	c.company_name,
	c.country,
		count(distinct od.order_id) AS order_counts
	from orders as o
	left join order_details as od
     	on o.order_id=od.order_id
	left join customers as c
		on o.customer_id=c.customer_id
			group by o.customer_id, c.company_name,c.country
			order by order_counts desc
			limit 10
--TUTAR BAZLI EN ÇOK SATILAN 5 ÜRÜN

select 	
		p.product_id,
		p.product_name,	
		sum(od.unit_price * od.quantity) as net_revenue
		from order_details as od
	left join products as p
	 on p.product_id=od.product_id
			group by p.product_id
			order by net_revenue desc
			limit 5
	
--TUTAR BAZLI EN ÇOK SATIŞ YAPILAN MÜŞTERİLER
select 
	o.customer_id,
	c.company_name,
	c.country,
	SUM(od.unit_price * od.quantity) AS customer_revenue
	from orders as o
	left join order_details as od
     	on o.order_id=od.order_id
	left join customers as c
		on o.customer_id=c.customer_id
			group by o.customer_id, c.company_name,c.country
			order by customer_revenue desc
			limit 10

--TUTAR BAZLI EN ÇOK SATIŞ YAPAN SATIŞ TEMSİLCİLERİ

select 
	o.employee_id,
	e.first_name|| ' ' ||e.last_name as name,
	et.territory_id,
	e.title,
	SUM(od.unit_price * od.quantity * (1 - od.discount)) as kazanç
		from order_details as od
		left join orders as o
			on od.order_id=o.order_id
		left join employees as e
			on o.employee_id=e.employee_id
		left join employeeterritories as et
			on e.employee_id=et.employee_id
				group by o.employee_id,name, e.title,et.territory_id
				order by kazanç desc
	
--ÜLKELER GÖRE ORTALAMA GÖNDERİM ÜCRETİ
select 
	ship_country,
	avg(freight) as ucret
	from orders
		group by ship_country
		order by ucret
ÜLKELER GÖRE ORTALAMA GÖNDEİM SÜRESİ
select 
	ship_country,
	avg(shipped_date - order_date) as days
	from orders
		group by ship_country
		order by days

--ÜLKELERE GÖRE KAZANÇ MİKTARLARI
select 
	ship_country,
	sum(od.unit_price * od.quantity ) as net_revenue
		from orders as o
	left join order_details as od
	 on o.order_id=od.order_id
		group by ship_country
		order by net_revenue desc


	



