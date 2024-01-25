{%- macro _get_unique_assertions(unique_columns) -%}
{#-
    Generates unique assertions based on the specified unique columns.

    Args:
        unique_columns (list[str|dict]):  column names or a nested structure
        containing columns for which unique assertions should be generated.

    Returns:
        dict: unique assertions for the specified columns.

    Example Usage:
        Suppose you have the following unique columns specified:

        __unique__:
          - column_a
          - column_b
          - nested_structure:
              - sub_column_1
              - sub_column_2

        Calling the macro with these columns will generate the following:

        {
          'unique': {
            'description': 'Row must be unique over the unique keys.',
            'expression': '1 = COUNT(1) OVER(PARTITION BY column_a, column_b)'
          },
          'nested_structure__unique': {
            'description': 'Items must be unique within nested_structure in the row.',
            'expression': 'NOT EXISTS (
                SELECT 1
                FROM UNNEST(nested_structure) nested_structure
                QUALIFY 1 < COUNT(1) OVER(
                    PARTITION BY
                        nested_structure.sub_column_1,
                        nested_structure.sub_column_2
                ))'
          }
        }

#}
    {{- return(adapter.dispatch('_get_unique_assertions', 'dbt_assertions') (unique_columns)) }}
{%- endmacro %}

{%- macro default___get_unique_assertions(unique_columns) %}

{%- set result = {} %}
{%- set layered_unique_columns = dbt_assertions._extract_columns(unique_columns) %}

{#- Iterate through columns by layer #}
{%- for parent_column, layer_unique_columns in layered_unique_columns.items() %}

    {%- set unique_columns = layer_unique_columns['columns'] %}
    {%- set depends_on = layer_unique_columns['depends_on'] %}


    {#- Create unique assertions on the first layer #}
    {%- if parent_column is none %}

        {%- do result.update({
                'unique': {
                    'description': 'Row must be unique over the unique keys.',
                    'expression': '1 = COUNT(1) OVER(PARTITION BY ' 
                        ~ ', '.join(unique_columns) ~ ')',
                }
            })
        %}

    {#- Create unique assertions on the other layers (more complex) #}
    {%- else %}

        {#- NOT EXISTS part #}
        {%- set expression = ['NOT EXISTS (\n    SELECT 1'] %}

        {#- Joins parts #}
        {%- for layer_dependence_key in depends_on + [parent_column] %}
            {%- do expression.append(
                '\n    ' ~ ('FROM' if loop.first else 'CROSS JOIN')
                )
            %}
            {%- do expression.append(
                ' UNNEST(' ~ layer_dependence_key ~') ' ~ layer_dependence_key
                )
            %}
        {%- endfor %}

        {#- QUALIFY parts #}
        {%- do expression.append(
            '\n    QUALIFY 1 < COUNT(1) OVER(\n    PARTITION BY'
            )
        %}
        {%- for layer_dependence_key in depends_on + [parent_column] %}

            {%- set loop_last_layer = loop.last %}
            {%- for unique_column in layered_unique_columns[layer_dependence_key]['columns'] %}
                {%- do expression.append(
                    '\n        ' ~ layer_dependence_key ~ '.' ~ unique_column
                    )
                %}
                {%- do expression.append(
                    '' if loop_last_layer and loop.last else ','
                    )
                %}

            {%- endfor %}
        {%- endfor %}

        {#- Close parenthesis #}
        {%- do expression.append('))') %}

        {%- do result.update({
                '.'.join(depends_on + [parent_column]) ~'__unique': {
                    'description': 'Items must be unique within'
                        ~ '.'.join(parents_columns) ~ ' in the row.',
                    'expression': ''.join(expression),
                }
            })
        %}

    {%- endif %}

{%- endfor %}

{{- return(result) }}

{%- endmacro %}
