// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/replies_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replies_provider.r.g.dart';

@riverpod
class Replies extends _$Replies {
  final Set<EventReference> _fetchedPollRefs = {};
  final Set<EventReference> _pendingPollRefs = {};
  bool _pollsFetchScheduled = false;

  final Set<String> _fetchedUserMetadataPubkeys = {};
  final Set<String> _pendingUserMetadataPubkeys = {};
  bool _userMetadataFetchScheduled = false;

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
        (previous, next) {
          if (next?.data is PagedData) {
            _queuePollFetch(next?.data.items);
            _queueUserMetadataFetch(next?.data.items);
          }
        },
        fireImmediately: true,
      );

    return entitiesPagedData;
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

  void _queueUserMetadataFetch(Set<IonConnectEntity>? entities) {
    if (entities == null || entities.isEmpty) return;

    final uniquePubkeys = entities
        .map((e) => e.masterPubkey)
        .where(
          (pubkey) =>
              !_fetchedUserMetadataPubkeys.contains(pubkey) &&
              !_pendingUserMetadataPubkeys.contains(pubkey),
        )
        .toSet();

    if (uniquePubkeys.isEmpty) return;

    _pendingUserMetadataPubkeys.addAll(uniquePubkeys);
    _fetchUserMetadata();
  }

  Future<void> _fetchUserMetadata() async {
    if (_userMetadataFetchScheduled) return;
    _userMetadataFetchScheduled = true;

    try {
      final toFetch = _drainPendingUserMetadata();
      if (toFetch.isEmpty) return;

      // Mark as fetched immediately to prevent re-queuing while fetch is in progress
      _fetchedUserMetadataPubkeys.addAll(toFetch);

      await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
            eventReferences: toFetch
                .map(
                  (pubkey) => ReplaceableEventReference(
                    masterPubkey: pubkey,
                    kind: UserMetadataEntity.kind,
                  ),
                )
                .toList(),
            search: ProfileBadgesSearchExtension(
              forKind: UserMetadataEntity.kind,
            ).toString(),
          );
    } finally {
      _userMetadataFetchScheduled = false;
      if (_pendingUserMetadataPubkeys.isNotEmpty) {
        unawaited(_fetchUserMetadata());
      }
    }
  }

  List<String> _drainPendingUserMetadata() {
    if (_pendingUserMetadataPubkeys.isEmpty) return const [];
    final list = _pendingUserMetadataPubkeys.toList();
    _pendingUserMetadataPubkeys.clear();
    return list;
  }
}
