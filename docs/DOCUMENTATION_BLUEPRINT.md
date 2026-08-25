# ZenRouter documentation blueprint

Status: approved implementation baseline  
Last audited: 2026-08-23  
Product target: ZenRouter 3.0.0-beta.1

This document is the planning gate for the documentation overhaul. The site
must follow this learning model and content contract before additional pages or
visual ideas are added.

## 1. The job of the documentation

ZenRouter has one difficult idea and many supporting APIs: navigation is a
typed graph whose routes, layouts, and URLs describe the same application.
The documentation must make that idea feel simpler than a growing collection
of `Navigator` calls.

The finished documentation should let a Flutter developer answer five
questions in order:

1. Which ZenRouter mode fits this part of my app?
2. What is the smallest correct application I can build?
3. How do typed routes, paths, layouts, and the route manifest relate?
4. How do I handle the real cases: tabs, authentication, deep links, browser
   history, restoration, modules, and 404s?
5. Where can I verify an API detail without rereading the guide?

The site is successful when a reader can build a small URL-aware application
without reading the source or reverse-engineering an example.

## 2. Audit findings

### What is true in 3.0

- `zenrouter` is currently `3.0.0-beta.1`; the default `flutter pub add
  zenrouter` command may still resolve the stable 2.x line.
- New URL-aware applications should prefer `RouteManifest` plus
  `RouteBinding`; handwritten `parseRouteFromUri` remains supported.
- A manifest is adapter-neutral. Flutter screens are created at the binding
  seam, not stored in the static topology.
- A generated coordinator includes a manifest, route bindings, reverse
  locations, and optional deferred imports.
- Navigation capabilities have been separated in `zenrouter_core`; Flutter's
  `Coordinator` still composes the full common capability set.
- Layouts bind to paths. `NavigationPath`, `IndexedStackPath`, and
  `BranchedStackPath` represent nested stacks, fixed destinations, and
  stateful branches respectively.
- Coordinator navigation commits are atomic and carry browser-history intent.
- Equal semantic routes can coexist in imperative stacks because page-entry
  identity is separate from route equality.

### Problems in the current material

- The README, long-form Markdown, generated-file guide, package docs, examples,
  and documentation application explain different generations of the API.
- The current site opens with claims instead of a learner problem and teaches
  the three paradigms before establishing the typed-graph mental model.
- The manifest—the recommended 3.0 seam—appears too late and is treated as an
  optional appendix to a handwritten URI switch.
- Pages alternate between terse reference, sprawling recipes, and ornamental
  literary prose. Readers cannot predict a page's depth or purpose.
- Several recipes repeat full applications before stating the invariant that
  the reader needs.
- Navigation is organized by implementation nouns rather than by the sequence
  of decisions a developer makes while building an app.
- The current Flutter documentation application looks like a conventional
  three-column docs portal. It does not yet deliver the book-like reading
  experience requested for this overhaul.

## 3. Readers and entry points

### Primary: Flutter developer choosing a router

They know `Navigator.push`, may have used `go_router`, and want a concrete
reason to adopt ZenRouter. They start at **Start here**, complete **Build your
first graph**, and stop when they can deep-link to a parameterized screen.

### Secondary: ZenRouter 2.x user

They need an explicit stability statement, a focused migration checklist, and
a map from handwritten parsing / deprecated lifecycle hooks to 3.0 concepts.
They enter through **Migrate to 3.0**, then revisit the manifest chapters.

### Secondary: application architect

They care about feature ownership, manifest fragments, nested coordinators,
headless hosts, and test seams. They enter at **Scale the graph** after reading
the five-minute mental model.

### Secondary: API lookup reader

They already know the model and need signatures, behavior, and caveats. They
use the reference section and should never have to extract contracts from a
tutorial.

## 4. Learning journey

The recommended path is a progressive application named **Compass**. It starts
with `/`, adds `/articles/:id`, then adds an application shell, authentication,
tabs with retained stacks, a modular knowledge-base feature, and debugging.
Every chapter changes one concept and preserves all earlier code.

### Stage A — Orient (10 minutes)

Reader outcome: choose a mode and understand the graph in one sentence.

1. **Start here** — the problem ZenRouter solves; release status; prerequisites.
2. **Choose a navigation model** — Coordinator vs declarative vs imperative,
   with use cases and a decision table.
3. **A route graph in five minutes** — route target, path, layout, manifest,
   binding, and coordinator on one screen.

### Stage B — Build (20 minutes)

Reader outcome: run a two-screen, URL-aware Flutter app.

4. **Install ZenRouter 3** — exact beta dependency, supported Flutter targets,
   generated vs handwritten setup.
5. **Build your first graph** — typed IDs, manifest patterns, bindings, route
   targets, a root `RouterConfig`, push, and reverse locations.
