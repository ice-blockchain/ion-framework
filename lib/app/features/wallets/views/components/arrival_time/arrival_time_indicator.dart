// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/generated/assets.gen.dart';

class ArrivalTimeIndicator extends StatelessWidget {
  const ArrivalTimeIndicator({
    required this.option,
    super.key,
  });

  final NetworkFeeOption option;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;
    final locale = context.i18n;
    final text = option.type?.getDisplayName(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: 28.0.s,
      ),
      child: Row(
        children: [
          if (text != null)
            Text(
              text,
              style: textTheme.body2.copyWith(
                color: colors.secondaryText,
              ),
            ),
          if (option.arrivalTime?.inMinutes != null) ...[
            SizedBox(width: 6.0.s),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0.s,
                vertical: 4.0.s,
              ),
              decoration: BoxDecoration(
                color: colors.onSecondaryBackground,
                borderRadius: BorderRadius.circular(15.0.s),
              ),
              child: Row(
                children: [
                  Assets.svg.iconBlockTime.icon(
                    size: 12.0.s,
                  ),
                  SizedBox(width: 5.0.s),
                  Text(
                    '${option.arrivalTime?.inMinutes} ${locale.wallet_arrival_time_minutes}',
                    style: textTheme.body2.copyWith(
                      color: colors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
