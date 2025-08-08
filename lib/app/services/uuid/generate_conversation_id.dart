// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:uuid/uuid.dart';

String generateConversationId({
  required ConversationType conversationType,
  List<String> receiverMasterPubkeys = const [],
}) {
  final sorted = List<String>.from(receiverMasterPubkeys)..sort();

  // For one-to-one conversations, we use v5 UUID to ensure the same conversation ID for the same participants.
  switch (conversationType) {
    case ConversationType.oneToOne:
      return const Uuid().v5(Namespace.nil.value, sorted.join());
    case ConversationType.group:
    case ConversationType.community:
      return const Uuid().v7();
  }
}
