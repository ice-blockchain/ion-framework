// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_operation.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:uuid/uuid.dart';

typedef SyncCallback<T extends OptimisticModel> = Future<T> Function(
  T previous,
  T optimistic,
);

typedef ErrorCallback = Future<bool> Function(String message, Object error);

/// Manages optimistic UI operations and state synchronization with the backend.
///
/// Handles optimistic updates, retries, rollback, and error management for a list of [OptimisticModel]s.
/// Emits state changes via a broadcast stream for UI consumption.
class OptimisticOperationManager<T extends OptimisticModel> {
  OptimisticOperationManager({
    required this.syncCallback,
    required this.onError,
    required this.enableLocal,
    this.maxRetries = 3,
    this.clearOnSuccessfulSync = false,
  })  : _state = [],
        _pending = Queue<OptimisticOperation<T>>();

  final SyncCallback<T> syncCallback;
  final ErrorCallback onError;
  final int maxRetries;
  final bool enableLocal;
  final bool clearOnSuccessfulSync;

  final _controller = StreamController<List<T>>.broadcast();
  Stream<List<T>> get stream => _controller.stream;

  List<T> get snapshot => List.unmodifiable(_state);

  final List<T> _state;
  final Queue<OptimisticOperation<T>> _pending;
  bool _busy = false;

  Future<void> initialize(FutureOr<List<T>> initial) async {
    final initialState = await initial;
    if (_controller.isClosed) return;
    _state
      ..clear()
      ..addAll(initialState);
    _controller.add(List.unmodifiable(_state));
  }

  /// Adds a new optimistic operation and triggers processing if idle.
  Future<void> perform({
    required T previous,
    required T optimistic,
  }) async {
    // Remove any pending operations for the same id to avoid conflicts.
    _pending.removeWhere(
      (operation) => operation.previousState.optimisticId == previous.optimisticId,
    );

    final optimisticOperation = OptimisticOperation<T>(
      id: const Uuid().v4(),
      type: T.toString(),
      previousState: previous,
      optimisticState: optimistic,
    );
    Logger.info(
      '[Optimistic UI - ${optimisticOperation.type}] Performing operation: ${optimisticOperation.id}, Optimistic ID: ${previous.optimisticId}',
    );
    if (enableLocal) _applyLocal(optimisticOperation);
    _pending.add(optimisticOperation);

    if (!_busy) await _next();
  }

  void dispose() => _controller.close();

  /// Applies the optimistic state locally and emits the updated state to the stream.
  void _applyLocal(OptimisticOperation<T> optimisticOperation) {
    final stateIndex = _state.indexWhere(
      (model) => model.optimisticId == optimisticOperation.previousState.optimisticId,
    );
    Logger.info(
      '[Optimistic UI - ${optimisticOperation.type}] Applying local state for operation: ${optimisticOperation.id}, Optimistic ID: ${optimisticOperation.previousState.optimisticId}',
    );
    if (stateIndex == -1) {
      _state.add(optimisticOperation.optimisticState);
    } else {
      _state[stateIndex] = optimisticOperation.optimisticState;
    }
    _controller.add(List.unmodifiable(_state));
  }

  /// Schedules and processes the next optimistic operation in the queue.
  /// Handles retries, backend sync, and triggers rollback on failure.
  Future<void> _next() async {
    if (_pending.isEmpty) return;
    _busy = true;

    var optimisticOperation = _pending.removeFirst();
    Logger.info(
      '[Optimistic UI - ${optimisticOperation.type}] Processing operation: ${optimisticOperation.id}, Optimistic ID: ${optimisticOperation.previousState.optimisticId}, Attempt: ${optimisticOperation.retryCount + 1}',
    );

    try {
      optimisticOperation = optimisticOperation.copyWith(status: OperationStatus.processing);
      final backendState = await syncCallback(
        optimisticOperation.previousState,
        optimisticOperation.optimisticState,
      );
      Logger.info(
        '[Optimistic UI - ${optimisticOperation.type}] Sync successful for operation: ${optimisticOperation.id}, Optimistic ID: ${optimisticOperation.previousState.optimisticId}',
      );

      if (!enableLocal) {
        final stateIndex =
            _state.indexWhere((model) => model.optimisticId == backendState.optimisticId);
        if (stateIndex == -1) {
          _state.add(backendState);
        } else {
          _state[stateIndex] = backendState;
        }

        _controller.add(List.unmodifiable(_state));

        return;
      }

      final stateIndex =
          _state.indexWhere((model) => model.optimisticId == backendState.optimisticId);
      final isStateMatching = optimisticOperation.optimisticState == backendState;

      if (!isStateMatching) {
        Logger.info(
          '[Optimistic UI - ${optimisticOperation.type}] Backend state mismatch for operation: ${optimisticOperation.id}. Scheduling follow-up sync.',
        );
        final currentLocalState =
            stateIndex != -1 ? _state[stateIndex] : optimisticOperation.optimisticState;
        await perform(previous: currentLocalState, optimistic: backendState);
      } else if (clearOnSuccessfulSync) {
        final index = _state.indexWhere((model) => model.optimisticId == backendState.optimisticId);
        if (index != -1) {
          _state.removeAt(index);
          _controller.add(List.unmodifiable(_state));
        }
      }
    } catch (error, stackTrace) {
      Logger.warning(
        '[Optimistic UI - ${optimisticOperation.type}] Sync failed for operation: ${optimisticOperation.id}. Error: $error',
      );
      final shouldRetry = await onError('Sync failed (${optimisticOperation.id})', error);
      if (shouldRetry && optimisticOperation.retryCount < maxRetries) {
        final retryDelay = Duration(seconds: pow(2, optimisticOperation.retryCount).toInt());
        Logger.info(
          '[Optimistic UI - ${optimisticOperation.type}] Retrying operation: ${optimisticOperation.id} after ${retryDelay.inSeconds}s (Attempt ${optimisticOperation.retryCount + 2})',
        );
        await Future<void>.delayed(retryDelay);
        _pending.addFirst(
          optimisticOperation.copyWith(
            retryCount: optimisticOperation.retryCount + 1,
            status: OperationStatus.pending,
          ),
        );
      } else {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message:
              '[Optimistic UI - ${optimisticOperation.type}] Operation failed permanently: ${optimisticOperation.id}. Initiating rollback.',
        );
        _rollback(optimisticOperation);
      }
    } finally {
      _busy = false;
      await _next();
    }
  }

  /// Rolls back the optimistic state to the previous state in case of failure.
  void _rollback(OptimisticOperation<T> optimisticOperation) {
    final stateIndex = _state.indexWhere(
      (model) => model.optimisticId == optimisticOperation.optimisticState.optimisticId,
    );
    Logger.info(
      '[Optimistic UI - ${optimisticOperation.type}] Rolling back state for operation: ${optimisticOperation.id}, Optimistic ID: ${optimisticOperation.optimisticState.optimisticId}',
    );
    if (stateIndex != -1) {
      _state[stateIndex] = optimisticOperation.previousState;
      _controller.add(List.unmodifiable(_state));
    }
  }
}
