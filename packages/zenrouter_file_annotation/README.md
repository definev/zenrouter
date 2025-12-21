<div align="center">

<img src="https://github.com/definev/zenrouter/blob/main/assets/logo.png?raw=true" width="300" alt="Logo">

# ZenRouter File Annotation

Shared annotations and structure for [zenrouter](https://pub.dev/packages/zenrouter) file-based routing.

This package contains the annotations (`@ZenRoute`, `@ZenLayout`, `@ZenCoordinator`) and helper classes used by the `zenrouter_file_generator` to generate type-safe routes.

[![pub package](https://img.shields.io/pub/v/zenrouter_file_annotation.svg)](https://pub.dev/packages/zenrouter_file_annotation)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

</div>

## Installation

This package is usually added automatically when using `zenrouter_file_generator`.

```yaml
dependencies:
  zenrouter_file_annotation: ^0.4.6

dev_dependencies:
  zenrouter_file_generator: ^0.4.6
```

## Usage

Use these annotations to define your routes and layouts:

```dart
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

@ZenRoute()
class MyRoute extends _$MyRoute { ... }

@ZenLayout(type: LayoutType.stack)
class MyLayout extends _$MyLayout { ... }

// With query parameters
@ZenRoute(queries: ['search', 'page'])
class SearchRoute extends _$SearchRoute { ... }
```

See [zenrouter_file_generator](https://pub.dev/packages/zenrouter_file_generator) for complete documentation and usage examples.
