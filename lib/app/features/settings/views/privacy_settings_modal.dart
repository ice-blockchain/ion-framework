// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/settings/components/selectable_options_group.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/settings/optimistic_ui/who_can_message_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class PrivacySettingsModal extends ConsumerWidget {
  const PrivacySettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(currentUserMetadataProvider).valueOrNull;

    if (metadata == null) {
      return const SizedBox.shrink();
    }

    final messagingPrivacy = ref.watch(whoCanMessageWatchProvider).valueOrNull?.visibility ??
        UserVisibilityPrivacyOption.followedPeople;

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              onBackPress: () => context.pop(true),
              title: Text(context.i18n.settings_privacy),
              actions: const [
                NavigationCloseButton(),
              ],
            ),
            ScreenSideOffset.small(
              child: ScreenBottomOffset(
                margin: 32.0.s,
                child: SeparatedColumn(
                  mainAxisSize: MainAxisSize.min,
                  separator: SelectableOptionsGroup.separator,
                  children: [
                    SelectableOptionsGroup(
                      selected: [messagingPrivacy],
                      options: UserVisibilityPrivacyOption.values,
                      title: context.i18n.privacy_group_who_can_message_you_title,
                      onSelected: (option) =>
                          ref.read(toggleWhoCanMessageNotifierProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
