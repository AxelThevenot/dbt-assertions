![Alt text](./img/dbt-assertions-logo.png)

<p align="center">
    <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-ff69b4?style=plastic"/>
    <img alt="Static Badge" src="https://img.shields.io/badge/dbt-package-orange">
    <img alt="GitHub Release" src="https://img.shields.io/github/v/release/AxelThevenot/dbt-assertions">
    <img alt="GitHub (Pre-)Release Date" src="https://img.shields.io/github/release-date-pre/AxelThevenot/dbt-assertions">
</p>

<p align="center">
    <img src="https://img.shields.io/circleci/project/github/badges/shields/master" alt="build status">
    <img alt="GitHub issues" src="https://img.shields.io/github/issues/AxelThevenot/dbt-assert">
    <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/AxelThevenot/dbt-assertions">
    <img src="https://img.shields.io/github/contributors/AxelThevenot/dbt-assertions" />
</p>

## Features

✅ **Robust Data Quality Checks**

`dbt-assertions` ensures thorough data quality assessments at the row level, enhancing the reliability of downstream models.

🔍 **Efficient Error Detection**

Granular row-by-row error detection identifies and flags specific rows that fail assertions, streamlining the resolution process.

🛠️ **Customizable Assertions & Easy Integration**

Easy-to-use macros `assertions()` and `assertions_filter()` empower users to customize without barriers data quality checks within the model YAML definition, adapting to specific data validation needs.

🚀 **An Easy Shift from your Actual Workflows**

A generic test `generic_assertions()` to perform dbt tests as usual, testing the package easily without compromising your current workflows.
**you can test the package with this generic test easily without having to rebuild you table**


## Content

