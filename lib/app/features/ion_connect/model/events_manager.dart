// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';

class EventsManagerConfig {
  const EventsManagerConfig({
    this.backgroundBatchSize = 3,
    this.foregroundBatchSize = 15,
  });

  final int foregroundBatchSize;
  final int backgroundBatchSize;
}

class EventsManager {
  EventsManager(
    this.ref,
    List<GlobalSubscriptionEventHandler?> handlers, {
    this.config = const EventsManagerConfig(),
  }) : _handlers = handlers.whereType<GlobalSubscriptionEventHandler>().toList() {
    _listenToAppLifecycle();
  }

  final Ref ref;
  final EventsManagerConfig config;
  final List<GlobalSubscriptionEventHandler> _handlers;
  final Queue<EventMessage> _eventQueue = Queue<EventMessage>();

  bool _isProcessing = false;
  bool _isAppInForeground = true;

  void _listenToAppLifecycle() {
    ref.listen<AppLifecycleState>(
      appLifecycleProvider,
      (previous, next) {
        if (next == AppLifecycleState.resumed) {
          _isAppInForeground = true;
        } else {
          _isAppInForeground = false;
        }
      },
    );
  }

  int get _currentBatchSize =>
      _isAppInForeground ? config.foregroundBatchSize : config.backgroundBatchSize;

  void dispatch(EventMessage eventMessage) {
    _eventQueue.add(eventMessage);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_eventQueue.isNotEmpty) {
        final batchSize =
            _eventQueue.length > _currentBatchSize ? _currentBatchSize : _eventQueue.length;
        final batch = <EventMessage>[];
        for (var i = 0; i < batchSize; i++) {
          batch.add(_eventQueue.removeFirst());
        }

        // Cache auth state for this batch
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;

        for (final eventMessage in batch) {
          print(
            'Processing event: ${eventMessage.id.substring(0, 5)}, queue size: ${_eventQueue.length}, batch size: $batchSize',
          );

          if (!isAuthenticated) {
            continue;
          }

          final futures = _handlers.where((handler) {
            return handler.canHandle(eventMessage);
          }).map((handler) => handler.handle(eventMessage));

          await Future.wait(futures);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
