<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_dark.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
  <img alt="ZenRouter Logo" src="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
</picture>

**Navigation as a typed graph.**

[![pub package](https://img.shields.io/pub/v/zenrouter.svg)](https://pub.dev/packages/zenrouter)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter)
[![Codecov - zenrouter_core](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter_core)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter_core)

</div>

---

```
Need deep linking or a browser URL?
│
├─ YES → Coordinator  (prefer RouteManifest + RouteBinding)
│
└─ NO → state-driven stack? → Declarative
        otherwise           → Imperative (NavigationPath)
```

**[zenrouter README](packages/zenrouter/README.md)** ·
**[Getting Started](packages/zenrouter/doc/guides/getting-started.md)**

## Packages

| Package | Role |
|---------|------|
| [`zenrouter`](packages/zenrouter/) | Flutter `Coordinator`, `NavigationStack`, restoration |
| [`zenrouter_core`](packages/zenrouter_core/) | `RouteTarget`, `CoordinatorCore`, paths, mixins, `RouteManifest` |
| [`zenrouter_devtools`](packages/zenrouter_devtools/) | Overlay, Graph tab |
| [`zenrouter_file_generator`](packages/zenrouter_file_generator/) | File-based codegen |

iOS, Android, Web, macOS, Windows, Linux

3.0 is a prerelease for early testers:

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
```

`flutter pub add zenrouter` still resolves 2.x. 2.x coordinators that
`extend Coordinator` still compile. See
[Migrating from 2.x](packages/zenrouter/README.md#migrating-from-2x).

## License

Apache 2.0. [LICENSE](LICENSE)

[definev](https://github.com/definev)
