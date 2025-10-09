// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/generated/assets.gen.dart';

class ModalActionButton extends StatelessWidget {
  const ModalActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
    this.labelStyle,
    super.key,
  });

  final Widget icon;
  final String label;
  final Widget? value;
  final Widget? trailing;
  final VoidCallback onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      onTap: onTap,
      leading: Button.icon(
        backgroundColor: context.theme.appColors.secondaryBackground,
        borderColor: context.theme.appColors.onTertiaryFill,
        borderRadius: BorderRadius.all(
          Radius.circular(10.0.s),
        ),
        size: 36.0.s,
        onPressed: onTap,
        icon: icon,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? context.theme.appTextThemes.body,
            ),
          ),
          if (value != null) ...[
            SizedBox(width: 16.0.s),
            value!,
          ],
        ],
      ),
      trailing:
          trailing ?? Assets.svg.iconArrowRight.icon(color: context.theme.appColors.primaryText),
      backgroundColor: context.theme.appColors.tertiaryBackground,
    );
  }
}
