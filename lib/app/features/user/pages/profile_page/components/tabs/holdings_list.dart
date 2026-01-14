// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/user_holdings_list_item.dart';
import 'package:ion/app/features/user/providers/user_holdings_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
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
    final holderAddress = userMetadata?.toEventReference().toString();

    if (holderAddress == null) {
      return const SizedBox.shrink();
    }

    final holdingsAsync = ref.watch(userHoldingsProvider(holderAddress));

    return holdingsAsync.when(
      data: (holdingsData) {
        final holdings = holdingsData.items;
        final totalHoldingsCount = holdingsData.totalHoldings;

        if (totalHoldingsCount == 0 || holdings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: context.theme.appColors.secondaryBackground,
          padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(holdingsCount: totalHoldingsCount, holderAddress: holderAddress),
              SizedBox(height: 14.0.s),
              ...holdings.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final token = entry.value;
                  final isLast = index == holdings.length - 1;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(bottom: isLast ? 0.0 : 14.0.s),
                    child: UserHoldingsListItem(token: token),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.holdingsCount,
    required this.holderAddress,
  });

  final int holdingsCount;
  final String holderAddress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return Row(
      children: [
        Assets.svg.iconTabsCoins.icon(
          size: 18.0.s,
          color: colors.onTertiaryBackground,
        ),
        SizedBox(width: 6.0.s),
        Text(
          context.i18n.profile_holdings_with_count(holdingsCount),
          style: texts.subtitle3.copyWith(
            color: colors.onTertiaryBackground,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            UserHoldingsRoute(holderAddress: holderAddress).push<void>(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
            child: Text(
              context.i18n.core_view_all,
              style: texts.caption.copyWith(
                color: colors.primaryAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
