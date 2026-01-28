## 1.0.0
- **BREAKING**: Requires `zenrouter: ^1.0.0` and `zenrouter_file_annotation: ^1.0.0`
- **Stable release**: Production-ready file-based routing generator
- Generates code compatible with zenrouter 1.0.0 features

## 0.4.14
- **Fix**: Upgrade to `analyzer` to `^9.0.0`

## 0.4.13
- **Docs**: Add "Customizing the Coordinator" section to README
- **Docs**: Add Table of Contents to README

## 0.4.12
- **Feat**: Add `super.paths` to ensure `root` always added in the `paths` getter (Thanks @mrgnhnt96)

## 0.4.11

### New Features

- **NavContext extension**: Auto-generated extension on route base class (e.g., `AppRoute`) providing convenient navigation methods directly from route instances:
  - `route.navigate(context)` - Navigate to the route
  - `route.push<T>(context)` - Push the route and optionally return a result
  - `route.replace(context)` - Replace the current route
  - `route.recover(context)` - Recover to the route

## 0.4.10

### New Features

- **CoordinatorProvider**: Auto-generated `InheritedWidget` provider for accessing the coordinator from the widget tree via `context.appCoordinator`
- **layoutBuilder override**: The generated Coordinator now includes a `layoutBuilder` override that wraps layouts with the provider
- **deferredImport in `@ZenCoordinator`**: Configure global deferred import via annotation, overriding `build.yaml`
- **routeBasePath in `@ZenCoordinator`**: Import a custom base route class from a specified path instead of generating it
- **outputFile config**: New `build.yaml` option to customize the output filename (default: `routes.zen.dart`)

### Bug Fixes

- **Fixed file processing order**: Read `_coordinator.dart` directly first before processing routes to ensure correct configuration

## 0.4.9
- **Refactor**: Use shared code generation utilities (`LayoutCodeGenerator`, `RouteCodeGenerator`) from `zenrouter_file_annotation`

## 0.4.8
- **Docs**: Update README

## 0.4.7
- **Docs**: Update README and add screenshots

## 0.4.6
- Downgrade `analyzer` to `^8.0.0` for compatibility.

## 0.4.5
- Support new `RouteQueryParameters` and new dot notation flavor in naming convention.

## 0.4.1
- **Docs**: Improve documentation and update outdated examples
- Bump zenrouter_file_annotation to 0.4.0

## 0.4.0
- **BREAKING CHANGE**: Upgraded generated code to use `zenrouter` 0.4.0+ constructor syntax (`NavigationPath.createWith`/`IndexedStackPath.createWith`). Requires `zenrouter: ^0.4.0`.

## 0.3.1

- **NEW FEATURE**: Add ability to lazy load routes using the `deferredImport` option in the `@ZenCoordinator` annotation
- **PERFORMANCE IMPROVEMENTS**: Performance improvements (30-40% faster generation, 25-35% lower memory) and automatic code formatting with `dart_style`

## 0.3.0
- Bump version to 0.3.0 
- Add support for catch-all parameters ([...slugs], [...ids], etc) in routes, including `List<String>` type handling and updated route specificity sorting.

## 0.2.3

- Format files

## 0.2.2

### Bug Fixes

- Update the debug label correctly for the generated Path in the Coordinator
- Update README.md

## 0.2.1

### New Features

- **Extract annotations and analyzer elements into a new `zenrouter_file_annotation` package**

### Breaking Changes

- **Remove `zenrouter_file_generator` from `pubspec.yaml` and move it to `dev_dependencies`**

## 0.2.0

### New Features

- **Route Groups `(name)`**: Wrap routes in a layout without adding the folder name to the URL path
  - Folders named with parentheses like `(auth)` create route groups
  - Routes inside `(auth)/login.dart` generate URL `/login` (not `/(auth)/login`)
  - Routes are still wrapped by the `_layout.dart` in that folder
  - Useful for grouping auth flows, marketing pages, or applying shared styling

## 0.1.0

- Initial release of zenrouter_file_generator with file-based routing support for Flutter.