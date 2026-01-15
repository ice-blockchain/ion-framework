// SPDX-License-Identifier: ice License 1.0

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ui_event_queue_notifier.r.g.dart';

@immutable
abstract class UiEvent {
  const UiEvent({required this.id});

  final String id;

  Future<void> performAction(BuildContext context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@Riverpod(keepAlive: true)
class UiEventQueueNotifier extends _$UiEventQueueNotifier {
  @override
  Queue<UiEvent> build() {
    return Queue();
  }

  bool _processing = false;

  void emit(UiEvent event) {
    if (!state.contains(event)) {
      state = Queue.of(state)..add(event);
    }
  }

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (state.isNotEmpty) {
        final event = state.first;
        state = Queue.of(state)..removeFirst();
        try {
          await event.performAction(rootNavigatorKey.currentContext!);
        } catch (error, stackTrace) {
          Logger.error(error, stackTrace: stackTrace);
        }
      }
    } finally {
      _processing = false;
    }
  }
}
