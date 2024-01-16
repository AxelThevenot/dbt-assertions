{%- macro assertions_filter(from_column='errors', whitelist=none, blacklist=none, reverse=false) -%}
{#-
    Generates an expression to filter rows based on errors.

    It will returns an expression to filter the rows without any error by default.
    You can change this default behaviour specifying a whitelist or blacklist (not both).

    Args:
        whitelist (optional[list[str]]): A list of error IDs to whitelist.
            If provided, only rows with with no error, ignoring whitelist error IDs, will be included.
        blacklist (optional[list[str]]): A list of error IDs to blacklist.
            If provided, rows with at least one of these error IDs will be excluded.
        reverse (optional[bool]): returns errorless rows when `reverse=false` and error rows when `reverse=true`.

    Returns:
        str: An expression to filter rows based on their errors.

    Example Usage:
        To filter rows based on a whitelist:

        SELECT *
        FROM my_table
        WHERE {{ assertions_filter(whitelist=['error_1', 'error_2']) }}

    Note: This is not compatible with materialized view.
-#}

    {{- adapter.dispatch('assertions_filter', 'dbt_assertions') (from_column, whitelist, blacklist, reverse) }}
{%- endmacro %}

{%- macro default__assertions_filter(from_column, whitelist, blacklist, reverse) -%}

{#- Check if both whitelist and blacklist are provided -#}
{%- if whitelist is not none and blacklist is not none -%}
    {{
        exceptions.raise_compiler_error(
            'Whitelist or blacklist must be provided. Not both. Got (whitelist: ' ~ whitelist ~ ', blacklist: ' ~ blacklist ~ ')'
        )
    }}
{%- endif -%}

{#- Generate expression based on the presence of whitelist or blacklist -#}
{{- '' if reverse else 'NOT ' -}}
{%- if whitelist is not none -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) error_ WHERE error_ NOT IN ('{{ whitelist | join("\', \'")}}'))
{%- elif blacklist is not none -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) error_ WHERE error_ IN ('{{ blacklist | join("\', \'")}}'))
{%- else -%}
EXISTS (SELECT 1 FROM UNNEST({{ from_column }}) error_ WHERE TRUE)
{%- endif -%}

{%- endmacro %}
