// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ContactItemName extends ConsumerWidget {
  const ContactItemName({
    required this.userPreviewData,
    super.key,
  });

  final UserPreviewEntity userPreviewData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = ref.watch(isUserVerifiedProvider(userPreviewData.masterPubkey));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            userPreviewData.data.trimmedDisplayName,
            style: context.theme.appTextThemes.title,
          ),
        ),
        if (isVerified)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 4.0.s),
            child: Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
          ),
      ],
    );
  }
}
