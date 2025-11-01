// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/counter.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_config.f.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/feed/data/repository/following_users_fetch_states_repository.r.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_data_source_builders.dart';
import 'package:ion/app/features/feed/providers/feed_request_queue.r.dart';
import 'package:ion/app/features/feed/providers/feed_selected_article_categories_provider.r.dart';
import 'package:ion/app/features/feed/providers/relevant_users_to_fetch_service.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/global_accounts_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_following_content_provider.m.freezed.dart';
part 'feed_following_content_provider.m.g.dart';

@riverpod
class FeedFollowingContent extends _$FeedFollowingContent implements PagedNotifier {
  @override
  FeedFollowingContentState build(
    FeedType feedType, {
    FeedModifier? feedModifier,

    /// Whether to fetch seen events from the local DB when all unseen events are exhausted.
    bool fetchSeen = true,

    /// Whether to automatically fetch the first batch of events when the provider is instantiated.
    bool autoFetch = true,

    /// Whether to use global accounts instead of the current user's following list.
    bool global = false,
  }) {
    if (autoFetch) {
      Future.microtask(fetchEntities);
    }
    return FeedFollowingContentState(
      items: null,
      isLoading: false,
      seenPagination: Pagination(hasMore: fetchSeen),
      unseenPagination: null,
    );
  }

  @override
  Future<void> fetchEntities() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await for (final entity in requestEntities(limit: feedType.pageSize)) {
        state = state.copyWith(items: {...(state.items ?? {}), entity});
      }
      _ensureEmptyState();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Requests entities for the feed:
  /// * First, requests unseen entities from followed users (see [_fetchUnseenEntities]).
  /// * Then, if [fetchSeen] is true, requests seen entities (see [_fetchSeenEntities]).
  Stream<IonConnectEntity> requestEntities({required int limit}) async* {
    Logger.info('$_logTag Requesting events');

    var unseenCount = 0;
    final retryCounter = await _buildRetryCounter();
    await for (final entity in _fetchUnseenEntities(limit: limit, retryCounter: retryCounter)) {
      yield entity;
      unseenCount++;
    }

    Logger.info('$_logTag Got total [$unseenCount] unseen events');

    if (unseenCount < limit && fetchSeen) {
      yield* _fetchSeenEntities(limit: limit - unseenCount);
    }

    Logger.info('$_logTag Done requesting events');
  }

  @override
  void refresh() {
    if (!state.isLoading) ref.invalidateSelf();
  }

  @override
  void insertEntity(IonConnectEntity entity) {
    state = state.copyWith(items: {entity, ...(state.items ?? {})});
  }

  @override
  void deleteEntity(IonConnectEntity entity) {
    final items = state.items;
    if (items == null) return;

    final updatedItems = {...items};
    final removed = updatedItems.remove(entity);

    if (removed) {
      state = state.copyWith(items: updatedItems);
    }
  }

  /// Fetches unseen entities up to the specified [limit].
  ///
  /// This method fetches entities from the followed pubkeys until the limit is reached
  /// or no more unseen entities are available.
  Stream<IonConnectEntity> _fetchUnseenEntities({
    required int limit,
    required Counter retryCounter,
  }) async* {
    if (retryCounter.isReached) return;

    Logger.info('$_logTag Requesting [$limit] unseen events');

    await _refreshUnseenPagination();

    final nextPageSources = await _getNextPageSources(limit: limit);

    if (nextPageSources.isEmpty) return;

    var requestedCount = 0;
    await for (final entity
        in _requestEntitiesFromPubkeys(pubkeys: nextPageSources, retryCounter: retryCounter)) {
      yield entity;
      requestedCount++;
    }

    final remaining = limit - requestedCount;

    Logger.info(
      '$_logTag Got [$requestedCount] unseen events, remaining: [$remaining], tries left: [${retryCounter.triesLeft}]',
    );

    if (remaining > 0) {
      if (retryCounter.isReached) {
        Logger.warning('$_logTag Retry limit reached');
      } else {
        yield* _fetchUnseenEntities(limit: remaining, retryCounter: retryCounter);
      }
    }
  }

