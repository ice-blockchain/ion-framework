// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/providers/selected_wallet_view_id_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';
import '../test_utils.dart';
import 'data/fake_wallet_view_data.dart';

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
    },
  );

  group('SelectedWalletIdNotifier Tests', () {
    test('build returns value from localStorage if it exists', () {
      when(
        () => mockLocalStorage.getString(
          SelectedWalletViewIdNotifier.selectedWalletIdKey,
        ),
      ).thenReturn('testWalletId');

      final result = container.read(selectedWalletViewIdNotifierProvider);

      expect(result, 'testWalletId');

      verify(
        () => mockLocalStorage.getString(SelectedWalletViewIdNotifier.selectedWalletIdKey),
      ).called(1);
    });

    test('selectedWalletId setter updates state and localStorage', () {
      final notifier = container.read(selectedWalletViewIdNotifierProvider.notifier);

      when(
        () => mockLocalStorage.setString(any(), any()),
      ).thenAnswer((_) => Future.value());

      notifier.selectedWalletId = 'newWalletId';

      expect(
        container.read(selectedWalletViewIdNotifierProvider),
        'newWalletId',
      );

      verify(
        () => mockLocalStorage.setString(
          SelectedWalletViewIdNotifier.selectedWalletIdKey,
          'newWalletId',
        ),
      ).called(1);
    });

    test('notifier reacts to changes in localStorage', () {
      final listener = Listener<String?>();

      when(
        () => mockLocalStorage.getString(SelectedWalletViewIdNotifier.selectedWalletIdKey),
      ).thenReturn(
        mockedWalletDataArray.first.id,
      );

      container.listen<String?>(
        selectedWalletViewIdNotifierProvider,
        listener.call,
        fireImmediately: true,
      );

      verify(
        () => listener(null, mockedWalletDataArray.first.id),
      ).called(1);

      when(
        () => mockLocalStorage.getString(SelectedWalletViewIdNotifier.selectedWalletIdKey),
      ).thenReturn('updatedWalletId');

      container.refresh(selectedWalletViewIdNotifierProvider);

      verify(
        () => listener(mockedWalletDataArray.first.id, 'updatedWalletId'),
      ).called(1);
    });
  });
}
