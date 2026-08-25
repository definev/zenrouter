# ZenRouter Domain Context

## Route Target

A presentation-capable destination stored in a navigation path. Route targets
may be constructed by Flutter bindings but are not the source of truth for the
application's static route topology.

## Route Manifest

The immutable, adapter-neutral graph of route and layout IDs, URI patterns,
parent relationships, and layout kinds. A layout kind is a sealed
child-structure contract (unbounded stack, fixed indexed children, or fixed
branch layout roots). Fixed children belong to the kind, not to the layout
node. The manifest owns graph validation, deterministic URI matching,
serialization, and reverse routing. Route IDs are strongly typed in memory. A
Route ID Codec maps them to stable string wire IDs only when the graph crosses
the JSON seam.

## Route Manifest Fragment

An immutable contribution from one Route Module to the application Route
Manifest. A fragment validates its local shape and ID uniqueness, while the
owning modular coordinator validates cross-module parents, indexed children,
branch roots, cycles, and URI conflicts after composing the complete graph.

## Route Binding

An adapter that maps a Route Manifest ID and matched parameters to a concrete
Route Target. File-based routing generates Flutter bindings; future server
adapters may bind the same manifest without importing Flutter.

## Route Binding Registry

The immutable, complete set of Route Bindings for one Route Manifest and Route
Target type. Construction rejects duplicate, unknown, layout, and unbound route
IDs. It owns manifest matching followed by sync or async Route Target creation.

## Navigation Commit

The atomic publication of a completed navigation transaction, including its
monotonic revision, previous/final URI, and browser-history intent.

## Branched Path

A fixed ordered set of Route Layout roots where exactly one branch is active
and every branch resolves an independent child Stack Path. Branch selection and
child navigation history are separate state: switching branches retains the
navigation depth of every branch.

## Invariants

- Static route topology lives in a Route Manifest, never in Flutter widgets.
- Route Manifest IDs are unique across routes and layouts.
- Route Manifest IDs are generic domain values, not intrinsically strings.
- String wire IDs are introduced only by a Route ID Codec during serialization.
- Overlapping URI patterns must have deterministic specificity or fail graph
  construction.
- Reverse routing and forward matching use the same route pattern.
- Flutter and server behavior attach through Route Bindings at the manifest
  seam.
- Branched Path entries are direct child layouts, never leaf Route Targets.
