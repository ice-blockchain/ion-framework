// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/app_links_service.r.dart';
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
/// into the UI event queue. Waits for [appReadyProvider] before processing to
/// ensure the navigator and full app state are initialized.
class ReceiveSharingIntentListener extends HookConsumerWidget {
  const ReceiveSharingIntentListener({super.key});

  void _emitEvent(WidgetRef ref, String text) {
    ref.read(uiEventQueueNotifierProvider.notifier).emit(
          ShowSharedContentEvent(SharedText(text)),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(appReadyProvider).valueOrNull ?? false;
    final initialChecked = useState(false);

    ref.listen(sharedTextStreamProvider, (_, AsyncValue<String> next) {
      if (!isReady) return;
      next.whenData((text) => _emitEvent(ref, text));
    });

    // One-time check for data that arrived before appReady completed
    if (isReady && !initialChecked.value) {
      initialChecked.value = true;
      final current = ref.read(sharedTextStreamProvider);
      if (current is AsyncData<String>) {
        _emitEvent(ref, current.value);
      }
    }

    return const SizedBox.shrink();
  }
}
