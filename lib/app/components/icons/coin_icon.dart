// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/icons/wallet_item_icon_widget.dart';

class CoinIconWidget extends StatelessWidget {
  const CoinIconWidget({
    required this.imageUrl,
    required this.type,
    super.key,
  });

  final String imageUrl;
  final WalletItemIconType type;

  @override
  Widget build(BuildContext context) {
    return WalletItemIconWidget(
      imageUrl: imageUrl,
      type: type,
    );
  }
}
