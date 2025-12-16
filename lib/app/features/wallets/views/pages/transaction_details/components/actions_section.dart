// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/transaction_details_actions.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({
    required this.disableButtons,
    required this.onViewOnExplorer,
    required this.onShare,
    super.key,
  });

  final bool disableButtons;
  final VoidCallback onViewOnExplorer;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return TransactionDetailsActions(
      disableButtons: disableButtons,
      onViewOnExplorer: onViewOnExplorer,
      onShare: onShare,
    );
  }
}
