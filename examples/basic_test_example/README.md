### Combine assertions & generic tests

#### Example usage

Suppose we are working with the `d_site` table - you want to use generic tests.

For instance, the `include_list` argument will filter all rows
containing at least a "site_id_is_not_null" exception:

```yml
version: 2

models:
  - name: basic_test_example_d_site
    tests:
      - dbt_assertions.generic_assertions:
          column: exceptions
          include_list:
            - site_id_is_not_null
          # `re_assert: true` to use only if your assertion's column
          # is not computed and saved in your table.
          re_assert: true

    columns:
      - name: site_id
      - name: country_trigram
      - name: open_date
      - name: exceptions
        assertions:
          site_id_is_not_null:
            description: 'Site ID is not null.'
            expression: site_id IS NOT NULL

          site_trigram_format:
            description: 'Site trigram must contain 3 upper digits'
            expression: |
              LENGTH(site_trigram) = 3
              AND site_trigram = UPPER(site_trigram)
```

You can also use the `exclude_list` and `column` arguments,
or use the function without arguments
(and thus filtering each row based on every assertion).