- [Features](#features)
- [Content](#content)
- [Install](#install)
- [Dependencies](#dependencies)
- [Variables](#variables)
- [Basic Example](#basic-example)
- [Documentation](#documentation)
  - [Macros](#macros)
    - [assertions](#assertions)
    - [assertions\_filter](#assertions_filter)
  - [Tests](#tests)
    - [generic\_assertions](#generic_assertions)
  - [Model definition](#model-definition)
    - [Yaml general definition](#yaml-general-definition)
    - [Custom assertions](#custom-assertions)
    - [`null_as_error`](#null_as_error)
    - [`__unique__` helper](#__unique__-helper)
    - [`__not_null__` helper](#__not_null__-helper)
    - [Custom column name](#custom-column-name)
- [Contribution](#contribution)
- [Acknowledgments](#acknowledgments)
- [Contact](#contact)


## Install

`dbt-assertions` currently supports `dbt 1.7.x` or higher.


Check [dbt package hub](https://hub.getdbt.com/calogica/dbt_expectations/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in `packages.yml`

```yaml
packages:
  - package: AxelThevenot/dbt_assertions
    version: [">=0.1.0", "<1.0.0"]
    # <see https://github.com/AxelThevenot/dbt-assertions/releases/latest> for the latest version tag
```

This package supports:

* BigQuery
* default (not tested on other databases, do not hesitate to contribute! ❤️)

For latest release, see [https://github.com/AxelThevenot/dbt-assertions/releases](https://github.com/AxelThevenot/dbt-assertions/releases/latest)


## Dependencies

This package do not have dependencies.

## Variables

This package do not have variables.

## Basic Example

Check the [basic_example](models/examples/basic_example) example.

## Documentation

### Macros

#### [assertions](macros/assertions.sql)

`assertions()` macro generates a select expression for row-level assertions.

**Arguments:**
- **from_column (optional[str]):** column to read the assertions from.

---

This macro parses the schema model YAML to extract row-level assertions; [custom assertions](#custom-assertions), [unique](#__unique__-helper), and [not-null](#__not_null__-helper). It then constructs an array of failed assertions for each row based on its assertions results.


By default, it will generate assertions based on your [YAML model definition](#model-definition) reading configuration for a column named `errors`.

You can call the macro using `from_column` argument to change this default column.

```sql
SELECT
    *,
    {{ dbt_assertions.assertions(from_column='warnings') }},
FROM {{ ref('my_model') }}
```

**Note:** this macro is made to generate assertions based of the result of the table. It means it must be generated at the end of the query.

```sql
WITH
    [...] -- Other CTEs
    final AS (
        SELECT
            [...]
        FROM {{ ref('my_model') }}
    )

-- After query results
SELECT
    *,
    {{ dbt_assertions.assertions() }},
FROM final
```

#### [assertions_filter](macros/assertions_filter.sql)

`assertions_filter()` macro generates an expression to filter rows based on errors generated with the [`assertions()`](#assertions) macro.

**Arguments:**
- **from_column (optional[str]):** column to read the failed assertions from.
- **whitelist (optional[list[str]]):** A list of error IDs to whitelist.
        If provided, only rows with with no error, ignoring whitelist error IDs, will be included.
- **blacklist (optional[list[str]]):** A list of error IDs to blacklist.
        If provided, rows with at least one of these error IDs will be excluded.
- **reverse (optional[bool]):** returns errorless rows when `reverse=false` and error rows when `reverse=true`.

---

It will filter the rows without any error by default.


```sql
SELECT
    *
FROM {{ ref('my_model') }}
WHERE {{ dbt_assertions.assertions_filter() }}
```

You can change this default behaviour specifying an optional `whitelist` or `blacklist` argument (not both).

```sql
SELECT
    *
FROM {{ ref('my_model') }}
WHERE {{ dbt_assertions.assertions_filter(whitelist=['assertions_id']) }}
```

### Tests

####  [generic_assertions](tests/generic/generic_assertions.sql)

Generates a test to get rows based on errors.

It will returns the rows without any error by default.
You can change this default behaviour specifying a whitelist or blacklist (not both).

You must defined beforehand the assertions for the model. [More on YAML definition for assertions](#yaml-general-definition).

**Arguments:**
- **from_column (optional[str]):** column to read the failed assertions from.
- **whitelist (optional[list[str]]):** A list of error IDs to whitelist.
    If provided, only rows with with no error, ignoring whitelist error IDs, will be included.
- **blacklist (optional[list[str]]):** A list of error IDs to blacklist.
    If provided, rows with at least one of these error IDs will be excluded.
- **re_assert (optional[bool]):** to set to `true` if your assertion field do not exists yet in your table.

Configure the generic test in schema.yml with:

```yml
model:
  name: my_model
  tests:
    - dbt_assertions.generic_assertions:
      [from_column: <column_name>]
      [whitelist: <list(str_to_filter)>]
      [blacklist: <list(str_to_filter)>]
      [re_assert: true | false]

  columns:
    ...
```

`[]` represents optional parts. Yes everything is optional but let's see it by examples.

In the [basic test example](./models/examples/basic_test_example/) you can easily create your test as follows then run your `dbt test` command.

```yml
models:
  - name: basic_test_example_d_site
    tests:
      - dbt_assertions.generic_assertions:
          from_column: errors
          blacklist:
            - site_id_is_not_null
          # `re_assert: true` to use only if your assertion's column
          # is not computed and saved in your table.
          re_assert: true

    columns:
      ...
```

### Model definition

#### Yaml general definition

The assertions definition **must** be created **under a column definition of your model** and respects the following.

```yml
assertions:
  [__unique__: <unique_expression>]
  [__not_null__: __unique__ | <not_null_expression>]

  [<custom_assertion_id>:
    description: [<string>]
    expression: <string>
    null_as_error: [<bool>]]
  ...
```

`[]` represents optional parts. Yes everything is optional but let's see it by examples.

#### Custom assertions

Custom assertions are the basics assertions.

> The package is made to support every assertions as long as it is supported in a SELECT statement of your underlying database. **So you can do a lot of things**.

It is represented as key values. Keys are the ID of the assertions.

Each assertions is defined by at least an `expression` which will be rendered to be evaulated as your test.
`description` and [`null_as_error`](#null_as_error) are optional.

```yml
assertions:
  unique:
    description: "Row must be unique."
    expression: "1 = COUNT(1) OVER(PARTITION by my_id)"

  site_creation_date_is_past:
    description: "Site must be created in the past."
    expression: "site_creation_date <= CURRENT_DATE()"

  site_type_pick_list:
    description: "The site type be must in its known picklist."
    expression: |
        site_type IN (
            'store',
            'ecommerce',
            'drive',
            'pickup'
        )
```

#### `null_as_error`

`null_as_error` is an optional configuration for your assertion.
Default to `false` it is the return result if your expression is evaluated to `NULL`.

Default behaviour is set to `false` because one assertion must evaluate on thing. Prefer using the [`__not_null_`](#__not_null__-helper) helper instead.

In our previous, if we want to also avoid `NULL` site types.

```yml
assertions:
  ...

  site_type_pick_list:
    description: "The site type be must in its known picklist."
    expression: |
        site_type IN (
            'store',
            'ecommerce',
            'drive',
            'pickup'
        )
    null_as_error: true
```

#### `__unique__` helper

As guaranteeing uniqueness of rows is a concern in most of the use cases, the `__unique__` helper is here to avoid writing complex and repetitive queries.

---

```yml
assertions:
  unique:
    description: "Row must be unique."
    expression: "1 = COUNT(1) OVER(PARTITION by key_1, key_2)"
```

The above configuration is the same as writing

```yml
assertions:
  __unique__:
    - key_1
    - key_2
```

---

You can also verify unique keys for nested/repeated structure. It will generate:
- One assertion for the 0-depth guaranteeing uniqueness **accross the rows**.
- One assertion **for each** repeated field guaranteeing uniqueness **within the row**.


The following example will generate the assertions:
- `unique`: Row must be unique over the unique keys.
- `nested_1_unique`: Items must be unique **within** nested_1 in the row.
- `nested_1.nested_2_unique`: Items must be unique **within** nested_1.nested_2 in the row.

```yml
assertions:
  __unique__:
    - key_1
    - key_2
    - nested_1:
        - key_3
        - key_4
        - nested_2:
            - key_5
            - key_6
```

#### `__not_null__` helper

As guaranteeing not null values is also concern in most of the use cases, the `__not_null__` helper is here to avoid writing complex and repetitive queries.

---

```yml
assertions:
  key_1_not_null:
    description: "key_1 is not null."
    expression: "key_1 IS NOT NULL"

  key_2_not_null:
    description: "key_2 is not null."
    expression: "key_2 IS NOT NULL"
```

The above configuration is the same as writing

```yml
assertions:
  __unique__:
    - key_1
    - key_2

  __not_null__:
    - key_1
    - key_2
```

And as the two helpers are often linked, you can rewrite the assertions as follows, which is also the same.

```yml
assertions:
  __unique__:
    - key_1
    - key_2

  __not_null__: __unique__
```

---

You can also verify unique keys for nested/repeated structure. It will generate:
- One assertion **for each column** of the 0-depth guaranteeing not null.
- One assertion **for each column** under the repeated field guaranteeing **all the values are not null within the row**.

The following example will generate the assertions:
- `key_1_not_null`: key_1 is not null.
- `key_2_not_null`: key_2 is not null.
- `nested_1.key_3_not_null`: nested_1.key_3 **are** not null.

```yml
assertions:
  __not_null__:
    - key_1
    - key_2
    - nested_1:
        - key_3
```

#### Custom column name

If `errors` column is not a naming convention you like, you can still opt for a column name you choose and the macro will still work with the `from_colum` argument.

You can also play with multiple columns.

```yml
model:
  name: my_model
  columns:
    ...
    - errors:
      assertions:
        __unique__:
            - key_1
            - key_2

        __not_null__: __unique__

    - warns:
      assertions:
        site_creation_date_is_past:
          description: "Site must be created in the past."
          expression: "site_creation_date <= CURRENT_DATE()"
```

And in your model query.

```sql
WITH final AS
    (
        SELECT ...
    )
SELECT
    *,
    {{ dbt_assertions.assertions() }},
    {{ dbt_assertions.assertions(from_column='warns') }},
FROM {{ ref('my_model') }}
```

## Contribution

If you want to contribute, please open a Pull Request or an Issue on this repo.
Feel free to reach me [Linkedin](https://www.linkedin.com/in/axel-thevenot/).

## Acknowledgments

Special thank to @vvaneeclo for its help !!

## Contact

If you have any question, please open a new Issue or feel free to reach out to [Linkedin](https://www.linkedin.com/in/axel-thevenot/)

---

Happy coding with **dbt-assertions**!
