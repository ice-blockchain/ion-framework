// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/token_type_gradients.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/unseen_transaction_indicator.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/precache_pictures.dart';
import 'package:ion/generated/assets.gen.dart';

class CoinsGroupItem extends HookConsumerWidget {
  const CoinsGroupItem({
    required this.coinsGroup,
    required this.onTap,
    this.showNewTransactionsIndicator = false,
    super.key,
  });

  final CoinsGroup coinsGroup;
  final VoidCallback onTap;
  final bool showNewTransactionsIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);
    final isContentReady = useState(false);

    useEffect(
      () {
        if (coinsGroup.iconUrl.isEmpty) {
          isContentReady.value = true;
          return;
        }
        precachePictures(context, [coinsGroup.iconUrl!]).whenComplete(
          () => isContentReady.value = true,
        );
        return null;
      },
      [coinsGroup.iconUrl],
    );

    final contentWidget = _CoinsGroupItemContent(
      coinsGroup: coinsGroup,
      onTap: onTap,
      showNewTransactionsIndicator: showNewTransactionsIndicator,
      isBalanceVisible: isBalanceVisible,
    );

    return Stack(
      children: [
        if (!isContentReady.value) const CoinsGroupItemPlaceholder() else contentWidget,
      ],
    );
  }
}

class _CoinsGroupItemContent extends StatelessWidget {
  const _CoinsGroupItemContent({
    required this.onTap,
    required this.coinsGroup,
    required this.isBalanceVisible,
    required this.showNewTransactionsIndicator,
  });

  final CoinsGroup coinsGroup;
  final VoidCallback onTap;
  final bool showNewTransactionsIndicator;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    // Get token type from the first coin that has a tokenized community token type
    final tokenType = coinsGroup.coins
        .map((e) => e.coin.tokenizedCommunityTokenType)
        .whereType<TokenizedCommunityTokenType>()
        .firstOrNull;

    return ListItem(
      key: Key(coinsGroup.symbolGroup),
      title: Text(coinsGroup.name),
      subtitle: Text(coinsGroup.abbreviation),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        clipBehavior: Clip.none,
        children: [
          CoinIconWidget(
            imageUrl: coinsGroup.iconUrl,
            showPlaceholder: true,
            type: WalletItemIconType.big(),
          ),
          switch (tokenType) {
            TokenizedCommunityTokenType.tokenTypeXcom => PositionedDirectional(
                bottom: -3.s,
                end: -3.s,
                child: Container(
                  padding: EdgeInsets.all(2.s),
                  decoration: BoxDecoration(
                    color: context.theme.appColors.asphalt,
                    borderRadius: BorderRadius.circular(4.0.s),
                  ),
                  child: Assets.svg.iconLoginXlogo.icon(
                    size: 8.0.s,
                    color: context.theme.appColors.secondaryBackground,
                  ),
                ),
              ),
            TokenizedCommunityTokenType.tokenTypePost ||
            TokenizedCommunityTokenType.tokenTypeVideo ||
            TokenizedCommunityTokenType.tokenTypeArticle =>
              PositionedDirectional(
                end: -3.0.s,
                bottom: -3.0.s,
                child: _CoinGradientIndicator(tokenType: tokenType!),
              ),
            TokenizedCommunityTokenType.tokenTypeProfile ||
            TokenizedCommunityTokenType.tokenTypeUndefined ||
            null =>
              const SizedBox.shrink(),
          },
        ],
      ),
      onTap: onTap,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (showNewTransactionsIndicator)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.0.s),
                  child: UnseenTransactionsIndicator(
                    coinIds: coinsGroup.coins.map((e) => e.coin.id).toList(),
                  ),
                ),
              Text(
                isBalanceVisible
                    ? formatCrypto(coinsGroup.totalAmount)
                    : StringConstants.obfuscated,
                style: context.theme.appTextThemes.body
                    .copyWith(color: context.theme.appColors.primaryText),
              ),
            ],
          ),
          Text(
            isBalanceVisible
                ? formatToCurrency(coinsGroup.totalBalanceUSD)
                : StringConstants.obfuscated,
            style: context.theme.appTextThemes.caption3
                .copyWith(color: context.theme.appColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _CoinGradientIndicator extends StatelessWidget {
  const _CoinGradientIndicator({
    required this.tokenType,
  });

  final TokenizedCommunityTokenType tokenType;

  @override
  Widget build(BuildContext context) {
    final gradient = TokenTypeGradients.getGradientForTokenizedType(tokenType);
    if (gradient == null) return const SizedBox.shrink();

    return Container(
      width: 12.0.s,
      height: 12.0.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}

class CoinsGroupItemPlaceholder extends StatelessWidget {
  const CoinsGroupItemPlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: ContainerSkeleton(
        height: 16.0.s,
        width: 101.0.s,
        skeletonBaseColor: context.theme.appColors.onTertiaryFill,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6.0.s),
          ContainerSkeleton(
            height: 12.0.s,
            width: 55.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
        ],
      ),
      leading: Assets.svg.walletemptyicon2.icon(size: 36.0.s),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ContainerSkeleton(
            height: 16.0.s,
            width: 40.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
          SizedBox(height: 6.0.s),
          ContainerSkeleton(
            height: 12.0.s,
            width: 30.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
        ],
      ),
    );
  }
}
