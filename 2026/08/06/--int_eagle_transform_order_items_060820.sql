--int_eagle_transform_order_items_06082026

create or replace table bi.mark_dev.int_eagle_transform_order_items_06082026 AS

WITH tmp_order_items AS (SELECT * FROM bi.mark_dev.int_order_items)

SELECT id
     , order_id
     , product_fk
     , price
     , gift_wrap
     , child_name
     , gender
     , ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY id) AS position
     , giftbox_sku
  FROM tmp_order_items