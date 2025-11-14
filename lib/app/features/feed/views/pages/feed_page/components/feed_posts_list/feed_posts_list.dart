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
import 'package:ion/app/features/feed/views/pages/feed_page/components/invite_friends_list_item.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedPostsList extends HookConsumerWidget {
  const FeedPostsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefetching mute list here so it can be used later with sync provider
    useOnInit(() {
      ref.read(cachedMutedUsersProvider);
    });

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
