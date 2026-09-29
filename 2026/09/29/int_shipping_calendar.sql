CREATE OR REPLACE TABLE bi.mark_dev.int_shipping_calendar AS

WITH working_days AS (SELECT * FROM bi.google_sheets.working_days_by_market)
    ,bank_holidays AS (SELECT * FROM bi.google_sheets.bank_holidays_by_market)

    ,date_spine AS (
    -- 2020-01-01 to 2030-12-31 (4,018 days). Widen if your history goes back further.
    SELECT DATEADD('day', ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, '2020-01-01'::DATE) AS cal_date
    FROM TABLE(GENERATOR(ROWCOUNT => 4018))
),

combos AS (
    SELECT DISTINCT market_code, shipping_service
    FROM working_days
),

holidays AS (
    -- Collapse any dates with two holidays so they can't duplicate rows
    SELECT market_code, region, holiday_date,
           LISTAGG(holiday_name, ' / ') AS holiday_name
    FROM bank_holidays
    GROUP BY market_code, region, holiday_date
),

daily AS (
    SELECT
        c.market_code,
        c.shipping_service,
        d.cal_date,
        DAYOFWEEKISO(d.cal_date)                  AS iso_day_of_week,   -- 1 = Mon, 7 = Sun
        w.market_code IS NOT NULL                 AS has_config,
        COALESCE(
            CASE DAYOFWEEKISO(d.cal_date)
                WHEN 1 THEN w.mon WHEN 2 THEN w.tue WHEN 3 THEN w.wed
                WHEN 4 THEN w.thu WHEN 5 THEN w.fri WHEN 6 THEN w.sat
                WHEN 7 THEN w.sun
            END = 1, FALSE)                       AS is_service_day,
        h.holiday_date IS NOT NULL                AS is_bank_holiday,
        h.holiday_name,
        COALESCE(w.observes_bank_holidays = 'Y', FALSE) AS observes_bank_holidays,
        w.date_from,
        w.date_to
    FROM combos c
    CROSS JOIN date_spine d
    LEFT JOIN working_days w
      ON w.market_code      = c.market_code
      AND w.shipping_service = c.shipping_service
      AND d.cal_date >= w.date_from
      --AND (w.date_to IS NULL OR d.cal_date <= w.date_to)   -- date_to inclusive, NULL = current
    LEFT JOIN holidays h
      ON  h.market_code  = c.market_code
      AND h.region       = w.holiday_region
      AND h.holiday_date = d.cal_date
),

flagged AS (
    SELECT
        *,
        is_service_day AND NOT (is_bank_holiday AND observes_bank_holidays) AS is_working_day
    FROM daily
)

SELECT
    *,
    -- Running count of working days. The difference between two dates'
    -- values is the number of working days between them.
    SUM(IFF(is_working_day, 1, 0)) OVER (
        PARTITION BY market_code, shipping_service
        ORDER BY cal_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS working_day_seq
FROM flagged;