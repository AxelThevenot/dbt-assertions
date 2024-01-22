{{
    config(alias='downstream_model', materialized='table', enabled=false)
}}

SELECT
    site_id,
    site_trigram,
    open_date,
FROM {{ ref('dbt_assertions', 'basic_example_d_site') }}
-- Remove bad data: here only sites without ID.
WHERE {{ dbt_assertions.assertions_filter(blacklist=['site_id_is_not_null']) }}
