// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/internet_status_stream_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ErrorPage extends HookConsumerWidget {
  const ErrorPage({
    this.message,
    super.key,
  });

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDebugInfo = ref.watch(envProvider.notifier).get<bool>(EnvVariable.SHOW_DEBUG_INFO);
    final noInternetConnection = !ref.watch(hasInternetConnectionProvider);
    final prevNoInternetConnection = usePrevious(noInternetConnection);
    useEffect(
      () {
        if (prevNoInternetConnection.falseOrValue && !noInternetConnection) {
          ref.invalidate(initAppProvider);
        }
        return null;
      },
      [prevNoInternetConnection.falseOrValue, noInternetConnection],
    );

    return Scaffold(
      body: Center(
        child: ScreenSideOffset.large(
          child: InfoCard(
            iconAsset: noInternetConnection
                ? Assets.svg.walletIconWalletLoadingerror
                : Assets.svg.actionFeedMaintenance,
            title: noInternetConnection
                ? context.i18n.no_connection_page_title
                : context.i18n.maintenance_page_title,
            descriptionWidget: Column(
              children: [
                Text(
                  noInternetConnection
                      ? context.i18n.no_connection_page_description
                      : context.i18n.maintenance_page_description,
                  textAlign: TextAlign.center,
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
                if (showDebugInfo && message != null && !noInternetConnection) ...[
                  SizedBox(height: 8.0.s),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
