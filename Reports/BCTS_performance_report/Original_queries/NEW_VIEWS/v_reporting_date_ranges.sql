CREATE OR REPLACE VIEW bcts_staging.report_date_ranges AS
SELECT
    -- 1. Fiscal year start to 15th of current month or end of previous month if 15th hasn't passed
    CASE
        WHEN EXTRACT(MONTH FROM CURRENT_DATE) < 4 
        THEN DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '9 months' -- Previous fiscal year's April 1
        ELSE DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '3 months' -- Current fiscal year's April 1
    END AS fiscal_year_start_date,
    CASE
        WHEN EXTRACT(DAY FROM CURRENT_DATE) > 15 
        THEN DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '15 days' -- 15th of current month
        ELSE DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day' -- End of previous month
    END AS fiscal_year_end_date,

    -- 2. Most recent half month
    CASE
        WHEN EXTRACT(DAY FROM CURRENT_DATE) > 15 
        THEN DATE_TRUNC('month', CURRENT_DATE) -- Start of current month
        ELSE DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' + INTERVAL '15 days' -- 15th of previous month

    END AS half_month_start_date,
    CASE
        WHEN EXTRACT(DAY FROM CURRENT_DATE) > 15 
        THEN DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '15 days' -- 15th of current month
        ELSE DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day' -- End of current month
    END AS half_month_end_date,

    -- 3. Last finished 3 months
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 months' AS last_3_months_start_date,
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day' AS last_3_months_end_date,

    -- 4. Last finished 6 months
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '6 months' AS last_6_months_start_date,
    DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day' AS last_6_months_end_date;