6. **Navigate without string drift** — `push`, `navigate`, `replace`, `pop`,
   `pushUri`, and why forward matching and reverse routing share a pattern.

### Stage C — Model real UI (35 minutes)

Reader outcome: express common application shells without flattening them into
one global stack.

7. **Paths and layouts** — nested stacks and layout ownership.
8. **Tabs and retained branches** — indexed destinations vs branched stacks.
9. **URLs, parameters, and 404s** — path parameters, rest parameters, query
   state, matching specificity, browser back, and requested-URI preservation.
10. **Guards and redirects** — leaving a route vs resolving an incoming route;
    direct capability vs reusable rule chains.
11. **Restoration and deep-link recovery** — process death, route-owned state,
    and deep-link strategies.

### Stage D — Scale and operate (30 minutes)

Reader outcome: divide ownership and diagnose navigation behavior.

12. **File-based routing** — conventions, generated graph, dynamic and catch-all
    parameters, route groups, layouts, deferred imports.
13. **Scale the graph** — manifest fragments, `CoordinatorModular`, nested
    coordinators, and `CoordinatorView`.
14. **See what the router sees** — DevTools overlay, topology, observed flow,
    history intent, and common diagnostics.
15. **Test navigation contracts** — manifest validation, binding tests, URI
    round trips, guards, and widget boundaries.

### Stage E — Apply or migrate

Reader outcome: adapt the model to a production requirement.

16. **Authentication flow** — preserve intent, redirect once, resume safely.
17. **Bottom navigation** — select indexed destinations or retain branch stacks.
18. **State management** — keep domain state outside routes; let URLs select it.
19. **Migrate to 3.0** — compatibility, deprecations, lifecycle, identity, and
    a staged rollout.
20. **Coming from another router** — concept maps for Navigator, go_router, and
    auto_route, with links to detailed migration notes.

## 5. Information architecture

The web interface presents the learning journey as a book with five parts.
Stable legacy URLs remain valid where practical, but navigation labels and
chapter order follow this outline.

| Part | Chapters | Reader promise |
| --- | --- | --- |
| I. Start with the graph | Start here; Choose a model; Graph in five minutes | Make the right architectural choice |
| II. Build Compass | Install; First graph; Navigate | Reach a working deep link quickly |
| III. Shape the app | Layouts; Tabs; URLs; Policies; Restoration | Model production navigation honestly |
| IV. Grow with confidence | File routing; Modules; DevTools; Tests | Scale ownership and diagnose behavior |
| V. Field guides | Auth; Bottom navigation; State; 3.0 migration; Other routers | Solve a focused production task |

The site also exposes utility destinations outside the chapter sequence:

- **Contents** — the complete ordered journey with a one-line outcome for every
  chapter.
- **Reference** — concise contracts grouped by Coordinator, manifests and
  bindings, paths, route capabilities, Flutter widgets, and generated APIs.
- **Packages** — the role and stability of `zenrouter`, `zenrouter_core`,
  `zenrouter_file_generator`, `zenrouter_file_annotation`, and
  `zenrouter_devtools`.
- **Examples** — source-linked runnable applications, indexed by problem.
- **Migration notes** — versioned changes kept separate from evergreen
  teaching.

## 6. Page contract

Every teaching chapter uses the same order:

1. **Promise** — one sentence describing what the reader will be able to do.
2. **Problem** — a concrete failure mode in a growing Flutter app.
3. **Model** — the ZenRouter invariant in plain language.
4. **Smallest working change** — one focused code path, never a kitchen-sink
   application.
5. **Trace** — what happens from intent to manifest match, route construction,
   path mutation, render, URI, and history.
6. **Choices and trade-offs** — when an adjacent ZenRouter primitive is better.
7. **Failure modes** — two to four specific mistakes and how to recognize them.
8. **Checkpoint** — a short observable result the reader can verify.
9. **Next chapter** — the question that naturally follows.

Reference pages use a different contract: purpose, declaration, parameters,
return/completion behavior, side effects, errors, minimal example, and related
APIs. Tutorials never masquerade as reference, and reference never introduces
a major concept for the first time.

## 7. Voice and editorial rules

- Write to one capable Flutter developer. Use “you” only when it clarifies an
  action; avoid marketing plural and ceremonial prose.
- Lead with the problem or result. Name the API after the reader understands
  the job it performs.
- Prefer “route graph”, “screen”, “URL”, and “stack” over abstract synonyms.
- State release-sensitive facts explicitly. Code examples for this edition use
  `3.0.0-beta.1` and should be re-audited at stable 3.0.
- Explain one new invariant per example. Ellipses are allowed only where the
  omitted code is irrelevant and already introduced.
- Use notes for boundaries, not for essential steps. A reader who ignores the
  margin must still complete the chapter.
- Avoid unsupported superlatives, emoji headings, fake quotations, and long
  “best practices” inventories.
