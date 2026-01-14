// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class UiEventQueueListener extends HookConsumerWidget {
  const UiEventQueueListener({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiEvents = ref.watch(uiEventQueueNotifierProvider);

    useOnInit(
      () {
        ref
            .read(uiEventQueueNotifierProvider.notifier)
            .processQueue(rootNavigatorKey.currentContext!);
      },
      uiEvents.toList(),
    );

    return const SizedBox.shrink();
  }
}
