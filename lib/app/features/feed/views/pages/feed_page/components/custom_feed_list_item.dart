// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';

class CustomFeedListItem extends StatelessWidget {
  const CustomFeedListItem({
    required this.header,
    required this.content,
    super.key,
  });

  final Widget header;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0.s, horizontal: 16.0.s),
      child: Column(
        spacing: 12.0.s,
        children: [
          header,
          content,
        ],
      ),
    );
  }
}
