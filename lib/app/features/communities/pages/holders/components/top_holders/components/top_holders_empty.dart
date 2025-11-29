import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TopHoldersEmpty extends StatelessWidget {
  const TopHoldersEmpty({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: 16.s),
        child: Column(
          children: [
            Assets.svg.walletChatNewchat.icon(size: 60.s),
            SizedBox(height: 8.s),
            Text(
              context.i18n.top_holders_empty,
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
