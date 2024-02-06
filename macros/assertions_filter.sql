{%- macro assertions_filter(column='exceptions', exclude_list=none, include_list=none, reverse=false) -%}
{#-
    Generates an expression to filter rows based on assertions results.

    By default, each row with exception(s) will be filtered.
    You can change this behaviour specifying an exclude_list or include_list (not both).

    Args:
        column (optional[str]): Column to read the exceptions from.
        exclude_list (optional[list[str]]): Assertions to exclude in the filter.
        include_list (optional[list[str]]): Assertions to include in the filter.
        reverse (optional[bool]): returns rows without exception when `reverse=false`,
            and rows with exceptions when `reverse=true`.

    Returns:
        str: An expression to filter rows based on their assertions.

    Example Usage:
        To filter rows based on specific exceptions:

        SELECT *
        FROM my_table
        WHERE {{ assertions_filter(include_list=['assert_1', 'assert_2']) }}

    Note: This is not compatible with materialized view.
-#}

    {{- adapter.dispatch('assertions_filter', 'dbt_assertions') (column, exclude_list, include_list, reverse) }}
{%- endmacro %}

{%- macro default__assertions_filter(column, exclude_list, include_list, reverse) -%}

{#- Check if both exclude_list and include_list are provided -#}
{%- if exclude_list is not none and include_list is not none -%}
    {{
        exceptions.raise_compiler_error(
            'exclude_list or include_list must be provided. Not both.'
            ~ 'Got (exclude_list: ' ~ exclude_list 
            ~ ', include_list: ' ~ include_list ~ ')'
        )
    }}
{%- endif -%}

{#- Generate filtering expression  -#}
{{- '' if reverse else 'NOT ' -}}
{%- if exclude_list is not none -%}
EXISTS (
    SELECT 1
    FROM UNNEST({{ column }}) assertion_
    WHERE assertion_ NOT IN ('{{ exclude_list | join("\', \'")}}')
)
{%- elif include_list is not none -%}
EXISTS (
    SELECT 1
    FROM UNNEST({{ column }}) assertion_
    WHERE assertion_ IN ('{{ include_list | join("\', \'")}}')
)
{%- else -%}
EXISTS (
    SELECT 1
    FROM UNNEST({{ column }}) assertion_
    WHERE TRUE
)
{%- endif -%}

{%- endmacro %}


{%- macro snowflake__assertions_filter(column, exclude_list, include_list, reverse) -%}

{#- Check if both exclude_list and include_list are provided -#}
{%- if exclude_list is not none and include_list is not none -%}
    {{
        exceptions.raise_compiler_error(
            'exclude_list or include_list must be provided. Not both.'
            ~ 'Got (exclude_list: ' ~ exclude_list 
            ~ ', include_list: ' ~ include_list ~ ')'
        )
    }}
{%- endif -%}

{#- Generate filtering expression  -#}
{{- 'NOT ' if reverse else '' -}}
{%- if include_list is not none -%}
ARRAY_SIZE(ARRAY_INTERSECTION({{ column }},ARRAY_CONSTRUCT('{{ include_list | join("\', \'")}}'))) = 0
{%- elif exclude_list is not none -%}
ARRAY_SIZE(ARRAY_EXCEPT({{ column }},ARRAY_CONSTRUCT('{{ exclude_list | join("\', \'")}}'))) = 0
{%- else -%}
ARRAY_SIZE({{ column }}) = 0
{%- endif -%}

{%- endmacro %}


{%- macro duckdb__assertions_filter(column, exclude_list, include_list, reverse) -%}

{#- Check if both exclude_list and include_list are provided -#}
{%- if exclude_list is not none and include_list is not none -%}
    {{
        exceptions.raise_compiler_error(
            'exclude_list or include_list must be provided. Not both.'
            ~ 'Got (exclude_list: ' ~ exclude_list 
            ~ ', include_list: ' ~ include_list ~ ')'
        )
    }}
{%- endif -%}

{#- Generate filtering expression  -#}
{{- 'NOT ' if reverse else '' -}}
{%- if include_list is not none -%}
LEN(ARRAY_INTERSECT({{ column }},['{{ include_list | join("\', \'")}}'])) = 0
{%- elif exclude_list is not none -%}
LEN(ARRAY_EXCEPT({{ column }},['{{ exclude_list | join("\', \'")}}'])) = 0
{%- else -%}
LEN({{ column }}) = 0
{%- endif -%}

{%- endmacro %}