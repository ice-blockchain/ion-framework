// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/replies_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
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
  StreamSubscription<EventMessage>? _subscription;

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
    final optimisticSubscription = ref
        .watch(createPostNotifierStreamProvider)
        .where((IonConnectEntity entity) => _isReply(entity, tokenDefinitionEventReference))
        .distinct()
        .listen(_handleReply);

    // Set up live subscription for new comments from other users
    // Only set up if not already active
    if (_subscription == null && dataSource != null && dataSource.isNotEmpty) {
      _setupSubscription(dataSource, tokenDefinitionEventReference);
    }

    // Listen to state changes for poll fetching
    ref
      ..listen<EntitiesPagedDataState?>(
        entitiesPagedDataProvider(dataSource),
        (previous, next) {
          if (next?.data is PagedData) {
            final pagedData = next!.data as PagedData;
            final items = pagedData.items as Set<IonConnectEntity>?;
            _queuePollFetch(items);
          }
        },
        fireImmediately: true,
      )
      ..onDispose(() {
        optimisticSubscription.cancel();
        _closeSubscription();
      });

    return entitiesPagedData;
  }

  void _setupSubscription(
    List<EntitiesDataSource> dataSource,
    EventReference tokenDefinitionEventReference,
  ) {
    if (dataSource.isEmpty) return;

    final firstDataSource = dataSource.first;

    // Set since to current time to only receive NEW events (created after now)
    // Set limit to 0 to not fetch any stored events, only listen for new ones
    final requestFilter = firstDataSource.requestFilter.copyWith(
      since: () => DateTime.now().microsecondsSinceEpoch,
      until: () => null,
      limit: () => 0,
    );
    final requestMessage = RequestMessage()..addFilter(requestFilter);

    final eventsStream = ref.read(
      ionConnectEventsSubscriptionProvider(
        requestMessage,
        actionSource: firstDataSource.actionSource,
      ),
    );

    _subscription = eventsStream.listen(
      (EventMessage event) {
        try {
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
      },
      onError: (Object error, StackTrace stackTrace) {
        Logger.error(error, stackTrace: stackTrace, message: 'Subscription error');
      },
      cancelOnError: false,
    );
  }

  void _closeSubscription() {
    _subscription?.cancel();
    _subscription = null;
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
    if (dataSource == null) {
      return;
    }

    // Check if entity already exists before inserting
    final currentState = ref.read(entitiesPagedDataProvider(dataSource));
    if (currentState?.data.items?.contains(entity) ?? false) {
      return;
    }

    // Comments are sorted newest first, and new comments from subscription are always the newest
    // So we can always insert at the top (index 0)
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
