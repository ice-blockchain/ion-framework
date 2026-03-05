// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/advanced_search_channels/explore_channels.dart';
import 'package:ion/app/features/search/views/components/advanced_search_channels/subscribed_channels.dart';
import 'package:ion/app/features/search/views/components/search_sub_header/search_sub_header.dart';
import 'package:ion/generated/assets.gen.dart';

class AdvancedSearchChannels extends HookConsumerWidget {
  const AdvancedSearchChannels({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    return SingleChildScrollView(
      restorationId: 'search_channels_scroll',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: 16.0.s),
            child: SearchSubHeader(
              icon: Assets.svg.iconCategoriesFollowing,
              title: context.i18n.chat_groups_subscribed,
              count: 4,
            ),
          ),
          const SubscribedChannels(),
          Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0.s),
            child: SearchSubHeader(
              icon: Assets.svg.iconSendfundsUser,
              title: context.i18n.chat_groups_explore,
              count: 4,
            ),
          ),
          const ExploreChannels(),
        ],
      ),
    );
  }
}
