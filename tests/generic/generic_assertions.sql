{% test generic_assertions(model, column_name, from_column='errors', whitelist=none, blacklist=none, re_assert=False) %}

{{ config(severity = 'warn') }}

WITH 
    final AS (
        SELECT
            *,
            {{ dbt_assertions.assertions(from_column=from_column) if re_assert else '' }}
        FROM
            {{ model }}
    )

SELECT
    *
FROM
    final

WHERE {{ dbt_assertions.assertions_filter(reverse=true, blacklist=blacklist, whitelist=whitelist, from_column=from_column) }}

{% endtest %}