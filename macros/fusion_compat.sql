{% macro get_assertions(column, default={}) %}
    {%- if column.get('assertions') != none -%}
        {{ return(column.assertions) }}
    {%- elif column.get("config") != none and column.get("config").get("meta") != none and ('assertions' in column.get("config").get("meta", {}).keys()) -%}
        {{ return(column.get("config").get("meta").get('assertions')) }}
    {%- else -%}
        {{ return(default) }}
    {%- endif -%}
{% endmacro %}
