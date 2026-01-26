// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageCoinItemWidget extends ConsumerWidget {
  const ManageCoinItemWidget({
    required this.coinsGroup,
    super.key,
  });

  final CoinsGroup coinsGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(manageCoinsNotifierProvider).maybeMap(
          data: (data) => data.value[coinsGroup.symbolGroup]?.isSelected ?? false,
          orElse: () => false,
        );
    return ListItem(
      title: Text(coinsGroup.name),
      subtitle: Text(coinsGroup.abbreviation),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: CoinIconWidget(
        imageUrl: coinsGroup.iconUrl,
        showPlaceholder: true,
        type: WalletItemIconType.big(),
      ),
      trailing: isSelected
          ? Assets.svg.iconBlockCheckboxOn.icon()
          : Assets.svg.iconBlockCheckboxOff.icon(),
      onTap: () {
        ref.read(manageCoinsNotifierProvider.notifier).switchCoinsGroup(coinsGroup);
      },
    );
  }
}
