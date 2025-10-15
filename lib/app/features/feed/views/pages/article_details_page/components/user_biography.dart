// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/user/user_about/user_about.dart';
import 'package:ion/app/features/components/user/user_info_summary/user_info_summary.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class UserBiography extends ConsumerWidget {
  const UserBiography({required this.eventReference, super.key});

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      alignment: AlignmentDirectional.topStart,
      decoration: BoxDecoration(
        color: context.theme.appColors.onPrimaryAccent,
        borderRadius: BorderRadius.all(Radius.circular(16.0.s)),
        border: Border.all(
          width: 1.0.s,
          color: context.theme.appColors.onTertiaryFill,
        ),
      ),
      padding: EdgeInsets.all(
        12.0.s,
      ),
      child: Column(
        children: [
          UserInfo(
            pubkey: eventReference.masterPubkey,
            network: true,
          ),
          SizedBox(height: 12.0.s),
          UserAbout(
            pubkey: eventReference.masterPubkey,
            padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
          ),
          UserInfoSummary(pubkey: eventReference.masterPubkey),
        ],
      ),
    );
  }
}
