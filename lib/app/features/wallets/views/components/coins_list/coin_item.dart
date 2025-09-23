// SPDX-License-Identifier: ice License 1.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/unseen_transaction_indicator.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:ion/app/utils/num.dart';
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
    final showContent = useState(false);

    useEffect(
      () {
        if (coinsGroup.iconUrl.isEmpty) {
          showContent.value = true;
          return null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            final precacheFuture = coinsGroup.iconUrl.isSvg
                ? () async {
                    final loader = SvgNetworkLoader(coinsGroup.iconUrl);
                    await svg.cache
                        .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
                  }()
                : precacheImage(CachedNetworkImageProvider(coinsGroup.iconUrl), context);

            await precacheFuture.whenComplete(() {
              if (context.mounted) {
                showContent.value = true;
              }
            });
          } else {
            showContent.value = true;
          }
        });

        return null;
      },
      [coinsGroup.symbolGroup, coinsGroup.iconUrl],
    );

    final contentWidget = _CoinsGroupItemContent(
      key: ValueKey('content-${coinsGroup.symbolGroup}'),
      coinsGroup: coinsGroup,
      onTap: onTap,
      showNewTransactionsIndicator: showNewTransactionsIndicator,
      isBalanceVisible: isBalanceVisible,
    );

    return Stack(
      children: [
        if (!showContent.value)
          const CoinsGroupItemPlaceholder(
            key: ValueKey('placeholder'),
          )
        else
          contentWidget,
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
    super.key,
  });

  final CoinsGroup coinsGroup;
  final VoidCallback onTap;
  final bool showNewTransactionsIndicator;
  final bool isBalanceVisible;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: Text(coinsGroup.name),
      subtitle: Text(coinsGroup.abbreviation),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: CoinIconWidget(
        imageUrl: coinsGroup.iconUrl,
        type: WalletItemIconType.big(),
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
