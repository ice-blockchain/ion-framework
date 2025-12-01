// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/tabs_header/tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/providers/creator_tokens_search_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensTabsHeader extends ConsumerWidget {
  const CreatorTokensTabsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: context.theme.appColors.primaryText,
      child: Row(
        children: [
          const Expanded(
            child: TabsHeader(
              tabs: CreatorTokensTabType.values,
            ),
          ),
          // Search Icon
          Padding(
            padding: EdgeInsets.only(right: 16.0.s),
            child: GestureDetector(
              onTap: () {
                ref.read(creatorTokensIsSearchActiveProvider.notifier).isSearching = true;
              },
              child: Assets.svg.iconFieldSearch.icon(
                size: 24.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
