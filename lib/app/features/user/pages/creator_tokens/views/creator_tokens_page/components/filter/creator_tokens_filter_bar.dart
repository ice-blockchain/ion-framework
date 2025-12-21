// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/filter/token_type_filter_dropdown.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensFilterBar extends StatelessWidget {
  const CreatorTokensFilterBar({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
      child: Row(
        children: [
          Assets.svg.iconFilter.icon(
            color: colors.onTertiaryBackground,
            size: 18.0.s,
          ),
          SizedBox(width: 8.0.s),
          Text(
            context.i18n.creator_tokens_filter_title,
            style: textStyles.subtitle3.copyWith(
              color: colors.onTertiaryBackground,
            ),
          ),
          const Spacer(),
          TokenTypeFilterDropdown(scrollController: scrollController),
        ],
      ),
    );
  }
}
