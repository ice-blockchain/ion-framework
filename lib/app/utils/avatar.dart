// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:ion/generated/assets.gen.dart';

String getRandomDefaultAvatar(String? seed) {
  final defaultAvatars = <String>[
    Assets.svg.avatars.a1,
    Assets.svg.avatars.a2,
    Assets.svg.avatars.a3,
    Assets.svg.avatars.a4,
    Assets.svg.avatars.a5,
    Assets.svg.avatars.a6,
    Assets.svg.avatars.a7,
    Assets.svg.avatars.a8,
    Assets.svg.avatars.a9,
    Assets.svg.avatars.a10,
  ];

  // If no seed is provided, keep truly random behavior.
  if (seed == null || seed.isEmpty) {
    return defaultAvatars[Random().nextInt(defaultAvatars.length)];
  }

  // Deterministic: same seed -> same avatar.
  final index = _fnv1a32(seed) % defaultAvatars.length;
  return defaultAvatars[index];
}

int _fnv1a32(String input) {
  // Stable hash across runs/platforms
  var hash = 0x811c9dc5; // FNV offset basis
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime
  }
  return hash;
}
