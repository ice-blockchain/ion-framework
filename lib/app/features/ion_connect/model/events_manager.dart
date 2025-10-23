// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/queue.dart';

class EventsManager {
  EventsManager(
    this.ref,
    List<GlobalSubscriptionEventHandler?> handlers, {
    int maxConcurrent = 10,
  })  : _handlers = handlers.whereType<GlobalSubscriptionEventHandler>().toList(),
        _taskQueue = ConcurrentTasksQueue(maxConcurrent: maxConcurrent) {
    _listenToAppLifecycle();
  }

  final Ref ref;
  final ConcurrentTasksQueue _taskQueue;
  final List<GlobalSubscriptionEventHandler> _handlers;

  void _listenToAppLifecycle() {
    ref.listen<AppLifecycleState>(
      appLifecycleProvider,
      (previous, next) {
        if (next != AppLifecycleState.resumed) {
          _taskQueue.cancelAll();
        }
      },
    );
  }

  void dispatch(EventMessage eventMessage) {
    _taskQueue.add(() => _processEvent(eventMessage));
  }

  Future<void> _processEvent(EventMessage eventMessage) async {
    // Check auth state
    final authState = ref.read(authProvider);
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;

    if (!isAuthenticated) {
      _taskQueue.cancelAll();
      return;
    }

    final futures =
        _handlers.where((handler) => handler.canHandle(eventMessage)).map((handler) async {
      try {
        await handler.handle(eventMessage);
      } catch (e, stack) {
        Logger.error(
          e,
          message: 'Error handling event in events manager: $e',
          stackTrace: stack,
        );
      }
    });

    await Future.wait(futures);
  }
}
