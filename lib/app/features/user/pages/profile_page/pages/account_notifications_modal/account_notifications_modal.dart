// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/optimistic_ui/account_notifications_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class AccountNotificationsModal extends ConsumerWidget {
  const AccountNotificationsModal({
    required this.userPubkey,
    super.key,
  });

  final String userPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final accountNotifications =
        ref.watch(accountNotificationsWatchProvider(userPubkey)).valueOrNull;
    final selectedOptions = accountNotifications?.selected ?? {UserNotificationsType.none};

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          title: Text(context.i18n.profile_notifications_popup_title),
        ),
        ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            final option = UserNotificationsType.values[index];
            final isSelected = selectedOptions.contains(option);

            return Column(
              children: [
                if (index == 0) const HorizontalSeparator(),
                ListItem(
                  backgroundColor: colors.secondaryBackground,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
                  constraints: const BoxConstraints(),
                  onTap: () => ref
                      .read(toggleAccountNotificationsNotifierProvider.notifier)
                      .toggle(userPubkey: userPubkey, option: option),
                  title: Text(option.getTitle(context), style: textStyles.body),
                  leading: ButtonIconFrame(
                    containerSize: 36.0.s,
                    borderRadius: BorderRadius.circular(10.0.s),
                    color: colors.onSecondaryBackground,
                    icon: option.iconAsset.icon(
                      size: 24.0.s,
                      color: colors.primaryAccent,
                    ),
                    border: Border.fromBorderSide(
                      BorderSide(color: colors.onTertiaryFill, width: 1.0.s),
                    ),
                  ),
                  trailing: isSelected
                      ? Assets.svg.iconBlockCheckboxOnblue.icon(
                          color: colors.success,
                        )
                      : Assets.svg.iconBlockCheckboxOff.icon(
                          color: colors.tertiaryText,
                        ),
                ),
                const HorizontalSeparator(),
              ],
            );
          },
          itemCount: UserNotificationsType.values.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
    );
  }
}
