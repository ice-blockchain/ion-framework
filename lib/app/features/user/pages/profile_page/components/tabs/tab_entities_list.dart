// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/entities_list/entities_list.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/feed/providers/user_posts_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/empty_state.dart';
import 'package:ion/app/features/user/providers/tab_data_source_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class TabEntitiesList extends HookConsumerWidget {
  const TabEntitiesList({
    required this.type,
    required this.pubkey,
    this.builder,
    this.onRefresh,
    super.key,
  });

  factory TabEntitiesList.replies({
    required String pubkey,
    VoidCallback? onRefresh,
    Key? key,
  }) {
    return TabEntitiesList(
      key: key,
      type: TabEntityType.replies,
      pubkey: pubkey,
      onRefresh: onRefresh,
      builder: (entities) => EntitiesList(
        items: entities
            .map((entity) => IonEntityListItem.event(eventReference: entity.toEventReference()))
            .toList(),
        displayParent: true,
        showNotInterested: false,
        showPinOption: true,
      ),
    );
  }

  final String pubkey;

  final Widget Function(List<IonConnectEntity> entities)? builder;

  final TabEntityType type;

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final userMetadata = ref.watch(userMetadataProvider(pubkey)).valueOrNull;
    final isBlockedOrBlockedBy =
        ref.watch(isBlockedOrBlockedByNotifierProvider(pubkey)).valueOrNull ?? false;
    final tabData = ref.watch(tabEntitiesDataProvider(type: type, pubkey: pubkey));
    final entities = tabData.items ?? [];

    return LoadMoreBuilder(
      onLoadMore: () async {
        if (type == TabEntityType.posts) {
          await ref.read(userPostsProvider(pubkey).notifier).fetchEntities();
        } else {
          final dataSource = ref.read(tabDataSourceProvider(type: type, pubkey: pubkey));
          if (dataSource != null) {
            await ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities();
          }
        }
      },
      hasMore: tabData.hasMore,
      slivers: [
        if (entities.isEmpty && tabData.hasMore)
          const EntitiesListSkeleton()
        else if (entities.isEmpty || isBlockedOrBlockedBy)
          EmptyState(
            type: type,
            isCurrentUserProfile: pubkey == ref.watch(currentPubkeySelectorProvider),
            username: prefixUsername(username: userMetadata?.data.name, context: context),
          )
        else
          builder != null
              ? builder!(entities.toList())
              : EntitiesList(
                  items: entities
                      .map(
                        (entity) =>
                            IonEntityListItem.event(eventReference: entity.toEventReference()),
                      )
                      .toList(),
                  showMuted: true,
                  showNotInterested: false,
                  showPinOption: true,
                  onVideoTap: ({
                    required String eventReference,
                    required int initialMediaIndex,
                    String? framedEventReference,
                  }) =>
                      ProfileVideosRoute(
                    eventReference: eventReference,
                    initialMediaIndex: initialMediaIndex,
                    framedEventReference: framedEventReference,
                    pubkey: pubkey,
                    tabEntityType: type,
                  ).push<void>(context),
                ),
      ],
      builder: (context, slivers) => PullToRefreshBuilder(
        slivers: slivers,
        onRefresh: () async {
          if (type == TabEntityType.posts) {
            ref.invalidate(userPostsProvider(pubkey));
          } else {
            final dataSource = ref.read(tabDataSourceProvider(type: type, pubkey: pubkey));
            if (dataSource != null) {
              ref.invalidate(entitiesPagedDataProvider(dataSource));
            }
          }
          onRefresh?.call();
        },
      ),
    );
  }
}
