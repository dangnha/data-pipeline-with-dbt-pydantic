with daily_base as (
    select
        date,
        revenue,
        cogs,
        order_count,
        unique_customers,
        sessions,
        unique_visitors,
        page_views,
        bounce_rate,
        avg_session_duration_sec,
        traffic_source
    from {{ ref('int_daily_metrics') }}
),

daily_promos as (
    select
        o.order_date as date,
        count(distinct oi.promo_id) as active_promo_count
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_order_items') }} oi on o.order_id = oi.order_id
    where oi.promo_id is not null
    group by 1
),

daily_returns as (
    select
        o.order_date as date,
        count(distinct r.return_id) as return_count
    from {{ ref('stg_returns') }} r
    join {{ ref('stg_orders') }} o on r.order_id = o.order_id
    group by 1
)

select
    b.date,
    b.revenue,
    b.cogs,
    b.revenue - b.cogs as gross_margin,
    b.order_count,
    b.unique_customers,
    case when b.order_count > 0 then b.revenue / b.order_count else 0 end as avg_order_value,
    coalesce(dp.active_promo_count, 0) as active_promo_count,
    coalesce(dr.return_count, 0) as return_count,
    case when b.order_count > 0 then coalesce(dr.return_count, 0)::float / b.order_count else 0 end as return_rate,
    b.sessions,
    b.unique_visitors,
    b.page_views,
    b.bounce_rate,
    b.avg_session_duration_sec,
    b.traffic_source,
    avg(b.revenue) over (
        order by b.date rows between 6 preceding and current row
    ) as revenue_7d_avg,
    avg(b.revenue) over (
        order by b.date rows between 29 preceding and current row
    ) as revenue_30d_avg
from daily_base b
left join daily_promos dp on b.date = dp.date
left join daily_returns dr on b.date = dr.date
