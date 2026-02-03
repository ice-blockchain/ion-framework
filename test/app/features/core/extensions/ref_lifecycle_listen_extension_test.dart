// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/core/extensions/ref_lifecycle_listen_extension.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../test_utils.dart';

void main() {
  void setLifecycle(ProviderContainer container, AppLifecycleState state) {
    container.read(appLifecycleProvider.notifier).newState = state;
  }

  test('fireImmediately emits initial transition with null previous', () {
    final events = <(AppLifecycleStatus?, AppLifecycleStatus)>[];

    final listenerProvider = Provider<void>((ref) {
      ref.listenOnLifecycleTransition(
        fireImmediately: true,
        onTransition: (previous, current) => events.add((previous, current)),
      );
    });

    createContainer().read(listenerProvider);

    expect(events.length, 1);
    expect(events.first.$1, isNull);
    expect(events.first.$2, AppLifecycleStatus.resumed);
  });

  test('without fireImmediately emits on state change', () {
    final events = <(AppLifecycleStatus?, AppLifecycleStatus)>[];

    final listenerProvider = Provider<void>((ref) {
      ref.listenOnLifecycleTransition(
        onTransition: (previous, current) => events.add((previous, current)),
      );
    });

    final container = createContainer()..read(listenerProvider);

    expect(events, isEmpty);

    setLifecycle(container, AppLifecycleState.paused);

    expect(events.length, 1);
    expect(events.first.$1, AppLifecycleStatus.resumed);
    expect(events.first.$2, AppLifecycleStatus.paused);
  });

  test('from/to filters only matching transition', () {
    final events = <(AppLifecycleStatus?, AppLifecycleStatus)>[];

    final listenerProvider = Provider<void>((ref) {
      ref.listenOnLifecycleTransition(
        from: AppLifecycleStatus.paused,
        to: AppLifecycleStatus.resumed,
        onTransition: (previous, current) => events.add((previous, current)),
      );
    });

    final container = createContainer()..read(listenerProvider);

    setLifecycle(container, AppLifecycleState.paused);
    setLifecycle(container, AppLifecycleState.resumed);

    expect(events.length, 1);
    expect(events.first.$1, AppLifecycleStatus.paused);
    expect(events.first.$2, AppLifecycleStatus.resumed);
  });

  parameterizedGroup<_FilterCase>('filters', _filterCases, (testCase) {
    test(testCase.name, () {
      final events = <(AppLifecycleStatus?, AppLifecycleStatus)>[];

      final listenerProvider = Provider<void>((ref) {
        ref.listenOnLifecycleTransition(
          from: testCase.from,
          to: testCase.to,
          onTransition: (previous, current) => events.add((previous, current)),
          fireImmediately: testCase.fireImmediately,
        );
      });

      final container = createContainer()..read(listenerProvider);

      for (final state in testCase.sequence) {
        setLifecycle(container, state);
      }

      expect(events, testCase.expected);
    });
  });
}

class _FilterCase {
  const _FilterCase({
    required this.name,
    required this.sequence,
    required this.expected,
    this.from,
    this.to,
    this.fireImmediately = false,
  });

  final String name;
  final List<AppLifecycleState> sequence;
  final List<(AppLifecycleStatus?, AppLifecycleStatus)> expected;
  final AppLifecycleStatus? from;
  final AppLifecycleStatus? to;
  final bool fireImmediately;
}

const _filterCases = <_FilterCase>[
  _FilterCase(
    name: 'to-only matches any source',
    to: AppLifecycleStatus.paused,
    sequence: [AppLifecycleState.paused],
    expected: [(AppLifecycleStatus.resumed, AppLifecycleStatus.paused)],
  ),
  _FilterCase(
    name: 'from-only matches any destination',
    from: AppLifecycleStatus.paused,
    sequence: [AppLifecycleState.paused, AppLifecycleState.resumed],
    expected: [(AppLifecycleStatus.paused, AppLifecycleStatus.resumed)],
  ),
  _FilterCase(
    name: 'hidden mapping',
    to: AppLifecycleStatus.hidden,
    sequence: [AppLifecycleState.hidden],
    expected: [(AppLifecycleStatus.resumed, AppLifecycleStatus.hidden)],
  ),
  _FilterCase(
    name: 'ignore same state transition',
    to: AppLifecycleStatus.resumed,
    sequence: [AppLifecycleState.resumed],
    expected: [],
  ),
  _FilterCase(
    name: 'fireImmediately respects filters',
    to: AppLifecycleStatus.paused,
    fireImmediately: true,
    sequence: [],
    expected: [],
  ),
];
