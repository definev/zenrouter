import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('NavigationGraph', () {
    test('projects manifest topology with deterministic branch ordering', () {
      final graph = NavigationGraph<_NodeId>.fromManifest(
        manifest: _manifest,
        currentUri: Uri.parse('/feed/42'),
      );

      expect(graph.name, 'test-app');
      expect(graph.routeCount, 4);
      expect(graph.layoutCount, 2);
      expect(graph.rootIds, [_NodeId.shell, _NodeId.about]);
      expect(graph[_NodeId.shell]!.childIds, [_NodeId.feed, _NodeId.settings]);
      expect(graph[_NodeId.feed]!.depth, 1);
      expect(graph[_NodeId.feedDetail]!.depth, 2);
      expect(graph[_NodeId.feed]!.branchIndex, 0);
      expect(graph[_NodeId.settings]!.branchIndex, 1);
      expect(graph[_NodeId.feedHome]!.branchIndex, isNull);
    });

    test('marks the matched route and all layout ancestors active', () {
      final graph = NavigationGraph<_NodeId>.fromManifest(
        manifest: _manifest,
        currentUri: Uri.parse('/feed/42?from=test'),
      );

      expect(graph.activeRouteId, _NodeId.feedDetail);
      expect(graph.activeNodeIds, {
        _NodeId.shell,
        _NodeId.feed,
        _NodeId.feedDetail,
      });
      expect(graph.currentUri.queryParameters, {'from': 'test'});
    });

    test('keeps the topology visible when the URI does not match', () {
      final graph = NavigationGraph<_NodeId>.fromManifest(
        manifest: _manifest,
        currentUri: Uri.parse('/missing'),
        labelForId: (id) => id.name.toUpperCase(),
      );

      expect(graph.nodes, hasLength(6));
      expect(graph.activeRouteId, isNull);
      expect(graph.activeNodeIds, isEmpty);
      expect(graph[_NodeId.feed]!.label, 'FEED');
    });

    test('preserves declared branched layout order', () {
      final manifest = RouteManifest<_BranchedId>(
        name: 'branched-app',
        idCodec: RouteIdCodec.enumValues(_BranchedId.values),
        routes: [
          RouteManifestRoute(
            id: _BranchedId.leftHome,
            path: '/left',
            parentId: _BranchedId.left,
          ),
          RouteManifestRoute(
            id: _BranchedId.rightHome,
            path: '/right',
            parentId: _BranchedId.right,
          ),
        ],
        layouts: [
          RouteManifestLayout(
            id: _BranchedId.shell,
            path: '/',
            kind: RouteManifestLayoutKind.branched,
            branchChildIds: [_BranchedId.right, _BranchedId.left],
          ),
          RouteManifestLayout(
            id: _BranchedId.left,
            path: '/left',
            parentId: _BranchedId.shell,
            kind: RouteManifestLayoutKind.stack,
          ),
          RouteManifestLayout(
            id: _BranchedId.right,
            path: '/right',
            parentId: _BranchedId.shell,
            kind: RouteManifestLayoutKind.stack,
          ),
        ],
      );

      final graph = NavigationGraph<_BranchedId>.fromManifest(
        manifest: manifest,
        currentUri: Uri.parse('/right'),
      );

      expect(
        graph[_BranchedId.shell]!.kind,
        NavigationGraphNodeKind.branchedLayout,
      );
      expect(graph[_BranchedId.shell]!.childIds, [
        _BranchedId.right,
        _BranchedId.left,
      ]);
      expect(graph[_BranchedId.right]!.branchIndex, 0);
      expect(graph[_BranchedId.left]!.branchIndex, 1);
      expect(graph.activeNodeIds, {
        _BranchedId.shell,
        _BranchedId.right,
        _BranchedId.rightHome,
      });
    });
  });
}

enum _NodeId { shell, feed, settings, feedHome, feedDetail, about }

final _manifest = RouteManifest<_NodeId>(
  name: 'test-app',
  idCodec: RouteIdCodec.enumValues(_NodeId.values),
  routes: [
    RouteManifestRoute(
      id: _NodeId.feedHome,
      path: '/feed',
      parentId: _NodeId.feed,
    ),
    RouteManifestRoute(
      id: _NodeId.feedDetail,
      path: '/feed/:id',
      parentId: _NodeId.feed,
    ),
    RouteManifestRoute(
      id: _NodeId.settings,
      path: '/settings',
      parentId: _NodeId.shell,
    ),
    RouteManifestRoute(id: _NodeId.about, path: '/about'),
  ],
  layouts: [
    RouteManifestLayout(
      id: _NodeId.shell,
      path: '/',
      kind: RouteManifestLayoutKind.indexed,
      indexedChildIds: [_NodeId.feed, _NodeId.settings],
    ),
    RouteManifestLayout(
      id: _NodeId.feed,
      path: '/feed',
      parentId: _NodeId.shell,
      kind: RouteManifestLayoutKind.stack,
    ),
  ],
);

enum _BranchedId { shell, left, right, leftHome, rightHome }
