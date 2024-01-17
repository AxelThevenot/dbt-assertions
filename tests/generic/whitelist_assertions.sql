


{% test assertions_test(model, column_name, blacklist, whitelist, from_column, re_assert=False) %}

with validation as (
    SELECT *,
    {% if re_assert %}
        {{ dbt_assertions.assertions() }}
    {% endif %}
    FROM {{ model }}
)

SELECT * FROM validation WHERE {{ dbt_assertions.assertions_filter(reverse=true) }}

{% endtest %}