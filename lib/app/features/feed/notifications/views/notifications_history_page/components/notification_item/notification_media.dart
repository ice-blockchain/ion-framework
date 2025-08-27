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
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

class NotificationMedia extends HookConsumerWidget {
  const NotificationMedia({required this.entity, super.key});

  final IonConnectEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventReference = switch (entity) {
      final GenericRepostEntity repost => repost.data.eventReference,
      _ => entity.toEventReference(),
    };

    final imageUrl = _getImageUrl(ref);

    if (imageUrl == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0.s),
      child: FeedIONConnectNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        authorPubkey: eventReference.masterPubkey,
      ),
    );
  }

  String? _getImageUrl(WidgetRef ref) {
    if (entity.toEventReference().isArticleReference) {
      if (entity is! ArticleEntity) return null;
      return (entity as ArticleEntity).data.image;
    }

    final postData = switch (entity) {
      final ModifiablePostEntity post => post.data,
      final PostEntity post => post.data,
      _ => null,
    };

    if (postData is! EntityDataWithMediaContent) return null;

    final (:content, :media) = ref.watch(cachedParsedMediaProvider(postData));
    return media.firstWhereOrNull((item) => item.mediaType == MediaType.image)?.url;
  }
}
