// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/core/permissions/data/models/models.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/wallets/utils/prefix_trimmer.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScannerBottomSheet extends HookConsumerWidget {
  const QRScannerBottomSheet({
    super.key,
    this.shouldTrimPrefix = true,
  });

  final bool shouldTrimPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrKey = useMemoized(GlobalKey.new);
    final subscriptionRef = useRef<StreamSubscription<Barcode>?>(null);
    final hasCameraPermission = ref.watch(hasPermissionProvider(Permission.camera));
    final permissionStrategy = ref.read(permissionStrategyProvider(Permission.camera));

    useEffect(
      () => subscriptionRef.value?.cancel,
      const [],
    );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0.s),
          child: NavigationAppBar.screen(
            title: Text(context.i18n.wallet_scan),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              QRView(
                onQRViewCreated: (controller) {
                  subscriptionRef.value = controller.scannedDataStream.listen(
                    (scanData) {
                      if (context.mounted) {
                        subscriptionRef.value?.cancel();
                        scanData.code
                            ?.map((code) => shouldTrimPrefix ? trimPrefix(code) : code)
                            .let(context.pop);
                      }
                    },
                  );
                },
                overlay: QrScannerOverlayShape(
                  borderColor: context.theme.appColors.primaryAccent,
                  borderRadius: 10.0.s,
                  borderLength: 30.0.s,
                  borderWidth: 6.0.s,
                  cutOutSize: 238.0.s,
                  cutOutBottomOffset: !hasCameraPermission ? 48.0.s : 0,
                  overlayColor: context.theme.appColors.backgroundSheet,
                ),
                key: qrKey,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: !hasCameraPermission ? 48.0.s : 80.0.s,
                      ),
                      child: SizedBox(
                        width: 200.0.s,
                        child: Text(
                          textAlign: TextAlign.center,
                          context.i18n.wallet_scan_hint,
                          style: context.theme.appTextThemes.body.copyWith(
                            color: context.theme.appColors.onPrimaryAccent,
                          ),
                        ),
                      ),
                    ),
                    if (!hasCameraPermission)
                      Padding(
                        padding: EdgeInsets.all(16.0.s),
                        child: _InfoMessageCard(
                          onPressed: () async {
                            await permissionStrategy.openSettings();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  const _InfoMessageCard({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.appColors.onPrimaryAccent,
        border: Border.all(
          color: context.theme.appColors.onSecondaryBackground,
        ),
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.s, vertical: 12.0.s),
        child: Column(
          spacing: 4.0.s,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 6.0.s,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Assets.svg.iconProfileNocamera.icon(
                  size: 20.0.s,
                  color: context.theme.appColors.sharkText,
                ),
                Text(
                  context.i18n.common_no_camera_permission,
                  style: context.theme.appTextThemes.body.copyWith(
                    color: context.theme.appColors.sharkText,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  context.i18n.common_no_camera_permission_hint,
                  style: context.theme.appTextThemes.caption2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
                TextButton(
                  onPressed: onPressed,
                  child: Text(
                    context.i18n.button_go_to_settings,
                    style: context.theme.appTextThemes.caption2.copyWith(
                      color: context.theme.appColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
