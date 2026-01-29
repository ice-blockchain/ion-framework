// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class QuillEmbedTextScaler extends StatelessWidget {
  const QuillEmbedTextScaler({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // To make embedded quill widgets follow the same scale as surrounding rich text.
    // ignore: deprecated_member_use
    return MediaQuery(data: mq.copyWith(textScaleFactor: 1), child: child);
  }
}
