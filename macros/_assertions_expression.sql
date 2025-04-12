{%- macro _assertions_expression(column, assertions) -%}
    {{- adapter.dispatch('_assertions_expression', 'dbt_assertions') (column, assertions) }}
{%- endmacro %}


{%- macro default___assertions_expression(column, assertions) -%}

ARRAY_CONCAT(
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression =
        assertion_config.expression
        if '\n' not in assertion_config.expression
        else assertion_config.expression | indent(12) -%}

    {%- set description= assertion_config.description -%}
    {%- set null_as_exception =
        'FALSE'
        if (assertion_config.null_as_exception is not defined
            or assertion_config.null_as_exception is true)
        else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    IF(
        COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE,
        ['{{ assertion_id }}'],
        CAST([] AS ARRAY<STRING>)
    ),
    {%- endfor %}
    CAST([] AS ARRAY<STRING>)
) AS {{ column }}

{%- endmacro %}


{%- macro snowflake___assertions_expression(column, assertions) -%}

ARRAY_CONSTRUCT_COMPACT(
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression =
        assertion_config.expression
        if '\n' not in assertion_config.expression
        else assertion_config.expression | indent(12) -%}

    {%- set description= assertion_config.description -%}
    {%- set null_as_exception =
        'FALSE'
        if (assertion_config.null_as_exception is not defined
            or assertion_config.null_as_exception is true)
        else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    IFF(
        COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE,
        '{{ assertion_id }}',
        CAST(NULL AS STRING)
    ),
    {%- endfor %}
    CAST(NULL AS STRING)
) AS {{ column }}

{%- endmacro %}


{%- macro duckdb___assertions_expression(column, assertions) -%}

LIST_DISTINCT([
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression =
        assertion_config.expression
        if '\n' not in assertion_config.expression
        else assertion_config.expression | indent(12) -%}

    {%- set description= assertion_config.description -%}
    {%- set null_as_exception =
        'FALSE'
        if (assertion_config.null_as_exception is not defined
            or assertion_config.null_as_exception is true)
        else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    CASE WHEN COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE
        THEN '{{ assertion_id }}'
        ELSE NULL
    END,
    {%- endfor %}
]) AS {{ column }}

{%- endmacro %}

{%- macro databricks___assertions_expression(column, assertions) -%}

ARRAY_DISTINCT(ARRAY(
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression =
        assertion_config.expression
        if '\n' not in assertion_config.expression
        else assertion_config.expression | indent(12) -%}

    {%- set description= assertion_config.description -%}
    {%- set null_as_exception =
        'FALSE'
        if (assertion_config.null_as_exception is not defined
            or assertion_config.null_as_exception is true)
        else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    IF(
        COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE,
        '{{ assertion_id }}',
        string(null)
    ){% if not loop.last %},{% endif %}
    {%- endfor %}
)) AS {{ column }}

{%- endmacro %}

{%- macro redshift___assertions_expression(column, assertions) -%}

ARRAY_FLATTEN(
    ARRAY(
        {%- for assertion_id, assertion_config in assertions.items() %}
        {%- set expression =
            assertion_config.expression
            if '\n' not in assertion_config.expression
            else assertion_config.expression | indent(12) -%}
        {%- set description= assertion_config.description -%}
        {%- set null_as_exception =
            'FALSE'
            if (assertion_config.null_as_exception is not defined
                or assertion_config.null_as_exception is true)
            else 'TRUE' %}
        /* {{ assertion_id }}: {{ description }} */
        CASE WHEN COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE
            THEN ARRAY('{{ assertion_id }}')
            ELSE ARRAY()
        END,
        {%- endfor %}
        ARRAY()
    )
) AS {{ column }}

{%- endmacro %}

{%- macro athena___assertions_expression(column, assertions) -%}

    ARRAY[
        {%- for assertion_id, assertion_config in assertions.items() %}
        {%- set expression =
            assertion_config.expression
            if '\n' not in assertion_config.expression
            else assertion_config.expression | indent(12) -%}
        {%- set description = assertion_config.description -%}
        {%- set null_as_exception =
            'FALSE'
            if (assertion_config.null_as_exception is not defined
                or assertion_config.null_as_exception is true)
            else 'TRUE' %}
        /* {{ assertion_id }}: {{ description }} */
        IF(
            COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE,
            '{{ assertion_id }}',
            NULL
        ),
        {%- endfor %}
        NULL
    ]
 AS {{ column }}

{%- endmacro %}
 



{%- macro clickhouse___assertions_expression(column, assertions) -%}

arrayConcat([
    {%- for assertion_id, assertion_config in assertions.items() %}

    {%- set expression =
        assertion_config.expression
        if '\n' not in assertion_config.expression
        else assertion_config.expression | indent(12) -%}

    {%- set description= assertion_config.description -%}
    {%- set null_as_exception =
        'FALSE'
        if (assertion_config.null_as_exception is not defined
            or assertion_config.null_as_exception is true)
        else 'TRUE' %}

    /* {{ assertion_id }}: {{ description }} */
    CASE WHEN COALESCE({{ expression }}, {{ null_as_exception }}) = FALSE
        THEN '{{ assertion_id }}'
        ELSE CAST(NULL AS STRING)
    END,
    {%- endfor %}
]) AS {{ column }}

{%- endmacro %}