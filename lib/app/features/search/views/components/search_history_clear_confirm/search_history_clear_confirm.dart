// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class SearchHistoryClearConfirm extends StatelessWidget {
  const SearchHistoryClearConfirm({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Column(
        children: [
          SizedBox(height: 30.0.s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 36.0.s),
            child: InfoCard(
              iconAsset: Assets.svg.actionSearchDeletehistory,
              title: context.i18n.feed_search_history_delete_title,
              description: context.i18n.feed_search_history_delete_message,
            ),
          ),
          SizedBox(height: 32.0.s),
          Row(
            children: [
              Expanded(
                child: Button(
                  type: ButtonType.outlined,
                  label: Text(context.i18n.button_cancel),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: 16.0.s),
              Expanded(
                child: Button(
                  label: Text(context.i18n.button_delete),
                  backgroundColor: context.theme.appColors.attentionRed,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
