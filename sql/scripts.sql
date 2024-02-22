/* Caculate rfm score and segment for each customers */
WITH rfm_cal AS(
	SELECT customer_id, 
	   DATE_PART('day','2022-09-01'::timestamp - MAX(purchase_date::timestamp)) AS recency,
	   COUNT(DISTINCT purchase_date::timestamp) AS frequency,
	   SUM(gmv) AS monetary
	FROM transactions
	where customer_id <> 0 
	GROUP BY customer_id
	HAVING sum(gmv) <> 0),
rfm_score as (
select *,
NTILE(4) OVER (ORDER BY recency desc) as r,
NTILE(4) OVER (ORDER BY frequency asc) as f,
NTILE(4) OVER (ORDER BY monetary asc) as m
from rfm_cal
), 
rfm_all AS(
SELECT *, concat(r,f,m) AS rfm FROM RFM_score),
rfm_all_2 AS(
SELECT *,
CASE 
	WHEN rfm IN ('444', '443', '434', '344') THEN 'Champions'
	WHEN rfm IN ('442', '441', '432', '431', '433', '343', '342', '341') THEN 'Loyal Customer'
	WHEN rfm IN ('424', '423', '324', '323', '413', '414', '343', '334') THEN 'Potential Loyalist'
	WHEN rfm IN ('333', '332', '331', '313', '314') THEN 'Promising'
	WHEN rfm IN ('422', '421', '412', '411', '311', '321', '312', '322') THEN 'New Customer'
	WHEN rfm IN ('131', '132', '141', '142', '231', '232', '241', '242') THEN 'Price Sensitive'
	WHEN rfm IN ('244', '234', '243', '233', '224', '214', '213', '134', '144', '143', '133') THEN 'Needs Attention'
	WHEN rfm IN ('223', '221', '222', '211', '212', '124') THEN 'About to sleep'
	WHEN rfm IN ('111', '112', '113', '114', '121', '122', '123') THEN 'Lost Customer'
END AS segment
FROM rfm_all
)

/* Count number of customers and revenue for each segment */
SELECT segment, COUNT(customer_id) AS num, SUM(monetary) AS rev
FROM rfm_all_2
GROUP BY segment
ORDER BY NUM DESC