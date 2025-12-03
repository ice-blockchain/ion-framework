// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/utils/username.dart';

class CreatorHeader extends ConsumerWidget {
  const CreatorHeader({
    required this.externalAddress,
    required this.opacity,
    required this.showBackButton,
    this.textColor,
    super.key,
  });

  final String externalAddress;
  final double opacity;
  final bool showBackButton;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (!showBackButton) SizedBox(width: 16.0.s),
        Expanded(
          child: _UserListItem(
            externalAddress: externalAddress,
            minHeight: HeaderAction.buttonSize,
            textColor: textColor,
          ),
        ),
      ],
    );
  }
}

class _UserListItem extends ConsumerWidget {
  const _UserListItem({
    required this.externalAddress,
    required this.minHeight,
    this.textColor,
  });

  final String externalAddress;
  final double minHeight;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull?.creator;

    final textStyle = textColor != null ? TextStyle(color: textColor) : null;

    if (creator == null) {
      return const SizedBox.shrink();
    }

    final displayName = creator.display;
    final username = creator.name;

    return ListItem.tokenCreator(
      title: Text(
        displayName,
        strutStyle: const StrutStyle(forceStrutHeight: true),
        style: textStyle,
      ),
      avatarUrl: creator.avatar,
      subtitle: !creator.verified
          ? Text(
              prefixUsername(username: username, context: context),
              style: textStyle,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prefixUsername(username: username, context: context),
                  style: textStyle,
                ),
                SizedBox(width: 4.0.s),
                Expanded(child: Text(context.i18n.nickname_not_owned_suffix)),
              ],
            ),
      constraints: BoxConstraints(maxHeight: minHeight, minHeight: minHeight),
    );
  }
}
