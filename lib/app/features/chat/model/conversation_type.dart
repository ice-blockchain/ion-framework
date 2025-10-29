// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/model/main_modal_list_item.dart';
import 'package:ion/generated/assets.gen.dart';

enum ConversationType implements MainModalListItem {
  direct,
  group,
  channel;

  @override
  String getDisplayName(BuildContext context) {
    return switch (this) {
      ConversationType.direct => context.i18n.common_chat,
      ConversationType.group => context.i18n.new_chat_modal_new_group_button,
      ConversationType.channel => context.i18n.new_chat_modal_new_channel_button,
    };
  }

  @override
  String getDescription(BuildContext context) {
    return switch (this) {
      ConversationType.direct => context.i18n.chat_modal_private_description,
      ConversationType.group => context.i18n.chat_modal_group_description,
      ConversationType.channel => context.i18n.chat_modal_channel_description,
    };
  }

  @override
  Color getIconColor(BuildContext context) {
    return switch (this) {
      ConversationType.direct => context.theme.appColors.orangePeel,
      ConversationType.group => context.theme.appColors.raspberry,
      ConversationType.channel => context.theme.appColors.success,
    };
  }

  @override
  String get iconAsset {
    return switch (this) {
      ConversationType.direct => Assets.svg.iconChatCreatenew,
      ConversationType.group => Assets.svg.iconSearchGroups,
      ConversationType.channel => Assets.svg.iconSearchChannel,
    };
  }

  String get subRouteLocation {
    return switch (this) {
      ConversationType.direct => NewChatModalRoute().location,
      ConversationType.group => AddParticipantsToGroupModalRoute().location,
      ConversationType.channel => NewChannelModalRoute().location,
    };
  }

  bool get isDirect => this == ConversationType.direct;
  bool get isGroup => this == ConversationType.group;
  bool get isChannel => this == ConversationType.channel;
}