  /// Fetches seen entities up to the specified [limit].
  ///
  /// This method fetches entities that have been seen by the user,
  /// excluding those already present in the current state.
  ///
  /// Returns the number of seen entities that could not be fetched (0 if all were fetched).
  Stream<IonConnectEntity> _fetchSeenEntities({required int limit}) async* {
    Logger.info('$_logTag Requesting [$limit] seen events');

    final nextSeenReferences = await _getNextSeenReferences(limit: limit);

    if (nextSeenReferences.isEmpty) return;

    var requestedCount = 0;
    await for (final entity in _requestEntitiesByReferences(eventReferences: nextSeenReferences)) {
      yield entity;
      requestedCount++;
    }

    final remaining = limit - requestedCount;

    Logger.info('$_logTag Got [$requestedCount] seen events, remaining: [$remaining]');

    if (remaining > 0) {
      yield* _fetchSeenEntities(limit: remaining);
    }
  }

  void _ensureEmptyState() {
    if (state.items == null) {
      state = state.copyWith(items: const {});
    }
  }

  /// Returns the list of pubkeys to be used as data sources for fetching events.
  ///
  /// If [global] is true, using not-followed global accounts' pubkeys.
  /// Otherwise, it uses the followed accounts' pubkeys.
  Future<List<String>> _getDataSourcePubkeys() async {
    final followList = await ref.read(currentUserFollowListProvider.future);
    final followListPubkeys = followList?.data.list.map((item) => item.pubkey) ?? [];

    if (global) {
      final globalAccounts = await ref.read(globalAccountsProvider.future);
      final globalAccountsPubkeys =
          globalAccounts.list.map((account) => account.masterPubKey).toSet();
      return globalAccountsPubkeys.difference(followListPubkeys.toSet()).toList();
    } else {
      return followListPubkeys.toList();
    }
  }

  Future<void> _refreshUnseenPagination() async {
    final dataSourcePubkeys = await _getDataSourcePubkeys();
    final newPagination = {
      for (final pubkey in dataSourcePubkeys) pubkey: _getPubkeyPagination(pubkey),
    };
    state = state.copyWith(unseenPagination: newPagination);
  }

  Pagination _getPubkeyPagination(String pubkey) {
    return state.unseenPagination?[pubkey] ?? const Pagination(hasMore: true);
  }

  /// Fetches the next seen event references, excluding those already in the state.
  ///
  /// In case of stories, it fetches only one event per author.
  Future<List<EventReference>> _getNextSeenReferences({required int limit}) async {
    final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);
    final dataSourcePubkeys = await _getDataSourcePubkeys();

    final stateEntityReferences = <EventReference>[];
    final stateEntityPubkeys = <String>{};
    for (final entity in state.items ?? <IonConnectEntity>{}) {
      final reference = entity.toEventReference();
      stateEntityReferences.add(reference);
      stateEntityPubkeys.add(reference.masterPubkey);
    }

    final uniqAuthors = feedType == FeedType.story;
    final pubkeys = uniqAuthors
        ? dataSourcePubkeys.where((pubkey) => !stateEntityPubkeys.contains(pubkey)).toList()
        : dataSourcePubkeys;

    final seenEvents = await seenEventsRepository.getEventReferences(
      feedType: feedType,
      feedModifier: feedModifier,
      excludeReferences: stateEntityReferences,
      pubkeys: pubkeys,
      limit: limit,
      until: state.seenPagination.lastEvent?.createdAt,
      groupByPubkey: uniqAuthors,
    );

    state = state.copyWith(
      seenPagination: state.seenPagination.copyWith(
        hasMore: seenEvents.isNotEmpty,
        lastEvent: seenEvents.lastOrNull,
      ),
    );

