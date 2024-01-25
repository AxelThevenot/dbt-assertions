{%- macro assertions_filter(from_column='exceptions', exclude_list=none, include_list=none, reverse=false) -%}
{#-
    Generates an expression to filter rows based on assertions results.

    By default, each row with exception(s) will be filtered.
    You can change this behaviour specifying an exclude_list or include_list (not both).

    Args:
        from_column (optional[str]): Column to read the exceptions from.
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

    {{- adapter.dispatch('assertions_filter', 'dbt_assertions') (from_column, exclude_list, include_list, reverse) }}
{%- endmacro %}

{%- macro default__assertions_filter(from_column, exclude_list, include_list, reverse) -%}

{#- Check if both exclude_list and exclude_list are provided -#}
{%- if exclude_list is not none and exclude_list is not none -%}
    {{
        exceptions.raise_compiler_error(
            'exclude_list or exclude_list must be provided. Not both. Got (exclude_list: ' ~ exclude_list ~ ', exclude_list: ' ~ exclude_list ~ ')'
        )
    }}
{%- endif -%}

{#- Generate expression based on the presence of exclude_list or exclude_list -#}
{{- '' if reverse else 'NOT ' -}}
{%- if exclude_list is not none -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) assertion_ WHERE assertion_ NOT IN ('{{ exclude_list | join("\', \'")}}'))
{%- elif exclude_list is not none -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) assertion_ WHERE assertion_ IN ('{{ exclude_list | join("\', \'")}}'))
{%- else -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) assertion_ WHERE TRUE)
{%- endif -%}

{%- endmacro %}
