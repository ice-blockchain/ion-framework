// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';

void main() {
  group('SelectedTwoFAOptionsNotifier', () {
    late ProviderContainer container;

    final availableTypesStateProvider = StateProvider<AvailableTwoFATypesState>(
      (_) => (types: [TwoFaType.email, TwoFaType.auth], count: 2),
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [
          availableTwoFaTypesProvider.overrideWith(
            (ref) => ref.watch(availableTypesStateProvider),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('keeps selected values after available types provider rebuilds', () {
      container.read(selectedTwoFAOptionsNotifierProvider.notifier)
        ..updateSelectedTwoFaOption(0, TwoFaType.email)
        ..updateSelectedTwoFaOption(1, TwoFaType.auth);

      container.read(availableTypesStateProvider.notifier).state = (
        types: [TwoFaType.auth, TwoFaType.email],
        count: 2,
      );

      final state = container.read(selectedTwoFAOptionsNotifierProvider);
      expect(state.selectedValues, [TwoFaType.email, TwoFaType.auth]);
      expect(
        container.read(selectedTwoFaOptionsProvider),
        {TwoFaType.email, TwoFaType.auth},
      );
    });

    test('keeps selections unchanged when available options update mid-flow', () {
      container.read(selectedTwoFAOptionsNotifierProvider.notifier)
        ..updateSelectedTwoFaOption(0, TwoFaType.email)
        ..updateSelectedTwoFaOption(1, TwoFaType.auth);

      container.read(availableTypesStateProvider.notifier).state = (
        types: [TwoFaType.auth],
        count: 1,
      );

      final state = container.read(selectedTwoFAOptionsNotifierProvider);
      expect(state.selectedValues, [TwoFaType.email, TwoFaType.auth]);
      expect(
        container.read(selectedTwoFaOptionsProvider),
        {TwoFaType.email, TwoFaType.auth},
      );
    });
  });
}
