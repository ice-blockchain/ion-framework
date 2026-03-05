// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/advanced_search_groups/explore_groups.dart';
import 'package:ion/app/features/search/views/components/advanced_search_groups/joined_groups.dart';
import 'package:ion/app/features/search/views/components/search_sub_header/search_sub_header.dart';
import 'package:ion/generated/assets.gen.dart';

class AdvancedSearchGroups extends HookConsumerWidget {
  const AdvancedSearchGroups({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    return SingleChildScrollView(
      restorationId: 'search_groups_scroll',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: 16.0.s),
            child: SearchSubHeader(
              icon: Assets.svg.iconSearchJoined,
              title: context.i18n.chat_groups_joined,
              count: 4,
            ),
          ),
          const JoinedGroups(),
          Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0.s),
            child: SearchSubHeader(
              icon: Assets.svg.iconSendfundsUser,
              title: context.i18n.chat_groups_explore,
              count: 4,
            ),
          ),
          const ExploreGroups(),
        ],
      ),
    );
  }
}
