// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ui_event_queue_notifier.r.g.dart';

abstract class UiEvent {
  const UiEvent({this.id});

  final String? id;

  FutureOr<void> performAction(BuildContext context);
}

@Riverpod(keepAlive: true)
class UiEventQueueNotifier extends _$UiEventQueueNotifier {
  @override
  Queue<UiEvent> build() {
    return Queue();
  }

  bool _processing = false;

  void emit(UiEvent event) {
    final eventId = event.id;
    if (eventId != null && state.any((queuedEvent) => queuedEvent.id == eventId)) {
      return;
    }
    state = Queue.of(state)..add(event);
  }

  Future<void> processQueue(
    Future<void> Function(UiEvent event) processor,
  ) async {
    if (_processing) {
      return;
    }

    _processing = true;
    try {
      while (state.isNotEmpty) {
        await _consume(processor);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _consume(Future<void> Function(UiEvent event) processor) async {
    if (state.isEmpty) {
      return;
    }

    final event = state.first;
    try {
      await processor(event);
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace);
    } finally {
      state = Queue.of(state)..remove(event);
    }
  }
}
