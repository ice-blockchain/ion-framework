// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:receive_sharing/receive_sharing.dart';

class ShowSharedTextEvent extends UiEvent {
  ShowSharedTextEvent(this.sharedText)
      : super(id: 'shared_text_${DateTime.now().millisecondsSinceEpoch}');

  final String sharedText;

  @override
  Future<void> performAction(BuildContext context) async {
    /// TODO(neoptolemus): remove this
    print('QWERTY: $sharedText');
    await showSimpleBottomSheet<void>(
      context: context,
      child: SharedTextDummySheet(text: sharedText),
    );
  }
}

/// Listens to shared text from [receive_sharing] and emits [ShowSharedTextEvent]
/// into the UI event queue.
class ReceiveSharingIntentListener extends HookConsumerWidget {
  const ReceiveSharingIntentListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sharedTextStreamProvider, (_, AsyncValue<String> next) {
      next.whenData((String text) {
        ref.read(uiEventQueueNotifierProvider.notifier).emit(ShowSharedTextEvent(text));
      });
    });
    return const SizedBox.shrink();
  }
}
