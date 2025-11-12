// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/item_loading_state.dart';
import 'package:ion/app/components/modal_action_button/modal_action_button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/language/language_sync_strategy_provider.r.dart';
import 'package:ion/app/features/settings/providers/video_settings_provider.m.dart';
import 'package:ion/app/features/settings/views/delete_confirm_modal.dart';
import 'package:ion/app/hooks/use_pop_if_returned_null.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class AccountSettingsModal extends HookConsumerWidget {
  const AccountSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentLangsAsync = ref.watch(contentLanguageWatchProvider);
    final videoSettings = ref.watch(videoSettingsProvider);

    final contentLanguages = useMemoized(
      () => contentLangsAsync.valueOrNull?.hashtags ?? const <String>[],
      [contentLangsAsync.valueOrNull],
    );

    final primaryColor = context.theme.appColors.primaryAccent;

    final popIfNull = usePopIfReturnedNull<bool>();

    final isDelegateAccessEnabled = ref
        .watch(featureFlagsProvider.notifier)
        .get(DelegateAccessFeatureFlag.delegateAccessEnabled);

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              onBackPress: () => context.pop(true),
              title: Text(context.i18n.common_account),
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.small(
              child: SeparatedColumn(
                separator: SizedBox(height: 9.0.s),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalActionButton(
                    icon: Assets.svg.iconProfileUser.icon(color: primaryColor),
                    label: context.i18n.settings_profile_edit,
                    onTap: () => ProfileEditRoute().go(context),
                  ),
                  if (isDelegateAccessEnabled)
                    ModalActionButton(
                      icon: Assets.svg.iconProfileDelegateaccess.icon(color: primaryColor),
                      label: context.i18n.settings_delegate_access,
                      onTap: () => popIfNull(() => DelegateAccessRoute().push<bool>(context)),
                    ),
                  ModalActionButton(
                    icon: Assets.svg.iconProfileBlockUser.icon(color: primaryColor),
                    label: context.i18n.settings_blocked_users,
                    onTap: () => popIfNull(() => BlockedUsersRoute().push<bool>(context)),
                  ),
                  ModalActionButton(
                    icon: Assets.svg.iconSettingsAutoplay.icon(color: primaryColor),
                    label: context.i18n.settings_video_autoplay,
                    onTap: ref.read(videoSettingsProvider.notifier).toggleAutoplay,
                    trailing: videoSettings.autoplay
                        ? Assets.svg.iconBlockCheckboxOn.icon()
                        : Assets.svg.iconBlockCheckboxOff.icon(),
                  ),
                  ModalActionButton(
                    icon: Assets.svg.iconSelectLanguage.icon(color: primaryColor),
                    label: context.i18n.settings_app_language,
                    value: Text(
                      ref.watch(localePreferredLanguagesProvider).first.name,
                      style: context.theme.appTextThemes.caption.copyWith(color: primaryColor),
                    ),
                    onTap: () => popIfNull(() => AppLanguagesRoute().push<bool>(context)),
                  ),
                  contentLangsAsync.maybeWhen(
                    orElse: () => const ItemLoadingState(),
                    data: (_) => ModalActionButton(
                      icon: Assets.svg.iconSelectLanguage.icon(color: primaryColor),
                      label: context.i18n.settings_content_language,
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contentLanguages.length > 1)
                            _RemainingLanguagesLabel(value: contentLanguages.length)
                          else if (contentLanguages.isNotEmpty)
                            Text(
                              Language.fromIsoCode(contentLanguages.first)?.name ??
                                  contentLanguages.first,
                              style:
                                  context.theme.appTextThemes.caption.copyWith(color: primaryColor),
                            ),
                        ],
                      ),
                      onTap: () => popIfNull(() => ContentLanguagesRoute().push<bool>(context)),
                    ),
                  ),
                  ModalActionButton(
                    icon: Assets.svg.iconBlockDelete.icon(
                      color: context.theme.appColors.attentionRed,
                    ),
                    label: context.i18n.settings_delete,
                    onTap: () => showSimpleBottomSheet<void>(
                      context: context,
                      isDismissible: false,
                      child: const ConfirmDeleteModal(),
                    ),
                  ),
                ],
              ),
            ),
            ScreenBottomOffset(margin: 32.0.s),
          ],
        ),
      ),
    );
  }
}

class _RemainingLanguagesLabel extends StatelessWidget {
  const _RemainingLanguagesLabel({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.onTertiaryFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.toString(),
          style: context.theme.appTextThemes.caption
              .copyWith(color: context.theme.appColors.primaryAccent),
        ),
      );
}
