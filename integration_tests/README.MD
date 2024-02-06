# Integration tests

To test the package for a new adapter:

- in your shell, `cd` to `integration_tests`
- set up the [relevant profile information](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles) for the profile name `integration_tests`
- do a `dbt deps` to symlink the package from the repo one (this is only required the first time you run some tests and not every time)
- do a `dbt build` (or `dbt build --target my_target` to specify a given target)
- the dbt command should run successfully, creating the models and running the test as expected ✅