    return seenEvents.map((event) => event.eventReference).toList();
  }

  /// Request 1 entity for each provider pubkey and update the state with the results.
  Stream<IonConnectEntity> _requestEntitiesFromPubkeys({
    required Iterable<String> pubkeys,
    required Counter retryCounter,
  }) async* {
    final requestsQueue = await ref.read(feedRequestQueueProvider.future);
    final resultsController = StreamController<IonConnectEntity>();
    final missingEvents = <EventsMetadataEntity>[];

    final requests = [
      for (final pubkey in pubkeys)
        requestsQueue.add(() async {
          if (retryCounter.isReached) return;

          final Pagination(:lastEvent) = _getPubkeyPagination(pubkey);
          final (entity, missing) = await _requestEntityFromPubkey(
            pubkey: pubkey,
            lastEventCreatedAt: lastEvent?.createdAt,
          );

          missingEvents.addAll(missing);

          final valid = await _handleRequestedPubkeyEntity(
            pubkey: pubkey,
            entity: entity,
            lastEventReference: lastEvent?.eventReference,
          );
          if (valid && entity != null) {
            await _saveSeenReposts(entity);
            resultsController.add(entity);
          } else {
            Logger.info('$_logTag No unseen events found for user: $pubkey');
            retryCounter.increment();
          }
          await _updateUserFetchState(pubkey, hasContent: valid);
        }).catchError((Object? error) {
          state = state.copyWith(
            unseenPagination: {
              ...state.unseenPagination!,
              pubkey: _getPubkeyPagination(pubkey).copyWith(hasMore: false),
            },
          );
          Logger.error(
            error ?? '',
            message: 'Error requesting entities for pubkey: $pubkey',
          );
        }),
    ];

    unawaited(
      Future.wait(requests).whenComplete(() {
        resultsController.close();
        if (missingEvents.isNotEmpty) {
          final refs =
              missingEvents.map((event) => event.data.metadataEventReference).nonNulls.toList();
          ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
                eventReferences: refs,
              );
        }
      }),
    );

    yield* resultsController.stream;
  }

  /// Requests a single entity for the given pubkey.
  ///
  /// Requests the most recent entity if pagination is empty or the next entity if not.
  Future<(IonConnectEntity?, List<EventsMetadataEntity>)> _requestEntityFromPubkey({
    required String pubkey,
    required int? lastEventCreatedAt,
  }) async {
    final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);

    final selectedArticleCategories = ref.read(feedSelectedArticleCategoriesProvider);

    final feedConfig = await ref.read(feedConfigProvider.future);
    final FeedEntitiesDataSource(:dataSource, :responseFilter) =
        _getDataSourceForPubkey(pubkey, feedConfig);

    final until = lastEventCreatedAt != null ? lastEventCreatedAt - 1 : null;
    final requestMessage = RequestMessage();
    final filter = dataSource.requestFilter;
    requestMessage.addFilter(
      // Do not use `since` here (from feedConfig.followingReqMaxAge),
      // as we want to request one overflow entity (if it exists),
      // to avoid the unnecessary requests in the future.
      filter.copyWith(
        limit: () => 1,
        until: () => until,
        tags: () => selectedArticleCategories.isEmpty
            ? null
            : {
                '#${RelatedHashtag.tagName}': selectedArticleCategories.toList(),
              },
      ),
    );

    final entities = await ionConnectNotifier
        .requestEntities(requestMessage, actionSource: dataSource.actionSource)
        .toList();

    final missingEntities = entities.whereType<EventsMetadataEntity>().toList();

    return (responseFilter(entities).firstOrNull, missingEntities);
  }

  Stream<IonConnectEntity> _requestEntitiesByReferences({
    required List<EventReference> eventReferences,
  }) async* {
    final requestsQueue = await ref.read(feedRequestQueueProvider.future);
    final resultsController = StreamController<IonConnectEntity>();

    final requests = [
      for (final eventReference in eventReferences)
        requestsQueue.add(() async {
          final entity = await _requestEntityByReference(eventReference: eventReference);
          final valid = await _validateRequestedReferenceEntity(entity: entity);
          if (valid && entity != null) {
            await _saveSeenReposts(entity);
            resultsController.add(entity);
          }
        }).catchError((Object? error) {
          Logger.error(
            error ?? '',
            message: 'Error requesting entities for event reference: $eventReference',
          );
        }),
    ];

    unawaited(Future.wait(requests).whenComplete(resultsController.close));

    yield* resultsController.stream;
  }

  Future<IonConnectEntity?> _requestEntityByReference({
    required EventReference eventReference,
  }) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      throw const CurrentUserNotFoundException();
    }

    final kind =
        eventReference is ReplaceableEventReference ? eventReference.kind : PostEntity.kind;

    final search = SearchExtensions([
      ...SearchExtensions.withCounters(currentPubkey: currentPubkey, forKind: kind).extensions,
      ...SearchExtensions.withAuthors(forKind: kind).extensions,
    ]).toString();

    return ref
        .read(ionConnectEntityProvider(eventReference: eventReference, search: search).future);
  }

  /// Handles the requested entity:
  /// * Updates the provider state: items, pagination.
  /// * Updates the seen entities state
  ///
  /// returns `true` if the entity should be shown to the user
  Future<bool> _handleRequestedPubkeyEntity({
    required String pubkey,
    required IonConnectEntity? entity,
    required EventReference? lastEventReference,
  }) async {
    final pagination = _getPubkeyPagination(pubkey);
    final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);

    // If the entity is null, it means there are no more entities to request for this pubkey.
    if (entity == null) {
      state = state.copyWith(
        unseenPagination: {...state.unseenPagination!, pubkey: pagination.copyWith(hasMore: false)},
      );
      return false;
    }

    // Update the nextEventReference for the previous event (pagination.lastEvent).
    // This maintains the correct sequence of seen events.
    if (lastEventReference != null) {
      await seenEventsRepository.setNextEvent(
        eventReference: lastEventReference,
        nextEventReference: entity.toEventReference(),
        feedType: feedType,
        feedModifier: feedModifier,
      );
    }

    // Checking if the entity has already been seen.
    // If it has, looking for the seen sequence end.
    final seenSequenceEnd = await seenEventsRepository.getSeenSequenceEnd(
      eventReference: entity.toEventReference(),
      feedType: feedType,
      feedModifier: feedModifier,
    );

    if (seenSequenceEnd == null) {
      // If the entity is not seen, we save it as a new seen event,
      // update the state items and pagination.
      // We don't mark stories and trending videos as seen, as they are handled separately when
      // they are actually seen through stories viewer.
      final isTrendingVideo = feedType == FeedType.video && feedModifier is FeedModifierTrending;
      if (feedType != FeedType.story && !isTrendingVideo) {
        await seenEventsRepository.save(entity, feedType: feedType, feedModifier: feedModifier);
      }
      final duplicatedRepost = await _isDuplicatedRepost(entity);
      final isInReqTimeFrame = await _isInReqTimeFrame(entity.createdAt);

      // For stories we fetch only one event per author. The rest are fetched on entering the story view.
      final isStory = feedType == FeedType.story;

      state = state.copyWith(
        unseenPagination: {
          ...state.unseenPagination!,
          pubkey: pagination.copyWith(
            hasMore: isInReqTimeFrame && !isStory,
            lastEvent: (
              eventReference: entity.toEventReference(),
              createdAt: entity.createdAt,
            ),
          ),
        },
      );
      return isInReqTimeFrame && !duplicatedRepost;
    } else {
      // If the entity is seen, we do not insert it to the state,
      // but we update the pagination with the seen sequence end.
      // This is to ensure that we do not request the same entity again
      // and skip all the seen events in between.

      final isInReqTimeFrame = await _isInReqTimeFrame(seenSequenceEnd.createdAt);

      // For stories, we fetch only one event per author. Stop, if no fresh stories found, because
      // we confider all the stories that go after the first seen one as also seen.
      final isStory = feedType == FeedType.story;

      state = state.copyWith(
        unseenPagination: {
          ...state.unseenPagination!,
          pubkey: pagination.copyWith(
            hasMore: isInReqTimeFrame && !isStory,
            lastEvent: (
              eventReference: seenSequenceEnd.eventReference,
              createdAt: seenSequenceEnd.createdAt
            ),
          ),
        },
      );
      return false;
    }
  }

  Future<bool> _validateRequestedReferenceEntity({required IonConnectEntity? entity}) async {
    if (entity == null) return false;
    final duplicatedRepost = await _isDuplicatedRepost(entity);
    return !duplicatedRepost;
  }

  FeedEntitiesDataSource _getDataSourceForPubkey(String pubkey, FeedConfig feedConfig) {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentPubkey == null) {
      throw const CurrentUserNotFoundException();
    }

    final feedModifierFilter = feedModifier?.filter();

    return switch (feedType) {
      FeedType.post => buildPostsDataSource(
          actionSource: ActionSource.user(pubkey),
          authors: [pubkey],
          currentPubkey: currentPubkey,
          searchExtensions: feedModifierFilter?.search,
          tags: feedModifierFilter?.tags,
        ),
      FeedType.article => buildArticlesDataSource(
          actionSource: ActionSource.user(pubkey),
          authors: [pubkey],
          currentPubkey: currentPubkey,
          searchExtensions: feedModifierFilter?.search,
          tags: feedModifierFilter?.tags,
        ),
      FeedType.video => buildVideosDataSource(
          actionSource: ActionSource.user(pubkey),
          authors: [pubkey],
          currentPubkey: currentPubkey,
          searchExtensions: feedModifierFilter?.search,
          tags: feedModifierFilter?.tags,
        ),
      FeedType.story => buildStoriesDataSource(
          actionSource: ActionSource.user(pubkey),
          authors: [pubkey],
          currentPubkey: currentPubkey,
          searchExtensions: [
            StoriesCountSearchExtension(),
            if (feedModifierFilter != null) ...feedModifierFilter.search,
          ],
          tags: feedModifierFilter?.tags,
        ),
    };
  }

  Future<bool> _isInReqTimeFrame(int time) async {
    final feedConfig = await ref.read(feedConfigProvider.future);
    return time.toDateTime.isAfter(DateTime.now().subtract(feedConfig.followingReqMaxAge));
  }

  Future<void> _saveSeenReposts(IonConnectEntity entity) async {
    final repostedEventReference = switch (entity) {
      GenericRepostEntity() => entity.data.eventReference,
      RepostEntity() => entity.data.eventReference,
      _ => null,
    };
    if (repostedEventReference != null) {
      final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);
      await seenEventsRepository.saveSeenRepostedEvent(repostedEventReference);
    }
  }

  Future<bool> _isDuplicatedRepost(IonConnectEntity entity) async {
    final repostedEventReference = switch (entity) {
      GenericRepostEntity() => entity.data.eventReference,
      RepostEntity() => entity.data.eventReference,
      _ => null,
    };
    if (repostedEventReference == null) return false;

    final seenEventsRepository = ref.read(followingFeedSeenEventsRepositoryProvider);
    final seenAt = await seenEventsRepository.getRepostedEventSeenAt(repostedEventReference);

    if (seenAt == null) return false;

    final feedConfig = await ref.read(feedConfigProvider.future);
    return seenAt.isAfter(DateTime.now().subtract(feedConfig.repostThrottleDelay));
  }

  Future<void> _updateUserFetchState(String pubkey, {required bool hasContent}) {
    final repository = ref.read(followingUsersFetchStatesRepositoryProvider);
    return repository.save(
      pubkey,
      feedType: feedType,
      hasContent: hasContent,
      feedModifier: feedModifier,
    );
  }

  Future<Counter> _buildRetryCounter() async {
    final feedConfig = await ref.read(feedConfigProvider.future);
    final maxRetries = (feedType.pageSize * feedConfig.followingMaxRetriesMultiplier).ceil();
    return Counter(limit: maxRetries);
  }

  Future<List<String>> _getNextPageSources({required int limit}) async {
    final dataSourcePubkeys = await _getDataSourcePubkeys();
    final pubkeysWithUnseenData =
        dataSourcePubkeys.where((pubkey) => _getPubkeyPagination(pubkey).hasMore).toList();
    final relevantUsers =
        await ref.read(relevantFollowingUsersToFetchServiceProvider).getRelevantUsersToFetch(
              pubkeysWithUnseenData,
              feedType: feedType,
              feedModifier: feedModifier,
              limit: limit,
            );

    final relevantUsersPubkeys = relevantUsers.map((item) => item.state.pubkey).toList();

    Logger.info(
      relevantUsersPubkeys.isEmpty
          ? '$_logTag No sources for the next page of unseen events'
          : '$_logTag Next page unseen sources are [${relevantUsersPubkeys.length}] users: $relevantUsersPubkeys',
    );

    return relevantUsersPubkeys;
  }

  String get _logTag => '[FEED FOLLOWING ${feedType.name}${global ? " (GLOBAL)" : ""}]';
}

@Freezed(equal: false)
class FeedFollowingContentState with _$FeedFollowingContentState implements PagedState {
  const factory FeedFollowingContentState({
    required Set<IonConnectEntity>? items,
    required Map<String, Pagination>? unseenPagination,
    required Pagination seenPagination,
    required bool isLoading,
  }) = _FeedFollowingContentState;

  const FeedFollowingContentState._();

  @override
  bool get hasMore =>
      unseenPagination == null ||
      unseenPagination!.values.any((pubkey) => pubkey.hasMore) ||
      seenPagination.hasMore;
}

@Freezed(equal: false)
class Pagination with _$Pagination {
  const factory Pagination({
    required bool hasMore,
    ({EventReference eventReference, int createdAt})? lastEvent,
  }) = _Pagination;
}
