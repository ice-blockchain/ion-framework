// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks.f.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_db_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/repository/event_messages_repository.r.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_bookmarks_notifier.r.g.dart';

@riverpod
Future<BookmarksSetEntity?> bookmarksCollection(
  Ref ref,
  String pubkey,
  String collectionDTag,
) async {
  final request = RequestMessage()
    ..addFilter(
      RequestFilter(
        kinds: const [BookmarksSetEntity.kind],
        authors: [pubkey],
        tags: {
          '#d': [collectionDTag],
        },
      ),
    );

  final eventMessage = await ref.watch(ionConnectNotifierProvider.notifier).requestEvent(request);

  if (eventMessage == null) {
    return null;
  }

  final entity = BookmarksSetEntity.fromEventMessage(eventMessage);

  return entity;
}

@Riverpod(keepAlive: true)
class FeedBookmarksNotifier extends _$FeedBookmarksNotifier {
  @override
  Future<BookmarksSetEntity?> build({
    required String collectionDTag,
  }) async {
    final authState = await ref.watch(authProvider.future);

    if (!authState.isAuthenticated) {
      return null;
    }

    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;
    if (currentPubkey == null || !delegationComplete) {
      return null;
    }

    final bookmarksCollection = await ref.watch(
      bookmarksCollectionProvider(
        currentPubkey,
        collectionDTag,
      ).future,
    );

    return bookmarksCollection;
  }

  Future<void> toggleBookmark(EventReference eventReference) async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final bookmarksCollection = state.valueOrNull;
    if (currentPubkey == null || bookmarksCollection == null) {
      return;
    }
    final newAllBookmarksRefs = <EventReference>[];
    if (bookmarksCollection.data.eventReferences.contains(eventReference)) {
      newAllBookmarksRefs
        ..addAll(bookmarksCollection.data.eventReferences)
        ..remove(eventReference);
    } else {
      newAllBookmarksRefs
        ..add(eventReference)
        ..addAll(bookmarksCollection.data.eventReferences);
    }

    state = AsyncValue.data(
      bookmarksCollection.copyWith(
        data: bookmarksCollection.data.copyWith(eventReferences: newAllBookmarksRefs),
      ),
    );
    try {
      if (bookmarksCollection.data.eventReferences.contains(eventReference)) {
        // If toggling off in the default collection, also remove from all other collections
        if (bookmarksCollection.data.type == BookmarksSetType.homeFeedCollectionsAll.dTagName) {
          final collectionsRefs = await ref.read(
            feedBookmarkCollectionsNotifierProvider.future,
          );
          final collectionsDTags = collectionsRefs
              .map((collectionRef) => collectionRef.dTag)
              .whereType<String>()
              .where((dTag) => dTag != BookmarksSetType.homeFeedCollectionsAll.dTagName)
              .toList();
          await Future.wait(
            collectionsDTags.map(
              (dTag) async {
                final isIncluded = (await ref.read(
                      feedBookmarksNotifierProvider(
                        collectionDTag: dTag,
                      ).future,
                    ))
                        ?.data
                        .eventReferences
                        .contains(eventReference) ??
                    false;
                if (isIncluded) {
                  await ref
                      .read(
                        feedBookmarksNotifierProvider(
                          collectionDTag: dTag,
                        ).notifier,
                      )
                      .toggleBookmark(eventReference);
                }
              },
            ),
          );
        }
      } else {
        if (bookmarksCollection.data.type != BookmarksSetType.homeFeedCollectionsAll.dTagName) {
          final isIncluded = (await ref.read(
                feedBookmarksNotifierProvider(
                  collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
                ).future,
              ))
                  ?.data
                  .eventReferences
                  .contains(eventReference) ??
              false;
          if (!isIncluded) {
            await ref
                .read(
                  feedBookmarksNotifierProvider(
                    collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
                  ).notifier,
                )
                .toggleBookmark(eventReference);
          }
        }
        if (bookmarksCollection.data.type == BookmarksSetType.homeFeedCollectionsAll.dTagName) {
          unawaited(ref.read(ionConnectDbCacheProvider.notifier).saveRef(eventReference));
        }
      }

      final newBookmarksCollectionData = BookmarksSetData(
        type: bookmarksCollection.data.type,
        eventReferences: newAllBookmarksRefs.toList(),
        title: bookmarksCollection.data.title,
      );
      await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(
            newBookmarksCollectionData,
          );
    } catch (e) {
      state = AsyncValue.data(
        bookmarksCollection,
      );
      rethrow;
    }
  }
}

