// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/providers/token_top_holders_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/holdings_list_item.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class HoldingsList extends ConsumerWidget {
  const HoldingsList({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(pubkey)).valueOrNull;
    final externalAddress = userMetadata?.toEventReference().toString();

    if (externalAddress == null) {
      return const SizedBox.shrink();
    }

    // Get token market info to get total holders count
    final token = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    final totalHoldersCount = token?.marketData.holders ?? 0;

    // Get top 5 holders for display
    final holdersAsync = ref.watch(tokenTopHoldersProvider(externalAddress, limit: 5));
    final allHolders = holdersAsync.valueOrNull ?? [];

    // Filter out bonding curve (it has holder == null) - only show real holders
    final holders = allHolders.where((holder) => holder.position.holder != null).toList();

    // Only show if there are real holders
    if (totalHoldersCount == 0 || holders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: context.theme.appColors.secondaryBackground,
      padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(holdersCount: totalHoldersCount),
          SizedBox(height: 14.0.s),
          ...holders.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final holder = entry.value;
              final isLast = index == holders.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0.0 : 14.0.s),
                child: HoldingsListItem(
                  holder: holder,
                  tokenExternalAddress: externalAddress,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.holdersCount,
  });

  final int holdersCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return SizedBox(
      height: 19.0.s,
      child: Row(
        children: [
          Assets.svg.iconTabsCoins.icon(
            size: 18.0.s,
            color: colors.onTertiaryBackground,
          ),
          SizedBox(width: 6.0.s),
          Text(
            'Holdings ($holdersCount)',
            style: texts.subtitle3.copyWith(
              color: colors.onTertiaryBackground,
            ),
          ),
          const Spacer(),
          Text(
            'view all',
            style: texts.caption.copyWith(
              color: colors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
