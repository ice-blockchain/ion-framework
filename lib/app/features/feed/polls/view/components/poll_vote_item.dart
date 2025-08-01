// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class PollVoteItem extends StatelessWidget {
  const PollVoteItem({
    required this.text,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0.s),
        constraints: BoxConstraints(maxWidth: 250.0.s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0.s),
          border: Border.all(
            color: context.theme.appColors.onTertiaryFill,
          ),
          color: context.theme.appColors.tertiaryBackground,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.0.s,
            vertical: 10.0.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: context.theme.appTextThemes.body.copyWith(
                    color: isSelected
                        ? context.theme.appColors.primaryText
                        : context.theme.appColors.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
