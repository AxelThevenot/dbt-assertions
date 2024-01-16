{%- macro _extract_columns(columns, parent_column=none, depends_on=none) %}
{#-
    Extracts a flattened representation of columns hierarchy.

    Args:
        columns (list): A list of column names or dictionaries representing nested structures.
        depends_on (optional[list]): A list representing the dependencies of the current columns.

    Returns:
        dict: A dictionary with keys representing the columns and values as dictionaries containing columns and their dependencies.

    Example:
        columns = [
            "key_01",
            "key_02",
            {
                "nested_field_1": ["sub_key_11", "sub_key_12"],
                "nested_field_2": [
                    "sub_key_21",
                    {
                        "nested_field_3": ["sub_key_31", "sub_key_32"]
                    }
                ]
            },
            {
                "nested_field_4": ["sub_key_41", "sub_key_42"],
            }
        ]

        _extract_columns(columns) returns:
        {
            none:             {'columns': ['key_01', 'key_02'],         'depends_on': []},
            'nested_field_1': {'columns': ['sub_key_11', 'sub_key_12'], 'depends_on': []},
            'nested_field_2': {'columns': ['sub_key_21'],               'depends_on': ['nested_field_1']},
            'nested_field_3': {'columns': ['sub_key_31', 'sub_key_32'], 'depends_on': ['nested_field_1', 'nested_field_2']},
            'nested_field_4': {'columns': ['sub_key_41', 'sub_key_42'], 'depends_on': []}
        }
#}
{%- set result = {parent_column: {'columns': [], 'depends_on': depends_on or []}} %}
{#- Iterate through columns #}
{%- for column in columns %}

    {#- Process flat keys (to the current layer) #}
    {%- if column is string %}
        {%- do result[parent_column]['columns'].append(column) %}

    {#- Process nested repeated keys (from the deeper layers) #}
    {%- elif column is mapping %}

        {#- Depth can be horizontal and vertical #}
        {%- for nested_column, sub_columns in column.items() %}

            {%- do result.update(dbt_assertions._extract_columns(
                    columns=sub_columns,
                    parent_column=nested_column,
                    depends_on=depends_on + [parent_column] if depends_on is not none else [],
                )
            ) %}

        {%- endfor %}

    {%- endif %}

{%- endfor %}

{{- return(result) }}

{%- endmacro %}
