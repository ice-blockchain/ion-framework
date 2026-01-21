// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

// Gradients for token type indicators
class TokenTypeGradients {
  TokenTypeGradients._();

  static const post = SweepGradient(
    colors: [
      Color(0xFF7D40FF),
      Color(0xFFAC86FF),
      Color(0xFF7D40FF),
      Color(0xFF5A0CFF),
      Color(0xFF7D40FF),
    ],
    stops: [0.00, 0.30, 0.72, 0.97, 1.00],
    startAngle: pi / 2,
    endAngle: pi * 5 / 2,
  );

  static const video = SweepGradient(
    colors: [
      Color(0xFFEA3665),
      Color(0xFFFF3232),
      Color(0xFFFF6C6C),
      Color(0xFFFF8686),
      Color(0xFFEA3665),
    ],
    stops: [0.00, 0.30, 0.72, 0.97, 1.00],
    startAngle: pi / 2,
    endAngle: pi * 5 / 2,
  );

  static const article = SweepGradient(
    colors: [
      Color(0xFF00AFA5),
      Color(0xFF00AA88),
      Color(0xFF35D487),
      Color(0xFF00DF86),
      Color(0xFF00AFA5),
    ],
    stops: [0.00, 0.30, 0.72, 0.97, 1.00],
    startAngle: pi / 2,
    endAngle: pi * 5 / 2,
  );

  static SweepGradient? getGradientForType(CommunityTokenType tokenType) {
    return switch (tokenType) {
      CommunityTokenType.post => post,
      CommunityTokenType.video => video,
      CommunityTokenType.article => article,
      CommunityTokenType.profile => null,
    };
  }

  static SweepGradient? getGradientForTokenizedType(TokenizedCommunityTokenType tokenType) {
    return switch (tokenType) {
      TokenizedCommunityTokenType.tokenTypePost => post,
      TokenizedCommunityTokenType.tokenTypeVideo => video,
      TokenizedCommunityTokenType.tokenTypeArticle => article,
      TokenizedCommunityTokenType.tokenTypeProfile => null,
      TokenizedCommunityTokenType.tokenTypeXcom => null,
      TokenizedCommunityTokenType.tokenTypeUndefined => null,
    };
  }
}
