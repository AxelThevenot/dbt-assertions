{%- macro _assertions_expression(from_column, assertions) -%}
    {{- adapter.dispatch('_assertions_expression', 'dbt_assertions') (from_column, assertions) }}
{%- endmacro %}


{%- macro default___assertions_expression(from_column, assertions) -%}

ARRAY_CONCAT(
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression      = assertion_config.expression if '\n' not in assertion_config.expression else assertion_config.expression | indent(12) -%}
    {%- set description     = assertion_config.description -%}
    {%- set null_as_exception = 'FALSE' if (assertion_config.null_as_exception is not defined or assertion_config.null_as_exception is true) else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    IF(
        COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE,
        ['{{ assertion_id }}'],
        CAST([] AS ARRAY<STRING>)
    ),
    {%- endfor %}
    CAST([] AS ARRAY<STRING>)
) AS {{ from_column }}

{%- endmacro %}
