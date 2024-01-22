{% test generic_assertions(model, from_column='errors', whitelist=none, blacklist=none, re_assert=False) %}
{#-
    Generates a test SELECT expression to get rows based on errors.

    It will returns the rows without any error by default.
    You can change this default behaviour specifying a whitelist or blacklist (not both).

    Args:
        from_column (optional[str]): column to read the failed assertions from.
        whitelist (optional[list[str]]): A list of error IDs to whitelist.
            If provided, only rows with with no error, ignoring whitelist error IDs, will be included.
        blacklist (optional[list[str]]): A list of error IDs to blacklist.
            If provided, rows with at least one of these error IDs will be excluded.
        re_assert (optional[bool]): to set to `true` if your assertion field do not exists yet in your table.

    Returns:
        str: An SELECT expression to return rows with errors.
-#}

WITH
    final AS (
        SELECT
            *
            {%- if re_assert and execute %}

                {%- set model_parts = (model | replace('`', '')).split('.') %}
                {%- set database    = model_parts[0] %}
                {%- set schema      = model_parts[1] %}
                {%- set alias       = model_parts[2] %}

                {#- Filter the graph to find the node for the specified model -#}
                {%- set node = (
                        graph.nodes.values()
                        | selectattr('resource_type', 'equalto', 'model')
                        | selectattr('database'     , 'equalto', database)
                        | selectattr('schema'       , 'equalto', schema)
                        | selectattr('alias'        , 'equalto', alias)
                    ) | first -%}

                ,
                {{ dbt_assertions.assertions(from_column=from_column, _node=node) | indent(12) }}

            {%- endif %}
        FROM {{ model }}
    )

SELECT
    *
FROM `final`
WHERE {{ dbt_assertions.assertions_filter(reverse=true, blacklist=blacklist, whitelist=whitelist, from_column=from_column) }}

{% endtest %}
