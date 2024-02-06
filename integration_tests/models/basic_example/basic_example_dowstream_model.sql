{{
    config(alias='downstream_model', materialized='table')
}}

SELECT
    site_id,
    site_trigram,
    open_date
FROM {{ ref('basic_example_d_site') }}
-- Remove bad data: here only sites without ID.
WHERE {{ dbt_assertions.assertions_filter(include_list=['site_id_is_not_null']) }}
