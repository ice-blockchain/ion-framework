// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';

class SuggestionsContainerEmpty extends ConsumerWidget {
  const SuggestionsContainerEmpty({
    required this.text,
    required this.icon,
    super.key,
  });

  final String text;
  final Widget icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 160.0.s,
      color: context.theme.appColors.secondaryBackground,
      child: Column(
        children: [
          const HorizontalSeparator(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(end: 8.0.s),
                child: icon,
              ),
              Text(
                text,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.tertiaryText,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
