// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class RecentChatsEmptyPage extends HookConsumerWidget {
  const RecentChatsEmptyPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = useState(false);

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ChatQuickSearchRoute().push<void>(context),
          child: const IgnorePointer(
            child: SearchInput(),
          ),
        ),
        Expanded(
          child: PullToRefreshBuilder(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: 210.0.s),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Assets.svg.walletChatEmptystate.icon(
                            size: 48.0.s,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: 8.0.s),
                            child: Text(
                              context.i18n.chat_empty_description,
                              style: context.theme.appTextThemes.caption2.copyWith(
                                color: context.theme.appColors.onTertiaryBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: isNavigating.value
                                ? null
                                : () async {
                                    isNavigating.value = true;
                                    try {
                                      await NewChatModalRoute().push<void>(context);
                                      // Add delay to let navigator settle after dialog closes
                                      await Future<void>.delayed(const Duration(milliseconds: 300));
                                    } finally {
                                      isNavigating.value = false;
                                    }
                                  },
                            child: Padding(
                              padding: EdgeInsets.all(UiConstants.hitSlop),
                              child: Text(
                                context.i18n.chat_new_message_button,
                                style: context.theme.appTextThemes.caption
                                    .copyWith(color: context.theme.appColors.primaryAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onRefresh: () async => ref.invalidate(conversationsProvider),
            builder: (context, slivers) => CustomScrollView(
              slivers: slivers,
            ),
          ),
        ),
      ],
    );
  }
}
