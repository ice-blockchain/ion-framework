// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/model/main_modal_list_item.dart';
import 'package:ion/generated/assets.gen.dart';

enum WalletMainModalListItem implements MainModalListItem {
  send,
  receive,
  swap;

  @override
  String getDisplayName(BuildContext context) {
    return switch (this) {
      WalletMainModalListItem.send => context.i18n.wallet_send,
      WalletMainModalListItem.receive => context.i18n.wallet_receive,
      WalletMainModalListItem.swap => context.i18n.wallet_swap,
    };
  }

  @override
  String getDescription(BuildContext context) {
    return switch (this) {
      WalletMainModalListItem.send => context.i18n.profile_send_option_desc,
      WalletMainModalListItem.receive => context.i18n.profile_request_option_desc,
      WalletMainModalListItem.swap => context.i18n.wallet_swap_option_desc,
    };
  }

  @override
  Color getIconColor(BuildContext context) {
    return switch (this) {
      WalletMainModalListItem.send => context.theme.appColors.orangePeel,
      WalletMainModalListItem.receive => context.theme.appColors.success,
      WalletMainModalListItem.swap => context.theme.appColors.purple,
    };
  }

  @override
  String get iconAsset {
    return switch (this) {
      WalletMainModalListItem.send => Assets.svg.iconButtonSend,
      WalletMainModalListItem.receive => Assets.svg.iconButtonReceive,
      WalletMainModalListItem.swap => Assets.svg.iconamoonSwap,
    };
  }
}
