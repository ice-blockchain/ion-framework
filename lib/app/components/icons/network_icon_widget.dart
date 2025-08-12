// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/icons/wallet_item_icon_widget.dart';

class NetworkIconWidget extends StatelessWidget {
  const NetworkIconWidget({
    required this.imageUrl,
    required this.type,
    super.key,
    this.color,
  });

  final String imageUrl;
  final WalletItemIconType type;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return WalletItemIconWidget(
      imageUrl: imageUrl,
      type: type,
      color: color,
    );
  }
}
