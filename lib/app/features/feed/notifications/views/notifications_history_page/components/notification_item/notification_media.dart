// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/extensions/riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/generated/assets.gen.dart';

class NotificationMedia extends HookConsumerWidget {
  const NotificationMedia({required this.entity, super.key});

  final IonConnectEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaChild = _buildMediaChild(context, ref);

    if (mediaChild == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsetsDirectional.only(end: 16.s),
      height: 50.s,
      width: 50.s,
      child: mediaChild,
    );
  }

  Widget? _buildMediaChild(BuildContext context, WidgetRef ref) {
    // For reposts, get the original entity to display its media
    final displayEntity = switch (entity) {
      final GenericRepostEntity _ => ref.watch(getRepostedEntityProvider(entity)),
      final RepostEntity _ => ref.watch(getRepostedEntityProvider(entity)),
      _ => entity,
    };

    if (displayEntity == null) {
      return null;
    }

    final eventReference = displayEntity.toEventReference();

    if (displayEntity is ArticleEntity) {
      final articleData = displayEntity.data;
      final imageUrl = articleData.image;
      final thumbUrl =
          articleData.media.values.where((item) => imageUrl == item.url).firstOrNull?.thumb;
      final notificationImage = imageUrl ?? thumbUrl;
      if (notificationImage == null) {
        return null;
      }

      return _NotificationImage(
        url: notificationImage,
        eventReference: eventReference,
      );
    }

    final postData = switch (displayEntity) {
      final ModifiablePostEntity post => post.data,
      final PostEntity post => post.data,
      _ => null,
    };

    if (postData is! EntityDataWithMediaContent) {
      return null;
    }

    final (:content, :media) = ref.watchParsedMediaWithMentions(postData);
    if (content.isEmpty) return null;
    final firstMedia = media.firstWhereOrNull(
      (item) => [MediaType.image, MediaType.video].contains(item.mediaType),
    );

    final notificationImageUrl = firstMedia?.thumb ?? firstMedia?.image;
    if (firstMedia == null || notificationImageUrl == null) {
      return null;
    }

    final notificationImage = _NotificationImage(
      url: notificationImageUrl,
      eventReference: eventReference,
    );

    if (firstMedia.mediaType == MediaType.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          notificationImage,
          Assets.svg.iconVideoPlay.icon(
            color: context.theme.appColors.secondaryBackground,
            fit: BoxFit.scaleDown,
            size: 5.0.s,
          ),
        ],
      );
    }

    return notificationImage;
  }
}

class _NotificationImage extends StatelessWidget {
  const _NotificationImage({
    required this.url,
    required this.eventReference,
  });

  final String url;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0.s),
      child: FeedIONConnectNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        authorPubkey: eventReference.masterPubkey,
      ),
    );
  }
}
