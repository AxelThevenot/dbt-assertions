{%- macro assertions(from_column='errors', _node=none) %}
{#-
    Generates row-level assertions based on the schema model YAML for error tracking.

    This macro parses the schema model YAML to extract row-level assertions,
    including unique and not-null constraints. It then constructs an array of failed assertions (errors)
    for each row based on its assertions results.

    Args:
        from_column (optional[str]): column to read the assertions from.
        _node (dict): any other node to read the columns from.
            This argument is reserved to `dbt-assertions`'s developers.

    Returns:
        str: An ARRAY<STRING> SELECT expression containing error ID for rows that violate assertions.

    Example Usage:
        Suppose the schema model YAML is set as below, you can call the function in you model the following:

        ```
        WITH
            final AS (
                SELECT
                    my_key,
                    my_other_key,
                    nested_structure,
                FROM {{ source('my_source') }}
            )
        SELECT
            *,
            {{ dbt_assertions.assertions() | indent(4)}},
        FROM final
        ```

        Suppose the schema model YAML includes the following assertions:

        ```
            - name: errors
              description: This column contains errors of the row based on assertions.
              assertions:
                __unique__:
                  - my_key
                  - my_other_key
                  - nested_structure:
                    - sub_key

                __not_null__: __unique__

                other_field_greater_than_1:
                  description: The row must follow this condition.
                  expression: my_other_field > 1

                site_key_exists:
                  description: The site key exists.
                  expression: |
                    site_key IN (
                        SELECT DISTINCT
                            site_key
                        FROM {{ '{{' ref('my_sites_model') '}}' }}
                    )
                  null_as_error: true
        ```

        The macro will generate an expression to check these assertions and return
        an array of error IDs for each row where the assertions are violated.

    Notes:
        - `expression` is correct as long as it can correct as a SELECT expression (including joins and analytic functions).
        - `__unique_key__` assertion is an helper to create dynamically the assertion on uniqueness over the row.
        - `__not_null__` assertion is an helper to create dynamically the assertion on required fields over the row. It will generate one assertion for each field.
        - `__not_null__` can be equal to __unique_key__ to avoid repetitions.
        - `__unique_key__` and `__not_null__` assertions will trigger an error if at least one of the sub fields do not respect the constraint.
        - `null_as_error` (default to false) the trigger error rule if the expression is evaluated to NULL.
        - The resulting array is named with `from_column` and can be used in subsequent transformations.
#}
    {{- adapter.dispatch('assertions', 'dbt_assertions') (from_column, _node) }}
{%- endmacro %}


{%- macro default__assertions(from_column, _node) %}

{#- Parses the assertions if exists. #}
{%- set model             = model if _node is none else _node %}
{%- set columns           = model.columns if ('columns' in model) else {} %}
{%- set assertions_column = columns[from_column] if (from_column in columns) else {} %}
{%- set assertions        = assertions_column.assertions if ('assertions' in assertions_column) else {} %}

{#- Generate assertions from helpers. #}
{%- set __unique__ = {} %}
{%- set __not_null__ = {} %}

{%- if '__unique__' in assertions %}
    {%- set __unique__ = assertions.pop('__unique__', {}) %}
{%- endif %}

{%- if '__not_null__' in assertions %}
    {%- set __not_null__ = assertions.pop('__not_null__', {}) %}
    {%- set __not_null__ = __not_null__ if ('__unique__' not in __not_null__) else __unique__ %}
{%- endif %}


{%- do assertions.update(dbt_assertions._get_unique_assertions(__unique__)) %}
{%- do assertions.update(dbt_assertions._get_not_null_assertions(__not_null__)) %}


{{- dbt_assertions._assertions_expression(from_column, assertions) }}

{%- endmacro %}
