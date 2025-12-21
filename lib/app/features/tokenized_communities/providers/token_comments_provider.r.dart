// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_subscription_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_comments_data_source_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_comments_provider.r.g.dart';

@riverpod
class TokenComments extends _$TokenComments {
  final Set<EventReference> _fetchedPollRefs = {};
  final Set<EventReference> _pendingPollRefs = {};
  bool _pollsFetchScheduled = false;
  StreamSubscription<EventMessage>? _initialSubscription;
  bool _initialSubscriptionSetup = false;
  EventReference? _tokenDefinitionEventReference;

  @override
  EntitiesPagedDataState? build(EventReference tokenDefinitionEventReference) {
    _tokenDefinitionEventReference ??= tokenDefinitionEventReference;
    final dataSource = ref.watch(
        tokenCommentsDataSourceProvider(
          tokenDefinitionEventReference: tokenDefinitionEventReference,
        ),
      );
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));

    // Listen to new replies from createPostNotifierStreamProvider
    final subscription = ref
        .watch(createPostNotifierStreamProvider)
        .where((IonConnectEntity entity) => _isReply(entity, tokenDefinitionEventReference))
        .distinct()
        .listen(_handleReply);

    ref
      ..onDispose(() {
        subscription.cancel();
        _closeInitialSubscription();
      })
      ..listen<EntitiesPagedDataState?>(
        entitiesPagedDataProvider(dataSource),
        (_, EntitiesPagedDataState? next) {
          if (next?.data is PagedData) {
            final pagedData = next!.data as PagedData;
            _queuePollFetch(pagedData.items as Set<IonConnectEntity>?);
            // Set up initial subscription after first fetch completes
            if (!_initialSubscriptionSetup && pagedData.items != null && dataSource != null) {
              _setupInitialSubscription(tokenDefinitionEventReference, dataSource);
              _initialSubscriptionSetup = true;
            }
          }
        },
        fireImmediately: true,
      );

    return entitiesPagedData;
  }

  void _setupInitialSubscription(
    EventReference tokenDefinitionEventReference,
    List<EntitiesDataSource> dataSource,
  ) {
    if (dataSource.isEmpty) return;

    final firstDataSource = dataSource.first;
    final requestMessage = RequestMessage()..addFilter(firstDataSource.requestFilter);

    final eventsStream = ref.read(
        ionConnectEventsSubscriptionProvider(
          requestMessage,
          actionSource: firstDataSource.actionSource,
        ),
      );

    _initialSubscription = eventsStream.listen((EventMessage event) {
      try {
        // Parse the event to get the entity
        final parser = ref.read(eventParserProvider);
        final entity = parser.parse(event);
        // Cache the entity
        ref.read(ionConnectCacheProvider.notifier).cache(entity);

        if (_isReply(entity, tokenDefinitionEventReference)) {
          _handleReply(entity);
        }
      } catch (e, stackTrace) {
        Logger.error(e, stackTrace: stackTrace, message: 'Error processing token comment event');
      }
    });
  }

  void _closeInitialSubscription() {
    _initialSubscription?.cancel();
    _initialSubscription = null;
    _initialSubscriptionSetup = false;
  }

  bool _isReply(IonConnectEntity entity, EventReference parentEventReference) {
    return entity is ModifiablePostEntity &&
        entity.data.parentEvent?.eventReference == parentEventReference;
  }

  void _handleReply(IonConnectEntity entity) {
    final tokenDefinitionRef = _tokenDefinitionEventReference;
    if (tokenDefinitionRef == null) return;

    final dataSource = ref
        .read(tokenCommentsDataSourceProvider(tokenDefinitionEventReference: tokenDefinitionRef));
    if (dataSource == null) return;

    final notifier = ref.read(entitiesPagedDataProvider(dataSource).notifier);

    // For replaceable entities (ModifiablePostEntity), we need to handle replacement
    if (entity is ModifiablePostEntity) {
      final newEventRef = entity.toEventReference();
      final currentItems = ref.read(entitiesPagedDataProvider(dataSource))?.data.items;

      if (currentItems != null) {
        // Convert to list to preserve order and find index
        final itemsList = currentItems.toList();
        int? oldEntityIndex;

        // Find and remove old entity with the same ReplaceableEventReference
        for (var i = 0; i < itemsList.length; i++) {
          final existingEntity = itemsList[i];
          if (existingEntity is ModifiablePostEntity) {
            final existingEventRef = existingEntity.toEventReference();
            // Compare replaceable event references (same kind, masterPubkey, and dTag)
            if (existingEventRef.kind == newEventRef.kind &&
                existingEventRef.masterPubkey == newEventRef.masterPubkey &&
                existingEventRef.dTag == newEventRef.dTag) {
              // Store the index before removing
              oldEntityIndex = i;
              // Remove the old entity
              notifier.deleteEntity(existingEntity);
              break;
            }
          }
        }

        if (entity.isDeleted) {
          return;
        }

        // Insert at the same position if we found the old entity, otherwise at the end
        final insertIndex = oldEntityIndex ?? itemsList.length;
        notifier.insertEntity(entity, index: insertIndex);
        return;
      }

      if (entity.isDeleted) {
        return;
      }
    }

    // Insert the new/updated entity (for non-replaceable entities or if currentItems is null)
    notifier.insertEntity(entity);
  }

  Future<void> loadMore(EventReference tokenDefinitionEventReference) async {
    final dataSource = ref.read(
        tokenCommentsDataSourceProvider(
          tokenDefinitionEventReference: tokenDefinitionEventReference,
        ),
      );
    if (dataSource == null) return;
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
}
