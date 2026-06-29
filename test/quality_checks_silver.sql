/*
=========================================================================
Quality Checks
=========================================================================
Script Purpose:
  Thiscript performs various quality checks for data consistency, accuracy,
  and tandardization across the 'silver' schema. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.
Usage Notes:
   -Run these checks after data loading Silver Layer.
   -Investigate and resolve any discrepancies found during the checks.
=========================================================================
*/
-- data cleaning and inserting crm_cust_info

INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)
select 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 ELSE 'n/a'
END cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'n/a'
END cst_gndr,
cst_create_date
from (

SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last 
FROM bronze.crm_cust_info
)t WHERE flag_last = 1 AND cst_id IS NOT NULL;


-- data checks

-- check for nulls or duplicates in primary key
SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
Having COUNT(*) > 1 OR cst_id IS NULL

-- check for unwanted spaces

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

select * from bronze.crm_cust_info

--Data standardization & consitency

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;



-- cross checking after insertion
-- 1. The Duplicate Check (Ensure NO Row is Loaded Twice)
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info 
GROUP BY cst_id 
HAVING COUNT(*) > 1;

-- 2. The Unique Distinct Count Check
SELECT 
    (SELECT COUNT(DISTINCT cst_id) FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL) AS Unique_Bronze_Count,
    (SELECT COUNT(*) FROM silver.crm_cust_info) AS Total_Silver_Count;
	
-- 3. Check for Data Integrity (No Bleeding Text)
SELECT cst_marital_status, cst_gndr, COUNT(*) AS Record_Count
FROM silver.crm_cust_info
GROUP BY cst_marital_status, cst_gndr;



-- data cleaning and inserting table crm_prd_info

INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, 
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN  'M' THEN 'Mountain'
	WHEN  'R' THEN 'Road'
	WHEN  'S' THEN 'Other Sales'
	WHEN  'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 
AS DATE
) AS prd_end_dt -- Calculate end date as one day before teh next start date
FROM bronze.crm_prd_info




-- duplicates or null
SELECT
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- we need to add this column to  erp_px_cat_g1v2 so these table column data needs to match
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') NOT IN 
(select distinct id from bronze.erp_px_cat_g1v2)

-- we need to add this column to  sls_prd_key so these table column data needs to match
WHERE SUBSTRING(prd_key,7,LEN(prd_key))  IN
(select sls_prd_key from bronze.crm_sales_details)

-- check for unwanted spaces
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for nulls or negative numbers
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- data standardization and consistency
select DISTINCT prd_line
FROM silver.crm_prd_info


-- check for Invalid date orders
select *
from bronze.crm_prd_info
where prd_end_dt < prd_start_dt -- end date must not be earlier than the start date

select *
from silver.crm_prd_info
where prd_end_dt < prd_start_dt

--
SELECT
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 as prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')


select *
from silver.crm_prd_info







-- data cleaning and inserting table crm_slaes_details
TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
	 ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
	 ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
	 ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN (sls_sales * 1.0) / NULLIF(sls_quantity,0)
	ELSE sls_price
END sls_price
FROM bronze.crm_sales_details



--WHERE sls_ord_num != TRIM (sls_ord_num)
--WHERE sls_prd_key NOT IN (select prd_key FROM silver.crm_prd_info)
--WHERE sls_cust_id NOT IN (select cst_id FROM silver.crm_cust_info)

--negative numbers or zeros can't be cast to a date
select
NULLIF(sls_order_dt,0) sls_order_dt
from bronze.crm_sales_details
--where sls_order_dt < 0
where sls_order_dt <=0 
OR LEN(sls_order_dt) !=8 
-- NULLIF() returns null if two given values are equal,otherwise it returns the first expression
--in this scenario the length of the date must be 8 or less than 8
-- check for outliers by validating the boundaries of the data range
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101


-- for shipping date
select
NULLIF(sls_ship_dt,0) sls_ship_dt
from bronze.crm_sales_details
--where sls_order_dt < 0
where sls_ship_dt <=0 
OR LEN(sls_ship_dt) !=8 
-- NULLIF() returns null if two given values are equal,otherwise it returns the first expression
--in this scenario the length of the date must be 8 or less than 8
-- check for outliers by validating the boundaries of the data range
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101

--due date
select
NULLIF(sls_due_dt,0) sls_due_dt
from bronze.crm_sales_details
--where sls_order_dt < 0
where sls_due_dt <=0 
OR LEN(sls_due_dt) !=8 
-- NULLIF() returns null if two given values are equal,otherwise it returns the first expression
--in this scenario the length of the date must be 8 or less than 8
-- check for outliers by validating the boundaries of the data range
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

-- order date must always be earlier than the shipping date or due date
select
*
from bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt >sls_due_dt


-- BUSINESS RULE
-- sales = quantity * price
-- must be positive , not allowed negative,zeros, null

SELECT DISTINCT
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0 
ORDER BY sls_sales,sls_quantity,sls_price

--RULES
-- If sales is negative,zero or null derive it using quantity and price.
-- if price is zero or null, calculate it using sales and quantity
-- if price is neagative, convert it to a positive value



-- checks after inserting data into silver
select
*
from silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales <= 0 OR sls_quantity <=0 OR sls_price <= 0
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
ORDER BY sls_sales, sls_quantity,sls_price
   

select * from silver.crm_sales_details;



-- data cleaning and inserting table erp_cust_az12
INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END cid,
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN('F','Female')  THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN('M','Male')	THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;



select DISTINCT
bdate
from bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

select distinct
gen,
CASE WHEN UPPER(TRIM(gen)) IN('F','Female')  THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN('M','Male')	THEN 'Male'
	 ELSE 'n/a'
END AS gen
from bronze.erp_cust_az12

-- checks after inserting data into silver

select DISTINCT
bdate
from silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

select distinct
gen,
CASE WHEN UPPER(TRIM(gen)) IN('F','Female')  THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN('M','Male')	THEN 'Male'
	 ELSE 'n/a'
END AS gen
from bronze.erp_cust_az12


select distinct
gen
from silver.erp_cust_az12


select * from silver.erp_cust_az12;



-- data cleaning and inserting table erp_loc_a101
INSERT INTO silver.erp_loc_a101(cid,cntry)
SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101


-- Data Standardization & consistency
select distinct cntry
from silver.erp_loc_a101
ORDER BY cntry

select * from silver.erp_loc_a101


-- data cleaning and inserting table erp_loc_a101
INSERT INTO silver.erp_px_cat_g1v2(
id,
cat,
subcat,
maintenance)
SELECT  
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;



select cat_id from silver.crm_prd_info

-- Check for unwanted spaces
SELECT * from bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
maintenance
from bronze.erp_px_cat_g1v2

SELECT * FROM silver.erp_px_cat_g1v2
