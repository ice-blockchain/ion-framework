// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:receive_sharing/receive_sharing.dart';

class ShowSharedContentEvent extends UiEvent {
  ShowSharedContentEvent(this.content)
      : super(id: 'shared_content_${DateTime.now().millisecondsSinceEpoch}');

  final SharedContent content;

  @override
  Future<void> performAction(BuildContext context) async {
    final sharedText = switch (content) {
      SharedText(:final text) => text,
    };
    await ShareExternalContentModalRoute(sharedText: sharedText).push<void>(context);
  }
}

/// Listens to shared text from [receive_sharing] and emits [ShowSharedContentEvent]
/// into the UI event queue.
class ReceiveSharingIntentListener extends HookConsumerWidget {
  const ReceiveSharingIntentListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sharedTextStreamProvider, (_, AsyncValue<String> next) {
      next.whenData((String text) {
        ref.read(uiEventQueueNotifierProvider.notifier).emit(
              ShowSharedContentEvent(SharedText(text)),
            );
      });
    });
    return const SizedBox.shrink();
  }
}
