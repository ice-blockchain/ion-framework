// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

void showMarketDataUnavailableSheet(
  BuildContext context, {
  required VoidCallback onClose,
}) {
  showSimpleBottomSheet<void>(
    context: context,
    onPopInvokedWithResult: (_, __) => onClose(),
    child: MarketDataUnavailableSheet(
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    ),
  );
}

class MarketDataUnavailableSheet extends StatelessWidget {
  const MarketDataUnavailableSheet({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleModalSheet.info(
      iconAsset: Assets.svg.nomarketdata,
      title: context.i18n.token_unable_to_fetch_market_data_title,
      description: context.i18n.token_unable_to_fetch_market_data_description,
      buttonText: context.i18n.button_close,
      isBottomSheet: true,
      topOffset: 30.0.s,
      onPressed: onPressed,
    );
  }
}
