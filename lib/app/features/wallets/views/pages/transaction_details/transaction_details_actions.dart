// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TransactionDetailsActions extends StatelessWidget {
  const TransactionDetailsActions({
    required this.onViewOnExplorer,
    required this.onShare,
    this.disableButtons = false,
    super.key,
  });

  final VoidCallback onViewOnExplorer;
  final VoidCallback onShare;
  final bool disableButtons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Button(
            type: disableButtons ? ButtonType.disabled : ButtonType.outlined,
            disabled: disableButtons,
            label: Text(
              context.i18n.transaction_details_view_on_explorer,
            ),
            mainAxisSize: MainAxisSize.max,
            leadingIcon: Assets.svg.iconButtonInternet.icon(
              color: disableButtons ? context.theme.appColors.onPrimaryAccent : null,
            ),
            onPressed: onViewOnExplorer,
            backgroundColor: disableButtons ? null : context.theme.appColors.tertiaryBackground,
            borderColor: disableButtons ? null : context.theme.appColors.onTertiaryFill,
          ),
        ),
        SizedBox(
          width: 12.0.s,
        ),
        Button.icon(
          disabled: disableButtons,
          icon: Assets.svg.iconButtonShare.icon(),
          type: ButtonType.outlined,
          onPressed: onShare,
          backgroundColor: context.theme.appColors.tertiaryBackground,
          borderColor: context.theme.appColors.onTertiaryFill,
        ),
      ],
    );
  }
}
