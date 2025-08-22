// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

bool useHasReaction(EventReference eventReference, WidgetRef ref) {
  final reactionsStream = useMemoized(
    () => ref.read(conversationMessageReactionDaoProvider).messageReactions(eventReference),
    [eventReference],
  );

  return useStream(reactionsStream).data?.isNotEmpty ?? false;
}
