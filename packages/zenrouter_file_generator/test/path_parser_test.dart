import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

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

      group('dot-notation file naming', () {
        test('parses simple dot notation', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            'docs.[id].detail.dart',
          );

          expect(segments, ['docs', ':id', 'detail']);
          expect(params.length, 1);
          expect(params[0].name, 'id');
          expect(isIndex, false);
          expect(fileName, 'detail');
        });

        test('parses rest param with dot notation', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            'docs.[...slugs].dart',
          );

          expect(segments, ['docs', '...:slugs']);
          expect(params.length, 1);
          expect(params[0].name, 'slugs');
          expect(params[0].isRest, true);
          expect(isIndex, false);
          expect(fileName, '[...slugs]');
        });

        test('parses hybrid path with trailing dot segments', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            'feed/tab/[id].detail.dart',
          );

          expect(segments, ['feed', 'tab', ':id', 'detail']);
          expect(params.length, 1);
          expect(params[0].name, 'id');
          expect(isIndex, false);
          expect(fileName, 'detail');
        });

        test('parses route group with dot notation', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            '(auth).login.dart',
          );

          expect(segments, ['login']);
          expect(params, isEmpty);
          expect(isIndex, false);
          expect(fileName, 'login');
        });

        test('parses complex hybrid with groups and params', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            '(auth)/settings.[userId].profile.dart',
          );

          expect(segments, ['settings', ':userId', 'profile']);
          expect(params.length, 1);
          expect(params[0].name, 'userId');
          expect(isIndex, false);
          expect(fileName, 'profile');
        });

        test('parses index with dot notation', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            'settings.index.dart',
          );

          expect(segments, ['settings']);
          expect(params, isEmpty);
          expect(isIndex, true);
          expect(fileName, 'index');
        });

        test('parses multiple params with dot notation', () {
          final (segments, params, isIndex, fileName) = PathParser.parsePath(
            'users.[userId].posts.[postId].dart',
          );

          expect(segments, ['users', ':userId', 'posts', ':postId']);
          expect(params.length, 2);
          expect(params[0].name, 'userId');
          expect(params[1].name, 'postId');
          expect(isIndex, false);
          expect(fileName, '[postId]');
        });
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

      test('parses layout path with dot notation', () {
        final segments = PathParser.parseLayoutPath(
          'settings.profile._layout.dart',
        );

        expect(segments, ['settings', 'profile']);
      });
    });
  });
}
