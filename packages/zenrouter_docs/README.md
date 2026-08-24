# ZenRouter documentation

The documentation site is a guided technical book for ZenRouter 3.

The editorial plan, audience, learning journey, page contract, visual direction,
and definition of done live in
[`../../docs/DOCUMENTATION_BLUEPRINT.md`](../../docs/DOCUMENTATION_BLUEPRINT.md).
That blueprint is the implementation baseline; the site should not grow a
second competing information architecture.

## Content model

- `assets/content/outline.md` is the source of truth for chapter order, part
  grouping, titles, and summaries.
- `assets/content/chapter-01.md` through `chapter-20.md` contain the prose.
  Edit these Markdown files to update the site; no Dart content registry needs
  to be changed.
- `lib/content/book_content.dart` loads only the small outline at startup.
  Chapter bodies are fetched on demand, cached by chapter number, and adjacent
  chapters are prefetched after the current page is visible.
- `lib/content/book_outline.dart` keeps only the 20-file ordering contract and
  legacy URL redirects; it contains no editorial copy.
- `lib/routes/docs/chapter/[slug].dart` renders every chapter through one
  generated ZenRouter route.
- Legacy documentation URLs are mapped to the closest chapter by
  `CustomDocsCoordinator`.
- The site uses its own generated manifest, bindings, layouts, and locations as
  a live example of the architecture it teaches.
- The interface uses Forui (`FTheme`, `FScaffold`, `FButton`, and `FTappable`)
  over `WidgetsApp.router`; the documentation shell has no Material component
  layer.

The examples in this edition target `zenrouter` 3.0.0-beta.1 and must be
re-audited when stable 3.0 is released.

## Development

```bash
fvm dart run build_runner build
fvm flutter run -d web-server
```

After changing a chapter Markdown file, restart the web app (or rebuild the
web release) so Flutter refreshes its asset manifest.

Each entry in `outline.md` uses this Markdown format:

```markdown
## II · Build Compass

- 05 | Build your first graph | Create a typed home route and parameterized article route.
```

Validate the content registry, analyze the app, and build the web release:

```bash
fvm flutter test
fvm dart analyze
fvm flutter build web
```

## Editorial rules

Write one invariant per example. Lead with a concrete navigation problem, keep
domain state outside route values, and introduce the manifest before
handwritten URI parsing. Tutorials explain; reference pages specify. Migration
material must be labeled and kept out of the main new-user path.
