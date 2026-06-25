/*CAUTION : Creted multiple table with different Datatypes , remembered to remove non working table and keep the working one




*/

CREATE TABLE bronze.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);

GO

-- TABLE 1: Your Original Strict Type Table (with decimal fixes)
CREATE TABLE bronze.crm_sales_strict (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt DATE,
    sls_ship_dt  DATE,
    sls_due_dt   DATE,
    sls_sales    DECIMAL(18,2), -- Changed from INT to capture cents
    sls_quantity INT,
    sls_price    DECIMAL(18,2)  -- Changed from INT to capture cents
);

GO

-- TABLE 2: The Tolerant Text Table
CREATE TABLE bronze.crm_sales_tolerant (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  NVARCHAR(50),
    sls_order_dt NVARCHAR(50),
    sls_ship_dt  NVARCHAR(50),
    sls_due_dt   NVARCHAR(50),
    sls_sales    NVARCHAR(50),
    sls_quantity NVARCHAR(50),
    sls_price    NVARCHAR(50)
);

GO

-- TABLE 1: Your Original Strict Type Table (with decimal fixes)
CREATE TABLE bronze.crm_prd_info_strict(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost DECIMAL(18,2),
    prd_line NVARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
   );

GO

-- TABLE 2: The Tolerant Text Table
CREATE TABLE bronze.crm_prd_info_tolerant(
    prd_id NVARCHAR(50),
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost NVARCHAR(50),
    prd_line NVARCHAR(50),
    prd_start_dt NVARCHAR(50),
    prd_end_dt NVARCHAR(50)
   )

   GO
 -- TABLE 1: Your Original Strict Type Table (with decimal fixes)

CREATE TABLE bronze.srm_cust_az12_strict(
        cust_cid INT,
        cust_bdate DATE,
        cust_gen NVARCHAR(50)
        )

    GO
-- TABLE 2: The Tolerant Text Table
CREATE TABLE bronze.srm_cust_az12_tolerant(
        cust_cid NVARCHAR(50),
        cust_bdate NVARCHAR(50),
        cust_gen NVARCHAR(50)
        )
    GO

CREATE TABLE bronze.srm_loc_a101(
    loc_cid NVARCHAR(50),
    loc_country NVARCHAR(50)
    )

GO


CREATE TABLE bronze.srm_px_cat_g1v2(
    px_cat_id NVARCHAR(50),
    px_cat_cat NVARCHAR(50),
    px_cat_subcat NVARCHAR(50),
    px_cat_maintenance NVARCHAR(50)
    )
GO



