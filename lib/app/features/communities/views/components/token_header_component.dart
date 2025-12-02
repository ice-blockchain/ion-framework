// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/user_list_item.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats_data.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenHeaderComponent extends StatelessWidget {
  const TokenHeaderComponent({
    required this.token,
    required this.masterPubkey,
    super.key,
  });

  final CommunityToken? token;
  final String masterPubkey;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    if (token == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: statusBarHeight + 20.0.s),
        if (token != null)
          Center(
            child: _TokenImage(
              imageUrl: token!.imageUrl,
            ),
          ),
        SizedBox(height: 12.0.s),
        if (token != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
            child: _TokenContent(
              masterPubkey: masterPubkey,
              token: token!,
            ),
          ),
        SizedBox(height: 16.0.s),
      ],
    );
  }
}

class _TokenImage extends HookWidget {
  const _TokenImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final imageColors = useImageColors(imageUrl);

    final gradient = useMemoized(
      () {
        return imageColors != null
            ? SweepGradient(
                colors: [
                  imageColors.second,
                  imageColors.first,
                ],
              )
            : storyBorderGradients[Random().nextInt(storyBorderGradients.length)];
      },
      [imageColors],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 142.0.s,
        maxHeight: 102.0.s,
        minWidth: 86.0.s,
        minHeight: 86.0.s,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0.s),
          // GradientBoxBorder not accepting AlignmentDirectional
          border: GradientBoxBorder(
            gradient: LinearGradient(
              // ignore: prefer_alignment_directional
              begin: Alignment.topLeft,
              // ignore: prefer_alignment_directional
              end: Alignment.bottomRight,
              colors: gradient.colors,
              stops: gradient.stops,
            ),
            width: 1.7.s,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0.s),
            child: IonNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenContent extends StatelessWidget {
  const _TokenContent({
    required this.masterPubkey,
    required this.token,
  });

  final String masterPubkey;
  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.5.s),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: UseListItem(
                  pubkey: masterPubkey,
                  minHeight: HeaderAction.buttonSize,
                  textColor: context.theme.appColors.secondaryBackground,
                ),
              ),
              ProfileTokenPrice(amount: token.marketData.priceUSD),
            ],
          ),
          Text(
            token.description,
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
            ),
          ),
          SizedBox(height: 12.0.s),
          GradientHorizontalDivider(
            margin: EdgeInsetsDirectional.symmetric(vertical: 12.0.s),
          ),
          ProfileTokenStats(
            masterPubkey: masterPubkey,
            shouldShowBuyButton: false,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            data: ProfileTokenStatsData(
              marketCap: MarketDataFormatter.formatCompactNumber(token.marketData.marketCap),
              price: MarketDataFormatter.formatPrice(token.marketData.priceUSD),
              volume: MarketDataFormatter.formatCompactNumber(token.marketData.volume),
            ),
          ),
          SizedBox(height: 16.0.s),
        ],
      ),
    );
  }
}
