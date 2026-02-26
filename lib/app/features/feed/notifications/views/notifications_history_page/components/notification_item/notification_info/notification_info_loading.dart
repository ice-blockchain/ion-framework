// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';

class NotificationInfoLoading extends StatelessWidget {
  const NotificationInfoLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: 240.0.s,
          height: 19.0.s,
        ),
      ),
    );
  }
}
