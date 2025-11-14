// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/message_reactions_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

bool useHasReaction(EventReference eventReference, WidgetRef ref) {
  final reactions =
      ref.watch(messageReactionWatchProvider(eventReference)).valueOrNull?.reactions ?? [];
  final hasReactions = reactions.any((r) => r.masterPubkeys.isNotEmpty);

  return hasReactions;
}
