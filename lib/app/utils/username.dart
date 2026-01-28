// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

String withPrefix({
  required String? input,
  required TextDirection textDirection,
  String separator = '',
  String prefix = '@',
}) {
  final rtl = textDirection == TextDirection.rtl;
  final lUsername = input ?? '';

  if (lUsername.isNotEmpty) {
    return rtl ? '$lUsername$separator$prefix' : '$prefix$separator$lUsername';
  } else {
    return lUsername;
  }
}
