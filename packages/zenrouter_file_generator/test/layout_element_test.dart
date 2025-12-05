import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator/src/analyzer/layout_element.dart';
import 'package:zenrouter_file_generator/src/annotations.dart';

void main() {
  group('LayoutElement', () {
    group('uriPattern', () {
      test('returns / for empty path segments (root layout)', () {
        final layout = LayoutElement(
          className: 'RootLayout',
          relativePath: '_layout',
          pathSegments: [],
          layoutType: LayoutType.stack,
        );

        expect(layout.uriPattern, '/');
      });

      test('returns correct pattern for nested layout', () {
        final layout = LayoutElement(
          className: 'SettingsLayout',
          relativePath: 'settings/_layout',
          pathSegments: ['settings'],
          layoutType: LayoutType.stack,
        );

        expect(layout.uriPattern, '/settings');
      });

      test('returns correct pattern for deeply nested layout', () {
        final layout = LayoutElement(
          className: 'ProfileSettingsLayout',
          relativePath: 'profile/settings/_layout',
          pathSegments: ['profile', 'settings'],
          layoutType: LayoutType.indexed,
        );

        expect(layout.uriPattern, '/profile/settings');
      });
    });

    group('generatedBaseClassName', () {
      test('returns prefixed class name', () {
        final layout = LayoutElement(
          className: 'TabsLayout',
          relativePath: 'tabs/_layout',
          pathSegments: ['tabs'],
          layoutType: LayoutType.indexed,
        );

        expect(layout.generatedBaseClassName, r'_$TabsLayout');
      });
    });

    group('pathFieldName', () {
      test('converts layout name to path field name', () {
        final layout = LayoutElement(
          className: 'TabsLayout',
          relativePath: 'tabs/_layout',
          pathSegments: ['tabs'],
          layoutType: LayoutType.indexed,
        );

        expect(layout.pathFieldName, 'tabsPath');
      });

      test('handles multi-word layout names', () {
        final layout = LayoutElement(
          className: 'MainNavigationLayout',
          relativePath: 'main/_layout',
          pathSegments: ['main'],
          layoutType: LayoutType.stack,
        );

        expect(layout.pathFieldName, 'mainNavigationPath');
      });

      test('handles layout without Layout suffix', () {
        // This is an edge case - class names should end with Layout
        // but the method handles it gracefully
        final layout = LayoutElement(
          className: 'Dashboard',
          relativePath: 'dashboard/_layout',
          pathSegments: ['dashboard'],
          layoutType: LayoutType.stack,
        );

        expect(layout.pathFieldName, 'dashboardPath');
      });
    });

    group('layoutType', () {
      test('stores stack layout type', () {
        final layout = LayoutElement(
          className: 'SettingsLayout',
          relativePath: 'settings/_layout',
          pathSegments: ['settings'],
          layoutType: LayoutType.stack,
        );

        expect(layout.layoutType, LayoutType.stack);
      });

      test('stores indexed layout type', () {
        final layout = LayoutElement(
          className: 'TabsLayout',
          relativePath: 'tabs/_layout',
          pathSegments: ['tabs'],
          layoutType: LayoutType.indexed,
        );

        expect(layout.layoutType, LayoutType.indexed);
      });
    });

    group('indexedRouteTypes', () {
      test('stores indexed route types for indexed layout', () {
        final layout = LayoutElement(
          className: 'TabsLayout',
          relativePath: 'tabs/_layout',
          pathSegments: ['tabs'],
          layoutType: LayoutType.indexed,
          indexedRouteTypes: ['HomeRoute', 'ProfileRoute', 'SettingsRoute'],
        );

        expect(layout.indexedRouteTypes, [
          'HomeRoute',
          'ProfileRoute',
          'SettingsRoute',
        ]);
      });

      test('defaults to empty list', () {
        final layout = LayoutElement(
          className: 'StackLayout',
          relativePath: 'stack/_layout',
          pathSegments: ['stack'],
          layoutType: LayoutType.stack,
        );

        expect(layout.indexedRouteTypes, isEmpty);
      });
    });

    group('parentLayoutType', () {
      test('stores parent layout type for nested layouts', () {
        final layout = LayoutElement(
          className: 'NestedLayout',
          relativePath: 'parent/nested/_layout',
          pathSegments: ['parent', 'nested'],
          layoutType: LayoutType.stack,
          parentLayoutType: 'ParentLayout',
        );

        expect(layout.parentLayoutType, 'ParentLayout');
      });

      test('defaults to null for root layouts', () {
        final layout = LayoutElement(
          className: 'RootLayout',
          relativePath: '_layout',
          pathSegments: [],
          layoutType: LayoutType.stack,
        );

        expect(layout.parentLayoutType, null);
      });
    });

    group('copyWith', () {
      test('copies with new parentLayoutType', () {
        final layout = LayoutElement(
          className: 'ChildLayout',
          relativePath: 'child/_layout',
          pathSegments: ['child'],
          layoutType: LayoutType.stack,
          parentLayoutType: null,
        );

        final copied = layout.copyWith(parentLayoutType: 'ParentLayout');

        expect(copied.className, 'ChildLayout');
        expect(copied.relativePath, 'child/_layout');
        expect(copied.parentLayoutType, 'ParentLayout');
      });

      test('preserves other properties when copying', () {
        final layout = LayoutElement(
          className: 'TabsLayout',
          relativePath: 'tabs/_layout',
          pathSegments: ['tabs'],
          layoutType: LayoutType.indexed,
          indexedRouteTypes: ['HomeRoute', 'ProfileRoute'],
          parentLayoutType: 'RootLayout',
        );

        final copied = layout.copyWith(parentLayoutType: 'NewParent');

        expect(copied.layoutType, LayoutType.indexed);
        expect(copied.indexedRouteTypes, ['HomeRoute', 'ProfileRoute']);
        expect(copied.pathSegments, ['tabs']);
        expect(copied.parentLayoutType, 'NewParent');
      });

      test('keeps existing parentLayoutType if null passed', () {
        final layout = LayoutElement(
          className: 'ChildLayout',
          relativePath: 'child/_layout',
          pathSegments: ['child'],
          layoutType: LayoutType.stack,
          parentLayoutType: 'ExistingParent',
        );

        final copied = layout.copyWith();

        expect(copied.parentLayoutType, 'ExistingParent');
      });
    });
  });
}
