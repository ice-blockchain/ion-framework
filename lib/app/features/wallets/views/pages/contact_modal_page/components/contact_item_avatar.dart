// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';

class ContactItemAvatar extends StatelessWidget {
  const ContactItemAvatar({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  static double get imageWidth => 60.0.s;

  @override
  Widget build(BuildContext context) {
    return IonConnectAvatar(
      size: imageWidth,
      masterPubkey: pubkey,
      borderRadius: BorderRadius.circular(14.0.s),
    );
  }
}
