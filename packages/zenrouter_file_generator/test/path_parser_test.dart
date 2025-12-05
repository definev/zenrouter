import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator/src/analyzer/path_parser.dart';

void main() {
  group('PathParser', () {
    group('parsePath', () {
      test('parses simple static path', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'about.dart',
        );

        expect(segments, ['about']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'about');
      });

      test('parses nested static path', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'settings/profile.dart',
        );

        expect(segments, ['settings', 'profile']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'profile');
      });

      test('parses single dynamic parameter', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'profile/[id].dart',
        );

        expect(segments, ['profile', ':id']);
        expect(params.length, 1);
        expect(params[0].name, 'id');
        expect(isIndex, false);
        expect(fileName, '[id]');
      });

      test('parses multiple dynamic parameters', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'profile/[profileId]/collections/[collectionId].dart',
        );

        expect(segments, [
          'profile',
          ':profileId',
          'collections',
          ':collectionId',
        ]);
        expect(params.length, 2);
        expect(params[0].name, 'profileId');
        expect(params[1].name, 'collectionId');
        expect(isIndex, false);
        expect(fileName, '[collectionId]');
      });

      test('handles index file', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'settings/index.dart',
        );

        expect(segments, ['settings']);
        expect(params, isEmpty);
        expect(isIndex, true);
        expect(fileName, 'index');
      });

      test('handles root index file', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'index.dart',
        );

        expect(segments, isEmpty);
        expect(params, isEmpty);
        expect(isIndex, true);
        expect(fileName, 'index');
      });

      test('skips private files (underscore prefix)', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'settings/_helper.dart',
        );

        expect(segments, ['settings']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, '_helper');
      });

      test('skips route groups (parentheses)', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          '(auth)/login.dart',
        );

        expect(segments, ['login']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'login');
      });

      test('handles nested route groups', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          '(marketing)/(campaigns)/landing.dart',
        );

        expect(segments, ['landing']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'landing');
      });

      test('handles complex path with groups and dynamic params', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          '(auth)/profile/[userId]/settings.dart',
        );

        expect(segments, ['profile', ':userId', 'settings']);
        expect(params.length, 1);
        expect(params[0].name, 'userId');
        expect(isIndex, false);
        expect(fileName, 'settings');
      });

      test('handles path without .dart extension', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'about',
        );

        expect(segments, ['about']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'about');
      });

      test('handles hyphenated path segments', () {
        final (segments, params, isIndex, fileName) = PathParser.parsePath(
          'user-profile/my-settings.dart',
        );

        expect(segments, ['user-profile', 'my-settings']);
        expect(params, isEmpty);
        expect(isIndex, false);
        expect(fileName, 'my-settings');
      });

      test('throws on empty dynamic parameter', () {
        expect(
          () => PathParser.parsePath('profile/[].dart'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('parseLayoutPath', () {
      test('parses simple layout path', () {
        final segments = PathParser.parseLayoutPath('settings/_layout.dart');

        expect(segments, ['settings']);
      });

      test('parses nested layout path', () {
        final segments = PathParser.parseLayoutPath(
          'dashboard/analytics/_layout.dart',
        );

        expect(segments, ['dashboard', 'analytics']);
      });

      test('parses root layout path', () {
        final segments = PathParser.parseLayoutPath('_layout.dart');

        expect(segments, isEmpty);
      });

      test('skips route groups in layout path', () {
        final segments = PathParser.parseLayoutPath(
          '(auth)/login/_layout.dart',
        );

        expect(segments, ['login']);
      });

      test('skips private directories in layout path', () {
        final segments = PathParser.parseLayoutPath(
          'settings/_private/_layout.dart',
        );

        expect(segments, ['settings']);
      });

      test('handles path without .dart extension', () {
        final segments = PathParser.parseLayoutPath('settings/_layout');

        expect(segments, ['settings']);
      });

      test('handles complex nested layout with groups', () {
        final segments = PathParser.parseLayoutPath(
          '(admin)/dashboard/(reports)/weekly/_layout.dart',
        );

        expect(segments, ['dashboard', 'weekly']);
      });
    });
  });
}
