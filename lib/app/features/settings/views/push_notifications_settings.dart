// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_request_sheet.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/settings/components/selectable_options_group.dart';
import 'package:ion/app/features/settings/model/push_notifications_options.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class PushNotificationsSettings extends ConsumerWidget {
  const PushNotificationsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SelectedPushCategoriesState(categories: selectedCategories, :suspended) =
        ref.watch(selectedPushCategoriesProvider);
    final hasPermissionOnDeviceLevel = ref.watch(hasPermissionProvider(Permission.notifications));
    final hasNotificationsPermission = hasPermissionOnDeviceLevel && !suspended;

    return SheetContent(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _NavBarDelegate(
              child: NavigationAppBar.modal(
                onBackPress: context.pop,
                title: Text(context.i18n.settings_push_notifications),
                actions: const [NavigationCloseButton()],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(bottom: 40.0.s),
            sliver: SliverToBoxAdapter(
              child: ScreenSideOffset.small(
                child: SeparatedColumn(
                  separator: SelectableOptionsGroup.separator,
                  children: [
                    _DevicePermissionButton(
                      hasPermission: hasNotificationsPermission,
                      hasPermissionOnDeviceLevel: hasPermissionOnDeviceLevel,
                      onChangeAppLevelPermission:
                          ref.read(selectedPushCategoriesProvider.notifier).toggleSuspended,
                    ),
                    SelectableOptionsGroup(
                      title: context.i18n.push_notification_social_group_title,
                      selected: _filterSelectedOptions(
                        SocialNotificationOption.values,
                        selected: selectedCategories,
                      ),
                      options: SocialNotificationOption.values,
                      onSelected: (option) => ref
                          .read(selectedPushCategoriesProvider.notifier)
                          .toggleCategory(option.category),
                      enabled: hasNotificationsPermission,
                    ),
                    SelectableOptionsGroup(
                      title: context.i18n.push_notification_chat_group_title,
                      selected: _filterSelectedOptions(
                        ChatNotificationOption.values,
                        selected: selectedCategories,
                      ),
                      options: ChatNotificationOption.values,
                      onSelected: (option) => ref
                          .read(selectedPushCategoriesProvider.notifier)
                          .toggleCategory(option.category),
                      enabled: hasNotificationsPermission,
                    ),
                    SelectableOptionsGroup(
                      title: context.i18n.push_notification_system_group_title,
                      selected: _filterSelectedOptions(
                        SystemNotificationOption.values,
                        selected: selectedCategories,
                      ),
                      options: SystemNotificationOption.values,
                      onSelected: (option) => ref
                          .read(selectedPushCategoriesProvider.notifier)
                          .toggleCategory(option.category),
                      enabled: hasNotificationsPermission,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<T> _filterSelectedOptions<T extends PushNotificationOption>(
    List<T> options, {
    required List<PushNotificationCategory> selected,
  }) {
    return options.where((option) => selected.contains(option.category)).toList();
  }
}

class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  _NavBarDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Material(
      elevation: overlaps ? 4 : 0,
      child: child,
    );
  }

  @override
  double get maxExtent => NavigationAppBar.modalHeaderHeight;

  @override
  double get minExtent => NavigationAppBar.modalHeaderHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _DevicePermissionButton extends StatelessWidget {
  const _DevicePermissionButton({
    required this.hasPermission,
    required this.hasPermissionOnDeviceLevel,
    required this.onChangeAppLevelPermission,
  });

  final VoidCallback onChangeAppLevelPermission;
  final bool hasPermissionOnDeviceLevel;
  final bool hasPermission;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PermissionAwareWidget(
          permissionType: Permission.notifications,
          requestDialog: const PermissionRequestSheet(
            permission: Permission.notifications,
          ),
          onGranted: () {},
          builder: (BuildContext context, VoidCallback onPressed) {
            final onTap = hasPermissionOnDeviceLevel ? onChangeAppLevelPermission : onPressed;

            return ListItem(
              onTap: onTap,
              title: Text(
                context.i18n.push_notification_device_permission,
              ),
              leading: Button.icon(
                backgroundColor: context.theme.appColors.secondaryBackground,
                borderColor: context.theme.appColors.onTertiaryFill,
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0.s),
                ),
                size: 36.0.s,
                onPressed: onTap,
                icon: Assets.svg.iconProfileDevicepermission.icon(
                  color: context.theme.appColors.primaryAccent,
                ),
              ),
              trailing: hasPermission
                  ? Assets.svg.iconBlockCheckboxOn.icon()
                  : Assets.svg.iconBlockCheckboxOff.icon(),
            );
          },
        ),
      ],
    );
  }
}
