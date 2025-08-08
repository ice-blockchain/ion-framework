// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/bookmark_sync_strategy_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/model/bookmark.f.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/toggle_bookmark_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmark_provider.r.g.dart';

@riverpod
OptimisticService<Bookmark> bookmarkService(Ref ref, String collectionDTag) {
  final manager = ref.watch(bookmarkManagerProvider(collectionDTag));
  final initialBookmarks = () async {
    final collection = await ref.read(
      feedBookmarksNotifierProvider(collectionDTag: collectionDTag).future,
    );
    final refs = collection?.data.eventReferences ?? <EventReference>[];
    return refs
        .map(
          (eventRef) => Bookmark(
            eventReference: eventRef,
            collectionDTag: collectionDTag,
            bookmarked: true,
          ),
        )
        .toList();
  }();
  final service = OptimisticService<Bookmark>(manager: manager)..initialize(initialBookmarks);
  return service;
}

@riverpod
Stream<Bookmark?> bookmarkWatch(
  Ref ref,
  String collectionDTag,
  EventReference eventReference,
) {
  final service = ref.watch(bookmarkServiceProvider(collectionDTag));
  final optimisticId = '${collectionDTag}_${eventReference.encode()}';
  return service.watch(optimisticId);
}

@riverpod
OptimisticOperationManager<Bookmark> bookmarkManager(Ref ref, String collectionDTag) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(bookmarkSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<Bookmark>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
  );

  ref.onDispose(manager.dispose);
  return manager;
}

@riverpod
class ToggleBookmarkNotifier extends _$ToggleBookmarkNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> toggle({
    required EventReference eventReference,
    required String collectionDTag,
  }) async {
    final service = ref.read(bookmarkServiceProvider(collectionDTag));
    final current = ref.read(bookmarkWatchProvider(collectionDTag, eventReference)).valueOrNull;
    await service.dispatch(
      ToggleBookmarkIntent(),
      current ??
          Bookmark(
            eventReference: eventReference,
            collectionDTag: collectionDTag,
            bookmarked: false,
          ),
    );
  }
}
