// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_keys_completed_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../mocks.dart';
import '../../../../../test_utils.dart';

void main() {
  late ProviderContainer container;
  late MockLocalStorage mockLocalStorage;

  setUp(() {
    mockLocalStorage = MockLocalStorage();
    container = createContainer(
      overrides: [
        localStorageProvider.overrideWithValue(mockLocalStorage),
      ],
    );
  });

  test('clearCompleted removes recovery keys completion flag for provided identity', () async {
    when(() => mockLocalStorage.remove(any())).thenAnswer((_) => Future.value());

    await container.read(recoveryKeysCompletedProvider.notifier).clearCompleted(
          identityKeyName: 'alice',
        );

    verify(() => mockLocalStorage.remove('user_alice:recovery_keys_completed')).called(1);
  });

  test('clearCompleted invalidates local completion state for current user', () async {
    var isCompleted = true;
    when(() => mockLocalStorage.getBool(any())).thenAnswer((_) => isCompleted);
    when(() => mockLocalStorage.remove(any())).thenAnswer((_) async {
      isCompleted = false;
    });

    await container
        .read(currentIdentityKeyNameSelectorProvider.notifier)
        .setCurrentIdentityKeyName('alice');

    expect(await container.read(recoveryKeysCompletedProvider.future), isTrue);

    await container.read(recoveryKeysCompletedProvider.notifier).clearCompleted(
          identityKeyName: 'alice',
        );

    expect(await container.read(recoveryKeysCompletedProvider.future), isFalse);
  });
}
