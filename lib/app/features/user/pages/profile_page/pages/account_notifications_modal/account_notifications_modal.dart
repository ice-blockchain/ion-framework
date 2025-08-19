// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/providers/user_specific_notifications_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class AccountNotificationsModal extends HookConsumerWidget {
  const AccountNotificationsModal({
    required this.userPubkey,
    super.key,
  });

  final String userPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final selectedOptions = useState<Set<UserNotificationsType>?>(null);
    final isLoading = useState(false);

    useEffect(
      () {
        Future.microtask(() async {
          try {
            final initialNotifications =
                await ref.refresh(userSpecificNotificationsProvider(userPubkey).future);
            selectedOptions.value = initialNotifications.toSet();
          } catch (error) {
            selectedOptions.value = <UserNotificationsType>{};
          }
        });
        return null;
      },
      [userPubkey],
    );

    final handleOptionSelection = useCallback(
      (UserNotificationsType option) async {
        if (selectedOptions.value == null || isLoading.value) return;

        isLoading.value = true;

        try {
          final currentSet = Set<UserNotificationsType>.from(selectedOptions.value!);

          if (option == UserNotificationsType.none) {
            if (currentSet.contains(UserNotificationsType.none)) {
              currentSet.remove(UserNotificationsType.none);
            } else {
              currentSet
                ..clear()
                ..add(UserNotificationsType.none);
            }
          } else {
            if (currentSet.contains(UserNotificationsType.none)) {
              currentSet.remove(UserNotificationsType.none);
            }

            if (currentSet.contains(option)) {
              currentSet.remove(option);
            } else {
              currentSet.add(option);
            }
          }

          selectedOptions.value = currentSet;

          await ref
              .read(userSpecificNotificationsProvider(userPubkey).notifier)
              .updateNotificationsForUser(userPubkey, selectedOptions.value!.toList());
        } catch (error) {
          try {
            final currentNotifications = await ref.read(
              userSpecificNotificationsProvider(userPubkey).future,
            );
            selectedOptions.value = currentNotifications.toSet();
          } catch (revertError) {
            selectedOptions.value = <UserNotificationsType>{UserNotificationsType.none};
          }
        } finally {
          isLoading.value = false;
        }
      },
      [selectedOptions, isLoading, ref, userPubkey],
    );

    if (selectedOptions.value == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.profile_notifications_popup_title),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

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
            final isSelected = selectedOptions.value!.contains(option);

            return Column(
              children: [
                if (index == 0) const HorizontalSeparator(),
                ListItem(
                  backgroundColor: colors.secondaryBackground,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
                  constraints: const BoxConstraints(),
                  onTap: isLoading.value ? null : () => handleOptionSelection(option),
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
