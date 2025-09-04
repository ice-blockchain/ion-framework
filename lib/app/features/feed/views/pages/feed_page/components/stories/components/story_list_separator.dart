// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/num.dart';

class StoryListSeparator extends StatelessWidget {
  const StoryListSeparator({super.key});

  static double get width => 12.0.s;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}