@riverpod
bool isBookmarkedInCollection(
  Ref ref,
  EventReference eventReference, {
  required String collectionDTag,
}) {
  final feedBookmarksNotifierState =
      ref.watch(feedBookmarksNotifierProvider(collectionDTag: collectionDTag));
  return feedBookmarksNotifierState.valueOrNull?.data.eventReferences.contains(eventReference) ??
      false;
}

@riverpod
Future<List<EventReference>> filteredBookmarksRefs(
  Ref ref, {
  required String collectionDTag,
  required String query,
}) async {
  final collectionEntity =
      await ref.watch(feedBookmarksNotifierProvider(collectionDTag: collectionDTag).future);

  final allRefs = collectionEntity?.data.eventReferences ?? [];

  if (query.isEmpty) return allRefs;

  final rawEvents = await ref
      .read(eventMessagesRepositoryProvider)
      .getFiltered(eventReferences: allRefs, query: query);
  return rawEvents.map((event) => event.eventReference).toList();
}

@Riverpod(keepAlive: true)
void feedBookmarksSync(Ref ref) {
  ref.listen<AsyncValue<BookmarksSetEntity?>>(
    feedBookmarksNotifierProvider(collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName),
    (previous, next) {
      final collection = next.value;
      if (collection != null) {
        ref
            .read(ionConnectDbCacheProvider.notifier)
            .saveAllNonExistingRefs(collection.data.eventReferences);
      }
    },
  );
}

@riverpod
class FeedBookmarkCollectionsNotifier extends _$FeedBookmarkCollectionsNotifier {
  @override
  Future<List<ReplaceableEventReference>> build() async {
    keepAliveWhenAuthenticated(ref);
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return [];
    }

    final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;
    if (!delegationComplete) {
      return [];
    }

    final bookmarksCollection = await ref.watch(
      bookmarksCollectionProvider(
        currentPubkey,
        BookmarksSetType.homeFeedCollections.dTagName,
      ).future,
    );
    final collectionsRefs = bookmarksCollection?.data.eventReferences ?? [];

