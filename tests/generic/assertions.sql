{% test assertions_test(model, column_name, blacklist=none, whitelist=none, from_column='errors', re_assert=False) %}

WITH 
    final AS (
        SELECT
            *,
            {% dbt_assertions.assertions(from_column=from_column) if re_assert else '' %}
        FROM
            {{ model }}
    )

SELECT
    *
FROM
    final

WHERE {{ dbt_assertions.assertions_filter(reverse=true, blacklist=blacklist, whitelist=whitelist, from_column=from_column) }}

{% endtest %}