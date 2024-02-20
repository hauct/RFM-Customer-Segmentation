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
rfm_score AS (
SELECT *,
CASE 
	WHEN recency >= '92' THEN '1'
	WHEN recency BETWEEN '62' AND '91' THEN '2'
	WHEN recency BETWEEN '31' AND '61' THEN '3'
	WHEN recency BETWEEN '1' AND '30' THEN '4'
END AS r,
CASE 
	WHEN frequency <= '2' THEN '1'
	WHEN frequency = '3' THEN '2'
	WHEN frequency = '4' THEN '3'
	WHEN frequency >= '5' THEN '4'
END AS f,
CASE 
	WHEN monetary <= '210000' THEN '1'
	WHEN monetary BETWEEN '210000' AND '266693' THEN '2'
	WHEN monetary BETWEEN '266694' AND '300000' THEN '3'
	WHEN monetary >= '300000' THEN '4'
END AS m
FROM rfm_cal
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
	WHEN rfm IN ('111', '112', '113', '114', '121', '122', '123') THEN 'Needs Attention'
END AS segment
FROM rfm_all
)

/* Count number of customers and revenue for each segment */
SELECT segment, COUNT(customer_id) as num_cus, SUM(monetary) as rev
FROM rfm_all