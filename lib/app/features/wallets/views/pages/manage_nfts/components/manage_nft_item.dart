// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/view_models/nft_networks_view_model.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageNftNetworkItem extends ConsumerWidget {
  const ManageNftNetworkItem({required this.network, super.key});

  final NetworkData network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(nftNetworksViewModelProvider);

    return ValueListenableBuilder(
      valueListenable: viewModel.selectedNetworkIds,
      builder: (context, selectedNetworkIds, _) {
        final isSelected = selectedNetworkIds.contains(network.id);

        return ListItem(
          title: Text(network.displayName),
          backgroundColor: context.theme.appColors.tertiaryBackground,
          leading: NetworkIconWidget(
            type: WalletItemIconType.big(),
            imageUrl: network.image,
          ),
          trailing: isSelected
              ? Assets.svg.iconBlockCheckboxOn.icon()
              : Assets.svg.iconBlockCheckboxOff.icon(),
          onTap: () => viewModel.toggleNetwork(network.id),
        );
      },
    );
  }
}
