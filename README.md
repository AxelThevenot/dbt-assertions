<h1 align="center">dbt-assertions</h1>

<p align="center">
    An image is coming....
</p>

<p align="center">
    <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-ff69b4?style=plastic"/>
    <img alt="Static Badge" src="https://img.shields.io/badge/dbt-package-orange">
</p>

<p align="center">
    <img alt="GitHub Release" src="https://img.shields.io/github/v/release/AxelThevenot/dbt-assertions">
    <img alt="GitHub (Pre-)Release Date" src="https://img.shields.io/github/release-date-pre/AxelThevenot/dbt-assertions">
    <img src="https://img.shields.io/circleci/project/github/badges/shields/master" alt="build status">
    <img alt="GitHub issues" src="https://img.shields.io/github/issues/AxelThevenot/dbt-assert">
    <img src="https://img.shields.io/github/contributors/AxelThevenot/dbt-assertions" />
    <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/AxelThevenot/dbt-assertions">
</p>

## About

`dbt-assertions` is a crucial extension package designed for dbt users, aiming to enhance data testing capabilities at the row level integrated into the data pipeline. With this package, users can conduct comprehensive data quality assessments, flagging each row based on specific assertions it fails. 

This approach not only elevates data quality for downstream models but also streamlines error management in daily operations, as the tests are smoothly integrated.

**In short:** efficient row-by-row error detection and resolution.

## Content

- [About](#about)
- [Content](#content)
- [Features](#features)
- [Install](#install)
- [Dependencies](#dependencies)
- [Variables](#variables)
- [Basic Example](#basic-example)
  - [Create the assertions you want on your table](#create-the-assertions-you-want-on-your-table)
  - [Generate assertions results during run-time](#generate-assertions-results-during-run-time)
  - [Easy data quality evaluation](#easy-data-quality-evaluation)
  - [Filter bad data in your downstream models](#filter-bad-data-in-your-downstream-models)
- [Documentation](#documentation)
  - [Macros](#macros)
    - [assertions](#assertions)
    - [assertions\_filter](#assertions_filter)
  - [Tests](#tests)
    - [what\_ever\_the\_test\_name](#what_ever_the_test_name)
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

## Features


## Install

`dbt-assertions` currently supports `dbt 1.2.x` or higher.


Check [dbt github package](https://hub.getdbt.com/calogica/dbt_expectations/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in `packages.yml`

```yaml
packages:
  - git: https://github.com/AxelThevenot/dbt-assertions.git
    revision: 0.1.0a
    # <see https://github.com/AxelThevenot/dbt-assertions/releases/latest> for the latest version tag
```

This package supports:

* BigQuery
* default (not tested on other databases, do not hesitate to contribute! ❤️
)

For latest release, see [https://github.com/AxelThevenot/dbt-assertions/releases](https://github.com/AxelThevenot/dbt-assertions/releases)


## Dependencies

This package do not have dependencies.

## Variables

This package do not have variables.

## Basic Example

Check the [basic_example](models/examples/basic_example) example.

### Create the assertions you want on your table

The `d_site` table is defined as follows:

```yml
version: 2

models:
  - name: basic_example
    columns:
      - name: site_id
      - name: site_trigram
      - name: open_date
      - name: errors
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

Assertions are set under the `errors` columns (can be changed).

### Generate assertions results during run-time

Once the assertions described, you can call the `dbt_assertions.assertions()` macro as follows.

```sql
{{ 
    config(alias='d_site', materialized='table')
}}

WITH
    final AS (
        SELECT 1 AS site_id, 'FRA' AS site_trigram, DATE('2023-01-01') AS open_date
        UNION ALL
        SELECT 2 AS site_id, 'France' AS site_trigram, DATE('2023-01-01') AS open_date
        UNION ALL
        SELECT NULL AS site_id, 'Belgium' AS site_trigram, DATE('2023-01-01') AS open_date
    )
SELECT
    *,
    {{ dbt_assertions.assertions() | indent(4) }},
FROM `final`
```

Everything works fine ! 🔥🔥🔥

### Easy data quality evaluation

![basic_example_d_site](img/basic_example_d_site.png)

All the failed assertions are saved under the `errors` columns which is an array of string containing failed assertions ID.

### Filter bad data in your downstream models

```sql
{{ 
    config(alias='downstream_model', materialized='table')
}}

SELECT
    site_id,
    site_trigram,
    open_date,
FROM {{ ref('basic_example_d_site') }}
-- Remove bad data: here only sites without ID.
WHERE {{ dbt_assertions.assertions_filter(blacklist=['site_id_is_not_null']) }}

```
![basic_example_downstream_model](img/basic_example_downstream_model.png)

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
- **from_column (optional[str])**: column to read the failed assertions from.
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

####  [what_ever_the_test_name](tests/generic/what_ever_the_test_name.sql)

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

## Acknowledgments

## Contact

If you have any question, please open a new Issue or feel free to reach out to [Linkedin](https://www.linkedin.com/in/axel-thevenot/)

---

Happy coding with **dbt-assertions**!
