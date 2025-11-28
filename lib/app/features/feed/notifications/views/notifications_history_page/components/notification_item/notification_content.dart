// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
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

    final isReply = entity is ModifiablePostEntity && (entity as ModifiablePostEntity).data.isReply;

    return Column(
      children: [
        PostContent(entity: entity),
        if (isReply)
          CounterItemsFooter(
            eventReference: eventReference,
            sidePadding: 0,
            itemPadding: EdgeInsetsDirectional.only(top: 10.0.s),
          ),
      ],
    );
  }
}
