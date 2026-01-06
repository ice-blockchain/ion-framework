// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class NotificationIcons extends StatelessWidget {
  const NotificationIcons({
    required this.notification,
    super.key,
  });

  final IonNotification notification;

  static double get separator => 4.0.s;

  static int get visibleIconsCount => 10;

  @override
  Widget build(BuildContext context) {
    final iconSize = ((MediaQuery.sizeOf(context).width - ScreenSideOffset.defaultSmallMargin * 2) -
            separator * (visibleIconsCount - 1)) /
        (visibleIconsCount + 0.5); // last icon should be half visible as a hint to scroll option

    return Row(
      children: [
        notification.getIcon(context, size: iconSize),
        SizedBox(width: separator / 2),
        Expanded(
          child: SizedBox(
            height: iconSize,
            child: ListView.separated(
              padding: EdgeInsetsGeometry.directional(start: separator / 2),
              scrollDirection: Axis.horizontal,
              itemCount: notification.pubkeys.length,
              separatorBuilder: (context, index) => SizedBox(width: separator),
              itemBuilder: (context, index) {
                final pubkey = notification.pubkeys[index];
                return GestureDetector(
                  key: ValueKey(pubkey),
                  onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
                  child: IonConnectAvatar(
                    size: iconSize,
                    fit: BoxFit.cover,
                    masterPubkey: pubkey,
                    borderRadius: BorderRadius.circular(10.0.s),
                    network: true,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
