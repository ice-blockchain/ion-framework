// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/empty_list/empty_list.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/entities_list.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/creators_you_might_like/creators_you_might_like.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/invite_friends_list_item.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedPostsList extends HookConsumerWidget {
  const FeedPostsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(feedPostsProvider.select((state) => state.items));

    if (entities == null) {
      return const EntitiesListSkeleton();
    } else if (entities.isEmpty) {
      return const _EmptyState();
    }

    return EntitiesList(
      items: _getFeedListItems(entities),
      onVideoTap: ({
        required String eventReference,
        required int initialMediaIndex,
        String? framedEventReference,
      }) {
        FeedVideosRoute(
          eventReference: eventReference,
          initialMediaIndex: initialMediaIndex,
          framedEventReference: framedEventReference,
        ).push<void>(context);
      },
      plainInlineStyles: true,
    );
  }

  static const int _creatorsInsertInterval = 2;

  List<IonEntityListItem> _getFeedListItems(Iterable<IonConnectEntity> entities) {
    final initialListItems = entities
        .map((entity) => IonEntityListItem.event(eventReference: entity.toEventReference()))
        .toList();

    if (initialListItems.length >= 2) {
      initialListItems.insert(
        2,
        const IonEntityListItem.custom(child: InviteFriendsListItem()),
      );
    }

    final totalEventItems = initialListItems.where((item) => item is EventIonEntityListItem).length;
    if (totalEventItems >= _creatorsInsertInterval) {
      var eventsSeen = 0;
      for (var i = 0; i < initialListItems.length; i++) {
        if (initialListItems[i] is EventIonEntityListItem) {
          eventsSeen++;
          if (eventsSeen > 0 && eventsSeen % _creatorsInsertInterval == 0) {
            initialListItems.insert(
              i + 1,
              const IonEntityListItem.custom(child: CreatorsYouMightLike()),
            );
            i++;
          }
        }
      }
    }

    return initialListItems;
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedCategory = ref.watch(feedCurrentFilterProvider.select((state) => state.category));
    final postsTypes = feedCategory.getPostsNames(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyList(
        asset: Assets.svg.walletIconProfileEmptyposts,
        title: context.i18n.feed_posts_empty(postsTypes),
      ),
    );
  }
}
