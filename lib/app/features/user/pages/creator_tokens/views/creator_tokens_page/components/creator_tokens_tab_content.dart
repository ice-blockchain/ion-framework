// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_tab_header.dart';

class CreatorTokensTabContent extends HookConsumerWidget {
  const CreatorTokensTabContent({
    required this.pubkey,
    required this.tabType,
    super.key,
  });

  final String pubkey;
  final CreatorTokensTabType tabType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CreatorTokensTabHeader(tabType: tabType),
        ),
        CreatorTokensList(
          pubkey: pubkey,
          tabType: tabType,
        ),
      ],
    );
  }
}
