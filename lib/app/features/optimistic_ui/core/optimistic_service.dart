// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

/// Thin wrapper over OptimisticOperationManager
class OptimisticService<T extends OptimisticModel> {
  OptimisticService({required OptimisticOperationManager<T> manager}) : _manager = manager;

  final OptimisticOperationManager<T> _manager;
  Completer<void>? _initializationCompleter;
  bool _isInitialized = false;

  Stream<T?> watch(String id) async* {
    if (!_isInitialized && _initializationCompleter != null) {
      await _initializationCompleter!.future;
    }

    yield get(id);

    yield* _manager.stream.map(
      (l) => l.firstWhereOrNull((e) => e.optimisticId == id),
    );
  }

  T? get(String id) => _manager.snapshot.firstWhereOrNull((e) => e.optimisticId == id);

  /// Dispatches an optimistic intent.
  Future<void> dispatch(OptimisticIntent<T> intent, T current) async =>
      _manager.perform(previous: current, optimistic: intent.optimistic(current));

  /// Initializes the manager with initial state.
  Future<void> initialize(FutureOr<List<T>> init) async {
    _initializationCompleter ??= Completer<void>();

    try {
      await _manager.initialize(init);
      _isInitialized = true;
      if (!_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete();
      }
    } catch (e) {
      if (!_initializationCompleter!.isCompleted) {
        _initializationCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  Future<void> dispose() async => _manager.dispose();
}
