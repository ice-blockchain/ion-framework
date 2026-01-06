// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/notifications/data/repository/token_launch_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_launch_notification_handler.r.g.dart';

class TokenLaunchNotificationHandler extends GlobalSubscriptionEventHandler {
  TokenLaunchNotificationHandler(
    this.tokenLaunchRepository,
    this.currentMasterPubkey,
  );

  final TokenLaunchRepository tokenLaunchRepository;
  final String currentMasterPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    if (eventMessage.kind != CommunityTokenDefinitionEntity.kind) {
      return false;
    }

    if (eventMessage.masterPubkey == currentMasterPubkey) {
      return false;
    }

    return true;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final entity = CommunityTokenDefinitionEntity.fromEventMessage(eventMessage);
    await tokenLaunchRepository.save(entity);
  }
}

@riverpod
TokenLaunchNotificationHandler? tokenLaunchNotificationHandler(Ref ref) {
  final tokenLaunchRepository = ref.watch(tokenLaunchRepositoryProvider);
  final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentMasterPubkey == null) {
    return null;
  }

  return TokenLaunchNotificationHandler(tokenLaunchRepository, currentMasterPubkey);
}
