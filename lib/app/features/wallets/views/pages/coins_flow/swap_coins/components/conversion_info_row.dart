// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class ConversionInfoRow extends HookConsumerWidget {
  const ConversionInfoRow({
    required this.sellCoin,
    required this.buyCoin,
    super.key,
  });

  final CoinsGroup sellCoin;
  final CoinsGroup buyCoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final swapCoinsController = ref.watch(swapCoinsControllerProvider);
    final isLoading = swapCoinsController.isQuoteLoading;
    final isError = swapCoinsController.isQuoteError;
    final swapQuoteInfo = swapCoinsController.swapQuoteInfo;

    if (isLoading) {
      return const _LoadingState();
    }

    if (isError) {
      return const _ErrorState();
    }

    if (swapQuoteInfo == null) {
      return SizedBox(
        height: 32.0.s,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '1 ${sellCoin.name} = ${swapQuoteInfo.priceForSellTokenInBuyToken.formatMax6} ${buyCoin.name}',
            style: textStyles.body2.copyWith(),
          ),
          Row(
            spacing: 4.0.s,
            children: [
              Text(
                swapQuoteInfo.type == SwapQuoteInfoType.bridge ? 'Bridge' : 'Cex + Dex',
                style: textStyles.body2.copyWith(),
              ),
              Assets.svg.iconBlockInformation.icon(
                color: colors.tertiaryText,
                size: 16.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(
            width: 120.0.s,
            height: 16.0.s,
          ),
          Row(
            spacing: 4.0.s,
            children: [
              SkeletonBox(
                width: 76.0.s,
                height: 16.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        children: [
          Assets.svg.iconBlockInformation.icon(
            color: colors.tertiaryText,
            size: 16.0.s,
          ),
          SizedBox(width: 5.0.s),
          Text(
            context.i18n.errorGettingSwapQuote,
            style: textStyles.body2.copyWith(),
          ),
        ],
      ),
    );
  }
}
