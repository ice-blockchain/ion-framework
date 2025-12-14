// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class BondingCurveHolderTile extends StatelessWidget {
  const BondingCurveHolderTile({
    required this.bondingCurveProgress,
    required this.token,
    super.key,
  });

  final CommunityToken token;
  final BondingCurveProgress bondingCurveProgress;

  @override
  Widget build(BuildContext context) {
    final supplyShare = bondingCurveProgress.currentAmount / (token.marketData.volume / 100);
    return HolderTile(
      rank: 0,
      amount: bondingCurveProgress.currentAmount as double,
      displayName: context.i18n.tokenized_community_bonding_curve,
      supplyShare: supplyShare,
      avatarUrl: Assets.svg.iconBondingCurveAvatar,
    );
  }
}

class TopHolderTile extends StatelessWidget {
  const TopHolderTile({
    required this.holder,
    super.key,
  });

  final TopHolder holder;

  @override
  Widget build(BuildContext context) {
    final holderAddress = holder.position.holder.addresses?.ionConnect;
    final creatorAddress = holder.creator.addresses?.ionConnect;
    final isCreator = creatorAddress != null && holderAddress == creatorAddress;

    return HolderTile(
      rank: holder.position.rank,
      amount: holder.position.amount,
      displayName: holder.position.holder.display,
      username: holder.position.holder.name,
      supplyShare: holder.position.supplyShare,
      verified: holder.position.holder.verified,
      isCreator: isCreator,
      avatarUrl: holder.position.holder.avatar,
    );
  }
}

class HolderTile extends StatelessWidget {
  const HolderTile({
    required this.rank,
    required this.amount,
    required this.displayName,
    required this.supplyShare,
    this.verified = false,
    this.isCreator = false,
    this.username,
    this.avatarUrl,
    super.key,
  });

  final int rank;
  final double amount;
  final String displayName;
  final double supplyShare;
  final bool isCreator;
  final bool verified;
  final String? username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    final amountText = formatDoubleCompact(amount);

    return GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _RankBadge(rank: rank),
                SizedBox(width: 12.0.s),
                HolderAvatar(imageUrl: avatarUrl),
                SizedBox(width: 8.0.s),
                _NameAndAmount(
                  name: displayName,
                  handle: username,
                  isCreator: isCreator,
                  verified: verified,
                  amountText: amountText,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
            decoration: BoxDecoration(
              color: colors.primaryBackground,
              borderRadius: BorderRadius.circular(12.0.s),
            ),
            child: Text(
              '${supplyShare.toStringAsFixed(2)}%',
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
    return Container(
      width: 30.0.s,
      height: 30.0.s,
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
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
      0 => Assets.svg.iconMemeBondingcurve,
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
    required this.isCreator,
  });

  final String name;
  final String? handle;
  final String amountText;
  final bool verified;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: texts.subtitle3.copyWith(
                  color: colors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
            if (isCreator) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeCreator.icon(size: 16.0.s),
            ],
            SizedBox(width: 8.0.s),
          ],
        ),
        Text(
          handle != null ? '$handle • $amountText' : amountText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: texts.caption.copyWith(color: colors.quaternaryText),
        ),
      ],
    );
  }
}
