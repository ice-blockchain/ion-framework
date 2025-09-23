// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/selected_wallet_view_id_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';

import '../mocks.dart';
import '../test_utils.dart';
import 'data/fake_wallet_view_data.dart';

void main() {
  group('CurrentWalletIdProvider', () {
    test('returns the selected wallet id when it exists in the data', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
          selectedWalletViewIdNotifierProvider.overrideWith(MockSelectedWalletIdNotifier.new),
        ],
      );

      container.read(selectedWalletViewIdNotifierProvider.notifier).selectedWalletId = '1';

      final currentWalletId = await container.read(currentWalletViewIdProvider.future);

      expect(currentWalletId, equals('1'));
    });

    test('returns the first wallet id when selected id does not exist', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
          selectedWalletViewIdNotifierProvider.overrideWith(MockSelectedWalletIdNotifier.new),
        ],
      );

      container.read(selectedWalletViewIdNotifierProvider.notifier).selectedWalletId =
          'non_existing_id';

      final currentWalletId = await container.read(currentWalletViewIdProvider.future);

      expect(currentWalletId, equals(mockedWalletDataArray.first.id));
    });

    test('throws when there are no wallets', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier([]),
          ),
          selectedWalletViewIdNotifierProvider.overrideWith(MockSelectedWalletIdNotifier.new),
        ],
      );

      container.read(selectedWalletViewIdNotifierProvider.notifier).selectedWalletId =
          'non_existing_id';

      expect(() => container.read(currentWalletViewIdProvider.future), throwsStateError);
    });
  });

  group('currentWalletDataProvider', () {
    test('returns the correct wallet data for the current wallet id', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
          selectedWalletViewIdNotifierProvider.overrideWith(MockSelectedWalletIdNotifier.new),
        ],
      );

      container.read(selectedWalletViewIdNotifierProvider.notifier).selectedWalletId = '1';

      final currentWalletData = await container.read(currentWalletViewDataProvider.future);

      expect(currentWalletData.id, equals('1'));
      expect(currentWalletData.name, equals('ice.wallet'));
      expect(currentWalletData.usdBalance, equals(36594.33));
    });

    test('throws StateError when the current wallet id does not exist', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
          currentWalletViewIdProvider.overrideWith((ref) => 'non_existing_id'),
        ],
      );

      try {
        await container.read(currentWalletViewDataProvider.future);
        fail('Expected StateError to be thrown');
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });

  group('walletByIdProvider', () {
    test('returns correct wallet data for given id', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
        ],
      );

      final result = await container.read(walletViewByIdProvider(id: '1').future);

      expect(result, isA<WalletViewData>());
      expect(result.id, '1');
    });

    test('throws when wallet with given id does not exist', () async {
      final container = createContainer(
        overrides: [
          walletViewsDataNotifierProvider.overrideWith(
            () => MockWalletsDataNotifier(mockedWalletDataArray),
          ),
        ],
      );

      try {
        await container.read(walletViewByIdProvider(id: 'non-existent').future);
        fail('Expected StateError to be thrown');
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });
  });
}
