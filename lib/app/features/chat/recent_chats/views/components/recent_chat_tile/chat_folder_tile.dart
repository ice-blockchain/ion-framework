// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';

class ChatFolderTile extends StatelessWidget {
  const ChatFolderTile({
    required this.avatarIcon,
    required this.title,
    required this.previewContent,
    required this.trailing,
    this.timestamp,
    this.onTap,
    super.key,
  });

  final Widget avatarIcon;
  final String title;
  final DateTime? timestamp;
  final Widget previewContent;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 16.0.s,
          top: 8.0.s,
          end: 16.0.s,
          bottom: 8.0.s,
        ),
        child: Row(
          children: [
            Avatar(
              imageWidget: avatarIcon,
              size: 48.0.s,
            ),
            SizedBox(width: 12.0.s),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: context.theme.appTextThemes.subtitle3.copyWith(
                          color: context.theme.appColors.primaryText,
                        ),
                      ),
                      if (timestamp != null) ChatTimestamp(timestamp!),
                    ],
                  ),
                  SizedBox(height: 2.0.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      previewContent,
                      trailing,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
