// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/generated/assets.gen.dart';

class LanguageListItem extends StatelessWidget {
  const LanguageListItem({
    required this.language,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final Language language;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScreenSideOffset.small(
        child: Container(
          height: 44.0.s,
          decoration: BoxDecoration(
            color: context.theme.appColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(12.0.s),
          ),
          child: ScreenSideOffset.small(
            child: Row(
              children: [
                Text(
                  language.flag,
                  style: TextStyle(fontSize: 18.0.s),
                ),
                SizedBox(width: 16.0.s),
                Expanded(
                  child: Text(
                    language.displayName,
                    style: context.theme.appTextThemes.subtitle2.copyWith(
                      color: context.theme.appColors.primaryText,
                    ),
                  ),
                ),
                if (isSelected)
                  Assets.svg.iconBlockCheckboxOn.icon()
                else
                  Assets.svg.iconBlockCheckboxOff.icon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
