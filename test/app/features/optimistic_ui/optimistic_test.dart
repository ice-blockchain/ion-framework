// SPDX-License-Identifier: ice License 1.0
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';

@immutable
class TestModel implements OptimisticModel {
  const TestModel(this.optimisticId, this.value);

  @override
  final String optimisticId;
  final String value;

  @override
  String toString() => '[$optimisticId:$value]';

  @override
  bool operator ==(Object other) =>
      other is TestModel && other.optimisticId == optimisticId && other.value == value;

  @override
  int get hashCode => Object.hash(optimisticId, value);
}

class ToggleValueIntent implements OptimisticIntent<TestModel> {
  @override
  TestModel optimistic(TestModel current) =>
      TestModel(current.optimisticId, current.value == 'A' ? 'B' : 'A');

  @override
  Future<TestModel> sync(TestModel prev, TestModel next) => Future.value(next);
}

class DummySyncStrategy implements SyncStrategy<TestModel> {
  DummySyncStrategy(this.delay);
  final Duration delay;

  @override
  Future<TestModel> send(TestModel prev, TestModel optimistic) async {
    await Future<void>.delayed(delay);
    return optimistic;
  }
}

void main() {
  group('OptimisticOperationManager', () {
    late OptimisticOperationManager<TestModel> operationManager;
    late List<List<TestModel>> emissions;
    late StreamSubscription<List<TestModel>> subscription;

    setUp(() => emissions = []);

    tearDown(() async => subscription.cancel());

    StreamSubscription<List<TestModel>> listen() =>
        operationManager.stream.listen((e) => emissions.add(List.of(e)));

    test('optimistic emission happens before syncCallback completes', () async {
      final optimisticEmitted = Completer<void>();

      operationManager = OptimisticOperationManager<TestModel>(
        syncCallback: (prev, opt) async {
          await optimisticEmitted.future;
          return opt;
        },
        onError: (_, __) async => false,
        enableLocal: true,
      );

      subscription = listen();
      await operationManager.initialize([const TestModel('1', 'A')]);

      subscription.onData((state) {
        emissions.add(List.of(state));
        if (state.any((m) => m.value == 'B') && !optimisticEmitted.isCompleted) {
          optimisticEmitted.complete();
        }
      });

      await operationManager.perform(
        previous: const TestModel('1', 'A'),
        optimistic: const TestModel('1', 'B'),
      );

      await optimisticEmitted.future;

      expect(emissions.length, 3);
      expect(emissions.where((e) => e.any((m) => m.value == 'B')).length, 1);
    });

    test('server stale triggers exactly one follow-up sync', () async {
      var attempts = 0;
      operationManager = OptimisticOperationManager<TestModel>(
        syncCallback: (prev, opt) async {
          attempts++;
          // server returns stale value -> manager will make follow-up
          return TestModel(opt.optimisticId, 'B');
        },
        onError: (_, __) async => false,
        enableLocal: true,
      );

      subscription = listen();
      await operationManager.initialize([const TestModel('1', 'A')]);

      await operationManager.perform(
        previous: const TestModel('1', 'A'),
        optimistic: const TestModel('1', 'C'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(attempts, 2);
      expect(emissions.where((e) => e.any((m) => m.value == 'B')).length, 1);
    });

    test('maxRetries limits attempts and rolls back state', () async {
      var attempts = 0;
      operationManager = OptimisticOperationManager<TestModel>(
        maxRetries: 2,
        syncCallback: (_, __) async {
          attempts++;
          throw Exception('permanent');
        },
        onError: (_, __) async => true, // always retry
        enableLocal: true,
      );

      subscription = listen();
      const initial = TestModel('1', 'A');
      await operationManager.initialize([initial]);

      await operationManager.perform(
        previous: initial,
        optimistic: const TestModel('1', 'B'),
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      expect(attempts, 3); // initial + 2 retries
      expect(emissions.where((e) => e.any((m) => m.value == 'A')).length, 1); // rollback
    });

    test('parallel operations on different ids resolve correctly', () async {
      var attempts = 0;
      operationManager = OptimisticOperationManager<TestModel>(
        syncCallback: (prev, opt) async {
          attempts++;
          return opt;
        },
        onError: (_, __) async => false,
        enableLocal: true,
      );

      subscription = listen();
      await operationManager.initialize([
        const TestModel('1', 'A'),
        const TestModel('2', 'X'),
      ]);

      await operationManager.perform(
        previous: const TestModel('1', 'A'),
        optimistic: const TestModel('1', 'B'),
      );
      await operationManager.perform(
        previous: const TestModel('2', 'X'),
        optimistic: const TestModel('2', 'Y'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(emissions.where((e) => e.any((m) => m.value == 'B')).length, 1);
      expect(emissions.where((e) => e.any((m) => m.value == 'Y')).length, 1);
      expect(attempts, 2);
    });

    test('dispose closes stream and prevents further emissions', () async {
      operationManager = OptimisticOperationManager<TestModel>(
        syncCallback: (prev, opt) async => opt,
        onError: (_, __) async => false,
        enableLocal: true,
      );

      subscription = listen();
      await operationManager.initialize([const TestModel('1', 'A')]);

      operationManager.dispose();

      expect(
        () => operationManager.perform(
          previous: const TestModel('1', 'A'),
          optimistic: const TestModel('1', 'B'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OptimisticService', () {
    test('dispatch emits optimistic value before sync completes', () async {
      final manager = OptimisticOperationManager<TestModel>(
        syncCallback: DummySyncStrategy(const Duration(milliseconds: 200)).send,
        onError: (_, __) async => false,
        enableLocal: true,
      );

      await manager.initialize([const TestModel('1', 'A')]);

      final service = OptimisticService<TestModel>(manager: manager);
      final emissions = <TestModel?>[];

      final sub = service.watch('1').listen(emissions.add);

      await service.dispatch(
        ToggleValueIntent(),
        const TestModel('1', 'A'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.any((e) => e?.value == 'B'), isTrue);
      expect(emissions.length, 2);

      await sub.cancel();
    });
  });
}
