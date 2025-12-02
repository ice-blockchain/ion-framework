// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
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
          child: _UseListItem(
            externalAddress: externalAddress,
            minHeight: HeaderAction.buttonSize,
            textColor: textColor,
          ),
        ),
      ],
    );
  }
}

class _UseListItem extends ConsumerWidget {
  const _UseListItem({
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

    return ListItem.user(
      title: Text(
        displayName,
        strutStyle: const StrutStyle(forceStrutHeight: true),
        style: textStyle,
      ),
      avatarWidget: creator.avatar != null
          ? IonNetworkImage(
              imageUrl: creator.avatar!,
              height: ListItem.defaultAvatarSize,
              width: ListItem.defaultAvatarSize,
            )
          : null,
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
