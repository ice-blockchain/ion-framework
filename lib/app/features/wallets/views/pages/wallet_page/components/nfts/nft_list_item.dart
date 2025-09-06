// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/nfts/nfts_network.dart';

class NftListItem extends StatelessWidget {
  const NftListItem({
    required this.nftData,
    required this.onTap,
    super.key,
  });

  final NftData nftData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: Text(nftData.name),
      onTap: onTap,
      subtitle: Text('#${nftData.tokenId}'),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: Avatar(
        size: 36.0.s,
        imageUrl: nftData.imageUrl,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(''),
          NftNetwork(network: nftData.network),
        ],
      ),
    );
  }
}
