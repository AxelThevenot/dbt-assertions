{%- macro _get_not_null_assertions(not_null_columns) -%}
{#-
    Generates not-null assertions based on the specified columns for error tracking.

    This macro dynamically creates not-null assertions for the given columns or nested structures.
    It is designed to be used in conjunction with the `assertions_expression` macro for constructing
    row-level assertions.

    Args:
        not_null_columns (list[str|dict]): A list of column names or a nested structure containing columns
            for which not-null assertions should be generated.

    Returns:
        dict: A dictionary containing not-null assertions for the specified columns.

    Example Usage:
        Suppose you have the following not-null columns specified:

        not_null_columns:
          - column_a
          - column_b
          - nested_structure:
              sub_column_1
              sub_column_2

        Calling the macro with these columns will generate not-null assertions for each column:

        {
          'column_a_not_null': {
            'description': 'column_a is not null.',
            'expression': 'column_a IS NOT NULL'
          },
          'column_b_not_null': {
            'description': 'column_b is not null.',
            'expression': 'column_b IS NOT NULL'
          },
          'nested_structure_sub_column_1_not_null': {
            'description': 'nested_structure.sub_column_1 are not null over the row.',
            'expression': 'NOT EXISTS (SELECT 1
                FROM UNNEST(nested_structure) nested_structure
                WHERE nested_structure IS NOT NULL AND
                nested_structure.sub_column_1 IS NULL)'
          },
          'nested_structure_sub_column_2_not_null': {
            'description': 'nested_structure.sub_column_2 are not null over the row.',
            'expression': 'NOT EXISTS (SELECT 1
                FROM UNNEST(nested_structure) nested_structure
                WHERE nested_structure IS NOT NULL AND
                nested_structure.sub_column_2 IS NULL)'
          }
        }

    Notes:
        - The macro handles both flat lists of columns and nested structures with sub-columns.
        - Recursive calls are made for nested structures to generate assertions for each sub-column.
        - The resulting dictionary is used in constructing row-level assertions for not-null constraints.
#}
    {{- return(adapter.dispatch('_get_not_null_assertions', 'dbt_assertions') (not_null_columns)) }}
{%- endmacro %}

{%- macro default___get_not_null_assertions(not_null_columns) %}

{%- set result = {} %}
{%- set layered_not_null_columns = dbt_assertions._extract_columns(not_null_columns) %}

{#- Iterate through columns by layer #}
{%- for parent_column, layer_not_null_columns in layered_not_null_columns.items() %}

    {%- set not_null_columns = layer_not_null_columns['columns'] %}
    {%- set depends_on = layer_not_null_columns['depends_on'] %}

    {#- Create not null assertions on the first layer #}
    {%- if parent_column is none %}


        {%- for column in not_null_columns %}
            {%- do result.update({
                    column ~ '_not_null': {
                        'description': column ~ ' is not null.',
                        'expression': column ~ ' IS NOT NULL'
                    }
                })
            %}
        {%- endfor %}

    {#- Create not null assertions on the other layers (more complex) #}
    {%- else %}

        {#- NOT EXISTS part #}
        {%- set expression = ['NOT EXISTS (\n    SELECT 1'] %}

        {#- Joins parts #}
        {%- for layer_dependence_key in depends_on + [parent_column] %}
            {%- do expression.append('\n    ' ~ ('FROM' if loop.first else 'CROSS JOIN')) %}
            {%- do expression.append(' UNNEST(' ~ layer_dependence_key ~') ' ~ layer_dependence_key) %}
        {%- endfor %}


        {#- WHERE parts #}
        {%- for column in not_null_columns %}

            {%- set column_where = [] %}
            {%- do column_where.append('\n    WHERE ' ~ parent_column ~ ' IS NOT NULL') %}
            {%- do column_where.append('\n    AND ' ~ parent_column ~ '.' ~ column ~ ' IS NULL') %}

            {%- do result.update({
                '.'.join(depends_on + [parent_column, column]) ~'_not_null': {
                        'description': '.'.join(depends_on + [parent_column, column]) ~ ' are not null within the row.',
                        'expression': ''.join(expression) ~ ''.join(column_where) ~ '\n)',
                    }
                })
            %}
        {%- endfor %}

    {%- endif %}

{%- endfor %}

{{- return(result) }}

{%- endmacro %}
