// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/features/feed/create_article/providers/create_article_provider.r.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/counters/helpers/counter_cache_helpers.r.dart';
import 'package:ion/app/features/feed/providers/counters/replies_count_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_videos_data_source_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_delete_file_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_entity_provider.r.g.dart';

@riverpod
class DeleteEntityController extends _$DeleteEntityController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> deleteByReference(
    EventReference eventReference, {
    FutureOr<void> Function()? onDelete,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entity =
          await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
      if (entity == null) {
        throw EntityNotFoundException(eventReference);
      }
      await _deleteEntity(entity);
      await onDelete?.call();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error deleting entity $eventReference');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteEntity(
    IonConnectEntity entity, {
    FutureOr<void> Function()? onDelete,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _deleteEntity(entity);
      await onDelete?.call();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error deleting entity $entity');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteEntity(IonConnectEntity entity) async {
    switch (entity) {
      case GenericRepostEntity() || RepostEntity() || PostEntity():
        {
          await _deleteFromServer(entity);
          if (entity is PostEntity) _deleteMedia(entity.data);
          _deleteFromDataSources(entity);
          _deleteFromCache(entity);
          await _deleteFromCounters(entity);
        }
      case ModifiablePostEntity():
        {
          await _deleteFromCounters(entity);
          await ref
              .read(createPostNotifierProvider(CreatePostOption.softDelete).notifier)
              .softDelete(eventReference: entity.toEventReference());
          _deleteFromDataSources(entity);
        }
      case ArticleEntity():
        {
          await ref
              .read(createArticleProvider(CreateArticleOption.softDelete).notifier)
              .softDelete(eventReference: entity.toEventReference());
        }
      case ReactionEntity():
        {
          await _deleteFromServer(entity);
        }
      default:
        {
          throw DeleteEntityUnsupportedTypeException();
        }
    }
  }

  Future<void> _deleteFromServer(IonConnectEntity entity) async {
    final entityKind = switch (entity) {
      ReactionEntity() => ReactionEntity.kind,
      PostEntity() => PostEntity.kind,
      RepostEntity() => RepostEntity.kind,
      GenericRepostEntity() => GenericRepostEntity.kind,
      _ => throw DeleteEntityUnsupportedTypeException(),
    };

    final pubkeysToPublish = switch (entity) {
      ReactionEntity() => [entity.data.eventReference.masterPubkey],
      PostEntity() => parseAndConvertDelta(
          entity.data.richText?.content,
          entity.data.content,
        ).extractMentionPubkeys(),
      RepostEntity() => [entity.data.eventReference.masterPubkey],
      GenericRepostEntity() => [entity.data.eventReference.masterPubkey],
      _ => <String>[],
    };

    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ImmutableEventReference(
            masterPubkey: entity.masterPubkey,
            eventId: entity.id,
            kind: entityKind,
          ),
        ),
      ],
    );

    final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

    final deletionEvent = await ionNotifier.sign(deletionRequest);

    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

    await Future.wait([
      ionNotifier.sendEvent(deletionEvent, cache: false),
      for (final pubkey in pubkeysToPublish)
        ionNotifier.sendEvent(
          deletionEvent,
          actionSource: ActionSourceUser(pubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
    ]);
  }

  void _deleteFromDataSources(IonConnectEntity entity) {
    final notifiers = <PagedNotifier>[
      ref.read(
        entitiesPagedDataProvider(ref.read(userVideosDataSourceProvider(entity.masterPubkey)))
            .notifier,
      ),
      ref.read(
        entitiesPagedDataProvider(ref.read(userPostsDataSourceProvider(entity.masterPubkey)))
            .notifier,
      ),
      ref.read(feedPostsProvider.notifier),
      ref.read(feedStoriesProvider.notifier),
    ];

    for (final notifier in notifiers) {
      notifier.deleteEntity(entity);
    }
  }

  void _deleteFromCache(IonConnectEntity entity) {
    if (entity is CacheableEntity) {
      ref.read(ionConnectCacheProvider.notifier).remove(entity.cacheKey);
    }
  }

  Future<void> _deleteFromCounters(IonConnectEntity entity) async {
    switch (entity) {
      case RepostEntity():
      case GenericRepostEntity():
        // Counter updates are handled by Optimistic UI
        break;
      case ModifiablePostEntity():
        if (entity.data.parentEvent != null) {
          ref
              .read(repliesCountProvider(entity.data.parentEvent!.eventReference).notifier)
              .removeOne();
        } else if (entity.data.quotedEvent != null) {
          await ref.read(quoteCounterUpdaterProvider).updateQuoteCounter(
                entity.data.quotedEvent!.eventReference,
                isAdding: false,
              );
        }
      default:
        break;
    }
  }

  void _deleteMedia(EntityDataWithMediaContent entity) {
    final media = entity.media.values;
    final fileHashes = media.map((e) => e.originalFileHash).toList();
    ref.read(ionConnectDeleteFileNotifierProvider.notifier).deleteMultiple(fileHashes);
  }
}
