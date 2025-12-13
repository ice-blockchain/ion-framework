// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/user_list_item.dart';

class Header extends ConsumerWidget {
  const Header({
    required this.pubkey,
    required this.opacity,
    required this.showBackButton,
    this.textColor,
    this.leadingPadding,
    super.key,
  });

  final String pubkey;
  final double opacity;
  final bool showBackButton;
  final Color? textColor;
  final double? leadingPadding;

  static const _defaultNoBackButtonSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveLeadingPadding =
        leadingPadding ?? (!showBackButton ? _defaultNoBackButtonSpacing : 0.0);

    return Row(
      children: [
        SizedBox(width: effectiveLeadingPadding.s),
        Expanded(
          child: UseListItem(
            pubkey: pubkey,
            minHeight: HeaderAction.buttonSize,
            textColor: textColor,
          ),
        ),
      ],
    );
  }
}
