// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/model/main_modal_list_item.dart';
import 'package:ion/generated/assets.gen.dart';

enum ConversationTypeItem implements MainModalListItem {
  directEncrypted,
  groupEncrypted,
  channel;

  @override
  String getDisplayName(BuildContext context) {
    return switch (this) {
      ConversationTypeItem.directEncrypted => context.i18n.common_chat,
      ConversationTypeItem.groupEncrypted => context.i18n.new_chat_modal_new_group_button,
      ConversationTypeItem.channel => context.i18n.new_chat_modal_new_channel_button,
    };
  }

  @override
  String getDescription(BuildContext context) {
    return switch (this) {
      ConversationTypeItem.directEncrypted => context.i18n.chat_modal_private_description,
      ConversationTypeItem.groupEncrypted => context.i18n.chat_modal_group_description,
      ConversationTypeItem.channel => context.i18n.chat_modal_channel_description,
    };
  }

  @override
  Color getIconColor(BuildContext context) {
    return switch (this) {
      ConversationTypeItem.directEncrypted => context.theme.appColors.orangePeel,
      ConversationTypeItem.groupEncrypted => context.theme.appColors.raspberry,
      ConversationTypeItem.channel => context.theme.appColors.success,
    };
  }

  @override
  String get iconAsset {
    return switch (this) {
      ConversationTypeItem.directEncrypted => Assets.svg.iconChatCreatenew,
      ConversationTypeItem.groupEncrypted => Assets.svg.iconSearchGroups,
      ConversationTypeItem.channel => Assets.svg.iconSearchChannel,
    };
  }

  String get subRouteLocation {
    return switch (this) {
      ConversationTypeItem.directEncrypted => NewChatModalRoute().location,
      ConversationTypeItem.groupEncrypted => AddParticipantsToGroupModalRoute().location,
      ConversationTypeItem.channel => NewChannelModalRoute().location,
    };
  }

  bool get isDirect => this == ConversationTypeItem.directEncrypted;
  bool get isGroup => this == ConversationTypeItem.groupEncrypted;
  bool get isChannel => this == ConversationTypeItem.channel;
}
