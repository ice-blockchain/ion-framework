// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../test_utils.dart';

class MockCurrentIdentityKeyNameSelector extends Notifier<String?>
    with Mock
    implements CurrentIdentityKeyNameSelector {}

void main() {
  late ProviderContainer container;
  late MockLocalStorage mockLocalStorage;

  setUp(
    () {
      mockLocalStorage = MockLocalStorage();
      container = createContainer(
        overrides: [
          localStorageProvider.overrideWithValue(mockLocalStorage),
        ],
      );
      container
          .read(currentIdentityKeyNameSelectorProvider.notifier)
          .setCurrentIdentityKeyName('test_user_key');
    },
  );

  group('VideoPlayerPositionDataProvider Tests', () {
    test('returns stored value from local storage with test_user_key', () {
      when(
        () => mockLocalStorage.getString('user_test_user_key:video_position_data'),
      ).thenReturn('{"FirstVideoKey": 1000, "${"SecondVideoKey".hashCode}": 2000}');

      final currentPosition = container.read(videoPlayerPositionDataProvider)['FirstVideoKey'];
      expect(currentPosition, 1000);

      final secondPosition =
          container.read(videoPlayerPositionDataProvider.notifier).getPosition('SecondVideoKey');
      expect(secondPosition, 2000);
    });
  });
}
