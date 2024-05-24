

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
WITH vendor_products AS (
    SELECT 
        v.vendor_name,
        p.product_name,
        vi.original_price
    FROM 
        vendor_inventory vi
    JOIN 
        vendor v ON vi.vendor_id = v.vendor_id
    JOIN 
        product p ON vi.product_id = p.product_id
),
customer_count AS (
    SELECT 
        COUNT(DISTINCT customer_id) AS total_customers
    FROM 
        customer
),
salesresult as (
	select 
		vp.vendor_name,
		vp.product_name,
		vp.original_price * 5 * cc.total_customers AS total_revenue
	from 
		vendor_products as vp
	cross join 
		customer_count cc
)

SELECT 
    vendor_name,
    product_name,
    total_revenue
FROM 
    salesresult
group by 
	 vendor_name,
    product_name,
    total_revenue


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
CREATE TABLE product_units AS
SELECT 
    product_id,
    product_name,
    product_size,
    product_qty_type,
    product_category_id
FROM 
    product
WHERE 
    product_qty_type = 'unit';

ALTER TABLE product_units
ADD COLUMN snapshot_timestamp TIMESTAMP;

UPDATE product_units
SET snapshot_timestamp = CURRENT_TIMESTAMP;


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name, product_size, product_qty_type, product_category_id, snapshot_timestamp)
VALUES (101, 'Apple Pie', 'Large', 'unit', '12324231', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE product_name = 'Apple Pie'
AND product_category_id='12324231'


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

WITH last_quantity_per_product AS (
    SELECT 
        vi.product_id,
        COALESCE(vi.quantity, 0) AS last_quantity
    FROM 
        vendor_inventory vi
    WHERE 
        vi.market_date = (
            SELECT MAX(market_date)
            FROM vendor_inventory
            WHERE product_id = vi.product_id
        )
)

-- Step 2: Update the current_quantity in product_units
UPDATE product_units
SET current_quantity = (
    SELECT last_quantity
    FROM last_quantity_per_product
    WHERE last_quantity_per_product.product_id = product_units.product_id
)
WHERE product_id IN (
    SELECT product_id
    FROM last_quantity_per_product
);

