// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repost_notifier.r.g.dart';

final _createRepostNotifierStreamController = StreamController<IonConnectEntity>.broadcast();

@riverpod
Raw<Stream<IonConnectEntity>> createRepostNotifierStream(Ref ref) {
  return _createRepostNotifierStreamController.stream;
}

@riverpod
class RepostNotifier extends _$RepostNotifier {
  @override
  FutureOr<void> build() {}

  Future<IonConnectEntity> repost({
    required EventReference eventReference,
  }) async {
    state = const AsyncValue.loading();

    return AsyncValue.guard(() async {
      final entity = ref.read(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

      if (entity == null) {
        throw EntityNotFoundException(eventReference);
      }

      // Use original event message if available to preserve all tags and data
      final repostData = switch (entity) {
        PostEntity() => RepostData(
            eventReference: entity.toEventReference(),
            repostedEvent: entity.eventMessage ?? await entity.toEventMessage(entity.data),
          ),
        ModifiablePostEntity() => GenericRepostData(
            eventReference: entity.toEventReference(),
            repostedEvent: entity.eventMessage ?? await entity.toEventMessage(entity.data),
            kind: ModifiablePostEntity.kind,
          ),
        ArticleEntity() => GenericRepostData(
            eventReference: entity.toEventReference(),
            repostedEvent: entity.eventMessage ?? await entity.toEventMessage(entity.data),
            kind: ArticleEntity.kind,
          ),
        _ => throw UnsupportedRepostException(entity.toEventReference()),
      };

      final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

      final repostEvent = await ionNotifier.sign(repostData);

      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

      final (repostEntity, _) = await (
        ionNotifier.sendEvent(repostEvent),
        ionNotifier.sendEvent(
          repostEvent,
          actionSource: ActionSourceUser(eventReference.masterPubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        )
      ).wait;

      if (repostEntity == null) {
        throw const RepostCreationFailedException();
      }

      _createRepostNotifierStreamController.add(repostEntity);
      await _updateInterests(entity);

      return repostEntity;
    }).then((value) {
      state = const AsyncValue.data(null);
      return value.requireValue;
    });
  }

  Future<void> _updateInterests(IonConnectEntity repostedEntity) async {
    final tags = switch (repostedEntity) {
      ModifiablePostEntity() => repostedEntity.data.relatedHashtags,
      PostEntity() => repostedEntity.data.relatedHashtags,
      ArticleEntity() => repostedEntity.data.relatedHashtags,
      _ => throw UnsupportedEntityType(repostedEntity)
    };

    final interactionCategories = tags?.map((tag) => tag.value).toList() ?? [];

    if (interactionCategories.isNotEmpty) {
      await ref
          .read(feedUserInterestsNotifierProvider.notifier)
          .updateInterests(FeedInterestInteraction.repost, interactionCategories);
    }
  }
}
