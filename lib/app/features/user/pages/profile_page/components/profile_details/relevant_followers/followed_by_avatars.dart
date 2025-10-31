// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';

class FollowedByAvatars extends StatelessWidget {
  const FollowedByAvatars({required this.pubkeys, super.key});

  final List<String> pubkeys;

  @override
  Widget build(BuildContext context) {
    final avatarSize = _FollowedAvatar.avatarSize;
    final overlap = avatarSize * 0.2;

    return SizedBox(
      height: avatarSize,
      width: avatarSize + (pubkeys.length - 1) * (avatarSize - overlap),
      child: Stack(
        children: [
          for (int i = pubkeys.length - 1; i >= 0; i--)
            PositionedDirectional(
              key: ValueKey<String>('pos-${pubkeys[i]}-$i'),
              start: i * (avatarSize - overlap),
              child: _FollowedAvatar(
                key: ValueKey<String>('avatar-${pubkeys[i]}'),
                pubkey: pubkeys[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowedAvatar extends StatelessWidget {
  const _FollowedAvatar({required this.pubkey, super.key});

  final String pubkey;

  static double get avatarSize => 20.0.s;

  double get borderWidth => 1.0.s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0.s),
      ),
      child: IonConnectAvatar(
        key: ValueKey<String>('ion-$pubkey'),
        size: avatarSize - borderWidth * 2,
        fit: BoxFit.cover,
        masterPubkey: pubkey,
        borderRadius: BorderRadius.circular(6.0.s),
      ),
    );
  }
}
