// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensListItem extends ConsumerWidget {
  const CreatorTokensListItem({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey).select(userPreviewDisplayNameSelector),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: BadgesUserListItem(
        title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
        trailing: const _TokenPriceLabel(
          //TODO: replace mock data
          price: 0.14,
        ),
        subtitle: const _CreatorStatsWidget(
          //TODO: replace mock data
          amount: 54757440,
          transactions: 134231,
          groups: 43400,
        ),
        masterPubkey: pubkey,
      ),
    );
  }
}

class _TokenPriceLabel extends StatelessWidget {
  const _TokenPriceLabel({
    required this.price,
  });

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
        vertical: 2.0.s,
      ),
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0.s),
        ),
      ),
      height: 20.0.s,
      child: Center(
        child: Text(
          formatToCurrency(price),
          style: context.theme.appTextThemes.caption4.copyWith(
            color: context.theme.appColors.primaryBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CreatorStatsWidget extends StatelessWidget {
  const _CreatorStatsWidget({
    required this.amount,
    required this.transactions,
    required this.groups,
  });

  final int amount;
  final int transactions;
  final int groups;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.appColors.quaternaryText;
    final iconColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    final textStyle = context.theme.appTextThemes.caption.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );

    final stats = [
      (icon: Assets.svg.iconMemeMarketcap, value: formatCount(amount)),
      (icon: Assets.svg.iconMemeMarkers, value: formatCount(transactions)),
      (
        icon: Assets.svg.iconSearchGroups,
        value: formatDouble(
          groups.toDouble(),
          minimumFractionDigits: 0,
        )
      ),
    ];

    return Row(
      children: [
        for (final item in stats) ...[
          SvgPicture.asset(
            item.icon,
            colorFilter: iconColorFilter,
            height: 14.0.s,
            width: 14.0.s,
          ),
          SizedBox(width: 2.0.s),
          Text(item.value, style: textStyle),
          if (item != stats.last) ...[
            SizedBox(width: 6.0.s),
            Text('•', style: textStyle),
            SizedBox(width: 6.0.s),
          ],
        ],
      ],
    );
  }
}
