// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/models/token_header_data.dart';
import 'package:ion/app/features/communities/utils/position_formatters.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenHeaderComponent extends StatelessWidget {
  const TokenHeaderComponent({
    required this.data,
    this.onBackPressed,
    this.onBookmarkPressed,
    this.onMorePressed,
    this.abbreviateCount = defaultAbbreviate,
    this.formatUsd = defaultUsd,
    super.key,
  });

  final TokenHeaderData data;
  final VoidCallback? onBackPressed;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onMorePressed;
  final SupplyAbbreviator abbreviateCount;
  final UsdFormatter formatUsd;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 316.0.s,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: statusBarHeight + 12.0.s),
                const _TokenIcon(),
                SizedBox(height: 6.0.s),
                _TokenInfo(
                  displayName: data.displayName,
                  handle: data.handle,
                  priceUsd: data.priceUsd,
                  verified: data.verified,
                ),
                SizedBox(height: 16.0.s),
                _StatsRow(
                  marketCapUsd: data.marketCapUsd,
                  holdersCount: data.holdersCount,
                  volumeUsd: data.volumeUsd,
                  abbreviateCount: abbreviateCount,
                  formatUsd: formatUsd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenIcon extends StatelessWidget {
  const _TokenIcon();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const ProfileAvatar(
          pubkey: 'pubkey',
          profileMode: ProfileMode.dark,
        ),
        PositionedDirectional(
          bottom: -6.0.s,
          end: -6.0.s,
          child: Container(
            width: 24.0.s,
            height: 24.0.s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryAccent,
            ),
            alignment: Alignment.center,
            child:
                Assets.svg.iconSearchFollow.icon(size: 18.0.s, color: colors.secondaryBackground),
          ),
        ),
      ],
    );
  }
}

class _TokenInfo extends StatelessWidget {
  const _TokenInfo({
    required this.displayName,
    required this.handle,
    required this.priceUsd,
    required this.verified,
  });

  final String displayName;
  final String handle;
  final double priceUsd;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: texts.subtitle2.copyWith(color: Colors.white),
            ),
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 18.0.s),
            ],
          ],
        ),
        SizedBox(height: 4.0.s),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              handle,
              style: texts.caption3.copyWith(color: Colors.white),
            ),
            SizedBox(width: 6.0.s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.0.s),
              ),
              child: Text(
                _formatPrice(priceUsd),
                style: texts.caption.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1) {
      return NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(price);
    }
    // Handle small prices with subscript notation similar to PriceLabelFormatter
    final abs = price.abs();
    if (abs == 0) return r'$0.00';

    final expStr = abs.toStringAsExponential(12);
    final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
    if (match == null) {
      return NumberFormat.currency(symbol: r'$', decimalDigits: 4).format(price);
    }

    final mantissaStr = match.group(1)!;
    final exponent = int.parse(match.group(2)!);

    if (exponent >= -1) {
      return NumberFormat.currency(symbol: r'$', decimalDigits: 4).format(price);
    }

    final digits = mantissaStr.replaceAll('.', '');
    final trailing = digits.isEmpty ? '0' : (digits.length >= 3 ? digits.substring(0, 3) : digits);

    return '\$0.0₄$trailing';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.marketCapUsd,
    required this.holdersCount,
    required this.volumeUsd,
    required this.abbreviateCount,
    required this.formatUsd,
  });

  final double marketCapUsd;
  final int holdersCount;
  final double volumeUsd;
  final SupplyAbbreviator abbreviateCount;
  final UsdFormatter formatUsd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275.0.s,
      height: 44.0.s,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.5.s),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            iconPath: Assets.svg.iconMemeMarketcap,
            value: abbreviateCount(marketCapUsd),
          ),
          _StatItem(
            iconPath: Assets.svg.iconMemeMarkers,
            value: formatUsd(volumeUsd).replaceAll(r'$', r'$'),
          ),
          _StatItem(
            iconPath: Assets.svg.iconSearchGroups,
            value: abbreviateCount(holdersCount),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconPath,
    required this.value,
  });

  final String iconPath;
  final String value;

  @override
  Widget build(BuildContext context) {
    final texts = context.theme.appTextThemes;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 14.0.s,
          height: 14.0.s,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        SizedBox(width: 3.0.s),
        Text(
          value,
          style: texts.caption2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
