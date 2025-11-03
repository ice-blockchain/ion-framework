// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/conversation_type.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/main_modal_item.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class ChatMainModalPage extends ConsumerWidget {
  const ChatMainModalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideGroup = false;
    //ref.watch(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideCommunity);
    // Always hide channels (not implemented yet)
    // Always show direct messages
    // Show groups only if hideCommunity is false
    final menuItems = ConversationType.values.where((type) {
      if (type.isDirect) return true;
      if (!hideGroup && type.isGroup) return true;
      return false;
    }).toList();

    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      topPadding: 0.0.s,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.chat_modal_title),
            showBackButton: false,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const HorizontalSeparator(),
            itemCount: menuItems.length,
            itemBuilder: (BuildContext context, int index) {
              final conversationType = menuItems[index];

              return MainModalItem(
                item: conversationType,
                index: index,
                onTap: () => context.pushReplacement(conversationType.subRouteLocation),
              );
            },
          ),
        ],
      ),
    );
  }
}
