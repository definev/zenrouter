## 1.0.0
- **Stable release**: Production-ready annotation package
- Compatible with `zenrouter: ^1.0.0` and `zenrouter_file_generator: ^1.0.0`

## 0.4.10

### New Features

- **deferredImport in `@ZenCoordinator`**: New optional `deferredImport` field to configure global deferred import behavior via annotation
  - Overrides the `deferredImport` option in `build.yaml` when specified
  - Example: `@ZenCoordinator(name: 'AppCoordinator', deferredImport: true)`
- **routeBasePath in `@ZenCoordinator`**: New optional `routeBasePath` field to import a custom base route class
  - When set, the generator imports the base class from the specified path instead of generating it
  - Example: `@ZenCoordinator(routeBase: 'MyAppRoute', routeBasePath: 'package:my_app/routes/base.dart')`

## 0.4.9
- **Refactor**: Extract shared code generation utilities (`LayoutCodeGenerator`, `RouteCodeGenerator`) for use by both `build_runner`

## 0.4.7
- **Docs**: Update README

## 0.4.6
- **Docs**: Update README and add screenshots

## 0.4.5
- Support new `RouteQueryParameters` and new dot notation flavor in naming convention.

## 0.4.0
- Update README.md

## 0.3.1
- Add support for lazy loading routes using the `deferredImport` option in the `@ZenCoordinator` annotation.

## 0.3.0
- Add support for catch-all parameters ([...slugs], [...ids], etc) in routes, including `List<String>` type handling and updated route specificity sorting.

## 0.2.1

- Initial extraction of annotations and structure from `zenrouter_file_generator`.
