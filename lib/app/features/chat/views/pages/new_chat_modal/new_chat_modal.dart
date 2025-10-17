// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';

class NewChatModal extends HookConsumerWidget {
  const NewChatModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onUserSelected = useCallback(
      (String masterPubkey) async {
        if (context.mounted) {
          context.replace(
            ConversationRoute(receiverMasterPubkey: masterPubkey).location,
          );
        }
      },
    );

    final hideCommunity =
        ref.watch(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideCommunity);

    final env = ref.read(envProvider.notifier);
    final expirationDuration = Duration(
      minutes: env.get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
    );

    return SheetContent(
      topPadding: 0,
      body: UserPickerSheet(
        controlPrivacy: true,
        expirationDuration: expirationDuration,
        cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
        navigationBar: NavigationAppBar.modal(
          showBackButton: false,
          title: Text(context.i18n.new_chat_modal_title),
          actions: const [NavigationCloseButton()],
        ),
        onUserSelected: onUserSelected,
        header: hideCommunity ? null : const _HeaderSection(),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return PinnedHeaderSliver(
      child: Row(
        children: [
          _HeaderButton(
            icon: Assets.svg.iconSearchGroups,
            title: context.i18n.new_chat_modal_new_group_button,
            onTap: () {
              AddParticipantsToGroupModalRoute().push<void>(context);
            },
          ),
          SizedBox(width: 20.0.s),
          _HeaderButton(
            icon: Assets.svg.iconSearchChannel,
            title: context.i18n.new_chat_modal_new_channel_button,
            onTap: () {
              NewChannelModalRoute().replace(context);
            },
          ),
          SizedBox(width: 12.0.s),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Button.compact(
        leadingIcon: icon.icon(
          size: 16.0.s,
          color: context.theme.appColors.primaryAccent,
        ),
        type: ButtonType.outlined,
        onPressed: onTap,
        label: Text(
          title,
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.primaryText,
          ),
        ),
      ),
    );
  }
}
