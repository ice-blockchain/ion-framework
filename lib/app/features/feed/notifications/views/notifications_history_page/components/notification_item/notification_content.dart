// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/views/components/article/article_title.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/post_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

class NotificationContent extends StatelessWidget {
  const NotificationContent({required this.entity, super.key});

  final IonConnectEntity entity;

  @override
  Widget build(BuildContext context) {
    final eventReference = switch (entity) {
      final GenericRepostEntity repost => repost.data.eventReference,
      _ => entity.toEventReference(),
    };

    if (eventReference.isArticleReference) {
      return ArticleTitle(
        eventReference: eventReference,
      );
    }

    return PostContent(entity: entity);
  }
}
