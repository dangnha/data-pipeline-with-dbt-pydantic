select
    r.return_id,
    r.order_id,
    r.product_id,
    r.return_date,
    r.return_reason,
    r.return_quantity,
    r.refund_amount,
    oi.quantity as order_quantity,
    oi.unit_price as order_unit_price,
    p.product_name,
    p.category,
    p.segment
from {{ ref('stg_returns') }} r
left join {{ ref('stg_order_items') }} oi
    on r.order_id = oi.order_id and r.product_id = oi.product_id
left join {{ ref('stg_products') }} p on r.product_id = p.product_id
