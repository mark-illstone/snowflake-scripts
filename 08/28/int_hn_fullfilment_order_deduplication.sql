

create or replace table bi.mark_dev.int_hn_fullfilment_order_deduplication as

WITH fulfillment_order AS (SELECT * FROM bi.fivetran_shopify_test_19.fulfillment_order)

SELECT
      id::integer as shipment_id, 
      order_id::integer as order_id,
      created_at::timestampntz  as created_at, 
      updated_at::timestampntz  as updated_at, 
      fulfill_by::timestampntz  as fulfill_by, 
      assigned_location_name::varchar as location, 
      delivery_method_min_delivery_date_time::timestampntz  as delivery_method_min_delivery_date_time, 
      delivery_method_max_delivery_date_time::timestampntz  as delivery_method_max_delivery_date_time
FROM fulfillment_order os
where not _fivetran_deleted
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id, location ORDER BY updated_at DESC) = 1;