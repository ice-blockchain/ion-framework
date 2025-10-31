// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/iterable.dart';

class SeparatedRow extends Row {
  SeparatedRow({
    required Widget separator,
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    List<Widget> children = const [],
  }) : super(
          children: children.separated(separator).toList(),
        );
}
