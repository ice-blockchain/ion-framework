// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/constants/links.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/android_soft_update.m.dart';
import 'package:ion/app/features/force_update/model/app_update_type.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ShowAppUpdateModalEvent extends UiEvent {
  const ShowAppUpdateModalEvent() : super(id: 'app_update_modal');

  static bool shown = false;

  @override
  Future<void> performAction(BuildContext context) async {
    if (!shown) {
      shown = true;
      await showSimpleBottomSheet<void>(
        context: context,
        isDismissible: false,
        child: const AppUpdateModal(
          appUpdateType: AppUpdateType.updateRequired,
        ),
      ).then((_) => shown = false);
    }
  }
}

class ShowInAppUpdateModalEvent extends UiEvent {
  const ShowInAppUpdateModalEvent() : super(id: 'in_app_update_modal');

  static bool shown = false;

  @override
  Future<void> performAction(BuildContext context) async {
    final ref = ProviderScope.containerOf(context);

    if (!shown) {
      shown = true;
      await showSimpleBottomSheet<void>(
        context: context,
        child: AppUpdateModal(
          appUpdateType: AppUpdateType.androidSoftUpdate,
          onPressedClose: () => context.pop(),
        ),
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            final currentState = ref.read(androidSoftUpdateProvider);
            if (currentState.updateState == AndroidUpdateState.loading) {
              ref.read(messageNotificationNotifierProvider.notifier).show(
                    MessageNotification(
                      message: context.i18n.update_inapp_notification_loading,
                      icon: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0.s),
                        child: ColoredBox(
                          color: context.theme.appColors.onPrimaryAccent,
                          child: Padding(
                            padding: EdgeInsets.all(6.0.s),
                            child: Assets.svg.iconBlockTime.icon(
                              color: context.theme.appColors.primaryAccent,
                              size: 16.0.s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
            }
          }
        },
      ).then((_) => shown = false);
    }
  }
}

class AppUpdateModal extends HookConsumerWidget {
  const AppUpdateModal({
    required this.appUpdateType,
    this.onPressedClose,
    super.key,
  });

  final AppUpdateType appUpdateType;
  final VoidCallback? onPressedClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSoftUpdate = appUpdateType == AppUpdateType.androidSoftUpdate;

    if (isSoftUpdate) {
      useOnInit(() => ref.read(androidSoftUpdateProvider.notifier).markModalAsShown());

      final updateState = ref.watch(androidSoftUpdateProvider).updateState;
      useEffect(
        () {
          if (updateState == AndroidUpdateState.success ||
              updateState == AndroidUpdateState.errorOrCancel) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            });
          }
          return null;
        },
        [updateState],
      );
    }

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.0.s),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 14.0.s),
              child: InfoCard(
                iconAsset: appUpdateType.iconAsset,
                title: appUpdateType.getTitle(context),
                description: appUpdateType.getDesc(context),
              ),
            ),
            SizedBox(height: 24.0.s),
            ScreenSideOffset.small(
              child: isSoftUpdate
                  ? const AndroidInAppUpdateButton()
                  : Button(
                      leadingIcon: appUpdateType.buttonIconAsset.icon(
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                      onPressed: () {
                        if (appUpdateType == AppUpdateType.updateRequired) {
                          openUrl(Links.appUpdate);
                        }
                      },
                      label: Text(appUpdateType.getActionTitle(context)),
                      mainAxisSize: MainAxisSize.max,
                    ),
            ),
            ScreenBottomOffset(),
          ],
        ),
        if (onPressedClose != null)
          PositionedDirectional(
            end: 10.0.s,
            top: 10.0.s,
            child: IconButton(
              icon: Assets.svg.iconSheetClose.icon(
                size: 24.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
              onPressed: onPressedClose,
            ),
          ),
      ],
    );
  }
}

class AndroidInAppUpdateButton extends ConsumerWidget {
  const AndroidInAppUpdateButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(androidSoftUpdateProvider).updateState;

    return Button(
      leadingIcon: (updateState == AndroidUpdateState.initial)
          ? Assets.svg.iconFeedUpdate.icon(color: context.theme.appColors.onPrimaryAccent)
          : null,
      onPressed: () async {
        if (updateState == AndroidUpdateState.initial) {
          await ref.read(androidSoftUpdateProvider.notifier).tryToStartUpdate();
        }

        if (context.mounted) context.pop();
      },
      label: _AndroidUpdateButtonLabel(state: updateState),
      mainAxisSize: MainAxisSize.max,
    );
  }
}

class _AndroidUpdateButtonLabel extends StatelessWidget {
  const _AndroidUpdateButtonLabel({required this.state});

  final AndroidUpdateState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AndroidUpdateState.loading => SizedBox(
          width: 26.0.s,
          height: 26.0.s,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: context.theme.appColors.onPrimaryAccent,
            strokeCap: StrokeCap.round,
          ),
        ),
      AndroidUpdateState.success || AndroidUpdateState.errorOrCancel => const SizedBox.shrink(),
      AndroidUpdateState.initial => Text(context.i18n.update_update_action),
    };
  }
}
