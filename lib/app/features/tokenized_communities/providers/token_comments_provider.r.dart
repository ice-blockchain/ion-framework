// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/replies_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_subscription_provider.r.dart';
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

  @override
  EntitiesPagedDataState? build(EventReference tokenDefinitionEventReference) {
    final dataSource = ref.watch(
      repliesDataSourceProvider(
        eventReference: tokenDefinitionEventReference,
      ),
    );
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));

    // Listen to new replies from createPostNotifierStreamProvider for immediate updates
    // when user creates a comment (optimistic update)
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
        (EntitiesPagedDataState? previous, EntitiesPagedDataState? next) {
          if (next?.data is PagedData) {
            final pagedData = next!.data as PagedData;
            _queuePollFetch(pagedData.items as Set<IonConnectEntity>?);
            // Set up initial subscription after first fetch completes
            // Check if we transitioned from loading to data (fetch completed)
            final wasLoading = previous?.data is PagedLoading;
            final isData = next.data is PagedData;
            if (!_initialSubscriptionSetup &&
                wasLoading &&
                isData &&
                pagedData.items != null &&
                dataSource != null) {
              final pagination = pagedData.pagination as Map<ActionSource, PaginationParams>;
              _setupInitialSubscription(dataSource, pagination);
              _initialSubscriptionSetup = true;
            }
          }
        },
        fireImmediately: true,
      );

    return entitiesPagedData;
  }

  void _setupInitialSubscription(
    List<EntitiesDataSource> dataSource,
    Map<ActionSource, PaginationParams> pagination,
  ) {
    if (dataSource.isEmpty) return;

    final firstDataSource = dataSource.first;
    final paginationParams = pagination[firstDataSource.actionSource];
    // Use the last event time as 'since' to only get new events, not re-fetch existing ones
    final sinceTimestamp = paginationParams?.lastEventTime?.microsecondsSinceEpoch;

    final requestFilter = firstDataSource.requestFilter.copyWith(
      since: () => sinceTimestamp,
    );
    final requestMessage = RequestMessage()..addFilter(requestFilter);

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
    // Skip deleted entities - they will be handled by the cache and UI watching by EventReference
    if (entity is ModifiablePostEntity && entity.isDeleted) {
      return;
    }

    final dataSource =
        ref.read(repliesDataSourceProvider(eventReference: tokenDefinitionEventReference));
    if (dataSource == null) return;

    // The cache automatically handles entity replacements, and the UI watches entities
    // by EventReference, so it will always show the latest version from cache.
    // We just need to insert the entity - if it's an update, the UI will show the
    // updated version from cache when rendering.
    ref.read(entitiesPagedDataProvider(dataSource).notifier).insertEntity(entity);
  }

  Future<void> loadMore(EventReference tokenDefinitionEventReference) async {
    final dataSource = ref.read(
      repliesDataSourceProvider(
        eventReference: tokenDefinitionEventReference,
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
