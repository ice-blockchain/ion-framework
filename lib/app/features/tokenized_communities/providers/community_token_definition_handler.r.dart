// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/views/creator_token_is_live_dialog.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_handler.r.g.dart';

class CommunityTokenDefinitionHandler extends GlobalSubscriptionEventHandler {
  CommunityTokenDefinitionHandler({
    required this.localStorage,
    required this.ionConnectCache,
    required this.uiEventQueueCallback,
    required this.currentUserMasterPubkey,
  });

  final LocalStorage localStorage;
  final IonConnectCache ionConnectCache;
  final String? currentUserMasterPubkey;
  final VoidCallback uiEventQueueCallback;

  String get localStorageKey => 'creator_token_is_live_dialog_shown_$currentUserMasterPubkey';

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == CommunityTokenDefinitionEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final isFirstBuyEvent = currentUserMasterPubkey != null &&
        eventMessage.tags
            .any((tag) => tag.equals([RelatedHashtag.tagName, 'community_token_action'])) &&
        eventMessage.tags.any((tag) => tag.equals([PubkeyTag.tagName, currentUserMasterPubkey!]));

    final isShown = localStorage.getBool(localStorageKey) ?? false;

    if (!isShown && isFirstBuyEvent) {
      uiEventQueueCallback();
      await localStorage.setBool(key: localStorageKey, value: true);
    }

    final entity = CommunityTokenDefinitionEntity.fromEventMessage(eventMessage);
    await ionConnectCache.cache(entity);
  }
}

@riverpod
CommunityTokenDefinitionHandler communityTokenDefinitionHandler(Ref ref) {
  final localStorage = ref.watch(localStorageProvider);
  final cache = ref.watch(ionConnectCacheProvider.notifier);
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  void uiEventQueueCallback() {
    ref.read(uiEventQueueNotifierProvider.notifier).emit(const CreatorTokenIsLiveDialogEvent());
  }

  return CommunityTokenDefinitionHandler(
    ionConnectCache: cache,
    localStorage: localStorage,
    uiEventQueueCallback: uiEventQueueCallback,
    currentUserMasterPubkey: currentUserMasterPubkey,
  );
}
