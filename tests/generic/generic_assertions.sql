{% test generic_assertions(model, from_column='exceptions', exclude_list=none, include_list=none, re_assert=False) %}
{#-
    Generates a test SELECT expression to get rows based on exceptions.

    By default, each row with exception(s) will be returned.
    You can change this behaviour specifying an exclude_list or include_list (not both).

    Args:
        from_column (optional[str]): Column to read the assertions from.
        exclude_list (optional[list[str]]): Assertions to exclude in the filter.
        include_list (optional[list[str]]): Assertions to include in the filter.
        re_assert (optional[bool]): to set to `true` if your assertion field
            is not calculated in your table.

    Returns:
        str: An SELECT expression to return rows with exceptions.
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
WHERE {{ dbt_assertions.assertions_filter(from_column, exclude_list, include_list, reverse=true) }}

{% endtest %}
