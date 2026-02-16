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
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_ad/ion_ad_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedPostsList extends HookConsumerWidget {
  const FeedPostsList({super.key});
  static const int startAdOffset = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(feedPostsProvider.select((state) => state.items));
    final ionAdClient = ref.watch(ionAdClientProvider).valueOrNull;

    if (entities == null) {
      return const EntitiesListSkeleton();
    } else if (entities.isEmpty) {
      return const _EmptyState();
    }

    return EntitiesList(
      items: _getFeedListItems(entities, ionAdClient),
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

  List<IonEntityListItem> _getFeedListItems(
    Iterable<IonConnectEntity> entities,
    AppodealIonAdsPlatform? ionAdClient,
  ) {
    final initialListItems = entities
        .map((entity) => IonEntityListItem.event(eventReference: entity.toEventReference()))
        .toList();

    if (initialListItems.length >= 2) {
      initialListItems.insert(
        2,
        const IonEntityListItem.custom(child: InviteFriendsListItem()),
      );
    }
    if (initialListItems.length >= startAdOffset &&
        ionAdClient != null &&
        ionAdClient.isNativeLoaded) {
      final adIndices =
          ionAdClient.computeInsertionIndices(initialListItems.length, startOffset: startAdOffset);
      for (final index in adIndices) {
        try {
          initialListItems.insert(
            index,
            IonEntityListItem.custom(child: _CustomNativeAd(key: ValueKey(index))),
          );
        } on Object catch (_) {
          // Ignore all errors
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

class _CustomNativeAd extends StatelessWidget {
  const _CustomNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        height: 246.0.s,
        child: AppodealNativeAd(
          options: NativeAdOptions.contentStreamOptions(),
        ),
      ),
    );
  }
}
