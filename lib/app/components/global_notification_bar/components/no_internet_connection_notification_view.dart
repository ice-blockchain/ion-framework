// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class NoInternetConnectionNotificationView extends StatelessWidget {
  const NoInternetConnectionNotificationView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final locale = context.i18n;

    return SizedBox(
      height: 24.0.s,
      child: ColoredBox(
        color: colors.raspberry,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 3.0.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16.0.s),
                child: Assets.svg.linearessentionaluidangertriangle.icon(size: 16.0.s),
              ),
              SizedBox(width: 8.0.s),
              Text(
                locale.common_no_internet_connection,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.onPrimaryAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
