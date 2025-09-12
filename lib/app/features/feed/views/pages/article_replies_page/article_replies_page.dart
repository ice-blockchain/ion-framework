// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/views/components/reply_input_field/reply_input_field.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/views/components/reply_list/reply_list.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class ArticleRepliesPage extends HookConsumerWidget {
  const ArticleRepliesPage({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReply = ref.watch(canReplyProvider(eventReference)).value ?? false;

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.common_comments),
      ),
      body: Column(
        children: [
          const HorizontalSeparator(),
          Flexible(
            child: ReplyList(eventReference: eventReference),
          ),
          if (canReply) ...[
            const HorizontalSeparator(),
            ReplyInputField(eventReference: eventReference),
          ],
        ],
      ),
    );
  }
}
