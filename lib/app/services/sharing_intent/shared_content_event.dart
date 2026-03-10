// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/app_links_service.r.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';
import 'package:ion/app/services/sharing_intent/shared_media_stream_provider.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class ShowSharedContentEvent extends UiEvent {
  ShowSharedContentEvent(this.content)
      : super(id: 'shared_content_${DateTime.now().millisecondsSinceEpoch}');

  final SharedContent content;

  @override
  Future<void> performAction(BuildContext context) async {
    switch (content) {
      case SharedText(:final text):
        await ShareExternalContentModalRoute(sharedText: text).push<void>(context);
      case SharedImage(:final paths):
        await ShareExternalImageModalRoute(imagePaths: jsonEncode(paths)).push<void>(context);
    }
  }
}

/// Listens to shared media from [sharedMediaStreamProvider] and emits [ShowSharedContentEvent]
/// into the UI event queue. Waits for [appReadyProvider] before processing to
/// ensure the navigator and full app state are initialized.
class ReceiveSharingIntentListener extends HookConsumerWidget {
  const ReceiveSharingIntentListener({super.key});

  void _emitEvent(WidgetRef ref, SharedContent content) {
    ref.read(uiEventQueueNotifierProvider.notifier).emit(
          ShowSharedContentEvent(content),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(appReadyProvider).valueOrNull ?? false;
    final initialChecked = useState(false);

    ref.listen(sharedMediaStreamProvider, (_, AsyncValue<SharedContent> next) {
      if (!isReady) return;
      next.whenData((content) => _emitEvent(ref, content));
    });

    // One-time check for data that arrived before appReady completed
    if (isReady && !initialChecked.value) {
      initialChecked.value = true;
      final current = ref.read(sharedMediaStreamProvider);
      if (current is AsyncData<SharedContent>) {
        _emitEvent(ref, current.value);
      }
    }

    return const SizedBox.shrink();
  }
}