    final bookmarkCollections = collectionsRefs
        .where(
          (collectionsRef) =>
              collectionsRef is ReplaceableEventReference &&
              collectionsRef.kind == BookmarksSetEntity.kind,
        )
        .cast<ReplaceableEventReference>()
        .toList();
    if (bookmarkCollections
        .none((ref) => ref.dTag == BookmarksSetType.homeFeedCollectionsAll.dTagName)) {
      final bookmarksData = BookmarksData(
        eventReferences: [
          ReplaceableEventReference(
            masterPubkey: currentPubkey,
            kind: BookmarksSetEntity.kind,
            dTag: BookmarksSetType.homeFeedCollections.dTagName,
          ),
        ],
      );
      final collectionsData = BookmarksSetData(
        type: BookmarksSetType.homeFeedCollections.dTagName,
        eventReferences: [
          ReplaceableEventReference(
            masterPubkey: currentPubkey,
            kind: BookmarksSetEntity.kind,
            dTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
          ),
        ],
      );
      final defaultBookmarksCollectionData = BookmarksSetData(
        type: BookmarksSetType.homeFeedCollectionsAll.dTagName,
        eventReferences: [],
      );

      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
        [defaultBookmarksCollectionData, collectionsData, bookmarksData],
        actionSource: ActionSourceUser(currentPubkey),
      );
      ref
        ..invalidate(
          bookmarksCollectionProvider(
            currentPubkey,
            BookmarksSetType.homeFeedCollections.dTagName,
          ),
        )
        ..invalidate(
          feedBookmarksNotifierProvider(
            collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
          ),
        );
      bookmarkCollections.add(
        ReplaceableEventReference(
          masterPubkey: currentPubkey,
          kind: BookmarksSetEntity.kind,
          dTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
        ),
      );
    }

    return bookmarkCollections;
  }

  Future<void> createCollection(String title) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    final currentBookmarkCollectionsRefs = state.valueOrNull ?? [];
    if (currentPubkey == null || currentBookmarkCollectionsRefs.isEmpty) {
      return;
    }

    final newCollectionData = BookmarksSetData(
      type: 'homefeed_collection_${generateUuid()}',
      eventReferences: [],
      title: title,
    );

    final updatedCollectionsRefs = <ReplaceableEventReference>[
      ...currentBookmarkCollectionsRefs,
      ReplaceableEventReference(
        masterPubkey: currentPubkey,
        kind: BookmarksSetEntity.kind,
        dTag: newCollectionData.type,
      ),
    ];
    final updatedAllCollectionsData = BookmarksSetData(
      type: BookmarksSetType.homeFeedCollections.dTagName,
      eventReferences: updatedCollectionsRefs,
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
      [newCollectionData, updatedAllCollectionsData],
      actionSource: ActionSourceUser(currentPubkey),
    );

    ref
      ..invalidateSelf()
      ..invalidate(
        bookmarksCollectionProvider(currentPubkey, BookmarksSetType.homeFeedCollections.dTagName),
      )
      ..invalidate(feedBookmarksNotifierProvider);
  }

  Future<void> deleteCollection(String collectionDTag) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    final currentBookmarkCollectionsRefs = state.valueOrNull ?? [];
    if (currentPubkey == null ||
        currentBookmarkCollectionsRefs.isEmpty ||
        collectionDTag == BookmarksSetType.homeFeedCollectionsAll.dTagName) {
      return;
    }

    final updatedRootRefs =
        currentBookmarkCollectionsRefs.where((ref) => ref.dTag != collectionDTag).toList();

    final updatedAllCollectionsData = BookmarksSetData(
      type: BookmarksSetType.homeFeedCollections.dTagName,
      eventReferences: updatedRootRefs,
    );

    final deleteCollectionData = BookmarksSetData(
      type: collectionDTag,
      eventReferences: [],
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData(
      [deleteCollectionData, updatedAllCollectionsData],
      actionSource: ActionSourceUser(currentPubkey),
    );

    ref
      ..invalidateSelf()
      ..invalidate(
        bookmarksCollectionProvider(currentPubkey, BookmarksSetType.homeFeedCollections.dTagName),
      )
      ..invalidate(feedBookmarksNotifierProvider);
  }

  Future<void> renameCollection(
    BookmarksSetData bookmarksCollectionData,
    String newTitle,
  ) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    final currentBookmarkCollectionsRefs = state.valueOrNull ?? [];
    final collectionDTag = bookmarksCollectionData.type;
    if (currentPubkey == null ||
        collectionDTag == BookmarksSetType.homeFeedCollectionsAll.dTagName ||
        !currentBookmarkCollectionsRefs.any((ref) => ref.dTag == collectionDTag)) {
      return;
    }

    final updatedCollectionData = BookmarksSetData(
      type: collectionDTag,
      eventReferences: bookmarksCollectionData.eventReferences,
      title: newTitle,
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(
          updatedCollectionData,
          actionSource: ActionSourceUser(currentPubkey),
        );

    ref
      ..invalidateSelf()
      ..invalidate(
        bookmarksCollectionProvider(currentPubkey, BookmarksSetType.homeFeedCollections.dTagName),
      )
      ..invalidate(feedBookmarksNotifierProvider);
  }
}
