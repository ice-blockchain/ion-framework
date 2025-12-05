// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class HolderTile extends StatelessWidget {
  const HolderTile({
    required this.holder,
    super.key,
  });

  final TopHolder holder;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    final rank = holder.position.rank;
    final amountText = formatDoubleCompact(holder.position.amount);

    return GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _RankBadge(rank: rank),
              SizedBox(width: 12.0.s),
              HolderAvatar(imageUrl: holder.position.holder.avatar),
              SizedBox(width: 8.0.s),
              _NameAndAmount(
                name: holder.position.holder.display,
                handle: holder.position.holder.name,
                verified: holder.position.holder.verified,
                amountText: amountText,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
            decoration: BoxDecoration(
              color: colors.primaryBackground,
              borderRadius: BorderRadius.circular(12.0.s),
            ),
            child: Text(
              '${holder.position.supplyShare.toStringAsFixed(2)}%',
              style: texts.caption2
                  .copyWith(color: colors.primaryText, height: 18 / texts.caption2.fontSize!),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final isMedal = rank <= 3;
    final bg = isMedal ? colors.primaryBackground : colors.primaryBackground;
    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.0.s)),
      alignment: Alignment.center,
      child: isMedal
          ? _MedalIcon(rank: rank)
          : Text(
              '$rank',
              style: context.theme.appTextThemes.body.copyWith(color: colors.primaryAccent),
            ),
    );
  }
}

class _MedalIcon extends StatelessWidget {
  const _MedalIcon({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) {
    return switch (rank) {
      1 => Assets.svg.iconMeme1stplace,
      2 => Assets.svg.iconMeme2ndtplace,
      3 => Assets.svg.iconMeme3rdplace,
      _ => throw UnimplementedError(),
    }
        .icon();
  }
}

class _NameAndAmount extends StatelessWidget {
  const _NameAndAmount({
    required this.name,
    required this.handle,
    required this.amountText,
    required this.verified,
  });
  final String name;
  final String handle;
  final String amountText;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              name,
              style: texts.subtitle3.copyWith(
                color: colors.primaryText,
              ),
            ),
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
          ],
        ),
        Text(
          '$handle • $amountText',
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
