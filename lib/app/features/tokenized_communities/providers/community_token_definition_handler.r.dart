// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/views/creator_token_is_live_dialog.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_handler.r.g.dart';

const localStorageKey = 'creator_token_is_live_dialog_shown';

class CommunityTokenDefinitionHandler extends GlobalSubscriptionEventHandler {
  CommunityTokenDefinitionHandler({
    required this.ionConnectCache,
    required this.localStorage,
    required this.uiEventQueueCallback,
  });

  final LocalStorage localStorage;
  final IonConnectCache ionConnectCache;
  final VoidCallback uiEventQueueCallback;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == CommunityTokenDefinitionEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final isShown = localStorage.getBool(localStorageKey) ?? false;

    if (!isShown) {
      uiEventQueueCallback();
      await localStorage.setBool(key: localStorageKey, value: true);
    }

    final entity = CommunityTokenDefinitionEntity.fromEventMessage(eventMessage);
    await ionConnectCache.cache(entity);
  }
}

@riverpod
CommunityTokenDefinitionHandler communityTokenDefinitionHandler(Ref ref) {
  final localStorage = ref.read(localStorageProvider);
  final cache = ref.read(ionConnectCacheProvider.notifier);

  void uiEventQueueCallback() {
    ref
        .read(uiEventQueueNotifierProvider.notifier)
        .emit(const CreatorTokenIsLiveDialogEvent());
  }

  return CommunityTokenDefinitionHandler(
    ionConnectCache: cache,
    localStorage: localStorage,
    uiEventQueueCallback: uiEventQueueCallback,
  );
}
