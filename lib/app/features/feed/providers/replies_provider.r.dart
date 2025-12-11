// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/counters/likes_count_provider.r.dart';
import 'package:ion/app/features/feed/providers/replies_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replies_provider.r.g.dart';

@riverpod
class Replies extends _$Replies {
  final Set<EventReference> _fetchedPollRefs = {};
  final Set<EventReference> _pendingPollRefs = {};
  bool _pollsFetchScheduled = false;

  @override
  EntitiesPagedDataState? build(EventReference eventReference) {
    final dataSource = ref.watch(repliesDataSourceProvider(eventReference: eventReference));
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));

    final subscription = ref
        .watch(createPostNotifierStreamProvider)
        .where((entity) => _isReply(entity, eventReference))
        .distinct()
        .listen(_handleReply);
    ref
      ..onDispose(subscription.cancel)
      ..listen<EntitiesPagedDataState?>(
        entitiesPagedDataProvider(dataSource),
        (_, next) {
          if (next?.data is PagedData) {
            _queuePollFetch(next?.data.items);
          }
        },
        fireImmediately: true,
      );

    return _sortReplies(entitiesPagedData);
  }

  EntitiesPagedDataState? _sortReplies(EntitiesPagedDataState? entitiesPagedData) {
    // Sort the entities: most likes first, then verified accounts, then the rest
    if (entitiesPagedData == null) return null;

    final sortedData = switch (entitiesPagedData.data) {
      PagedLoading(:final items, :final pagination) =>
        Paged<IonConnectEntity, Map<ActionSource, PaginationParams>>.loading(
          _sortEntities(items),
          pagination: pagination,
        ),
      PagedData(:final items, :final pagination) =>
        Paged<IonConnectEntity, Map<ActionSource, PaginationParams>>.data(
          _sortEntities(items),
          pagination: pagination,
        ),
      PagedError(:final items, :final error, :final pagination) =>
        Paged<IonConnectEntity, Map<ActionSource, PaginationParams>>.error(
          _sortEntities(items),
          error: error,
          pagination: pagination,
        ),
    };

    return entitiesPagedData.copyWith(data: sortedData);
  }

  bool _isReply(IonConnectEntity entity, EventReference parentEventReference) {
    return entity is ModifiablePostEntity &&
        entity.data.parentEvent?.eventReference == parentEventReference;
  }

  void _handleReply(IonConnectEntity entity) {
    final dataSource = ref.read(repliesDataSourceProvider(eventReference: eventReference));
    ref.read(entitiesPagedDataProvider(dataSource).notifier).insertEntity(entity);
  }

  Future<void> loadMore(EventReference eventReference) async {
    final dataSource = ref.read(repliesDataSourceProvider(eventReference: eventReference));
    await ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities();
  }

  void _queuePollFetch(Set<IonConnectEntity>? entities) {
    if (entities == null || entities.isEmpty) return;

    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) return;

    final newRefs = _pollRefsFrom(entities);
    if (newRefs.isEmpty) return;

    _pendingPollRefs.addAll(newRefs);
    _fetchPolls();
  }

  List<EventReference> _pollRefsFrom(Set<IonConnectEntity> entities) {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) return const [];

    return entities
        .whereType<ModifiablePostEntity>()
        .where((e) => e.data.poll != null && e.masterPubkey != currentPubkey)
        .map((e) => e.toEventReference())
        // Filter out already fetched poll references
        .where(_fetchedPollRefs.add)
        .toList();
  }

  Future<void> _fetchPolls() async {
    if (_pollsFetchScheduled) return;
    _pollsFetchScheduled = true;

    try {
      final toFetch = _drainPending();
      if (toFetch.isEmpty) return;

      final currentPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentPubkey == null) return;

      await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
            cache: false,
            eventReferences: toFetch,
            search: SearchExtensions([
              PollVotesCountSearchExtension(),
              PollVotesSearchExtension(currentPubkey: currentPubkey),
            ]).toString(),
          );
    } finally {
      _pollsFetchScheduled = false;
      if (_pendingPollRefs.isNotEmpty) {
        unawaited(_fetchPolls());
      }
    }
  }

  List<EventReference> _drainPending() {
    if (_pendingPollRefs.isEmpty) return const [];
    final list = _pendingPollRefs.toList();
    _pendingPollRefs.clear();
    return list;
  }

  Set<IonConnectEntity>? _sortEntities(Set<IonConnectEntity>? entities) {
    if (entities == null || entities.isEmpty) return entities;

    final sortedList = entities.toList()..sort(_compareEntities);
    return sortedList.toSet();
  }

  int _compareEntities(IonConnectEntity a, IonConnectEntity b) {
    // Get like counts
    final aLikes = ref.read(likesCountProvider(a.toEventReference()));
    final bLikes = ref.read(likesCountProvider(b.toEventReference()));

    // Get verified status
    final aVerified = ref.read(isUserVerifiedProvider(a.masterPubkey));
    final bVerified = ref.read(isUserVerifiedProvider(b.masterPubkey));

    // Primary sort: by likes count (descending)
    if (aLikes != bLikes) {
      return bLikes.compareTo(aLikes);
    }

    // Secondary sort: verified accounts first
    if (aVerified != bVerified) {
      return bVerified ? 1 : -1;
    }

    // Tertiary sort: by creation time (newest first) to maintain consistent ordering
    return b.createdAt.compareTo(a.createdAt);
  }
}
