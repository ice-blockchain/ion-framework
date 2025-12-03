// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/theme_data.dart';

class AttributionTextContainer extends StatelessWidget {
  const AttributionTextContainer({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.onPrimaryAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: context.textPrimary.caption4.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