- Use the library spelling exactly: ZenRouter, `RouteManifest`,
  `RouteBinding`, `RouteTarget`, `NavigationPath`, `IndexedStackPath`, and
  `BranchedStackPath`.
- Every public code example must either come from a tested repository example
  or be checked against the current source signatures during review.

## 8. Interface direction

The visual model is a technical book translated to the web, influenced by the
reading experience of gameprogrammingpatterns.com.

The implementation uses Forui as its platform-agnostic UI foundation. The app
root is `WidgetsApp.router` with `FTheme`; navigation controls use `FButton`
and `FTappable`, and page structure uses `FScaffold`. The documentation shell
does not depend on Material components or `ThemeData`.

### Keep from the reference

- A restrained paper field and a centered reading object.
- A narrow main measure (roughly 560–640 px) for long-form prose.
- A light sans-serif display face for chapter titles, a readable serif for
  prose, and a true monospace for code.
- Previous / contents / next controls at both chapter boundaries.
- Marginal notes on wide screens that collapse into inline notes on small
  screens.
- Large chapter openings, small part labels, generous vertical rhythm, and a
  complete book-like contents page.

### Make distinctly ZenRouter

- Brand blue for navigational affordances and manifest edges; amber for route
  destinations and checkpoints.
- A code-native black “book cover” on the home page featuring the ZenRouter
  mark and the line “Navigation as a typed graph.”
- Subtle graph-paper texture rather than the reference site's assets.
- Route diagrams built from labeled nodes and connecting strokes, not copied
  illustrations.
- A visible “3.0 beta” edition marker and links to GitHub / pub.dev.

### Responsive behavior

- **≥ 1040 px:** 640 px reading column plus a 240–270 px margin column.
- **720–1039 px:** centered reading column; notes become full-width inset
  panels; chapter controls keep text labels.
- **< 720 px:** edge-to-edge paper, 20 px gutters, 40–44 px title, horizontally
  scrollable code, compact previous/contents/next labels, and no persistent
  sidebar.

### Accessibility baseline

- Body contrast meets WCAG AA in both themes.
- Text remains readable at 200% zoom without horizontal page scrolling; only
  code blocks may scroll horizontally.
- All navigation controls expose semantic labels and minimum touch targets.
- Color is never the only signal for route kind, active state, note type, or
  code diff.
- Motion is limited to brief hover/focus feedback and respects reduced motion
  where the platform exposes it.

## 9. Content model and maintenance

Chapter metadata is data, not duplicated widget code. Each chapter owns:

- stable path and optional legacy aliases;
- part number and chapter number;
- title, promise, estimated reading time, and keywords;
- Markdown body;
- optional margin notes and checkpoint;
- previous and next links derived from the ordered registry.

The route graph may use a catch-all documentation route so new chapters do not
require a new screen class. The site should still be built with ZenRouter and
use its generated manifest, bindings, reverse parsing, layouts, and URL
recovery as a live example of the documented model.

Source-of-truth rules:

1. API behavior comes from the current public exports, source, and tests.
2. Runnable examples come from `packages/zenrouter/example` or a focused test.
3. Version changes come from `CHANGELOG.md` and `MIGRATION_GUIDE.md`.
4. Long-form Markdown that is not represented in the book remains supporting
   material, not a competing “getting started” path.

## 10. Implementation slices

### Slice 1 — recognizable book

- New home cover and opening copy.
- New contents page showing all five parts.
- One complete chapter using the final reading shell, typography, marginal
  notes, code treatment, and chapter navigation.

### Slice 2 — complete learning path

- Chapter registry and catch-all route.
- All 20 chapter summaries and the essential technical chapters in full.
- Legacy URL mapping for the currently linked site paths.
- Focused field guides for auth, tabs, and migration.

### Slice 3 — verification and handoff

- Route and content registry tests.
- Static analysis and Flutter web build.
- Browser verification at desktop, tablet, and phone widths.
- Link, keyboard, contrast, overflow, and console checks.
- Deployment metadata and a public preview.

## 11. Definition of done

- A new user can reach a working, URL-aware example from the home page in no
  more than two choices.
- The recommended 3.0 path teaches manifests before handwritten URI parsing.
- Every chapter has an explicit outcome, stable place in the journey, previous
  and next navigation, and a checkpoint.
- Current public concepts—manifests, bindings, fragments, atomic commits,
  layout kinds, branched paths, generated locations, `CoordinatorView`, and
  DevTools flow—have a discoverable home.
- Old 2.x guidance is labeled as migration material, not mixed into the main
  tutorial.
- The site visually reads as a ZenRouter technical book and remains usable on
  phone, tablet, desktop, keyboard, and touch.
- The documentation application analyzes cleanly and produces a Flutter web
  release build without errors.
